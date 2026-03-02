using System;
using System.Collections.Generic;
using UnityEngine;

using Incantation.Engine.Voxels.Components;

namespace Incantation.Engine.Voxels.Authoring
{
    /// <summary>
    /// Authoring-side container for expensive precomputed voxel volume data.
    /// 
    /// This class is a POCO (Plain Old CLR Object) used to cache values
    /// so that entity conversion at game startup is fast.
    /// 
    /// During baking, its contents are copied onto the entity:
    /// - VoxelVolumeID -> IComponentData
    /// - GPUHeapLocation -> IComponentData
    /// - Voxels -> DynamicBuffer<Voxel>
    /// </summary>
    [Serializable]
    public class PrebakedVoxelVolumeAuthoring : MonoBehaviour
    {
        // =========================
        // Core Components
        // =========================

        [SerializeField]
        public VoxelVolumeID voxelVolumeID;

        [SerializeField]
        public GPUHeapVoxelState gpuHeapVoxelState;

        // =========================
        // Voxel Data (temporary holder)
        // =========================

        [SerializeField]
        private List<Voxel> voxels = new List<Voxel>();

        public VoxelVolumeID VoxelVolumeID
        {
            get => voxelVolumeID;
            set => voxelVolumeID = value;
        }

        public GPUHeapVoxelState GPUHeapVoxelState
        {
            get => gpuHeapVoxelState;
            set => gpuHeapVoxelState = value;
        }

        /// <summary>
        /// Read-only access to voxel list.
        /// Modify through SetVoxels for safety.
        /// </summary>
        public IReadOnlyList<Voxel> Voxels => voxels;

        public void SetVoxels(List<Voxel> newVoxels)
        {
            voxels = newVoxels ?? new List<Voxel>();
        }
    }
}