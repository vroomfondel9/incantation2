using UnityEngine;
using UnityEngine.Assertions;
using Unity.Mathematics;
using System.Collections.Generic;

using static UnityEngine.Mathf;

public class Simulation3D : MonoBehaviour
{
    public static bool DEBUG_MODE = true;

    public event System.Action SimulationStepCompleted;

    [Header("Settings")]
    public float timeScale = 1;
    public bool fixedTimeStep;
    public int iterationsPerFrame;
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

    // Buffers that hold the principle SPH values
    public ComputeBuffer positionBuffer { get; private set; }
    public ComputeBuffer velocityBuffer { get; private set; }
    public ComputeBuffer densityBuffer { get; private set; }
    public ComputeBuffer predictedPositionsBuffer;
    public ComputeBuffer debugBuffer { get; private set; }

    // Used to hold indices and keys for sorting
    // Buffers 3 & 4 may not be needed but is used by sort algorithms that can't sort in place and need to double buffer
    ComputeBuffer spacialPart1;
    ComputeBuffer spacialPart2;
    ComputeBuffer spacialPart3;
    ComputeBuffer spacialPart4;

    //Used as a double buffer to re-order density, velocity, position, predicated position values after sort
    public ComputeBuffer tempBuffer;

    //Offsets into the array for origin cells. Stores the start and end indices.
    public ComputeBuffer offsets;

    //Offsets into the array for neighbor lists aligned along the one dimension. Stores the start and end indices.
    public ComputeBuffer spannedOffsets;

    // Kernel Names and IDs
    private const string externalForcesKernel = "ExternalForces";
    private const string initializeSpacialPartitionBuffers = "InitializeSpacialPartitionBuffers";
    private const string copyBufferKernel = "CopyBuffer";
    private const string initalizeOffsetsKernel = "InitOffsets";
    private const string calculateOffsetsKernel = "CalcOffsets";
    private const string spanOffsetsKernel = "SpanOffsets";
    private const string densityKernel = "CalculateDensities";
    private const string pressureKernel = "CalculatePressureForce";
    private const string viscosityKernel = "CalculateViscosity";
    private const string updatePositionsKernel = "UpdatePositions";
    private const string debugKernel = "Debug";
    private string[] kernelNames = { externalForcesKernel, initializeSpacialPartitionBuffers,
        copyBufferKernel, initalizeOffsetsKernel, calculateOffsetsKernel,spanOffsetsKernel, densityKernel,
            pressureKernel, viscosityKernel, updatePositionsKernel };
    private Dictionary<string, int> kernelNameToId = new();

    // Constants for copying data
    const int numCopyBuffers = 4;
    const int numCopyDirections = 2;

    GPUSort gpuSort;

    // State
    bool isPaused;
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
        Debug.Log("Controls: Space = Play/Pause, R = Reset");
        Debug.Log("Use transform tool in scene to scale/rotate simulation bounding box.");

        float deltaTime = 1 / 60f;
        Time.fixedDeltaTime = deltaTime;

        spawnData = spawner.GetSpawnData();

        int numParticles = spawnData.points.Length;
        this.simBounds = new SimulationBounds(this.transform, Mathf.Max(this.gridCellSize, this.smoothingRadius));
        int numCells = (int)this.simBounds.getCellTotal();

