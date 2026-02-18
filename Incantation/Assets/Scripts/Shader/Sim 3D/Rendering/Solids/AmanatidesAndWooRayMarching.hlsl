#ifndef VOXEL_DDA_INCLUDED
#define VOXEL_DDA_INCLUDED

// Small epsilon to avoid precision issues
static const float EPSILON = 1e-5;

// Volume bounds in object space
static const float3 VOLUME_MIN = float3(-0.5, -0.5, -0.5);
static const float3 VOLUME_MAX = float3( 0.5,  0.5,  0.5);

void VoxelDDA_float(
    UnityTexture3D Texture,
    float3 EntryPointObj,
    float3 RayDirObj,
    float3 GridResolutionObj,
    out float Hit,
    out float3 UV
)
{
    Hit = false;
    UV = float3(0,0,0);

    float3 rayDir = RayDirObj;
    float3 pos = EntryPointObj;

    // Ensure ray direction is normalized
    rayDir = normalize(rayDir);

    // If ray starts slightly outside, push inward
    pos += rayDir * EPSILON;

    // Convert object position to voxel grid coordinates
    float3 gridPos = (pos - VOLUME_MIN) / GridResolutionObj;

    int3 voxel = int3(floor(gridPos));

    // Compute step direction
    int3 stepDir = int3(
        rayDir.x > 0 ? 1 : -1,
        rayDir.y > 0 ? 1 : -1,
        rayDir.z > 0 ? 1 : -1
    );

    // Precompute tDelta (distance to cross one voxel)
    float3 tDelta = abs(GridResolutionObj / rayDir);

    // Compute next voxel boundary
    float3 voxelBoundary = (voxel + (stepDir > 0 ? 1 : 0)) * GridResolutionObj + VOLUME_MIN;

    float3 tMax = (voxelBoundary - pos) / rayDir;

    // Handle rays parallel to axis
    if (abs(rayDir.x) < EPSILON)
	{
		tMax.x = 1e30;
		tDelta.x = 1e30;
	}
	if (abs(rayDir.y) < EPSILON)
	{
		tMax.y = 1e30;
		tDelta.y = 1e30;
	}
	if (abs(rayDir.z) < EPSILON)
	{
		tMax.z = 1e30;
		tDelta.z = 1e30;
	}

    // Maximum traversal steps safeguard
    const int MAX_STEPS = 512;

    [loop]
    for (int i = 0; i < MAX_STEPS; i++)
    {
        // Check bounds
        float3 voxelMin = VOLUME_MIN;
        float3 voxelMax = VOLUME_MAX;

        float3 worldPos = voxel * GridResolutionObj + VOLUME_MIN;

        if (worldPos.x < voxelMin.x || worldPos.y < voxelMin.y || worldPos.z < voxelMin.z ||
            worldPos.x >= voxelMax.x || worldPos.y >= voxelMax.y || worldPos.z >= voxelMax.z)
        {
            return; // exited volume
        }

        // Convert to UV space
        float3 uv = (worldPos + 0.5 * GridResolutionObj - VOLUME_MIN) / (VOLUME_MAX - VOLUME_MIN);

		float4 sample = SAMPLE_TEXTURE3D(Texture, Texture.samplerstate, uv);

        if (sample.a > 0.5) // occupancy threshold
        {
            Hit = true;
            UV = uv;
            return;
        }

        // Advance voxel
        if (tMax.x < tMax.y)
        {
            if (tMax.x < tMax.z)
            {
                voxel.x += stepDir.x;
                tMax.x += tDelta.x;
            }
            else
            {
                voxel.z += stepDir.z;
                tMax.z += tDelta.z;
            }
        }
        else
        {
            if (tMax.y < tMax.z)
            {
                voxel.y += stepDir.y;
                tMax.y += tDelta.y;
            }
            else
            {
                voxel.z += stepDir.z;
                tMax.z += tDelta.z;
            }
        }
    }
}

#endif