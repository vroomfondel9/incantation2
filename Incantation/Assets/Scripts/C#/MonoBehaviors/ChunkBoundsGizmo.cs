using Unity.Mathematics;
using UnityEngine;
[ExecuteAlways]
public class ChunkBoundsGizmo : MonoBehaviour
{
    // Color of the gizmo
    public Color boundaryColor = Color.blue;

    private void OnDrawGizmos()
    {
        if (GlobalConstants.BROADPHASE_GRID_SIZE.Equals(float3.zero))
            return;

        Gizmos.color = boundaryColor;

        // Center at origin
        Vector3 center = Vector3.zero;

        // Convert float3 to Vector3 for Gizmos
        Vector3 size = new Vector3(
            GlobalConstants.BROADPHASE_GRID_SIZE.x,
            GlobalConstants.BROADPHASE_GRID_SIZE.y,
            GlobalConstants.BROADPHASE_GRID_SIZE.z
        );

        // Draw wireframe cube
        Gizmos.DrawWireCube(center, size);
    }
}