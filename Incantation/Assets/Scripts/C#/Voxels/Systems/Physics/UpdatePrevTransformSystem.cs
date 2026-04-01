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
    public partial struct UpdatePrevTransformSystem : ISystem
    {
        [BurstCompile]
        public void OnCreate(ref SystemState state)
        {
            state.RequireForUpdate<PrevTransform>();
        }

        [BurstCompile]
        public void OnUpdate(ref SystemState state)
        {
            var job = new UpdatePrevTransformJob();

            state.Dependency = job.ScheduleParallel(state.Dependency);
        }

        [BurstCompile]
        [WithAll(typeof(IsVoxelVolume))]
        [WithAll(typeof(IsDynamic))]
        public partial struct UpdatePrevTransformJob : IJobEntity
        {
            public void Execute(ref PrevTransform prevTransform, in LocalTransform localTransform)
            {
                prevTransform.position = localTransform.Position;
                prevTransform.rotation = localTransform.Rotation;
            }
        }
    }
}