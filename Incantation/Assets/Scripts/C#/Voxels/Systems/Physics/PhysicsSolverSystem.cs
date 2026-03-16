using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;
using Incantation.Engine.Voxels.Systems.Physics.Support;
using System;
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
using UnityEngine;
using static UnityEngine.EventSystems.EventTrigger;

namespace Incantation.Engine.Voxels.Systems.Physics
{
    [BurstCompile]
    [UpdateInGroup(typeof(FixedStepSimulationSystemGroup))]
    public partial struct PhysicsSolverSystem : ISystem
    {
        #region STATE AND LIFECYCLE

        NativeParallelMultiHashMap<BroadphaseCell, Entity> broadphaseDynamicCellToEntities;
        NativeParallelMultiHashMap<BroadphaseCell, Entity> broadphaseStaticCellToEntities;

        NativeList<BroadphaseEntityInCell> dynamicRemovalList;
        NativeList<BroadphaseEntityInCell> staticRemovalList;
        NativeList<BroadphaseEntityInCell> dynamicAddedList;
        NativeList<BroadphaseEntityInCell> staticAddedList;

        NativeParallelHashMap<PotentiallyCollidingPair, int> broadphasePairsToCellCount;

        NativeArray<PhysicsSolverStatsThreadLocal> threadStatsUpdatesDynamic;
        NativeArray<PhysicsSolverStatsThreadLocal> threadStatsSpawnDynamic;
        NativeArray<PhysicsSolverStatsThreadLocal> threadStatsSpawnStatic;
        NativeArray<PhysicsSolverStatsThreadLocal> threadStatsDespawnDynamic;
        NativeArray<PhysicsSolverStatsThreadLocal> threadStatsDespawnStatic;
        NativeReference<PhysicsSolverStatsSingleThreaded> singleThreadedStats;

        Entity statsEntity;

        public void OnCreate(ref SystemState state)
        {
            int maxEntitiesPerSceneCapacity = GlobalConstants.MAX_UNIQUE_ORIG_VOX_VOLS_PER_SCENE;
            int maxEntitiesPerScenePairsCapacity = maxEntitiesPerSceneCapacity * 64;    //Assumes 64 neighbors per entity

            // Create data structures
            broadphaseDynamicCellToEntities = new NativeParallelMultiHashMap<BroadphaseCell, Entity>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            broadphaseStaticCellToEntities = new NativeParallelMultiHashMap<BroadphaseCell, Entity>(maxEntitiesPerSceneCapacity, Allocator.Persistent);

            dynamicRemovalList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            staticRemovalList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            dynamicAddedList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            staticAddedList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);

            broadphasePairsToCellCount = new NativeParallelHashMap<PotentiallyCollidingPair, int>(maxEntitiesPerScenePairsCapacity, Allocator.Persistent);

            threadStatsUpdatesDynamic = new NativeArray<PhysicsSolverStatsThreadLocal>(JobsUtility.MaxJobThreadCount,Allocator.Persistent);
            threadStatsSpawnDynamic = new NativeArray<PhysicsSolverStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            threadStatsSpawnStatic = new NativeArray<PhysicsSolverStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            threadStatsDespawnDynamic = new NativeArray<PhysicsSolverStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            threadStatsDespawnStatic = new NativeArray<PhysicsSolverStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            singleThreadedStats = new NativeReference<PhysicsSolverStatsSingleThreaded>(Allocator.Persistent);

            // Create Singletons
            state.EntityManager.CreateSingleton<PhysicsSolverStats>();
        }

        public void OnDestroy(ref SystemState state)
        {
            if (broadphaseDynamicCellToEntities.IsCreated) broadphaseDynamicCellToEntities.Dispose();
            if (broadphaseStaticCellToEntities.IsCreated) broadphaseStaticCellToEntities.Dispose();

            if (dynamicRemovalList.IsCreated) dynamicRemovalList.Dispose();
            if (staticRemovalList.IsCreated) staticRemovalList.Dispose();
            if (dynamicAddedList.IsCreated) dynamicAddedList.Dispose();
            if (staticAddedList.IsCreated) staticAddedList.Dispose();

            if (broadphasePairsToCellCount.IsCreated) broadphasePairsToCellCount.Dispose();

            if (threadStatsUpdatesDynamic.IsCreated) threadStatsUpdatesDynamic.Dispose();
            if (threadStatsSpawnDynamic.IsCreated) threadStatsSpawnDynamic.Dispose();
            if (threadStatsSpawnStatic.IsCreated) threadStatsSpawnStatic.Dispose();
            if (threadStatsDespawnDynamic.IsCreated) threadStatsDespawnDynamic.Dispose();
            if (threadStatsDespawnStatic.IsCreated) threadStatsDespawnStatic.Dispose();
            if (singleThreadedStats.IsCreated) singleThreadedStats.Dispose();
        }

