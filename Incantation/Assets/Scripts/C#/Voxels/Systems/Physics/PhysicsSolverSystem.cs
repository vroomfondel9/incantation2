using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Debug;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;
using Incantation.Engine.Voxels.Systems.Physics.Support;
using Incantation.Engine.Voxels.Utils.Debug;
using NUnit;
using NUnit.Framework;
using System;
using Unity.Burst;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Entities;
using Unity.Jobs;
using Unity.Jobs.LowLevel.Unsafe;
using Unity.Logging;
using Unity.Mathematics;
using Unity.Rendering;
using Unity.Transforms;
using UnityEngine;
using UnityEngine.SocialPlatforms;
using UnityEngine.UIElements;

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

#if STATS_BROADPHASE
        NativeArray<BroadphaseStatsThreadLocal> broadphaseThreadStatsUpdatesDynamic;
        NativeArray<BroadphaseStatsThreadLocal> broadphaseThreadStatsSpawnDynamic;
        NativeArray<BroadphaseStatsThreadLocal> broadphaseThreadStatsSpawnStatic;
        NativeArray<BroadphaseStatsThreadLocal> broadphaseThreadStatsDespawnDynamic;
        NativeArray<BroadphaseStatsThreadLocal> broadphaseThreadStatsDespawnStatic;
        NativeReference<BroadphaseStatsSingleThreaded> broadphaseSingleThreadedStats;
#endif
        #endregion

        #region Collections - Narrowphase
        NativeList<PotentiallyCollidingPair> narrowphasePairsNeedingVoxelLevelCheck;
        NativeList<Support.ContactPoint> contactPoints;

#if STATS_NARROWPHASE
        NativeArray<NarrowphaseStatsThreadLocal> narrowThreadStats;
#endif
        #endregion

        #region Component Lookups - Narrowphase
        private ComponentLookup<LocalTransform> localTransformLookup;
        private ComponentLookup<LocalToWorld> localToWorldLookup;
        private ComponentLookup<PrevTransform> prevTransformLookup;
        private ComponentLookup<OriginalTopologyReference> originalTopologyRefLookup;
        private ComponentLookup<OriginalDimensions> originalDimensionsLookup;
        private ComponentLookup<IsVoxelVolume> isVoxelVolumeLookup;
        private ComponentLookup<IsDynamic> isDynamicLookup;
        #endregion

        public void OnCreate(ref SystemState state)
        {
            int maxEntitiesPerSceneCapacity = GlobalConstants.MAX_UNIQUE_ORIG_VOX_VOLS_PER_SCENE;
            int maxEntitiesPerScenePairsCapacity = maxEntitiesPerSceneCapacity * GlobalConstants.AVG_PAIRS_PER_VOX_VOL;
            int maxCollidingObjects = (int) math.round(maxEntitiesPerScenePairsCapacity * GlobalConstants.AVG_COLLISION_RATE_PER_PAIR);
            int maxContactPoints = maxCollidingObjects * GlobalConstants.MAX_CONTACTS_PER_COLLIDING_PAIR;

            // Create data structures
            #region Init Collections - Broadphase
            broadphaseDynamicCellToEntities = new NativeParallelMultiHashMap<BroadphaseCell, Entity>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            broadphaseStaticCellToEntities = new NativeParallelMultiHashMap<BroadphaseCell, Entity>(maxEntitiesPerSceneCapacity, Allocator.Persistent);

            broadphaseDynamicRemovalList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            broadphaseStaticRemovalList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            broadphaseDynamicAddedList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);
            broadphaseStaticAddedList = new NativeList<BroadphaseEntityInCell>(maxEntitiesPerSceneCapacity, Allocator.Persistent);

            broadphasePairsToCellCount = new NativeParallelHashMap<PotentiallyCollidingPair, int>(maxEntitiesPerScenePairsCapacity, Allocator.Persistent);

#if STATS_BROADPHASE
            broadphaseThreadStatsUpdatesDynamic = new NativeArray<BroadphaseStatsThreadLocal>(JobsUtility.MaxJobThreadCount,Allocator.Persistent);
            broadphaseThreadStatsSpawnDynamic = new NativeArray<BroadphaseStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            broadphaseThreadStatsSpawnStatic = new NativeArray<BroadphaseStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            broadphaseThreadStatsDespawnDynamic = new NativeArray<BroadphaseStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            broadphaseThreadStatsDespawnStatic = new NativeArray<BroadphaseStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
            broadphaseSingleThreadedStats = new NativeReference<BroadphaseStatsSingleThreaded>(Allocator.Persistent);
#endif
            #endregion

            #region Init Collections - Narrowphase
            contactPoints = new NativeList<Support.ContactPoint>(maxContactPoints, Allocator.Persistent);

            narrowphasePairsNeedingVoxelLevelCheck = new NativeList<PotentiallyCollidingPair>(maxEntitiesPerScenePairsCapacity, Allocator.Persistent);

#if STATS_NARROWPHASE
            narrowThreadStats = new NativeArray<NarrowphaseStatsThreadLocal>(JobsUtility.MaxJobThreadCount, Allocator.Persistent);
#endif
            #endregion

            // Create Component Lookups
            #region Init Component Lookups
            // TODO turns out localToWorld can be a frame behind. Rewrite things that need this
            localTransformLookup = state.GetComponentLookup<LocalTransform>(true);
            localToWorldLookup = state.GetComponentLookup<LocalToWorld>(true);
            prevTransformLookup = state.GetComponentLookup<PrevTransform>(true);
            originalTopologyRefLookup = state.GetComponentLookup<OriginalTopologyReference>(true);
            originalDimensionsLookup = state.GetComponentLookup<OriginalDimensions>(true);
            isVoxelVolumeLookup = state.GetComponentLookup<IsVoxelVolume>(true);
            isDynamicLookup = state.GetComponentLookup<IsDynamic>(true);
            #endregion

        // Create Singletons
        #region Init Singletons

#if STATS_BROADPHASE
        state.EntityManager.CreateSingleton<BroadphaseStats>();
#endif
#if STATS_NARROWPHASE
            state.EntityManager.CreateSingleton<NarrowphaseStats>();
#endif
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

#if STATS_BROADPHASE
            if (broadphaseThreadStatsUpdatesDynamic.IsCreated) broadphaseThreadStatsUpdatesDynamic.Dispose();
            if (broadphaseThreadStatsSpawnDynamic.IsCreated) broadphaseThreadStatsSpawnDynamic.Dispose();
            if (broadphaseThreadStatsSpawnStatic.IsCreated) broadphaseThreadStatsSpawnStatic.Dispose();
            if (broadphaseThreadStatsDespawnDynamic.IsCreated) broadphaseThreadStatsDespawnDynamic.Dispose();
            if (broadphaseThreadStatsDespawnStatic.IsCreated) broadphaseThreadStatsDespawnStatic.Dispose();
            if (broadphaseSingleThreadedStats.IsCreated) broadphaseSingleThreadedStats.Dispose();
#endif
            #endregion

            #region Collection Disposal - Narrowphase
            if (contactPoints.IsCreated) contactPoints.Dispose();

            if (narrowphasePairsNeedingVoxelLevelCheck.IsCreated) narrowphasePairsNeedingVoxelLevelCheck.Dispose();

#if STATS_NARROWPHASE
            if (narrowThreadStats.IsCreated) narrowThreadStats.Dispose();
