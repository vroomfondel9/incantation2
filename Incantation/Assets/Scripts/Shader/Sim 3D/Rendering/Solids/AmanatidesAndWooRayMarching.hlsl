#ifndef VOXEL_DDA_INCLUDED
#define VOXEL_DDA_INCLUDED

static const float EPSILON = 1e-5;
static const float ENTRY_POINT_EPSILON = 5e-3;

static const float3 VOLUME_MIN = float3(-0.5, -0.5, -0.5);
static const float3 VOLUME_MAX = float3( 0.5,  0.5,  0.5);

void VoxelDDA_float(
    UnityTexture3D Texture,
    float3 EntryPointObj,
    float3 RayDirObj,
    float3 GridDimensions,
    out float Hit,
    out float3 UV,
    out float3 Normals
)
{
    Hit = 0.0;
    UV = float3(0,0,0);
    Normals = float3(0,0,0);
	
    float3 voxelSize = 1.0 / GridDimensions;
	float3 halfVoxelSize = voxelSize * 0.5;
	float halfSmallestDim = min(halfVoxelSize.x, min(halfVoxelSize.y, halfVoxelSize.z));

    float3 rayDir = normalize(RayDirObj);
    float3 pos = EntryPointObj + rayDir * halfSmallestDim * ENTRY_POINT_EPSILON;

    int3 gridDims = int3(GridDimensions);

    // Convert to voxel coordinates
    float3 gridPos = (pos - VOLUME_MIN) * gridDims;
    int3 voxel = int3(floor(gridPos));

    // Step direction
    int3 stepDir = int3(
        rayDir.x > 0 ? 1 : -1,
        rayDir.y > 0 ? 1 : -1,
        rayDir.z > 0 ? 1 : -1
    );

    // Distance to cross one voxel
    float3 tDelta = abs(voxelSize / rayDir);

    // Compute first boundary
    float3 nextBoundary = (voxel + (stepDir > 0 ? 1 : 0)) * voxelSize + VOLUME_MIN;
    float3 tMax = (nextBoundary - pos) / rayDir;

    // Parallel rays
    if (abs(rayDir.x) < EPSILON) { tMax.x = 1e30; tDelta.x = 1e30; }
    if (abs(rayDir.y) < EPSILON) { tMax.y = 1e30; tDelta.y = 1e30; }
    if (abs(rayDir.z) < EPSILON) { tMax.z = 1e30; tDelta.z = 1e30; }

    // Initial face detection (entry face)
    // Track last-crossed axis for normals
	int3 faceMask = int3(
		abs(abs(EntryPointObj.x) - VOLUME_MAX.x) < EPSILON ? 1 : 0,
		abs(abs(EntryPointObj.y) - VOLUME_MAX.y) < EPSILON ? 1 : 0,
		abs(abs(EntryPointObj.z) - VOLUME_MAX.z) < EPSILON ? 1 : 0
	);

	int3 weighted = faceMask * int3(1, 2, 3);

	int lastAxis = weighted.x + weighted.y + weighted.z - 1;

    float t = 0.0;

    const int MAX_STEPS = 512;

    [loop]
    for (int i = 0; i < MAX_STEPS; i++)
    {
        // Integer bounds check (stable)
        if (voxel.x < 0 || voxel.y < 0 || voxel.z < 0 ||
            voxel.x >= gridDims.x ||
            voxel.y >= gridDims.y ||
            voxel.z >= gridDims.z)
        {
            return;
        }

        // Compute UV from voxel center for sampling
        float3 voxelCenter = (voxel + 0.5) * voxelSize;
        float3 uv = voxelCenter / (VOLUME_MAX - VOLUME_MIN);

        float4 sample = SAMPLE_TEXTURE3D_LOD(Texture, Texture.samplerstate, uv, 0);

        if (sample.a > 0.5)
        {
            Hit = 1.0;
            UV = uv;

            if (lastAxis == 0)
                Normals = float3(-stepDir.x, 0, 0);
            else if (lastAxis == 1)
                Normals = float3(0, -stepDir.y, 0);
            else if (lastAxis == 2)
                Normals = float3(0, 0, -stepDir.z);

            return;
        }

        // Advance DDA
        if (tMax.x < tMax.y)
        {
            if (tMax.x < tMax.z)
            {
                t = tMax.x;
                voxel.x += stepDir.x;
                tMax.x += tDelta.x;
                lastAxis = 0;
            }
            else
            {
                t = tMax.z;
                voxel.z += stepDir.z;
                tMax.z += tDelta.z;
                lastAxis = 2;
            }
        }
        else
        {
            if (tMax.y < tMax.z)
            {
                t = tMax.y;
                voxel.y += stepDir.y;
                tMax.y += tDelta.y;
                lastAxis = 1;
            }
            else
            {
                t = tMax.z;
                voxel.z += stepDir.z;
                tMax.z += tDelta.z;
                lastAxis = 2;
            }
        }
    }
}

#endif
