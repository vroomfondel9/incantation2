using Unity.Entities;

namespace Incantation.Engine.Voxels.Systems.Physics.Support
{
    public struct BroadphaseStatsThreadLocal
    {
        public int broadphaseCellAdds;
        public int broadphaseCellRemovals;

        public int countVolumesDidNotUpdateGrid;
        public int countVolumesUpdatedGrid;

        public int numVolumes;

        public int totalVolumeCells;

        public int maxCellsPerVolume;
    }
}