#endif
            #endregion
        }

        public void OnUpdate(ref SystemState state)
        {
            NativeArray<PotentiallyCollidingPair> broadphasePairs = findCollisionBroadphasePairs(ref state);
            findCollisionNarrowphaseContacts(ref state, broadphasePairs);

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
#if STATS_BROADPHASE
            clearBroadphaseStats();
#endif

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
#if STATS_BROADPHASE
                ThreadStats = broadphaseThreadStatsUpdatesDynamic
#endif
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
#if STATS_BROADPHASE
                ThreadStats = broadphaseThreadStatsSpawnDynamic
#endif
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
#if STATS_BROADPHASE
                ThreadStats = broadphaseThreadStatsSpawnStatic
#endif
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
#if STATS_BROADPHASE
                ThreadStats = broadphaseThreadStatsDespawnDynamic
#endif
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
#if STATS_BROADPHASE
                ThreadStats = broadphaseThreadStatsDespawnStatic
#endif
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
#if STATS_BROADPHASE
                Stats = broadphaseSingleThreadedStats
#endif
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
#if STATS_BROADPHASE
                Stats = broadphaseSingleThreadedStats
#endif
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
#if STATS_BROADPHASE
                Stats = broadphaseSingleThreadedStats
#endif
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
#if STATS_BROADPHASE
                Stats = broadphaseSingleThreadedStats
#endif
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
#if STATS_BROADPHASE
                Stats = broadphaseSingleThreadedStats
#endif
            };

            var removeDyVsDyAgainstMovingH = removeDyVsDyAgainstMovingJ.Schedule(addStaticAgainstUnmovingH);

            var removeDyVsStAgainstMovingJ = new UpdateBroadphasePairsAgainstMovingJob
            {
                ListA = broadphaseDynamicRemovalList,
                ListB = broadphaseStaticRemovalList,
                PairCounts = broadphasePairsToCellCount,
                Increment = -1,
                SameList = false,
#if STATS_BROADPHASE
                Stats = broadphaseSingleThreadedStats
#endif
            };

            var removeDyVsStAgainstMovingH = removeDyVsStAgainstMovingJ.Schedule(removeDyVsDyAgainstMovingH);

            var addDyVsDyAgainstMovingJ = new UpdateBroadphasePairsAgainstMovingJob
            {
                ListA = broadphaseDynamicAddedList,
                ListB = broadphaseDynamicAddedList,
                PairCounts = broadphasePairsToCellCount,
                Increment = +1,
                SameList = true,
#if STATS_BROADPHASE
                Stats = broadphaseSingleThreadedStats
#endif
            };

            var addDyVsDyAgainstMovingH = addDyVsDyAgainstMovingJ.Schedule(removeDyVsStAgainstMovingH);

            var addDyVsStAgainstMovingJ = new UpdateBroadphasePairsAgainstMovingJob
            {
                ListA = broadphaseDynamicAddedList,
                ListB = broadphaseStaticAddedList,
                PairCounts = broadphasePairsToCellCount,
                Increment = +1,
                SameList = false,
#if STATS_BROADPHASE
                Stats = broadphaseSingleThreadedStats
#endif
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
            NativeArray<PotentiallyCollidingPair> broadphasePairs;

#if DEBUG_DRAW_BROADPHASE
            var broadphasePairsAndOccuranceCounts = broadphasePairsToCellCount.GetKeyValueArrays(Allocator.TempJob);
            drawDebugBroadphasePairResults(ref state, broadphasePairsAndOccuranceCounts);
            state.Dependency = broadphasePairsAndOccuranceCounts.Values.Dispose(state.Dependency);
            broadphasePairs = broadphasePairsAndOccuranceCounts.Keys;
#else
            broadphasePairs = broadphasePairsToCellCount.GetKeyArray(Allocator.TempJob);
#endif

#if STATS_BROADPHASE
            var mainThreadStats = broadphaseSingleThreadedStats.Value;
            mainThreadStats.totalBroadphasePairs = broadphasePairs.Length;
            broadphaseSingleThreadedStats.Value = mainThreadStats;

            aggregateBroadphaseStats(ref state);
#endif

            return broadphasePairs;
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

#if STATS_BROADPHASE
            [NativeDisableParallelForRestriction]
            public NativeArray<BroadphaseStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;
#endif

            void Execute(
                Entity entity,
                ref PrevBroadphaseCellIndices prevIndices,
                in WorldRenderBounds bounds)
            {
#if STATS_BROADPHASE
                var stats = ThreadStats[threadIndex];
#endif

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
#if STATS_BROADPHASE
                    stats.countVolumesDidNotUpdateGrid++;
                    ThreadStats[threadIndex] = stats;
#endif
                    return;
                }

#if STATS_BROADPHASE
                stats.countVolumesUpdatedGrid++;
#endif

                int3 prevMin = BroadphaseCell.DecodeMorton(prevIndices.minExtentCellIndex);
                int3 prevMax = BroadphaseCell.DecodeMorton(prevIndices.maxExtentCellIndex);

                int3 prevCellVolumeDims = prevMax - prevMin + 1;
                int3 curCellVolumeDims = maxCell - minCell + 1;
                int prevCellVolume = prevCellVolumeDims.x * prevCellVolumeDims.y * prevCellVolumeDims.z;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;
                int volumeDiff = curCellVolume - prevCellVolume;

#if STATS_BROADPHASE
                stats.totalVolumeCells += volumeDiff;
                stats.maxCellsPerVolume = math.max(stats.maxCellsPerVolume, curCellVolume);
#endif

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
#if STATS_BROADPHASE
                            stats.broadphaseCellRemovals++;
#endif
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

#if STATS_BROADPHASE
                            stats.broadphaseCellAdds++;
#endif
                        }

                prevIndices.minExtentCellIndex = newMinMorton;
                prevIndices.maxExtentCellIndex = newMaxMorton;

#if STATS_BROADPHASE
                ThreadStats[threadIndex] = stats;
#endif
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

#if STATS_BROADPHASE
            [NativeDisableParallelForRestriction]
            public NativeArray<BroadphaseStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;
#endif

            void Execute(
                [ChunkIndexInQuery] int chunkIndex,
                Entity entity,
                ref PrevBroadphaseCellIndices prevIndices,
                in WorldRenderBounds bounds)
            {
#if STATS_BROADPHASE
                var stats = ThreadStats[threadIndex];

                stats.numVolumes++;
                stats.countVolumesUpdatedGrid++;
#endif

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                int3 curCellVolumeDims = maxCell - minCell + 1;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;

#if STATS_BROADPHASE
                stats.totalVolumeCells += curCellVolume;
                stats.maxCellsPerVolume = math.max(stats.maxCellsPerVolume, curCellVolume);
#endif

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

#if STATS_BROADPHASE
                            stats.broadphaseCellAdds++;
#endif
                        }

                BroadphaseCell minCellStruct = new BroadphaseCell(minCell.x, minCell.y, minCell.z);
                BroadphaseCell maxCellStruct = new BroadphaseCell(maxCell.x, maxCell.y, maxCell.z);

                prevIndices.minExtentCellIndex = minCellStruct.Morton;
                prevIndices.maxExtentCellIndex = maxCellStruct.Morton;

                ECB.SetComponentEnabled<IsBroadphaseRecorded>(chunkIndex, entity, true);

#if STATS_BROADPHASE
                ThreadStats[threadIndex] = stats;
#endif
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

