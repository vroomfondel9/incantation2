using Unity.Entities;

namespace Incantation.Engine.Voxels.Systems.Physics.Support
{
    public struct NarrowphaseStatsThreadLocal
    {
        public int totalPairsFromBroadphase;
        public int spherePassed;
        public int aabbPassed;
        public int obbPassed;
    }
}