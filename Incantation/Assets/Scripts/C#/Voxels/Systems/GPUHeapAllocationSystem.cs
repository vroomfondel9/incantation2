using Incantation.Engine.Voxels.Components;
using System;
using System.Collections.Generic;
using System.Drawing;
using Unity.Collections;
using Unity.Entities;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal.Internal;

namespace Incantation.Engine.Voxels.Components
{
    /*
     * Manages addresses / sizes within a conceptual memory heap within the global voxels GPU StructureBuffer.
     * 
     * Allocation implemented as requesting new heap space and once a section of memory is carved out and ownership transfers,
     * flags are set telling the GPU StructuredBuffer manager that it's okay to begin copying data to it. A number
     * of frames later (settable via GlobalConstants.GPU_BUFFER_UPDATE_SWAP_DELAY_FRAMES), this class will switch
     * from using the old memory space to the newly allocated one (which is assumed to have all values copied in by now)
     * and free up the old memory space. This is called a "sync".
     * 
     * Reallocation will not occur until all existing syncs are completed (so a voxel volume can own, at most, 2 chunks
     * of heap memory at any given time). Deallocation removes ownership and frees up both the old memory region and any
     * regions in which a sync is currently happening.
     * 
     * It maintains a set of stats about the state of the heap that can be used for heap monitoring purposes. See GPUHeapStats.
     * 
     * Heap implementation is pretty straight-forward. This class keeps track a tail pointer. Nothing past the tail pointer is
     * allocated if a free region before the tail pointer can be used instead. Free regions are merged if adjascent. On allocating,
     * we try to find the smallest free region that'll fit the data. That sort of thing.
     * 
     * This system manages centralized state across multiple entities and is order dependent (allocations and deallocations
     * done across the same objects in a different order will result in a different memory layout) and is not parallel-safe
     * (entities would compete over the same memory regions).
     * 
     * Data flow Flags:
     * ================
     * 
     * NeedsGPUReallocation - Set on any entities that are newly-spawned but haven't yet been made to render or interact with
     * the physics system. Also set on any entities which have been modified in a way that alters their memory usage. An example
     * would be a voxel volume whose dimensions were reduced so it no longer needs so much memory to store its values.
     * 
     * NeedsGPUDeallocation - Indicates an intent to free up all memory regions associated with this entity. Used only prior to
     * despawn.
     * 
     * GPUSyncNeeded - Set to indicate that a new memory region has been allocated and it's okay to start copying data into it.
     * Once that copy has begun, this system expects GPUSyncInProgress to be set by a downstream process (at which point, it'll
     * start updating its frame countdown to switching and freeing up the old memory space).
     */
    [UpdateInGroup(typeof(GPUBuffersUpdateSystemGroup))]
    public partial struct GPUHeapAllocationSystem : ISystem
    {
        // Used for initial capacity for memory management variables
        private static int ASSUMED_MAX_VOX_VOLS = 300000;

        // Allocation bookkeeping
        private struct Allocation
        {
            public uint offset;
            public uint size;
            public uint consumers;
        }

        private struct AllocationKey : IEquatable<AllocationKey>
        {
            public ulong hash;
            public uint index;

            public bool Equals(AllocationKey other)
            {
                return hash == other.hash && index == other.index;
            }

            public override bool Equals(object obj)
            {
                return obj is AllocationKey other && Equals(other);
            }

            public override int GetHashCode()
            {
                // Good 64+32 bit mix
                unchecked
                {
                    ulong h = hash ^ index;
                    h *= 1099511628211UL;
                    return (int)h;
                }
            }
        }

        private struct FreeRegion
        {
            public uint offset;
            public uint size;
        }

        // For sorting free regions of memory (first by size, next by offset)
        private struct FreeRegionComparer : IComparer<FreeRegion>
        {
            public int Compare(FreeRegion a, FreeRegion b)
            {
                int sizeCompare = a.size.CompareTo(b.size);
                if (sizeCompare != 0)
                    return sizeCompare;

                return a.offset.CompareTo(b.offset);
            }
        }
        private FreeRegionComparer freeRegionComparator;

        // Memory management variables
        private NativeParallelHashMap<AllocationKey, Allocation> allocations;
        private NativeParallelHashMap<uint, uint> startingFreeOffsetsToSize;
        private NativeParallelHashMap<uint, uint> endingFreeOffsetsToSize;
        private NativeList<FreeRegion> freeRegions;
        private uint allocationsTail;