#if STATS_BROADPHASE
            [NativeDisableParallelForRestriction]
            public NativeArray<BroadphaseStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;
#endif

            void Execute(
                [ChunkIndexInQuery] int chunkIndex,
                Entity entity,
                in WorldRenderBounds bounds)
            {
#if STATS_BROADPHASE
                var stats = ThreadStats[threadIndex];

                stats.numVolumes++;
#endif

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                int3 curCellVolumeDims = maxCell - minCell + 1;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;

#if STATS_BROADPHASE
                stats.totalVolumeCells += curCellVolume;
                stats.maxCellsPerVolume = math.max(stats.maxCellsPerVolume, curCellVolume);
#endif

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

#if STATS_BROADPHASE
                            stats.broadphaseCellAdds++;
#endif
                        }

                ECB.SetComponentEnabled<IsBroadphaseRecorded>(chunkIndex, entity, true);

#if STATS_BROADPHASE
                ThreadStats[threadIndex] = stats;
#endif
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

#if STATS_BROADPHASE
            [NativeDisableParallelForRestriction]
            public NativeArray<BroadphaseStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;
#endif

            void Execute(
                Entity entity,
                in WorldRenderBounds bounds,
                in PrevBroadphaseCellIndices prev)
            {
#if STATS_BROADPHASE
                var stats = ThreadStats[threadIndex];

                stats.numVolumes--;
                stats.countVolumesUpdatedGrid++;
#endif

                int3 min = BroadphaseCell.DecodeMorton(prev.minExtentCellIndex);
                int3 max = BroadphaseCell.DecodeMorton(prev.maxExtentCellIndex);

                int3 curCellVolumeDims = max - min + 1;
                int curCellVolume = (int)(curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z);

#if STATS_BROADPHASE
                stats.totalVolumeCells -= curCellVolume;
#endif

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

#if STATS_BROADPHASE
                            stats.broadphaseCellRemovals++;
#endif
                        }
#if STATS_BROADPHASE
                ThreadStats[threadIndex] = stats;
#endif
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

#if STATS_BROADPHASE
            [NativeDisableParallelForRestriction]
            public NativeArray<BroadphaseStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;
#endif

            void Execute(
                Entity entity,
                in WorldRenderBounds bounds)
            {
#if STATS_BROADPHASE
                var stats = ThreadStats[threadIndex];

                stats.numVolumes--;
#endif

                float3 min = bounds.Value.Center - bounds.Value.Extents;
                float3 max = bounds.Value.Center + bounds.Value.Extents;

                int3 minCell = (int3)math.floor((min + WorldHalf) / CellSize);
                int3 maxCell = (int3)math.floor((max + WorldHalf) / CellSize);

                int3 curCellVolumeDims = maxCell - minCell + 1;
                int curCellVolume = curCellVolumeDims.x * curCellVolumeDims.y * curCellVolumeDims.z;

#if STATS_BROADPHASE
                stats.totalVolumeCells -= curCellVolume;
#endif

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

#if STATS_BROADPHASE
                            stats.broadphaseCellRemovals++;
#endif
                        }

#if STATS_BROADPHASE
                ThreadStats[threadIndex] = stats;
#endif
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

#if STATS_BROADPHASE
            public NativeReference<BroadphaseStatsSingleThreaded> Stats;
#endif

            public void Execute()
            {
#if STATS_BROADPHASE
                var stats = Stats.Value;
#endif

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

                            UpdatePair(pair
#if STATS_BROADPHASE
                                , ref stats
#endif
                            );

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

                            UpdatePair(pair
#if STATS_BROADPHASE
                                , ref stats
#endif
                            );

                        } while (StaticMap.TryGetNextValue(out otherStatic, ref it2));
                    }
                }

#if STATS_BROADPHASE
                Stats.Value = stats;
#endif
            }

            private void UpdatePair(PotentiallyCollidingPair pair
#if STATS_BROADPHASE
                , ref BroadphaseStatsSingleThreaded stats
#endif
            )
            {
                if (PairCounts.TryGetValue(pair, out int count))
                {
                    count += Increment;

                    if (count == 0)
                    {
                        PairCounts.Remove(pair);
#if STATS_BROADPHASE
                        stats.existingPairsRemoved++;
#endif
                    }
                    else
                    {
                        PairCounts[pair] = count;
#if STATS_BROADPHASE
                        stats.existingPairsUpdated++;
#endif
                    }
                }
                else
                {
                    PairCounts.Add(pair, Increment);
#if STATS_BROADPHASE
                    stats.newPairsGenerated++;
#endif
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

#if STATS_BROADPHASE
            public NativeReference<BroadphaseStatsSingleThreaded> Stats;
#endif

            public void Execute()
            {
#if STATS_BROADPHASE
                var stats = Stats.Value;
#endif

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

                        UpdatePair(pair
#if STATS_BROADPHASE
                            , ref stats
#endif
                        );
                    }
                }
#if STATS_BROADPHASE
                Stats.Value = stats;
#endif
            }

            private void UpdatePair(PotentiallyCollidingPair pair
#if STATS_BROADPHASE
                , ref BroadphaseStatsSingleThreaded stats
#endif
            )
            {
                if (PairCounts.TryGetValue(pair, out int count))
                {
                    count += Increment;

                    if (count == 0)
                    {
                        PairCounts.Remove(pair);
#if STATS_BROADPHASE
                        stats.existingPairsRemoved++;
#endif
                    }
                    else
                    {
                        PairCounts[pair] = count;
#if STATS_BROADPHASE
                        stats.existingPairsUpdated++;
#endif
                    }
                }
                else
                {
                    PairCounts.Add(pair, Increment);
#if STATS_BROADPHASE
                    stats.newPairsGenerated++;
#endif
                }
            }
        }
        #endregion

        #region STATS COLLECTION AND DEBUG VISUALIZATION
#if STATS_BROADPHASE
        // This is 32-128 items so don't worry about parallelizing
        private void clearBroadphaseStats()
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

        private void aggregateBroadphaseStats(ref SystemState state)
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

#endif

#if DEBUG_DRAW_BROADPHASE
        private void drawDebugBroadphasePairResults(ref SystemState state, NativeKeyValueArrays<PotentiallyCollidingPair, int> broadphasePairs)
        {
            if (DebugSwitches.DRAW_BROADPHASE)
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

                    UnityEngine.Debug.DrawLine(posA, posB, color, Time.fixedDeltaTime);
                }
            }
        }
