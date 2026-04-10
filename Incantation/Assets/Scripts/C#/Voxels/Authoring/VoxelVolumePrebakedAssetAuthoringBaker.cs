using Incantation.Engine.Voxels.Authoring;
using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Physics.RigidBody;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Rendering;
using Unity.Transforms;
using UnityEditor.PackageManager;
using UnityEngine;
using UnityEngine.Rendering;

namespace Incantation.Engine.Voxels.Baking
{
    public class VoxelVolumePrebakedAssetAuthoringBaker
        : Baker<VoxelVolumePrebakedAssetAuthoring>
    {
        public override void Bake(VoxelVolumePrebakedAssetAuthoring authoring)
        {
            var entity = GetEntity(TransformUsageFlags.Dynamic);
            Unity.Mathematics.Random rng = RangeRandomizer.CreateRandom(authoring);

            rng = addPlacementComponents(authoring, entity, rng);
            int3 dims = addIdentityComponents(authoring, entity);

            if (authoring.isDynamic)
            {
                addMassComponents(authoring, entity);
                rng = addVelocityComponents(authoring, entity, rng);
            }

            addEnableableComponents(authoring, entity);
            addInitializationVoxelsBufferElements(authoring, entity, dims);
            rng = addCloneOffsetBufferElements(authoring, entity, rng);
        }

        private Unity.Mathematics.Random addCloneOffsetBufferElements(VoxelVolumePrebakedAssetAuthoring authoring, Entity entity, Unity.Mathematics.Random rng)
        {
            long cloneCount = 1;

            switch (authoring.cloneCountType)
            {
                case VariableValueType.None:
                    cloneCount = 1;
                    break;

                case VariableValueType.Constant:
                    cloneCount = authoring.cloneCountMin;
                    break;

                case VariableValueType.Random:
                case VariableValueType.Range:
                    cloneCount = RangeRandomizer.RandomLong(
                        ref rng,
                        RangeRandomization.Uniform,
                        authoring.cloneCountMin,
                        authoring.cloneCountMax);
                    break;
            }

            if (cloneCount > 1)
            {
                var cloneBuffer = AddBuffer<InitializationCloneOffsets>(entity);
                cloneBuffer.EnsureCapacity((int)math.min(cloneCount, int.MaxValue));

                switch (authoring.cloneShape)
                {
                    case CloneShape.Cube:
                        generateCubicCloneOffsets(authoring, ref rng, cloneBuffer, cloneCount);
                        break;

                    case CloneShape.Sphere:
                        generateSphericalCloneOffsets(authoring, ref rng, cloneBuffer, cloneCount);
                        break;
                }
            }

            return rng;
        }

        private void addInitializationVoxelsBufferElements(VoxelVolumePrebakedAssetAuthoring authoring, Entity entity, int3 dims)
        {
            int size = dims.x * dims.y * dims.z;
            var buffer = AddBuffer<InitializationColorTopologyPackedVoxel>(entity);
            buffer.EnsureCapacity(size);

            foreach (uint packedVoxelValue in authoring.voxelVolumePrebakedAsset.packedValues)
            {
                buffer.Add(new InitializationColorTopologyPackedVoxel { PackedValue = packedVoxelValue });
            }
        }

        private void addEnableableComponents(VoxelVolumePrebakedAssetAuthoring authoring, Entity entity)
        {
            AddComponent<IsDynamic>(entity);
            SetComponentEnabled<IsDynamic>(entity, authoring.isDynamic);
        }

        private Unity.Mathematics.Random addVelocityComponents(VoxelVolumePrebakedAssetAuthoring authoring, Entity entity, Unity.Mathematics.Random rng)
        {
            float3 linearVelocity = float3.zero;

            switch (authoring.initialVelocityLinearType)
            {
                case VariableValueType.None:
                    linearVelocity = float3.zero;
                    break;

                case VariableValueType.Random:
                    linearVelocity = rng.NextFloat3Direction();
                    break;

                case VariableValueType.Constant:
                    linearVelocity = authoring.initialVelocityLinearBasis;
                    break;

                case VariableValueType.Range:
                    linearVelocity = RangeRandomizer.RandomDirectionSpread(
                        ref rng,
                        authoring.initialVelocityLinearBasis,
                        authoring.initialVelocityLinearRandomization,
                        authoring.initialVelocityLinearMinSpread,
                        authoring.initialVelocityLinearMaxSpread);
                    break;
            }

            if (authoring.initialVelocityLinearSpace == CoordSpace.Local)
            {
                linearVelocity = math.rotate(authoring.transform.rotation, linearVelocity);
            }

            // Angular Velocity
            float3 angularVelocity = float3.zero;

            switch (authoring.initialVelocityAngularType)
            {
                case VariableValueType.None:
                    angularVelocity = float3.zero;
                    break;

                case VariableValueType.Random:
                    angularVelocity = rng.NextFloat3Direction();
                    break;

                case VariableValueType.Constant:
                    angularVelocity = authoring.initialVelocityAngularMin;
                    break;

                case VariableValueType.Range:
                    angularVelocity = RangeRandomizer.RandomFloat3(
                        ref rng,
                        authoring.initialVelocityAngularRandomization,
                        authoring.initialVelocityAngularMin,
                        authoring.initialVelocityAngularMax);
                    break;
            }

            if (authoring.initialVelocityAngularSpace == CoordSpace.Local)
            {
                angularVelocity = math.rotate(authoring.transform.rotation, angularVelocity);
            }

            AddComponent(entity, new PhysicsVelocity
            {
                Linear = linearVelocity,
                Angular = angularVelocity
            });
            return rng;
        }

        private void addMassComponents(VoxelVolumePrebakedAssetAuthoring authoring, Entity entity)
        {
            float invMass = authoring.voxelVolumePrebakedAsset.inverseMass;
            float3 invInertia = new float3(
                authoring.voxelVolumePrebakedAsset.inverseInertia.x,
                authoring.voxelVolumePrebakedAsset.inverseInertia.y,
                authoring.voxelVolumePrebakedAsset.inverseInertia.z
            );
            float3 com = new float3(
                authoring.voxelVolumePrebakedAsset.centerOfMass.x,
                authoring.voxelVolumePrebakedAsset.centerOfMass.y,
                authoring.voxelVolumePrebakedAsset.centerOfMass.z
            );
            AddComponent(entity, new PhysicsMass
            {
                InverseMass = invMass,
                InverseInertia = invInertia,
                CenterOfMass = com
            });
        }

        private int3 addIdentityComponents(VoxelVolumePrebakedAssetAuthoring authoring, Entity entity)
        {
            int3 dims = authoring.voxelVolumePrebakedAsset.dimensions;
            ulong hash = authoring.voxelVolumePrebakedAsset.hash;
            AddComponent(entity, new OriginalVoxelVolumeID
            {
                Hash = hash
            });

            AddComponent(entity, new GridDimensions((uint)dims.x, (uint)dims.y, (uint)dims.z));

            AddComponent(entity, new InitializationTopologyMetadata
            {
                cornerCount = authoring.voxelVolumePrebakedAsset.cornerVoxelCount,
                edgeCount = authoring.voxelVolumePrebakedAsset.edgeVoxelCount
            });
            return dims;
        }

        private Unity.Mathematics.Random addPlacementComponents(VoxelVolumePrebakedAssetAuthoring authoring, Entity entity, Unity.Mathematics.Random rng)
        {
            float3 offset = RangeRandomizer.RandomFloat3(
                            ref rng,
                            authoring.positionOffsetRandomization,
                            authoring.positionOffsetMin,
                            authoring.positionOffsetMax
                        );

            if (authoring.positionOffsetType == VariableValueType.None)
            {
                offset = float3.zero;
            }

            AddComponent(entity, LocalTransform.FromPositionRotationScale(
                new float3(authoring.transform.position) + offset,
                authoring.transform.rotation,
                authoring.transform.localScale.x
            ));
            return rng;
        }

        private Unity.Mathematics.Random generateSphericalCloneOffsets(
            VoxelVolumePrebakedAssetAuthoring authoring,
            ref Unity.Mathematics.Random rng,
            DynamicBuffer<InitializationCloneOffsets> cloneBuffer,
            long cloneCount)
        {
            float3 voxelDims = new float3(
                authoring.voxelVolumePrebakedAsset.dimensions.x,
                authoring.voxelVolumePrebakedAsset.dimensions.y,
                authoring.voxelVolumePrebakedAsset.dimensions.z
            );

            float3 objSize = voxelDims * GlobalConstants.VOXEL_SCALE;

            float spacing = math.cmax(objSize);

            float spacingOffset = RangeRandomizer.RandomFloat(
                ref rng,
                RangeRandomization.Uniform,
                authoring.cloneSpacingMin.x,
                authoring.cloneSpacingMax.x);

            float radius = (spacing + spacingOffset) * math.pow(cloneCount, 1f / 3f);

            for (int i = 0; i < cloneCount; i++)
            {
                float3 dir = rng.NextFloat3Direction();

                float dist = rng.NextFloat(0f, radius);

                float3 posOffset = dir * dist;

                float3 velLinear = computeCloneLinearVelocityOffset(authoring, ref rng);
                float3 velAngular = computeCloneAngularVelocityOffset(authoring, ref rng);

                cloneBuffer.Add(new InitializationCloneOffsets
                {
                    Position = posOffset,
                    VelocityLinear = velLinear,
                    VelocityAngular = velAngular
                });
            }
            return rng;
        }

        private Unity.Mathematics.Random generateCubicCloneOffsets(
            VoxelVolumePrebakedAssetAuthoring authoring,
            ref Unity.Mathematics.Random rng,
            DynamicBuffer<InitializationCloneOffsets> cloneBuffer,
            long cloneCount)
        {
            int cubeSize = (int)math.ceil(math.pow(cloneCount, 1f / 3f));

            float3 voxelDims = new float3(
                authoring.voxelVolumePrebakedAsset.dimensions.x,
                authoring.voxelVolumePrebakedAsset.dimensions.y,
                authoring.voxelVolumePrebakedAsset.dimensions.z
            );

            float3 spacingObjSize = voxelDims * GlobalConstants.VOXEL_SCALE;

            float3 spacingGaps = RangeRandomizer.RandomFloat3(
                ref rng,
                RangeRandomization.Uniform,
                authoring.cloneSpacingMin,
                authoring.cloneSpacingMax);

            float3 spacingTotal = spacingObjSize + spacingGaps;

            float3 worldOffsets = spacingTotal * ((cubeSize - 1) * 0.5f);

            long added = 0;

            for (int x = 0; x < cubeSize && added < cloneCount; x++)
            {
                for (int y = 0; y < cubeSize && added < cloneCount; y++)
                {
                    for (int z = 0; z < cubeSize && added < cloneCount; z++)
                    {
                        float3 posOffset = new float3(x, y, z) * spacingTotal - worldOffsets;

                        float3 velLinear = computeCloneLinearVelocityOffset(authoring, ref rng);
                        float3 velAngular = computeCloneAngularVelocityOffset(authoring, ref rng);

                        cloneBuffer.Add(new InitializationCloneOffsets
                        {
                            Position = posOffset,
                            VelocityLinear = velLinear,
                            VelocityAngular = velAngular
                        });

                        added++;
                    }
                }
            }
            return rng;
        }

        private float3 computeCloneLinearVelocityOffset(
            VoxelVolumePrebakedAssetAuthoring authoring,
            ref Unity.Mathematics.Random rng)
        {
            float3 velocity = float3.zero;

            switch (authoring.cloneInitialVelocityLinearOffsetType)
            {
                case VariableValueType.None:
                    return float3.zero;

                case VariableValueType.Random:
                    velocity = rng.NextFloat3Direction();
                    break;

                case VariableValueType.Constant:
                    velocity = authoring.cloneInitialVelocityLinearOffsetBasis;
                    break;

                case VariableValueType.Range:
                    velocity = RangeRandomizer.RandomDirectionSpread(
                        ref rng,
                        authoring.cloneInitialVelocityLinearOffsetBasis,
                        authoring.cloneInitialVelocityLinearOffsetRandomization,
                        authoring.cloneInitialVelocityLinearOffsetMinSpread,
                        authoring.cloneInitialVelocityLinearOffsetMaxSpread);
                    break;
            }

            if (authoring.cloneInitialVelocityLinearOffsetSpace == CoordSpace.Local)
            {
                velocity = math.rotate(authoring.transform.rotation, velocity);
            }

            return velocity;
        }

        private float3 computeCloneAngularVelocityOffset(
            VoxelVolumePrebakedAssetAuthoring authoring,
            ref Unity.Mathematics.Random rng)
        {
            float3 velocity = float3.zero;

            switch (authoring.cloneInitialVelocityAngularOffsetType)
            {
                case VariableValueType.None:
                    return float3.zero;

                case VariableValueType.Random:
                    velocity = rng.NextFloat3Direction();
                    break;

                case VariableValueType.Constant:
                    velocity = authoring.cloneInitialVelocityAngularOffsetMin;
                    break;

                case VariableValueType.Range:
                    velocity = RangeRandomizer.RandomFloat3(
                        ref rng,
                        authoring.cloneInitialVelocityAngularOffsetRandomization,
                        authoring.cloneInitialVelocityAngularOffsetMin,
                        authoring.cloneInitialVelocityAngularOffsetMax);
                    break;
            }

            if (authoring.cloneInitialVelocityAngularOffsetSpace == CoordSpace.Local)
            {
                velocity = math.rotate(authoring.transform.rotation, velocity);
            }

            return velocity;
        }
    }
}