        public void OnUpdate(ref SystemState state)
        {
            clearStats();

            NativeArray<PotentiallyCollidingPair> broadphasePairs = onUpdateBroadphaseSetup(ref state);

            aggregateStats(ref state);

            broadphasePairs.Dispose(state.Dependency);
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
        private NativeArray<PotentiallyCollidingPair> onUpdateBroadphaseSetup(ref SystemState state)
        {
            var mainThreadStats = singleThreadedStats.Value;

            float cellSize = GlobalConstants.BROADPHASE_GRID_CELL_SIZE;
            float3 worldHalf = GlobalConstants.BROADPHASE_GRID_SIZE * 0.5f;

            var ecbDynamic = new EntityCommandBuffer(Allocator.TempJob);
            var ecbStatic = new EntityCommandBuffer(Allocator.TempJob);

            dynamicRemovalList.Clear();
            staticRemovalList.Clear();
            dynamicAddedList.Clear();
            staticAddedList.Clear();

            var dynamicCellToEntitiesWriter = broadphaseDynamicCellToEntities.AsParallelWriter();
            var staticCellToEntitiesWriter = broadphaseStaticCellToEntities.AsParallelWriter();

            var dynamicRemovalWriter = dynamicRemovalList.AsParallelWriter();
            var staticRemovalWriter = staticRemovalList.AsParallelWriter();
            var dynamicAddedWriter = dynamicAddedList.AsParallelWriter();
            var staticAddedWriter = staticAddedList.AsParallelWriter();

            // ------------------------------
            // BROADPHASE SETUP - ROUND 1 - QUERY HOT (Dynamic, already initialized, compares this frame to last for changes)
            // ------------------------------

            var q1 = new UpdateDynamicBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                RemovalList = dynamicRemovalWriter,
                AddedList = dynamicAddedWriter,
                ThreadStats = threadStatsUpdatesDynamic
            };

            var h1 = q1.ScheduleParallel(state.Dependency);

            // ------------------------------
            // BROADPHASE SETUP - ROUND 1 - QUERY Init dynamic just spawned
            // ------------------------------

            var q2 = new SpawnDynamicBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                AddedList = dynamicAddedWriter,
                ECB = ecbDynamic.AsParallelWriter(),
                ThreadStats = threadStatsSpawnDynamic
            };

            var h2 = q2.ScheduleParallel(h1);

            // ------------------------------
            // BROADPHASE SETUP - ROUND 1 - Init Static just spawned
            // ------------------------------

