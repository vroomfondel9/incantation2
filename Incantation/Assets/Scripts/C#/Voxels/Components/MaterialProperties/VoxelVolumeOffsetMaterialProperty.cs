using Unity.Entities;
using Unity.Rendering;

namespace Incantation.Engine.Voxels.Components
{
    [MaterialProperty("_VoxelVolumeOffset")]
    public struct VoxelVolumeOffsetMaterialProperty : IComponentData
    {
        public float Value;
    }
}