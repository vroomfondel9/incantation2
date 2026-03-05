using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    public struct GlobalVoxelHeapStats : IComponentData
    {
        // Percent of total memory space used
        public float UsagePercent;

        // Percent of memory space that contains items (so up to the tail of used memory) that is free
        public float FragmentationPercent;
        // Percent of memory allocations that are non-shared
        public float UniqueAllocationPercent;

        // Amount of fragmentation. Does not count tail region of memory.
        public long FreeSum;
        // Number of consumers of shared memory after the primary consumer that requested the memory allocation.
        public long SharedMemoryVolumeRiders;

        // Number of voxel volumed being shared by >1 consumer in total
        public long SharedMemoryVolumes;

        // Total number of volumes being managed (includes shared volumes), which includes both the main memory region for
        // the volume and any in-progress syncing regions
        public long TotalVolumes;

        // Total number of volumes being managed that are shared, with each volume counted once regardless of number of consumers.
        public long SharedAllocations;
        // Total number of volumes being managed that are unshared
        public long UniqueAllocations;
        // Total number of volumes being managed but counting shared volumes only once.
        public long TotalAllocations;
    }
}