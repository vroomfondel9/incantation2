static const int3 offsets3D[27] =
{
	// Origin first for functionality that only cares about the origin or wants to skip the origin
	int3(0, 0, 0),

	// Next, the rest of the YZ slice centered at the origin
	int3(0, -1, -1),
	int3(0, 0, -1),
	int3(0, 1, -1),
	int3(0, -1, 0),
	int3(0, 1, 0),
	int3(0, -1, 1),
	int3(0, 0, 1),
	int3(0, 1, 1),

	// Next, the previous YZ slice for (x-1)
	int3(-1, -1, -1),
	int3(-1, 0, -1),
	int3(-1, 1, -1),
	int3(-1, -1, 0),
	int3(-1, 0, 0),
	int3(-1, 1, 0),
	int3(-1, -1, 1),
	int3(-1, 0, 1),
	int3(-1, 1, 1),

	// Finally, the last YZ slice for (x+1)
	int3(1, -1, -1),
	int3(1, 0, -1),
	int3(1, 1, -1),
	int3(1, -1, 0),
	int3(1, 0, 0),
	int3(1, 1, 0),
	int3(1, -1, 1),
	int3(1, 0, 1),
	int3(1, 1, 1),
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

uint3 GetCellFromInBoundsKey(uint key, uint3 boundsSize)
{
	uint zDiv = boundsSize.x * boundsSize.y;
	uint yDiv = boundsSize.x;

	uint z = key / zDiv;
	key -= z * zDiv;
	uint y = key / yDiv;
	uint x = key - y * yDiv;

	return uint3(x, y, z);
}
