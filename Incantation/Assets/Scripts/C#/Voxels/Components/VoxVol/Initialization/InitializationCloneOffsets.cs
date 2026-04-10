using Unity.Entities;
using System.Runtime.CompilerServices;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components
{
    // Used for efficiently spawning multiple copies of the same entity. You specify the offsets from the
    // original entity (which functions like a prefab basically). This avoids doing things like copying voxel
    // data multiple times, etc. and cloning lives as part of the normal spawning data flow.
    public struct InitializationCloneOffsets : IBufferElementData
    {
        public float3 Position;
        public float3 VelocityLinear;
        public float3 VelocityAngular;
    }
}