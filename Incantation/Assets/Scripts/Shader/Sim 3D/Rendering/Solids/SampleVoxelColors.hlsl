#ifndef SAMPLE_TEXTURE3D_RGB_INCLUDED
#define SAMPLE_TEXTURE3D_RGB_INCLUDED

void ColorSample_float(
    UnityTexture3D ColorTexture,
	float3 GridDimensions,
	float VoxelVolumeOffset,
	float3 UV,
	float3 Voxel,
	out float3 RGB
)
{
	RGB = float3(0, 0, 0);
	
	#ifdef _EDITOR_MODE
		float4 sample = SAMPLE_TEXTURE3D(
			ColorTexture.tex,
			ColorTexture.samplerstate,
			UV
		);
		RGB = sample.rgb;
	#else
		uint globalIndex = ((uint)VoxelVolumeOffset) + Voxel.x + GridDimensions.x * Voxel.y + GridDimensions.x * GridDimensions.y * Voxel.z;
		uint packedValue = _Voxels[globalIndex];
		
		uint r = (packedValue >> 24) & 0xFF;
		uint g = (packedValue >> 16) & 0xFF;
		uint b = (packedValue >> 8) & 0xFF;
		
		RGB = float3(r / 255.0, g / 255.0, b / 255.0);
	#endif
}


#endif