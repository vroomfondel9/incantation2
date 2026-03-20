using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;
using Incantation.Engine.Voxels.Systems.Physics.Support;
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

namespace Incantation.Engine.Voxels.Systems.Physics
{
    [BurstCompile]
    [UpdateInGroup(typeof(FixedStepSimulationSystemGroup))]
    public partial struct PhysicsSolverSystem : ISystem
    {
        #region STATE AND LIFECYCLE

        #region Collections - Broadphase
        NativeParallelMultiHashMap<BroadphaseCell, Entity> broadphaseDynamicCellToEntities;
        NativeParallelMultiHashMap<BroadphaseCell, Entity> broadphaseStaticCellToEntities;

        NativeList<BroadphaseEntityInCell> broadphaseDynamicRemovalList;
        NativeList<BroadphaseEntityInCell> broadphaseStaticRemovalList;
        NativeList<BroadphaseEntityInCell> broadphaseDynamicAddedList;
        NativeList<BroadphaseEntityInCell> broadphaseStaticAddedList;

        NativeParallelHashMap<PotentiallyCollidingPair, int> broadphasePairsToCellCount;

        NativeArray<BroadphaseStatsThreadLocal> broadphaseThreadStatsUpdatesDynamic;
        NativeArray<BroadphaseStatsThreadLocal> broadphaseThreadStatsSpawnDynamic;
        NativeArray<BroadphaseStatsThreadLocal> broadphaseThreadStatsSpawnStatic;
        NativeArray<BroadphaseStatsThreadLocal> broadphaseThreadStatsDespawnDynamic;
        NativeArray<BroadphaseStatsThreadLocal> broadphaseThreadStatsDespawnStatic;
        NativeReference<BroadphaseStatsSingleThreaded> broadphaseSingleThreadedStats;
        #endregion

        public void OnCreate(ref SystemState state)
        {
            int maxEntitiesPerSceneCapacity = GlobalConstants.MAX_UNIQUE_ORIG_VOX_VOLS_PER_SCENE;
            int maxEntitiesPerScenePairsCapacity = maxEntitiesPerSceneCapacity * 64;    //Assumes 64 neighbors per entity

            // Create data structures
            #region Init Collections - Broadphase
            broadphaseDynamicCellToEntities = new NativeParallelMultiHashMap<BroadphaseCell, Entity>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            broadphaseStaticCellToEntities = new NativeParallelMultiHashMap<BroadphaseCell, Entity>(maxEntitiesPerSceneCapacity, Allocator.Persistent);

            broadphaseDynamicRemovalList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            broadphaseStaticRemovalList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            broadphaseDynamicAddedList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            broadphaseStaticAddedList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);

            broadphasePairsToCellCount = new NativeParallelHashMap<PotentiallyCollidingPair, int>(maxEntitiesPerScenePairsCapacity, Allocator.Persistent);

            broadphaseThreadStatsUpdatesDynamic = new NativeArray<BroadphaseStatsThreadLocal>(JobsUtility.MaxJobThreadCount,Allocator.Persistent);
            broadphaseThreadStatsSpawnDynamic = new NativeArray<BroadphaseStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            broadphaseThreadStatsSpawnStatic = new NativeArray<BroadphaseStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            broadphaseThreadStatsDespawnDynamic = new NativeArray<BroadphaseStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            broadphaseThreadStatsDespawnStatic = new NativeArray<BroadphaseStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            broadphaseSingleThreadedStats = new NativeReference<BroadphaseStatsSingleThreaded>(Allocator.Persistent);
            #endregion

            // Create Singletons
            #region Init Singletons - Broadphase
            state.EntityManager.CreateSingleton<BroadphaseStats>();
            #endregion
        }

