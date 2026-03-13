using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.System;
using Unity.Burst;
using Unity.Collections;
using Unity.Entities;

namespace Incantation.Engine.Voxels.Systems
{
    /// <summary>
    /// Removes volume entities ready for deletion. This should execute last in system order
    /// to give all other systems time to cleanup.
    ///
    ///
    ///    Deletes entities marked with NeedsDeletion to free
    ///    resources.
    /// </summary>
    [BurstCompile]
    [UpdateInGroup(typeof(PresentationSystemGroup))]
    public partial struct DeleteVolumeSystem : ISystem
    {
        private EntityQuery _deallocationQuery;

        public void OnCreate(ref SystemState state)
        {
            _deallocationQuery = new EntityQueryBuilder(Allocator.Temp)
                .WithAll<NeedsDeletion>()
                .Build(ref state);
        }

        public void OnUpdate(ref SystemState state)
        {
            var ecb = new EntityCommandBuffer(state.WorldUpdateAllocator);

            // Destroy entities marked for original voxel deallocation
            foreach (var (needsDealloc, entity) in
                SystemAPI.Query<NeedsDeletion>()
                         .WithEntityAccess())
            {
                ecb.DestroyEntity(entity);
            }

            ecb.Playback(state.EntityManager);
        }
    }
}