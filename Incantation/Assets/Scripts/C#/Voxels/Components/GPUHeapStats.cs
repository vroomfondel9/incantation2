using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    public struct GPUHeapStats : IComponentData
    {
        public float UsagePercent;
        public float FragmentationPercent;
        public float UniqueAllocationPercent;

        public long FreeSum;
        public long SharedMemoryVolumeRiders;

        public long SharedMemoryVolumes;
        public long TotalVolumes;
        public long SharedAllocations;
        public long UniqueAllocations;
        public long TotalAllocations;
    }
}