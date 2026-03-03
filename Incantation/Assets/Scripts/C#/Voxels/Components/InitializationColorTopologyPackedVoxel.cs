using Unity.Entities;
using System.Runtime.CompilerServices;

namespace Incantation.Engine.Voxels.Components
{
    /// <summary>
    /// Voxel
    /// =====
    ///
    /// Packed 32-bit representation of a voxel.
    ///
    /// Layout (LSB → MSB):
    ///
    /// Bits  0–7   : Topology byte (R8 UNorm in texture world)
    /// Bits  8–31  : RGB24 color (R8 | G8 | B8)
    ///
    /// ------------------------------------------------------------
    /// TOPOLOGY BYTE ENCODING
    /// ------------------------------------------------------------
    ///
    /// The topology byte has two conceptual regions:
    ///
    /// 0–63  : Reserved for neighbor information of FILLED voxels.
    /// 64–254: Signed distance field (SDF) values.
    /// 255   : Indefinite SDF value.
    ///
    /// Internally we compute:
    ///
    ///     signedValue = (topology - 63)
    ///
    /// If signedValue > 0:
    ///     → Empty voxel.
    ///     → Represents SDF distance.
    ///     → SDF = signedValue.
    ///     → 255 results in signedValue = 192 (maximum possible SDF).
    ///       This is considered an "indefinite SDF value".
    ///
    /// If signedValue <= 0:
    ///     → Filled voxel.
    ///     → Neighbor bitfield is:
    ///           neighborBits = -signedValue   (range 0–63)
    ///
    /// Neighbor bit layout (6 bits):
    ///
    /// Bit 0 : -X
    /// Bit 1 : +X
    /// Bit 2 : -Y
    /// Bit 3 : +Y
    /// Bit 4 : -Z
    /// Bit 5 : +Z
    ///
    /// A bit value of 1 indicates a filled neighbor in that direction.
    /// A bit value of 0 indicates empty in that direction.
    ///
    /// Higher-level topology classification:
    ///
    /// Count how many dimensions have BOTH positive and negative neighbor bits set.
    /// Let dimensionPairCount be:
    ///
    ///   X dimension → (-X AND +X)
    ///   Y dimension → (-Y AND +Y)
    ///   Z dimension → (-Z AND +Z)
    ///
    /// Then:
    ///
    ///   dimensionPairCount == 0 → Corner
    ///   dimensionPairCount == 1 → Edge
    ///   dimensionPairCount == 2 → Face
    ///   dimensionPairCount == 3 → Interior
    ///
    /// ------------------------------------------------------------
    /// PERFORMANCE NOTES
    /// ------------------------------------------------------------
    ///
    /// - Designed for extremely hot loops.
    /// - All methods are static and aggressively inlined.
    /// - Avoid calling high-level helpers inside inner-most loops
    ///   if manual bit logic is faster in your specific job.
    /// - Operate directly on PackedValue (uint) in tight loops.
    /// 
    /// TODO OPT - LOW - Branchless Voxel Helper Functions - Helper functions are very hot. Make branchless if possible. Low because Burst probably does this already automatically.
    /// </summary>
    public struct InitializationColorTopologyPackedVoxel : IBufferElementData
    {
        public uint PackedValue;

        private const uint TOPO_MASK = 0xFFu;
        private const uint COLOR_MASK = 0xFFFFFF00u;

        private const int TOPO_OFFSET = 63;

        // ------------------------------------------------------------
        // TOPOLOGY RAW ACCESS
        // ------------------------------------------------------------

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static byte GetTopology(uint packed)
            => (byte)(packed & TOPO_MASK);

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static uint SetTopology(uint packed, byte topo)
            => (packed & COLOR_MASK) | topo;

