using UnityEngine;
using static UnityEngine.Mathf;
using Unity.Mathematics;

public class OneSweepRadixSort : GPUSort
{
    private const int m_initOneSweepKernel = 1;
    private const int m_globalHistKernel = 2;
    private const int m_scanKernel = 3;
    private const int m_digitBinPassKernel = 4;
    private const int m_initRandomKernel = 5;
    private const int m_validationKernel = 6;

    private const int k_radixPasses = 4;
    private const int k_radix = 256;
    private const int k_partitionSize = 3840;
    private const string k_computeShaderString = "OneSweep";

    private int m_size = 0;
    private int m_threadBlocks = 0;

    private ComputeBuffer altBuffer;
    private ComputeBuffer globalHistoryBuffer;
    private ComputeBuffer interIndexBuffer;
    private ComputeBuffer passHistoryBuffer;
    private ComputeBuffer errorCountBuffer;

    public OneSweepRadixSort() : base("OneSweepRadixSort") { }

    protected override void createAlgorithmSpecificBuffers(int elementCount) 
    {
        CheckShader();
        m_size = elementCount;
        m_threadBlocks = divRoundUp(m_size, k_partitionSize);
        UpdateSize();
        UpdateGlobHistBuffer();
        UpdateIndexBuffer();
        UpdateErrorBuffer();

        Debug.Log(k_computeShaderString + ": init Complete.");
    }

    protected override void setBuffersInKernels()
    {
        ComputeHelper.SetBuffer(this.sortCompute, this.offsetBuffer, "Offsets", calculateOffsetsKernel);
        ComputeHelper.SetBuffer(this.sortCompute, this.indexBuffer, "Entries", calculateOffsetsKernel);
    }

    // Sorts given buffer of integer values using bitonic merge sort
    // Note: buffer size is not restricted to powers of 2 in this implementation
    protected override void Sort()
    {
        DispatchKernels();
    }

    private void CheckShader()
    {
        try
        {
            sortCompute.FindKernel("Init" + k_computeShaderString);
        }
        catch
        {
            Debug.LogError("Kernel(s) not found, most likely you do not have the correct compute shader attached to the game object");
            Debug.LogError("The correct compute shader is" + k_computeShaderString + ". Exit play mode and attatch to the gameobject, then retry.");
            Debug.LogError("Destroying this object.");
            Destroy(this);
        }
    }

    private void Destroy(OneSweepRadixSort toDestroy)
    {
        toDestroy.OnDestroy();
    }

    private void UpdateSize()
    {
        sortCompute.SetInt("e_numKeys", m_size);
        sortCompute.SetInt("e_threadBlocks", m_threadBlocks);
        UpdateSortBuffers();
        UpdatePassHistBuffer();
    }

    private void UpdateSortBuffers()
    {
        if (altBuffer != null)
            altBuffer.Dispose();

        altBuffer = ComputeHelper.CreateStructuredBuffer<uint3>(m_size);
    }

    private void UpdatePassHistBuffer()
    {
        if (passHistoryBuffer != null)
            passHistoryBuffer.Dispose();

        passHistoryBuffer = new ComputeBuffer(m_threadBlocks * k_radix * k_radixPasses, sizeof(uint));
    }

    private void UpdateGlobHistBuffer()
    {
        if (globalHistoryBuffer != null)
            globalHistoryBuffer.Dispose();
        globalHistoryBuffer = new ComputeBuffer(k_radixPasses * k_radix, sizeof(uint));
    }

    private void UpdateIndexBuffer()
    {
        if (interIndexBuffer != null)
            interIndexBuffer.Dispose();
        interIndexBuffer = new ComputeBuffer(k_radixPasses, sizeof(uint));
    }

