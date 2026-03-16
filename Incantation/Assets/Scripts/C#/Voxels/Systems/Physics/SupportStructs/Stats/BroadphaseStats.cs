using Unity.Entities;

namespace Incantation.Engine.Voxels.Systems.Physics.Support
{
    public struct BroadphaseStats : IComponentData
    {
        public int totalBroadphasePairs;

        public int newPairsGenerated;
        public int existingPairsRemoved;
        public int existingPairsUpdated;
        public int totalPairIterations;

        public int broadphaseCellAddsDynamic;
        public int broadphaseCellAddsStatic;

        public int broadphaseCellRemovalsDynamic;
        public int broadphaseCellRemovalsStatic;

        public int countVolumesDidNotUpdateGrid;
        public int countVolumesUpdatedGrid;

        public int numDynamicVolumes;
        public int numStaticVolumes;

        public int totalDynamicVolumeCells;
        public int totalStaticVolumeCells;

        /*
         * 1 – 4 cells per body → excellent
            4 – 8 cells → acceptable
            8 – 20 cells → grid too small
            20+ cells → grid is badly wrong
        */

        public float AvgCellsPerVolumeDynamic;
        public float AvgCellsPerVolumeStatic;

        /*
         * 2–8 → normal
            10–20 → large body
            50+ → something is very wrong
        */
        public int maxCellsPerVolumeDynamic;
        public int maxCellsPerVolumeStatic;

        /*
         * <5% → excellent
            5–20% → normal
            20–50% → heavy movement
            >50% → something unusual
        */
        public float updateRateDynamicPercent;
    }
}