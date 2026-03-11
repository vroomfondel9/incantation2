using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.System;
using Unity.Burst;
using Unity.Collections;
using Unity.Entities;

namespace Incantation.Engine.Voxels.Systems
{
    /// <summary>
    /// Marks voxel volume initialization as complete.
    ///
    /// After GPUOriginalVoxelBufferManagerSystem finishes uploading voxel data,
    /// this system performs two cleanup tasks:
    ///
    /// 1. Removes InitializationColorTopologyPackedVoxel buffers from entities
    ///    since they are no longer needed after initialization.
    ///
    /// 2. Deletes entities marked with NeedsOriginalVoxelDeallocation to free
    ///    space for voxel volumes that were freshly deallocated.
    /// </summary>
    [BurstCompile]
    [UpdateInGroup(typeof(VoxelVolumeInitializationSystemGroup))]
    [UpdateAfter(typeof(SpawnClonesSystem))]
    public partial struct FinalizeInitializationSystem : ISystem
    {
        private EntityQuery _removeInitializationBufferQuery;
        private EntityQuery _deallocationQuery;

        public void OnCreate(ref SystemState state)
        {
            _removeInitializationBufferQuery = new EntityQueryBuilder(Allocator.Temp)
                .WithAll<InitializationColorTopologyPackedVoxel>()
                .Build(ref state);

            _deallocationQuery = new EntityQueryBuilder(Allocator.Temp)
                .WithAll<NeedsOriginalVoxelDeallocation>()
                .Build(ref state);
        }

        public void OnUpdate(ref SystemState state)
        {
            var ecb = new EntityCommandBuffer(state.WorldUpdateAllocator);

            // Remove initialization buffers
            foreach (var (buffer, entity) in
                SystemAPI.Query<DynamicBuffer<InitializationColorTopologyPackedVoxel>>()
                         .WithEntityAccess())
            {
                ecb.RemoveComponent<InitializationColorTopologyPackedVoxel>(entity);
            }

            // Destroy entities marked for original voxel deallocation
            foreach (var (needsDealloc, entity) in
                SystemAPI.Query<NeedsOriginalVoxelDeallocation>()
                         .WithEntityAccess())
            {
                ecb.DestroyEntity(entity);
            }

            ecb.Playback(state.EntityManager);
        }
    }
}