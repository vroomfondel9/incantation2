using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    // Indicates if GPU deallocation is needed. This should only happen right before deletion.
    public struct NeedsDeletion : IComponentData, IEnableableComponent { }
}