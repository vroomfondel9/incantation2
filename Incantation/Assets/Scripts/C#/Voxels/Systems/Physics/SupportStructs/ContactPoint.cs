using System;
using Unity.Entities;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Systems.Physics.Support
{
    public struct ContactPoint
    {
        public Entity A;
        public Entity B;
        public int3 coordsA;
        public int3 coordsB;
        public float3 normal;
        public float penetration;
        // Linear value between [0-1] where 0 is exactly last simulation step and 1 is exactly this simulation step
        public float time;
    }
}