        public void OnDestroy(ref SystemState state)
        {
            #region Collection Disposal - Broadphase
            if (broadphaseDynamicCellToEntities.IsCreated) broadphaseDynamicCellToEntities.Dispose();
            if (broadphaseStaticCellToEntities.IsCreated) broadphaseStaticCellToEntities.Dispose();

            if (broadphaseDynamicRemovalList.IsCreated) broadphaseDynamicRemovalList.Dispose();
            if (broadphaseStaticRemovalList.IsCreated) broadphaseStaticRemovalList.Dispose();
            if (broadphaseDynamicAddedList.IsCreated) broadphaseDynamicAddedList.Dispose();
            if (broadphaseStaticAddedList.IsCreated) broadphaseStaticAddedList.Dispose();

            if (broadphasePairsToCellCount.IsCreated) broadphasePairsToCellCount.Dispose();

            if (broadphaseThreadStatsUpdatesDynamic.IsCreated) broadphaseThreadStatsUpdatesDynamic.Dispose();
            if (broadphaseThreadStatsSpawnDynamic.IsCreated) broadphaseThreadStatsSpawnDynamic.Dispose();
            if (broadphaseThreadStatsSpawnStatic.IsCreated) broadphaseThreadStatsSpawnStatic.Dispose();
            if (broadphaseThreadStatsDespawnDynamic.IsCreated) broadphaseThreadStatsDespawnDynamic.Dispose();
            if (broadphaseThreadStatsDespawnStatic.IsCreated) broadphaseThreadStatsDespawnStatic.Dispose();
            if (broadphaseSingleThreadedStats.IsCreated) broadphaseSingleThreadedStats.Dispose();
            #endregion
        }

        public void OnUpdate(ref SystemState state)
        {
            NativeArray<PotentiallyCollidingPair> broadphasePairs = findCollisionBroadphasePairs(ref state);

            state.Dependency = broadphasePairs.Dispose(state.Dependency);
        }

        #endregion

        #region COLLISION DETECTION - BROADPHASE

