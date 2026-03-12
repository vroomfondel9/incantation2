using Incantation.Engine.Voxels.Utils.Import;
using System.IO;
using System.Text.RegularExpressions;
using Unity.Entities;
using UnityEditor;
using UnityEngine;

/// <summary>
/// Automatically generates a VoxelVolume ScriptableObject for any PNG
/// placed into Assets/VoxVol or its subfolders.
/// </summary>
public class VoxelVolumeAutoBake : AssetPostprocessor
{
    // Regex to get _h# from the filename
    private static Regex heightRegex = new Regex(@"_h(\d+)$", RegexOptions.Compiled);

    /// <summary>
    /// Called by Unity after assets are imported.
    /// </summary>
    static void OnPostprocessAllAssets(
        string[] importedAssets,
        string[] deletedAssets,
        string[] movedAssets,
        string[] movedFromAssetPaths)
    {
        foreach (string assetPath in importedAssets)
        {
            // Only process PNGs in Assets/VoxVol
            if (!assetPath.EndsWith(".png", System.StringComparison.OrdinalIgnoreCase))
                continue;

            if (!assetPath.StartsWith("Assets/VoxVol"))
                continue;

            CreateVoxelVolume(assetPath);
        }
    }

    private static void CreateVoxelVolume(string pngAssetPath)
    {
        System.Diagnostics.Stopwatch sw = System.Diagnostics.Stopwatch.StartNew();

        string folder = Path.GetDirectoryName(pngAssetPath);
        string filename = Path.GetFileNameWithoutExtension(pngAssetPath);
        string coreFilename = heightRegex.Replace(filename, "");

        string logPrefix = "[" + coreFilename + "]: ";
        //Debug.Log(logPrefix + "Beginning Auto-Bake.");

        // --- Extract _h# from filename ---
        Match match = heightRegex.Match(filename);
        if (!match.Success)
        {
            Debug.LogError(logPrefix + "Auto-Bake failed. Filename must end with _h#.png (example: tree_h32.png). Aborting Auto-Bake.");
            return;
        }

        int rows = int.Parse(match.Groups[1].Value);

        // STEP 1 - UPDATE METADATA OF PNG

        // --- Get importer ---
        TextureImporter importer = (TextureImporter)TextureImporter.GetAtPath(pngAssetPath);
        if (importer == null)
        {
            Debug.LogError(logPrefix + "Bake failed. Could not get texture importer.");
            return;
        }

        // --- Set metadata exactly as requested ---
        importer.textureType = TextureImporterType.Default;
        importer.textureShape = TextureImporterShape.Texture3D;
        importer.sRGBTexture = true;
        importer.alphaSource = TextureImporterAlphaSource.FromInput;
        importer.isReadable = true;
        importer.alphaIsTransparency = true;

        importer.mipmapEnabled = false;
        importer.wrapMode = TextureWrapMode.Clamp;
        importer.filterMode = FilterMode.Point;
        importer.maxTextureSize = 2048;
        importer.textureCompression = TextureImporterCompression.Uncompressed;

        importer.npotScale = TextureImporterNPOTScale.None;

        // Columns = 1, Rows = extracted #
        TextureImporterSettings settings = new TextureImporterSettings();
        importer.ReadTextureSettings(settings);

        settings.flipbookColumns = 1;
        settings.flipbookRows = rows;

        importer.SetTextureSettings(settings);


        importer.SaveAndReimport();

        // --- Reload as Texture3D ---
        Texture3D tex3D = AssetDatabase.LoadAssetAtPath<Texture3D>(pngAssetPath);
        if (tex3D == null)
        {
            Debug.LogError(logPrefix + "Auto-Bake failed. Failed to reload original png as Texture3D.");
            return;
        }

        // STEP 2 - COMPUTE DIMENSIONS
        int width = tex3D.width;
        int totalHeight = tex3D.height;

        Unity.Mathematics.int3 dims;
        dims.x = width;
        dims.y = totalHeight;
        dims.z = rows;
        //Debug.Log(logPrefix + "Derived grid dimensions: " + width + "x" + totalHeight + "x" + rows);

        // STEP 3 - Extract Voxel and Topology Data from MagicaVoxel Png
        MagicaVoxelImportUtils.TopologyAnalysisResults topologyCounts = new MagicaVoxelImportUtils.TopologyAnalysisResults();
        uint[] packedVoxels = MagicaVoxelImportUtils.GetPackedValuesFromMagicaVoxelPng(tex3D, out topologyCounts);

        // LAST STEP - WRITE FILES TO SCRIPTABLE OBJECT ASSET

        string assetPath = Path.Combine(folder, coreFilename + ".asset");

        // Avoid overwriting existing assets
        if (File.Exists(assetPath))
        {
            Debug.LogError($"VoxelVolume asset already exists: {assetPath}. Aborting Auto-Bake.");
            return;
        }

        // Create ScriptableObject
        var voxelVolume = ScriptableObject.CreateInstance<VoxelVolumePrebakedAsset>();
        voxelVolume.sourcePng = pngAssetPath;
        voxelVolume.hash = topologyCounts.hash;
        voxelVolume.dimensions = dims;
        voxelVolume.packedValues = packedVoxels;
        voxelVolume.cornerVoxelCount = topologyCounts.corners;
        voxelVolume.edgeVoxelCount = topologyCounts.edges;
        voxelVolume.faceVoxelCount = topologyCounts.faces;
        voxelVolume.interiorVoxelCount = topologyCounts.interiors;
        voxelVolume.emptyVoxelCount = topologyCounts.empties;
        voxelVolume.totalVoxelCount = topologyCounts.total;
        voxelVolume.centerOfMass = topologyCounts.centerOfMass;
        voxelVolume.mass = topologyCounts.mass;
        voxelVolume.momentOfInertia = topologyCounts.momentOfInertia;
        voxelVolume.inverseMass = (voxelVolume.mass == 0) ? float.MaxValue : 1.0f / voxelVolume.mass;
        voxelVolume.inverseInertia = new Vector3(
            (voxelVolume.momentOfInertia.x == 0) ? float.MaxValue : 1.0f / voxelVolume.momentOfInertia.x,
            (voxelVolume.momentOfInertia.y == 0) ? float.MaxValue : 1.0f / voxelVolume.momentOfInertia.y,
            (voxelVolume.momentOfInertia.z == 0) ? float.MaxValue : 1.0f / voxelVolume.momentOfInertia.z
        );

        AssetDatabase.CreateAsset(voxelVolume, assetPath);
        AssetDatabase.SaveAssets();
        //AssetDatabase.Refresh();

        sw.Stop();
        Debug.Log(logPrefix + "Auto-Bake success. Time: " + sw.ElapsedMilliseconds + "ms.");
    }
}