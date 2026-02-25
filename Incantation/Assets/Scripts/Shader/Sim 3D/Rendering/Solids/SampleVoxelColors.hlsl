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
		//Voxel Topology (Corners = Red, Edges = Green, Faces = Blue, Unclassified/Interior = Black)
		else if (DebugVisualizationMode == 3)
		{
			uint topologyMask = (uint) VoxelValue;
			//Corner if:
			//	-Filled in both sides of exactly 0 axises. Other axises can either be empty on both sides or filled on only one, but not both.
			//	
			//Edge if:
			//	-Filled in both sides of exactly 1 axises. Other axises can either be empty on both sides or filled on only one, but not both.
			//	
			//Face if:
			//	-Filled in both sides of exactly 2 axises. Other axis can be either empty on both sides or filled on only one, but not both.
			//	
			//Interior if:
			//	-Filled in both sides of all 3 axises.
			uint bothFilledInZ = ((topologyMask & 3u) == 3u);
			uint bothFilledInY = ((topologyMask & 12u) == 12u);
			uint bothFilledInX = ((topologyMask & 48u) == 48u);
			
			uint numDimsFilledInBothDirs = bothFilledInZ + bothFilledInY + bothFilledInX;
			
			RGB = float3(numDimsFilledInBothDirs == 0, numDimsFilledInBothDirs == 1, numDimsFilledInBothDirs == 2);
		}
	}
}


#endif