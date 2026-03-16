using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DebugConstants
{
    public const bool DISABLE_ALL_DEBUG = false;

    public const bool ENABLE_BROADPHASE_DRAW_PAIRS = !DISABLE_ALL_DEBUG && true;

    // This is should not be a const
    public static bool DRAW_AABBS = false;
}
