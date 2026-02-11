using UnityEngine;
using UnityEngine.Assertions;
using Unity.Mathematics;
using System.Collections.Generic;

using static UnityEngine.Mathf;
using System;

public class Simulation3D : MonoBehaviour
{
    public static bool DEBUG_MODE = false;

    public event System.Action SimulationStepCompleted;

    [Header("Time Step")]
    public float normalTimeScale = 1;
    public float slowTimeScale = 0.1f;
    public float maxTimestepFPS = 60; // if time-step dips lower than this fps, simulation will run slower (set to 0 to disable)
    public int iterationsPerFrame = 3;

    [Header("Simulation Settings")]
    public float gravity = -10;
    [Range(0, 1)] public float collisionDamping = 0.05f;
    public float smoothingRadius = 0.2f;
    public float gridCellSize = 0.2f;

    [Header("Debug Info")]
    public uint3 gridDimensions;
    public uint totalGridCells;

    [Header("Fluid Properties")]
    public float targetDensity;
    public float pressureMultiplier;
    public float nearPressureMultiplier;
    public float viscosityStrength;

    [Header("Visualizations")]
    public bool showUniformGrid;

    [Header("References")]
    public ComputeShader compute;
    public Spawner3D spawner;
    public ParticleDisplay3D display;
    public Transform floorDisplay;

    //Pointers for principle SPH values. This will always point to one of the two double buffers below
    public ComputeBuffer positionBuffer { get; private set; }
    public ComputeBuffer velocityBuffer { get; private set; }
    public ComputeBuffer densityBuffer { get; private set; }
    public ComputeBuffer predictedPositionsBuffer;
    public ComputeBuffer debugBuffer { get; private set; }

    // Buffers that actually hold the principle SPH values
    // Each of these is double-buffered
    public ComputeBuffer positionBuffer1 { get; private set; }
    public ComputeBuffer positionBuffer2 { get; private set; }
    public ComputeBuffer velocityBuffer1 { get; private set; }
    public ComputeBuffer velocityBuffer2 { get; private set; }
    public ComputeBuffer densityBuffer1 { get; private set; }
    public ComputeBuffer densityBuffer2 { get; private set; }
    public ComputeBuffer predictedPositionsBuffer1;
    public ComputeBuffer predictedPositionsBuffer2;
    public ComputeBuffer debugBuffer1 { get; private set; }
    public ComputeBuffer debugBuffer2 { get; private set; }

    // Used to hold indices and keys for sorting
    // Buffers 3 & 4 may not be needed but is used by sort algorithms that can't sort in place and need to double buffer
    ComputeBuffer spacialPart1;
    ComputeBuffer spacialPart2;
    ComputeBuffer spacialPart3;
    ComputeBuffer spacialPart4;

    //Offsets into the array for origin cells. Stores the start and end indices.
    public ComputeBuffer offsets;

    //Offsets into the array for neighbor lists aligned along the one dimension. Stores the start and end indices.
    public ComputeBuffer spannedOffsets;

    //Keeps track of which double buffer is in use
    private bool doubleBufferOnOne;

    // Kernel Names and IDs
    private const string externalForcesKernel = "ExternalForces";
    private const string initializeSpacialPartitionBuffers = "InitializeSpacialPartitionBuffers";
    private const string scatterToSortedIndicesKernel = "ScatterToSortedIndices";
    private const string initalizeOffsetsKernel = "InitOffsets";
    private const string calculateOffsetsKernel = "CalcOffsets";
    private const string spanOffsetsKernel = "SpanOffsets";
    private const string densityKernel = "CalculateDensities";
    private const string pressureKernel = "CalculatePressureForce";
    private const string viscosityKernel = "CalculateViscosity";
    private const string updatePositionsKernel = "UpdatePositions";
    private const string debugKernel = "Debug";
    private string[] kernelNames = { externalForcesKernel, initializeSpacialPartitionBuffers,
        scatterToSortedIndicesKernel, initalizeOffsetsKernel, calculateOffsetsKernel,spanOffsetsKernel, densityKernel,
            pressureKernel, viscosityKernel, updatePositionsKernel };
    private Dictionary<string, int> kernelNameToId = new();

    GPUSort gpuSort;

    // State
    bool isPaused;
    bool inSlowMode;
    bool pauseNextFrame;
    Spawner3D.SpawnData spawnData;
    public SimulationBounds simBounds;

    void Start()
    {
        Initialize();
    }

