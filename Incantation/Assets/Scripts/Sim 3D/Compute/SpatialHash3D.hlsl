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

// Constants used for hashing
static const uint hashK1 = 15823;
static const uint hashK2 = 9737333;
static const uint hashK3 = 440817757;

// Convert floating point position into an unsigned grid cell coordinate
uint3 GetCell3D(float3 position, float radius, uint3 boundsSize)
{
	float3 halfBoundsSizeWorldCoord = (boundsSize / 2.0f) * radius;
	float3 offsetPosition = position + halfBoundsSizeWorldCoord;
	return (uint3)floor(offsetPosition / radius);
}

uint BoundedKeyCell3D(uint3 cell, uint3 boundsSize)
{
	uint key = (boundsSize.x * boundsSize.y * cell.z) + (boundsSize.x * cell.y) + cell.x;
	return key;
}

// Convert floating point position into an integer cell coordinate
int3 UnboundedGetCell3D(float3 position, float radius)
{
	return (int3)floor(position / radius);
}

// Hash cell coordinate to a single unsigned integer
uint UnboundedHashCell3D(int3 cell)
{
	cell = (uint3) cell;
	return (cell.x * hashK1) + (cell.y * hashK2) + (cell.z * hashK3);
}

uint UnboundedKeyFromHash(uint hash, uint tableSize)
{
	return hash % tableSize;
}
