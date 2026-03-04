using Unity.Entities;
using System.Runtime.CompilerServices;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components
{
    // Used for efficiently spawning multiple copies of the same entity. You specify the offset from the
    // original entity (which functions like a prefab basically). This avoids doing things like copying voxel
    // data multiple times, etc. and cloning lives as part of the normal spawning data flow.
    public struct InitializationCloneOffset : IBufferElementData
    {
        public float3 Offset;
    }
}