#endif
        #endregion

        #endregion

        #region COLLISION DETECTION - NARROWPHASE
        // -------------------------------------------------
        // NARROWPHASE
        // -------------------------------------------------
        public void findCollisionNarrowphaseContacts(ref SystemState state,
            NativeArray<PotentiallyCollidingPair> broadphasePairs)
        {
            #region Init
            // TODO return an empty list if early exit on no broadphase pairs

            if (!broadphasePairs.IsCreated || broadphasePairs.Length == 0)
                return;

            localTransformLookup.Update(ref state);
            localToWorldLookup.Update(ref state);
            prevTransformLookup.Update(ref state);
            originalTopologyRefLookup.Update(ref state);
            originalDimensionsLookup.Update(ref state);
            isVoxelVolumeLookup.Update(ref state);
            isDynamicLookup.Update(ref state);

            contactPoints.Clear();
            narrowphasePairsNeedingVoxelLevelCheck.Clear();

            float fixedDeltaTime = SystemAPI.Time.DeltaTime;

#if DEBUG_DRAW_NARROWPHASE
            EntityCommandBuffer ecb = new EntityCommandBuffer(Allocator.TempJob);
            clearDebugVisualizationFlags(ref state);
#endif

#if STATS_NARROWPHASE
            clearNarrowphaseStats();
#endif
            #endregion

            var volumeWideNarrowphaseJob = new NarrowphaseVolumeWidePairJob
            {
                PairsToCheck = broadphasePairs,
                LocalToWorldLookup = localToWorldLookup,
#if DEBUG_DRAW_NARROWPHASE
                ECB = ecb.AsParallelWriter(),
#endif
                VoxelCheckPairs = narrowphasePairsNeedingVoxelLevelCheck.AsParallelWriter(),
#if STATS_NARROWPHASE
                ThreadStats = narrowThreadStats
#endif
            };

            var volumeWideNarrowphaseJobHandle = volumeWideNarrowphaseJob.ScheduleParallel(broadphasePairs.Length, 64, state.Dependency);
            volumeWideNarrowphaseJobHandle.Complete();

            var voxelLevelNarrowphaseJob = new NarrowphaseVoxelPairJob
            {
                PairsToCheck = narrowphasePairsNeedingVoxelLevelCheck.AsArray(),
                ContactPoints = contactPoints.AsParallelWriter(),

                LocalTransformLookup = localTransformLookup,
                PrevTransformLookup = prevTransformLookup,
                TopologyRefLookup = originalTopologyRefLookup,
                DimensionsLookup = originalDimensionsLookup,
                IsVoxelVolumeLookup = isVoxelVolumeLookup,
                IsDynamicLookup = isDynamicLookup,

                FixedDeltaTime = fixedDeltaTime
            };

            state.Dependency = voxelLevelNarrowphaseJob.ScheduleParallel(narrowphasePairsNeedingVoxelLevelCheck.Length, 64, volumeWideNarrowphaseJobHandle);
            state.Dependency.Complete();

#if DEBUG_DRAW_NARROWPHASE
            if (DebugSwitches.DRAW_NARROWPHASE)
            {
                ecb.Playback(state.EntityManager);
            }
            ecb.Dispose();
#endif

            Log.Debug($"Found {contactPoints.Length} contact points.");

#if STATS_NARROWPHASE
            aggregateNarrowphaseStats(ref state);
#endif
        }

        #region Job Structs

        #region Volume-Wide Narrowphase
        [BurstCompile]
        private struct NarrowphaseVolumeWidePairJob : IJobFor
        {
            private const float epsilon = 1e-6f;

            private readonly static float3 LOCAL_EXTENTS = new float3(0.5f, 0.5f, 0.5f);
            private readonly static float LOCAL_EXTENTS_LENGTH = math.length(LOCAL_EXTENTS);

            [ReadOnly] public NativeArray<PotentiallyCollidingPair> PairsToCheck;
            [ReadOnly] public ComponentLookup<LocalToWorld> LocalToWorldLookup;
#if DEBUG_DRAW_NARROWPHASE
            public EntityCommandBuffer.ParallelWriter ECB;
#endif
            public NativeList<PotentiallyCollidingPair>.ParallelWriter VoxelCheckPairs;

#if STATS_NARROWPHASE
            [NativeDisableParallelForRestriction]
            public NativeArray<NarrowphaseStatsThreadLocal> ThreadStats;

            [NativeSetThreadIndex] int threadIndex;
#endif

            public void Execute(int index)
            {
                #region Compute Shared Values
#if STATS_NARROWPHASE
                var stats = ThreadStats[threadIndex];
                stats.totalPairsFromBroadphase++;
#endif

                PotentiallyCollidingPair pair = PairsToCheck[index];
                Entity entityA = pair.A;
                Entity entityB = pair.B;

                if (!LocalToWorldLookup.HasComponent(entityA) ||
                    !LocalToWorldLookup.HasComponent(entityB))
                {
#if STATS_NARROWPHASE
                    ThreadStats[threadIndex] = stats;
#endif
                    return;
                }

                // Commonly shared value calculation
                LocalToWorld ltwA = LocalToWorldLookup[entityA];
                LocalToWorld ltwB = LocalToWorldLookup[entityB];

                float3 worldCenterA = ltwA.Position;
                float3 worldCenterB = ltwB.Position;

                float3 rightA = ltwA.Right;
                float3 rightB = ltwB.Right;
                float3 upA = ltwA.Up;
                float3 upB = ltwB.Up;
                float3 forwardA = ltwA.Forward;
                float3 forwardB = ltwB.Forward;

                float rightALength = math.length(rightA);
                float rightBLength = math.length(rightB);
                float upALength = math.length(upA);
                float upBLength = math.length(upB);
                float forwardALength = math.length(forwardA);
                float forwardBLength = math.length(forwardB);
                #endregion

                #region Shape-Based Checks
                if (!isSphereCollision(worldCenterA, worldCenterB, rightALength, rightBLength, 
                    upALength, upBLength, forwardALength, forwardBLength))
                {
#if STATS_NARROWPHASE
                    ThreadStats[threadIndex] = stats;
#endif
                    return;
                }
#if DEBUG_DRAW_NARROWPHASE
                else
                {
                    ECB.SetComponentEnabled<DebugCollNearSphereHit>(index, entityA, true);
                    ECB.SetComponentEnabled<DebugCollNearSphereHit>(index, entityB, true);
                }
#endif

#if STATS_NARROWPHASE
                stats.spherePassed++;
#endif

                if (!isAABBCollision(worldCenterA, worldCenterB, rightA, rightB, upA, upB, forwardA, forwardB))
                {
#if STATS_NARROWPHASE
                    ThreadStats[threadIndex] = stats;
#endif
                    return;
                }
#if DEBUG_DRAW_NARROWPHASE
                else
                {
                    ECB.SetComponentEnabled<DebugCollNearAABBHit>(index, entityA, true);
                    ECB.SetComponentEnabled<DebugCollNearAABBHit>(index, entityB, true);
                }
#endif

#if STATS_NARROWPHASE
                stats.aabbPassed++;
#endif

                if (!isOBBCollision(worldCenterA, worldCenterB, rightA, rightB,
                    upA, upB, forwardA, forwardB, rightALength, rightBLength,
                    upALength, upBLength, forwardALength, forwardBLength))
                {
#if STATS_NARROWPHASE
                    ThreadStats[threadIndex] = stats;
#endif
                    return;
                }
#if DEBUG_DRAW_NARROWPHASE
                else
                {
                    ECB.SetComponentEnabled<DebugCollNearOBBHit>(index, entityA, true);
                    ECB.SetComponentEnabled<DebugCollNearOBBHit>(index, entityB, true);
                }
#endif

#if STATS_NARROWPHASE
                stats.obbPassed++;
#endif
                #endregion

                #region Write Results
                // Write results
                VoxelCheckPairs.AddNoResize(pair);

#if STATS_NARROWPHASE
                ThreadStats[threadIndex] = stats;
#endif
                #endregion
            }

            #region Narrow Phase - Sphere Check
            private static bool isSphereCollision(float3 worldCenterA, float3 worldCenterB, float rightALength, float rightBLength, 
                float upALength, float upBLength, float forwardALength, float forwardBLength)
            {
                float maxAxisScaleA = math.max(rightALength, math.max(upALength, forwardALength));
                float maxAxisScaleB = math.max(rightBLength, math.max(upBLength, forwardBLength));

                float radiusA = LOCAL_EXTENTS_LENGTH * maxAxisScaleA;
                float radiusB = LOCAL_EXTENTS_LENGTH * maxAxisScaleB;
                float combinedRadius = radiusA + radiusB;

                return math.lengthsq(worldCenterA - worldCenterB) <= combinedRadius * combinedRadius;
            }
            #endregion

            #region Narrow Phase - AABB Check
            private static bool isAABBCollision(float3 worldCenterA, float3 worldCenterB, 
                float3 rightA, float3 rightB, float3 upA, float3 upB, float3 forwardA, float3 forwardB)
            {
                float3 worldExtentsA =
                    math.abs(rightA) * LOCAL_EXTENTS.x +
                    math.abs(upA) * LOCAL_EXTENTS.y +
                    math.abs(forwardA) * LOCAL_EXTENTS.z;

                float3 worldExtentsB =
                    math.abs(rightB) * LOCAL_EXTENTS.x +
                    math.abs(upB) * LOCAL_EXTENTS.y +
                    math.abs(forwardB) * LOCAL_EXTENTS.z;

                float3 minA = worldCenterA - worldExtentsA;
                float3 minB = worldCenterB - worldExtentsB;

                float3 maxA = worldCenterA + worldExtentsA;
                float3 maxB = worldCenterB + worldExtentsB;

                if (maxA.x < minB.x || minA.x > maxB.x) return false;
                if (maxA.y < minB.y || minA.y > maxB.y) return false;
                if (maxA.z < minB.z || minA.z > maxB.z) return false;

                return true;
            }
            #endregion

            #region Narrow Phase - OBB check

            private static bool isOBBCollision(float3 worldCenterA, float3 worldCenterB, float3 rightA, float3 rightB,
                float3 upA, float3 upB, float3 forwardA, float3 forwardB, float rightALength, float rightBLength,
                float upALength, float upBLength, float forwardALength, float forwardBLength)
            {
                float3 A0 = math.normalizesafe(rightA);
                float3 A1 = math.normalizesafe(upA);
                float3 A2 = math.normalizesafe(forwardA);

                float3 B0 = math.normalizesafe(rightB);
                float3 B1 = math.normalizesafe(upB);
                float3 B2 = math.normalizesafe(forwardB);

                float3 HalfExtentsA = new float3(
                    LOCAL_EXTENTS.x * rightALength,
                    LOCAL_EXTENTS.y * upALength,
                    LOCAL_EXTENTS.z * forwardALength);
                float3 HalfExtentsB = new float3(
                    LOCAL_EXTENTS.x * rightBLength,
                    LOCAL_EXTENTS.y * upBLength,
                    LOCAL_EXTENTS.z * forwardBLength);

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
                if (math.abs(t0) > ra + rb) return false;

                ra = a1;
                rb = b0 * AR10 + b1 * AR11 + b2 * AR12;
                if (math.abs(t1) > ra + rb) return false;

                ra = a2;
                rb = b0 * AR20 + b1 * AR21 + b2 * AR22;
                if (math.abs(t2) > ra + rb) return false;

                // Test B's local axes
                ra = a0 * AR00 + a1 * AR10 + a2 * AR20;
                rb = b0;
                t = math.abs(t0 * R00 + t1 * R10 + t2 * R20);
                if (t > ra + rb) return false;

                ra = a0 * AR01 + a1 * AR11 + a2 * AR21;
                rb = b1;
                t = math.abs(t0 * R01 + t1 * R11 + t2 * R21);
                if (t > ra + rb) return false;

                ra = a0 * AR02 + a1 * AR12 + a2 * AR22;
                rb = b2;
                t = math.abs(t0 * R02 + t1 * R12 + t2 * R22);
                if (t > ra + rb) return false;

                // Test cross products A0 x Bj
                ra = a1 * AR20 + a2 * AR10;
                rb = b1 * AR02 + b2 * AR01;
                t = math.abs(t2 * R10 - t1 * R20);
                if (t > ra + rb) return false;

                ra = a1 * AR21 + a2 * AR11;
                rb = b0 * AR02 + b2 * AR00;
                t = math.abs(t2 * R11 - t1 * R21);
                if (t > ra + rb) return false;

                ra = a1 * AR22 + a2 * AR12;
                rb = b0 * AR01 + b1 * AR00;
                t = math.abs(t2 * R12 - t1 * R22);
                if (t > ra + rb) return false;

                // Test cross products A1 x Bj
                ra = a0 * AR20 + a2 * AR00;
                rb = b1 * AR12 + b2 * AR11;
                t = math.abs(t0 * R20 - t2 * R00);
                if (t > ra + rb) return false;

                ra = a0 * AR21 + a2 * AR01;
                rb = b0 * AR12 + b2 * AR10;
                t = math.abs(t0 * R21 - t2 * R01);
                if (t > ra + rb) return false;

                ra = a0 * AR22 + a2 * AR02;
                rb = b0 * AR11 + b1 * AR10;
                t = math.abs(t0 * R22 - t2 * R02);
                if (t > ra + rb) return false;

                // Test cross products A2 x Bj
                ra = a0 * AR10 + a1 * AR00;
                rb = b1 * AR22 + b2 * AR21;
                t = math.abs(t1 * R00 - t0 * R10);
                if (t > ra + rb) return false;

                ra = a0 * AR11 + a1 * AR01;
                rb = b0 * AR22 + b2 * AR20;
                t = math.abs(t1 * R01 - t0 * R11);
                if (t > ra + rb) return false;

                ra = a0 * AR12 + a1 * AR02;
                rb = b0 * AR21 + b1 * AR20;
                t = math.abs(t1 * R02 - t0 * R12);
                if (t > ra + rb) return false;

                return true;
            }
            #endregion
        }
        #endregion

        #region Voxel-Level Narrowphase
        [BurstCompile]
        public struct NarrowphaseVoxelPairJob : IJobFor
        {
            #region Struct Properties
            [ReadOnly] public NativeArray<PotentiallyCollidingPair> PairsToCheck;
            public NativeList<Support.ContactPoint>.ParallelWriter ContactPoints;

            [ReadOnly] public ComponentLookup<LocalTransform> LocalTransformLookup;
            [ReadOnly] public ComponentLookup<PrevTransform> PrevTransformLookup;
            [ReadOnly] public ComponentLookup<OriginalTopologyReference> TopologyRefLookup;
            [ReadOnly] public ComponentLookup<OriginalDimensions> DimensionsLookup;
            [ReadOnly] public ComponentLookup<IsVoxelVolume> IsVoxelVolumeLookup;
            [ReadOnly] public ComponentLookup<IsDynamic> IsDynamicLookup;

            [ReadOnly] public float FixedDeltaTime;
            #endregion

            #region Debug Visualization Color Constants
            private static readonly Color COL_MOTION_LINE_A = new Color(0.0f, 0.35f, 0.85f, 0.75f);
            private static readonly Color COL_START_A = new Color(0.0f, 0.35f, 0.85f, 0.75f);
            private static readonly Color COL_END_A = new Color(0.7f, 0.35f, 0.85f, 0.75f);

            private static readonly Color COL_MOTION_LINE_B = new Color(0.5f, 0.5f, 0.1f, 0.75f);
            private static readonly Color COL_START_B = new Color(0.5f, 0.5f, 0.1f, 0.75f);
            private static readonly Color COL_END_B = new Color(0.0f, 0.5f, 0.1f, 0.75f);

            private static readonly Color COL_COLLISION_STRUCK = new Color(1.0f, 0.0f, 0.0f, 1f);
            private static readonly Color COL_COLLISION_STRIKER = new Color(1.0f, 0.0f, 1.0f, 1f);
            private static readonly Color COL_COLLISION_CONNECTING_LINE = new Color(1.0f, 0.0f, 0.0f, 1f);

            private static readonly Color COL_CONTINUOUS_SWEEP_DIRECT_CELL_COLOR = new Color(0.75f, 0.75f, 0.75f, 0.5f);
            #endregion

            public void Execute(int index)
            {
                #region Per-Pair One-time Initialization
                var pair = PairsToCheck[index];

                Entity A = pair.A;
                Entity B = pair.B;

                if (!IsVoxelVolumeLookup.IsComponentEnabled(A) ||
                    !IsVoxelVolumeLookup.IsComponentEnabled(B))
                    return;

                #region Init Transforms
                LocalTransform localTransformAComp = LocalTransformLookup[A];
                LocalTransform localTransformBComp = LocalTransformLookup[B];

                RigidTransform rltwA_cur = new RigidTransform
                {
                    pos = localTransformAComp.Position,
                    rot = localTransformAComp.Rotation
                };

                RigidTransform rltwB_cur = new RigidTransform
                {
                    pos = localTransformBComp.Position,
                    rot = localTransformBComp.Rotation
                };

                RigidTransform rwtlA_cur = math.inverse(rltwA_cur);
                RigidTransform rwtlB_cur = math.inverse(rltwB_cur);

                RigidTransform rltwA_prev;
                RigidTransform rltwB_prev;
                RigidTransform rwtlA_prev;
                RigidTransform rwtlB_prev;

                PrevTransform prevTransformAComp;
                PrevTransform prevTransformBComp;

                bool dynamicA = IsDynamicLookup.IsComponentEnabled(A);
                bool dynamicB = IsDynamicLookup.IsComponentEnabled(B);

                if (dynamicA)
                {
                    prevTransformAComp = PrevTransformLookup[A];

                    rltwA_prev = new RigidTransform
                    {
                        pos = prevTransformAComp.Position,
                        rot = prevTransformAComp.Rotation
                    };
                    rwtlA_prev = math.inverse(rltwA_prev);
                }
                else
                {
                    rltwA_prev = rltwA_cur;
                    rwtlA_prev = rwtlA_cur;
                }

                if (dynamicB)
                {
                    prevTransformBComp = PrevTransformLookup[B];

                    rltwB_prev = new RigidTransform
                    {
                        pos = prevTransformBComp.Position,
                        rot = prevTransformBComp.Rotation
                    };
                    rwtlB_prev = math.inverse(rltwB_prev);
                }
                else
                {
                    rltwB_prev = rltwB_cur;
                    rwtlB_prev = rwtlB_cur;
                }

                RigidTransform rAprev_to_Bprev = math.mul(rwtlB_prev, rltwA_prev);
                RigidTransform rAcur_to_Bcur = math.mul(rwtlB_cur, rltwA_cur);

                RigidTransform rBprev_to_Aprev = math.mul(rwtlA_prev, rltwB_prev);
                RigidTransform rBcur_to_Acur = math.mul(rwtlA_cur, rltwB_cur);

                #endregion

                #region Init Topology
                var topoRefA = TopologyRefLookup[A];
                var topoRefB = TopologyRefLookup[B];

                ref var topoA = ref topoRefA.topologyReference.Value;
                ref var topoB = ref topoRefB.topologyReference.Value;
                #endregion

                #region Init Dimensions
                var dimsA = DimensionsLookup[A];
                var dimsB = DimensionsLookup[B];

                int3 dimensionsA = new int3((int)dimsA.X, (int)dimsA.Y, (int)dimsA.Z);
                int3 dimensionsB = new int3((int)dimsB.X, (int)dimsB.Y, (int)dimsB.Z);

                float3 dimensionsAFloat = new float3(dimensionsA);
                float3 dimensionsBFloat = new float3(dimensionsB);

                float3 invDimensionsA = 1.0f / dimensionsAFloat;
                float3 invDimensionsB = 1.0f / dimensionsBFloat;

                float3 halfDimsA = dimensionsAFloat * 0.5f;
                float3 halfDimsB = dimensionsBFloat * 0.5f;

                float3 halfCellWidthLocalA = 0.5f / dimensionsAFloat;
                float3 halfCellWidthLocalB = 0.5f / dimensionsBFloat;

                int widthA = (int)dimsA.X;
                int heightA = (int)dimsA.Y;

                int widthB = (int)dimsB.X;
                int heightB = (int)dimsB.Y;
                #endregion

                #endregion

                #region Pass 1: A corners vs B

                ref var cornersA = ref topoA.cornerCoords;

                for (int i = 0; i < cornersA.Length; i++)
                {
                    int packed = cornersA[i];
                    int3 coord = OriginalTopology.UnpackCoords(packed);

                    float3 pa_A = (new float3(coord) + 0.5f - halfDimsA) * GlobalConstants.VOXEL_SCALE;

                    float3 pa_B_prev = math.transform(rAprev_to_Bprev, pa_A);
                    float3 pa_B_cur = math.transform(rAcur_to_Bcur, pa_A);

                    checkCollision(
                        A,
                        B,
                        pa_B_prev,
                        pa_B_cur,
                        dimensionsB,
                        halfDimsB,
                        halfDimsA,
                        ref topoB,
                        TopologyClassification.CORNER,
                        true,
                        coord,
                        true,
                        rltwB_cur,
                        rltwA_cur
                    );
                }
                #endregion

                #region Pass 2: B corners vs A
                ref var cornersB = ref topoB.cornerCoords;

                for (int i = 0; i < cornersB.Length; i++)
                {
                    int packed = cornersB[i];
                    int3 coord = OriginalTopology.UnpackCoords(packed);

                    float3 pb_B = (new float3(coord) + 0.5f - halfDimsB) * GlobalConstants.VOXEL_SCALE;

                    float3 pb_A_prev = math.transform(rBprev_to_Aprev, pb_B);
                    float3 pb_A_cur = math.transform(rBcur_to_Acur, pb_B);

                    checkCollision(
                        A,
                        B,
                        pb_A_prev,
                        pb_A_cur,
                        dimensionsA,
                        halfDimsA,
                        halfDimsB,
                        ref topoA,
                        TopologyClassification.CORNER,
                        false, 
                        coord,
                        false,
                        rltwA_cur,
                        rltwB_cur
                    );
                }
                #endregion

                #region Pass 3: A edges vs B
                ref var edgesA = ref topoA.edgeCoords;

                for (int i = 0; i < edgesA.Length; i++)
                {
                    int packed = edgesA[i];
                    int3 coord = OriginalTopology.UnpackCoords(packed);

                    float3 pa_A = (new float3(coord) + 0.5f - halfDimsA) * GlobalConstants.VOXEL_SCALE;

                    float3 pa_B_prev = math.transform(rAprev_to_Bprev, pa_A);
                    float3 pa_B_cur = math.transform(rAcur_to_Bcur, pa_A);

                    checkCollision(
                        A,
                        B,
                        pa_B_prev,
                        pa_B_cur,
                        dimensionsB,
                        halfDimsB,
                        halfDimsA,
                        ref topoB,
                        TopologyClassification.EDGE,
                        true,
                        coord,
                        true,
                        rltwB_cur,
                        rltwA_cur
                    );
                }
                #endregion
            }

            #region Per-Striking Voxel Collision Check
            private bool checkCollision(
                Entity A,
                Entity B,
                float3 start,
                float3 end,
                int3 dimsStruck,
                float3 halfDimsStruck,
                float3 halfDimsStriker,
                ref OriginalTopology topologiesStruck,
                TopologyClassification topologyStriker,
                bool equalityAllowed,
                int3 strikerCoords,
                bool strikerIsA,
                RigidTransform ltwStruck,
                RigidTransform ltwStriker
                )
            {
                bool foundContact = false;
                int3 contactCoords = new int3(-1, -1, -1);
                float3 contactNormal = new float3(0, 0, 0);
                float contactTime = 0;
                float penetration = 0;

#if DEBUG_DRAW_CORNER_PROJECTIONS
                drawCornerProjection(start, end, topologyStriker, FixedDeltaTime, ltwStruck, strikerIsA,
                    COL_START_A, COL_START_B, COL_END_A, COL_END_B, COL_MOTION_LINE_A, COL_MOTION_LINE_B);
#endif

                foundContact = continuousCollisionDetectionSweep(start, end, dimsStruck, halfDimsStruck, ref topologiesStruck, 
                    topologyStriker, equalityAllowed, ltwStruck, out contactCoords, out contactNormal, out penetration, out contactTime);

                if (foundContact)
                {
                    Support.ContactPoint contactPoint = new Support.ContactPoint();

                    contactPoint.A = A;
                    contactPoint.B = B;
                    contactPoint.coordsA = strikerIsA ? strikerCoords : contactCoords;
                    contactPoint.coordsB = strikerIsA ? contactCoords : strikerCoords;
                    contactPoint.normal = contactNormal;
                    contactPoint.penetration = penetration;
                    contactPoint.time = contactTime;

#if DEBUG_DRAW_CONTACT_POINTS
                    drawContactPoint(contactPoint, strikerIsA, FixedDeltaTime, halfDimsStruck, halfDimsStriker, ltwStruck, ltwStriker,
                        COL_COLLISION_STRUCK, COL_COLLISION_STRIKER, COL_COLLISION_CONNECTING_LINE);
#endif

                    ContactPoints.AddNoResize(contactPoint);

                    return true;
                }

                return false;
            }
            #endregion

            #region Continuous Collision Detection - Voxel Cube Sweep Through Volume
            private bool continuousCollisionDetectionSweep(
                float3 start,
                float3 end,
                int3 dims,
                float3 halfDims,
                ref OriginalTopology topology,
                TopologyClassification topologyType,
                bool equalityAllowed,
                RigidTransform ltw,
                out int3 contactCoords,
                out float3 contactNormal,
                out float penetration,
                out float contactTime
                )
            {
                contactCoords = new int3(-1, -1, -1);
                contactNormal = new float3(-1, -1, -1);
                penetration = 0;
                contactTime = 0;

                #region Init and Early Exit Checking
                float3 dir = end - start;
                float3 unitDir = math.normalizesafe(dir, float3.zero);

                // We must project the cube center to its edges to account for the cube having volume.
                // If we don't, objects will sink in until the halfway point of their first voxel.
                float3 endOffset = end + unitDir * GlobalConstants.HALF_VOXEL_SCALE;

                float3 startGrid = start / GlobalConstants.VOXEL_SCALE + halfDims;
                float3 endGrid = endOffset / GlobalConstants.VOXEL_SCALE + halfDims;

                float3 gridDir = endGrid - startGrid;
                float3 invGridDir = math.select(math.rcp(gridDir), float.MaxValue, gridDir == 0);

                float3 boundsMin = 0;
                float3 boundsMax = dims;

                float3 t1 = (boundsMin - startGrid) * invGridDir;
                float3 t2 = (boundsMax - startGrid) * invGridDir;

                float3 tmin3 = math.min(t1, t2);
                float3 tmax3 = math.max(t1, t2);

                float tEnter = math.cmax(tmin3);
                float tExit = math.cmin(tmax3);

                // The cube center never passes through the other volume - early exit
                if (tEnter > tExit || tExit < 0)
                    return false;

                int width = dims.x;
                int height = dims.y;
                int depth = dims.z;

                float tStart = math.max(0, tEnter);

                float3 startGridClipped = startGrid + gridDir * tStart;
                int3 cell = math.clamp((int3)math.floor(startGridClipped), 0, dims - 1);

                int3 step = math.select(-1, 1, gridDir > 0f);

                float3 nextBoundary = cell + math.select(0f, 1f, step > 0);

                float3 tMax = tStart + (nextBoundary - startGridClipped) * invGridDir;
                float3 tDelta = math.abs(invGridDir);

                bool xlty = (tMax.x < tMax.y);
                bool xltz = (tMax.x < tMax.z);
                bool yltz = (tMax.y < tMax.z);

                bool3 axisStepped = new bool3(
                    xlty && xltz,
                    yltz && !xlty,
                    !yltz && !xltz
                );

                int3 axisMask = math.select(int3.zero, 1, axisStepped);
                float tCross = tStart;
                #endregion

                while (tCross < tExit)
                {
                    #region Check Current Cell For Collision
                    if (cell.x < 0 || cell.x >= width ||
                        cell.y < 0 || cell.y >= height ||
                            cell.z < 0 || cell.z >= depth)
                        return false;

                    var topo = topology.getTopologyAt(cell, width, height);

                    bool collision = equalityAllowed
                        ? (topologyType <= topo)
                        : (topologyType < topo);

                    if (collision)
                    {
                        contactCoords = cell;
                        contactTime = tCross;

                        float3 contactNormalLocal = -1 * step * axisMask;
                        contactNormal = math.mul(ltw.rot, contactNormalLocal);

                        float remainingT = 1f - tCross;
                        penetration = remainingT * math.length(dir);
                        penetration *= math.dot(unitDir, contactNormalLocal);
                        penetration = math.max(0f, penetration);

                        return true;
                    }

#if DEBUG_DRAW_CORNER_PROJECTION_CHECKED_CELLS
                    drawCCDCornerCheckedCell(cell, halfDims, ltw, FixedDeltaTime, topologyType,
                        COL_CONTINUOUS_SWEEP_DIRECT_CELL_COLOR);
#endif
                    #endregion

                    #region Advance Variables For Next Cell
                    tCross = math.cmin(tMax);
                    if (tCross >= tExit)
                        return false;

                    xlty = (tMax.x < tMax.y);
                    xltz = (tMax.x < tMax.z);
                    yltz = (tMax.y < tMax.z);

                    axisStepped = new bool3(
                        xlty && xltz,
                        yltz && !xlty,
                        !yltz && !xltz
                    );

                    axisMask = math.select(int3.zero, 1, axisStepped);

                    cell += step * axisMask;
                    tMax += tDelta * axisMask;
                    #endregion
                }

                return false;
            }
            #endregion
        }
        #endregion
        #endregion

        #region Stat Collection and Debug Visualization

        #region Voxel-Level Debug Visualizations
