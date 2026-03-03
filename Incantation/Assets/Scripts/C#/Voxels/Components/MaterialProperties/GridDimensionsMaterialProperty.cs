using Unity.Entities;
using Unity.Mathematics;
using Unity.Rendering;

namespace Incantation.Engine.Voxels.Components
{
    [MaterialProperty("_GridDimensions")]
    public struct GridDimensionsMaterialProperty : IComponentData
    {
        public float3 Value;
    }
}