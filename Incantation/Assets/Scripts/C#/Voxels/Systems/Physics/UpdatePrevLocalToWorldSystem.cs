using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;
using Unity.Burst;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Transforms;

namespace Incantation.Engine.Voxels.Systems.Physics
{
    [BurstCompile]
    [UpdateInGroup(typeof(FixedStepSimulationSystemGroup))]
    [UpdateAfter(typeof(PhysicsSolverSystem))]
    public partial struct UpdatePrevLocalToWorldSystem : ISystem
    {
        [BurstCompile]
        public void OnCreate(ref SystemState state)
        {
            state.RequireForUpdate<PrevLocalToWorld>();
        }

        [BurstCompile]
        public void OnUpdate(ref SystemState state)
        {
            var job = new UpdatePrevLocalToWorldJob();

            state.Dependency = job.ScheduleParallel(state.Dependency);
        }

        [BurstCompile]
        [WithAll(typeof(IsVoxelVolume))]
        [WithAll(typeof(IsDynamic))]
        public partial struct UpdatePrevLocalToWorldJob : IJobEntity
        {
            public void Execute(ref PrevLocalToWorld prevLocalToWorld, in LocalToWorld localToWorld)
            {
                prevLocalToWorld.Value = localToWorld.Value;
            }
        }
    }
}