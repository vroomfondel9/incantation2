using Unity.Entities;

namespace Incantation.Engine.Voxels.Components.Debug
{
    public struct DebugCollisionComponent : IComponentData
    {
        public uint sphereCollisions;
        public uint aabbCollisions;
        public uint obbCollisions;
    }
}