using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class GPUSort
{
    readonly protected ComputeShader sortCompute;

    protected int keySize;

    protected ComputeBuffer predictedPositions;

    protected ComputeBuffer keys;
    protected ComputeBuffer values;
    protected ComputeBuffer keysDB;
    protected ComputeBuffer valuesDB;

    public GPUSort(string shaderResourceName)
    {
        this.sortCompute = ComputeHelper.LoadComputeShader(shaderResourceName);
    }

    // Assume buffer management (ie release) is managed by caller, as buffers may be reused for other steps
    public void SetBuffers(int keySize, ComputeBuffer keys, ComputeBuffer values, ComputeBuffer keysDB, ComputeBuffer valuesDB)
    {
        this.keySize = keySize;

        this.keys = keys;
        this.values = values;
        this.keysDB = keysDB;
        this.valuesDB = valuesDB;

        createAlgorithmSpecificBuffers(keySize);
        setBuffersInKernels();
    }

    /*
     * After sort, sorted keys should be in buffer1 and indices should be in buffer2.
     */
    public abstract void Sort();

    public abstract void destroy();
    protected abstract void createAlgorithmSpecificBuffers(int keysCount);
    protected abstract void setBuffersInKernels();
    protected abstract bool isSortInPlace();
}
