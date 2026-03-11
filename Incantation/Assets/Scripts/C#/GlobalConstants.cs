using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal.Internal;

public class GlobalConstants
{
    public static float VOXEL_SCALE = 1 / 10.0f;

    public static int MAX_GLOBAL_ORIGINAL_VOXELS = 100000000;

    public static int MAX_UNIQUE_ORIG_VOX_VOLS_PER_SCENE = 300000;

    public static int MAX_VOX_VOLS_MODIFIABLE_PER_FRAME = 1000;

    public static uint PER_VOXEL_BUFFER_UPDATE_SWAP_DELAY_FRAMES = 1;
}
