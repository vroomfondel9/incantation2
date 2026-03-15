using Unity.Mathematics;
using System;

namespace Incantation.Engine.Voxels.Systems.Physics.Support
{
    // Used to hold cell -> entity mappings for fast lookup during broadphase collision detection
    public struct BroadphaseCell : IEquatable<BroadphaseCell>
    {
        // Signed grid coordinates
        public int x;
        public int y;
        public int z;

        // Morton key used for hashing
        public uint Morton;

        private const float SQRT3 = 1.7320508f;
        private const uint SAFETY_MARGIN = 0;       // In case items actually extend slightly out of bounds and haven't been corrected by boundary systems yet (such as mid solver, etc)

        private const int MORTON_AXIS_BITS = 10;
        private const int MORTON_AXIS_SIZE = 1 << MORTON_AXIS_BITS;   // 1024

        private static readonly float MAX_EXTENTS_SIZE_WORLD =
            GlobalConstants.VOXEL_SCALE * GlobalConstants.MAX_VOXEL_SIZE_PER_DIM / 2.0f;

        // Perfect diagonal rotation case
        private static readonly float WORST_CASE_AABB_EXTENTS =
            MAX_EXTENTS_SIZE_WORLD * SQRT3;

        private static readonly float MAX_DIST_AABB_CAN_EXTEND_OUTSIDE_GRID =
            WORST_CASE_AABB_EXTENTS - MAX_EXTENTS_SIZE_WORLD;

        private static readonly uint NEGATIVE_SPACE_TO_RESERVE =
            ((uint)math.ceil(MAX_DIST_AABB_CAN_EXTEND_OUTSIDE_GRID /
                GlobalConstants.BROADPHASE_GRID_CELL_SIZE))
                    + SAFETY_MARGIN;

        private const uint MORTON_MAX_COORD = MORTON_AXIS_SIZE - 1;

        public BroadphaseCell(int x, int y, int z)
        {
            this.x = x;
            this.y = y;
            this.z = z;

            uint ex = EncodeSigned(x);
            uint ey = EncodeSigned(y);
            uint ez = EncodeSigned(z);

            Morton = EncodeMorton(ex, ey, ez);
        }

        public bool Equals(BroadphaseCell other)
        {
            return Morton == other.Morton;
        }

        public override int GetHashCode()
        {
            return (int)Morton;
        }

        // ---------------------------------------------------------
        // Morton Space Helpers
        // ---------------------------------------------------------

        private static uint EncodeSigned(int value)
        {
            return (uint)(value + NEGATIVE_SPACE_TO_RESERVE);
        }

        private static int DecodeSigned(uint value)
        {
            return (int)value - (int)NEGATIVE_SPACE_TO_RESERVE;
        }

        /// <summary>
        /// Returns true if the given signed coordinates can be represented
        /// inside the 10-bit Morton axis space.
        /// </summary>
        public static bool IsWithinMortonSpace(int x, int y, int z)
        {
            int min = -(int)NEGATIVE_SPACE_TO_RESERVE;
            int max = (int)MORTON_MAX_COORD - (int)NEGATIVE_SPACE_TO_RESERVE;

            return
                x >= min && x <= max &&
                y >= min && y <= max &&
                z >= min && z <= max;
        }

        // ---------------------------------------------------------
        // Morton Encoding
        // ---------------------------------------------------------

        static uint Part1By2(uint n)
        {
            n &= 0x000003ff;
            n = (n ^ (n << 16)) & 0xff0000ff;
            n = (n ^ (n << 8)) & 0x0300f00f;
            n = (n ^ (n << 4)) & 0x030c30c3;
            n = (n ^ (n << 2)) & 0x09249249;
            return n;
        }

        public static uint EncodeMorton(uint x, uint y, uint z)
        {
            return Part1By2(x) |
                   (Part1By2(y) << 1) |
                   (Part1By2(z) << 2);
        }

        static uint Compact1By2(uint n)
        {
            n &= 0x09249249;
            n = (n ^ (n >> 2)) & 0x030c30c3;
            n = (n ^ (n >> 4)) & 0x0300f00f;
            n = (n ^ (n >> 8)) & 0xff0000ff;
            n = (n ^ (n >> 16)) & 0x000003ff;
            return n;
        }

        /// <summary>
        /// Decode Morton code back into signed grid coordinates.
        /// </summary>
        public static int3 DecodeMorton(uint code)
        {
            uint ux = Compact1By2(code);
            uint uy = Compact1By2(code >> 1);
            uint uz = Compact1By2(code >> 2);

            return new int3(
                DecodeSigned(ux),
                DecodeSigned(uy),
                DecodeSigned(uz)
            );
        }
    }
}