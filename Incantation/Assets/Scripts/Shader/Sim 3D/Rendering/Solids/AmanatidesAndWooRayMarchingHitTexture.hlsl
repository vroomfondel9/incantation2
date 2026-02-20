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
	
	float normalizedValue = LOAD_TEXTURE3D(_HitTexture, voxel);
	uint value = (uint)round(normalizedValue * 255.0);
	Hit = min(value / 50.0, 1.0);
}

#endif
