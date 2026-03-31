using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    // In cases of shared, unmodified voxel data, indicates that this entity is responsible
    // for making sure the voxel data is uploaded to both the CPU and GPU. This avoids the
    // wasted work that would otherwise happen with multiple entities uploading the same data if
    // loading at the same time.
    public struct ShouldUploadVoxelData : IComponentData, IEnableableComponent { }
}