using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Systems;
using System;
using System.Runtime.InteropServices;
using Unity.Entities;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal.Internal;
using static Unity.Burst.Intrinsics.X86.Avx;

namespace Incantation.Engine.Voxels.System
{
    [UpdateInGroup(typeof(VoxelVolumeInitializationSystemGroup))]
    [UpdateAfter(typeof(CPUOriginalVoxelBlobAssetManagerSystem))]
    public partial class GPUOriginalVoxelBufferManagerSystem : SystemBase
    {
        // GPU Buffers
        private GraphicsBuffer origVoxelBuffer;

        protected override void OnCreate()
        {
            // Set globals once
            Shader.DisableKeyword("_EDITOR_MODE");
            Shader.SetGlobalFloat("_DebugVisualizationMode", 0f);

            // Setup structured buffers
            origVoxelBuffer = new GraphicsBuffer(
                GraphicsBuffer.Target.Structured,
                GlobalConstants.MAX_GLOBAL_ORIGINAL_VOXELS,
                sizeof(uint)
            );

            // Bind global buffers
            Shader.SetGlobalBuffer("_OriginalVoxels", origVoxelBuffer);
        }

        protected override void OnDestroy()
        {
            origVoxelBuffer?.Dispose();
        }

        protected override void OnUpdate()
        {
            // Get Command Buffers
            var cmd = CommandBufferPool.Get("GPUGlobalVoxelBufferManagerSystem");
            cmd.SetExecutionFlags(CommandBufferExecutionFlags.AsyncCompute);
            var ecb = new EntityCommandBuffer(Unity.Collections.Allocator.Temp);

            // Do Queries
            uploadData(cmd, ecb);
            reuseAlreadyUploadedSharedData(ecb);

            // Execute Command Buffers
            Graphics.ExecuteCommandBufferAsync(cmd, ComputeQueueType.Default);
            cmd.Clear();
            CommandBufferPool.Release(cmd);

            ecb.Playback(EntityManager);
            ecb.Dispose();
        }

        private void uploadData(CommandBuffer cmd, EntityCommandBuffer ecb)
        {
            foreach (var (origDimensions, origOffset, initialBuffer, entity)
                in SystemAPI.Query<
                        RefRO<OriginalDimensions>,
                        RefRO<OriginalVoxelVolumeGlobalOffset>,
                        DynamicBuffer<InitializationColorTopologyPackedVoxel>>()
                    .WithAll<ShouldUploadVoxelData, InitializationTopologyMetadata>()
                    .WithEntityAccess())
            {
                var origDim = origDimensions.ValueRO;
                var offset = origOffset.ValueRO;

                var initBuffer = SystemAPI.GetBuffer<InitializationColorTopologyPackedVoxel>(entity);
                if (initBuffer.Length != origDim.Size)
                    throw new Exception($"Mismatched voxel region sizes prior to initial copy into voxel buffer. {origDim.Size}=/={initBuffer.Length}");

                // Copy CPU buffer data to GPU voxel buffer asynchronously
                cmd.SetBufferData(origVoxelBuffer, initBuffer.AsNativeArray(), 0, (int)offset.Value, (int)origDim.Size);

                // Remove initialization components via ECB
                ecb.RemoveComponent<InitializationColorTopologyPackedVoxel>(entity);
                ecb.RemoveComponent<InitializationTopologyMetadata>(entity);
                ecb.SetComponentEnabled<ShouldUploadVoxelData>(entity, false);
            }
        }

        private void reuseAlreadyUploadedSharedData(EntityCommandBuffer ecb)
        {
            foreach (var (initialBuffer, entity)
                in SystemAPI.Query<
                        DynamicBuffer<InitializationColorTopologyPackedVoxel>>()
                    .WithDisabled<ShouldUploadVoxelData>()
                    .WithAll<InitializationTopologyMetadata>()
                    .WithEntityAccess())
            {
                // Remove initialization components via ECB
                ecb.RemoveComponent<InitializationColorTopologyPackedVoxel>(entity);
                ecb.RemoveComponent<InitializationTopologyMetadata>(entity);
            }
        }
    }
}