        public void OnCreate(ref SystemState state)
        {
            freeRegionComparator = new FreeRegionComparer();

            // Initialize memory management variables
            allocations = new NativeParallelHashMap<AllocationKey, Allocation>(ASSUMED_MAX_VOX_VOLS, Allocator.Persistent);
            startingFreeOffsetsToSize = new NativeParallelHashMap<uint, uint>(ASSUMED_MAX_VOX_VOLS, Allocator.Persistent);
            endingFreeOffsetsToSize = new NativeParallelHashMap<uint, uint>(ASSUMED_MAX_VOX_VOLS, Allocator.Persistent);
            freeRegions = new NativeList<FreeRegion>(Allocator.Persistent);
            freeRegions.SetCapacity(ASSUMED_MAX_VOX_VOLS);
            allocationsTail = 0;

            // Create singleton components
            state.EntityManager.CreateSingleton<GPUHeapStats>();
        }

        public void OnDestroy(ref SystemState state)
        {
            allocations.Dispose();
            startingFreeOffsetsToSize.Dispose();
            endingFreeOffsetsToSize.Dispose();
            freeRegions.Dispose();
        }

        public void OnUpdate(ref SystemState state)
        {
            // Heap status (for runtime monitoring / debugging)
            var statsRW = SystemAPI.GetSingletonRW<GPUHeapStats>();
            ref var stats = ref statsRW.ValueRW;

            updateInProgressGPUSyncs(ref stats, ref state);
            reallocateNewOrModified(ref stats, ref state);
            deallocateDespawning(ref stats, ref state);

            updateHeapStats(ref stats);
        }

        private void updateInProgressGPUSyncs(ref GPUHeapStats stats, ref SystemState state)
        {
            foreach (var (heapState, volumeId, entity)
                in SystemAPI.Query<
                        RefRW<GPUVoxelHeapState>,
                        RefRO<VoxelVolumeID>>()
                    .WithAll<GPUSyncInProgress>()
                    .WithEntityAccess())
            {
                ref var componentHeapState = ref heapState.ValueRW;
                componentHeapState.FramesUntilSyncSwap--;

                if (componentHeapState.FramesUntilSyncSwap == 0)
                {
                    ulong hash = volumeId.ValueRO.Hash;

                    // Deallocate only old buffer region
                    if (componentHeapState.Allocated)
                    {
                        deallocateUpToIndex(0, hash, ref stats, ref state);
                    }

                    // Swap allocation index in allocations (sync partition to main partition)
                    AllocationKey mainKey = new AllocationKey();
                    AllocationKey syncKey = new AllocationKey();

                    mainKey.hash = hash;
                    syncKey.hash = hash;
                    mainKey.index = 0;
                    syncKey.index = 1;

                    if (allocations.TryGetValue(syncKey, out Allocation syncAlloc))
                    {
                        allocations.Add(mainKey, syncAlloc);
                        allocations.Remove(syncKey);
                    }
                    else
                    {
                        throw new Exception("Attempt to GPU sync voxel volume after global memory copy but expected sync allocation was not found!");
                    }

                    syncKey.index = 0;

                    // Swap data from new buffer region in
                    componentHeapState.Offset = componentHeapState.SyncInProgressOffset;
                    componentHeapState.Size = componentHeapState.SyncInProgressSize;
                    componentHeapState.Shared = componentHeapState.SyncInProgressShared;
                    componentHeapState.SyncInProgressOffset = 0;
                    componentHeapState.SyncInProgressSize = 0;
                    componentHeapState.SyncInProgressShared = false;
                    componentHeapState.Allocated = true;

                    // Toggles
                    SystemAPI.SetComponentEnabled<GPUSyncInProgress>(entity, false);
                }
            }
        }

