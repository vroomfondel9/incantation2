using Unity.Mathematics;
using System;

namespace Incantation.Engine.Voxels.Systems.Physics.Support
{
    // Used to hold cell -> entity mappings for fast lookup during broadphase collision detection
    public struct BroadphaseCell : IEquatable<BroadphaseCell>
    {
        public uint x;
        public uint y;
        public uint z;

        public uint Morton;

        public BroadphaseCell(uint x, uint y, uint z)
        {
            this.x = x;
            this.y = y;
            this.z = z;
            Morton = EncodeMorton(x, y, z);
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

        public static uint3 DecodeMorton(uint code)
        {
            return new uint3(
                Compact1By2(code),
                Compact1By2(code >> 1),
                Compact1By2(code >> 2)
            );
        }
    }
}