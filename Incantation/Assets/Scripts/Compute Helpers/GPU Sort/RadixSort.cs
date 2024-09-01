using UnityEngine;
using static UnityEngine.Mathf;
using Unity.Mathematics;

public abstract class RadixSort : GPUSort
{
    protected const int NUMBUCKETS = 4;
    protected const string SRC_BUCKET_VAR_NAME = "SrcBuckets";
    protected const string DST_BUCKET_VAR_NAME = "DstBuckets";

    protected struct BucketStruct
    {
        public uint[] buckets;
    }

    protected ComputeBuffer srcBucketBuffer;
    protected ComputeBuffer dstBucketBuffer;
    protected ComputeBuffer scatterEntriesBuffer;

    public RadixSort(string resourceName) : base(resourceName) { }

    protected override void createAlgorithmSpecificBuffers(int elementCount) 
    {
        int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(uint));
        this.srcBucketBuffer = new ComputeBuffer(elementCount, stride * NUMBUCKETS);
        this.dstBucketBuffer = new ComputeBuffer(elementCount, stride * NUMBUCKETS);
        this.scatterEntriesBuffer = ComputeHelper.CreateStructuredBuffer<uint3>(this.indexBuffer.count);
    }

    protected void swapBucketBuffers(int kernelId)
    {
        ComputeBuffer tmp = this.dstBucketBuffer;
        this.dstBucketBuffer = this.srcBucketBuffer;
        this.srcBucketBuffer = tmp;

        ComputeHelper.SetBuffer(this.sortCompute, this.srcBucketBuffer, SRC_BUCKET_VAR_NAME, kernelId);
        ComputeHelper.SetBuffer(this.sortCompute, this.dstBucketBuffer, DST_BUCKET_VAR_NAME, kernelId);
    }
}