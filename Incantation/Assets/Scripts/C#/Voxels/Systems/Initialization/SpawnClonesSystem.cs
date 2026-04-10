using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;
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
    [UpdateAfter(typeof(GPUOriginalVoxelBufferManagerSystem))]
    public partial struct SpawnClonesSystem : ISystem
    {
        public void OnCreate(ref SystemState state)
        {
            state.RequireForUpdate<InitializationCloneOffsets>();
        }

        public void OnUpdate(ref SystemState state)
        {
            var ecb = new EntityCommandBuffer(Allocator.Temp);

            foreach (var (cloneOffsets, transform, velocities, entity)
                in SystemAPI.Query<
                        DynamicBuffer<InitializationCloneOffsets>,
                        RefRO<LocalTransform>,
                        RefRO<PhysicsVelocity>>()
                    .WithEntityAccess())
            {
                float3 basePosition = transform.ValueRO.Position;
                quaternion baseRotation = transform.ValueRO.Rotation;
                float baseScale = transform.ValueRO.Scale;

                float3 baseLinearVelocity = velocities.ValueRO.Linear;
                float3 baseAngularVelocity = velocities.ValueRO.Angular;

                ecb.RemoveComponent<InitializationCloneOffsets>(entity);

                // Create clones
                for (int i = 0; i < cloneOffsets.Length; i++)
                {
                    float3 posOffset = cloneOffsets[i].Position;
                    float3 linearVelocityOffset = cloneOffsets[i].VelocityLinear;
                    float3 angularVelocityOffset = cloneOffsets[i].VelocityAngular;

                    Entity clone = ecb.Instantiate(entity);

                    float3 newPosition = basePosition + posOffset;
                    float3 newLinearVelocity = baseLinearVelocity + linearVelocityOffset;
                    float3 newAngularVelocity = baseAngularVelocity + angularVelocityOffset;

                    ecb.SetComponent(clone,
                        LocalTransform.FromPositionRotationScale(
                            newPosition,
                            baseRotation,
                            baseScale
                        ));

                    ecb.SetComponent(clone,
                        new PhysicsVelocity { 
                            Linear = newLinearVelocity,
                            Angular = newAngularVelocity
                        });

                }

                // Delete the placeholder prefab component (make sure a clone at that position is present if you want to preserve it)
                ecb.DestroyEntity(entity);
            }

            ecb.Playback(state.EntityManager);
            ecb.Dispose();
        }
    }
}