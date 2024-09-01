#define BUCKET_NUM 4 // Size of the uint array

// Includes
#include "./GPUSortCommon.hlsl"

struct BucketStruct
{
    uint buckets[BUCKET_NUM];
};

RWStructuredBuffer<BucketStruct> SrcBuckets; // Define the RWStructuredBuffer
RWStructuredBuffer<BucketStruct> DstBuckets; // Define the RWStructuredBuffer
RWStructuredBuffer<Entry> ScatterEntries; // Define the RWStructuredBuffer

//k aka digit places aka place values. From 0 to ciel(log32(num particles)) - 1. 32^curPlaceValue gives current multiple.
const int curPlaceValue;

uint getDigitForPlaceValueFromKey(uint key)
{
	//Cut off the irrelevant part to the right and normalize to least significant 5 bits (for 32 buckets)
	uint numBits = log2(BUCKET_NUM);
	uint digitForPlaceValue = key >> 5 * curPlaceValue;	
	//Cut off the irrelevant part to the left and select only the first 5 bits (for 32 buckets) we're interest in
	//This will now be a number 0 to (BUCKET_NUM-1)
	digitForPlaceValue &= (BUCKET_NUM - 1);

	return digitForPlaceValue;
}

BucketStruct CalculateInitBucketsWithPredicate(uint3 id)
{
	uint i = id.x;

	BucketStruct buckStruct;
	uint key = Entries[i].key;
	uint digitForPlaceValue = getDigitForPlaceValueFromKey(key);

	// Loop through all buckets and reinit to 0
	for (uint j = 0; j < BUCKET_NUM; j++)
	{
		buckStruct.buckets[j] = (digitForPlaceValue == j);
	}

	return buckStruct;
}

// Assumes SrcBuckets is Inclusive Sum and DstBuckets is Exclusive Sum
// For digit d at particle index i, new index = (Sum from j=0 to d-1 of InclusiveSum[j][numParticles - 1]) + ExclusiveSum[d][i].
// (Sum from j=0 to d-1 of InclusiveSum[j][numParticles - 1]): Represents the number of digits less than digit d.
// ExclusiveSum[d][i]: Represents the number of digits equal to d but with index values less than i.
void CalculateIndexAndScatter(uint3 id)
{
	Entry entryToMove = Entries[id.x];
	uint thisDigit = getDigitForPlaceValueFromKey(entryToMove.key);
	BucketStruct inclusiveSumAllDigits = SrcBuckets[numEntries - 1];
	BucketStruct exclusiveSumThisDigit = DstBuckets[id.x];

	uint numDigitsLessThanThisDigit = 0;

	for (uint curDigit = 0; curDigit < thisDigit; curDigit++)
	{
		numDigitsLessThanThisDigit = inclusiveSumAllDigits.buckets[curDigit];
	}

	uint numSameDigitBeforeThisInBuffer = exclusiveSumThisDigit.buckets[thisDigit];

	uint newIndex = numDigitsLessThanThisDigit + numSameDigitBeforeThisInBuffer;

	ScatterEntries[newIndex] = entryToMove;
}

void CopyFromScatter(uint3 id)
{
	Entries[id.x] = ScatterEntries[id.x];
}
