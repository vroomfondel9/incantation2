using UnityEngine;
using UnityEngine.Experimental.Rendering;
using System;

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
        Texture3D source)
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

                    bool boundary =
                        x == 0 || x == width - 1 ||
                        y == 0 || y == height - 1 ||
                        z == 0 || z == depth - 1;

                    if (filled)
                        dist[i] = 0;
                    else if (boundary)
                        dist[i] = 1;
                    else
                        dist[i] = maxDist;
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

                    if (x > 0)
                        d = Mathf.Min(d, dist[Index(x - 1, y, z, width, height)] + 1);

                    if (y > 0)
                        d = Mathf.Min(d, dist[Index(x, y - 1, z, width, height)] + 1);

                    if (z > 0)
                        d = Mathf.Min(d, dist[Index(x, y, z - 1, width, height)] + 1);

                    dist[i] = d;
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

                    if (x < width - 1)
                        d = Mathf.Min(d, dist[Index(x + 1, y, z, width, height)] + 1);

                    if (y < height - 1)
                        d = Mathf.Min(d, dist[Index(x, y + 1, z, width, height)] + 1);

                    if (z < depth - 1)
                        d = Mathf.Min(d, dist[Index(x, y, z + 1, width, height)] + 1);

                    dist[i] = d;
                }
            }
        }

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