        private void reallocateNewOrModified(ref GPUHeapStats stats, ref SystemState state)
        {
            foreach (var (heapState, volumeId, entity)
                in SystemAPI.Query<
                        RefRW<GPUVoxelHeapState>,
                        RefRO<VoxelVolumeID>>()
                    .WithAll<NeedsGPUReallocation>()
                    .WithNone<GPUSyncInProgress>()
                    .WithEntityAccess())
            {
                ulong hash = volumeId.ValueRO.Hash;
                uint requiredSize =
                    volumeId.ValueRO.Dimensions.x *
                    volumeId.ValueRO.Dimensions.y *
                    volumeId.ValueRO.Dimensions.z;

                stats.TotalVolumes++;
                bool useSharedMemSpace = false;

                Allocation newAlloc = new Allocation();
                AllocationKey key = new AllocationKey();
                key.hash = hash;

                //Check if shared heap space already allocated that can be reused
                for (uint i = 0; i < 2; i++)
                {
                    key.index = i;
                    if (allocations.TryGetValue(key, out var allocation))
                    {
                        if (allocation.size == requiredSize)
                        {
                            useSharedMemSpace = true;

                            // Update heap stats
                            stats.SharedMemoryVolumeRiders++;
                            stats.SharedAllocations += (allocation.consumers == 1) ? 1 : 0;

                            // Update shared consumer count
                            allocation.consumers++;
                            allocations[key] = allocation;
                            newAlloc = allocation;

                            // Update entity
                            heapState.ValueRW.SyncInProgressOffset = allocation.offset;
                        }
                    }
                }

                // New allocation needed
                key.index = 1;

                if (!useSharedMemSpace)
                {
                    int freeIndex = FindFirstFreeRegionWithSizeAtLeast(requiredSize);

                    // Free space found that we can reuse
                    if (freeIndex != -1)
                    {
                        FreeRegion freeRegion = freeRegions.ElementAt(freeIndex);
                        uint remainder = freeRegion.size - requiredSize;
                        stats.FreeSum -= requiredSize;

                        // Remove free region from offset maps
                        startingFreeOffsetsToSize.Remove(freeRegion.offset);
                        endingFreeOffsetsToSize.Remove(freeRegion.offset + requiredSize - 1);

                        // Can just remove the FreeRegion at that index and the rest shift
                        if (remainder == 0)
                        {
                            freeRegions.RemoveAt(freeIndex);
                        }
                        // Must resort free region list to maintain the remainder free space
                        else
                        {
                            FreeRegion remainderRegion = new FreeRegion();
                            remainderRegion.offset = freeRegion.offset + requiredSize;
                            remainderRegion.size = remainder;

                            freeRegions.RemoveAtSwapBack(freeIndex);
                            freeRegions.Add(remainderRegion);
                            freeRegions.Sort(freeRegionComparator);

                            startingFreeOffsetsToSize.Add(remainderRegion.offset, remainderRegion.size);
                            endingFreeOffsetsToSize.Add(remainderRegion.offset + remainderRegion.size - 1, remainderRegion.size);
                        }

                        newAlloc.offset = freeRegion.offset;
                        newAlloc.size = requiredSize;
                        newAlloc.consumers = 1;

                        allocations.Add(key, newAlloc);
                    }
                    // No existing free region big enough - add to end
                    else
                    {
                        if (allocationsTail + requiredSize <= GlobalConstants.MAX_GLOBAL_VOXELS)
                        {
                            uint offset = allocationsTail;
                            allocationsTail += requiredSize;

                            newAlloc.offset = offset;
                            newAlloc.size = requiredSize;
                            newAlloc.consumers = 1;

                            allocations.Add(key, newAlloc);
                        }
                        // Exceeded voxel memory size
                        else
                        {
                            throw new Exception("Attempt to allocate voxels but ran out of GPU voxel buffer memory. Try increasing GlobalConstants.MAX_GLOBAL_VOXELS.");
                        }
                    }
                }

                // Update components based on allocation and whether it's shared memory
                ref var componentHeapState = ref heapState.ValueRW;

                componentHeapState.SyncInProgressOffset = newAlloc.offset;
                componentHeapState.SyncInProgressSize = newAlloc.size;
                componentHeapState.SyncInProgressShared = useSharedMemSpace;
                componentHeapState.FramesUntilSyncSwap = GlobalConstants.GPU_BUFFER_UPDATE_SWAP_DELAY_FRAMES;

                // Toggles
                SystemAPI.SetComponentEnabled<NeedsGPUReallocation>(entity, false);
                SystemAPI.SetComponentEnabled<GPUSyncNeeded>(entity, true);
            }
        }

        private void deallocateDespawning(ref GPUHeapStats stats, ref SystemState state)
        {
            foreach (var (heapState, volumeId, entity)
                in SystemAPI.Query<
                        RefRW<GPUVoxelHeapState>,
                        RefRO<VoxelVolumeID>>()
                    .WithAll<NeedsGPUDeallocation>()
                    .WithEntityAccess())
            {
                ulong hash = volumeId.ValueRO.Hash;
                deallocateUpToIndex(1, hash, ref stats, ref state);

                // Update components based on allocation and whether it's shared memory
                ref var componentHeapState = ref heapState.ValueRW;

                componentHeapState.Allocated = false;
                componentHeapState.Offset = 0;
                componentHeapState.Size = 0;
                componentHeapState.Shared = false;
                componentHeapState.SyncInProgressOffset = 0;
                componentHeapState.SyncInProgressSize = 0;
                componentHeapState.SyncInProgressShared = false;
                componentHeapState.FramesUntilSyncSwap = 0;

                // Toggles
                SystemAPI.SetComponentEnabled<NeedsGPUDeallocation>(entity, false);
                SystemAPI.SetComponentEnabled<NeedsDeletion>(entity, true);
            }
        }