#if DEBUG_DRAW_CORNER_PROJECTIONS
        private static void drawCornerProjection(float3 start, float3 end, TopologyClassification topologyStriker, 
            float deltaTime, RigidTransform ltwStruck, bool strikerIsA, Color startAColor, Color startBColor, 
                Color endAColor, Color endBColor, Color lineAColor, Color lineBColor)
        {
            if (topologyStriker == TopologyClassification.CORNER)
            {
                Color col_start = strikerIsA ? startAColor : startBColor;
                Color col_end = strikerIsA ? endAColor : endBColor;
                Color col_motion = strikerIsA ? lineAColor : lineBColor;
                DebugShapeVizualizationUtil.DrawBox(start - GlobalConstants.HALF_VOXEL_SCALE,
                    start + GlobalConstants.HALF_VOXEL_SCALE, col_start, ltwStruck, deltaTime, false);
                DebugShapeVizualizationUtil.DrawBox(end - GlobalConstants.HALF_VOXEL_SCALE,
                    end + GlobalConstants.HALF_VOXEL_SCALE, col_end, ltwStruck, deltaTime, false);

                float3 start_W = math.transform(ltwStruck, start);
                float3 end_W = math.transform(ltwStruck, end);
                UnityEngine.Debug.DrawLine(new Vector3(start_W.x, start_W.y, start_W.z),
                    new Vector3(end_W.x, end_W.y, end_W.z), col_motion, deltaTime, false);
            }
        }
