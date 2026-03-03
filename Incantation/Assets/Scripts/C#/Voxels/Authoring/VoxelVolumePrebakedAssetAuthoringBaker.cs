using Unity.Entities;
using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Authoring;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Baking
{
    public class VoxelVolumePrebakedAssetAuthoringBaker
        : Baker<VoxelVolumePrebakedAssetAuthoring>
    {
        public override void Bake(VoxelVolumePrebakedAssetAuthoring authoring)
        {
            // Create entity associated with this GameObject
            var entity = GetEntity(TransformUsageFlags.None);

            // Create components
            int3 dims = authoring.voxelVolumePrebakedAsset.dimensions;
            ulong hash = authoring.voxelVolumePrebakedAsset.hash;
            AddComponent(entity, new VoxelVolumeID
            {
                Dimensions = new uint3((uint)dims.x, (uint)dims.y, (uint)dims.z),
                Hash = hash
            });

            int size = dims.x * dims.y * dims.z;
            AddComponent(entity, new GPUVoxelHeapState
            {
                Offset = 0,
                SyncInProgressOffset = 0,
                Size = (uint)size,
                SyncInProgressSize = 0,
                Shared = false,
                SyncInProgressShared = false,
                Allocated = false,
                FramesUntilSyncSwap = 0,
            });

            // Material properties
            AddComponent(entity, new GridDimensionsMaterialProperty
            {
                Value = new float3((float)dims.x, (float)dims.y, (float)dims.z)
            });

            AddComponent(entity, new VoxelVolumeOffsetMaterialProperty
            {
                Value = 0
            });

            // Enableables
            AddComponent<NeedsGPUReallocation>(entity);
            SetComponentEnabled<NeedsGPUReallocation>(entity, true);

            AddComponent<NeedsGPUDeallocation>(entity);
            SetComponentEnabled<NeedsGPUDeallocation>(entity, false);

            AddComponent<GPUSyncNeeded>(entity);
            SetComponentEnabled<GPUSyncNeeded>(entity, false);

            AddComponent<GPUSyncInProgress>(entity);
            SetComponentEnabled<GPUSyncInProgress>(entity, false);

            AddComponent<NeedsDeletion>(entity);
            SetComponentEnabled<NeedsDeletion>(entity, false);

            // Add Dynamic Buffer Components
            var buffer = AddBuffer<InitializationColorTopologyPackedVoxel>(entity);
            buffer.EnsureCapacity(size);

            foreach (uint packedVoxelValue in authoring.voxelVolumePrebakedAsset.packedValues)
            {
                buffer.Add(new InitializationColorTopologyPackedVoxel { PackedValue = packedVoxelValue });
            }
        }
    }
}