#ifndef SAMPLE_TEXTURE3D_RGB_INCLUDED
#define SAMPLE_TEXTURE3D_RGB_INCLUDED

void ColorSample_float(
    UnityTexture3D ColorTexture,
	float3 GridDimensions,
	float VoxelVolumeOffset,
	float DebugVisualizationMode,
	float3 UV,
	float3 Voxel,
	float VoxelValue,
	float3 NormalsObj,
	float Depth,
	out float3 RGB
)
{
	RGB = float3(0, 0, 0);
	
	// Base color (sampled even in debug visualization mode to maintain same performance characteristics)
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
	
	// Overwrite base color if in debug mode
	if (DebugVisualizationMode > 0)
	{
		//Normals (World Space)
		if (DebugVisualizationMode == 1)
		{
			float3 normalWS = TransformObjectToWorldNormal(NormalsObj);
			RGB = (normalWS / 2.0) + 0.5;
		}
		//Depth (Raw, non-linear 0-1 value based on distance to near/far plane)
		//Editor's camera has stupidly large far plane, so hacked in something to make the different values more noticible
		else if (DebugVisualizationMode == 2)
		{
			RGB = float3(Depth, Depth, Depth);
			#ifdef _EDITOR_MODE
				RGB = RGB * 50.0;
			#endif
		}
		//Voxel Topology (Corners = Red, Edges = Green, Faces = Blue, Unclassified/Interior = White)
		else if (DebugVisualizationMode == 3)
		{
			//TODO
		}
	}
}


#endif