#endif

#if DEBUG_DRAW_CONTACT_POINTS
        private static void drawContactPoint(Support.ContactPoint contactPoint, bool strikerIsA, float deltaTime, 
            float3 halfDimsStruck, float3 halfDimsStriker, RigidTransform ltwStruck, RigidTransform ltwStriker,
                Color struckCol, Color strikerCol, Color lineCol)
        {
            int3 contactCoords = strikerIsA ? contactPoint.coordsB : contactPoint.coordsA;
            int3 strikerCoords = strikerIsA ? contactPoint.coordsA : contactPoint.coordsB;

            float3 contactPointLocalStruck = (new float3(contactCoords) + 0.5f - halfDimsStruck) * GlobalConstants.VOXEL_SCALE;
            DebugShapeVizualizationUtil.DrawBoxWithXFaces(contactPointLocalStruck - GlobalConstants.HALF_VOXEL_SCALE,
                contactPointLocalStruck + GlobalConstants.HALF_VOXEL_SCALE, struckCol, ltwStruck, deltaTime, false);

            float3 contactPointLocalStriker = (new float3(strikerCoords) + 0.5f - halfDimsStriker) * GlobalConstants.VOXEL_SCALE;
            DebugShapeVizualizationUtil.DrawBoxWithXFaces(contactPointLocalStriker - GlobalConstants.HALF_VOXEL_SCALE,
                contactPointLocalStriker + GlobalConstants.HALF_VOXEL_SCALE, strikerCol, ltwStriker, deltaTime, false);

            float3 contactPointWorldStruck = math.transform(ltwStruck, contactPointLocalStruck);
            float3 contactPointWorldStriker = math.transform(ltwStriker, contactPointLocalStriker);
            UnityEngine.Debug.DrawLine(new Vector3(contactPointWorldStruck.x, contactPointWorldStruck.y, contactPointWorldStruck.z),
                new Vector3(contactPointWorldStriker.x, contactPointWorldStriker.y, contactPointWorldStriker.z),
                    lineCol, deltaTime, false);
        }
