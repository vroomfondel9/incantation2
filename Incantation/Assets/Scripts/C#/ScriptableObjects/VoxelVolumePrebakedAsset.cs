using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

public class VoxelVolumePrebakedAsset : ScriptableObject
{
    public string sourcePng;

    public ulong hash;
    public int3 dimensions;

    public int cornerVoxelCount;
    public int edgeVoxelCount;
    public int faceVoxelCount;
    public int interiorVoxelCount;
    public int emptyVoxelCount;
    public int totalVoxelCount;

    [HideInInspector]
    public uint[] packedValues;
}