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
    }
}