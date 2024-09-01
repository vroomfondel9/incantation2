using UnityEngine;
using static UnityEngine.Mathf;

public class RadixHillisSteeleSort : RadixSort
{
    const int initPredicateKernel = 1;
    const int hillisSteeleStepKernel = 2;
    const int convertInclusiveScanToExclusiveKernel = 3;
    const int ScatterSpacialIndicesKernel = 4;
    const int CopyEntriesBufferBackKernel = 5;

    public RadixHillisSteeleSort() : base("RadixHillisSteeleSort") { }

    protected override void setBuffersInKernels()
    {
        ComputeHelper.SetBuffer(this.sortCompute, this.offsetBuffer, "Offsets", calculateOffsetsKernel);
        ComputeHelper.SetBuffer(this.sortCompute, this.indexBuffer, "Entries", initPredicateKernel, convertInclusiveScanToExclusiveKernel, ScatterSpacialIndicesKernel, CopyEntriesBufferBackKernel, calculateOffsetsKernel);
        ComputeHelper.SetBuffer(this.sortCompute, this.scatterEntriesBuffer, "ScatterEntries", ScatterSpacialIndicesKernel, CopyEntriesBufferBackKernel);
    }

    // Sorts given buffer of integer values using bitonic merge sort
    // Note: buffer size is not restricted to powers of 2 in this implementation
    protected override void Sort()
    {
        //Calculate maximum place value
        int maxNumberOfPlaceValues = (int)Mathf.Ceil(Log(indexBuffer.count, NUMBUCKETS));

        // Launch each step of the sorting algorithm (once the previous step is complete)
        // Number of steps = [log2(n) * (log2(n) + 1)] / 2
        // where n = nearest power of 2 that is greater or equal to the number of inputs
        int numStages = (int)Log(NextPowerOfTwo(indexBuffer.count), 2);
        int curStride;

        sortCompute.SetInt("numEntries", indexBuffer.count);

        for (int curPlaceValue = 0; curPlaceValue < maxNumberOfPlaceValues; curPlaceValue++)
        {
            curStride = 1;
            sortCompute.SetInt("curPlaceValue", curPlaceValue);
            ComputeHelper.SetBuffer(this.sortCompute, this.dstBucketBuffer, DST_BUCKET_VAR_NAME, initPredicateKernel);

            ComputeHelper.Dispatch(sortCompute, indexBuffer.count, kernelIndex: initPredicateKernel);

            for (int stageIndex = 0; stageIndex < numStages; stageIndex++)
            {
                sortCompute.SetInt("curStride", curStride);
                swapBucketBuffers(hillisSteeleStepKernel);

                ComputeHelper.Dispatch(sortCompute, indexBuffer.count, kernelIndex: hillisSteeleStepKernel);

                curStride *= 2;
            }

            swapBucketBuffers(convertInclusiveScanToExclusiveKernel);
            ComputeHelper.Dispatch(sortCompute, indexBuffer.count, kernelIndex: convertInclusiveScanToExclusiveKernel);

            ComputeHelper.SetBuffer(this.sortCompute, this.srcBucketBuffer, SRC_BUCKET_VAR_NAME, ScatterSpacialIndicesKernel);
            ComputeHelper.SetBuffer(this.sortCompute, this.dstBucketBuffer, DST_BUCKET_VAR_NAME, ScatterSpacialIndicesKernel);

            ComputeHelper.Dispatch(sortCompute, indexBuffer.count, kernelIndex: ScatterSpacialIndicesKernel);
            //ComputeHelper.Dispatch(sortCompute, indexBuffer.count, kernelIndex: CopyEntriesBufferBackKernel);
        }
    }
}