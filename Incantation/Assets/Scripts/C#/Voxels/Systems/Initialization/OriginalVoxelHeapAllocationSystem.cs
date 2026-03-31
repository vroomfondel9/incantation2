using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Systems;
using System;
using System.Collections.Generic;
using System.Drawing;
using Unity.Collections;
using Unity.Entities;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal.Internal;
using static UnityEditor.FilePathAttribute;

namespace Incantation.Engine.Voxels.Components
{
    /*
     * Manages addresses / sizes within a conceptual memory heap within the a global read-only original voxel buffer. 
     * These values can be used on both the CPU and GPU size in order to do any heap management involving per-voxel values. 
     * Since this class isn't tied to any buffer in particular, it can be reused across any per-voxel buffers as needed and 
     * all of those buffers are kept in sync in terms of indices, sizes, etc.
     * 
     * It maintains a set of stats about the state of the heap that can be used for heap monitoring purposes.
     * 
     * Heap implementation is pretty straight-forward. This class keeps track a tail pointer. Nothing past the tail pointer is
     * allocated if a free region before the tail pointer can be used instead. Free regions are merged if adjascent. On allocating,
     * we try to find the smallest free region that'll fit the data. That sort of thing.
     * 
     * This system manages centralized state across multiple entities and is order dependent (allocations and deallocations
     * done across the same objects in a different order will result in a different memory layout) and is not parallel-safe
     * (entities would compete over the same memory regions).
     */
    [UpdateInGroup(typeof(VoxelVolumeInitializationSystemGroup))]
    [UpdateAfter(typeof(VoxelVolumeInitialComponentDecoratorSystem))]
    public partial struct OriginalVoxelHeapAllocationSystem : ISystem
    {
        // Allocation bookkeeping
        private struct Allocation
        {
            public uint offset;
            public uint size;
            public uint consumers;
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
        private NativeParallelHashMap<ulong, Allocation> allocations;
        private NativeParallelHashMap<uint, uint> startingFreeOffsetsToSize;
        private NativeParallelHashMap<uint, uint> endingFreeOffsetsToSize;
        private NativeList<FreeRegion> freeRegions;
        private uint allocationsTail;

        public void OnCreate(ref SystemState state)
        {
            freeRegionComparator = new FreeRegionComparer();

            // Initialize memory management variables
            allocations = new NativeParallelHashMap<ulong, Allocation>(GlobalConstants.MAX_UNIQUE_ORIG_VOX_VOLS_PER_SCENE, Allocator.Persistent);
            startingFreeOffsetsToSize = new NativeParallelHashMap<uint, uint>(GlobalConstants.MAX_UNIQUE_ORIG_VOX_VOLS_PER_SCENE, Allocator.Persistent);
            endingFreeOffsetsToSize = new NativeParallelHashMap<uint, uint>(GlobalConstants.MAX_UNIQUE_ORIG_VOX_VOLS_PER_SCENE, Allocator.Persistent);
            freeRegions = new NativeList<FreeRegion>(Allocator.Persistent);
            freeRegions.SetCapacity(GlobalConstants.MAX_UNIQUE_ORIG_VOX_VOLS_PER_SCENE);
            allocationsTail = 0;

            // Create singleton components
#if STATS_ALLOCATOR_ORIGINAL
            state.EntityManager.CreateSingleton<OriginalVoxelHeapStats>();
#endif
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
#if STATS_ALLOCATOR_ORIGINAL
            // Heap status (for runtime monitoring / debugging)
            var statsRW = SystemAPI.GetSingletonRW<OriginalVoxelHeapStats>();
            ref var stats = ref statsRW.ValueRW;
#endif

            allocateNew(
#if STATS_ALLOCATOR_ORIGINAL
                ref stats,
#endif
                ref state);
            deallocateDespawning(
#if STATS_ALLOCATOR_ORIGINAL
                ref stats,
#endif
                ref state);
#if STATS_ALLOCATOR_ORIGINAL
            updateHeapStats(ref stats);
#endif
        }

