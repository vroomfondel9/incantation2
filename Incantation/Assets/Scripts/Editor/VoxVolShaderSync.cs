using System;
using System.IO;
using System.Reflection;
using System.Text;
using Unity.Rendering.Universal;
using UnityEditor;
using UnityEngine;

public class VoxVolShaderSync : AssetPostprocessor
{
    private const string GraphName = "Assets/Scripts/Shader/Sim 3D/Rendering/Solids/VoxVolShaderNoDepth.shadergraph";
    private const string TargetShaderName = "VoxVolShader.shader";

    static void OnPostprocessAllAssets(
        string[] importedAssets,
        string[] deletedAssets,
        string[] movedAssets,
        string[] movedFromAssetPaths)
    {
        foreach (var asset in importedAssets)
        {
            if (!asset.EndsWith(GraphName))
                continue;

            Debug.Log("Detected change to VoxVolShaderNoDepth.shadergraph. Syncing...");

            //SyncShader(asset);
            Debug.Log("Source found: " + GenerateShaderCode(GraphName));
        }
    }

    private static void SyncShader(string shaderGraphPath)
    {
        var shader = AssetDatabase.LoadAssetAtPath<Shader>(shaderGraphPath);
        if (shader == null)
        {
            Debug.LogError("Failed to load ShaderGraph as Shader.");
            return;
        }

        string generatedShader = GetGeneratedShaderSource(shader);
        if (string.IsNullOrEmpty(generatedShader))
        {
            Debug.LogError("Failed to extract generated shader source.");
            return;
        }

        // Replace include
        generatedShader = generatedShader.Replace(
            "#include \"Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl\"",
            "#include \"PBRForwardPass.hlsl\""
        );

        string targetPath = Path.Combine(Path.GetDirectoryName(shaderGraphPath), TargetShaderName);
        File.WriteAllText(targetPath, generatedShader);

        AssetDatabase.ImportAsset(targetPath);

        Debug.Log("VoxVolShader.shader updated successfully.");
    }
    private static object GetGraphData(string shaderAssetPath)
    {
        var importer = AssetImporter.GetAtPath(shaderAssetPath);

        var textGraph = File.ReadAllText(importer.assetPath, Encoding.UTF8);
        var graphObjectType = Type.GetType("UnityEditor.Graphing.GraphObject, Unity.ShaderGraph.Editor")!;

        // var graphObject = CreateInstance<GraphObject>();
        var graphObject = ScriptableObject.CreateInstance(graphObjectType);

        graphObject.hideFlags = HideFlags.HideAndDontSave;
        bool isSubGraph;
        var extension = Path.GetExtension(importer.assetPath).Replace(".", "");
        switch (extension)
        {
            case "shadergraph":
                isSubGraph = false;
                break;
            case "ShaderGraph":
                isSubGraph = false;
                break;
            case "shadersubgraph":
                isSubGraph = true;
                break;
            default:
                throw new Exception($"Invalid file extension {extension}");
        }
        var assetGuid = AssetDatabase.AssetPathToGUID(importer.assetPath);

        // graphObject.graph = new GraphData { assetGuid = assetGuid, isSubGraph = isSubGraph, messageManager = null };
        var graphObject_graphProperty = graphObjectType.GetProperty("graph")!;
        var graphDataType = Type.GetType("UnityEditor.ShaderGraph.GraphData, Unity.ShaderGraph.Editor")!;
        var graphDataInstance = Activator.CreateInstance(graphDataType);
        graphDataType.GetProperty("assetGuid")!.SetValue(graphDataInstance, assetGuid);
        graphDataType.GetProperty("isSubGraph")!.SetValue(graphDataInstance, isSubGraph);
        graphDataType.GetProperty("messageManager")!.SetValue(graphDataInstance, null);
        graphObject_graphProperty.SetValue(graphObject, graphDataInstance);

        // MultiJson.Deserialize(graphObject.graph, textGraph);
        // = MultiJson.Deserialize<JsonObject>(graphObject.graph, textGraph, null, false);
        var multiJsonType = Type.GetType("UnityEditor.ShaderGraph.Serialization.MultiJson, Unity.ShaderGraph.Editor")!;
        var deserializeMethod = multiJsonType.GetMethod("Deserialize")!;
        var descrializeGenericMethod = deserializeMethod.MakeGenericMethod(graphDataType);
        descrializeGenericMethod.Invoke(null, new object[] { graphDataInstance, textGraph, null, false });

        // graphObject.graph.OnEnable();
        graphDataType.GetMethod("OnEnable")!.Invoke(graphDataInstance, null);

        // graphObject.graph.ValidateGraph();
        graphDataType.GetMethod("ValidateGraph")!.Invoke(graphDataInstance, null);

        // return graphData.graph
        return graphDataInstance;
    }

    private static string GenerateShaderCode(string shaderAssetPath, string shaderName = null)
    {
        Type generatorType =
            Type.GetType("UnityEditor.ShaderGraph.Generator, Unity.ShaderGraph.Editor")!;
        Type modeType =
            Type.GetType("UnityEditor.ShaderGraph.GenerationMode, Unity.ShaderGraph.Editor")!;

        shaderName ??= Path.GetFileNameWithoutExtension(shaderAssetPath);

        object graphData = GetGraphData(shaderAssetPath);

        // new Generator(graphData, null, GenerationMode.ForReals, assetName, target:null, assetCollection:null, humanReadable: true);
        object forReals = ((FieldInfo)modeType.GetMember("ForReals")[0]).GetValue(null);
        object generator = Activator.CreateInstance(
            generatorType,
            new object[] { graphData, null, forReals, shaderName, null, null, true }
        );
        object shaderCode = generatorType
            .GetProperty("generatedShader", BindingFlags.Public | BindingFlags.Instance)!
            .GetValue(generator);

        return (string)shaderCode;
    }
}