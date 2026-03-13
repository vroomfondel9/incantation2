using Incantation.Engine.Voxels.Components;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Rendering;
using Unity.Transforms;
using UnityEngine;

[UpdateInGroup(typeof(PresentationSystemGroup))]
public partial struct DrawAABBSystem : ISystem
{
    public void OnUpdate(ref SystemState state)
    {
        if (DebugConstants.DRAW_AABBS)
        {
            foreach (var bounds in
                SystemAPI.Query<RefRO<WorldRenderBounds>>()
                .WithAll<OriginalVoxelVolumeID>())
            {
                AABB aabb = bounds.ValueRO.Value;
                float3 min = aabb.Min;
                float3 max = aabb.Max;

                DrawAABB(min, max, Color.grey);
            }
        }
    }

    void DrawAABB(float3 min, float3 max, Color color)
    {
        float3 p0 = new(min.x, min.y, min.z);
        float3 p1 = new(max.x, min.y, min.z);
        float3 p2 = new(max.x, max.y, min.z);
        float3 p3 = new(min.x, max.y, min.z);

        float3 p4 = new(min.x, min.y, max.z);
        float3 p5 = new(max.x, min.y, max.z);
        float3 p6 = new(max.x, max.y, max.z);
        float3 p7 = new(min.x, max.y, max.z);

        Debug.DrawLine(p0, p1, color);
        Debug.DrawLine(p1, p2, color);
        Debug.DrawLine(p2, p3, color);
        Debug.DrawLine(p3, p0, color);

        Debug.DrawLine(p4, p5, color);
        Debug.DrawLine(p5, p6, color);
        Debug.DrawLine(p6, p7, color);
        Debug.DrawLine(p7, p4, color);

        Debug.DrawLine(p0, p4, color);
        Debug.DrawLine(p1, p5, color);
        Debug.DrawLine(p2, p6, color);
        Debug.DrawLine(p3, p7, color);
    }
}