        // Create buffers
        positionBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        predictedPositionsBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        velocityBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        densityBuffer = ComputeHelper.CreateStructuredBuffer<float2>(numParticles);
        spacialPart1 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);
        spacialPart2 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);
        spacialPart3 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);
        spacialPart4 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);
        tempBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        offsets = ComputeHelper.CreateStructuredBuffer<uint2>(numCells);
        spannedOffsets = ComputeHelper.CreateStructuredBuffer<uint2>(numCells);

        if (DEBUG_MODE)
        {
            debugBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        }

        // Set buffer data
        SetInitialBufferData(spawnData);

        // Init compute
        ComputeHelper.SetBuffer(compute, positionBuffer, "Positions", kernelNameToId[externalForcesKernel], kernelNameToId[copyBufferKernel], kernelNameToId[updatePositionsKernel]);
        ComputeHelper.SetBuffer(compute, predictedPositionsBuffer, "PredictedPositions", kernelNameToId[externalForcesKernel], kernelNameToId[initializeSpacialPartitionBuffers], kernelNameToId[copyBufferKernel], kernelNameToId[densityKernel], kernelNameToId[pressureKernel], kernelNameToId[viscosityKernel], kernelNameToId[updatePositionsKernel]);
        ComputeHelper.SetBuffer(compute, densityBuffer, "Densities", kernelNameToId[densityKernel], kernelNameToId[pressureKernel], kernelNameToId[viscosityKernel], kernelNameToId[copyBufferKernel]);
        ComputeHelper.SetBuffer(compute, velocityBuffer, "Velocities", kernelNameToId[externalForcesKernel], kernelNameToId[pressureKernel], kernelNameToId[viscosityKernel], kernelNameToId[updatePositionsKernel], kernelNameToId[copyBufferKernel]);
        ComputeHelper.SetBuffer(compute, spacialPart1, "keys", kernelNameToId[initializeSpacialPartitionBuffers], kernelNameToId[calculateOffsetsKernel]);
        ComputeHelper.SetBuffer(compute, spacialPart2, "indices", kernelNameToId[initializeSpacialPartitionBuffers], kernelNameToId[copyBufferKernel]);
        ComputeHelper.SetBuffer(compute, tempBuffer, "tempBuffer", kernelNameToId[copyBufferKernel]);
        ComputeHelper.SetBuffer(compute, offsets, "offsets", kernelNameToId[initalizeOffsetsKernel], kernelNameToId[calculateOffsetsKernel], kernelNameToId[spanOffsetsKernel]);
        ComputeHelper.SetBuffer(compute, spannedOffsets, "spannedOffsets", kernelNameToId[spanOffsetsKernel], kernelNameToId[densityKernel], kernelNameToId[pressureKernel], kernelNameToId[viscosityKernel]);

        if (DEBUG_MODE)
        {
            ComputeHelper.SetBuffer(compute, positionBuffer, "Positions", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, predictedPositionsBuffer, "PredictedPositions", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, densityBuffer, "Densities", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, velocityBuffer, "Velocities", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, spacialPart1, "keys", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, spacialPart2, "indices", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, tempBuffer, "tempBuffer", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, offsets, "offsets", kernelNameToId[debugKernel]);
            ComputeHelper.SetBuffer(compute, spannedOffsets, "spannedOffsets", kernelNameToId[debugKernel]);

            ComputeHelper.SetBuffer(compute, debugBuffer, "DebugValues", kernelNameToId[debugKernel]);
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

    void FixedUpdate()
    {
        // Run simulation if in fixed timestep mode
        if (fixedTimeStep)
        {
            RunSimulationFrame(Time.fixedDeltaTime);
        }
    }

    void Update()
    {
        // Run simulation if not in fixed timestep mode
        // (skip running for first few frames as timestep can be a lot higher than usual)
        if (!fixedTimeStep && Time.frameCount > 10)
        {
            RunSimulationFrame(Time.deltaTime);
        }

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
            float timeStep = frameTime / iterationsPerFrame * timeScale;

            UpdateSettings(timeStep);

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

    void UpdateSettings(float deltaTime)
    {
        compute.SetFloat("deltaTime", deltaTime);
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
        for (int curBuffer = 0; curBuffer < numCopyBuffers; curBuffer++)
        {
            compute.SetInt("copyBufferId", curBuffer);

            for (int curCopyDirection = 0; curCopyDirection < numCopyDirections; curCopyDirection++)
            {
                compute.SetInt("copyDirection", curCopyDirection);
                ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: kernelNameToId[copyBufferKernel]);
            }
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
    }

    void OnDestroy()
    {
        ComputeHelper.Release(positionBuffer, predictedPositionsBuffer, velocityBuffer, densityBuffer, 
            spacialPart1, spacialPart2, spacialPart3, spacialPart4, tempBuffer, offsets, spannedOffsets);
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
