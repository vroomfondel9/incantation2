using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    // Indicates if voxel volume is dynamic, implying it moves subject to forces, has a non-infinite mass, etc
    // Contrast with static / kinematic
    public struct IsDynamic : IComponentData, IEnableableComponent { }
}