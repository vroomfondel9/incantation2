using Unity.Burst;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Transforms;

using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;

// TODO a temp system to test whether basic movement works and serve as a sample for usage

namespace Incantation.Engine.Voxels.Systems.Physics
{
    [UpdateInGroup(typeof(FixedStepSimulationSystemGroup))]
    [UpdateBefore(typeof(PhysicsSolverSystem))]
    [BurstCompile]
    public partial struct IntegrateVelocitySystem : ISystem
    {
        [BurstCompile]
        public void OnCreate(ref SystemState state)
        {
            state.RequireForUpdate<PhysicsVelocity>();
        }

        [BurstCompile]
        public void OnUpdate(ref SystemState state)
        {
            float dt = SystemAPI.Time.DeltaTime;

            foreach (var (transform, velocity, mass) in
                     SystemAPI.Query<
                        RefRW<LocalTransform>,
                        RefRO<PhysicsVelocity>,
                        RefRO<PhysicsMass>>()
                     .WithAll<IsDynamic>())
            {
                float3 position = transform.ValueRO.Position;
                quaternion rotation = transform.ValueRO.Rotation;

                float3 linear = velocity.ValueRO.Linear;
                float3 angular = velocity.ValueRO.Angular;
                float3 comOffset = mass.ValueRO.CenterOfMass;

                // --- Compute world-space center of mass ---
                float3 worldCOM = position + math.rotate(rotation, comOffset);

                // --- Integrate linear motion of the COM ---
                worldCOM += linear * dt;

                // --- Integrate angular motion ---
                float angularSpeed = math.length(angular);

                if (angularSpeed > 0f)
                {
                    float3 axis = angular / angularSpeed;
                    float angle = angularSpeed * dt;

                    quaternion dq = quaternion.AxisAngle(axis, angle);
                    rotation = math.normalize(math.mul(dq, rotation));
                }

                // --- Recompute pivot position so COM stays consistent ---
                position = worldCOM - math.rotate(rotation, comOffset);

                // --- Write back ---
                transform.ValueRW.Position = position;
                transform.ValueRW.Rotation = rotation;
            }
        }
    }
}