#endif

#if DEBUG_DRAW_CORNER_PROJECTION_CHECKED_CELLS
        private static void drawCCDCornerCheckedCell(int3 cell, float3 halfDims, RigidTransform ltw, float deltaTime, TopologyClassification topologyType, Color color)
        {
            if (topologyType == TopologyClassification.CORNER)
            {
                float3 curPoint = (new float3(cell) + 0.5f - halfDims) * GlobalConstants.VOXEL_SCALE;
                DebugShapeVizualizationUtil.DrawBox(curPoint - GlobalConstants.HALF_VOXEL_SCALE,
                                    curPoint + GlobalConstants.HALF_VOXEL_SCALE, color, ltw, deltaTime, false);
            }
        }
#endif
        #endregion

        #region Volume-Level Debug Visualizations

#if DEBUG_DRAW_NARROWPHASE
        private void clearDebugVisualizationFlags(ref SystemState state)
        {
            if (DebugSwitches.DRAW_NARROWPHASE)
            {
                // Clear all debug flags on the main thread because we're not concerned about perf
                // if these flags are set
                foreach (var (localToWorld, entity) in
                    SystemAPI.Query<RefRO<LocalToWorld>>()
                        .WithAll<IsVoxelVolume>()
                        .WithAny<
                            DebugCollNearSphereHit,
                            DebugCollNearAABBHit,
                            DebugCollNearOBBHit>()
                        .WithEntityAccess())
                {
                    if (SystemAPI.IsComponentEnabled<DebugCollNearSphereHit>(entity))
                        SystemAPI.SetComponentEnabled<DebugCollNearSphereHit>(entity, false);

                    if (SystemAPI.IsComponentEnabled<DebugCollNearAABBHit>(entity))
                        SystemAPI.SetComponentEnabled<DebugCollNearAABBHit>(entity, false);

                    if (SystemAPI.IsComponentEnabled<DebugCollNearOBBHit>(entity))
                        SystemAPI.SetComponentEnabled<DebugCollNearOBBHit>(entity, false);
                }
            }
        }
