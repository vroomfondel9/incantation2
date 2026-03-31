/*
2-bit classification stored inside packedTopologyVoxels.

Encoding:

00 = EMPTY_OR_INTERIOR
01 = CORNER
10 = FACE
11 = EDGE

These values are packed into packedTopologyVoxels sequentially,
with 16 entries per uint.

This allows Corner vs Corner, Face, and Edge as well as Edge vs Edge
only checks via using the >= operator.

*/
namespace Incantation.Engine.Voxels.Components
{
    public enum TopologyClassification : uint
    {
        EMPTY_OR_INTERIOR = 0,
        CORNER = 1,
        FACE = 2,
        EDGE = 3
    }
}