static const int3 offsets3D[27] =
{
	int3(-1, -1, -1),
	int3(0, -1, -1),
	int3(1, -1, -1),
	int3(-1, 0, -1),
	int3(0, 0, -1),
	int3(1, 0, -1),
	int3(-1, 1, -1),
	int3(0, 1, -1),
	int3(1, 1, -1),
	int3(-1, -1, 0),
	int3(0, -1, 0),
	int3(1, -1, 0),
	int3(-1, 0, 0),
	int3(1, 0, 0),
	int3(-1, 1, 0),
	int3(0, 1, 0),
	int3(1, 1, 0),
	int3(-1, -1, 1),
	int3(0, -1, 1),
	int3(1, -1, 1),
	int3(-1, 0, 1),
	int3(0, 0, 1),
	int3(1, 0, 1),
	int3(-1, 1, 1),
	int3(0, 1, 1),
	int3(1, 1, 1),
	//Origin is last element because some functionality only cares about adjascent cells and loops 1-26, and others care about
	//origin of this cell too and loops 1-27.
	int3(0, 0, 0),
};

//Checks if the given cell is in-bounds to the grid or not.
bool isCellInBounds(int3 cell, int3 boundsSize)
{
	return (cell.x >= 0) && (cell.x < boundsSize.x) &&
		(cell.y >= 0) && (cell.y < boundsSize.y) &&
		(cell.z >= 0) && (cell.z < boundsSize.z);
}

// Convert floating point position into an unsigned grid cell coordinate
// Clamps out-of-bounds positions to within the grid.
// Assumes the world boundaries are at position and rotation (0, 0, 0). This will break if this is false.
// TODO compare more sophisticated matrix-based approach.
uint3 GetInBoundsCell(float3 position, float radius, uint3 boundsSize)
{
	float3 halfBoundsSizeWorldCoord = 0.5f * boundsSize * radius;
	float3 offsetPosition = position + halfBoundsSizeWorldCoord;
	float3 unclampedCell = floor(offsetPosition / radius);
	float3 clampedCell = clamp(unclampedCell, 0, boundsSize - 1);
	return (uint3)clampedCell;
}

//Requires an in-bounds cell grid or will return values outside the range [0, (numCells - 1)].
uint GetKeyFromInBoundsCell(uint3 cell, uint3 boundsSize)
{
	return (boundsSize.x * boundsSize.y * cell.z) 
		+ (boundsSize.x * cell.y) 
		+ cell.x;
}
