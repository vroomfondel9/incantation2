using Unity.Entities;
using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Authoring;

namespace Incantation.Engine.Voxels.Baking
{
    public class PrebakedVoxelVolumeAuthoringBaker
        : Baker<PrebakedVoxelVolumeAuthoring>
    {
        public override void Bake(PrebakedVoxelVolumeAuthoring authoring)
        {
            // Create entity associated with this GameObject
            var entity = GetEntity(TransformUsageFlags.None);

            // Add simple components
            AddComponent(entity, authoring.voxelVolumeID);
            AddComponent(entity, authoring.gpuHeapVoxelState);

            // Add DynamicBuffer<Voxel>
            var buffer = AddBuffer<Voxel>(entity);

            // Prevent constant resizing as voxels are added
            buffer.EnsureCapacity(authoring.Voxels.Count);

            // Copy voxel data into DynamicBuffer
            foreach (var voxel in authoring.Voxels)
            {
                buffer.Add(voxel);
            }
        }
    }
}