using Incantation.Engine.Voxels.Components;
using Unity.Entities;
using UnityEngine;
using UnityEngine.Rendering.Universal.Internal;

namespace Incantation.Engine.Voxels.System
{

    [UpdateInGroup(typeof(GPUBuffersUpdateSystemGroup))]
    [UpdateAfter(typeof(GPUHeapAllocationSystem))]
    public partial class GPUGlobalVoxelBufferManagerSystem : SystemBase
    {
        private GraphicsBuffer voxelBuffer;

        protected override void OnCreate()
        {
            // Set globals once
            Shader.DisableKeyword("EDITOR_MODE");
            Shader.SetGlobalFloat("_DebugVisualizationMode", 0f);

            // Setup structured buffer
            voxelBuffer = new GraphicsBuffer(
                GraphicsBuffer.Target.Structured,
                GlobalConstants.MAX_GLOBAL_VOXELS,
                sizeof(uint)
            );

            Shader.SetGlobalBuffer("_Voxels", voxelBuffer);
        }

        protected override void OnDestroy()
        {
            voxelBuffer?.Dispose();
        }

        protected override void OnUpdate()
        {
            // GPUSyncNeeded and has DynamicBuffer of InitializationColorTopologyPackedVoxel -> Fill buffer initially
            // GPUSyncNeeded and doesn't have a DynamicBuffer of init data -> copy existing buffer to new region (Compute shader?)
            // In either case, toggle off GPUSyncNeeded and toggle on GPUSyncInProgress
        }
    }
}