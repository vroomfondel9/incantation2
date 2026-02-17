using UnityEngine;
using static UnityEngine.Mathf;
using UnityEngine.Rendering;
using GPUSorting.Runtime;

public class DeviceRdxSort : GPUSort
{
    ComputeShader deviceRadixSort;

    DeviceRadixSort m_dvr;

    protected int keysCount;

    protected ComputeBuffer globalHist;
    protected ComputeBuffer passHist;

    public DeviceRdxSort() : base("GPUSortPackage/Shaders/DeviceRadixSort") { }

    public override void destroy()
    {
        globalHist?.Dispose();
        passHist?.Dispose();
    }

    public override void Sort()
    {
        m_dvr.Sort(
            this.keysCount,
            this.keys,
            this.values,
            this.keysDB,
            this.valuesDB,
            this.globalHist,
            this.passHist,
            typeof(uint),
            typeof(uint),
            true);
    }

    protected override void createAlgorithmSpecificBuffers(int keysCount)
    {
        this.keysCount = keysCount;

        m_dvr = new DeviceRadixSort(
            this.sortCompute,
            keysCount,
            ref this.keysDB,
            ref this.valuesDB,
            ref globalHist,
            ref passHist);
    }

    protected override bool isSortInPlace()
    {
        return false;
    }

    protected override void setBuffersInKernels() {}
}