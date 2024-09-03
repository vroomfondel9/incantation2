const uint numEntries;

// Multipurpose buffers used for sort.
// 1.x: Initialized to keys to sort. After sort and element reindexing, remains keys.
// 1.y: Initialized to indices ride with sort. After sort and element reindexing, used as offset.
// 2: Corresponds to spacialPart1 for sort algorithms that need double buffering. Unused for sort-in-place.
RWStructuredBuffer<uint2> spacialPart1;
RWStructuredBuffer<uint2> spacialPart2;