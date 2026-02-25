#ifndef VOXEL_DDA_INCLUDED
#define VOXEL_DDA_INCLUDED

#ifndef _EDITOR_MODE
	StructuredBuffer<uint> _Voxels;
#endif

static const float EPSILON = 1e-5;
static const float ENTRY_POINT_EPSILON = 5e-3;

static const float3 VOLUME_MIN = float3(-0.5, -0.5, -0.5);
static const float3 VOLUME_MAX = float3( 0.5,  0.5,  0.5);

void RayMarch_float(
    UnityTexture3D Texture,
    float3 EntryPointObj,
    float3 RayDirObj,
    float3 GridDimensions,
	float VoxelVolumeOffset,
    out float3 UV,
	out float3 Voxel,
    out float Hit,
    out float3 NormalsObj,
	out float3 VoxelSurfaceStrikeLocObj,
	out float VoxelValue
)
{
    Hit = 0.0;
    UV = float3(0,0,0);
	Voxel = float3(0, 0, 0);
    NormalsObj = float3(0,0,0);
	VoxelSurfaceStrikeLocObj = float3(0, 0, 0);
	VoxelValue = 1.0;
	
    float3 voxelSize = 1.0 / GridDimensions;
	float3 halfVoxelSize = voxelSize * 0.5;
	float halfSmallestDim = min(halfVoxelSize.x, min(halfVoxelSize.y, halfVoxelSize.z));

    float3 rayDir = normalize(RayDirObj);
    float3 pos = EntryPointObj + rayDir * halfSmallestDim * ENTRY_POINT_EPSILON;
	
	if ((pos.x > VOLUME_MAX.x) || (pos.x < VOLUME_MIN.x) ||
		(pos.y > VOLUME_MAX.y) || (pos.y < VOLUME_MIN.y) ||
		(pos.z > VOLUME_MAX.z) || (pos.z < VOLUME_MIN.z))
	{
		// Early exit for cases on the very edge of bounding box where tracing inside at all puts OOB
		return;
	}

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

	float tPrev = 0.0;
    float t = 0.0;

    const int MAX_STEPS = 512;
	uint value;

    [loop]
    for (int i = 0; i < MAX_STEPS; i++)
    {
		// Texture Sampling
		#ifdef _EDITOR_MODE
			float normalizedValue = LOAD_TEXTURE3D(Texture, voxel);
			value = (uint)round(normalizedValue * 255.0);
		#else
			uint indexInVolume = voxel.x + GridDimensions.x * voxel.y + GridDimensions.x * GridDimensions.y * voxel.z;
			uint globalIndex = ((uint)VoxelVolumeOffset) + indexInVolume;
			value = _Voxels[globalIndex];
			value = value & 0xFF;
		#endif

        if (value == 0)
        {
            Hit = 1.0;
			
			// Compute UV from voxel center for sampling
			float3 voxelCenter = (voxel + 0.5) * voxelSize;
			float3 uv = voxelCenter / (VOLUME_MAX - VOLUME_MIN);
            UV = uv;
			Voxel = voxel;
			VoxelValue = value;
			
			VoxelSurfaceStrikeLocObj = pos + rayDir * t;

            if (lastAxis == 0)
                NormalsObj = float3(-stepDir.x, 0, 0);
            else if (lastAxis == 1)
                NormalsObj = float3(0, -stepDir.y, 0);
            else if (lastAxis == 2)
                NormalsObj = float3(0, 0, -stepDir.z);

            return;
        }

        // Advance DDA using SDF acceleration structure
		for (int j = value; j > 0; j--)
		{
			tPrev = t;
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
			
			// Integer bounds check (stable)
			if (voxel.x < 0 || voxel.y < 0 || voxel.z < 0 ||
				voxel.x >= gridDims.x ||
				voxel.y >= gridDims.y ||
				voxel.z >= gridDims.z)
			{
				return;
			}
		}
    }
}

#endif
