using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering.Universal.Internal;

public class GlobalConstants
{
    public static readonly float VOXEL_SCALE = 1 / 10.0f;                           //Experimentally obtained by comparing water and voxel sizes

    public static readonly int MAX_GLOBAL_ORIGINAL_VOXELS = 100000000;

    public static readonly int MAX_UNIQUE_ORIG_VOX_VOLS_PER_SCENE = 300000;

    public static readonly int MAX_VOX_VOLS_MODIFIABLE_PER_FRAME = 1000;

    public static readonly uint PER_VOXEL_BUFFER_UPDATE_SWAP_DELAY_FRAMES = 1;

    public static readonly float BROADPHASE_GRID_CELL_SIZE = VOXEL_SCALE * 64.0f;     //Anything 16^3 voxels or smaller can fit in only one grid cell

    public static readonly uint3 BROADPHASE_GRID_CELLS_PER_CHUNK = new uint3(8, 8, 8);

    // Note: Chunk size must be <= this size.
    public static readonly float3 BROADPHASE_GRID_SIZE = new float3(
        BROADPHASE_GRID_CELLS_PER_CHUNK.x * BROADPHASE_GRID_CELL_SIZE,
        BROADPHASE_GRID_CELLS_PER_CHUNK.y * BROADPHASE_GRID_CELL_SIZE,
        BROADPHASE_GRID_CELLS_PER_CHUNK.z * BROADPHASE_GRID_CELL_SIZE
    );

    public static readonly uint MAX_VOXEL_SIZE_PER_DIM = 255;

    public static readonly uint3 MAX_VOXEL_SIZE = new uint3(MAX_VOXEL_SIZE_PER_DIM, MAX_VOXEL_SIZE_PER_DIM, MAX_VOXEL_SIZE_PER_DIM);
}
