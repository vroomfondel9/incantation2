using Unity.Entities;
using System.Runtime.CompilerServices;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components
{
    public struct InitializationTopologyMetadata : IComponentData
    {
        public int cornerCount;
        public int edgeCount;
    }
}