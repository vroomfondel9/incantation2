using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;
using Incantation.Engine.Voxels.Systems.Physics.Support;
using System.Linq;
using Unity.Burst;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Entities;
using Unity.Jobs;
using Unity.Jobs.LowLevel.Unsafe;
using Unity.Mathematics;
using Unity.Rendering;
using Unity.Transforms;

namespace Incantation.Engine.Voxels.Systems.Physics
{
    [BurstCompile]
    [UpdateInGroup(typeof(FixedStepSimulationSystemGroup))]
    public partial struct PhysicsSolverSystem : ISystem
    {
        #region STATE AND LIFECYCLE

        NativeParallelMultiHashMap<BroadphaseCell, Entity> broadphaseDynamic;
        NativeParallelMultiHashMap<BroadphaseCell, Entity> broadphaseStatic;

        NativeQueue<BroadphaseEntityInCell> dynamicRemovalQueue;
        NativeQueue<BroadphaseEntityInCell> staticRemovalQueue;

        NativeArray<PhysicsSolverStatsThreadLocal> threadStatsUpdatesDynamic;
        NativeArray<PhysicsSolverStatsThreadLocal> threadStatsSpawnDynamic;
        NativeArray<PhysicsSolverStatsThreadLocal> threadStatsSpawnStatic;
        NativeArray<PhysicsSolverStatsThreadLocal> threadStatsDespawnDynamic;
        NativeArray<PhysicsSolverStatsThreadLocal> threadStatsDespawnStatic;

        Entity statsEntity;

        public void OnCreate(ref SystemState state)
        {
            int totalCells =
                (int)(GlobalConstants.MIN_GRID_CELLS_PER_CHUNK.x *
                      GlobalConstants.MIN_GRID_CELLS_PER_CHUNK.y *
                      GlobalConstants.MIN_GRID_CELLS_PER_CHUNK.z);

            int capacity = totalCells * 4;

            // Create data structures
            broadphaseDynamic = new NativeParallelMultiHashMap<BroadphaseCell, Entity>(capacity, Allocator.Persistent);
            broadphaseStatic = new NativeParallelMultiHashMap<BroadphaseCell, Entity>(capacity, Allocator.Persistent);

            dynamicRemovalQueue = new NativeQueue<BroadphaseEntityInCell>(Allocator.Persistent);
            staticRemovalQueue = new NativeQueue<BroadphaseEntityInCell>(Allocator.Persistent);

            threadStatsUpdatesDynamic = new NativeArray<PhysicsSolverStatsThreadLocal>(JobsUtility.MaxJobThreadCount,Allocator.Persistent);
            threadStatsSpawnDynamic = new NativeArray<PhysicsSolverStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            threadStatsSpawnStatic = new NativeArray<PhysicsSolverStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            threadStatsDespawnDynamic = new NativeArray<PhysicsSolverStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            threadStatsDespawnStatic = new NativeArray<PhysicsSolverStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);


            // Create Singletons
            state.EntityManager.CreateSingleton<PhysicsSolverStats>();
        }

        public void OnDestroy(ref SystemState state)
        {
            if (broadphaseDynamic.IsCreated) broadphaseDynamic.Dispose();
            if (broadphaseStatic.IsCreated) broadphaseStatic.Dispose();
            if (dynamicRemovalQueue.IsCreated) dynamicRemovalQueue.Dispose();
            if (staticRemovalQueue.IsCreated) staticRemovalQueue.Dispose();

            if (threadStatsUpdatesDynamic.IsCreated) threadStatsUpdatesDynamic.Dispose();
            if (threadStatsSpawnDynamic.IsCreated) threadStatsSpawnDynamic.Dispose();
            if (threadStatsSpawnStatic.IsCreated) threadStatsSpawnStatic.Dispose();
            if (threadStatsDespawnDynamic.IsCreated) threadStatsDespawnDynamic.Dispose();
            if (threadStatsDespawnStatic.IsCreated) threadStatsDespawnStatic.Dispose();
        }

        public void OnUpdate(ref SystemState state)
        {
            clearStats();

            onUpdateBroadphaseSetup(ref state);

            aggregateStats(ref state);
        }

        #endregion

        #region PREP PHASE 1 - BROADPHASE SETUP

