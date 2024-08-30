using UnityEngine;
using Unity.Mathematics;
using UnityEngine.Rendering;

public class Simulation3D : MonoBehaviour
{
    public event System.Action SimulationStepCompleted;

    [Header("Settings")]
    public float timeScale = 1;
    public bool fixedTimeStep;
    public int iterationsPerFrame;
    public float gravity = -10;
    [Range(0, 1)] public float collisionDamping = 0.05f;
    public float smoothingRadius = 0.2f;
    public float targetDensity;
    public float pressureMultiplier;
    public float nearPressureMultiplier;
    public float viscosityStrength;

    [Header("References")]
    public ComputeShader compute;
    public Spawner3D spawner;
    public ParticleDisplay3D display;
    public Transform floorDisplay;

    // Command Buffer
    CommandBuffer commandBuffer;

    // Buffers
    public ComputeBuffer positionBuffer { get; private set; }
    public ComputeBuffer velocityBuffer { get; private set; }
    public ComputeBuffer densityBuffer { get; private set; }
    public ComputeBuffer predictedPositionsBuffer;
    ComputeBuffer spatialIndices;
    ComputeBuffer spatialOffsets;

    // Kernel IDs
    const int externalForcesKernel = 0;
    const int spatialHashKernel = 1;
    const int densityKernel = 2;
    const int pressureKernel = 3;
    const int viscosityKernel = 4;
    const int updatePositionsKernel = 5;

    GPUSort gpuSort;

    // State
    bool isPaused;
    bool pauseNextFrame;
    Spawner3D.SpawnData spawnData;

    void Start()
    {
        Debug.Log("Controls: Space = Play/Pause, R = Reset");
        Debug.Log("Use transform tool in scene to scale/rotate simulation bounding box.");

        float deltaTime = 1 / 60f;
        Time.fixedDeltaTime = deltaTime;

        spawnData = spawner.GetSpawnData();

        commandBuffer = new CommandBuffer();
        commandBuffer.SetExecutionFlags(CommandBufferExecutionFlags.AsyncCompute);

        // Create buffers
        int numParticles = spawnData.points.Length;
        positionBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        predictedPositionsBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        velocityBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        densityBuffer = ComputeHelper.CreateStructuredBuffer<float2>(numParticles);
        spatialIndices = ComputeHelper.CreateStructuredBuffer<uint3>(numParticles);
        spatialOffsets = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);

        // Set buffer data
        SetInitialBufferData(spawnData);

        // Init compute
        ComputeHelper.SetBuffer(compute, positionBuffer, "Positions", commandBuffer: commandBuffer, kernels: new int[]{ externalForcesKernel, updatePositionsKernel});
        ComputeHelper.SetBuffer(compute, predictedPositionsBuffer, "PredictedPositions", commandBuffer: commandBuffer, kernels: new int[] { externalForcesKernel, spatialHashKernel, densityKernel, pressureKernel, viscosityKernel, updatePositionsKernel });
        ComputeHelper.SetBuffer(compute, spatialIndices, "SpatialIndices", commandBuffer: commandBuffer, kernels: new int[] { spatialHashKernel, densityKernel, pressureKernel, viscosityKernel });
        ComputeHelper.SetBuffer(compute, spatialOffsets, "SpatialOffsets", commandBuffer: commandBuffer, kernels: new int[] { spatialHashKernel, densityKernel, pressureKernel, viscosityKernel });
        ComputeHelper.SetBuffer(compute, densityBuffer, "Densities", commandBuffer: commandBuffer, kernels: new int[] { densityKernel, pressureKernel, viscosityKernel });
        ComputeHelper.SetBuffer(compute, velocityBuffer, "Velocities", commandBuffer: commandBuffer, kernels: new int[] { externalForcesKernel, pressureKernel, viscosityKernel, updatePositionsKernel });

        commandBuffer.SetComputeIntParam(compute, "numParticles", positionBuffer.count);

        gpuSort = new();
        gpuSort.SetBuffers(spatialIndices, spatialOffsets, commandBuffer: commandBuffer);

        // Init display
        display.Init(this);
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
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: externalForcesKernel, commandBuffer: commandBuffer);
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: spatialHashKernel, commandBuffer: commandBuffer);
        gpuSort.SortAndCalculateOffsets(commandBuffer: commandBuffer);
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: densityKernel, commandBuffer: commandBuffer);
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: pressureKernel, commandBuffer: commandBuffer);
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: viscosityKernel, commandBuffer: commandBuffer);
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: updatePositionsKernel, commandBuffer: commandBuffer);

        Graphics.ExecuteCommandBuffer(commandBuffer);
    }

    void UpdateSettings(float deltaTime)
    {
        Vector3 simBoundsSize = transform.localScale;
        Vector3 simBoundsCentre = transform.position;

        commandBuffer.SetComputeFloatParam(compute, "deltaTime", deltaTime);
        commandBuffer.SetComputeFloatParam(compute, "gravity", gravity);
        commandBuffer.SetComputeFloatParam(compute, "collisionDamping", collisionDamping);
        commandBuffer.SetComputeFloatParam(compute, "smoothingRadius", smoothingRadius);
        commandBuffer.SetComputeFloatParam(compute, "targetDensity", targetDensity);
        commandBuffer.SetComputeFloatParam(compute, "pressureMultiplier", pressureMultiplier);
        commandBuffer.SetComputeFloatParam(compute, "nearPressureMultiplier", nearPressureMultiplier);
        commandBuffer.SetComputeFloatParam(compute, "viscosityStrength", viscosityStrength);
        commandBuffer.SetComputeVectorParam(compute, "boundsSize", simBoundsSize);
        commandBuffer.SetComputeVectorParam(compute, "centre", simBoundsCentre);

        commandBuffer.SetComputeMatrixParam(compute, "localToWorld", transform.localToWorldMatrix);
        commandBuffer.SetComputeMatrixParam(compute, "worldToLocal", transform.worldToLocalMatrix);
    }

    void SetInitialBufferData(Spawner3D.SpawnData spawnData)
    {
        float3[] allPoints = new float3[spawnData.points.Length];
        System.Array.Copy(spawnData.points, allPoints, spawnData.points.Length);

        positionBuffer.SetData(allPoints);
        predictedPositionsBuffer.SetData(allPoints);
        velocityBuffer.SetData(spawnData.velocities);
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
        ComputeHelper.Release(positionBuffer, predictedPositionsBuffer, velocityBuffer, densityBuffer, spatialIndices, spatialOffsets);
        commandBuffer.Release();
    }

    void OnDrawGizmos()
    {
        // Draw Bounds
        var m = Gizmos.matrix;
        Gizmos.matrix = transform.localToWorldMatrix;
        Gizmos.color = new Color(0, 1, 0, 0.5f);
        Gizmos.DrawWireCube(Vector3.zero, Vector3.one);
        Gizmos.matrix = m;

    }
}
