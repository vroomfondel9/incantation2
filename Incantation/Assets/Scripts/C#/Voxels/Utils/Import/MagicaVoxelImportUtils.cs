using UnityEngine;
using UnityEngine.Experimental.Rendering;
using System;
using UnityEngine.UI;

namespace Incantation.Engine.Voxels.Utils.Import
{
    public static class MagicaVoxelImportUtils
    {
        // Prime values used for fast FNV-1a hashing
        private const ulong FNV_OFFSET_BASIS = 14695981039346656037UL;
        private const ulong FNV_PRIME = 1099511628211UL;

        public static float FILLED_ALPHA_THRESHOLD = 0.5f;

        public struct TopologyAnalysisResults
        {
            public int corners;
            public int edges;
            public int faces;
            public int interiors;
            public int empties;
            public int total;
            public ulong hash;
        }

        /// <summary>
        /// Topology is generated using a Manhattan distance field (6-connected) from a 3D RGBA texture.
        /// Topology and color is packed together
        /// Filled voxels (alpha > threshold) get value 0.
        /// Empty voxels get distance to nearest filled voxel OR grid boundary.
        /// Output is a 1-byte R8 Texture3D.
        /// </summary>
        public static uint[] GetPackedValuesFromMagicaVoxelPng(
            Texture3D source, out TopologyAnalysisResults topologyCounts)
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
            uint[] dist = new uint[total];

            // Only non-zero for edges. For edges, it has a value where the last 6 bits are set like:
            // -x +x -y +y -z +z
            // Where each of those bits is 1 if there's an adjascent neighbor in that direction
            uint[] neighboringEdgeMasks = new uint[total];

            // Large initial value (max possible Manhattan distance in grid)
            uint maxDist = (uint)(width + height + depth);

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
                        int d = (int) dist[i];
                        int m = (int) neighboringEdgeMasks[i];
                        int n;

                        if (x > 0)
                        {
                            n = (int) dist[Index(x - 1, y, z, width, height)];
                            d = Mathf.Min(d, n + 1);
                            m |= (n == 0 ? 1 : 0) << 5;
                        }

                        if (y > 0)
                        {
                            n = (int) dist[Index(x, y - 1, z, width, height)];
                            d = Mathf.Min(d, n + 1);
                            m |= (n == 0 ? 1 : 0) << 3;
                        }

                        if (z > 0)
                        {
                            n = (int) dist[Index(x, y, z - 1, width, height)];
                            d = Mathf.Min(d, n + 1);
                            m |= (n == 0 ? 1 : 0) << 1;
                        }

                        dist[i] = (uint) d;
                        neighboringEdgeMasks[i] = (uint) m;
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
                        int d = (int) dist[i];
                        int m = (int) neighboringEdgeMasks[i];
                        int n;

                        if (x < width - 1)
                        {
                            n = (int) dist[Index(x + 1, y, z, width, height)];
                            d = Mathf.Min(d, n + 1);
                            m |= (n == 0 ? 1 : 0) << 4;
                        }

                        if (y < height - 1)
                        {
                            n = (int) dist[Index(x, y + 1, z, width, height)];
                            d = Mathf.Min(d, n + 1);
                            m |= (n == 0 ? 1 : 0) << 2;
                        }

                        if (z < depth - 1)
                        {
                            n = (int) dist[Index(x, y, z + 1, width, height)];
                            d = Mathf.Min(d, n + 1);
                            m |= (n == 0 ? 1 : 0) << 0;
                        }

                        dist[i] = (uint) d;
                        neighboringEdgeMasks[i] = (uint) m;
                    }
                }
            }

            // --------------------------------------------
            // Final Pass to Merge, Cap, Normalize, Pack Values
            // And count topology features
            // --------------------------------------------
            topologyCounts = new TopologyAnalysisResults();

            ulong hash = FNV_OFFSET_BASIS;

            // Hash dimensions (x, y, z)
            hash ^= (ulong)width;
            hash *= FNV_PRIME;

            hash ^= (ulong)height;
            hash *= FNV_PRIME;

            hash ^= (ulong)depth;
            hash *= FNV_PRIME;

            for (int z = depth - 1; z >= 0; z--)
            {
                for (int y = height - 1; y >= 0; y--)
                {
                    for (int x = width - 1; x >= 0; x--)
                    {
                        int i = Index(x, y, z, width, height);

                        int d = (int) dist[i];
                        int m = (int) neighboringEdgeMasks[i];
                        Color32 color = src[i];

                        // Pack SDF and Topology mask values together
                        // Max SDF distance becomes 192 to make room for the 63 possible values of the topology mask
                        m *= ((d == 0) ? 1 : 0);
                        if (d > 192) d = 192;
                        int topoPackedValue = d + (63 - m);

                        // Pack Color info together as r g b (least sig bits to most)
                        int colorPackedValue = (color.r << 8) | (color.g << 16) | (color.b << 24);

                        int packedValue = colorPackedValue | topoPackedValue;

                        dist[i] = (uint) packedValue;

                        hash ^= (ulong) packedValue;
                        hash *= FNV_PRIME;

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

            topologyCounts.hash = hash;

            return dist;
        }

        private static int Index(int x, int y, int z, int width, int height)
        {
            return x + y * width + z * width * height;
        }
    }
}
