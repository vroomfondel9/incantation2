using Incantation.Engine.Voxels.Authoring;
using System.IO;
using Unity.Mathematics;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using static UnityEngine.Rendering.DebugUI.Table;

public static class VoxelVolumeInstanceCreator
{
    private const string ShaderPath = "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/VoxVolShader.shader";

    [MenuItem("Assets/Create/Voxel Volume", true, 0)]
    private static bool ValidateCreateVoxelVolumeInstance()
    {
        return Selection.activeObject is VoxelVolumePrebakedAsset;
    }

    [MenuItem("Assets/Create/Voxel Volume", false, 0)]
    private static void CreateVoxelVolumeInstance()
    {
        VoxelVolumePrebakedAsset voxelVolume = Selection.activeObject as VoxelVolumePrebakedAsset;
        if (voxelVolume == null)
            return;

        // --- Create Cube ---
        GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube.name = voxelVolume.name;
        cube.transform.position = Vector3.zero;
        cube.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
        cube.transform.localScale = new Vector3(
            voxelVolume.dimensions.x * GlobalConstants.VOXEL_SCALE,
            voxelVolume.dimensions.y * GlobalConstants.VOXEL_SCALE,
            voxelVolume.dimensions.z * GlobalConstants.VOXEL_SCALE
        );

        // Remove BoxCollider if present
        BoxCollider collider = cube.GetComponent<BoxCollider>();
        if (collider != null)
            Object.DestroyImmediate(collider);

        // Add Entity authoring script
        VoxelVolumePrebakedAssetAuthoring authoring =
            cube.AddComponent<VoxelVolumePrebakedAssetAuthoring>();
        authoring.voxelVolumePrebakedAsset = voxelVolume;

        // --- Load Shader ---
        Shader shader = AssetDatabase.LoadAssetAtPath<Shader>(ShaderPath);
        if (shader == null)
        {
            Debug.LogError($"Shader not found at path: {ShaderPath}");
            return;
        }

        Material material = new Material(shader);
        material.name = voxelVolume.name + "_Material";

        // --- Load Color Texture (3D) ---
        Texture3D colorTexture = AssetDatabase.LoadAssetAtPath<Texture3D>(voxelVolume.sourcePng);
        if (colorTexture == null)
        {
            Debug.LogError($"Color Texture3D not found at path: {voxelVolume.sourcePng}");
            return;
        }

        material.SetTexture("_ColorTexture", colorTexture);

        // --- Create Hit Texture from topology bytes ---
        int width = voxelVolume.dimensions.x;
        int height = voxelVolume.dimensions.y;
        int depth = voxelVolume.dimensions.z;

        int voxelCount = width * height * depth;
        byte[] topologyBytes = new byte[voxelCount];

        for (int i = 0; i < voxelCount; i++)
        {
            uint packed = voxelVolume.packedValues[i];

            // LSB is topology byte
            byte topology = (byte)(packed & 0xFF);
            topologyBytes[i] = topology;
        }

        Texture3D hitTexture = new Texture3D(
            width,
            height,
            depth,
            GraphicsFormat.R8_UNorm,
            TextureCreationFlags.None);

        hitTexture.filterMode = FilterMode.Point;
        hitTexture.wrapMode = TextureWrapMode.Clamp;
        hitTexture.SetPixelData(topologyBytes, 0);
        hitTexture.Apply(false, false);

        material.SetTexture("_HitTexture", hitTexture);

        // --- Grid Dimensions ---
        material.SetVector("_GridDimensions",
            new Vector4(width, height, depth, 0f));

        // --- Enable Editor Mode keyword ---
        material.EnableKeyword("_EDITOR_MODE");

        // Assign material
        cube.GetComponent<Renderer>().sharedMaterial = material;

        // Register undo
        Undo.RegisterCreatedObjectUndo(cube, "Create Voxel Volume Instance");

        Selection.activeGameObject = cube;
    }
}