        // -------------------------------------------------
        // BROADPHASE
        // -------------------------------------------------
        public NativeArray<PotentiallyCollidingPair> findCollisionBroadphasePairs(ref SystemState state)
        {
            #region Init
            clearStats();

            float cellSize = GlobalConstants.BROADPHASE_GRID_CELL_SIZE;
            float3 worldHalf = GlobalConstants.BROADPHASE_GRID_SIZE * 0.5f;

            var ecbDynamic = new EntityCommandBuffer(Allocator.TempJob);
            var ecbStatic = new EntityCommandBuffer(Allocator.TempJob);

            broadphaseDynamicRemovalList.Clear();
            broadphaseStaticRemovalList.Clear();
            broadphaseDynamicAddedList.Clear();
            broadphaseStaticAddedList.Clear();

            var dynamicCellToEntitiesWriter = broadphaseDynamicCellToEntities.AsParallelWriter();
            var staticCellToEntitiesWriter = broadphaseStaticCellToEntities.AsParallelWriter();

            var dynamicRemovalWriter = broadphaseDynamicRemovalList.AsParallelWriter();
            var staticRemovalWriter = broadphaseStaticRemovalList.AsParallelWriter();
            var dynamicAddedWriter = broadphaseDynamicAddedList.AsParallelWriter();
            var staticAddedWriter = broadphaseStaticAddedList.AsParallelWriter();
            #endregion

            #region ROUND 1 - Queries to collect entity grid cell changes since last frame
            // ------------------------------
            // BROADPHASE SETUP - ROUND 1 - QUERY HOT (Dynamic, already initialized, compares this frame to last for changes)
            // ------------------------------

            var q1 = new UpdateDynamicBroadphaseJob
            {
                CellSize = cellSize,
                WorldHalf = worldHalf,
                RemovalList = dynamicRemovalWriter,
                AddedList = dynamicAddedWriter,
                ThreadStats = broadphaseThreadStatsUpdatesDynamic
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
                ThreadStats = broadphaseThreadStatsSpawnDynamic
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
                ThreadStats = broadphaseThreadStatsSpawnStatic
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
                ThreadStats = broadphaseThreadStatsDespawnDynamic
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
                ThreadStats = broadphaseThreadStatsDespawnStatic
            };

            var h5 = q5.ScheduleParallel(state.Dependency);

            var allEntityQueries = JobHandle.CombineDependencies(h3, h4, h5);
            allEntityQueries.Complete();

            ecbDynamic.Playback(state.EntityManager);
            ecbStatic.Playback(state.EntityManager);
            ecbDynamic.Dispose();
            ecbStatic.Dispose();

            #endregion

            #region ROUND 2 - Remove moved entities from cell -> entity map
            // ------------------------------
            // BROADPHASE SETUP - ROUND 2 - Remove entities that are moving from the cell to entities map (leaves only unmoving)
            // ------------------------------

            var removeDynamicJob = new ModifyCellToEntriesMapJob
            {
                ToModifyList = broadphaseDynamicRemovalList.AsArray().AsReadOnly(),
                Map = broadphaseDynamicCellToEntities,
                Add = false
            };

            var removeStaticJob = new ModifyCellToEntriesMapJob
            {
                ToModifyList = broadphaseStaticRemovalList.AsArray().AsReadOnly(),
                Map = broadphaseStaticCellToEntities,
                Add = false
            };

            var hRemoveDynamic = removeDynamicJob.Schedule(allEntityQueries);
            var hRemoveStatic = removeStaticJob.Schedule(allEntityQueries);

            var allRemovalsHandle = JobHandle.CombineDependencies(hRemoveDynamic, hRemoveStatic);
            allRemovalsHandle.Complete();
            #endregion

            #region ROUND 3 - Update pair counts for moved entities vs unmoved entities
            // ------------------------------
            // BROADPHASE SETUP - ROUND 3 - Update pair counts (# of cells this pair exists in) for unmoving entities
            // ------------------------------

            var removeDynamicAgainstUnmovingJ = new UpdateBroadphasePairsAgainstUnmovingJob
            {
                ChangedEntitiesInCells = broadphaseDynamicRemovalList,
                DynamicMap = broadphaseDynamicCellToEntities,
                StaticMap = broadphaseStaticCellToEntities,
                PairCounts = broadphasePairsToCellCount,
                Increment = -1,
                ChangedEntitiesAreDynamic = true,
                Stats = broadphaseSingleThreadedStats
            };

            var removeDynamicAgainstUnmovingH = removeDynamicAgainstUnmovingJ.Schedule(allRemovalsHandle);


            var removeStaticAgainstUnmovingJ = new UpdateBroadphasePairsAgainstUnmovingJob
            {
                ChangedEntitiesInCells = broadphaseStaticRemovalList,
                DynamicMap = broadphaseDynamicCellToEntities,
                StaticMap = broadphaseStaticCellToEntities,
                PairCounts = broadphasePairsToCellCount,
                Increment = -1,
                ChangedEntitiesAreDynamic = false,
                Stats = broadphaseSingleThreadedStats
            };

            var removeStaticAgainstUnmovingH = removeStaticAgainstUnmovingJ.Schedule(removeDynamicAgainstUnmovingH);


            var addDynamicAgainstUnmovingJ = new UpdateBroadphasePairsAgainstUnmovingJob
            {
                ChangedEntitiesInCells = broadphaseDynamicAddedList,
                DynamicMap = broadphaseDynamicCellToEntities,
                StaticMap = broadphaseStaticCellToEntities,
                PairCounts = broadphasePairsToCellCount,
                Increment = +1,
                ChangedEntitiesAreDynamic = true,
                Stats = broadphaseSingleThreadedStats
            };

            var addDynamicAgainstUnmovingH = addDynamicAgainstUnmovingJ.Schedule(removeStaticAgainstUnmovingH);

            var addStaticAgainstUnmovingJ = new UpdateBroadphasePairsAgainstUnmovingJob
            {
                ChangedEntitiesInCells = broadphaseStaticAddedList,
                DynamicMap = broadphaseDynamicCellToEntities,
                StaticMap = broadphaseStaticCellToEntities,
                PairCounts = broadphasePairsToCellCount,
                Increment = +1,
                ChangedEntitiesAreDynamic = false,
                Stats = broadphaseSingleThreadedStats
            };

            var addStaticAgainstUnmovingH = addStaticAgainstUnmovingJ.Schedule(addDynamicAgainstUnmovingH);

            var allUnmovingEntitiesPairsCounted = addStaticAgainstUnmovingH;
            allUnmovingEntitiesPairsCounted.Complete();
            #endregion

            #region ROUND 4 - Update counts for moved entities vs each other + add moved entities to cell -> entity map
            // ------------------------------
            // BROADPHASE SETUP - ROUND 4 - Update pair counts (# of cells this pair exists in) for moving entities
            // ------------------------------

            var removeDyVsDyAgainstMovingJ = new UpdateBroadphasePairsAgainstMovingJob
            {
                ListA = broadphaseDynamicRemovalList,
                ListB = broadphaseDynamicRemovalList,
                PairCounts = broadphasePairsToCellCount,
                Increment = -1,
                SameList = true,
                Stats = broadphaseSingleThreadedStats
            };

            var removeDyVsDyAgainstMovingH = removeDyVsDyAgainstMovingJ.Schedule(addStaticAgainstUnmovingH);

            var removeDyVsStAgainstMovingJ = new UpdateBroadphasePairsAgainstMovingJob
            {
                ListA = broadphaseDynamicRemovalList,
                ListB = broadphaseStaticRemovalList,
                PairCounts = broadphasePairsToCellCount,
                Increment = -1,
                SameList = false,
                Stats = broadphaseSingleThreadedStats
            };

            var removeDyVsStAgainstMovingH = removeDyVsStAgainstMovingJ.Schedule(removeDyVsDyAgainstMovingH);

            var addDyVsDyAgainstMovingJ = new UpdateBroadphasePairsAgainstMovingJob
            {
                ListA = broadphaseDynamicAddedList,
                ListB = broadphaseDynamicAddedList,
                PairCounts = broadphasePairsToCellCount,
                Increment = +1,
                SameList = true,
                Stats = broadphaseSingleThreadedStats
            };

            var addDyVsDyAgainstMovingH = addDyVsDyAgainstMovingJ.Schedule(removeDyVsStAgainstMovingH);

            var addDyVsStAgainstMovingJ = new UpdateBroadphasePairsAgainstMovingJob
            {
                ListA = broadphaseDynamicAddedList,
                ListB = broadphaseStaticAddedList,
                PairCounts = broadphasePairsToCellCount,
                Increment = +1,
                SameList = false,
                Stats = broadphaseSingleThreadedStats
            };

            var addDyVsStAgainstMovingH = addDyVsStAgainstMovingJ.Schedule(addDyVsDyAgainstMovingH);

            var cellCountsUpdatesDoneHandle = addDyVsStAgainstMovingH;

            // ------------------------------
            // BROADPHASE SETUP - ROUND 4 - Apply adds to cell to entities map
            // ------------------------------

            var addDynamicJob = new ModifyCellToEntriesMapJob
            {
                ToModifyList = broadphaseDynamicAddedList.AsArray().AsReadOnly(),
                Map = broadphaseDynamicCellToEntities,
                Add = true
            };

            var addStaticJob = new ModifyCellToEntriesMapJob
            {
                ToModifyList = broadphaseStaticAddedList.AsArray().AsReadOnly(),
                Map = broadphaseStaticCellToEntities,
                Add = true
            };

            var hAddDynamic = addDynamicJob.Schedule(allUnmovingEntitiesPairsCounted);
            var hAddStatic = addStaticJob.Schedule(allUnmovingEntitiesPairsCounted);

            var allAdditionsHandle = JobHandle.CombineDependencies(hAddDynamic, hAddStatic);

            state.Dependency = JobHandle.CombineDependencies(allAdditionsHandle, cellCountsUpdatesDoneHandle);

            state.Dependency.Complete();
            #endregion

            #region ROUND 5 - Get broadphase pairs from remaining map keys
            // ------------------------------
            // BROADPHASE SETUP - ROUND 5 - Remaining map keys (>1 cell count) are broadphase pairs
            // ------------------------------
            var broadphasePairs = broadphasePairsToCellCount.GetKeyValueArrays(Allocator.TempJob);

            var mainThreadStats = broadphaseSingleThreadedStats.Value;
            mainThreadStats.totalBroadphasePairs = broadphasePairs.Keys.Length;
            broadphaseSingleThreadedStats.Value = mainThreadStats;

            drawDebugBroadphasePairResults(ref state, broadphasePairs);
            state.Dependency = broadphasePairs.Values.Dispose(state.Dependency);

            aggregateStats(ref state);

            return broadphasePairs.Keys;
            #endregion
        }

