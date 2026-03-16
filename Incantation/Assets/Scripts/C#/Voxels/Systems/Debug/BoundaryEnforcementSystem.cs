using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;
using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Rendering;
using Unity.Transforms;

namespace Incantation.Engine.Voxels.Systems
{
    [UpdateInGroup(typeof(SimulationSystemGroup))]
    [BurstCompile]
    public partial struct BoundaryEnfrocementSystem : ISystem
    {
        // Small epsilon to keep entities fully inside bounds
        private static readonly float EPSILON = 0.0001f;

        [BurstCompile]
        public void OnUpdate(ref SystemState state)
        {
            // Get chunk extents
            float3 halfChunk = GlobalConstants.BROADPHASE_GRID_SIZE * 0.5f;

            var ecb = new EntityCommandBuffer(Allocator.Temp);

            // Delta time is not needed for this, just positions
            foreach (var (translation, bounds, linearVelocity, entity) in
                     SystemAPI.Query<RefRW<LocalTransform>, RefRW<WorldRenderBounds>, RefRW<PhysicsVelocity>>()
                              .WithAll<IsVoxelVolume>()
                              .WithEntityAccess())
            {
                float3 minBound = -halfChunk;
                float3 maxBound = halfChunk;

                float3 pos = translation.ValueRW.Position;
                float3 extents = bounds.ValueRO.Value.Extents;

                float3 newPos = pos;
                float3 newVel = linearVelocity.ValueRW.Linear;

                bool changed = false;

                for (int i = 0; i < 3; i++)
                {
                    float minPos = minBound[i] + extents[i] + EPSILON;
                    float maxPos = maxBound[i] - extents[i] - EPSILON;

                    if (pos[i] < minPos)
                    {
                        newPos[i] = minPos;
                        newVel[i] = math.abs(newVel[i]); // Push back positive
                        changed = true;
                    }
                    else if (pos[i] > maxPos)
                    {
                        newPos[i] = maxPos;
                        newVel[i] = -math.abs(newVel[i]); // Push back negative
                        changed = true;
                    }
                }

                if (changed)
                {
                    translation.ValueRW.Position = newPos;
                    linearVelocity.ValueRW.Linear = newVel;
                }
            }

            ecb.Playback(state.EntityManager);
            ecb.Dispose();
        }
    }
}