    protected void Initialize()
    {
        ValidateKernels();
        Debug.Log("Controls: Space = Play/Pause, Q = SlowMode, R = Reset, Right Arrow = Next Frame");

        float deltaTime = 1 / 60f;
        Time.fixedDeltaTime = deltaTime;

        spawnData = spawner.GetSpawnData();

        int numParticles = spawnData.points.Length;
        this.simBounds = new SimulationBounds(this.transform, Mathf.Max(this.gridCellSize, this.smoothingRadius));
        int numCells = (int)this.simBounds.getCellTotal();

        // Create buffers
        positionBuffer1 = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        positionBuffer2 = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        predictedPositionsBuffer1 = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        predictedPositionsBuffer2 = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        velocityBuffer1 = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        velocityBuffer2 = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        densityBuffer1 = ComputeHelper.CreateStructuredBuffer<float2>(numParticles);
        densityBuffer2 = ComputeHelper.CreateStructuredBuffer<float2>(numParticles);

        spacialPart1 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);
        spacialPart2 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);
        spacialPart3 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);
        spacialPart4 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);

        offsets = ComputeHelper.CreateStructuredBuffer<uint2>(numCells);
        spannedOffsets = ComputeHelper.CreateStructuredBuffer<uint2>(numCells);

        if (DEBUG_MODE)
        {
            debugBuffer1 = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
            debugBuffer2 = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        }

        // Initialize double buffers
        doubleBufferOnOne = false;
        swapSPHDoubleBuffers();

        // Set buffer data
        SetInitialBufferData(spawnData);

        // Init non-double buffers
        ComputeHelper.SetBuffer(compute, spacialPart1, "keys", kernelNameToId[initializeSpacialPartitionBuffers], kernelNameToId[calculateOffsetsKernel]);
        ComputeHelper.SetBuffer(compute, spacialPart2, "indices", kernelNameToId[initializeSpacialPartitionBuffers], kernelNameToId[scatterToSortedIndicesKernel]);
        ComputeHelper.SetBuffer(compute, offsets, "offsets", kernelNameToId[initalizeOffsetsKernel], kernelNameToId[calculateOffsetsKernel], kernelNameToId[spanOffsetsKernel]);
        ComputeHelper.SetBuffer(compute, spannedOffsets, "spannedOffsets", kernelNameToId[spanOffsetsKernel], kernelNameToId[densityKernel], kernelNameToId[pressureKernel], kernelNameToId[viscosityKernel]);

        if (DEBUG_MODE)
        {
            ComputeHelper.SetBuffer(compute, spacialPart1, "keys", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, spacialPart2, "indices", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, offsets, "offsets", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, spannedOffsets, "spannedOffsets", kernelNameToId[debugKernel]);
        }

        compute.SetInt("numParticles", numParticles);
        compute.SetInt("numCells", numCells);

        uint3 dim = simBounds.getDimensions();
        compute.SetFloat("cellSize", gridCellSize);
        compute.SetInts("boundsSize", new int[] { (int)dim.x, (int)dim.y, (int)dim.z });

        gpuSort = new DeviceRdxSort();
        gpuSort.SetBuffers(predictedPositionsBuffer.count, spacialPart1, spacialPart2, spacialPart3, spacialPart4);

        // Init display
        display.Init(this);
    }

    protected void ValidateKernels()
    {
        bool valid = true;

        List<string> kernelNms = new List<string>(kernelNames);
        if (DEBUG_MODE)
        {
            kernelNms.Add(debugKernel);
        }

        if (compute)
        {
            int curValue;
            bool curValid;
            foreach (string curKey in kernelNms)
            {
                curValid = false;

                // Throws Argument Exception if not found
                curValue = compute.FindKernel(curKey);

                if (!compute.IsSupported(curValue))
                {
                    Debug.LogError("Kernel " + curKey + " contains features not supported by end-user device.");
                }
                else
                {
                    kernelNameToId.Add(curKey, curValue);
                    curValid = true;
                }

                valid &= curValid;
            }
        }

        Assert.IsTrue(valid);
    }

    void Update()
    {
        float maxDeltaTime = maxTimestepFPS > 0 ? 1 / maxTimestepFPS : float.PositiveInfinity; // If framerate dips too low, run the simulation slower than real-time
        float dt = Mathf.Min(Time.deltaTime * ActiveTimeScale, maxDeltaTime);

        RunSimulationFrame(dt);

        if (pauseNextFrame)
        {
            isPaused = true;
            pauseNextFrame = false;
        }
        floorDisplay.transform.localScale = new Vector3(1, 1 / transform.localScale.y * 0.1f, 1);

        HandleInput();
    }

    void RunSimulationFrame(float frameTime)
    {
        if (!isPaused)
        {
            float timeStep = frameTime / iterationsPerFrame;

            UpdateSettings(timeStep, frameTime);

            for (int i = 0; i < iterationsPerFrame; i++)
            {
                RunSimulationStep();
                SimulationStepCompleted?.Invoke();
            }
        }
    }

    void RunSimulationStep()
    {
        // External forces (not neighbor-dependent)
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: kernelNameToId[externalForcesKernel]);
        
        // Spacial partitioning for upcoming neighbor searches
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: kernelNameToId[initializeSpacialPartitionBuffers]);
        gpuSort.Sort();
        coalesceMemory();
        ComputeHelper.Dispatch(compute, offsets.count, kernelIndex: kernelNameToId[initalizeOffsetsKernel]);
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: kernelNameToId[calculateOffsetsKernel]);
        ComputeHelper.Dispatch(compute, offsets.count, kernelIndex: kernelNameToId[spanOffsetsKernel]);

        // SPH core functions
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: kernelNameToId[densityKernel]);
        if (DEBUG_MODE)
        {
            ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: kernelNameToId[debugKernel]);
        }
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: kernelNameToId[pressureKernel]);
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: kernelNameToId[viscosityKernel]);

        // Copying predicted position back into position buffer for next iteration
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: kernelNameToId[updatePositionsKernel]);
    }

    void UpdateSettings(float stepDeltaTime, float frameDeltaTime)
    {
        compute.SetFloat("deltaTime", stepDeltaTime);
        compute.SetFloat("deltaTimeOverAllIterations", frameDeltaTime);
        compute.SetFloat("gravity", gravity);
        compute.SetFloat("collisionDamping", collisionDamping);
        compute.SetFloat("smoothingRadius", smoothingRadius);
        compute.SetFloat("targetDensity", targetDensity);
        compute.SetFloat("pressureMultiplier", pressureMultiplier);
        compute.SetFloat("nearPressureMultiplier", nearPressureMultiplier);
        compute.SetFloat("viscosityStrength", viscosityStrength);
        compute.SetMatrix("localToWorld", simBounds.getLocalToWorldMatrix());
        compute.SetMatrix("worldToLocal", simBounds.getWorldToLocalMatrix());
    }

    void SetInitialBufferData(Spawner3D.SpawnData spawnData)
    {
        float3[] allPoints = new float3[spawnData.points.Length];
        System.Array.Copy(spawnData.points, allPoints, spawnData.points.Length);

        positionBuffer.SetData(allPoints);
        predictedPositionsBuffer.SetData(allPoints);
        velocityBuffer.SetData(spawnData.velocities);
    }

    void coalesceMemory()
    {
        swapSPHDoubleBuffers();
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: kernelNameToId[scatterToSortedIndicesKernel]);
    }

    void swapSPHDoubleBuffers()
    {
        doubleBufferOnOne = !doubleBufferOnOne;

        ComputeBuffer positionBufferSrc, predictedPositionsBufferSrc, velocityBufferSrc, densityBufferSrc, debugBufferSrc;

        if (doubleBufferOnOne)
        {
            positionBuffer = positionBuffer1;
            predictedPositionsBuffer = predictedPositionsBuffer1;
            velocityBuffer = velocityBuffer1;
            densityBuffer = densityBuffer1;
            if (DEBUG_MODE)
            {
                debugBuffer = debugBuffer1;
            }

            positionBufferSrc = positionBuffer2;
            predictedPositionsBufferSrc = predictedPositionsBuffer2;
            velocityBufferSrc = velocityBuffer2;
            densityBufferSrc = densityBuffer2;
            if (DEBUG_MODE)
            {
                debugBufferSrc = debugBuffer2;
            }
        }
        else
        {
            positionBuffer = positionBuffer2;
            predictedPositionsBuffer = predictedPositionsBuffer2;
            velocityBuffer = velocityBuffer2;
            densityBuffer = densityBuffer2;
            if (DEBUG_MODE)
            {
                debugBuffer = debugBuffer2;
            }

            positionBufferSrc = positionBuffer1;
            predictedPositionsBufferSrc = predictedPositionsBuffer1;
            velocityBufferSrc = velocityBuffer1;
            densityBufferSrc = densityBuffer1;
            if (DEBUG_MODE)
            {
                debugBufferSrc = debugBuffer1;
            }
        }

        ComputeHelper.SetBuffer(compute, positionBuffer, "Positions", kernelNameToId[externalForcesKernel], kernelNameToId[scatterToSortedIndicesKernel], kernelNameToId[updatePositionsKernel]);
        ComputeHelper.SetBuffer(compute, predictedPositionsBuffer, "PredictedPositions", kernelNameToId[externalForcesKernel], kernelNameToId[initializeSpacialPartitionBuffers], kernelNameToId[scatterToSortedIndicesKernel], kernelNameToId[densityKernel], kernelNameToId[pressureKernel], kernelNameToId[viscosityKernel], kernelNameToId[updatePositionsKernel]);
        ComputeHelper.SetBuffer(compute, densityBuffer, "Densities", kernelNameToId[densityKernel], kernelNameToId[pressureKernel], kernelNameToId[viscosityKernel], kernelNameToId[scatterToSortedIndicesKernel]);
        ComputeHelper.SetBuffer(compute, velocityBuffer, "Velocities", kernelNameToId[externalForcesKernel], kernelNameToId[pressureKernel], kernelNameToId[viscosityKernel], kernelNameToId[updatePositionsKernel], kernelNameToId[scatterToSortedIndicesKernel]);

        ComputeHelper.SetBuffer(compute, positionBufferSrc, "PositionsSrc", kernelNameToId[scatterToSortedIndicesKernel]);
        ComputeHelper.SetBuffer(compute, predictedPositionsBufferSrc, "PredictedPositionsSrc", kernelNameToId[scatterToSortedIndicesKernel]);
        ComputeHelper.SetBuffer(compute, densityBufferSrc, "DensitiesSrc", kernelNameToId[scatterToSortedIndicesKernel]);
        ComputeHelper.SetBuffer(compute, velocityBufferSrc, "VelocitiesSrc", kernelNameToId[scatterToSortedIndicesKernel]);


        if (DEBUG_MODE)
        {
            ComputeHelper.SetBuffer(compute, positionBuffer, "Positions", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, predictedPositionsBuffer, "PredictedPositions", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, densityBuffer, "Densities", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, velocityBuffer, "Velocities", kernelNameToId[debugKernel]);

            ComputeHelper.SetBuffer(compute, debugBuffer, "DebugValues", kernelNameToId[debugKernel]);
        }
    }

    void HandleInput()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            isPaused = !isPaused;
        }

        if (Input.GetKeyDown(KeyCode.RightArrow))
        {
            isPaused = false;
            pauseNextFrame = true;
        }

        if (Input.GetKeyDown(KeyCode.R))
        {
            isPaused = true;
            SetInitialBufferData(spawnData);
        }

        if (Input.GetKeyDown(KeyCode.Q))
        {
            inSlowMode = !inSlowMode;
        }
    }

    private float ActiveTimeScale => inSlowMode ? slowTimeScale : normalTimeScale;

    void OnDestroy()
    {
        ComputeHelper.Release(positionBuffer1, predictedPositionsBuffer1, velocityBuffer1, densityBuffer1,
            positionBuffer2, predictedPositionsBuffer2, velocityBuffer2, densityBuffer2,
            spacialPart1, spacialPart2, spacialPart3, spacialPart4, 
            offsets, spannedOffsets);

        if (DEBUG_MODE)
        {
            ComputeHelper.Release(debugBuffer1, debugBuffer2);
        }

        this.gpuSort.destroy();
    }

    void checkResizeSimBounds()
    {
        if (!Application.isPlaying)
        {
            if (simBounds == null)
            {
                simBounds = new SimulationBounds(this.transform, Mathf.Max(this.gridCellSize, this.smoothingRadius));
            }
            simBounds.update(this.transform, Mathf.Max(this.gridCellSize, this.smoothingRadius));

            gridDimensions = simBounds.getDimensions();
            totalGridCells = simBounds.getCellTotal();
        }
    }

    void OnValidate()
    {
        checkResizeSimBounds();
    }

    void OnDrawGizmos()
    {
        checkResizeSimBounds();

        // Draw Bounds
        var m = Gizmos.matrix;

        Gizmos.matrix = this.transform.localToWorldMatrix;
        Gizmos.color = new Color(0, 0.75f, 0.25f, 0.5f);
        Gizmos.DrawWireCube(Vector3.zero, Vector3.one);

        Gizmos.matrix = this.simBounds.getLocalToWorldMatrix();
        Gizmos.color = new Color(0, 1, 0, 0.5f);
        Gizmos.DrawWireCube(Vector3.zero, Vector3.one);

        Gizmos.matrix = m;

        if (showUniformGrid)
        {
            Gizmos.color = new Color(1, 1, 1, 0.25f);

            uint3 dimensions = this.simBounds.getDimensions();
            Vector3 scale = this.simBounds.getScale();
            float cellSize = this.simBounds.getCellSize();

            Vector3 halfScale = new Vector3(scale.x / 2.0f, scale.y / 2.0f, scale.z / 2.0f);
            Vector3 halfCellSize = new Vector3(cellSize / 2.0f, cellSize / 2.0f, cellSize / 2.0f);
            Vector3 startPos = -1 * halfScale + halfCellSize;
            Vector3 singleCellScale = Vector3.one * cellSize;

            Vector3 curStartPos;
            for (int x = 0; x < dimensions.x; x++)
            {
                for (int y = 0; y < dimensions.y; y++)
                {
                    for (int z = 0; z < dimensions.z; z++)
                    {
                        curStartPos = new Vector3(
                            startPos.x + x * cellSize, 
                            startPos.y + y * cellSize, 
                            startPos.z + z * cellSize
                        );
                        Gizmos.DrawWireCube(curStartPos, singleCellScale);
                    }
                }
            }
        }
    }
}
