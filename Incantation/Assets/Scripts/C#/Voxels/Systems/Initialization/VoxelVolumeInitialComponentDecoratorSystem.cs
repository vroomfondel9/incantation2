using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Debug;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;
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

            foreach (var (gridDimensions, matMeshInfo, isDynamic, entity) in SystemAPI.Query<
                RefRO<GridDimensions>,
                RefRW<MaterialMeshInfo>,
                EnabledRefRO<IsDynamic>>()
                         .WithAll<InitializationColorTopologyPackedVoxel>()
                         .WithOptions(EntityQueryOptions.IgnoreComponentEnabledState)
                         .WithEntityAccess())
            {
                // --- Add OriginalDimensions ---
                var dims = gridDimensions.ValueRO.XYZ;
                uint size = dims.x * dims.y * dims.z;

                ecb.AddComponent(entity, new OriginalDimensions(dims.x, dims.y, dims.z));

                // --- Physics ---
                if (isDynamic.ValueRO)
                {
                    ecb.AddComponent(entity, new PhysicsVelocity
                    {
                        Angular = new float3(UnityEngine.Random.Range(-1.0f, 1.0f), UnityEngine.Random.Range(-1.0f, 1.0f), UnityEngine.Random.Range(-1.0f, 1.0f)),
                        Linear = new float3(UnityEngine.Random.Range(-1.0f, 1.0f), UnityEngine.Random.Range(-1.0f, 1.0f), UnityEngine.Random.Range(-1.0f, 1.0f))
                    });

                    ecb.AddComponent(entity, new PrevBroadphaseCellIndices
                    {
                        minExtentCellIndex = 0,
                        maxExtentCellIndex = 0
                    });
                }

                // --- Material properties ---
                ecb.AddComponent(entity, new OriginalVoxelVolumeGlobalOffset
                {
                    Value = 0
                });

                ecb.AddComponent(entity, new VolumeWideConstantColorOverride(0, 0, 0));

                // --- Dynamic Buffers ---
                DynamicBuffer<VolumeWideConstantColorOverrideEffect> effectBuffer = 
                    ecb.AddBuffer<VolumeWideConstantColorOverrideEffect>(entity);

                // Example for adding a damage effect
                //effectBuffer.Add(new VolumeWideConstantColorOverrideEffect(255, 0, 0,
                //    0.5f, 0.0f, false,
                //    1000, EasingFunction.LINEAR,
                //    1000, CompletionFunction.REMOVE));

                // --- Enableables ---
                ecb.AddComponent<IsVoxelVolume>(entity);
                ecb.SetComponentEnabled<IsVoxelVolume>(entity, true);

                ecb.AddComponent<NeedsDeletion>(entity);
                ecb.SetComponentEnabled<NeedsDeletion>(entity, false);

                ecb.AddComponent<ShouldUploadVoxelData>(entity);
                ecb.SetComponentEnabled<ShouldUploadVoxelData>(entity, false);

                ecb.AddComponent<IsBroadphaseRecorded>(entity);
                ecb.SetComponentEnabled<IsBroadphaseRecorded>(entity, false);

                // --- Debug Components ---
#if DEBUG_DRAW_NARROWPHASE
                ecb.AddComponent<DebugCollNearSphereHit>(entity);
                ecb.SetComponentEnabled<DebugCollNearSphereHit>(entity, false);

                ecb.AddComponent<DebugCollNearAABBHit>(entity);
                ecb.SetComponentEnabled<DebugCollNearAABBHit>(entity, false);

                ecb.AddComponent<DebugCollNearOBBHit>(entity);
                ecb.SetComponentEnabled<DebugCollNearOBBHit>(entity, false);
#endif

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