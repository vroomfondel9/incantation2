using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    // Flags volume as ready for deletion, giving all systems one frame to clean up this volume's resources.
    // Should be deleted very late in system order to ensure other systems have a chance to clean up.
    public struct NeedsDeletion : IComponentData, IEnableableComponent { }
}