        // ------------------------------------------------------------
        // EMPTY / SDF
        // ------------------------------------------------------------

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool IsEmpty(uint packed)
        {
            int signedValue = (int)((packed & TOPO_MASK) - TOPO_OFFSET);
            return signedValue > 0;
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static int GetSDF(uint packed)
        {
            int signedValue = (int)((packed & TOPO_MASK) - TOPO_OFFSET);
            return signedValue > 0 ? signedValue : 0;
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool IsDefiniteSDFValue(uint packed)
        {
            byte topo = (byte)(packed & TOPO_MASK);
            return topo >= 64 && topo <= 254;
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool IsIndefiniteSDFValue(uint packed)
            => (packed & TOPO_MASK) == 255;

        // ------------------------------------------------------------
        // NEIGHBOR BIT EXTRACTION
        // ------------------------------------------------------------

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static int GetNeighborBitsIfFilled(uint packed)
        {
            int signedValue = (int)((packed & TOPO_MASK) - TOPO_OFFSET);

            // If empty, return 0 (no neighbors).
            if (signedValue > 0)
                return 0;

            return -signedValue;
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool HasNeighborLeft(uint packed)
            => (GetNeighborBitsIfFilled(packed) & (1 << 0)) != 0; // -X

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool HasNeighborRight(uint packed)
            => (GetNeighborBitsIfFilled(packed) & (1 << 1)) != 0; // +X

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool HasNeighborDown(uint packed)
            => (GetNeighborBitsIfFilled(packed) & (1 << 2)) != 0; // -Y

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool HasNeighborUp(uint packed)
            => (GetNeighborBitsIfFilled(packed) & (1 << 3)) != 0; // +Y

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool HasNeighborBackward(uint packed)
            => (GetNeighborBitsIfFilled(packed) & (1 << 4)) != 0; // -Z

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool HasNeighborForward(uint packed)
            => (GetNeighborBitsIfFilled(packed) & (1 << 5)) != 0; // +Z

        // ------------------------------------------------------------
        // HIGH-LEVEL TOPOLOGY CLASSIFICATION
        // ------------------------------------------------------------

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static int CountDimensionPairs(uint packed)
        {
            int bits = GetNeighborBitsIfFilled(packed);

            int count = 0;

            // X dimension
            if ((bits & (1 << 0)) != 0 && (bits & (1 << 1)) != 0) count++;

            // Y dimension
            if ((bits & (1 << 2)) != 0 && (bits & (1 << 3)) != 0) count++;

            // Z dimension
            if ((bits & (1 << 4)) != 0 && (bits & (1 << 5)) != 0) count++;

            return count;
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool IsCorner(uint packed)
            => !IsEmpty(packed) && CountDimensionPairs(packed) == 0;

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool IsEdge(uint packed)
            => !IsEmpty(packed) && CountDimensionPairs(packed) == 1;

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool IsFace(uint packed)
            => !IsEmpty(packed) && CountDimensionPairs(packed) == 2;

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool IsInterior(uint packed)
            => !IsEmpty(packed) && CountDimensionPairs(packed) == 3;

        // ------------------------------------------------------------
        // COLOR (RGB24)
        // ------------------------------------------------------------

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static uint GetRGB24Color(uint packed)
            => packed >> 8;

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static uint SetRGB24Color(uint packed, uint rgb24)
            => (rgb24 << 8) | (packed & TOPO_MASK);

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static byte GetR8(uint packed)
            => (byte)((packed >> 8) & 0xFF);

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static byte GetG8(uint packed)
            => (byte)((packed >> 16) & 0xFF);

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static byte GetB8(uint packed)
            => (byte)((packed >> 24) & 0xFF);

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static uint SetR8(uint packed, byte r)
            => (packed & 0xFFFF00FFu) | ((uint)r << 8);

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static uint SetG8(uint packed, byte g)
            => (packed & 0xFF00FFFFu) | ((uint)g << 16);

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static uint SetB8(uint packed, byte b)
            => (packed & 0x00FFFFFFu) | ((uint)b << 24);
    }
}