        // -------------------------------------------------
        // BROADPHASE
        // -------------------------------------------------
        // ------------------------------------------------------------
        //
        // 1. Schedule jobs
        //    ├─ q1 : UpdateDynamicBroadphaseJob
        //    │      Updates dynamic entities that moved between cells
        //    │      Adds new cell entries and queues old ones for removal
        //    │
        //    ├─ q2 : SpawnDynamicBroadphaseJob
        //    │      Initializes newly spawned dynamic entities
        //    │      Adds them to broadphaseDynamic
        //    │      Records their cell extents via ECB
        //    │
        //    ├─ q3 : SpawnStaticBroadphaseJob
        //    │      Initializes newly spawned static entities
        //    │      Adds them to broadphaseStatic
        //    │      Marks them as recorded via ECB
        //    │
        //    ├─ q4 : CleanupDynamicBroadphaseJob
        //    │      Handles dynamic entities flagged for deletion
        //    │      Queues all occupied cells for removal
        //    │
        //    └─ q5 : CleanupStaticBroadphaseJob
        //           Handles static entities flagged for deletion
        //           Queues all occupied cells for removal
        //
        // 2. Parallel execution
        //    All jobs run concurrently on worker threads.
        //    Jobs write additions directly to the broadphase maps and
        //    enqueue removals into removal queues.
        //
        // 3. Job Interdependencies
        //    Conceptually, these are all totally independent, however
        //    a safety check by ECS prevents all the dynamic jobs from
        //    being run at the same time because they all read and write
        //    to the same component (storing last frame's morton codes).
        //    The fact that each of these jobs will always operate on a 
        //    mutually exclusive set of entities due to the way their
        //    quiries are structured is not something ECS checks for,
        //    and there's no mechanism for overriding that safety block.
        //    Therefore, they are each programmed as dependent on each other
        //    Even though they're really not.
        //
        // 4. ECB Playback
        //    Structural changes recorded during jobs are applied:
        //      • PrevBroadphaseCellIndices set for new or updated dynamic entities
        //      • IsBroadphaseRecorded enabled
        //
        //    These changes become visible to ECS queries starting next frame.
        //
        // 5. Apply removal queues (main thread)
        //    All queued BroadphaseEntityInCell entries are processed and
        //    removed from the appropriate broadphase hash maps.
        //
        // 6. Broadphase state is now fully updated and ready for the
        //    next physics stage (pair generation).
        // ------------------------------------------------------------
        private void onUpdateBroadphaseSetup(ref SystemState state)
        {
            float cellSize = GlobalConstants.MIN_CHUNK_GRID_CELL_SIZE;
            float3 worldHalf = GlobalConstants.CHUNK_SIZE * 0.5f;

            var ecbDynamic = new EntityCommandBuffer(Allocator.TempJob);
            var ecbStatic = new EntityCommandBuffer(Allocator.TempJob);

            dynamicRemovalQueue.Clear();
            staticRemovalQueue.Clear();

            var dynamicWriter = broadphaseDynamic.AsParallelWriter();
            var staticWriter = broadphaseStatic.AsParallelWriter();

            var dynamicRemovalWriter = dynamicRemovalQueue.AsParallelWriter();
            var staticRemovalWriter = staticRemovalQueue.AsParallelWriter();

            // ------------------------------
            // BROADPHASE SETUP - QUERY HOT (Dynamic, already initialized, compares this frame to last for changes)
            // ------------------------------

            var q1 = new UpdateDynamicBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                BroadphaseDynamic = dynamicWriter,
                RemovalQueue = dynamicRemovalWriter,
                ThreadStats = threadStatsUpdatesDynamic
            };

            var h1 = q1.ScheduleParallel(state.Dependency);

            // ------------------------------
            // BROADPHASE SETUP - QUERY Init dynamic just spawned
            // ------------------------------