        private int FindFirstFreeRegionWithSizeAtLeast(uint requestedSize)
        {
            int left = 0;
            int right = freeRegions.Length - 1;
            int result = -1;

            while (left <= right)
            {
                int mid = left + ((right - left) >> 1);

                uint midSize = freeRegions[mid].size;

                if (midSize >= requestedSize)
                {
                    result = mid;        // candidate found
                    right = mid - 1;     // search further left for first match
                }
                else
                {
                    left = mid + 1;
                }
            }

            return result;
        }

        private void deallocateUpToIndex(int maxAllocationIndex, ulong hash, 
            ref GPUHeapStats stats, ref SystemState state)
        {
            AllocationKey key = new AllocationKey();
            key.hash = hash;

            for (uint i = 0; i <= maxAllocationIndex; i++)
            {
                key.index = i;

                if (!allocations.TryGetValue(key, out var alloc))
                    continue;

                stats.TotalVolumes--;
                alloc.consumers--;

                // Shared volumes we shouldn't release because others are using it
                if (alloc.consumers > 0)
                {
                    stats.SharedMemoryVolumeRiders--;
                    if (alloc.consumers == 1)
                    {
                        stats.SharedAllocations--;
                    }

                    allocations[key] = alloc;
                }
                // Dedicated volumes we should release
                else
                {
                    allocations.Remove(key);

                    // Determine new free region size
                    uint newOffset = alloc.offset;
                    uint newSize = alloc.size;
                    stats.FreeSum += newSize;

                    uint endIndex = alloc.offset + alloc.size - 1;

                    // Merge with previous
                    bool merged = false;
                    if ((alloc.offset > 0) && (endingFreeOffsetsToSize.TryGetValue(alloc.offset - 1, out uint prevSize)))
                    {
                        uint prevOffset = alloc.offset - prevSize;
                        RemoveFreeRegion(prevOffset, prevSize);
                        newOffset = prevOffset;
                        newSize += prevSize;
                        merged = true;
                    }

                    // Merge with next
                    if (startingFreeOffsetsToSize.TryGetValue(endIndex + 1, out uint nextSize))
                    {
                        RemoveFreeRegion(endIndex + 1, nextSize);
                        newSize += nextSize;
                        merged = true;
                    }

                    // Free region at end - shrink the tail
                    if (newOffset + newSize == allocationsTail)
                    {
                        allocationsTail = newOffset;
                        stats.FreeSum -= newSize;

                        if (merged)
                        {
                            freeRegions.Sort(freeRegionComparator);
                        }
                    }
                    // Free region in middle - add new free region to list
                    else
                    {
                        FreeRegion newFreeRegion = new FreeRegion();
                        newFreeRegion.offset = newOffset;
                        newFreeRegion.size = newSize;

                        startingFreeOffsetsToSize[newOffset] = newSize;
                        endingFreeOffsetsToSize[newOffset + newSize - 1] = newSize;


                        freeRegions.Add(newFreeRegion);
                        freeRegions.Sort(freeRegionComparator);
                    }
                }
            }
        }

        private void RemoveFreeRegion(uint offset, uint size)
        {
            startingFreeOffsetsToSize.Remove(offset);
            endingFreeOffsetsToSize.Remove(offset + size - 1);

            // Search for free region in the list to remove
            int firstSizeIndex = FindFirstFreeRegionWithSizeAtLeast(size);
            for (int curIndex = firstSizeIndex; curIndex < freeRegions.Length; curIndex++)
            {
                FreeRegion curRegion = freeRegions.ElementAt(curIndex);

                if (curRegion.offset == offset)
                {
                    freeRegions.RemoveAtSwapBack(curIndex);
                }

                if (curRegion.size > size)
                {
                    break;
                }
            }
        }

        private void updateHeapStats(ref GPUHeapStats stats)
        {
            stats.TotalAllocations = allocations.Count();
            stats.UniqueAllocations = stats.TotalAllocations - stats.SharedAllocations;
            stats.SharedMemoryVolumes = stats.SharedMemoryVolumeRiders + stats.SharedAllocations;

            stats.UniqueAllocationPercent = stats.TotalAllocations == 0
                ? 0
                : (float)stats.UniqueAllocations / stats.TotalAllocations * 100f;

            stats.UsagePercent = allocationsTail == 0
                ? 0
                : (float)allocationsTail / GlobalConstants.MAX_GLOBAL_VOXELS * 100f;

            stats.FragmentationPercent = allocationsTail == 0
                ? 0
                : (float)stats.FreeSum / allocationsTail * 100f;
        }
    }
}