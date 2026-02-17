using UnityEngine;
using static UnityEngine.Mathf;
using UnityEngine.Rendering;
using GPUSorting.Runtime;

public class OneSweepSort : GPUSort
{
    ComputeShader oneSweep;

    OneSweep m_os;

    protected int keysCount;

    protected ComputeBuffer globalHist;
    protected ComputeBuffer passHist;
    protected ComputeBuffer index;

    public OneSweepSort() : base("GPUSortPackage/Shaders/OneSweep") { }

    public override void destroy()
    {
        globalHist?.Dispose();
        passHist?.Dispose();
        index?.Dispose();
    }

    public override void Sort()
    {
        m_os.Sort(
            this.keysCount,
            this.keys,
            this.values,
            this.keysDB,
            this.valuesDB,
            this.globalHist,
            this.passHist,
            this.index,
            typeof(uint),
            typeof(uint),
            true);
    }

    protected override void createAlgorithmSpecificBuffers(int keysCount)
    {
        this.keysCount = keysCount;

        m_os = new OneSweep(
            this.sortCompute,
            keysCount,
            ref this.keysDB,
            ref this.valuesDB,
            ref globalHist,
            ref passHist,
            ref index);
    }

    protected override bool isSortInPlace()
    {
        return false;
    }

    protected override void setBuffersInKernels() {}
}