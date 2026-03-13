using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    // Indicates if voxel volume has been initially recorded in the Broadphase per-frame buffers
    public struct IsBroadphaseRecorded : IComponentData, IEnableableComponent { }
}