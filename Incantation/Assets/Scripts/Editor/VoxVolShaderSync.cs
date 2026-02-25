using UnityEngine;
using UnityEditor;
using System.IO;
using System.Linq;

public class VoxVolShaderSync : AssetPostprocessor
{
    const string ShaderGraphPath = "Assets/Shaders/VoxVolShaderNoDepth.shadergraph";
    const string TargetShaderPath = "Assets/Shaders/VoxVolShader.shader";

    static void OnPostprocessAllAssets(
        string[] importedAssets,
        string[] deletedAssets,
        string[] movedAssets,
        string[] movedFromAssetPaths)
    {
        // Only react when the shadergraph is saved/reimported
        if (!importedAssets.Contains(ShaderGraphPath))
            return;

        SyncShader();
    }

    static void SyncShader()
    {
        // Load the generated shader
        Shader generated = AssetDatabase.LoadAssetAtPath<Shader>(ShaderGraphPath);
        if (generated == null)
        {
            Debug.LogError("Failed to load generated shader.");
            return;
        }

        // Export generated shader source to temp file
        string tempPath = Path.Combine(Application.dataPath, "../Temp/GeneratedShader.shader");
        ShaderUtil.WriteShaderToDisk(generated, tempPath);

        if (!File.Exists(tempPath))
        {
            Debug.LogError("Failed to export shader source.");
            return;
        }

        string source = File.ReadAllText(tempPath);

        // ?? Replace the include
        source = source.Replace(
            "#include \"Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl\"",
            "#include \"PBRForwardPass.hlsl\""
        );

        // Write final shader
        File.WriteAllText(TargetShaderPath, source);

        // Clean up temp file
        File.Delete(tempPath);

        AssetDatabase.Refresh();

        Debug.Log("VoxVol shader synced.");
    }
}