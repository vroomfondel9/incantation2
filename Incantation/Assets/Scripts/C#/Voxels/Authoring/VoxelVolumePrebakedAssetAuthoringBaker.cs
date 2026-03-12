using Incantation.Engine.Voxels.Authoring;
using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Rendering;
using UnityEditor.PackageManager;
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

            // Create identity components
            int3 dims = authoring.voxelVolumePrebakedAsset.dimensions;
            ulong hash = authoring.voxelVolumePrebakedAsset.hash;
            AddComponent(entity, new OriginalVoxelVolumeID
            {
                Hash = hash
            });
            AddComponent(entity, new GridDimensions((uint)dims.x, (uint)dims.y, (uint)dims.z));

            // Physics
            float invMass = authoring.voxelVolumePrebakedAsset.inverseMass;
            float3 invInertia = new float3(
                authoring.voxelVolumePrebakedAsset.inverseInertia.x,
                authoring.voxelVolumePrebakedAsset.inverseInertia.y,
                authoring.voxelVolumePrebakedAsset.inverseInertia.z
            );
            float3 com = new float3(
                authoring.voxelVolumePrebakedAsset.centerOfMass.x,
                authoring.voxelVolumePrebakedAsset.centerOfMass.y,
                authoring.voxelVolumePrebakedAsset.centerOfMass.z
            );
            AddComponent(entity, new PhysicsMass
            {
                InverseMass = invMass,
                InverseInertia = invInertia,
                CenterOfMass = com
            });

            // Add Dynamic Buffer Component for individual voxels
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
                long cloneCount = authoring.count;

                var cloneBuffer = AddBuffer<InitializationCloneOffset>(entity);
                cloneBuffer.EnsureCapacity((int)math.min(cloneCount, int.MaxValue));

                generateCubicCloneOffsets(authoring, cloneBuffer);
            }
        }

        private void generateCubicCloneOffsets(VoxelVolumePrebakedAssetAuthoring authoring, 
            DynamicBuffer<InitializationCloneOffset> cloneBuffer)
        {
            long cloneCount = authoring.count;

            // Determine cubic grid size
            int cubeSize = (int)math.ceil(math.pow(authoring.count, 1f / 3f));

            // Determine spacing so volumes do not overlap
            // Use voxel dimensions scaled by VOXEL_SCALE
            float3 voxelDims = new float3(
                authoring.voxelVolumePrebakedAsset.dimensions.x,
                authoring.voxelVolumePrebakedAsset.dimensions.y,
                authoring.voxelVolumePrebakedAsset.dimensions.z
            );

            float3 spacingObjSize = voxelDims * GlobalConstants.VOXEL_SCALE;
            float3 spacingGaps = new float3(authoring.spacing.x, authoring.spacing.y, authoring.spacing.z);
            float3 spacingTotal = spacingObjSize + spacingGaps;

            float3 worldOffsets = spacingTotal * ((cubeSize - 1) * 0.5f);

            long added = 0;

            for (int x = 0; x < cubeSize && added < cloneCount; x++)
            {
                for (int y = 0; y < cubeSize && added < cloneCount; y++)
                {
                    for (int z = 0; z < cubeSize && added < cloneCount; z++)
                    {
                        float3 offset = new float3(x, y, z) * spacingTotal - worldOffsets;

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