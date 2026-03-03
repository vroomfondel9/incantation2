using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    // Indicates if GPU reallocation is potentially needed. This could happen if:
    // -It hasn't been allocated yet
    // -It needs to be copied from shared memory to per-volume memory prior to modification
    // -It's dimensions have changed
    //
    // Note that modifications within a per-voxel volume space should not need reallocation
    // as long as the dimensions don't change.
    public struct NeedsGPUReallocation : IComponentData, IEnableableComponent {}
}