using Incantation.Engine.Voxels.Components;
using System;
using System.Collections.Generic;
using UnityEngine;

public class DebugVisualizer : MonoBehaviour
{
    private enum DEBUG_VISUALIZATION_MODES
    {
        NONE = 0,
        BOUNDING_BOXES = 1,
        NORMALS = 2,
        DEPTH = 3,
        VOXEL_TOPOLOGY = 4,
        RAYMARCH_ITERATIONS = 5,
        RAYMARCH_SAMPLES = 6
    }

    // Debug properties
    [Header("Debug Visualization Mode")]
    [SerializeField] private int debugVisualizationMode = 0;

    #region Unity Lifecycle

    private void Start()
    {
        Debug.Log("Hold L Key and Press Number Keys for Debug Visualizations.");
    }

    void Update()
    {
        CheckDebugModeKeyChange();
    }

    private void OnValidate()
    {
        SetDebugMode((DEBUG_VISUALIZATION_MODES)debugVisualizationMode);
    }

    #endregion

    #region Debug Visualization
    void CheckDebugModeKeyChange()
    {
        // Only respond while L is held
        if (!Input.GetKey(KeyCode.L))
            return;

        CheckKey(KeyCode.Alpha0, DEBUG_VISUALIZATION_MODES.NONE);
        CheckKey(KeyCode.Alpha1, DEBUG_VISUALIZATION_MODES.BOUNDING_BOXES);
        CheckKey(KeyCode.Alpha2, DEBUG_VISUALIZATION_MODES.NORMALS);
        CheckKey(KeyCode.Alpha3, DEBUG_VISUALIZATION_MODES.DEPTH);
        CheckKey(KeyCode.Alpha4, DEBUG_VISUALIZATION_MODES.VOXEL_TOPOLOGY);
        CheckKey(KeyCode.Alpha5, DEBUG_VISUALIZATION_MODES.RAYMARCH_ITERATIONS);
        CheckKey(KeyCode.Alpha6, DEBUG_VISUALIZATION_MODES.RAYMARCH_SAMPLES);
    }

    void CheckKey(KeyCode key, DEBUG_VISUALIZATION_MODES mode)
    {
        if (Input.GetKeyDown(key))
        {
            SetDebugMode(mode);
        }
    }

    void SetDebugMode(DEBUG_VISUALIZATION_MODES mode)
    {
        DebugConstants.DRAW_AABBS = false;

        debugVisualizationMode = (int)mode;
        Shader.SetGlobalFloat("_DebugVisualizationMode", (int)mode);
        if (mode == DEBUG_VISUALIZATION_MODES.BOUNDING_BOXES)
        {
            DebugConstants.DRAW_AABBS = true;
        }

        Debug.Log($"Global Debug Mode set to: {mode}");
    }

    #endregion

}
