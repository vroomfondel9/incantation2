const uint numEntries;

// Multipurpose buffers used for sort.
// 1: Initialized to keys to sort. After sort and element reindexing, remains keys.
// 2: Initialized to indices ride with sort. After sort and element reindexing, used as offset.
// 3: Corresponds to spacialPart1 for sort algorithms that need double buffering. Unused for sort-in-place.
// 4: Corresponds to spacialPart2 for sort algorithms that need double buffering. Unused for sort-in-place.
RWStructuredBuffer<uint> spacialPart1;
RWStructuredBuffer<uint> spacialPart2;
RWStructuredBuffer<uint> spacialPart3;
RWStructuredBuffer<uint> spacialPart4;