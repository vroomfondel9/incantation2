using Incantation.Engine.Voxels.Components;
using Incantation.Engine.Voxels.Components.Debug;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Rendering;
using Unity.Transforms;
using UnityEditor;
using UnityEngine;

namespace Incantation.Engine.Voxels.Systems.Debug
{

    [UpdateInGroup(typeof(PresentationSystemGroup))]
    public partial struct DebugVisualizeCollisionsSystem : ISystem
    {
        public void OnCreate(ref SystemState state)
        {
            state.Enabled = DebugConstants.ENABLE_NARROWPHASE_DRAW_SPHERES ||
                DebugConstants.ENABLE_NARROWPHASE_DRAW_AABBS ||
                    DebugConstants.ENABLE_NARROWPHASE_DRAW_OBBS;
        }

        public void OnUpdate(ref SystemState state)
        {
            if (DebugConstants.ENABLE_NARROWPHASE_DRAW_SPHERES ||
                DebugConstants.ENABLE_NARROWPHASE_DRAW_AABBS ||
                    DebugConstants.ENABLE_NARROWPHASE_DRAW_OBBS)
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

                    drawSphere &= DebugConstants.ENABLE_NARROWPHASE_DRAW_SPHERES;
                    drawAABB &= DebugConstants.ENABLE_NARROWPHASE_DRAW_AABBS;
                    drawOOB &= DebugConstants.ENABLE_NARROWPHASE_DRAW_OBBS;

                    Color color = new Color(0.75f, 0.75f, 0.75f, 0.75f);

                    if (drawSphere)
                    {
                        DrawWireSphere(worldAABB.Center, math.length(worldAABB.Extents), color);
                    }

                    if (drawAABB)
                    {
                        DrawBox(worldAABBMin, worldAABBMax, color, float4x4.identity);
                    }

                    if (drawOOB)
                    {
                        DrawBox(localAABBMin, localAABBMax, color, ltw.ValueRO.Value);
                    }
                }
            }
        }

        public static void DrawWireSphere(Vector3 center, float radius, Color color, float duration = 0f, int segments = 24)
        {
            DrawCircle(center, Vector3.right, Vector3.up, radius, color, duration, segments);   // XY
            DrawCircle(center, Vector3.right, Vector3.forward, radius, color, duration, segments); // XZ
            DrawCircle(center, Vector3.up, Vector3.forward, radius, color, duration, segments);    // YZ
        }

        private static void DrawCircle(
            Vector3 center,
            Vector3 axisA,
            Vector3 axisB,
            float radius,
            Color color,
            float duration,
            int segments)
        {
            float step = Mathf.PI * 2f / segments;

            Vector3 prev = center + axisA * radius;

            for (int i = 1; i <= segments; i++)
            {
                float angle = i * step;
                Vector3 next = center + (axisA * Mathf.Cos(angle) + axisB * Mathf.Sin(angle)) * radius;
                UnityEngine.Debug.DrawLine(prev, next, color, duration);
                prev = next;
            }
        }

        private void DrawBox(float3 min, float3 max, Color color, float4x4 transform)
        {
            float3 p0 = math.transform(transform, new float3(min.x, min.y, min.z));
            float3 p1 = math.transform(transform, new float3(max.x, min.y, min.z));
            float3 p2 = math.transform(transform, new float3(max.x, max.y, min.z));
            float3 p3 = math.transform(transform, new float3(min.x, max.y, min.z));

            float3 p4 = math.transform(transform, new float3(min.x, min.y, max.z));
            float3 p5 = math.transform(transform, new float3(max.x, min.y, max.z));
            float3 p6 = math.transform(transform, new float3(max.x, max.y, max.z));
            float3 p7 = math.transform(transform, new float3(min.x, max.y, max.z));

            UnityEngine.Debug.DrawLine(p0, p1, color);
            UnityEngine.Debug.DrawLine(p1, p2, color);
            UnityEngine.Debug.DrawLine(p2, p3, color);
            UnityEngine.Debug.DrawLine(p3, p0, color);

            UnityEngine.Debug.DrawLine(p4, p5, color);
            UnityEngine.Debug.DrawLine(p5, p6, color);
            UnityEngine.Debug.DrawLine(p6, p7, color);
            UnityEngine.Debug.DrawLine(p7, p4, color);

            UnityEngine.Debug.DrawLine(p0, p4, color);
            UnityEngine.Debug.DrawLine(p1, p5, color);
            UnityEngine.Debug.DrawLine(p2, p6, color);
            UnityEngine.Debug.DrawLine(p3, p7, color);
        }
    }
}