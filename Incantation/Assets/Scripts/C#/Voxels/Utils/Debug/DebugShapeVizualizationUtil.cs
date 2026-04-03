using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

namespace Incantation.Engine.Voxels.Utils.Debug
{
    public class DebugShapeVizualizationUtil
    {
        private DebugShapeVizualizationUtil() { }

        public static void DrawWireSphere(Vector3 center, float radius, Color color, float duration = 0f, int segments = 24)
        {
            DrawCircle(center, Vector3.right, Vector3.up, radius, color, duration, segments);   // XY
            DrawCircle(center, Vector3.right, Vector3.forward, radius, color, duration, segments); // XZ
            DrawCircle(center, Vector3.up, Vector3.forward, radius, color, duration, segments);    // YZ
        }

        public static void DrawCircle(
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

        public static void DrawBox(float3 min, float3 max, Color color, float duration = 0.0f, bool depthTest = true)
        {
            DrawBox(min, max, color, float4x4.identity, duration, depthTest);
        }

        public static void DrawBox(float3 min, float3 max, Color color, float4x4 transform, float duration = 0.0f, bool depthTest = true)
        {
            float3 p0 = math.transform(transform, new float3(min.x, min.y, min.z));
            float3 p1 = math.transform(transform, new float3(max.x, min.y, min.z));
            float3 p2 = math.transform(transform, new float3(max.x, max.y, min.z));
            float3 p3 = math.transform(transform, new float3(min.x, max.y, min.z));

            float3 p4 = math.transform(transform, new float3(min.x, min.y, max.z));
            float3 p5 = math.transform(transform, new float3(max.x, min.y, max.z));
            float3 p6 = math.transform(transform, new float3(max.x, max.y, max.z));
            float3 p7 = math.transform(transform, new float3(min.x, max.y, max.z));

            UnityEngine.Debug.DrawLine(p0, p1, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p2, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p3, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p3, p0, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p4, p5, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p5, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p6, p7, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p7, p4, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p0, p4, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p5, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p3, p7, color, duration, depthTest);
        }

        public static void DrawBox(float3 min, float3 max, Color color, RigidTransform transform, float duration = 0.0f, bool depthTest = true)
        {
            float3 p0 = math.transform(transform, new float3(min.x, min.y, min.z));
            float3 p1 = math.transform(transform, new float3(max.x, min.y, min.z));
            float3 p2 = math.transform(transform, new float3(max.x, max.y, min.z));
            float3 p3 = math.transform(transform, new float3(min.x, max.y, min.z));

            float3 p4 = math.transform(transform, new float3(min.x, min.y, max.z));
            float3 p5 = math.transform(transform, new float3(max.x, min.y, max.z));
            float3 p6 = math.transform(transform, new float3(max.x, max.y, max.z));
            float3 p7 = math.transform(transform, new float3(min.x, max.y, max.z));

            UnityEngine.Debug.DrawLine(p0, p1, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p2, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p3, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p3, p0, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p4, p5, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p5, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p6, p7, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p7, p4, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p0, p4, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p5, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p3, p7, color, duration, depthTest);
        }

        public static void DrawBoxWithXFaces(float3 min, float3 max, Color color, float duration = 0.0f, bool depthTest = true)
        {
            DrawBoxWithXFaces(min, max, color, float4x4.identity, duration, depthTest);
        }

        public static void DrawBoxWithXFaces(float3 min, float3 max, Color color, float4x4 transform, float duration = 0.0f, bool depthTest = true)
        {
            float3 p0 = math.transform(transform, new float3(min.x, min.y, min.z));
            float3 p1 = math.transform(transform, new float3(max.x, min.y, min.z));
            float3 p2 = math.transform(transform, new float3(max.x, max.y, min.z));
            float3 p3 = math.transform(transform, new float3(min.x, max.y, min.z));

            float3 p4 = math.transform(transform, new float3(min.x, min.y, max.z));
            float3 p5 = math.transform(transform, new float3(max.x, min.y, max.z));
            float3 p6 = math.transform(transform, new float3(max.x, max.y, max.z));
            float3 p7 = math.transform(transform, new float3(min.x, max.y, max.z));

            // Box edges
            UnityEngine.Debug.DrawLine(p0, p1, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p2, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p3, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p3, p0, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p4, p5, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p5, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p6, p7, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p7, p4, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p0, p4, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p5, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p3, p7, color, duration, depthTest);

            // Face Xs
            UnityEngine.Debug.DrawLine(p0, p2, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p3, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p4, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p5, p7, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p0, p7, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p3, p4, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p1, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p5, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p0, p5, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p4, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p3, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p7, color, duration, depthTest);
        }

        public static void DrawBoxWithXFaces(float3 min, float3 max, Color color, RigidTransform transform, float duration = 0.0f, bool depthTest = true)
        {
            float3 p0 = math.transform(transform, new float3(min.x, min.y, min.z));
            float3 p1 = math.transform(transform, new float3(max.x, min.y, min.z));
            float3 p2 = math.transform(transform, new float3(max.x, max.y, min.z));
            float3 p3 = math.transform(transform, new float3(min.x, max.y, min.z));

            float3 p4 = math.transform(transform, new float3(min.x, min.y, max.z));
            float3 p5 = math.transform(transform, new float3(max.x, min.y, max.z));
            float3 p6 = math.transform(transform, new float3(max.x, max.y, max.z));
            float3 p7 = math.transform(transform, new float3(min.x, max.y, max.z));

            // Box edges
            UnityEngine.Debug.DrawLine(p0, p1, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p2, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p3, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p3, p0, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p4, p5, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p5, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p6, p7, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p7, p4, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p0, p4, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p5, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p3, p7, color, duration, depthTest);

            // Face Xs
            UnityEngine.Debug.DrawLine(p0, p2, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p3, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p4, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p5, p7, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p0, p7, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p3, p4, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p1, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p5, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p0, p5, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p1, p4, color, duration, depthTest);

            UnityEngine.Debug.DrawLine(p3, p6, color, duration, depthTest);
            UnityEngine.Debug.DrawLine(p2, p7, color, duration, depthTest);
        }
    }
}
