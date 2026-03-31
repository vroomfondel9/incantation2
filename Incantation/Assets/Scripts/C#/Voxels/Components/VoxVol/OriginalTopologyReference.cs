using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    public struct OriginalTopologyReference : IComponentData
    {
        public BlobAssetReference<OriginalTopology> topologyReference;
    }
}