            var q3 = new SpawnStaticBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                AddedList = staticAddedWriter,
                ECB = ecbStatic.AsParallelWriter(),
                ThreadStats = threadStatsSpawnStatic
            };

            var h3 = q3.ScheduleParallel(state.Dependency);

            // ------------------------------
            // BROADPHASE SETUP - ROUND 1 - QUERY cleanup dynamic prior to deletion
            // ------------------------------

            var q4 = new CleanupDynamicBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                RemovalList = dynamicRemovalWriter,
                ThreadStats = threadStatsDespawnDynamic
            };

            var h4 = q4.ScheduleParallel(h2);

            // ------------------------------
            // BROADPHASE SETUP - ROUND 1 - QUERY cleanup static prior to deletion
            // ------------------------------

            var q5 = new CleanupStaticBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                RemovalList = staticRemovalWriter,
                ThreadStats = threadStatsDespawnStatic
            };

            var h5 = q5.ScheduleParallel(state.Dependency);

            var allEntityQueries = JobHandle.CombineDependencies(h3, h4, h5);
            allEntityQueries.Complete();

            ecbDynamic.Playback(state.EntityManager);
            ecbStatic.Playback(state.EntityManager);
            ecbDynamic.Dispose();
            ecbStatic.Dispose();

            // ------------------------------
            // BROADPHASE SETUP - ROUND 2 - Remove entities that are moving from the cell to entities map (leaves only unmoving)
            // ------------------------------

            var removeDynamicJob = new ModifyCellToEntriesMapJob
            {
                ToModifyList = dynamicRemovalList.AsArray().AsReadOnly(),
                Map = broadphaseDynamicCellToEntities,
                Add = false
            };

            var removeStaticJob = new ModifyCellToEntriesMapJob
            {
                ToModifyList = staticRemovalList.AsArray().AsReadOnly(),
                Map = broadphaseStaticCellToEntities,
                Add = false
            };

            var hRemoveDynamic = removeDynamicJob.Schedule(allEntityQueries);
            var hRemoveStatic = removeStaticJob.Schedule(allEntityQueries);

            var allRemovalsHandle = JobHandle.CombineDependencies(hRemoveDynamic, hRemoveStatic);
            allRemovalsHandle.Complete();

            // ------------------------------
            // BROADPHASE SETUP - ROUND 3 - Update pair counts (# of cells this pair exists in) for unmoving entities
            // ------------------------------

            var removeDynamicAgainstUnmovingJ = new UpdateBroadphasePairsAgainstUnmovingJob
            {
                ChangedEntitiesInCells = dynamicRemovalList,
                DynamicMap = broadphaseDynamicCellToEntities,
                StaticMap = broadphaseStaticCellToEntities,
                PairCounts = broadphasePairsToCellCount,
                Increment = -1,
                ChangedEntitiesAreDynamic = true,
                Stats = singleThreadedStats
            };

            var removeDynamicAgainstUnmovingH = removeDynamicAgainstUnmovingJ.Schedule(allRemovalsHandle);


            var removeStaticAgainstUnmovingJ = new UpdateBroadphasePairsAgainstUnmovingJob
            {
                ChangedEntitiesInCells = staticRemovalList,
                DynamicMap = broadphaseDynamicCellToEntities,
                StaticMap = broadphaseStaticCellToEntities,
                PairCounts = broadphasePairsToCellCount,
                Increment = -1,
                ChangedEntitiesAreDynamic = false,
                Stats = singleThreadedStats
            };

            var removeStaticAgainstUnmovingH = removeStaticAgainstUnmovingJ.Schedule(removeDynamicAgainstUnmovingH);


            var addDynamicAgainstUnmovingJ = new UpdateBroadphasePairsAgainstUnmovingJob
            {
                ChangedEntitiesInCells = dynamicAddedList,
                DynamicMap = broadphaseDynamicCellToEntities,
                StaticMap = broadphaseStaticCellToEntities,
                PairCounts = broadphasePairsToCellCount,
                Increment = +1,
                ChangedEntitiesAreDynamic = true,
                Stats = singleThreadedStats
            };

            var addDynamicAgainstUnmovingH = addDynamicAgainstUnmovingJ.Schedule(removeStaticAgainstUnmovingH);

            var addStaticAgainstUnmovingJ = new UpdateBroadphasePairsAgainstUnmovingJob
            {
                ChangedEntitiesInCells = staticAddedList,
                DynamicMap = broadphaseDynamicCellToEntities,
                StaticMap = broadphaseStaticCellToEntities,
                PairCounts = broadphasePairsToCellCount,
                Increment = +1,
                ChangedEntitiesAreDynamic = false,
                Stats = singleThreadedStats
            };

            var addStaticAgainstUnmovingH = addStaticAgainstUnmovingJ.Schedule(addDynamicAgainstUnmovingH);

            var allUnmovingEntitiesPairsCounted = addStaticAgainstUnmovingH;
            allUnmovingEntitiesPairsCounted.Complete();

            // ------------------------------
            // BROADPHASE SETUP - ROUND 4 - Update pair counts (# of cells this pair exists in) for moving entities
            // ------------------------------

            var removeDyVsDyAgainstMovingJ = new UpdateBroadphasePairsAgainstMovingJob
            {
                ListA = dynamicRemovalList,
                ListB = dynamicRemovalList,
                PairCounts = broadphasePairsToCellCount,
                Increment = -1,
                SameList = true,
                Stats = singleThreadedStats
            };

            var removeDyVsDyAgainstMovingH = removeDyVsDyAgainstMovingJ.Schedule(addStaticAgainstUnmovingH);

            var removeDyVsStAgainstMovingJ = new UpdateBroadphasePairsAgainstMovingJob
            {
                ListA = dynamicRemovalList,
                ListB = staticRemovalList,
                PairCounts = broadphasePairsToCellCount,
                Increment = -1,
                SameList = false,
                Stats = singleThreadedStats
            };

            var removeDyVsStAgainstMovingH = removeDyVsStAgainstMovingJ.Schedule(removeDyVsDyAgainstMovingH);

            var addDyVsDyAgainstMovingJ = new UpdateBroadphasePairsAgainstMovingJob
            {
                ListA = dynamicAddedList,
                ListB = dynamicAddedList,
                PairCounts = broadphasePairsToCellCount,
                Increment = +1,
                SameList = true,
                Stats = singleThreadedStats
            };

            var addDyVsDyAgainstMovingH = addDyVsDyAgainstMovingJ.Schedule(removeDyVsStAgainstMovingH);

            var addDyVsStAgainstMovingJ = new UpdateBroadphasePairsAgainstMovingJob
            {
                ListA = dynamicAddedList,
                ListB = staticAddedList,
                PairCounts = broadphasePairsToCellCount,
                Increment = +1,
                SameList = false,
                Stats = singleThreadedStats
            };

            var addDyVsStAgainstMovingH = addDyVsStAgainstMovingJ.Schedule(addDyVsDyAgainstMovingH);

            var cellCountsUpdatesDoneHandle = addDyVsStAgainstMovingH;

            // ------------------------------
            // BROADPHASE SETUP - ROUND 4 - Apply adds to cell to entities map
            // ------------------------------

            var addDynamicJob = new ModifyCellToEntriesMapJob
            {
                ToModifyList = dynamicAddedList.AsArray().AsReadOnly(),
                Map = broadphaseDynamicCellToEntities,
                Add = true
            };

            var addStaticJob = new ModifyCellToEntriesMapJob
            {
                ToModifyList = staticAddedList.AsArray().AsReadOnly(),
                Map = broadphaseStaticCellToEntities,
                Add = true
            };

            var hAddDynamic = addDynamicJob.Schedule(allUnmovingEntitiesPairsCounted);
            var hAddStatic = addStaticJob.Schedule(allUnmovingEntitiesPairsCounted);

            var allAdditionsHandle = JobHandle.CombineDependencies(hAddDynamic, hAddStatic);

            state.Dependency = JobHandle.CombineDependencies(allAdditionsHandle, cellCountsUpdatesDoneHandle);

            state.Dependency.Complete();

            // ------------------------------
            // BROADPHASE SETUP - ROUND 5 - Remaining map keys (>1 cell count) are broadphase pairs
            // ------------------------------

            //var broadphasePairs = broadphasePairsToCellCount.GetKeyArray(Allocator.TempJob);
            var broadphasePairs = broadphasePairsToCellCount.GetKeyValueArrays(Allocator.TempJob);
            mainThreadStats.totalBroadphasePairs = broadphasePairs.Keys.Length;

            drawDebugBroadphasePairResults(ref state, broadphasePairs);

            singleThreadedStats.Value = mainThreadStats;

            return broadphasePairs.Keys;
        }

        // -------------------------------------------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
        // BROADPHASE SETUP - QUERY HOT (Dynamic, already initialized, compares this frame to last for changes)
        // -------------------------------------------------

        [BurstCompile]
        [WithAll(typeof(IsVoxelVolume))]
        [WithAll(typeof(IsDynamic))]
        [WithNone(typeof(NeedsDeletion))]
        [WithAll(typeof(IsBroadphaseRecorded))]
        partial struct UpdateDynamicBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeList<BroadphaseEntityInCell>.ParallelWriter RemovalList;
            public NativeList<BroadphaseEntityInCell>.ParallelWriter AddedList;

            [NativeDisableParallelForRestriction]
            public NativeArray<PhysicsSolverStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;

            void Execute(
                Entity entity,
                ref PrevBroadphaseCellIndices prevIndices,
                in WorldRenderBounds bounds)
            {
                var stats = ThreadStats[threadIndex];

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                BroadphaseCell minCellStruct = new BroadphaseCell(minCell.x, minCell.y, minCell.z);
                BroadphaseCell maxCellStruct = new BroadphaseCell(maxCell.x, maxCell.y, maxCell.z);

                uint newMinMorton = minCellStruct.Morton;
                uint newMaxMorton = maxCellStruct.Morton;

                if (newMinMorton == prevIndices.minExtentCellIndex &&
                    newMaxMorton == prevIndices.maxExtentCellIndex)
                {
                    stats.countVolumesDidNotUpdateGrid++;
                    ThreadStats[threadIndex] = stats;
                    return;
                }

                stats.countVolumesUpdatedGrid++;

                int3 prevMin = BroadphaseCell.DecodeMorton(prevIndices.minExtentCellIndex);
                int3 prevMax = BroadphaseCell.DecodeMorton(prevIndices.maxExtentCellIndex);

                int3 prevCellVolumeDims = prevMax - prevMin + 1;
                int3 curCellVolumeDims = maxCell - minCell + 1;
                int prevCellVolume = prevCellVolumeDims.x * prevCellVolumeDims.y * prevCellVolumeDims.z;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                int volumeDiff = curCellVolume - prevCellVolume;
                stats.totalVolumeCells += volumeDiff;
                stats.maxCellsPerVolume = math.max(stats.maxCellsPerVolume, curCellVolume);

                int3 intersectMin = math.max(prevMin, minCell);
                int3 intersectMax = math.min(prevMax, maxCell);

                for (int x = prevMin.x; x <= prevMax.x; x++)
                    for (int y = prevMin.y; y <= prevMax.y; y++)
                        for (int z = prevMin.z; z <= prevMax.z; z++)
                        {
                            if (x >= intersectMin.x && x <= intersectMax.x &&
                                y >= intersectMin.y && y <= intersectMax.y &&
                                z >= intersectMin.z && z <= intersectMax.z)
                                continue;

                            if ((x < 0) || (x >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.x) ||
                                    (y < 0) || (y >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.y) ||
                                    (z < 0) || (z >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.z))
                                continue;

                            RemovalList.AddNoResize(new BroadphaseEntityInCell(
                                new BroadphaseCell(x, y, z), entity));

                            stats.broadphaseCellRemovals++;
                        }

                for (int x = minCell.x; x <= maxCell.x; x++)
                    for (int y = minCell.y; y <= maxCell.y; y++)
                        for (int z = minCell.z; z <= maxCell.z; z++)
                        {
                            if (x >= intersectMin.x && x <= intersectMax.x &&
                                y >= intersectMin.y && y <= intersectMax.y &&
                                z >= intersectMin.z && z <= intersectMax.z)
                                continue;

                            if ((x < 0) || (x >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.x) ||
                                    (y < 0) || (y >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.y) ||
                                    (z < 0) || (z >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.z))
                                continue;

                            AddedList.AddNoResize(new BroadphaseEntityInCell(
                                new BroadphaseCell(x, y, z), entity));

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
        [WithAll(typeof(IsVoxelVolume))]
        [WithAll(typeof(IsDynamic))]
        [WithNone(typeof(NeedsDeletion))]
        [WithNone(typeof(IsBroadphaseRecorded))]
        partial struct SpawnDynamicBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeList<BroadphaseEntityInCell>.ParallelWriter AddedList;
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

                int3 curCellVolumeDims = maxCell - minCell + 1;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                stats.totalVolumeCells += curCellVolume;
                stats.maxCellsPerVolume = math.max(stats.maxCellsPerVolume, curCellVolume);

                for (int x = minCell.x; x <= maxCell.x; x++)
                    for (int y = minCell.y; y <= maxCell.y; y++)
                        for (int z = minCell.z; z <= maxCell.z; z++)
                        {
                            if ((x < 0) || (x >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.x) ||
                                    (y < 0) || (y >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.y) ||
                                    (z < 0) || (z >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.z))
                                continue;

                            AddedList.AddNoResize(new BroadphaseEntityInCell(
                                new BroadphaseCell(x, y, z), entity));

                            stats.broadphaseCellAdds++;
                        }

                BroadphaseCell minCellStruct = new BroadphaseCell(minCell.x, minCell.y, minCell.z);
                BroadphaseCell maxCellStruct = new BroadphaseCell(maxCell.x, maxCell.y, maxCell.z);

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
        [WithAll(typeof(IsVoxelVolume))]
        [WithNone(typeof(IsDynamic))]
        [WithNone(typeof(NeedsDeletion))]
        [WithNone(typeof(IsBroadphaseRecorded))]
        partial struct SpawnStaticBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeList<BroadphaseEntityInCell>.ParallelWriter AddedList;
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

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                int3 curCellVolumeDims = maxCell - minCell + 1;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                stats.totalVolumeCells += curCellVolume;
                stats.maxCellsPerVolume = math.max(stats.maxCellsPerVolume, curCellVolume);

                for (int x = minCell.x; x <= maxCell.x; x++)
                    for (int y = minCell.y; y <= maxCell.y; y++)
                        for (int z = minCell.z; z <= maxCell.z; z++)
                        {
                            if ((x < 0) || (x >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.x) ||
                                    (y < 0) || (y >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.y) ||
                                    (z < 0) || (z >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.z))
                                continue;

                            AddedList.AddNoResize(new BroadphaseEntityInCell(
                                new BroadphaseCell(x, y, z), entity));

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
        [WithAll(typeof(IsVoxelVolume))]
        [WithAll(typeof(IsDynamic))]
        [WithAll(typeof(NeedsDeletion))]
        partial struct CleanupDynamicBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeList<BroadphaseEntityInCell>.ParallelWriter RemovalList;

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

                int3 min = BroadphaseCell.DecodeMorton(prev.minExtentCellIndex);
                int3 max = BroadphaseCell.DecodeMorton(prev.maxExtentCellIndex);

                int3 curCellVolumeDims = max - min + 1;
                int curCellVolume = (int)(curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z);
                stats.totalVolumeCells -= curCellVolume;

                for (int x = min.x; x <= max.x; x++)
                    for (int y = min.y; y <= max.y; y++)
                        for (int z = min.z; z <= max.z; z++)
                        {
                            if ((x < 0) || (x >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.x) ||
                                    (y < 0) || (y >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.y) ||
                                    (z < 0) || (z >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.z))
                                continue;

                            RemovalList.AddNoResize(new BroadphaseEntityInCell(
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
        [WithAll(typeof(IsVoxelVolume))]
        [WithNone(typeof(IsDynamic))]
        [WithAll(typeof(NeedsDeletion))]
        partial struct CleanupStaticBroadphaseJob : IJobEntity
        {
            public float CellSize;
            public float3 WorldHalf;

            public NativeList<BroadphaseEntityInCell>.ParallelWriter RemovalList;

            [NativeDisableParallelForRestriction]
            public NativeArray<PhysicsSolverStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;

            void Execute(
                Entity entity,
                in WorldRenderBounds bounds)
            {
                var stats = ThreadStats[threadIndex];

                stats.numVolumes--;

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                int3 curCellVolumeDims = maxCell - minCell + 1;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                stats.totalVolumeCells -= curCellVolume;

                for (int x = minCell.x; x <= maxCell.x; x++)
                    for (int y = minCell.y; y <= maxCell.y; y++)
                        for (int z = minCell.z; z <= maxCell.z; z++)
                        {
                            if ((x < 0) || (x >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.x) ||
                                    (y < 0) || (y >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.y) ||
                                    (z < 0) || (z >= GlobalConstants.BROADPHASE_GRID_CELLS_PER_CHUNK.z))
                                continue;

                            RemovalList.AddNoResize(new BroadphaseEntityInCell(
                                new BroadphaseCell(x, y, z), entity));

                            stats.broadphaseCellRemovals++;
                        }

                ThreadStats[threadIndex] = stats;
            }
        }

        [BurstCompile]
        public struct ModifyCellToEntriesMapJob : IJob
        {
            [ReadOnly] public NativeArray<BroadphaseEntityInCell>.ReadOnly ToModifyList;
            public NativeParallelMultiHashMap<BroadphaseCell, Entity> Map;

            public bool Add;

            public void Execute()
            {
                for (int i = 0; i < ToModifyList.Length; i++)
                {
                    var item = ToModifyList[i];
                    if (Add)
                    {
                        Map.Add(item.Cell, item.Entity);
                    }
                    else
                    {
                        Map.Remove(item.Cell, item.Entity);
                    }
                }
            }
        }

        [BurstCompile]
        public struct UpdateBroadphasePairsAgainstUnmovingJob : IJob
        {
            [ReadOnly] public NativeList<BroadphaseEntityInCell> ChangedEntitiesInCells;

            [ReadOnly] public NativeParallelMultiHashMap<BroadphaseCell, Entity> DynamicMap;
            [ReadOnly] public NativeParallelMultiHashMap<BroadphaseCell, Entity> StaticMap;

            public NativeParallelHashMap<PotentiallyCollidingPair, int> PairCounts;

            public int Increment;
            public bool ChangedEntitiesAreDynamic;

            public NativeReference<PhysicsSolverStatsSingleThreaded> Stats;

            public void Execute()
            {
                var stats = Stats.Value;

                for (int i = 0; i < ChangedEntitiesInCells.Length; i++)
                {
                    var entry = ChangedEntitiesInCells[i];
                    var entity = entry.Entity;
                    var cell = entry.Cell;

                    // -------------------------
                    // Dynamic map lookup
                    // -------------------------

                    if (DynamicMap.TryGetFirstValue(cell, out var other, out var it))
                    {
                        do
                        {
                            if (other == entity)
                                continue;

                            var pair = new PotentiallyCollidingPair(entity, other);

                            UpdatePair(pair, ref stats);

                        } while (DynamicMap.TryGetNextValue(out other, ref it));
                    }

                    // -------------------------
                    // Static map lookup
                    // -------------------------

                    // Skip static/static pairs
                    if (!ChangedEntitiesAreDynamic)
                        continue;

                    if (StaticMap.TryGetFirstValue(cell, out var otherStatic, out var it2))
                    {
                        do
                        {
                            if (otherStatic == entity)
                                continue;

                            var pair = new PotentiallyCollidingPair(entity, otherStatic);

                            UpdatePair(pair, ref stats);

                        } while (StaticMap.TryGetNextValue(out otherStatic, ref it2));
                    }
                }

                Stats.Value = stats;
            }

            private void UpdatePair(PotentiallyCollidingPair pair, ref PhysicsSolverStatsSingleThreaded stats)
            {
                if (PairCounts.TryGetValue(pair, out int count))
                {
                    count += Increment;

                    if (count == 0)
                    {
                        PairCounts.Remove(pair);
                        stats.existingPairsRemoved++;
                    }
                    else
                    {
                        PairCounts[pair] = count;
                        stats.existingPairsUpdated++;
                    }
                }
                else
                {
                    PairCounts.Add(pair, Increment);
                    stats.newPairsGenerated++;
                }
            }
        }

        // This kinda sucks because its O(n^2) or O(n * m) but these lists should be small because they're the
        // cell movement deltas between frames...Hopefully.
        [BurstCompile]
        public struct UpdateBroadphasePairsAgainstMovingJob : IJob
        {
            [ReadOnly] public NativeList<BroadphaseEntityInCell> ListA;
            [ReadOnly] public NativeList<BroadphaseEntityInCell> ListB;

            public NativeParallelHashMap<PotentiallyCollidingPair, int> PairCounts;

            public int Increment;

            // If true, ListA and ListB are the same list
            // so we avoid duplicate pairs using Entity.Index ordering
            public bool SameList;

            public NativeReference<PhysicsSolverStatsSingleThreaded> Stats;

            public void Execute()
            {
                var stats = Stats.Value;

                for (int i = 0; i < ListA.Length; i++)
                {
                    var a = ListA[i];

                    for (int j = 0; j < ListB.Length; j++)
                    {
                        var b = ListB[j];

                        // Skip self
                        if (a.Entity == b.Entity)
                            continue;

                        // Only process if in same cell
                        if (!a.Cell.Equals(b.Cell))
                            continue;

                        // Avoid duplicates when using same list
                        if (SameList && a.Entity.Index >= b.Entity.Index)
                            continue;

                        var pair = new PotentiallyCollidingPair(a.Entity, b.Entity);

                        UpdatePair(pair, ref stats);
                    }
                }

                Stats.Value = stats;
            }

            private void UpdatePair(PotentiallyCollidingPair pair, ref PhysicsSolverStatsSingleThreaded stats)
            {
                if (PairCounts.TryGetValue(pair, out int count))
                {
                    count += Increment;

                    if (count == 0)
                    {
                        PairCounts.Remove(pair);
                        stats.existingPairsRemoved++;
                    }
                    else
                    {
                        PairCounts[pair] = count;
                        stats.existingPairsUpdated++;
                    }
                }
                else
                {
                    PairCounts.Add(pair, Increment);
                    stats.newPairsGenerated++;
                }
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

            singleThreadedStats.Value = default;
        }

        private void aggregateStats(ref SystemState state)
        {
            var existingStatsRW = SystemAPI.GetSingletonRW<PhysicsSolverStats>();
            ref var existingStats = ref existingStatsRW.ValueRW;
            PhysicsSolverStats finalStats = default;

            // Aggregate per-thread stat values
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
                finalStats.totalStaticVolumeCells += s.totalVolumeCells;
                finalStats.numStaticVolumes += s.numVolumes;
                finalStats.maxCellsPerVolumeStatic = math.max(finalStats.maxCellsPerVolumeStatic, s.maxCellsPerVolume);
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
                finalStats.totalStaticVolumeCells += s.totalVolumeCells;
                finalStats.numStaticVolumes += s.numVolumes;
            }

            // Assign single-threaded stats
            finalStats.totalBroadphasePairs = singleThreadedStats.Value.totalBroadphasePairs;
            finalStats.newPairsGenerated = singleThreadedStats.Value.newPairsGenerated;
            finalStats.existingPairsRemoved = singleThreadedStats.Value.existingPairsRemoved;
            finalStats.existingPairsUpdated = singleThreadedStats.Value.existingPairsUpdated;

            // Relative to last frame's stats
            finalStats.totalDynamicVolumeCells += existingStats.totalDynamicVolumeCells;
            finalStats.totalStaticVolumeCells += existingStats.totalStaticVolumeCells;
            finalStats.numDynamicVolumes += existingStats.numDynamicVolumes;
            finalStats.numStaticVolumes += existingStats.numStaticVolumes;
            finalStats.maxCellsPerVolumeDynamic = math.max(finalStats.maxCellsPerVolumeDynamic, existingStats.maxCellsPerVolumeDynamic);
            finalStats.maxCellsPerVolumeStatic = math.max(finalStats.maxCellsPerVolumeStatic, existingStats.maxCellsPerVolumeStatic);

            // Derived stats
            finalStats.totalPairIterations = finalStats.newPairsGenerated + finalStats.existingPairsRemoved 
                + finalStats.existingPairsUpdated;
            finalStats.AvgCellsPerVolumeDynamic = finalStats.numDynamicVolumes > 0 ? 
                finalStats.totalDynamicVolumeCells / ((float)finalStats.numDynamicVolumes) : 0.0f;
            finalStats.AvgCellsPerVolumeStatic = finalStats.numStaticVolumes > 0 ?
                finalStats.totalStaticVolumeCells / ((float)finalStats.numStaticVolumes) : 0.0f;
            finalStats.updateRateDynamicPercent = finalStats.numDynamicVolumes > 0 ?
                100.0f * finalStats.countVolumesUpdatedGrid / ((float)finalStats.numDynamicVolumes) : 0.0f;

            //Assign to values to singleton
            existingStats = finalStats;
        }

        private void drawDebugBroadphasePairResults(ref SystemState state, NativeKeyValueArrays<PotentiallyCollidingPair, int> broadphasePairs)
        {
            for (int i = 0; i < broadphasePairs.Keys.Length; i++)
            {
                var cellCount = broadphasePairs.Values[i];
                var pair = broadphasePairs.Keys[i];

                var transformA = state.EntityManager.GetComponentData<LocalTransform>(pair.A);
                var transformB = state.EntityManager.GetComponentData<LocalTransform>(pair.B);

                float3 posA = transformA.Position;
                float3 posB = transformB.Position;

                var magnitude = math.abs(cellCount / 8.0f);
                magnitude = math.min(magnitude, 1.0f);
                var redMult = cellCount < 0 ? 1 : 0;
                var greenMult = cellCount > 0 ? 1 : 0;
                Color color = new Color(redMult * magnitude, greenMult * magnitude, 0.0f, 0.25f);

                Debug.DrawLine(posA, posB, color, Time.fixedDeltaTime);
            }
        }
        #endregion
    }
}