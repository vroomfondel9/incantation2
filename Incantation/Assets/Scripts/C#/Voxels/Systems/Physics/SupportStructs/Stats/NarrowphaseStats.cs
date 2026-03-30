using Unity.Entities;

namespace Incantation.Engine.Voxels.Systems.Physics.Support
{
    public struct NarrowphaseStats : IComponentData
    {
        public int startingPairs;

        public int eliminatedBySphereCheck;

        public int eliminatedByAABBCheck;

        public int eliminatedByOBBCheck;

        public float sphereCheckFilterRate;

        public float aabbCheckFilterRate;

        public float obbCheckFilterRate;

        public int voxelCheckPairs;

        public float voxelCheckRate;
    }
}