        #region Job Structs
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
            public NativeArray<BroadphaseStatsThreadLocal> ThreadStats;

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
            public NativeArray<BroadphaseStatsThreadLocal> ThreadStats;

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
            public NativeArray<BroadphaseStatsThreadLocal> ThreadStats;

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
            public NativeArray<BroadphaseStatsThreadLocal> ThreadStats;

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
            public NativeArray<BroadphaseStatsThreadLocal> ThreadStats;

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

            public NativeReference<BroadphaseStatsSingleThreaded> Stats;

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

            private void UpdatePair(PotentiallyCollidingPair pair, ref BroadphaseStatsSingleThreaded stats)
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

            public NativeReference<BroadphaseStatsSingleThreaded> Stats;

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

            private void UpdatePair(PotentiallyCollidingPair pair, ref BroadphaseStatsSingleThreaded stats)
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

        #region PHYSICS STATS COLLECTION
        // This is 32-128 items so don't worry about parallelizing
        private void clearStats()
        {
            for (int i = 0; i < broadphaseThreadStatsUpdatesDynamic.Length; i++)
                broadphaseThreadStatsUpdatesDynamic[i] = default;

            for (int i = 0; i < broadphaseThreadStatsSpawnDynamic.Length; i++)
                broadphaseThreadStatsSpawnDynamic[i] = default;

            for (int i = 0; i < broadphaseThreadStatsSpawnStatic.Length; i++)
                broadphaseThreadStatsSpawnStatic[i] = default;

            for (int i = 0; i < broadphaseThreadStatsDespawnDynamic.Length; i++)
                broadphaseThreadStatsDespawnDynamic[i] = default;

            for (int i = 0; i < broadphaseThreadStatsDespawnStatic.Length; i++)
                broadphaseThreadStatsDespawnStatic[i] = default;

            broadphaseSingleThreadedStats.Value = default;
        }

