using Unity.Entities;

namespace Incantation.Engine.Voxels.Systems.Physics.Support
{
    public struct PhysicsSolverStatsThreadLocal
    {
        public uint broadphaseCellAddsDynamic;
        public uint broadphaseCellRemovalsDynamic;

        public uint broadphaseCellAddsStatic;
        public uint broadphaseCellRemovalsStatic;

        public uint countVolumesDidNotUpdateGrid;
        public uint countVolumesUpdatedGrid;

        public int numDynamicVolumes;
        public int numStaticVolumes;

        public int totalDynamicVolumeCells;
        public int totalStaticVolumeCells;

        public uint maxCellsPerVolumeDynamic;
        public uint maxCellsPerVolumeStatic;
    }
}