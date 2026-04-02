using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Debug;
using Incantation.Engine.Voxels.Utils.Debug;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Rendering;
using Unity.Transforms;
using UnityEditor;
using UnityEngine;

#if DEBUG_DRAW_NARROWPHASE
namespace Incantation.Engine.Voxels.Systems.Debug
{
    [UpdateInGroup(typeof(PresentationSystemGroup))]
    public partial struct DebugVisualizeNarrowphaseCollisionShapesSystem : ISystem
    {
        public void OnUpdate(ref SystemState state)
        {
            if (DebugSwitches.DRAW_NARROWPHASE)
            {
                foreach (var (ltw, localAABBBounds, worldAABBBounds, entity) in
                    SystemAPI.Query<
                        RefRO<LocalToWorld>,
                        RefRO<RenderBounds>,
                        RefRO<WorldRenderBounds>>()
                    .WithAll<IsVoxelVolume>()
                    .WithAny<
                        DebugCollNearSphereHit,
                        DebugCollNearAABBHit,
                        DebugCollNearOBBHit>()
                    .WithEntityAccess())
                {
                    AABB localAABB = localAABBBounds.ValueRO.Value;
                    float3 localAABBMin = localAABB.Min;
                    float3 localAABBMax = localAABB.Max;

                    AABB worldAABB = worldAABBBounds.ValueRO.Value;
                    float3 worldAABBMin = worldAABB.Min;
                    float3 worldAABBMax = worldAABB.Max;

                    bool hasSphereComponentOn = SystemAPI.HasComponent<DebugCollNearSphereHit>(entity)
                        && SystemAPI.IsComponentEnabled<DebugCollNearSphereHit>(entity);
                    bool hasAABBComponentOn = SystemAPI.HasComponent<DebugCollNearAABBHit>(entity)
                        && SystemAPI.IsComponentEnabled<DebugCollNearAABBHit>(entity);
                    bool hasOBBComponentOn = SystemAPI.HasComponent<DebugCollNearOBBHit>(entity)
                        && SystemAPI.IsComponentEnabled<DebugCollNearOBBHit>(entity);

                    bool drawSphere = hasSphereComponentOn && !hasAABBComponentOn && !hasOBBComponentOn;
                    bool drawAABB = hasAABBComponentOn && !hasOBBComponentOn;
                    bool drawOOB = hasOBBComponentOn;

                    Color color = new Color(0.25f, 0.75f, 0.25f, 0.5f);

                    if (drawSphere)
                    {
                        DebugShapeVizualizationUtil.DrawWireSphere(worldAABB.Center, math.length(worldAABB.Extents), color);
                    }

                    if (drawAABB)
                    {
                        DebugShapeVizualizationUtil.DrawBox(worldAABBMin, worldAABBMax, color);
                    }

                    if (drawOOB)
                    {
                        DebugShapeVizualizationUtil.DrawBox(localAABBMin, localAABBMax, color, ltw.ValueRO.Value);
                    }
                }
            }
        }
    }
}
#endif