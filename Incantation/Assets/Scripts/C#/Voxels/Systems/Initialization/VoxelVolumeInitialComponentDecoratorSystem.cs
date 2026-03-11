using Incantation.Engine.Voxels.Components;
using System;
using Unity.Entities;
using Unity.Entities.Graphics;
using Unity.Mathematics;
using Unity.Rendering;
using Unity.Transforms;
using UnityEngine;
using UnityEngine.Rendering;

namespace Incantation.Engine.Voxels.Systems
{
    [UpdateInGroup(typeof(VoxelVolumeInitializationSystemGroup))]
    public partial class VoxelVolumeInitialComponentDecoratorSystem : SystemBase
    {
        // Singletons for Mesh and Material
        private RenderMeshArray renderMeshArray;

        protected override void OnCreate()
        {
            base.OnCreate();

            // Load default mesh and material once
            Mesh cube = GenerateCubeMesh();
            Material cleanMaterial = new Material(Shader.Find("Shader Graphs/VoxVolShader"));

            if (cleanMaterial == null)
                throw new Exception("Could not find Voxel Volume Shader (Did you forget to rename it to 'Shader Graphs/VoxVolShader' last time you copied it from ShaderGraph?)");

            Material[] matArray = { cleanMaterial };
            Mesh[] meshArray = { cube };

            renderMeshArray = new RenderMeshArray(matArray, meshArray);
            renderMeshArray.ComputeHash128();
        }

        protected override void OnUpdate()
        {
            var ecb = new EntityCommandBuffer(Unity.Collections.Allocator.Temp);

            // Query: entities with OriginalVoxelVolumeID but without GPUVoxelHeapState
            foreach (var (gridDimensions, matMeshInfo, entity) in SystemAPI.Query<
                RefRO<GridDimensions>,
                RefRW<MaterialMeshInfo>>()
                         .WithNone<GlobalVoxelHeapState>()
                         .WithEntityAccess())
            {
                // --- Add GPUVoxelHeapState ---
                var dims = gridDimensions.ValueRO.XYZ;
                uint size = dims.x * dims.y * dims.z;

                ecb.AddComponent(entity, new GlobalVoxelHeapState
                {
                    Offset = 0,
                    SyncInProgressOffset = 0,
                    Size = size,
                    SyncInProgressSize = 0,
                    Shared = false,
                    SyncInProgressShared = false,
                    Allocated = false,
                    FramesUntilSyncSwap = 0,
                });

                // --- Material properties ---
                ecb.AddComponent(entity, new OriginalVoxelVolumeGlobalOffset
                {
                    Value = 0
                });

                // --- Enableables ---
                ecb.AddComponent<NeedsGlobalVoxelReallocation>(entity);
                ecb.SetComponentEnabled<NeedsGlobalVoxelReallocation>(entity, true);

                ecb.AddComponent<NeedsGlobalVoxelDeallocation>(entity);
                ecb.SetComponentEnabled<NeedsGlobalVoxelDeallocation>(entity, false);

                ecb.AddComponent<GlobalVoxelSyncNeeded>(entity);
                ecb.SetComponentEnabled<GlobalVoxelSyncNeeded>(entity, false);

                ecb.AddComponent<GlobalVoxelSyncInProgress>(entity);
                ecb.SetComponentEnabled<GlobalVoxelSyncInProgress>(entity, false);

                ecb.AddComponent<NeedsDeletion>(entity);
                ecb.SetComponentEnabled<NeedsDeletion>(entity, false);

                // Hack to fix GPU instancing because Entitles Graphics is dumb
                matMeshInfo.ValueRW.Material = -1;
                ecb.SetSharedComponentManaged(entity, renderMeshArray);
            }

            // Apply all structural changes at once
            ecb.Playback(EntityManager);
            ecb.Dispose();
        }

        private static Mesh GenerateCubeMesh()
        {
            Mesh mesh = new Mesh();
            mesh.vertices = new Vector3[]
            {
        new Vector3(-0.5f,-0.5f,-0.5f),
        new Vector3(0.5f,-0.5f,-0.5f),
        new Vector3(0.5f,0.5f,-0.5f),
        new Vector3(-0.5f,0.5f,-0.5f),
        new Vector3(-0.5f,-0.5f,0.5f),
        new Vector3(0.5f,-0.5f,0.5f),
        new Vector3(0.5f,0.5f,0.5f),
        new Vector3(-0.5f,0.5f,0.5f)
            };
            mesh.triangles = new int[]
            {
        0,2,1, 0,3,2,
        1,2,6, 6,5,1,
        4,5,6, 6,7,4,
        2,3,6, 6,3,7,
        0,7,3, 0,4,7,
        0,1,5, 0,5,4
            };
            mesh.RecalculateNormals();
            return mesh;
        }
    }
}