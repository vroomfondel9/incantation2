using Incantation.Engine.Voxels.Authoring;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using static Incantation.Engine.Voxels.Authoring.VoxelVolumePrebakedAssetAuthoring;

[CustomEditor(typeof(VoxelVolumePrebakedAssetAuthoring))]
public class VoxelVolumePrebakedAssetAuthoringCustomEditor : Editor
{
    public override void OnInspectorGUI()
    {
        VoxelVolumePrebakedAssetAuthoring asset = (VoxelVolumePrebakedAssetAuthoring)target;
        serializedObject.Update();

        // SOURCE ART ASSET
        EditorGUILayout.LabelField("Source Art Asset", EditorStyles.boldLabel);

        // Voxel Volume Prebaked Asset
        EditorGUILayout.PropertyField(serializedObject.FindProperty("voxelVolumePrebakedAsset"));
        EditorGUILayout.Space();

        // PLACEMENT SETTINGS
        EditorGUILayout.LabelField("Placement Settings", EditorStyles.boldLabel);

        asset.positionOffsetType = (VariableValueType)EditorGUILayout.EnumPopup(
            "Position Offset", asset.positionOffsetType);

        switch (asset.positionOffsetType)
        {
            case VariableValueType.None:
                asset.positionOffsetMin = Vector3.zero;
                asset.positionOffsetMax = Vector3.zero;
                asset.positionOffsetRandomization = RangeRandomization.None;
                break;

            case VariableValueType.Constant:
                asset.positionOffsetMin = EditorGUILayout.Vector3Field("Offset:", asset.positionOffsetMin);
                asset.positionOffsetMax = asset.positionOffsetMin;
                asset.positionOffsetRandomization = RangeRandomization.None;
                break;

            case VariableValueType.Random:
            case VariableValueType.Range:
                asset.positionOffsetMin = EditorGUILayout.Vector3Field("Offset Min:", asset.positionOffsetMin);
                asset.positionOffsetMax = EditorGUILayout.Vector3Field("Offset Max:", asset.positionOffsetMax);
                asset.positionOffsetRandomization = RangeRandomization.Uniform;
                break;
        }

        EditorGUILayout.Space();

        // PHYSICS SETTINGS
        EditorGUILayout.LabelField("Physics Settings", EditorStyles.boldLabel);

        // IsDynamic
        EditorGUILayout.PropertyField(serializedObject.FindProperty("isDynamic"));

        // Initial Linear Velocity
        asset.initialVelocityLinearType = (VariableValueType)EditorGUILayout.EnumPopup(
            "Initial Linear Velocity", asset.initialVelocityLinearType);

        switch (asset.initialVelocityLinearType)
        {
            case VariableValueType.None:
                asset.initialVelocityLinearBasis = Vector3.zero;
                asset.initialVelocityLinearMinSpread = Vector2.zero;
                asset.initialVelocityLinearMaxSpread = Vector2.zero;
                asset.initialVelocityLinearSpace = CoordSpace.World;
                asset.initialVelocityLinearRandomization = RangeRandomization.None;
                break;

            case VariableValueType.Random:
                asset.initialVelocityLinearBasis = Vector3.zero;
                asset.initialVelocityLinearMinSpread = Vector2.zero;
                asset.initialVelocityLinearMaxSpread = Vector2.zero;
                asset.initialVelocityLinearSpace = CoordSpace.World;
                asset.initialVelocityLinearRandomization = RangeRandomization.Uniform;
                break;

            case VariableValueType.Constant:
                asset.initialVelocityLinearBasis = EditorGUILayout.Vector3Field("Linear Velocity:", asset.initialVelocityLinearBasis);
                asset.initialVelocityLinearSpace = (CoordSpace)EditorGUILayout.EnumPopup(
                    "Coord Space", asset.initialVelocityLinearSpace);
                asset.initialVelocityLinearMinSpread = Vector2.zero;
                asset.initialVelocityLinearMaxSpread = Vector2.zero;
                asset.initialVelocityLinearRandomization = RangeRandomization.None;
                break;

            case VariableValueType.Range:
                asset.initialVelocityLinearBasis = EditorGUILayout.Vector3Field("Linear Velocity Basis:", asset.initialVelocityLinearBasis);
                asset.initialVelocityLinearSpace = (CoordSpace)EditorGUILayout.EnumPopup(
                    "Coord Space", asset.initialVelocityLinearSpace);
                asset.initialVelocityLinearMinSpread = EditorGUILayout.Vector2Field("Min Spread:", asset.initialVelocityLinearMinSpread);
                asset.initialVelocityLinearMaxSpread = EditorGUILayout.Vector2Field("Max Spread:", asset.initialVelocityLinearMaxSpread);
                asset.initialVelocityLinearRandomization = RangeRandomization.Uniform;
                asset.initialVelocityLinearRandomization = (RangeRandomization)EditorGUILayout.EnumPopup(
                    "Randomization", asset.initialVelocityLinearRandomization);
                break;
        }

        // Initial Angular Velocity
        asset.initialVelocityAngularType = (VariableValueType)EditorGUILayout.EnumPopup(
            "Initial Angular Velocity", asset.initialVelocityAngularType);

        switch (asset.initialVelocityAngularType)
        {
            case VariableValueType.None:
                asset.initialVelocityAngularMin = Vector3.zero;
                asset.initialVelocityAngularMax = Vector3.zero;
                asset.initialVelocityAngularSpace = CoordSpace.World;
                asset.initialVelocityAngularRandomization = RangeRandomization.None;
                break;

            case VariableValueType.Random:
                asset.initialVelocityAngularMin = Vector3.zero;
                asset.initialVelocityAngularMax = Vector3.zero;
                asset.initialVelocityAngularSpace = CoordSpace.World;
                asset.initialVelocityAngularRandomization = RangeRandomization.Uniform;
                break;

            case VariableValueType.Constant:
                asset.initialVelocityAngularMin = EditorGUILayout.Vector3Field("Angular Velocity:", asset.initialVelocityAngularMin);
                asset.initialVelocityAngularSpace = (CoordSpace)EditorGUILayout.EnumPopup(
                    "Coord Space", asset.initialVelocityAngularSpace);
                asset.initialVelocityAngularMax = asset.initialVelocityAngularMin;
                asset.initialVelocityAngularRandomization = RangeRandomization.None;
                break;

            case VariableValueType.Range:
                asset.initialVelocityAngularMin = EditorGUILayout.Vector3Field("Angular Velocity Min:", asset.initialVelocityAngularMin);
                asset.initialVelocityAngularMax = EditorGUILayout.Vector3Field("Angular Velocity Max:", asset.initialVelocityAngularMax);
                asset.initialVelocityAngularSpace = (CoordSpace)EditorGUILayout.EnumPopup(
                    "Coord Space", asset.initialVelocityAngularSpace);
                asset.initialVelocityAngularRandomization = (RangeRandomization)EditorGUILayout.EnumPopup(
                    "Randomization", asset.initialVelocityAngularRandomization);
                break;
        }
        EditorGUILayout.Space();

        // SPAWN CLONES
        EditorGUILayout.LabelField("Spawn Clones", EditorStyles.boldLabel);

        // Clone number
        asset.cloneCountType = (VariableValueType)EditorGUILayout.EnumPopup(
            "Clones", asset.cloneCountType);

        switch (asset.cloneCountType)
        {
            case VariableValueType.None:
                asset.cloneCountMin = 1;
                asset.cloneCountMax = 1;
                break;

            case VariableValueType.Constant:
                asset.cloneCountMin = EditorGUILayout.LongField("Number:", asset.cloneCountMin);
                asset.cloneCountMax = asset.cloneCountMin;
                break;

            case VariableValueType.Random:
            case VariableValueType.Range:
                asset.cloneCountMin = EditorGUILayout.LongField("Min Number:", asset.cloneCountMin);
                asset.cloneCountMax = EditorGUILayout.LongField("Max Number:", asset.cloneCountMax);
                break;
        }

        if (asset.cloneCountMin > 1)
        {
            // Clone shape
            asset.cloneShape = (CloneShape)EditorGUILayout.EnumPopup(
                "Shape", asset.cloneShape);

            // Clone spacing
            asset.cloneSpacingType = (VariableValueType)EditorGUILayout.EnumPopup(
                "Spacing", asset.cloneSpacingType);

            switch (asset.cloneSpacingType)
            {
                case VariableValueType.None:
                    asset.cloneSpacingMin = Vector3.zero;
                    asset.cloneSpacingMax = Vector3.zero;
                    break;

                case VariableValueType.Constant:
                    asset.cloneSpacingMin = EditorGUILayout.Vector3Field("Constant Spacing:", asset.cloneSpacingMin);
                    asset.cloneSpacingMax = asset.cloneSpacingMin;
                    break;

                case VariableValueType.Random:
                case VariableValueType.Range:
                    asset.cloneSpacingMin = EditorGUILayout.Vector3Field("Min Spacing:", asset.cloneSpacingMin);
                    asset.cloneSpacingMax = EditorGUILayout.Vector3Field("Max Spacing:", asset.cloneSpacingMax);
                    break;
            }

            // Clone Initial Linear Velocity Offset
            asset.cloneInitialVelocityLinearOffsetType = (VariableValueType)EditorGUILayout.EnumPopup(
            "Initial Linear Velocity Offset", asset.cloneInitialVelocityLinearOffsetType);

            switch (asset.cloneInitialVelocityLinearOffsetType)
            {
                case VariableValueType.None:
                    asset.cloneInitialVelocityLinearOffsetBasis = Vector3.zero;
                    asset.cloneInitialVelocityLinearOffsetMinSpread = Vector2.zero;
                    asset.cloneInitialVelocityLinearOffsetMaxSpread = Vector2.zero;
                    asset.cloneInitialVelocityLinearOffsetSpace = CoordSpace.World;
                    asset.cloneInitialVelocityLinearOffsetRandomization = RangeRandomization.None;
                    break;

                case VariableValueType.Random:
                    asset.cloneInitialVelocityLinearOffsetBasis = Vector3.zero;
                    asset.cloneInitialVelocityLinearOffsetMinSpread = Vector2.zero;
                    asset.cloneInitialVelocityLinearOffsetMaxSpread = Vector2.zero;
                    asset.cloneInitialVelocityLinearOffsetSpace = CoordSpace.World;
                    asset.cloneInitialVelocityLinearOffsetRandomization = RangeRandomization.Uniform;
                    break;

                case VariableValueType.Constant:
                    asset.cloneInitialVelocityLinearOffsetBasis = EditorGUILayout.Vector3Field("Constant Linear Offset:", asset.cloneInitialVelocityLinearOffsetBasis);
                    asset.cloneInitialVelocityLinearOffsetSpace = (CoordSpace)EditorGUILayout.EnumPopup(
                        "Coord Space", asset.cloneInitialVelocityLinearOffsetSpace);
                    asset.cloneInitialVelocityLinearOffsetMinSpread = Vector2.zero;
                    asset.cloneInitialVelocityLinearOffsetMaxSpread = Vector2.zero;
                    asset.cloneInitialVelocityLinearOffsetRandomization = RangeRandomization.None;
                    break;

                case VariableValueType.Range:
                    asset.cloneInitialVelocityLinearOffsetBasis = EditorGUILayout.Vector3Field("Linear Offset Basis:", asset.cloneInitialVelocityLinearOffsetBasis);
                    asset.cloneInitialVelocityLinearOffsetSpace = (CoordSpace)EditorGUILayout.EnumPopup(
                        "Coord Space", asset.cloneInitialVelocityLinearOffsetSpace);
                    asset.cloneInitialVelocityLinearOffsetMinSpread = EditorGUILayout.Vector2Field("Min Spread:", asset.cloneInitialVelocityLinearOffsetMinSpread);
                    asset.cloneInitialVelocityLinearOffsetMaxSpread = EditorGUILayout.Vector2Field("Max Spread:", asset.cloneInitialVelocityLinearOffsetMaxSpread);
                    asset.cloneInitialVelocityLinearOffsetRandomization = RangeRandomization.Uniform;
                    asset.cloneInitialVelocityLinearOffsetRandomization = (RangeRandomization)EditorGUILayout.EnumPopup(
                        "Randomization", asset.cloneInitialVelocityLinearOffsetRandomization);
                    break;
            }

            // Clone Initial Angular Velocity Offset
            asset.cloneInitialVelocityAngularOffsetType = (VariableValueType)EditorGUILayout.EnumPopup(
                "Initial Angular Velocity Offset", asset.cloneInitialVelocityAngularOffsetType);

            switch (asset.cloneInitialVelocityAngularOffsetType)
            {
                case VariableValueType.None:
                    asset.cloneInitialVelocityAngularOffsetMin = Vector3.zero;
                    asset.cloneInitialVelocityAngularOffsetMax = Vector3.zero;
                    asset.cloneInitialVelocityAngularOffsetSpace = CoordSpace.World;
                    asset.cloneInitialVelocityAngularOffsetRandomization = RangeRandomization.None;
                    break;

                case VariableValueType.Random:
                    asset.cloneInitialVelocityAngularOffsetMin = Vector3.zero;
                    asset.cloneInitialVelocityAngularOffsetMax = Vector3.zero;
                    asset.cloneInitialVelocityAngularOffsetSpace = CoordSpace.World;
                    asset.cloneInitialVelocityAngularOffsetRandomization = RangeRandomization.Uniform;
                    break;

                case VariableValueType.Constant:
                    asset.cloneInitialVelocityAngularOffsetMin = EditorGUILayout.Vector3Field("Angular Offset:", asset.cloneInitialVelocityAngularOffsetMin);
                    asset.cloneInitialVelocityAngularOffsetSpace = (CoordSpace)EditorGUILayout.EnumPopup(
                        "Coord Space", asset.cloneInitialVelocityAngularOffsetSpace);
                    asset.cloneInitialVelocityAngularOffsetMax = asset.cloneInitialVelocityAngularOffsetMin;
                    asset.cloneInitialVelocityAngularOffsetRandomization = RangeRandomization.None;
                    break;

                case VariableValueType.Range:
                    asset.cloneInitialVelocityAngularOffsetMin = EditorGUILayout.Vector3Field("Angular Offset Min:", asset.cloneInitialVelocityAngularOffsetMin);
                    asset.cloneInitialVelocityAngularOffsetMax = EditorGUILayout.Vector3Field("Angular Offset Max:", asset.cloneInitialVelocityAngularOffsetMax);
                    asset.cloneInitialVelocityAngularOffsetSpace = (CoordSpace)EditorGUILayout.EnumPopup(
                        "Coord Space", asset.cloneInitialVelocityAngularOffsetSpace);
                    asset.cloneInitialVelocityAngularOffsetRandomization = (RangeRandomization)EditorGUILayout.EnumPopup(
                        "Randomization", asset.cloneInitialVelocityAngularOffsetRandomization);
                    break;
            }
        }

        serializedObject.ApplyModifiedProperties();

        if (GUI.changed)
            EditorUtility.SetDirty(target);
    }
}
