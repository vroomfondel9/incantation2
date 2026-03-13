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

        NativeArray<PhysicsSolverStatsThreadLocal> threadStats;

        Entity statsEntity;

        public void OnCreate(ref SystemState state)
        {
            int totalCells =
                (int)(GlobalConstants.MIN_GRID_CELLS_PER_CHUNK.x *
                      GlobalConstants.MIN_GRID_CELLS_PER_CHUNK.y *
                      GlobalConstants.MIN_GRID_CELLS_PER_CHUNK.z);

            int capacity = totalCells * 4;

            broadphaseDynamic = new NativeParallelMultiHashMap<BroadphaseCell, Entity>(capacity, Allocator.Persistent);
            broadphaseStatic = new NativeParallelMultiHashMap<BroadphaseCell, Entity>(capacity, Allocator.Persistent);

            dynamicRemovalQueue = new NativeQueue<BroadphaseEntityInCell>(Allocator.Persistent);
            staticRemovalQueue = new NativeQueue<BroadphaseEntityInCell>(Allocator.Persistent);

            threadStats = new NativeArray<PhysicsSolverStatsThreadLocal>(
                JobsUtility.MaxJobThreadCount,
                Allocator.Persistent);

            statsEntity = state.EntityManager.CreateEntity(typeof(PhysicsSolverStats));
        }

        public void OnDestroy(ref SystemState state)
        {
            if (broadphaseDynamic.IsCreated) broadphaseDynamic.Dispose();
            if (broadphaseStatic.IsCreated) broadphaseStatic.Dispose();
            if (dynamicRemovalQueue.IsCreated) dynamicRemovalQueue.Dispose();
            if (staticRemovalQueue.IsCreated) staticRemovalQueue.Dispose();

            if (threadStats.IsCreated) threadStats.Dispose();
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
        // PhysicsSolverSystem Frame Execution Flow
        //
        // Frame N:
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
        // 3. state.Dependency.Complete() sync point
        //    Main thread waits until all scheduled jobs have finished.
        //
        // 4. ECB Playback
        //    Structural changes recorded during jobs are applied:
        //      • PrevBroadphaseCellIndices added for new dynamic entities
        //      • IsBroadphaseRecorded enabled
        //
        //    These changes become visible to ECS queries starting next frame.
        //
        // 5. Apply removal queues (main thread)
        //    All queued BroadphaseEntityInCell entries are processed and
        //    removed from the appropriate broadphase hash maps.
        //
        // 6. Broadphase state is now fully updated and ready for the
        //    next physics stage (e.g., pair generation or narrowphase).
        // ------------------------------------------------------------
        private void onUpdateBroadphaseSetup(ref SystemState state)
        {
            float cellSize = GlobalConstants.MIN_CHUNK_GRID_CELL_SIZE;
            float3 worldHalf = GlobalConstants.CHUNK_SIZE * 0.5f;

            var ecb = new EntityCommandBuffer(Allocator.TempJob);

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
                ThreadStats = threadStats
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
                ECB = ecb.AsParallelWriter(),
                ThreadStats = threadStats
            };

            var h2 = q2.ScheduleParallel(state.Dependency);

            // ------------------------------
            // BROADPHASE SETUP - Init Static just spawned
            // ------------------------------

            var q3 = new SpawnStaticBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                BroadphaseStatic = staticWriter,
                ECB = ecb.AsParallelWriter(),
                ThreadStats = threadStats
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
                ThreadStats = threadStats
            };

            var h4 = q4.ScheduleParallel(state.Dependency);

            // ------------------------------
            // BROADPHASE SETUP - QUERY cleanup static prior to deletion
            // ------------------------------

            var q5 = new CleanupStaticBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                RemovalQueue = staticRemovalWriter,
                ThreadStats = threadStats
            };

            var h5 = q5.ScheduleParallel(state.Dependency);

            var h123 = JobHandle.CombineDependencies(h1, h2, h3);
            var h45 = JobHandle.CombineDependencies(h4, h5);
            state.Dependency = JobHandle.CombineDependencies(h123, h45);

            state.Dependency.Complete();

            ecb.Playback(state.EntityManager);
            ecb.Dispose();

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
        partial struct UpdateDynamicBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeParallelMultiHashMap<BroadphaseCell, Entity>.ParallelWriter BroadphaseDynamic;
            public NativeQueue<BroadphaseEntityInCell>.ParallelWriter RemovalQueue;

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
                stats.totalDynamicVolumeCells += volumeDiff;
                stats.maxCellsPerVolumeDynamic = (uint)math.max(stats.maxCellsPerVolumeDynamic, curCellVolume);

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

                            stats.broadphaseCellRemovalsDynamic++;
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

                            stats.broadphaseCellAddsDynamic++;
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
        partial struct SpawnDynamicBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeParallelMultiHashMap<BroadphaseCell, Entity>.ParallelWriter BroadphaseDynamic;
            public EntityCommandBuffer.ParallelWriter ECB;

            public NativeArray<PhysicsSolverStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;

            void Execute(
                [ChunkIndexInQuery] int chunkIndex,
                Entity entity,
                in WorldRenderBounds bounds,
                EnabledRefRO<IsDynamic> isDynamic,
                EnabledRefRO<IsBroadphaseRecorded> recorded)
            {
                if (!isDynamic.ValueRO || recorded.ValueRO)
                    return;

                var stats = ThreadStats[threadIndex];

                stats.numDynamicVolumes++;

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                int3 curCellVolumeDims = maxCell - minCell;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                stats.totalDynamicVolumeCells += curCellVolume;
                stats.maxCellsPerVolumeDynamic = (uint)math.max(stats.maxCellsPerVolumeDynamic, curCellVolume);

                for (int x = minCell.x; x <= maxCell.x; x++)
                    for (int y = minCell.y; y <= maxCell.y; y++)
                        for (int z = minCell.z; z <= maxCell.z; z++)
                        {
                            BroadphaseDynamic.Add(new BroadphaseCell((uint)x, (uint)y, (uint)z), entity);

                            stats.broadphaseCellAddsDynamic++;
                        }

                BroadphaseCell minCellStruct = new BroadphaseCell((uint)minCell.x, (uint)minCell.y, (uint)minCell.z);
                BroadphaseCell maxCellStruct = new BroadphaseCell((uint)maxCell.x, (uint)maxCell.y, (uint)maxCell.z);

                ECB.AddComponent(chunkIndex, entity, new PrevBroadphaseCellIndices
                {
                    minExtentCellIndex = minCellStruct.Morton,
                    maxExtentCellIndex = maxCellStruct.Morton
                });

                ECB.SetComponentEnabled<IsBroadphaseRecorded>(chunkIndex, entity, true);

                ThreadStats[threadIndex] = stats;
            }
        }

        // -------------------------------------------------
        // BROADPHASE SETUP - Init Static just spawned
        // -------------------------------------------------

        [BurstCompile]
        partial struct SpawnStaticBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeParallelMultiHashMap<BroadphaseCell, Entity>.ParallelWriter BroadphaseStatic;
            public EntityCommandBuffer.ParallelWriter ECB;

            public NativeArray<PhysicsSolverStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;

            void Execute(
                [ChunkIndexInQuery] int chunkIndex,
                Entity entity,
                in WorldRenderBounds bounds,
                EnabledRefRO<IsDynamic> isDynamic,
                EnabledRefRO<IsBroadphaseRecorded> recorded)
            {
                if (isDynamic.ValueRO || recorded.ValueRO)
                    return;

                var stats = ThreadStats[threadIndex];

                stats.numStaticVolumes++;

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                int3 curCellVolumeDims = maxCell - minCell;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                stats.totalStaticVolumeCells += curCellVolume;
                stats.maxCellsPerVolumeStatic = (uint)math.max(stats.maxCellsPerVolumeDynamic, curCellVolume);

                for (int x = minCell.x; x <= maxCell.x; x++)
                    for (int y = minCell.y; y <= maxCell.y; y++)
                        for (int z = minCell.z; z <= maxCell.z; z++)
                        {
                            BroadphaseStatic.Add(new BroadphaseCell((uint)x, (uint)y, (uint)z), entity);

                            stats.broadphaseCellAddsStatic++;
                        }

                ECB.SetComponentEnabled<IsBroadphaseRecorded>(chunkIndex, entity, true);

                ThreadStats[threadIndex] = stats;
            }
        }

        // -------------------------------------------------
        // BROADPHASE SETUP - QUERY cleanup dynamic prior to deletion
        // -------------------------------------------------

        [BurstCompile]
        partial struct CleanupDynamicBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeQueue<BroadphaseEntityInCell>.ParallelWriter RemovalQueue;

            public NativeArray<PhysicsSolverStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;

            void Execute(
                Entity entity,
                in WorldRenderBounds bounds,
                in PrevBroadphaseCellIndices prev,
                EnabledRefRO<NeedsDeletion> deletion,
                EnabledRefRO<IsDynamic> dynamic)
            {
                if (!deletion.ValueRO || !dynamic.ValueRO)
                    return;

                var stats = ThreadStats[threadIndex];

                stats.numDynamicVolumes--;

                uint3 min = BroadphaseCell.DecodeMorton(prev.minExtentCellIndex);
                uint3 max = BroadphaseCell.DecodeMorton(prev.maxExtentCellIndex);

                uint3 curCellVolumeDims = max - min;
                int curCellVolume = (int)(curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z);
                stats.totalDynamicVolumeCells -= curCellVolume;

                for (uint x = min.x; x <= max.x; x++)
                    for (uint y = min.y; y <= max.y; y++)
                        for (uint z = min.z; z <= max.z; z++)
                        {
                            RemovalQueue.Enqueue(new BroadphaseEntityInCell(
                                new BroadphaseCell(x, y, z), entity));

                            stats.broadphaseCellRemovalsDynamic++;
                        }

                ThreadStats[threadIndex] = stats;
            }
        }

        // -------------------------------------------------
        // BROADPHASE SETUP - QUERY cleanup static prior to deletion
        // -------------------------------------------------

        [BurstCompile]
        partial struct CleanupStaticBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeQueue<BroadphaseEntityInCell>.ParallelWriter RemovalQueue;

            public NativeArray<PhysicsSolverStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;

            void Execute(
                Entity entity,
                in WorldRenderBounds bounds,
                EnabledRefRO<NeedsDeletion> deletion,
                EnabledRefRO<IsDynamic> dynamic)
            {
                if (!deletion.ValueRO || dynamic.ValueRO)
                    return;

                var stats = ThreadStats[threadIndex];

                stats.numStaticVolumes--;

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                int3 curCellVolumeDims = maxCell - minCell;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                stats.totalStaticVolumeCells -= curCellVolume;

                for (int x = minCell.x; x <= maxCell.x; x++)
                    for (int y = minCell.y; y <= maxCell.y; y++)
                        for (int z = minCell.z; z <= maxCell.z; z++)
                        {
                            RemovalQueue.Enqueue(new BroadphaseEntityInCell(
                                new BroadphaseCell((uint)x, (uint)y, (uint)z), entity));

                            stats.broadphaseCellRemovalsStatic++;
                        }

                ThreadStats[threadIndex] = stats;
            }
        }

    #endregion

        #region MISC - PHYSICS STATS COLLECTION
        private void clearStats()
        {
            // This is 32-128 items so don't worry about parallelizing
            for (int i = 0; i < threadStats.Length; i++)
                threadStats[i] = default;
        }

        private void aggregateStats(ref SystemState state)
        {
            PhysicsSolverStats existingStats = state.EntityManager.GetComponentData<PhysicsSolverStats>(statsEntity);
            PhysicsSolverStats finalStats = default;

            for (int i = 0; i < threadStats.Length; i++)
            {
                var s = threadStats[i];

                finalStats.broadphaseCellAddsDynamic += s.broadphaseCellAddsDynamic;
                finalStats.broadphaseCellRemovalsDynamic += s.broadphaseCellRemovalsDynamic;

                finalStats.broadphaseCellAddsStatic += s.broadphaseCellAddsStatic;
                finalStats.broadphaseCellRemovalsStatic += s.broadphaseCellRemovalsStatic;

                finalStats.countVolumesDidNotUpdateGrid += s.countVolumesDidNotUpdateGrid;
                finalStats.countVolumesUpdatedGrid += s.countVolumesUpdatedGrid;

                finalStats.totalDynamicVolumeCells += s.totalDynamicVolumeCells;
                finalStats.totalStaticVolumeCells += s.totalStaticVolumeCells;

                finalStats.numDynamicVolumes += s.numDynamicVolumes;
                finalStats.numStaticVolumes += s.numStaticVolumes;

                finalStats.maxCellsPerVolumeDynamic = math.max(finalStats.maxCellsPerVolumeDynamic, s.maxCellsPerVolumeDynamic);
                finalStats.maxCellsPerVolumeStatic = math.max(finalStats.maxCellsPerVolumeStatic, s.maxCellsPerVolumeStatic);
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

            state.EntityManager.SetComponentData(statsEntity, finalStats);
        }
        #endregion
    }
}