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

        [SerializeField]
        public long count = 1;

        [SerializeField]
        public Vector3 spacing = Vector3.zero;

        public VoxelVolumePrebakedAsset VoxelVolumePrebakedAsset
        {
            get => voxelVolumePrebakedAsset;
            set => voxelVolumePrebakedAsset = value;
        }
    }
}