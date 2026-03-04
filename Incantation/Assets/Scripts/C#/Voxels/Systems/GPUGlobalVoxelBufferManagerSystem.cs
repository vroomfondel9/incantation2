using Incantation.Engine.Voxels.Components;
using System;
using System.Runtime.InteropServices;
using Unity.Entities;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal.Internal;

namespace Incantation.Engine.Voxels.System
{
    [UpdateInGroup(typeof(GPUBuffersUpdateSystemGroup))]
    [UpdateAfter(typeof(GPUHeapAllocationSystem))]
    public partial class GPUGlobalVoxelBufferManagerSystem : SystemBase
    {
        private float THREAD_GROUP_SIZE = 64.0f;

        // Kernel names
        private string KERNEL_NAME_COPY_VOXEL_VOLUMES = "CopyVoxVols";

        // Kernel ids
        private int kernelIdCopyVoxelVolumes;

        // GPU Buffers
        private GraphicsBuffer voxelBuffer;

        // Compute Shaders
        private ComputeShader copyVoxelRegionsShader;

        protected override void OnCreate()
        {
            // Find Shader
            var copyVoxelRegionsShaderConfig = 
                Resources.Load<ComputeShaderReference>("ComputeShaders/CopyGlobalVoxelsRegionsComputeShader");
            if (copyVoxelRegionsShaderConfig == null)
                throw new Exception("ComputeShaders/CopyGlobalVoxelsRegionsComputeShader not found in Resources or no shader set.");
            copyVoxelRegionsShader = copyVoxelRegionsShaderConfig.shader;

            // Set globals once
            Shader.DisableKeyword("_EDITOR_MODE");
            Shader.SetGlobalFloat("_DebugVisualizationMode", 0f);

            // Setup structured buffers
            voxelBuffer = new GraphicsBuffer(
                GraphicsBuffer.Target.Structured,
                GlobalConstants.MAX_GLOBAL_VOXELS,
                sizeof(uint)
            );

            // Bind Global Buffers
            Shader.SetGlobalBuffer("_Voxels", voxelBuffer);

            // Find Kernel IDs
            kernelIdCopyVoxelVolumes = copyVoxelRegionsShader.FindKernel(KERNEL_NAME_COPY_VOXEL_VOLUMES);

            // Bind buffers to kernels that won't change at runtime
            copyVoxelRegionsShader.SetBuffer(kernelIdCopyVoxelVolumes, "VoxelBuffer", voxelBuffer);
        }

        protected override void OnDestroy()
        {
            voxelBuffer?.Dispose();
        }

        protected override void OnUpdate()
        {
            // Get Command Buffers
            var cmd = CommandBufferPool.Get("GPUGlobalVoxelBufferManagerSystem");
            cmd.SetExecutionFlags(CommandBufferExecutionFlags.AsyncCompute);
            var ecb = new EntityCommandBuffer(Unity.Collections.Allocator.Temp);

            // Do Queries
            copyExistingVoxelRegions(cmd, ecb);
            populateInitializingVoxels(cmd, ecb);

            // Execute Command Buffers
            Graphics.ExecuteCommandBufferAsync(cmd, ComputeQueueType.Default);
            cmd.Clear();
            CommandBufferPool.Release(cmd);

            ecb.Playback(EntityManager);
            ecb.Dispose();
        }

        private void copyExistingVoxelRegions(CommandBuffer cmd, EntityCommandBuffer ecb)
        {
            foreach (var (heapState, entity)
                in SystemAPI.Query<
                        RefRO<GPUVoxelHeapState>>()
                    .WithAll<GPUSyncNeeded>()
                    .WithNone<GPUSyncInProgress, InitializationColorTopologyPackedVoxel>()
                    .WithEntityAccess())
            {
                var heap = heapState.ValueRO;

                if (heap.Size != heap.SyncInProgressSize)
                    throw new Exception($"Mismatched voxel region sizes prior to copy voxel kernel call. {heap.Size}=/={heap.SyncInProgressSize}");

                // Set compute shader constants
                copyVoxelRegionsShader.SetInt("Src", (int)heap.Offset);
                copyVoxelRegionsShader.SetInt("Dst", (int)heap.SyncInProgressOffset);
                copyVoxelRegionsShader.SetInt("Size", (int)heap.Size);

                int groups = Mathf.CeilToInt(heap.Size / THREAD_GROUP_SIZE);
                cmd.DispatchCompute(copyVoxelRegionsShader, kernelIdCopyVoxelVolumes, groups, 1, 1);

                // Toggle components
                SystemAPI.SetComponentEnabled<GPUSyncNeeded>(entity, false);
                SystemAPI.SetComponentEnabled<GPUSyncInProgress>(entity, true);
            }
        }

        private void populateInitializingVoxels(CommandBuffer cmd, EntityCommandBuffer ecb)
        {
            foreach (var (heapState, initialBuffer, entity)
                in SystemAPI.Query<
                        RefRO<GPUVoxelHeapState>,
                        DynamicBuffer<InitializationColorTopologyPackedVoxel>>()
                    .WithAll<GPUSyncNeeded>()
                    .WithNone<GPUSyncInProgress>()
                    .WithEntityAccess())
            {
                var heap = heapState.ValueRO;

                var initBuffer = SystemAPI.GetBuffer<InitializationColorTopologyPackedVoxel>(entity);
                if (initBuffer.Length != heap.Size)
                    throw new Exception($"Mismatched voxel region sizes prior to initial copy into voxel buffer. {heap.Size}=/={initBuffer.Length}");

                // Copy CPU buffer data to GPU voxel buffer asynchronously
                cmd.SetBufferData(voxelBuffer, initBuffer.AsNativeArray(), 0, (int) heap.SyncInProgressOffset, (int) heap.SyncInProgressSize);

                // Remove DynamicBuffer via ECB
                ecb.RemoveComponent<InitializationColorTopologyPackedVoxel>(entity);

                // Toggle components
                SystemAPI.SetComponentEnabled<GPUSyncNeeded>(entity, false);
                SystemAPI.SetComponentEnabled<GPUSyncInProgress>(entity, true);
            }
        }
    }
}