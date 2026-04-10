using Incantation.Engine.Voxels.Components;
using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using Unity.Mathematics;
using UnityEditor;
using UnityEngine;

namespace Incantation.Engine.Voxels.Authoring
{
    //Basically just a container for a VoxelVolumePrebakedAsset read from disk because authoring components have to be MonoBehaviors
    [Serializable]
    public class VoxelVolumePrebakedAssetAuthoring : MonoBehaviour
    {
        // SOURCE ART ASSET
        [SerializeField]
        public VoxelVolumePrebakedAsset voxelVolumePrebakedAsset;

        // PLACEMENT SETTINGS
        public VariableValueType positionOffsetType;
        public RangeRandomization positionOffsetRandomization;
        public Vector3 positionOffsetMin;
        public Vector3 positionOffsetMax;

        // PHYSICS SETTINGS
        public bool isDynamic = true;

        // Initial Linear Velocity
        public VariableValueType initialVelocityLinearType;
        public CoordSpace initialVelocityLinearSpace;
        public RangeRandomization initialVelocityLinearRandomization;
        public Vector3 initialVelocityLinearBasis = Vector3.zero;
        public Vector2 initialVelocityLinearMinSpread = Vector2.zero;
        public Vector2 initialVelocityLinearMaxSpread = Vector2.zero;

        // Initial Angular Velocity
        public VariableValueType initialVelocityAngularType;
        public CoordSpace initialVelocityAngularSpace;
        public RangeRandomization initialVelocityAngularRandomization;
        public Vector3 initialVelocityAngularMin = Vector3.zero;
        public Vector3 initialVelocityAngularMax = Vector3.zero;

        // SPAWN CLONES

        // Clone Count
        public VariableValueType cloneCountType;
        public long cloneCountMin = 1;
        public long cloneCountMax = 1;

        // Clone Shape
        public CloneShape cloneShape;

        // Clone Spacing
        public VariableValueType cloneSpacingType;
        public Vector3 cloneSpacingMin = Vector3.zero;
        public Vector3 cloneSpacingMax = Vector3.zero;

        // Clone Initial Linear Velocity Offset
        public VariableValueType cloneInitialVelocityLinearOffsetType;
        public CoordSpace cloneInitialVelocityLinearOffsetSpace;
        public RangeRandomization cloneInitialVelocityLinearOffsetRandomization;
        public Vector3 cloneInitialVelocityLinearOffsetBasis = Vector3.zero;
        public Vector2 cloneInitialVelocityLinearOffsetMinSpread = Vector2.zero;
        public Vector2 cloneInitialVelocityLinearOffsetMaxSpread = Vector2.zero;

        // Clone Initial Angular Velocity Offset
        public VariableValueType cloneInitialVelocityAngularOffsetType;
        public CoordSpace cloneInitialVelocityAngularOffsetSpace;
        public RangeRandomization cloneInitialVelocityAngularOffsetRandomization;
        public Vector3 cloneInitialVelocityAngularOffsetMin = Vector3.zero;
        public Vector3 cloneInitialVelocityAngularOffsetMax = Vector3.zero;

        public VoxelVolumePrebakedAsset VoxelVolumePrebakedAsset
        {
            get => voxelVolumePrebakedAsset;
            set => voxelVolumePrebakedAsset = value;
        }
    }

    public enum VariableValueType
    {
        None = 0,
        Constant,
        Range,
        Random
    }

    public enum CoordSpace
    {
        World,
        Local
    }

    public enum RangeRandomization
    {
        None,
        Uniform,
        Gaussian
    }

    public enum CloneShape
    {
        Cube = 0,
        Sphere
    }
}