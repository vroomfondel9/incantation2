using UnityEngine;
using Unity.Mathematics;

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

    // Buffers that hold the principle SPH values
    public ComputeBuffer positionBuffer { get; private set; }
    public ComputeBuffer velocityBuffer { get; private set; }
    public ComputeBuffer densityBuffer { get; private set; }
    public ComputeBuffer predictedPositionsBuffer;

    // These are reused, depending on the kernel to hold things like keys vs indices
    // After indices have been reordered, this is repurposed to hold keys and offsets
    // Once offsets are computed, keys are no longer needed as they're computed based on position
    // Buffers 3 & 4 may not be needed but is used by sort algorithms that can't sort in place and need to double buffer
    ComputeBuffer spacialPart1;
    ComputeBuffer spacialPart2;
    ComputeBuffer spacialPart3;
    ComputeBuffer spacialPart4;

    //Used as a double buffer to re-order density, velocity, position, predicated position values after sort
    public ComputeBuffer tempBuffer;

    // Kernel IDs
    const int externalForcesKernel = 0;
    const int initializeSpacialPartitionBuffers = 1;
    const int densityKernel = 2;
    const int pressureKernel = 3;
    const int viscosityKernel = 4;
    const int updatePositionsKernel = 5;
    const int copyBufferKernel = 6;
    const int calculateOffsetsKernel = 6;

    // Constants for copying data
    const int numCopyBuffers = 4;
    const int numCopyDirections = 2;

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

        // Create buffers
        int numParticles = spawnData.points.Length;
        positionBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        predictedPositionsBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        velocityBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);
        densityBuffer = ComputeHelper.CreateStructuredBuffer<float2>(numParticles);
        spacialPart1 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);
        spacialPart2 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);
        spacialPart3 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);
        spacialPart4 = ComputeHelper.CreateStructuredBuffer<uint>(numParticles);
        tempBuffer = ComputeHelper.CreateStructuredBuffer<float3>(numParticles);

        // Set buffer data
        SetInitialBufferData(spawnData);

        // Init compute
        ComputeHelper.SetBuffer(compute, positionBuffer, "Positions", externalForcesKernel, updatePositionsKernel, copyBufferKernel);
        ComputeHelper.SetBuffer(compute, predictedPositionsBuffer, "PredictedPositions", externalForcesKernel, initializeSpacialPartitionBuffers, densityKernel, pressureKernel, viscosityKernel, updatePositionsKernel, copyBufferKernel);
        ComputeHelper.SetBuffer(compute, densityBuffer, "Densities", densityKernel, pressureKernel, viscosityKernel, copyBufferKernel);
        ComputeHelper.SetBuffer(compute, velocityBuffer, "Velocities", externalForcesKernel, pressureKernel, viscosityKernel, updatePositionsKernel, copyBufferKernel);
        ComputeHelper.SetBuffer(compute, spacialPart1, "spacialPart1", initializeSpacialPartitionBuffers, calculateOffsetsKernel);
        ComputeHelper.SetBuffer(compute, spacialPart2, "spacialPart2", initializeSpacialPartitionBuffers, calculateOffsetsKernel, densityKernel, pressureKernel, viscosityKernel);
        ComputeHelper.SetBuffer(compute, tempBuffer, "tempBuffer", copyBufferKernel);


        compute.SetInt("numParticles", positionBuffer.count);

        gpuSort = new BitonicSort();
        gpuSort.SetBuffers(predictedPositionsBuffer, spacialPart1, spacialPart2, spacialPart3, spacialPart4);


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
        // External forces (not neighbor-dependent)
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: externalForcesKernel);
        
        // Spacial partitioning for upcoming neighbor searches
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: initializeSpacialPartitionBuffers);
        gpuSort.Sort();
        coalesceMemory();
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: calculateOffsetsKernel);
        
        // SPH core functions
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: densityKernel);
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: pressureKernel);
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: viscosityKernel);

        // Copying predicted position back into position buffer for next iteration
        ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: updatePositionsKernel);

    }

    void UpdateSettings(float deltaTime)
    {
        Vector3 simBoundsSize = transform.localScale;
        Vector3 simBoundsCentre = transform.position;

        compute.SetFloat("deltaTime", deltaTime);
        compute.SetFloat("gravity", gravity);
        compute.SetFloat("collisionDamping", collisionDamping);
        compute.SetFloat("smoothingRadius", smoothingRadius);
        compute.SetFloat("targetDensity", targetDensity);
        compute.SetFloat("pressureMultiplier", pressureMultiplier);
        compute.SetFloat("nearPressureMultiplier", nearPressureMultiplier);
        compute.SetFloat("viscosityStrength", viscosityStrength);
        compute.SetVector("boundsSize", simBoundsSize);
        compute.SetVector("centre", simBoundsCentre);

        compute.SetMatrix("localToWorld", transform.localToWorldMatrix);
        compute.SetMatrix("worldToLocal", transform.worldToLocalMatrix);
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
                ComputeHelper.Dispatch(compute, positionBuffer.count, kernelIndex: copyBufferKernel);
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
        ComputeHelper.Release(positionBuffer, predictedPositionsBuffer, velocityBuffer, densityBuffer, spacialPart1, spacialPart2, spacialPart3, spacialPart4, tempBuffer);
        this.gpuSort.destroy();
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
