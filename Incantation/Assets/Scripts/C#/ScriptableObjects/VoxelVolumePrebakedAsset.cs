using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

public class VoxelVolumePrebakedAsset : ScriptableObject
{
    [Header("Source Image")]
    public string sourcePng;

    [Header("Identity Properties")]
    public ulong hash;
    public int3 dimensions;

    [Header("Topology Counts")]
    public int cornerVoxelCount;
    public int edgeVoxelCount;
    public int faceVoxelCount;
    public int interiorVoxelCount;
    public int emptyVoxelCount;
    public int totalVoxelCount;

    [Header("Physics Properties")]
    public float mass;
    public float inverseMass;
    public Vector3 momentOfInertia;
    public Vector3 inverseInertia;
    public Vector3 centerOfMass;

    [HideInInspector]
    public uint[] packedValues;
}