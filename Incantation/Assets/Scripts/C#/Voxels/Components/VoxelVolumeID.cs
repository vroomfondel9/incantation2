using Unity.Entities;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components
{
    /// <summary>
    /// Uniquely identifies a voxel volume.
    ///
    /// Identity is determined by:
    ///  - Grid dimensions (uint3)
    ///  - A deterministic 64-bit content hash of:
    ///        * Grid dimensions
    ///        * Entire voxel grid contents (everything in the packed value)
    ///
    /// Since grid dimensions are baked into hash, checking only hash is sufficient for equality checks.
    /// 
    /// Data flow:
    /// This is filled as part of topology scanning whenever a new voxel volume is spawned or an existing one
    /// is modified.
    /// </summary>
    public struct VoxelVolumeID : IComponentData
    {
        /// <summary>
        /// Dimensions of the voxel grid.
        /// </summary>
        public uint3 Dimensions;

        /// <summary>
        /// 64-bit FNV-1a hash of:
        ///   - Dimensions
        ///   - Entire voxel buffer contents (PackedValue stream)
        ///
        /// FNV-1a is a fast, non-cryptographic hashing algorithm
        /// chosen for:
        ///   - Determinism
        ///   - Excellent bit dispersion
        ///   - Low collision probability for large binary data
        ///   - Burst-friendly performance in hot loops
        ///
        /// Offset basis: 1469598103934665603
        /// Prime:        1099511628211
        /// </summary>
        public ulong Hash;
    }
}