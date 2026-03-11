using Unity.Entities;

namespace Incantation.Engine.Voxels.Components
{
    /// <summary>
    /// Holds the dimension information for unmodified voxel volumes. These are read-only
    /// and implicitly sharable. Modifiable subregions are stored separately as deltas of the original.
    ///
    /// OriginalDimensions packing (uint):
    /// [ unused ][   X   ][   Y   ][   Z   ]
    ///   31-24      23-16     15-8      7-0
    ///
    /// Each dimension is 0–255. The most significant byte is unused.
    /// </summary>
    public struct OriginalDimensions : IComponentData
    {
        public uint packedValue;

        public OriginalDimensions(uint x, uint y, uint z)
        {
            packedValue = (x << 16) | (y << 8) | z;
        }

        public static uint Pack(uint x, uint y, uint z)
            => (x << 16) | (y << 8) | z;

        public static uint GetX(uint packed)
            => (packed >> 16) & 0xFF;

        public static uint GetY(uint packed)
            => (packed >> 8) & 0xFF;

        public static uint GetZ(uint packed)
            => packed & 0xFF;

        public uint X => (packedValue >> 16) & 0xFF;
        public uint Y => (packedValue >> 8) & 0xFF;
        public uint Z => packedValue & 0xFF;

        public uint Size =>
            ((packedValue >> 16) & 0xFF) *
            ((packedValue >> 8) & 0xFF) *
            (packedValue & 0xFF);
    }
}