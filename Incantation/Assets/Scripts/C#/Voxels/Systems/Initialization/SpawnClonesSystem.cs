using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.System;
using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Transforms;

namespace Incantation.Engine.Voxels.Systems
{
    [BurstCompile]
    [UpdateInGroup(typeof(VoxelVolumeInitializationSystemGroup))]
    [UpdateAfter(typeof(GPUGlobalVoxelBufferManagerSystem))]
    public partial struct SpawnClonesSystem : ISystem
    {
        public void OnCreate(ref SystemState state)
        {
            state.RequireForUpdate<InitializationCloneOffset>();
        }

        public void OnUpdate(ref SystemState state)
        {
            var ecb = new EntityCommandBuffer(Allocator.Temp);

            foreach (var (cloneOffsets, transform, entity)
                in SystemAPI.Query<
                        DynamicBuffer<InitializationCloneOffset>,
                        RefRO<LocalTransform>>()
                    .WithEntityAccess())
            {
                float3 basePosition = transform.ValueRO.Position;
                quaternion baseRotation = transform.ValueRO.Rotation;
                float baseScale = transform.ValueRO.Scale;

                ecb.RemoveComponent<InitializationCloneOffset>(entity);

                // Create clones
                for (int i = 0; i < cloneOffsets.Length; i++)
                {
                    float3 offset = cloneOffsets[i].Offset;

                    Entity clone = ecb.Instantiate(entity);

                    float3 newPosition = basePosition + offset;

                    ecb.SetComponent(clone,
                        LocalTransform.FromPositionRotationScale(
                            newPosition,
                            baseRotation,
                            baseScale
                        ));

                }

                // Delete the placeholder prefab component (make sure a clone at that position is present if you want to preserve it)
                ecb.DestroyEntity(entity);
            }

            ecb.Playback(state.EntityManager);
            ecb.Dispose();
        }
    }
}