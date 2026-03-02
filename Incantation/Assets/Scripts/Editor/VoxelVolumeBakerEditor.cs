using System.IO;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

[CustomEditor(typeof(VoxelVolumeBaker))]
public class VoxelVolumeBakerEditor : Editor
{
    private const string shaderPath =
        "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/VoxVolShader.shader";

    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        VoxelVolumeBaker baker = (VoxelVolumeBaker)target;

        GUILayout.Space(10);

        if (GUILayout.Button("Bake"))
        {
            Bake(baker);
        }
    }

    private void Bake(VoxelVolumeBaker baker)
    {
        System.Diagnostics.Stopwatch sw = System.Diagnostics.Stopwatch.StartNew();

        string logPrefix = "[" + baker.gameObject.name + "]: ";
        Debug.Log(logPrefix + "Beginning Bake.");

        if (baker.sourceTexture == null)
        {
            Debug.LogError(logPrefix + "Bake failed. No PNG assigned.");
            return;
        }

        string path = AssetDatabase.GetAssetPath(baker.sourceTexture);
        string filename = Path.GetFileNameWithoutExtension(path);
        baker.originalVoxelTextureId = path;
        baker.modified = false;

        // --- Extract _h# from filename ---
        Match match = Regex.Match(filename, @"_h(\d+)$");
        if (!match.Success)
        {
            Debug.LogError(logPrefix + "Bake failed. Filename must end with _h#.png (example: tree_h32.png)");
            return;
        }

        int rows = int.Parse(match.Groups[1].Value);

        // --- Get importer ---
        TextureImporter importer = (TextureImporter)TextureImporter.GetAtPath(path);
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
        Texture3D tex3D = AssetDatabase.LoadAssetAtPath<Texture3D>(path);
        if (tex3D == null)
        {
            Debug.LogError(logPrefix + "Bake failed. Failed to reload original Texture as Texture3D.");
            return;
        }

        // Reassign so reference doesn't become Missing
        baker.sourceTexture = tex3D;

        EditorUtility.SetDirty(baker);
        AssetDatabase.SaveAssets();

        // --- Compute scale ---
        int width = tex3D.width;
        int totalHeight = tex3D.height;
        Debug.Log(logPrefix + "Derived grid dimensions: " + width + "x" + totalHeight + "x" + rows);

        Transform t = baker.transform;

        t.localScale = new Vector3(
            width * GlobalConstants.VOXEL_SCALE,
            totalHeight * GlobalConstants.VOXEL_SCALE,
            rows * GlobalConstants.VOXEL_SCALE
        );

        // --- Rotate 90° on X ---
        t.localRotation = Quaternion.Euler(90f, 0f, 0f);

        // --- Remove BoxCollider ---
        BoxCollider col = baker.GetComponent<BoxCollider>();
        if (col != null)
        {
            DestroyImmediate(col);
        }

        // --- Create material from ShaderGraph ---
        Shader shader = AssetDatabase.LoadAssetAtPath<Shader>(shaderPath);
        if (shader == null)
        {
            Debug.LogError(logPrefix + "Bake failed. Could not find shader at: " + shaderPath);
            return;
        }

        Material mat = new Material(shader);

        // Assign texture
        mat.SetTexture("_ColorTexture", tex3D);

        // GridDimensions - size of voxel grid
        Vector3 gridDims = new Vector3(
            width,
            totalHeight,
            rows
        );

        mat.SetVector("_GridDimensions", gridDims);

        // --- Create _HitTexture (R8_UInt, all values = 1) ---
        TOPOLOGY_COUNTS topologyCounts = new TOPOLOGY_COUNTS();
        Texture3D hitTex = VoxelSDFGenerator.GenerateManhattanDistanceField(tex3D, out topologyCounts);

        Debug.Log(logPrefix + "Topology Summary: " +
            $"Corners={topologyCounts.corners} ({100.0 * topologyCounts.corners / topologyCounts.total:F1}%), " +
            $"Edges={topologyCounts.edges} ({100.0 * topologyCounts.edges / topologyCounts.total:F1}%), " +
            $"Faces={topologyCounts.faces} ({100.0 * topologyCounts.faces / topologyCounts.total:F1}%), " +
            $"Interiors={topologyCounts.interiors} ({100.0 * topologyCounts.interiors / topologyCounts.total:F1}%), " +
            $"Empties={topologyCounts.empties} ({100.0 * topologyCounts.empties / topologyCounts.total:F1}%), " +
            $"Total={topologyCounts.total}.");

        // Assign to material
        mat.SetTexture("_HitTexture", hitTex);

        // Assign Editor Mode Conditional Compilation Version
        mat.EnableKeyword("_EDITOR_MODE");

        // Assign to renderer
        Renderer renderer = baker.GetComponent<Renderer>();
        if (renderer != null)
        {
            renderer.sharedMaterial = mat;
        }
        baker.editorMaterial = mat;

        sw.Stop();
        Debug.Log(logPrefix + "Bake success. Time: " + sw.ElapsedMilliseconds + "ms.");
    }
}