            var q2 = new SpawnDynamicBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                BroadphaseDynamic = dynamicWriter,
                ECB = ecbDynamic.AsParallelWriter(),
                ThreadStats = threadStatsSpawnDynamic
            };

            var h2 = q2.ScheduleParallel(h1);

            // ------------------------------
            // BROADPHASE SETUP - Init Static just spawned
            // ------------------------------

            var q3 = new SpawnStaticBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                BroadphaseStatic = staticWriter,
                ECB = ecbStatic.AsParallelWriter(),
                ThreadStats = threadStatsSpawnStatic
            };

            var h3 = q3.ScheduleParallel(state.Dependency);

            // ------------------------------
            // BROADPHASE SETUP - QUERY cleanup dynamic prior to deletion
            // ------------------------------

            var q4 = new CleanupDynamicBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                RemovalQueue = dynamicRemovalWriter,
                ThreadStats = threadStatsDespawnDynamic
            };

            var h4 = q4.ScheduleParallel(h2);

            // ------------------------------
            // BROADPHASE SETUP - QUERY cleanup static prior to deletion
            // ------------------------------

            var q5 = new CleanupStaticBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                RemovalQueue = staticRemovalWriter,
                ThreadStats = threadStatsDespawnStatic
            };

            var h5 = q5.ScheduleParallel(state.Dependency);

            state.Dependency = JobHandle.CombineDependencies(h3, h4, h5);

            state.Dependency.Complete();

            ecbDynamic.Playback(state.EntityManager);
            ecbStatic.Playback(state.EntityManager);

            ecbDynamic.Dispose();
            ecbStatic.Dispose();

            // ------------------------------------------------
            // APPLY REMOVALS (MAIN THREAD)
            // ------------------------------------------------

            while (dynamicRemovalQueue.TryDequeue(out var item))
            {
                broadphaseDynamic.Remove(item.Cell, item.Entity);
            }

            while (staticRemovalQueue.TryDequeue(out var item))
            {
                broadphaseStatic.Remove(item.Cell, item.Entity);
            }
        }

        // -------------------------------------------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
        // BROADPHASE SETUP - QUERY HOT (Dynamic, already initialized, compares this frame to last for changes)
        // -------------------------------------------------

        [BurstCompile]
        [WithAll(typeof(IsDynamic))]
        [WithNone(typeof(NeedsDeletion))]
        [WithAll(typeof(IsBroadphaseRecorded))]
        partial struct UpdateDynamicBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeParallelMultiHashMap<BroadphaseCell, Entity>.ParallelWriter BroadphaseDynamic;
            public NativeQueue<BroadphaseEntityInCell>.ParallelWriter RemovalQueue;

            [NativeDisableParallelForRestriction]
            public NativeArray<PhysicsSolverStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;

            void Execute(
                Entity entity,
                ref PrevBroadphaseCellIndices prevIndices,
                in WorldRenderBounds bounds,
                EnabledRefRO<IsDynamic> isDynamic,
                EnabledRefRO<IsBroadphaseRecorded> recorded)
            {
                if (!isDynamic.ValueRO || !recorded.ValueRO)
                    return;

                var stats = ThreadStats[threadIndex];

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                BroadphaseCell minCellStruct = new BroadphaseCell((uint)minCell.x, (uint)minCell.y, (uint)minCell.z);
                BroadphaseCell maxCellStruct = new BroadphaseCell((uint)maxCell.x, (uint)maxCell.y, (uint)maxCell.z);

                uint newMinMorton = minCellStruct.Morton;
                uint newMaxMorton = maxCellStruct.Morton;

                if (newMinMorton == prevIndices.minExtentCellIndex &&
                    newMaxMorton == prevIndices.maxExtentCellIndex)
                {
                    stats.countVolumesDidNotUpdateGrid++;
                    return;
                }

                stats.countVolumesUpdatedGrid++;

                uint3 prevMin = BroadphaseCell.DecodeMorton(prevIndices.minExtentCellIndex);
                uint3 prevMax = BroadphaseCell.DecodeMorton(prevIndices.maxExtentCellIndex);

                uint3 prevCellVolumeDims = prevMax - prevMin;
                int3 curCellVolumeDims = maxCell - minCell;
                int prevCellVolume = (int)(prevCellVolumeDims.x * prevCellVolumeDims.y * prevCellVolumeDims.z);
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                int volumeDiff = curCellVolume - prevCellVolume;
                stats.totalVolumeCells += volumeDiff;
                stats.maxCellsPerVolume = math.max(stats.maxCellsPerVolume, curCellVolume);

                uint3 intersectMin = math.max(prevMin, (uint3)minCell);
                uint3 intersectMax = math.min(prevMax, (uint3)maxCell);

                for (uint x = prevMin.x; x <= prevMax.x; x++)
                    for (uint y = prevMin.y; y <= prevMax.y; y++)
                        for (uint z = prevMin.z; z <= prevMax.z; z++)
                        {
                            if (x >= intersectMin.x && x <= intersectMax.x &&
                                y >= intersectMin.y && y <= intersectMax.y &&
                                z >= intersectMin.z && z <= intersectMax.z)
                                continue;

                            RemovalQueue.Enqueue(new BroadphaseEntityInCell(
                                new BroadphaseCell(x, y, z), entity));

                            stats.broadphaseCellRemovals++;
                        }

                for (uint x = (uint)minCell.x; x <= (uint)maxCell.x; x++)
                    for (uint y = (uint)minCell.y; y <= (uint)maxCell.y; y++)
                        for (uint z = (uint)minCell.z; z <= (uint)maxCell.z; z++)
                        {
                            if (x >= intersectMin.x && x <= intersectMax.x &&
                                y >= intersectMin.y && y <= intersectMax.y &&
                                z >= intersectMin.z && z <= intersectMax.z)
                                continue;

                            BroadphaseDynamic.Add(new BroadphaseCell(x, y, z), entity);

                            stats.broadphaseCellAdds++;
                        }

                prevIndices.minExtentCellIndex = newMinMorton;
                prevIndices.maxExtentCellIndex = newMaxMorton;

                ThreadStats[threadIndex] = stats;
            }
        }

        // -------------------------------------------------
        // BROADPHASE SETUP - QUERY Init dynamic just spawned
        // -------------------------------------------------

        [BurstCompile]
        [WithAll(typeof(IsDynamic))]
        [WithNone(typeof(NeedsDeletion))]
        [WithNone(typeof(IsBroadphaseRecorded))]
        partial struct SpawnDynamicBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeParallelMultiHashMap<BroadphaseCell, Entity>.ParallelWriter BroadphaseDynamic;
            public EntityCommandBuffer.ParallelWriter ECB;

            [NativeDisableParallelForRestriction]
            public NativeArray<PhysicsSolverStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;

            void Execute(
                [ChunkIndexInQuery] int chunkIndex,
                Entity entity,
                ref PrevBroadphaseCellIndices prevIndices,
                in WorldRenderBounds bounds)
            {
                var stats = ThreadStats[threadIndex];

                stats.numVolumes++;
                stats.countVolumesUpdatedGrid++;

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                int3 curCellVolumeDims = maxCell - minCell;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                stats.totalVolumeCells += curCellVolume;
                stats.maxCellsPerVolume = math.max(stats.maxCellsPerVolume, curCellVolume);

                for (int x = minCell.x; x <= maxCell.x; x++)
                    for (int y = minCell.y; y <= maxCell.y; y++)
                        for (int z = minCell.z; z <= maxCell.z; z++)
                        {
                            BroadphaseDynamic.Add(new BroadphaseCell((uint)x, (uint)y, (uint)z), entity);

                            stats.broadphaseCellAdds++;
                        }

                BroadphaseCell minCellStruct = new BroadphaseCell((uint)minCell.x, (uint)minCell.y, (uint)minCell.z);
                BroadphaseCell maxCellStruct = new BroadphaseCell((uint)maxCell.x, (uint)maxCell.y, (uint)maxCell.z);

                prevIndices.minExtentCellIndex = minCellStruct.Morton;
                prevIndices.maxExtentCellIndex = maxCellStruct.Morton;

                ECB.SetComponentEnabled<IsBroadphaseRecorded>(chunkIndex, entity, true);

                ThreadStats[threadIndex] = stats;
            }
        }

        // -------------------------------------------------
        // BROADPHASE SETUP - Init Static just spawned
        // -------------------------------------------------

        [BurstCompile]
        [WithNone(typeof(IsDynamic))]
        [WithNone(typeof(NeedsDeletion))]
        [WithNone(typeof(IsBroadphaseRecorded))]
        partial struct SpawnStaticBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeParallelMultiHashMap<BroadphaseCell, Entity>.ParallelWriter BroadphaseStatic;
            public EntityCommandBuffer.ParallelWriter ECB;

            [NativeDisableParallelForRestriction]
            public NativeArray<PhysicsSolverStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;

            void Execute(
                [ChunkIndexInQuery] int chunkIndex,
                Entity entity,
                in WorldRenderBounds bounds)
            {
                var stats = ThreadStats[threadIndex];

                stats.numVolumes++;
                stats.countVolumesUpdatedGrid++;

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                int3 curCellVolumeDims = maxCell - minCell;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                stats.totalVolumeCells += curCellVolume;
                stats.maxCellsPerVolume = math.max(stats.maxCellsPerVolume, curCellVolume);

                for (int x = minCell.x; x <= maxCell.x; x++)
                    for (int y = minCell.y; y <= maxCell.y; y++)
                        for (int z = minCell.z; z <= maxCell.z; z++)
                        {
                            BroadphaseStatic.Add(new BroadphaseCell((uint)x, (uint)y, (uint)z), entity);

                            stats.broadphaseCellAdds++;
                        }

                ECB.SetComponentEnabled<IsBroadphaseRecorded>(chunkIndex, entity, true);

                ThreadStats[threadIndex] = stats;
            }
        }

        // -------------------------------------------------
        // BROADPHASE SETUP - QUERY cleanup dynamic prior to deletion
        // -------------------------------------------------

        [BurstCompile]
        [WithAll(typeof(IsDynamic))]
        [WithAll(typeof(NeedsDeletion))]
        partial struct CleanupDynamicBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeQueue<BroadphaseEntityInCell>.ParallelWriter RemovalQueue;

            [NativeDisableParallelForRestriction]
            public NativeArray<PhysicsSolverStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;

            void Execute(
                Entity entity,
                in WorldRenderBounds bounds,
                in PrevBroadphaseCellIndices prev)
            {
                var stats = ThreadStats[threadIndex];

                stats.numVolumes--;
                stats.countVolumesUpdatedGrid++;

                uint3 min = BroadphaseCell.DecodeMorton(prev.minExtentCellIndex);
                uint3 max = BroadphaseCell.DecodeMorton(prev.maxExtentCellIndex);

                uint3 curCellVolumeDims = max - min;
                int curCellVolume = (int)(curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z);
                stats.totalVolumeCells -= curCellVolume;

                for (uint x = min.x; x <= max.x; x++)
                    for (uint y = min.y; y <= max.y; y++)
                        for (uint z = min.z; z <= max.z; z++)
                        {
                            RemovalQueue.Enqueue(new BroadphaseEntityInCell(
                                new BroadphaseCell(x, y, z), entity));

                            stats.broadphaseCellRemovals++;
                        }

                ThreadStats[threadIndex] = stats;
            }
        }

        // -------------------------------------------------
        // BROADPHASE SETUP - QUERY cleanup static prior to deletion
        // -------------------------------------------------

        [BurstCompile]
        [WithNone(typeof(IsDynamic))]
        [WithAll(typeof(NeedsDeletion))]
        partial struct CleanupStaticBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeQueue<BroadphaseEntityInCell>.ParallelWriter RemovalQueue;

            [NativeDisableParallelForRestriction]
            public NativeArray<PhysicsSolverStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;

            void Execute(
                Entity entity,
                in WorldRenderBounds bounds)
            {
                var stats = ThreadStats[threadIndex];

                stats.numVolumes--;
                stats.countVolumesUpdatedGrid++;

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                int3 curCellVolumeDims = maxCell - minCell;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                stats.totalVolumeCells -= curCellVolume;

                for (int x = minCell.x; x <= maxCell.x; x++)
                    for (int y = minCell.y; y <= maxCell.y; y++)
                        for (int z = minCell.z; z <= maxCell.z; z++)
                        {
                            RemovalQueue.Enqueue(new BroadphaseEntityInCell(
                                new BroadphaseCell((uint)x, (uint)y, (uint)z), entity));

                            stats.broadphaseCellRemovals++;
                        }

                ThreadStats[threadIndex] = stats;
            }
        }

        #endregion

        #region MISC - PHYSICS STATS COLLECTION
        // This is 32-128 items so don't worry about parallelizing
        private void clearStats()
        {
            for (int i = 0; i < threadStatsUpdatesDynamic.Length; i++)
                threadStatsUpdatesDynamic[i] = default;

            for (int i = 0; i < threadStatsSpawnDynamic.Length; i++)
                threadStatsSpawnDynamic[i] = default;

            for (int i = 0; i < threadStatsSpawnStatic.Length; i++)
                threadStatsSpawnStatic[i] = default;

            for (int i = 0; i < threadStatsDespawnDynamic.Length; i++)
                threadStatsDespawnDynamic[i] = default;

            for (int i = 0; i < threadStatsDespawnStatic.Length; i++)
                threadStatsDespawnStatic[i] = default;
        }

        private void aggregateStats(ref SystemState state)
        {
            var existingStatsRW = SystemAPI.GetSingletonRW<PhysicsSolverStats>();
            ref var existingStats = ref existingStatsRW.ValueRW;
            PhysicsSolverStats finalStats = default;

            for (int i = 0; i < threadStatsUpdatesDynamic.Length; i++)
            {
                var s = threadStatsUpdatesDynamic[i];

                finalStats.broadphaseCellAddsDynamic += s.broadphaseCellAdds;
                finalStats.broadphaseCellRemovalsDynamic += s.broadphaseCellRemovals;
                finalStats.countVolumesDidNotUpdateGrid += s.countVolumesDidNotUpdateGrid;
                finalStats.countVolumesUpdatedGrid += s.countVolumesUpdatedGrid;
                finalStats.totalDynamicVolumeCells += s.totalVolumeCells;
                finalStats.numDynamicVolumes += s.numVolumes;
                finalStats.maxCellsPerVolumeDynamic = math.max(finalStats.maxCellsPerVolumeDynamic, s.maxCellsPerVolume);
            }

            for (int i = 0; i < threadStatsSpawnDynamic.Length; i++)
            {
                var s = threadStatsSpawnDynamic[i];

                finalStats.broadphaseCellAddsDynamic += s.broadphaseCellAdds;
                finalStats.countVolumesUpdatedGrid += s.countVolumesUpdatedGrid;
                finalStats.totalDynamicVolumeCells += s.totalVolumeCells;
                finalStats.numDynamicVolumes += s.numVolumes;
                finalStats.maxCellsPerVolumeDynamic = math.max(finalStats.maxCellsPerVolumeDynamic, s.maxCellsPerVolume);
            }

            for (int i = 0; i < threadStatsSpawnStatic.Length; i++)
            {
                var s = threadStatsSpawnStatic[i];

                finalStats.broadphaseCellAddsStatic += s.broadphaseCellAdds;
                finalStats.countVolumesUpdatedGrid += s.countVolumesUpdatedGrid;
                finalStats.totalStaticVolumeCells += s.totalVolumeCells;
                finalStats.numStaticVolumes += s.numVolumes;
                finalStats.maxCellsPerVolumeStatic = math.max(finalStats.maxCellsPerVolumeDynamic, s.maxCellsPerVolume);
            }

            for (int i = 0; i < threadStatsDespawnDynamic.Length; i++)
            {
                var s = threadStatsDespawnDynamic[i];

                finalStats.broadphaseCellRemovalsDynamic += s.broadphaseCellRemovals;
                finalStats.countVolumesUpdatedGrid += s.countVolumesUpdatedGrid;
                finalStats.totalDynamicVolumeCells += s.totalVolumeCells;
                finalStats.numDynamicVolumes += s.numVolumes;
            }

            for (int i = 0; i < threadStatsDespawnStatic.Length; i++)
            {
                var s = threadStatsDespawnStatic[i];

                finalStats.broadphaseCellRemovalsStatic += s.broadphaseCellRemovals;
                finalStats.countVolumesUpdatedGrid += s.countVolumesUpdatedGrid;
                finalStats.totalStaticVolumeCells += s.totalVolumeCells;
                finalStats.numStaticVolumes += s.numVolumes;
            }

            finalStats.totalDynamicVolumeCells += existingStats.totalDynamicVolumeCells;
            finalStats.totalStaticVolumeCells += existingStats.totalStaticVolumeCells;

            finalStats.numDynamicVolumes += existingStats.numDynamicVolumes;
            finalStats.numStaticVolumes += existingStats.numStaticVolumes;

            finalStats.maxCellsPerVolumeDynamic = math.max(finalStats.maxCellsPerVolumeDynamic, existingStats.maxCellsPerVolumeDynamic);
            finalStats.maxCellsPerVolumeStatic = math.max(finalStats.maxCellsPerVolumeStatic, existingStats.maxCellsPerVolumeStatic);

            finalStats.cellsPerVolumeDynamic = finalStats.numDynamicVolumes > 0 ? 
                finalStats.totalDynamicVolumeCells / ((float)finalStats.numDynamicVolumes) : 0.0f;
            finalStats.cellsPerVolumeStatic = finalStats.numStaticVolumes > 0 ?
                finalStats.totalStaticVolumeCells / ((float)finalStats.numStaticVolumes) : 0.0f;

            finalStats.updateRateDynamic = finalStats.numDynamicVolumes > 0 ?
                finalStats.countVolumesUpdatedGrid / ((float)finalStats.numDynamicVolumes) : 0.0f;

            //Assign to values to singleton
            existingStats = finalStats;
        }
        #endregion
    }
}