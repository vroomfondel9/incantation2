using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    // Indicates if Voxel Data needs to be synced
    public struct GlobalVoxelSyncNeeded : IComponentData, IEnableableComponent { }
}