        private void allocateNew(
#if STATS_ALLOCATOR_ORIGINAL
            ref OriginalVoxelHeapStats stats,
#endif
            ref SystemState state)
        {
            foreach (var (originalDimensions, originalOffset, volumeId, gridDimensions, entity)
                in SystemAPI.Query<
                        RefRO<OriginalDimensions>,
                        RefRW<OriginalVoxelVolumeGlobalOffset>,
                        RefRO<OriginalVoxelVolumeID>,
                        RefRO<GridDimensions>>()
                    .WithAll<InitializationColorTopologyPackedVoxel, IsVoxelVolume>()
                    .WithEntityAccess())
            {
                ulong hash = volumeId.ValueRO.Hash;
                uint requiredSize =
                    gridDimensions.ValueRO.X *
                    gridDimensions.ValueRO.Y *
                    gridDimensions.ValueRO.Z;
                bool useSharedMemSpace = false;

#if STATS_ALLOCATOR_ORIGINAL
                stats.TotalVolumes++;
#endif


                Allocation newAlloc = new Allocation();

                uint clones = 0;
                if (SystemAPI.HasBuffer<InitializationCloneOffset>(entity))
                {
                    DynamicBuffer<InitializationCloneOffset> cloneOffsets = SystemAPI.GetBuffer<InitializationCloneOffset>(entity);
                    clones = (uint) cloneOffsets.Length;
                }

#if STATS_ALLOCATOR_ORIGINAL
                stats.SharedMemoryVolumeRiders += clones;
                stats.SharedAllocations += (clones > 0) ? 1 : 0;
#endif

                //Check if shared heap space already allocated that can be reused
                if (allocations.TryGetValue(hash, out var allocation))
                {
                    if (allocation.size == requiredSize)
                    {
                        useSharedMemSpace = true;

#if STATS_ALLOCATOR_ORIGINAL
                        // Update heap stats
                        stats.SharedMemoryVolumeRiders++;
                        stats.SharedAllocations += (allocation.consumers == 1) ? 1 : 0;
                        stats.SharedAllocations -= (clones > 0) ? 1 : 0;
#endif

                        // Update shared consumer count
                        allocation.consumers += 1 + clones;
                        allocations[hash] = allocation;
                        newAlloc = allocation;

                        // Update entity
                        originalOffset.ValueRW.Value = allocation.offset;
                    }
                }

                // New allocation needed
                if (!useSharedMemSpace)
                {
                    int freeIndex = FindFirstFreeRegionWithSizeAtLeast(requiredSize);

                    // Free space found that we can reuse
                    if (freeIndex != -1)
                    {
                        FreeRegion freeRegion = freeRegions.ElementAt(freeIndex);
                        uint remainder = freeRegion.size - requiredSize;

#if STATS_ALLOCATOR_ORIGINAL
                        stats.FreeSum -= requiredSize;
#endif

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
                        newAlloc.consumers = 1 + clones;

                        allocations.Add(hash, newAlloc);
                    }
                    // No existing free region big enough - add to end
                    else
                    {
                        if (allocationsTail + requiredSize <= GlobalConstants.MAX_GLOBAL_ORIGINAL_VOXELS)
                        {
                            uint offset = allocationsTail;
                            allocationsTail += requiredSize;

                            newAlloc.offset = offset;
                            newAlloc.size = requiredSize;
                            newAlloc.consumers = 1 + clones;

                            allocations.Add(hash, newAlloc);
                        }
                        // Exceeded voxel memory size
                        else
                        {
                            throw new Exception("Attempt to allocate voxels but ran out of voxel buffer memory. Try increasing GlobalConstants.MAX_GLOBAL_VOXELS.");
                        }
                    }
                }

                // Update components based on allocation and whether it's shared memory
                originalOffset.ValueRW.Value = newAlloc.offset;
            }
        }

        private void deallocateDespawning(
#if STATS_ALLOCATOR_ORIGINAL
            ref OriginalVoxelHeapStats stats,
#endif
            ref SystemState state)
        {
            foreach (var (originalOffset, volumeId, entity)
                in SystemAPI.Query<
                        RefRW<OriginalVoxelVolumeGlobalOffset>,
                        RefRO<OriginalVoxelVolumeID>>()
                    .WithAll<NeedsDeletion, IsVoxelVolume>()
                    .WithEntityAccess())
            {
                ulong hash = volumeId.ValueRO.Hash;

                if (!allocations.TryGetValue(hash, out var alloc))
                    continue;

#if STATS_ALLOCATOR_ORIGINAL
                stats.TotalVolumes--;
#endif

                alloc.consumers--;

                // Shared volumes we shouldn't release because others are using it
                if (alloc.consumers > 0)
                {

#if STATS_ALLOCATOR_ORIGINAL
                    stats.SharedMemoryVolumeRiders--;

                    if (alloc.consumers == 1)
                    {
                        stats.SharedAllocations--;
                    }
#endif

                    allocations[hash] = alloc;
                }
                // Dedicated volumes we should release
                else
                {
                    allocations.Remove(hash);

                    // Determine new free region size
                    uint newOffset = alloc.offset;
                    uint newSize = alloc.size;

#if STATS_ALLOCATOR_ORIGINAL
                    stats.FreeSum += newSize;
#endif

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

#if STATS_ALLOCATOR_ORIGINAL
                        stats.FreeSum -= newSize;
#endif

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

                // Update components based on allocation
                originalOffset.ValueRW.Value = 0;
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

#if STATS_ALLOCATOR_ORIGINAL
        private void updateHeapStats(ref OriginalVoxelHeapStats stats)
        {
            stats.TotalAllocations = allocations.Count();
            stats.UniqueAllocations = stats.TotalAllocations - stats.SharedAllocations;
            stats.SharedMemoryVolumes = stats.SharedMemoryVolumeRiders + stats.SharedAllocations;

            stats.UniqueAllocationPercent = stats.TotalAllocations == 0
                ? 0
                : (float)stats.UniqueAllocations / stats.TotalAllocations * 100f;

            stats.UsagePercent = allocationsTail == 0
                ? 0
                : (float)allocationsTail / GlobalConstants.MAX_GLOBAL_ORIGINAL_VOXELS * 100f;

            stats.FragmentationPercent = allocationsTail == 0
                ? 0
                : (float)stats.FreeSum / allocationsTail * 100f;
        }
#endif
    }
}