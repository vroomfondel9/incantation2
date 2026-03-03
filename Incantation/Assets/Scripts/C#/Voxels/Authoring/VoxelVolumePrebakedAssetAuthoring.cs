using System;
using System.Collections.Generic;
using UnityEngine;

using Incantation.Engine.Voxels.Components;

namespace Incantation.Engine.Voxels.Authoring
{
    //Basically just a container for a VoxelVolumePrebakedAsset read from disk because authoring components have to be MonoBehaviors
    [Serializable]
    public class VoxelVolumePrebakedAssetAuthoring : MonoBehaviour
    {
        [SerializeField]
        public VoxelVolumePrebakedAsset voxelVolumePrebakedAsset;

        public VoxelVolumePrebakedAsset VoxelVolumePrebakedAsset
        {
            get => voxelVolumePrebakedAsset;
            set => voxelVolumePrebakedAsset = value;
        }
    }
}