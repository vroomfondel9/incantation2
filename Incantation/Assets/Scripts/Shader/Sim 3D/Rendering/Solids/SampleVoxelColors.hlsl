#ifndef SAMPLE_TEXTURE3D_RGB_INCLUDED
#define SAMPLE_TEXTURE3D_RGB_INCLUDED

void ColorSample_float(
    UnityTexture3D ColorTexture,
	float3 GridDimensions,
	float VoxelVolumeOffset,
	float DebugVisualizationMode,
	float3 EntryPointObj,
	float3 Hit,
	float3 UV,
	float3 Voxel,
	float VoxelValue1,
	float VoxelValue2,
	float3 NormalsObj,
	float RaymarchIterations,
	float RaymarchSamples,
	float Depth,
	out float3 RGB,
	out float Alpha,
	out float Dpth,
	out float3 NormsObj
)
{
	RGB = float3(0, 0, 0);
	Alpha = Hit;
	Dpth = Depth;
	NormsObj = NormalsObj;
	
	//Hack needed to bypass loss of floating point precision by splitting it into two non-lossy floats to avoid resampling a value I already got from memory
	uint voxelValue = (((uint) VoxelValue1) << 16) | (((uint) VoxelValue2));
	
	// Base color (sampled even in debug visualization mode to maintain same performance characteristics)
	#ifdef _EDITOR_MODE
		float4 sample = SAMPLE_TEXTURE3D(
			ColorTexture.tex,
			ColorTexture.samplerstate,
			UV
		);
		RGB = sample.rgb;
	#else
		uint r = (voxelValue >> 24) & 0xFF;
		uint g = (voxelValue >> 16) & 0xFF;
		uint b = (voxelValue >> 8) & 0xFF;
		
		RGB = float3(r / 255.0, g / 255.0, b / 255.0);
	#endif
	
	// Overwrite base color if in debug mode
	if (DebugVisualizationMode > 0)
	{
		//Voxel Volume Bounding Boxes
		if (DebugVisualizationMode == 1)
		{
			float borderWidth = 0.02;
			
			float maxDim = max(GridDimensions.x, max(GridDimensions.y, GridDimensions.z));
			float3 objectScale = float3(GridDimensions.x / maxDim, GridDimensions.y / maxDim, GridDimensions.z / maxDim);
			float3 borderWidthObj = borderWidth / objectScale;
			
			float3 entryUVOnBorder = (abs(EntryPointObj) > (0.5 - borderWidthObj));
			uint numDimsNearBorder = entryUVOnBorder.x + entryUVOnBorder.y + entryUVOnBorder.z;
			if (numDimsNearBorder >= 2)
			{
				float EPSILON = 1e-5;
			
				//Recompute normals for border only
				int3 faceMask = int3(
					abs(abs(EntryPointObj.x) - 0.5) < EPSILON ? 1 : 0,
					abs(abs(EntryPointObj.y) - 0.5) < EPSILON ? 1 : 0,
					abs(abs(EntryPointObj.z) - 0.5) < EPSILON ? 1 : 0
				);
				
				int3 entryDir = int3(
					EntryPointObj.x > 0 ? 1 : -1,
					EntryPointObj.y > 0 ? 1 : -1,
					EntryPointObj.z > 0 ? 1 : -1
				);
				
				NormsObj = (faceMask * entryDir) * 0.5 + NormalsObj * 0.5;
			
				float grayscale = dot(RGB, float3(0.2126, 0.7152, 0.0722));
				RGB = grayscale;
				
				if (Alpha < 0.5)
				{
					Alpha = 1;
					RGB = float3(1, 1, 1);
				}
			}
		}
		//Normals (World Space)
		if (DebugVisualizationMode == 2)
		{
			float3 normalWS = TransformObjectToWorldNormal(NormalsObj);
			RGB = (normalWS / 2.0) + 0.5;
		}
		//Depth (Raw, non-linear 0-1 value based on distance to near/far plane)
		//Editor's camera has stupidly large far plane, so hacked in something to make the different values more noticible
		else if (DebugVisualizationMode == 3)
		{
			RGB = float3(Depth, Depth, Depth);
			#ifdef _EDITOR_MODE
				RGB = RGB * 50.0;
			#endif
		}
		//Voxel Topology (Corners = Red, Edges = Green, Faces = Blue, Unclassified/Interior = Black)
		else if (DebugVisualizationMode == 4)
		{
			uint topologyMask = voxelValue & 0xFF;
			topologyMask = (uint) max((((int)topologyMask) - 63) * -1, 0);
			
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
		//Ray march iterations
		else if (DebugVisualizationMode == 5)
		{
			if (Alpha == 0.0)
				Alpha = 0.5;
				
			float t = RaymarchIterations / 100.0;

			float3 col;
			if (t < 0.5)
				col = lerp(float3(0,0,1), float3(0,1,0), t*2);   // blue→green
			else
				col = lerp(float3(0,1,0), float3(1,0,0), (t-0.5)*2); // green→red

			RGB = col;
		}
		//Ray march samples
		else if (DebugVisualizationMode == 6)
		{
			if (Alpha == 0.0)
				Alpha = 0.5;
				
			float t = RaymarchSamples / 100.0;

			float3 col;
			if (t < 0.5)
				col = lerp(float3(0,0,1), float3(0,1,0), t*2);   // blue→green
			else
				col = lerp(float3(0,1,0), float3(1,0,0), (t-0.5)*2); // green→red

			RGB = col;
		}
	}
}


#endif