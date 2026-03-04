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
            var entity = GetEntity(TransformUsageFlags.Dynamic);

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

            // Add clone offsets in a cube if count > 1
            if (authoring.count > 1)
            {
                long cloneCount = authoring.count - 1;

                var cloneBuffer = AddBuffer<InitializationCloneOffset>(entity);
                cloneBuffer.EnsureCapacity((int)math.min(cloneCount, int.MaxValue));

                // Determine cubic grid size
                int cubeSize = (int)math.ceil(math.pow(authoring.count, 1f / 3f));

                // Determine spacing so volumes do not overlap
                // Use voxel dimensions scaled by VOXEL_SCALE
                float3 voxelDims = new float3(
                    authoring.voxelVolumePrebakedAsset.dimensions.x,
                    authoring.voxelVolumePrebakedAsset.dimensions.y,
                    authoring.voxelVolumePrebakedAsset.dimensions.z
                );

                float3 spacing = voxelDims * GlobalConstants.VOXEL_SCALE;

                long added = 0;

                for (int x = 0; x < cubeSize && added < cloneCount; x++)
                {
                    for (int y = 0; y < cubeSize && added < cloneCount; y++)
                    {
                        for (int z = 0; z < cubeSize && added < cloneCount; z++)
                        {
                            // Skip the origin (that's the original entity)
                            if (x == 0 && y == 0 && z == 0)
                                continue;

                            float3 offset = new float3(
                                x * spacing.x,
                                y * spacing.y,
                                z * spacing.z
                            );

                            cloneBuffer.Add(new InitializationCloneOffset
                            {
                                Offset = offset
                            });

                            added++;
                        }
                    }
                }
            }
        }
    }
}