        private void aggregateStats(ref SystemState state)
        {
            var existingStatsRW = SystemAPI.GetSingletonRW<BroadphaseStats>();
            ref var existingStats = ref existingStatsRW.ValueRW;

            BroadphaseStats finalStats = default;

            // Aggregate per-thread stat values
            for (int i = 0; i < broadphaseThreadStatsUpdatesDynamic.Length; i++)
            {
                var s = broadphaseThreadStatsUpdatesDynamic[i];

                finalStats.broadphaseCellAddsDynamic += s.broadphaseCellAdds;
                finalStats.broadphaseCellRemovalsDynamic += s.broadphaseCellRemovals;
                finalStats.countVolumesDidNotUpdateGrid += s.countVolumesDidNotUpdateGrid;
                finalStats.countVolumesUpdatedGrid += s.countVolumesUpdatedGrid;
                finalStats.totalDynamicVolumeCells += s.totalVolumeCells;
                finalStats.numDynamicVolumes += s.numVolumes;
                finalStats.maxCellsPerVolumeDynamic = math.max(finalStats.maxCellsPerVolumeDynamic, s.maxCellsPerVolume);
            }

            for (int i = 0; i < broadphaseThreadStatsSpawnDynamic.Length; i++)
            {
                var s = broadphaseThreadStatsSpawnDynamic[i];

                finalStats.broadphaseCellAddsDynamic += s.broadphaseCellAdds;
                finalStats.countVolumesUpdatedGrid += s.countVolumesUpdatedGrid;
                finalStats.totalDynamicVolumeCells += s.totalVolumeCells;
                finalStats.numDynamicVolumes += s.numVolumes;
                finalStats.maxCellsPerVolumeDynamic = math.max(finalStats.maxCellsPerVolumeDynamic, s.maxCellsPerVolume);
            }

            for (int i = 0; i < broadphaseThreadStatsSpawnStatic.Length; i++)
            {
                var s = broadphaseThreadStatsSpawnStatic[i];

                finalStats.broadphaseCellAddsStatic += s.broadphaseCellAdds;
                finalStats.totalStaticVolumeCells += s.totalVolumeCells;
                finalStats.numStaticVolumes += s.numVolumes;
                finalStats.maxCellsPerVolumeStatic = math.max(finalStats.maxCellsPerVolumeStatic, s.maxCellsPerVolume);
            }

            for (int i = 0; i < broadphaseThreadStatsDespawnDynamic.Length; i++)
            {
                var s = broadphaseThreadStatsDespawnDynamic[i];

                finalStats.broadphaseCellRemovalsDynamic += s.broadphaseCellRemovals;
                finalStats.countVolumesUpdatedGrid += s.countVolumesUpdatedGrid;
                finalStats.totalDynamicVolumeCells += s.totalVolumeCells;
                finalStats.numDynamicVolumes += s.numVolumes;
            }

            for (int i = 0; i < broadphaseThreadStatsDespawnStatic.Length; i++)
            {
                var s = broadphaseThreadStatsDespawnStatic[i];

                finalStats.broadphaseCellRemovalsStatic += s.broadphaseCellRemovals;
                finalStats.totalStaticVolumeCells += s.totalVolumeCells;
                finalStats.numStaticVolumes += s.numVolumes;
            }

            // Assign single-threaded stats
            finalStats.totalBroadphasePairs = broadphaseSingleThreadedStats.Value.totalBroadphasePairs;
            finalStats.newPairsGenerated = broadphaseSingleThreadedStats.Value.newPairsGenerated;
            finalStats.existingPairsRemoved = broadphaseSingleThreadedStats.Value.existingPairsRemoved;
            finalStats.existingPairsUpdated = broadphaseSingleThreadedStats.Value.existingPairsUpdated;

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
            if (DebugConstants.ENABLE_BROADPHASE_DRAW_PAIRS)
            {
#pragma warning disable CS0162 // Unreachable code detected
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

                    UnityEngine.Debug.DrawLine(posA, posB, color, Time.fixedDeltaTime);
                }
#pragma warning restore CS0162 // Unreachable code detected
            }
        }
        #endregion

        #endregion

        #region COLLISION DETECTION - NARROWPHASE
        // -------------------------------------------------
        // BROADPHASE
        // -------------------------------------------------
        public static void findCollisionNarrowphaseContacts(ref SystemState state,
            NativeArray<PotentiallyCollidingPair> broadphasePairs)
        {
            // TODO return an empty list if early exit on no broadphase pairs

            if (!broadphasePairs.IsCreated || broadphasePairs.Length == 0)
                return;

            var localToWorldLookup = state.GetComponentLookup<LocalToWorld>(true);
            var renderBoundsLookup = state.GetComponentLookup<RenderBounds>(true);

            var job = new NarrowphasePairJob
            {
                Pairs = broadphasePairs,
                LocalToWorldLookup = localToWorldLookup,
                RenderBoundsLookup = renderBoundsLookup
            };

            state.Dependency = job.ScheduleParallel(broadphasePairs.Length, 64, state.Dependency);
        }

        #region Job Structs
        [BurstCompile]
        private struct NarrowphasePairJob : IJobFor
        {
            const float epsilon = 1e-6f;

            [ReadOnly] public NativeArray<PotentiallyCollidingPair> Pairs;
            [ReadOnly] public ComponentLookup<LocalToWorld> LocalToWorldLookup;
            [ReadOnly] public ComponentLookup<RenderBounds> RenderBoundsLookup;

            public void Execute(int index)
            {
                PotentiallyCollidingPair pair = Pairs[index];
                Entity entityA = pair.A;
                Entity entityB = pair.B;

                if (!LocalToWorldLookup.HasComponent(entityA) ||
                    !LocalToWorldLookup.HasComponent(entityB) ||
                    !RenderBoundsLookup.HasComponent(entityA) ||
                    !RenderBoundsLookup.HasComponent(entityB))
                {
                    return;
                }

                LocalToWorld ltwA = LocalToWorldLookup[entityA];
                LocalToWorld ltwB = LocalToWorldLookup[entityB];

                AABB localBoundsA = RenderBoundsLookup[entityA].Value;
                AABB localBoundsB = RenderBoundsLookup[entityB].Value;

                checkForSphereCollision(ltwA, ltwB, localBoundsA, localBoundsB);
            }

            #region Narrow Phase - Sphere
            private static void checkForSphereCollision(LocalToWorld ltwA, LocalToWorld ltwB, AABB localBoundsA, AABB localBoundsB)
            {
                // Calcs needed by subsequent checks too
                float3 localCenterA = localBoundsA.Center;
                float3 localCenterB = localBoundsB.Center;

                float3 localExtentsA = localBoundsA.Extents;
                float3 localExtentsB = localBoundsB.Extents;

                float3 worldCenterA = math.transform(ltwA.Value, localCenterA);
                float3 worldCenterB = math.transform(ltwB.Value, localCenterB);

                float3 rightA = ltwA.Right;
                float3 rightB = ltwB.Right;
                float3 upA = ltwA.Up;
                float3 upB = ltwB.Up;
                float3 forwardA = ltwA.Forward;
                float3 forwardB = ltwB.Forward;

                // Calcs specific for sphere check
                float maxAxisScaleA = math.max(math.length(rightA), math.max(math.length(upA), math.length(forwardA)));
                float maxAxisScaleB = math.max(math.length(rightB), math.max(math.length(upB), math.length(forwardB)));

                float localRadiusA = math.length(localExtentsA);
                float localRadiusB = math.length(localExtentsB);

                float radiusA = localRadiusA * maxAxisScaleA;
                float radiusB = localRadiusB * maxAxisScaleB;
                float combinedRadius = radiusA + radiusB;

                // Sphere collision early exit
                if (math.lengthsq(worldCenterA - worldCenterB) <= combinedRadius * combinedRadius) return;

                checkForAABBCollision(worldCenterA, worldCenterB, rightA, rightB, upA, upB,
                    forwardA, forwardB, localExtentsA, localExtentsB);
            }
            #endregion

            #region Narrow Phase - AABB Check
            private static void checkForAABBCollision(float3 worldCenterA, float3 worldCenterB, float3 rightA, float3 rightB,
                float3 upA, float3 upB, float3 forwardA, float3 forwardB, float3 localExtentsA, float3 localExtentsB)
            {
                // Calcs specific for world AABB check
                float3 worldExtentsA =
                    math.abs(rightA) * localExtentsA.x +
                    math.abs(upA) * localExtentsA.y +
                    math.abs(forwardA) * localExtentsA.z;
                float3 worldExtentsB =
                    math.abs(rightB) * localExtentsB.x +
                    math.abs(upB) * localExtentsB.y +
                    math.abs(forwardB) * localExtentsB.z;

                float3 minA = worldCenterA - worldExtentsA;
                float3 minB = worldCenterB - worldExtentsB;

                float3 maxA = worldCenterA + worldExtentsA;
                float3 maxB = worldCenterB + worldExtentsB;

                // AABB collision early exits
                if (maxA.x < minB.x || minA.x > maxB.x) return;
                if (maxA.y < minB.y || minA.y > maxB.y) return;
                if (maxA.z < minB.z || minA.z > maxB.z) return;

                checkForOBBCollision(worldCenterA, worldCenterB, rightA, rightB, upA, upB, 
                    forwardA, forwardB, localExtentsA, localExtentsB);
            }
            #endregion

            #region Narrow Phase - OBB check

            private static void checkForOBBCollision(float3 worldCenterA, float3 worldCenterB, float3 rightA, float3 rightB,
                float3 upA, float3 upB, float3 forwardA, float3 forwardB, float3 localExtentsA, float3 localExtentsB)
            {
                float lenXA = math.length(rightA);
                float lenYA = math.length(upA);
                float lenZA = math.length(forwardA);

                float lenXB = math.length(rightB);
                float lenYB = math.length(upB);
                float lenZB = math.length(forwardB);

                float invLenXA = lenXA > epsilon ? 1.0f / lenXA : 0.0f;
                float invLenYA = lenYA > epsilon ? 1.0f / lenYA : 0.0f;
                float invLenZA = lenZA > epsilon ? 1.0f / lenZA : 0.0f;

                float invLenXB = lenXB > epsilon ? 1.0f / lenXB : 0.0f;
                float invLenYB = lenYB > epsilon ? 1.0f / lenYB : 0.0f;
                float invLenZB = lenZB > epsilon ? 1.0f / lenZB : 0.0f;

                float3 A0 = rightA * invLenXA;
                float3 A1 = upA * invLenYA;
                float3 A2 = forwardA * invLenZA;

                float3 B0 = rightB * invLenXB;
                float3 B1 = upB * invLenYB;
                float3 B2 = forwardB * invLenZB;

                float3 HalfExtentsA = new float3(
                    localExtentsA.x * lenXA,
                    localExtentsA.y * lenYA,
                    localExtentsA.z * lenZA);
                float3 HalfExtentsB = new float3(
                    localExtentsB.x * lenXB,
                    localExtentsB.y * lenYB,
                    localExtentsB.z * lenZB);

                float3 tWorld = worldCenterB - worldCenterA;

                // Translation expressed in A's basis
                float t0 = math.dot(tWorld, A0);
                float t1 = math.dot(tWorld, A1);
                float t2 = math.dot(tWorld, A2);

                // Rotation matrix R = transpose(A) * B
                float R00 = math.dot(A0, B0);
                float R01 = math.dot(A0, B1);
                float R02 = math.dot(A0, B2);

                float R10 = math.dot(A1, B0);
                float R11 = math.dot(A1, B1);
                float R12 = math.dot(A1, B2);

                float R20 = math.dot(A2, B0);
                float R21 = math.dot(A2, B1);
                float R22 = math.dot(A2, B2);

                float AR00 = math.abs(R00) + epsilon;
                float AR01 = math.abs(R01) + epsilon;
                float AR02 = math.abs(R02) + epsilon;

                float AR10 = math.abs(R10) + epsilon;
                float AR11 = math.abs(R11) + epsilon;
                float AR12 = math.abs(R12) + epsilon;

                float AR20 = math.abs(R20) + epsilon;
                float AR21 = math.abs(R21) + epsilon;
                float AR22 = math.abs(R22) + epsilon;

                float a0 = HalfExtentsA.x;
                float a1 = HalfExtentsA.y;
                float a2 = HalfExtentsA.z;

                float b0 = HalfExtentsB.x;
                float b1 = HalfExtentsB.y;
                float b2 = HalfExtentsB.z;

                float ra, rb, t;

                // ---------------------
                // 15 SAT checks
                // ---------------------

                // Test A's local axes
                ra = a0;
                rb = b0 * AR00 + b1 * AR01 + b2 * AR02;
                if (math.abs(t0) > ra + rb) return;

                ra = a1;
                rb = b0 * AR10 + b1 * AR11 + b2 * AR12;
                if (math.abs(t1) > ra + rb) return;

                ra = a2;
                rb = b0 * AR20 + b1 * AR21 + b2 * AR22;
                if (math.abs(t2) > ra + rb) return;

                // Test B's local axes
                ra = a0 * AR00 + a1 * AR10 + a2 * AR20;
                rb = b0;
                t = math.abs(t0 * R00 + t1 * R10 + t2 * R20);
                if (t > ra + rb) return;

                ra = a0 * AR01 + a1 * AR11 + a2 * AR21;
                rb = b1;
                t = math.abs(t0 * R01 + t1 * R11 + t2 * R21);
                if (t > ra + rb) return;

                ra = a0 * AR02 + a1 * AR12 + a2 * AR22;
                rb = b2;
                t = math.abs(t0 * R02 + t1 * R12 + t2 * R22);
                if (t > ra + rb) return;

                // Test cross products A0 x Bj
                ra = a1 * AR20 + a2 * AR10;
                rb = b1 * AR02 + b2 * AR01;
                t = math.abs(t2 * R10 - t1 * R20);
                if (t > ra + rb) return;

                ra = a1 * AR21 + a2 * AR11;
                rb = b0 * AR02 + b2 * AR00;
                t = math.abs(t2 * R11 - t1 * R21);
                if (t > ra + rb) return;

                ra = a1 * AR22 + a2 * AR12;
                rb = b0 * AR01 + b1 * AR00;
                t = math.abs(t2 * R12 - t1 * R22);
                if (t > ra + rb) return;

                // Test cross products A1 x Bj
                ra = a0 * AR20 + a2 * AR00;
                rb = b1 * AR12 + b2 * AR11;
                t = math.abs(t0 * R20 - t2 * R00);
                if (t > ra + rb) return;

                ra = a0 * AR21 + a2 * AR01;
                rb = b0 * AR12 + b2 * AR10;
                t = math.abs(t0 * R21 - t2 * R01);
                if (t > ra + rb) return;

                ra = a0 * AR22 + a2 * AR02;
                rb = b0 * AR11 + b1 * AR10;
                t = math.abs(t0 * R22 - t2 * R02);
                if (t > ra + rb) return;

                // Test cross products A2 x Bj
                ra = a0 * AR10 + a1 * AR00;
                rb = b1 * AR22 + b2 * AR21;
                t = math.abs(t1 * R00 - t0 * R10);
                if (t > ra + rb) return;

                ra = a0 * AR11 + a1 * AR01;
                rb = b0 * AR22 + b2 * AR20;
                t = math.abs(t1 * R01 - t0 * R11);
                if (t > ra + rb) return;

                ra = a0 * AR12 + a1 * AR02;
                rb = b0 * AR21 + b1 * AR20;
                t = math.abs(t1 * R02 - t0 * R12);
                if (t > ra + rb) return;

                checkForVoxelCollisions();
            }
            #endregion

            #region Narrow Phase - Voxel Check

            private static void checkForVoxelCollisions()
            {
                // TODO implement this
            }

            #endregion
        }
        #endregion

        #endregion
    }
}