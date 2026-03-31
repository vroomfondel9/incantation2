using Incantation.Engine.Voxels.Components;
using System;
using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Entities.UniversalDelegates;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Systems
{
    [UpdateInGroup(typeof(VoxelVolumeInitializationSystemGroup))]
    [UpdateAfter(typeof(OriginalVoxelHeapAllocationSystem))]
    [BurstCompile]
    public partial struct CPUOriginalVoxelBlobAssetManagerSystem : ISystem
    {
        private NativeHashMap<uint, BlobAssetReference<OriginalTopology>> topologyMap;

        public void OnCreate(ref SystemState state)
        {
            topologyMap = new NativeHashMap<uint, BlobAssetReference<OriginalTopology>>(
                GlobalConstants.MAX_UNIQUE_ORIG_VOX_VOLS_PER_SCENE, Allocator.Persistent);
        }

        public void OnDestroy(ref SystemState state)
        {
            if (topologyMap.IsCreated)
            {
                foreach (var kv in topologyMap)
                {
                    if (kv.Value.IsCreated)
                        kv.Value.Dispose();
                }

                topologyMap.Dispose();
            }
        }

        public void OnUpdate(ref SystemState state)
        {
            var ecb = new EntityCommandBuffer(Allocator.Temp);

            uploadData(ref state, ecb);
            reuseAlreadyUploadedSharedData(ref state, ecb);

            ecb.Playback(state.EntityManager);
            ecb.Dispose();
        }

        private void uploadData(ref SystemState state, EntityCommandBuffer ecb)
        {
            foreach (var (origDimensions, origOffset, origTopoMetadata, initialBuffer, entity)
                in SystemAPI.Query<
                        RefRO<OriginalDimensions>,
                        RefRO<OriginalVoxelVolumeGlobalOffset>,
                        RefRO<InitializationTopologyMetadata>,
                        DynamicBuffer<InitializationColorTopologyPackedVoxel>>()
                    .WithAll<ShouldUploadVoxelData>()
                    .WithEntityAccess())
            {
                uint key = origOffset.ValueRO.Value;

                BlobAssetReference<OriginalTopology> blob;
                OriginalTopologyReference topologyRef;

                // Deallocate first if already created
                if (topologyMap.TryGetValue(key, out blob))
                {
                    if (blob.IsCreated)
                        blob.Dispose();
                }

                // --------------------------------------------------
                // Blob creation
                // --------------------------------------------------

                BlobBuilder builder = new BlobBuilder(Allocator.Temp);

                ref OriginalTopology root = ref builder.ConstructRoot<OriginalTopology>();

                var origDim = origDimensions.ValueRO;
                if (initialBuffer.Length != origDim.Size)
                    throw new Exception($"Mismatched voxel region sizes prior to initial creation of Original Blob Asset. {origDim.Size}=/={initialBuffer.Length}");


                var metadata = origTopoMetadata.ValueRO;
                int packedVoxelCount = (initialBuffer.Length + 15) >> 4;
                int cornerCount = metadata.cornerCount;
                int edgeCount = metadata.edgeCount;

                var packedArray = builder.Allocate(ref root.packedTopologyVoxels, packedVoxelCount);
                var cornerArray = builder.Allocate(ref root.cornerCoords, cornerCount);
                var edgeArray = builder.Allocate(ref root.edgeCoords, edgeCount);

                int width = (int)origDim.X;
                int height = (int)origDim.Y;

                // Initialization
                uint curPackedTop = 0;
                int cornerIndex = 0;
                int edgeIndex = 0;

                for (int i = 0; i < initialBuffer.Length; i++)
                {
                    InitializationColorTopologyPackedVoxel initPackedVoxel = initialBuffer[i];
                    TopologyClassification topoClassif =
                        InitializationColorTopologyPackedVoxel.ToTopologyClassification(initPackedVoxel.PackedValue);

                    if (topoClassif == TopologyClassification.CORNER)
                        cornerArray[cornerIndex++] = OriginalTopology.FromFlattenedIndex(i, width, height);

                    if (topoClassif == TopologyClassification.EDGE)
                        edgeArray[edgeIndex++] = OriginalTopology.FromFlattenedIndex(i, width, height);

                    curPackedTop = (curPackedTop << 2) | (uint)topoClassif;

                    if ((i & 15) == 15)
                    {
                        packedArray[i >> 4] = curPackedTop;
                        curPackedTop = 0;
                    }
                }

                int leftover = initialBuffer.Length & 15;
                if (leftover > 0)
                {
                    curPackedTop <<= (16 - leftover) * 2;
                    packedArray[packedVoxelCount - 1] = curPackedTop;
                }

                if (cornerIndex != cornerCount)
                    throw new Exception($"Mismatched corner counts prior to initial creation of Original Blob Asset. {cornerIndex}=/={cornerCount}");
                if (edgeIndex != edgeCount)
                    throw new Exception($"Mismatched edge counts prior to initial creation of Original Blob Asset. {edgeIndex}=/={edgeCount}");

                blob = builder.CreateBlobAssetReference<OriginalTopology>(Allocator.Persistent);

                builder.Dispose();

                // Store in system map
                topologyMap.Add(key, blob);

                // Create component reference
                topologyRef = new OriginalTopologyReference
                {
                    topologyReference = blob
                };

                // Add component via ECB
                ecb.AddComponent(entity, topologyRef);
            }
        }
        
        private void reuseAlreadyUploadedSharedData(ref SystemState state, EntityCommandBuffer ecb)
        {
            foreach (var (origDimensions, origOffset, origTopoMetadata, initialBuffer, entity)
                in SystemAPI.Query<
                        RefRO<OriginalDimensions>,
                        RefRO<OriginalVoxelVolumeGlobalOffset>,
                        RefRO<InitializationTopologyMetadata>,
                        DynamicBuffer<InitializationColorTopologyPackedVoxel>>()
                    .WithDisabled<ShouldUploadVoxelData>()
                    .WithEntityAccess())
            {
                uint key = origOffset.ValueRO.Value;

                // Deallocate first if already created
                BlobAssetReference<OriginalTopology> blob;
                OriginalTopologyReference topologyRef;

                if (topologyMap.TryGetValue(key, out blob))
                {
                    topologyRef = new OriginalTopologyReference
                    {
                        topologyReference = blob
                    };

                    ecb.AddComponent(entity, topologyRef);
                    continue;
                }

                throw new Exception($"Non-uploading entity could not find needed shared data.");
            }
        }
    }
}