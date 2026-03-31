using global::System.Runtime.CompilerServices;
using Unity.Entities;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components
{
    public struct OriginalTopology
    {
        /*
        packedTopologyVoxels

        Stores the topology classification of voxels using 2 bits per voxel.

        Layout strategy:
        - Each uint (32 bits) stores the classification for 16 voxels.
        - Each voxel uses 2 bits representing a TopologyClassification value.
        - Values are packed from MOST significant bits to LEAST significant bits.

        Bit layout of one uint:

        [V0][V1][V2]...[V14][V15]
        31..30 29..28 ... 3..2 1..0

        Where each Vn is a 2-bit TopologyClassification value.

        Example (first 4 voxels stored):

        CORNER FACE EDGE EMPTY

        Binary representation:

        01 10 11 00 000000000000000000000000

        This allows:
        - 16 voxel classifications per uint
        - Fast extraction using shifts and masks
        - Minimal memory usage (0.25 bytes per voxel)
        */
        public BlobArray<uint> packedTopologyVoxels;

        /*
        cornerCoords

        Stores sparse coordinates of voxels classified as CORNER.

        Each coordinate is packed into a single int using 3 bytes:

        [unused][x][y][z]

        Bit layout:

        31..24  23..16  15..8  7..0
         unused   x       y     z

        x, y, z are each 8-bit values (0–255).

        This allows coordinates within a 256³ voxel volume
        to be stored in a single 32-bit integer.

        Coordinates can be unpacked with simple bit shifts and masks.
        */
        public BlobArray<int> cornerCoords;

        /*
        edgeCoords

        Same packing strategy as cornerCoords.

        Stores sparse coordinates of voxels classified as EDGE.

        Packing layout:

        [unused][x][y][z]

        31..24  23..16  15..8  7..0
         unused   x       y     z

        This allows efficient iteration over edge voxels without
        scanning the full voxel volume.
        */
        public BlobArray<int> edgeCoords;

        /*
        Retrieves the TopologyClassification of a voxel at the given coordinate.

        Steps:
        1. Convert the 3D coordinate to a flattened voxel index.
        2. Determine which uint contains the 2-bit classification.
        3. Extract the correct 2-bit region using bit shifts.
        4. Map that value to the TopologyClassification enum.

        The packedTopologyVoxels array stores 16 voxels per uint,
        so the index math uses fast bit operations:

        voxelIndex >> 4  == voxelIndex / 16
        voxelIndex & 15  == voxelIndex % 16
        */
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public TopologyClassification getTopologyAt(int3 coord, int width, int height)
        {
            // Convert 3D coordinate to flattened voxel index.
            // Layout: X fastest, then Y, then Z.
            int voxelIndex = coord.x + coord.y * width + coord.z * width * height;

            // Determine which packed uint contains the voxel classification.
            // Each uint holds 16 voxel values.
            int packedIndex = voxelIndex >> 4;     // divide by 16
            int subIndex = voxelIndex & 15;        // modulo 16

            // Load the packed value.
            uint packedValue = packedTopologyVoxels[packedIndex];

            // Because values are packed from MSB to LSB,
            // we reverse the index when computing the shift.
            int shift = (15 - subIndex) << 1;     // (15 - subIndex) * 2 bits

            // Extract the 2-bit classification value.
            uint value = (packedValue >> shift) & 0x3;

            return (TopologyClassification)value;
        }

        /*
        Packs x, y, z coordinates into a single 32-bit integer.

        Packing layout:

        [unused][x][y][z]

        31..24  23..16  15..8  7..0

        x, y, z must be within 0–255.

        This compact representation allows coordinates to be stored
        efficiently inside BlobArrays and quickly unpacked later.
        */
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static int PackCoords(int x, int y, int z)
        {
            return (x << 16) | (y << 8) | z;
        }

        /*
        Overload of PackCoords accepting an int3.
        */
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static int PackCoords(int3 v)
        {
            return (v.x << 16) | (v.y << 8) | v.z;
        }

        /*
        Unpacks a packed coordinate back into an int3.

        Reverse of PackCoords.

        Extracts x, y, z by shifting and masking the packed integer.
        */
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static int3 UnpackCoords(int packed)
        {
            return new int3(
                (packed >> 16) & 0xFF,
                (packed >> 8) & 0xFF,
                packed & 0xFF
            );
        }

        /*
        Converts a packed coordinate directly into a flattened voxel index.

        This avoids constructing an intermediate int3 when only the flat
        index is needed.

        Flattening formula:

        index = x + y * width + z * width * height
        */
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static int ToFlattenedIndex(int packed, int width, int height)
        {
            return ((packed >> 16) & 0xFF) +
                ((packed >> 8) & 0xFF) * width +
                (packed & 0xFF) * width * height;
        }

        /*
        Converts a flattened voxel index back into a packed coordinate.

        Inverse of ToFlattenedIndex().

        Unflattening formula:

        slice = width * height

        z = index / slice
        remainder = index % slice

        y = remainder / width
        x = remainder % width

        The resulting x,y,z values are then packed using the same
        [x][y][z] byte layout:

        31..24  23..16  15..8  7..0
        unused     x      y     z
        */
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static int FromFlattenedIndex(int index, int width, int height)
        {
            int slice = width * height;

            int z = index / slice;
            int remainder = index - z * slice;

            int y = remainder / width;
            int x = remainder - y * width;

            return (x << 16) | (y << 8) | z;
        }
    }
}