#endif
        #endregion

        #region Stats

#if STATS_NARROWPHASE
        private void clearNarrowphaseStats()
        {
            for (int i = 0; i < narrowThreadStats.Length; i++)
                narrowThreadStats[i] = default;
        }

        private void aggregateNarrowphaseStats(ref SystemState state)
        {
            var existingStatsRW = SystemAPI.GetSingletonRW<NarrowphaseStats>();
            var existingStats = existingStatsRW.ValueRW;

            existingStats = default;

            // Aggregate per-thread stat values
            for (int i = 0; i < narrowThreadStats.Length; i++)
            {
                var s = narrowThreadStats[i];

                existingStats.startingPairs += s.totalPairsFromBroadphase;
                existingStats.eliminatedBySphereCheck += s.totalPairsFromBroadphase - s.spherePassed;
                existingStats.eliminatedByAABBCheck += s.spherePassed - s.aabbPassed;
                existingStats.eliminatedByOBBCheck += s.aabbPassed - s.obbPassed;
                existingStats.voxelCheckPairs += s.obbPassed;
            }

            // Derived stats
            int leftover;

            existingStats.voxelCheckRate = existingStats.startingPairs > 0
                ? existingStats.voxelCheckPairs / (float)existingStats.startingPairs * 100.0f : 0.0f;

            existingStats.sphereCheckFilterRate = existingStats.startingPairs > 0 
                ? existingStats.eliminatedBySphereCheck / (float)existingStats.startingPairs * 100.0f : 0.0f;

            leftover = existingStats.startingPairs - existingStats.eliminatedBySphereCheck;
            existingStats.aabbCheckFilterRate = leftover > 0
                ? existingStats.eliminatedByAABBCheck / (float)leftover * 100.0f : 0.0f;

            leftover = leftover - existingStats.eliminatedByAABBCheck;
            existingStats.obbCheckFilterRate = leftover > 0
                ? existingStats.eliminatedByOBBCheck / (float)leftover * 100.0f : 0.0f;

            existingStatsRW.ValueRW = existingStats;
        }
#endif
        #endregion

        #endregion

        #endregion
    }
}