using Incantation.Engine.Voxels.Authoring;
using Incantation.Engine.Voxels.Components;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Rendering;
using UnityEngine;
using UnityEngine.Rendering;

namespace Incantation.Engine.Voxels.Baking
{
    public class VoxelVolumePrebakedAssetAuthoringBaker
        : Baker<VoxelVolumePrebakedAssetAuthoring>
    {
        public override void Bake(VoxelVolumePrebakedAssetAuthoring authoring)
        {
            var entity = GetEntity(TransformUsageFlags.Renderable);

            // Create components
            int3 dims = authoring.voxelVolumePrebakedAsset.dimensions;
            ulong hash = authoring.voxelVolumePrebakedAsset.hash;
            AddComponent(entity, new VoxelVolumeID
            {
                Dimensions = new uint3((uint)dims.x, (uint)dims.y, (uint)dims.z),
                Hash = hash
            });

            // Add Dynamic Buffer Components
            int size = dims.x * dims.y * dims.z;
            var buffer = AddBuffer<InitializationColorTopologyPackedVoxel>(entity);
            buffer.EnsureCapacity(size);

            foreach (uint packedVoxelValue in authoring.voxelVolumePrebakedAsset.packedValues)
            {
                buffer.Add(new InitializationColorTopologyPackedVoxel { PackedValue = packedVoxelValue });
            }
        }
    }
}