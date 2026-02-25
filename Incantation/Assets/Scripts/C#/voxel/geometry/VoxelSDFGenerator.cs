using UnityEngine;
using UnityEngine.Experimental.Rendering;
using System;
using UnityEngine.UI;

public static class VoxelSDFGenerator
{
    public static float FILLED_ALPHA_THRESHOLD = 0.5f;

    /// <summary>
    /// Generates a Manhattan distance field (6-connected) from a 3D RGBA texture.
    /// Filled voxels (alpha > threshold) get value 0.
    /// Empty voxels get distance to nearest filled voxel OR grid boundary.
    /// Output is a 1-byte R8 Texture3D.
    /// </summary>
    public static Texture3D GenerateManhattanDistanceField(
        Texture3D source, out TOPOLOGY_COUNTS topologyCounts)
    {
        if (source == null)
            throw new ArgumentNullException(nameof(source));

        int width = source.width;
        int height = source.height;
        int depth = source.depth;

        int total = width * height * depth;

        // Get source colors (must be readable)
        Color32[] src = source.GetPixels32();
        if (src == null || src.Length != total)
            throw new Exception("Failed to read Texture3D pixel data. Make sure it's readable.");

        // Distance buffer (int for transform phase)
        int[] dist = new int[total];

        // Only non-zero for edges. For edges, it has a value where the last 6 bits are set like:
        // -x +x -y +y -z +z
        // Where each of those bits is 1 if there's an adjascent neighbor in that direction
        int[] neighboringEdgeMasks = new int[total];

        // Large initial value (max possible Manhattan distance in grid)
        int maxDist = width + height + depth;

        // --------------------------------------------
        // Initialization
        // --------------------------------------------
        for (int z = 0; z < depth; z++)
        {
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    int i = Index(x, y, z, width, height);

                    bool filled = src[i].a > FILLED_ALPHA_THRESHOLD * 255f;

                    if (filled)
                        dist[i] = 0;
                    else
                        dist[i] = maxDist;

                    neighboringEdgeMasks[i] = 0;
                }
            }
        }

        // --------------------------------------------
        // Forward pass
        // --------------------------------------------
        for (int z = 0; z < depth; z++)
        {
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    int i = Index(x, y, z, width, height);
                    int d = dist[i];
                    int m = neighboringEdgeMasks[i];
                    int n;

                    if (x > 0)
                    {
                        n = dist[Index(x - 1, y, z, width, height)];
                        d = Mathf.Min(d, n + 1);
                        m |= (n == 0 ? 1 : 0) << 5;
                    }

                    if (y > 0)
                    {
                        n = dist[Index(x, y - 1, z, width, height)];
                        d = Mathf.Min(d, n + 1);
                        m |= (n == 0 ? 1 : 0) << 3;
                    }

                    if (z > 0)
                    {
                        n = dist[Index(x, y, z - 1, width, height)];
                        d = Mathf.Min(d, n + 1);
                        m |= (n == 0 ? 1 : 0) << 1;
                    }

                    dist[i] = d;
                    neighboringEdgeMasks[i] = m;
                }
            }
        }

        // --------------------------------------------
        // Backward pass
        // --------------------------------------------
        for (int z = depth - 1; z >= 0; z--)
        {
            for (int y = height - 1; y >= 0; y--)
            {
                for (int x = width - 1; x >= 0; x--)
                {
                    int i = Index(x, y, z, width, height);
                    int d = dist[i];
                    int m = neighboringEdgeMasks[i];
                    int n;

                    if (x < width - 1)
                    {
                        n = dist[Index(x + 1, y, z, width, height)];
                        d = Mathf.Min(d, n + 1);
                        m |= (n == 0 ? 1 : 0) << 4;
                    }

                    if (y < height - 1)
                    {
                        n = dist[Index(x, y + 1, z, width, height)];
                        d = Mathf.Min(d, n + 1);
                        m |= (n == 0 ? 1 : 0) << 2;
                    }

                    if (z < depth - 1)
                    {
                        n = dist[Index(x, y, z + 1, width, height)];
                        d = Mathf.Min(d, n + 1);
                        m |= (n == 0 ? 1 : 0) << 0;
                    }

                    dist[i] = d;
                    neighboringEdgeMasks[i] = m;
                }
            }
        }

        // --------------------------------------------
        // Final Pass to Merge, Cap, Normalize Values
        // And count topology features
        // --------------------------------------------
        topologyCounts = new TOPOLOGY_COUNTS();
        for (int z = depth - 1; z >= 0; z--)
        {
            for (int y = height - 1; y >= 0; y--)
            {
                for (int x = width - 1; x >= 0; x--)
                {
                    int i = Index(x, y, z, width, height);
                    int d = dist[i];
                    int m = neighboringEdgeMasks[i];

                    // Pack SDF and Topology mask values together
                    // Max SDF distance becomes 192 to make room for the 63 possible values of the topology mask
                    m *= ((d == 0) ? 1 : 0);
                    if (d > 192) d = 192;
                    int packedValue = d + (63 - m);

                    dist[i] = packedValue;

                    // Analyze topology and update counts
                    int bothDirsFilledZDim = ((m & 3u) == 3u) ? 1 : 0;
                    int bothDirsFilledYDim = ((m & 12u) == 12u) ? 1 : 0;
                    int bothDirsFilledXDim = ((m & 48u) == 48u) ? 1 : 0;

                    int numDimsWithBothDirsFilled = bothDirsFilledZDim + bothDirsFilledYDim + bothDirsFilledXDim;

                    if (d == 0)
                    {
                        if (numDimsWithBothDirsFilled == 0) topologyCounts.corners++;
                        if (numDimsWithBothDirsFilled == 1) topologyCounts.edges++;
                        if (numDimsWithBothDirsFilled == 2) topologyCounts.faces++;
                        if (numDimsWithBothDirsFilled == 3) topologyCounts.interiors++;
                    }
                    else if (d > 0)
                    {
                        topologyCounts.empties++;
                    }
                }
            }
        }

        topologyCounts.total = topologyCounts.corners + topologyCounts.edges + topologyCounts.faces + topologyCounts.interiors + topologyCounts.empties;
        if (topologyCounts.total != total)
            throw new Exception("Mismatch between number of classified topology voxels and total voxels in volume.");

        // --------------------------------------------
        // Convert to 1-byte texture
        // --------------------------------------------
        byte[] resultBytes = new byte[total];

        for (int i = 0; i < total; i++)
        {
            // Clamp to 255 since output is 1 byte
            resultBytes[i] = (byte)Mathf.Min(dist[i], 255);
        }

        Texture3D result = new Texture3D(
            width,
            height,
            depth,
            GraphicsFormat.R8_UNorm,
            TextureCreationFlags.None);

        result.filterMode = FilterMode.Point;
        result.wrapMode = TextureWrapMode.Clamp;

        result.SetPixelData(resultBytes, 0);
        result.Apply(false, false);

        return result;
    }

    private static int Index(int x, int y, int z, int width, int height)
    {
        return x + y * width + z * width * height;
    }
}
