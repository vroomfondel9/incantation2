using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DebugConstants
{
    public const bool DISABLE_ALL_DEBUG = false;

    // Collision Debug Values
    public const bool ENABLE_BROADPHASE_DRAW_PAIRS = !DISABLE_ALL_DEBUG && true;

    public const bool ENABLE_NARROWPHASE_DRAW_SPHERES = !DISABLE_ALL_DEBUG && true;

    public const bool ENABLE_NARROWPHASE_DRAW_AABBS = !DISABLE_ALL_DEBUG && true;

    public const bool ENABLE_NARROWPHASE_DRAW_OBBS = !DISABLE_ALL_DEBUG && true;
}
