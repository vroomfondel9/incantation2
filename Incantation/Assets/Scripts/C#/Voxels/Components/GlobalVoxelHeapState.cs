using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    /// <summary>
    /// Identifies the location of this voxel volume inside the global voxel buffers of, managed as a heap.
    ///
    /// Offset:
    ///     Offset in global heap where this volume's voxel data starts
    ///
    /// Shared:
    ///     Indicates whether this allocation is shared between
    ///     multiple voxel volumes (e.g., deduplicated identical grids).
    ///
    /// Data Flow:
    /// This depends on voxel identity (hash) being determined. It's essential for rendering in play mode.
    /// May be reallocated on modification.
    /// </summary>
    public struct GlobalVoxelHeapState : IComponentData
    {
        public uint Offset;

        public uint SyncInProgressOffset;

        public uint Size;

        public uint SyncInProgressSize;

        public bool Shared;

        public bool SyncInProgressShared;

        public bool Allocated;

        public uint FramesUntilSyncSwap;
    }
}