using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class GPUSort
{
    protected const int calculateOffsetsKernel = 0;

    readonly protected ComputeShader sortCompute;

    protected ComputeBuffer indexBuffer;
    protected ComputeBuffer offsetBuffer;

    public GPUSort(string shaderResourceName)
    {
        this.sortCompute = ComputeHelper.LoadComputeShader(shaderResourceName);
    }

    public void SetBuffers(ComputeBuffer indexBuffer, ComputeBuffer offsetBuffer)
    {
        this.indexBuffer = indexBuffer;
        this.offsetBuffer = offsetBuffer;

        createAlgorithmSpecificBuffers();
        setBuffersInKernels();
    }

    public void SortAndCalculateOffsets()
    {
        Sort();

        ComputeHelper.Dispatch(this.sortCompute, indexBuffer.count, kernelIndex: calculateOffsetsKernel);
    }

    protected abstract void createAlgorithmSpecificBuffers();
    protected abstract void setBuffersInKernels();
    protected abstract void Sort();
}
