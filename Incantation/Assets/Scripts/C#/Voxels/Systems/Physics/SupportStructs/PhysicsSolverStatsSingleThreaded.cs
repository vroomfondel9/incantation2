using Unity.Entities;

namespace Incantation.Engine.Voxels.Systems.Physics.Support
{
    public struct PhysicsSolverStatsSingleThreaded
    {
        public int totalBroadphasePairs;
        public int newPairsGenerated;
        public int existingPairsRemoved;
        public int existingPairsUpdated;
    }
}