    private void UpdateErrorBuffer()
    {
        if (errorCountBuffer != null)
            errorCountBuffer.Dispose();
        errorCountBuffer = new ComputeBuffer(1, sizeof(uint));
    }
    private void SetStaticBuffers()
    {
        //Input
        sortCompute.SetBuffer(m_initRandomKernel, "b_sort", indexBuffer);

        //Init
        sortCompute.SetBuffer(m_initOneSweepKernel, "b_passHist", passHistoryBuffer);
        sortCompute.SetBuffer(m_initOneSweepKernel, "b_globalHist", globalHistoryBuffer);
        sortCompute.SetBuffer(m_initOneSweepKernel, "b_index", interIndexBuffer);

        //GlobalHist
        sortCompute.SetBuffer(m_globalHistKernel, "b_sort", indexBuffer);
        sortCompute.SetBuffer(m_globalHistKernel, "b_globalHist", globalHistoryBuffer);

        //Scan
        sortCompute.SetBuffer(m_scanKernel, "b_globalHist", globalHistoryBuffer);
        sortCompute.SetBuffer(m_scanKernel, "b_passHist", passHistoryBuffer);

        //DigitBinningPass
        sortCompute.SetBuffer(m_digitBinPassKernel, "b_passHist", passHistoryBuffer);
        sortCompute.SetBuffer(m_digitBinPassKernel, "b_globalHist", globalHistoryBuffer);
        sortCompute.SetBuffer(m_digitBinPassKernel, "b_index", interIndexBuffer);

        //Validate
        sortCompute.SetBuffer(m_validationKernel, "b_sort", indexBuffer);
        sortCompute.SetBuffer(m_validationKernel, "b_errorCount", errorCountBuffer);
    }

    private void DispatchKernels()
    {
        SetStaticBuffers();
        //sortCompute.SetInt("e_seed", (int)(Time.realtimeSinceStartup * 100000.0f));
        //sortCompute.Dispatch(m_initRandomKernel, 256, 1, 1);

        sortCompute.Dispatch(m_initOneSweepKernel, 256, 1, 1);
        sortCompute.Dispatch(m_globalHistKernel, m_threadBlocks, 1, 1);

        sortCompute.Dispatch(m_scanKernel, k_radixPasses, 1, 1);

        sortCompute.SetInt("e_radixShift", 0);
        sortCompute.SetBuffer(m_digitBinPassKernel, "b_sort", indexBuffer);
        sortCompute.SetBuffer(m_digitBinPassKernel, "b_alt", altBuffer);
        sortCompute.Dispatch(m_digitBinPassKernel, m_threadBlocks, 1, 1);

        sortCompute.SetInt("e_radixShift", 8);
        sortCompute.SetBuffer(m_digitBinPassKernel, "b_sort", altBuffer);
        sortCompute.SetBuffer(m_digitBinPassKernel, "b_alt", indexBuffer);
        sortCompute.Dispatch(m_digitBinPassKernel, m_threadBlocks, 1, 1);

        sortCompute.SetInt("e_radixShift", 16);
        sortCompute.SetBuffer(m_digitBinPassKernel, "b_sort", indexBuffer);
        sortCompute.SetBuffer(m_digitBinPassKernel, "b_alt", altBuffer);
        sortCompute.Dispatch(m_digitBinPassKernel, m_threadBlocks, 1, 1);

        sortCompute.SetInt("e_radixShift", 24);
        sortCompute.SetBuffer(m_digitBinPassKernel, "b_sort", altBuffer);
        sortCompute.SetBuffer(m_digitBinPassKernel, "b_alt", indexBuffer);
        sortCompute.Dispatch(m_digitBinPassKernel, m_threadBlocks, 1, 1);
    }

    private void ValidateSort()
    {
        DispatchKernels();
        uint[] errCount = new uint[1] { 0 };
        errorCountBuffer.SetData(errCount);
        sortCompute.Dispatch(m_validationKernel, 256, 1, 1);
        errorCountBuffer.GetData(errCount);

        if (errCount[0] == 0)
            Debug.Log("OneSweep passed test at size " + m_size + ".");
        else
            Debug.LogError("OneSweep failed test at size " + m_size + " with " + errCount[0] + " errors.");
    }

    static int divRoundUp(int x, int y)
    {
        return (x + y - 1) / y;
    }

    private void OnDestroy()
    {
        if (altBuffer != null)
            altBuffer.Dispose();
        if (globalHistoryBuffer != null)
            globalHistoryBuffer.Dispose();
        if (interIndexBuffer != null)
            interIndexBuffer.Dispose();
        if (passHistoryBuffer != null)
            passHistoryBuffer.Dispose();
        if (errorCountBuffer != null)
            errorCountBuffer.Dispose();
    }
}