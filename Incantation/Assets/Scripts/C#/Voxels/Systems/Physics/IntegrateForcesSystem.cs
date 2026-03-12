using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;
using Unity.Burst;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Transforms;
using UnityEngine;

// TODO a temp system to test whether basic movement works and serve as a sample for usage
namespace Incantation.Engine.Voxels.Systems.Physics
{
    [UpdateInGroup(typeof(FixedStepSimulationSystemGroup))]
    [UpdateBefore(typeof(IntegrateVelocitySystem))]
    [BurstCompile]
    public partial struct IntegrateForcesSystem : ISystem
    {
        [BurstCompile]
        public void OnUpdate(ref SystemState state)
        {
            float dt = SystemAPI.Time.DeltaTime;

            foreach (var (transform, velocity, force, mass) in
                     SystemAPI.Query<
                        RefRO < LocalTransform >,
                        RefRW<PhysicsVelocity>,
                        RefRW<PhysicsForce>,
                        RefRO<PhysicsMass>>()
                     .WithAll<IsDynamic>())
            {
                float3 invInertia = mass.ValueRO.InverseInertia;

                // Linear acceleration
                velocity.ValueRW.Linear += force.ValueRO.Force * mass.ValueRO.InverseMass * dt;

                // Angular acceleration
                float3x3 R = new float3x3(transform.ValueRO.Rotation);

                float3x3 invInertiaLocal = float3x3.Scale(mass.ValueRO.InverseInertia);

                // I⁻¹_world = R * I⁻¹_local * Rᵀ
                float3x3 invInertiaWorld = math.mul(math.mul(R, invInertiaLocal), math.transpose(R));

                velocity.ValueRW.Angular += math.mul(invInertiaWorld, force.ValueRO.Torque) * dt;
                // Clear accumulators
                force.ValueRW.Force = float3.zero;
                force.ValueRW.Torque = float3.zero;
            }
        }
    }
}