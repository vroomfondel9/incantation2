using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class GPUSort
{
    readonly protected ComputeShader sortCompute;

    protected int numParticles;

    protected ComputeBuffer predictedPositions;

    protected ComputeBuffer buffer1;
    protected ComputeBuffer buffer2;

    public GPUSort(string shaderResourceName)
    {
        this.sortCompute = ComputeHelper.LoadComputeShader(shaderResourceName);
    }

    // Assume buffer management (ie release) is managed by caller, as buffers may be reused for other steps
    // Assume buffer1.x is keys to sort and buffer1.y is indices
    // Assume buffer 2 is arbitrary uninitialized values since these are used (optionally) to double buffer
    public void SetBuffers(ComputeBuffer predictedPositions, ComputeBuffer buffer1, ComputeBuffer buffer2)
    {
        this.numParticles = predictedPositions.count;

        this.predictedPositions = predictedPositions;
        this.buffer1 = buffer1;
        this.buffer2 = buffer2;

        createAlgorithmSpecificBuffers(numParticles);
        setBuffersInKernels();
    }

    public abstract void Sort();

    public abstract void destroy();
    protected abstract void createAlgorithmSpecificBuffers(int elementCount);
    protected abstract void setBuffersInKernels();
    protected abstract bool isSortInPlace();
}
