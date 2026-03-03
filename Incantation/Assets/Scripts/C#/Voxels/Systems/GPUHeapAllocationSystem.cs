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
                        deallocateUpToIndex(1, hash, ref stats, ref state);
                    }

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
                deallocateUpToIndex(2, hash, ref stats, ref state);

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
                    if (endingFreeOffsetsToSize.TryGetValue(alloc.offset - 1, out uint prevSize))
                    {
                        uint prevOffset = alloc.offset - prevSize;
                        RemoveFreeRegion(prevOffset, prevSize);
                        newOffset = prevOffset;
                        newSize += prevSize;
                    }

                    // Merge with next
                    if (startingFreeOffsetsToSize.TryGetValue(endIndex + 1, out uint nextSize))
                    {
                        RemoveFreeRegion(endIndex + 1, nextSize);
                        newSize += nextSize;
                    }

                    // Add new free region
                    FreeRegion newFreeRegion = new FreeRegion();
                    newFreeRegion.offset = newOffset;
                    newFreeRegion.size = newSize;

                    freeRegions.Add(newFreeRegion);
                    startingFreeOffsetsToSize[newOffset] = newSize;
                    endingFreeOffsetsToSize[newOffset + newSize - 1] = newSize;
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