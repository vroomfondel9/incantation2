using System;
using System.Collections.Generic;
using UnityEngine;

[DefaultExecutionOrder(1000)]
public class VoxelVolumeRegistry : MonoBehaviour
{
    public static VoxelVolumeRegistry Instance { get; private set; }

    [Header("Capacity")]
    [SerializeField] private int maxVoxels = 1_000_000;

    [Header("Shader Setup")]
    [SerializeField] private Shader voxelShader; // Shader Graphs/VoxVolShader

    // GPU Buffers
    private GraphicsBuffer voxels; // uint (4 bytes) packed as RGBH where H is hit info

    private Material runtimeMaterial;

    // Allocation bookkeeping
    private struct Allocation
    {
        public int offset;
        public int size;
        public int consumers;
    }

    private enum DEBUG_VISUALIZATION_MODES
    {
        NONE = 0,
        BOUNDING_BOXES = 1,
        NORMALS = 2,
        DEPTH = 3,
        VOXEL_TOPOLOGY = 4,
        RAYMARCH_ITERATIONS = 5,
        RAYMARCH_SAMPLES = 6
    }

    // Memory management variables
    private Dictionary<long, Allocation> allocations = new();
    private Dictionary<int, int> startingFreeOffsetsToSize = new();
    private Dictionary<int, int> endingFreeOffsetsToSize = new();
    private Dictionary<String, long> sourceTopologyIdToAllocationId = new();
    private List<(int offset, int size)> freeRegions = new();

    private int allocationsTail = 0;
    private long nextVoxelVolumeID = 1;

    // Debug properties
    [Header("Debug Visualization Mode")]
    [SerializeField] private int debugVisualizationMode = 0;

    [Header("Memory Management - Percent")]
    [SerializeField][Range(0, 100)] private float usagePercent;
    [SerializeField][Range(0, 100)] private float fragmentationPercent;
    [SerializeField][Range(0, 100)] private float uniqueAllocationPercent;

    private long freeSum = 0;
    private long sharedMemoryVolumeRiders = 0;
    [Header("Memory Management - Absolute Values")]
    [SerializeField] private long sharedMemoryVolumes = 0;
    [SerializeField] private long totalVolumes = 0;
    [SerializeField] private long sharedAllocations = 0;
    [SerializeField] private long uniqueAllocations = 0;
    [SerializeField] private long totalAllocations = 0;

    public float UsagePercent => usagePercent;
    public float FragmentationPercent => fragmentationPercent;

    #region Unity Lifecycle

    private void Awake()
    {
        if (Instance != null)
        {
            Destroy(gameObject);
            return;
        }

        Instance = this;
    }

    private void Start()
    {
        CreateBuffers();
        CreateRuntimeMaterial();
        RegisterAllVolumesInScene();
        UpdateDebugStats();
        Debug.Log("Hold L Key and Press Number Keys for Debug Visualizations.");
    }

    void Update()
    {
        CheckDebugModeKeyChange();
    }

    private void OnDestroy()
    {
        voxels?.Dispose();
    }

    private void OnValidate()
    {
        SetDebugMode((DEBUG_VISUALIZATION_MODES)debugVisualizationMode);
    }

        #endregion

        #region Debug Visualization

        void CheckDebugModeKeyChange()
    {
        // Only respond while L is held
        if (!Input.GetKey(KeyCode.L))
            return;

        CheckKey(KeyCode.Alpha0, DEBUG_VISUALIZATION_MODES.NONE);
        CheckKey(KeyCode.Alpha1, DEBUG_VISUALIZATION_MODES.BOUNDING_BOXES);
        CheckKey(KeyCode.Alpha2, DEBUG_VISUALIZATION_MODES.NORMALS);
        CheckKey(KeyCode.Alpha3, DEBUG_VISUALIZATION_MODES.DEPTH);
        CheckKey(KeyCode.Alpha4, DEBUG_VISUALIZATION_MODES.VOXEL_TOPOLOGY);
        CheckKey(KeyCode.Alpha5, DEBUG_VISUALIZATION_MODES.RAYMARCH_ITERATIONS);
        CheckKey(KeyCode.Alpha6, DEBUG_VISUALIZATION_MODES.RAYMARCH_SAMPLES);

        // Optional numpad support
        CheckKey(KeyCode.Keypad0, DEBUG_VISUALIZATION_MODES.NONE);
        CheckKey(KeyCode.Keypad1, DEBUG_VISUALIZATION_MODES.BOUNDING_BOXES);
        CheckKey(KeyCode.Keypad2, DEBUG_VISUALIZATION_MODES.NORMALS);
        CheckKey(KeyCode.Keypad3, DEBUG_VISUALIZATION_MODES.DEPTH);
        CheckKey(KeyCode.Keypad4, DEBUG_VISUALIZATION_MODES.VOXEL_TOPOLOGY);
        CheckKey(KeyCode.Keypad5, DEBUG_VISUALIZATION_MODES.RAYMARCH_ITERATIONS);
        CheckKey(KeyCode.Keypad6, DEBUG_VISUALIZATION_MODES.RAYMARCH_SAMPLES);
    }

    void CheckKey(KeyCode key, DEBUG_VISUALIZATION_MODES mode)
    {
        if (Input.GetKeyDown(key))
        {
            SetDebugMode(mode);
        }
    }

    void SetDebugMode(DEBUG_VISUALIZATION_MODES mode)
    {
        debugVisualizationMode = (int)mode;
        Shader.SetGlobalFloat("_DebugVisualizationMode", (int)mode);
        Debug.Log($"Global Debug Mode set to: {mode}");
    }

    #endregion

    #region Initialization

    private void CreateBuffers()
    {
        voxels = new GraphicsBuffer(
            GraphicsBuffer.Target.Structured,
            maxVoxels,
            sizeof(uint)
        );
    }

    private void CreateRuntimeMaterial()
    {
        Shader.SetGlobalFloat("_DebugVisualizationMode", debugVisualizationMode);

        runtimeMaterial = new Material(voxelShader);
        runtimeMaterial.enableInstancing = true;

        runtimeMaterial.SetBuffer("_Voxels", voxels);
    }

    private void RegisterAllVolumesInScene()
    {
        var renderers = FindObjectsOfType<Renderer>();

        foreach (var renderer in renderers)
        {
            RegisterVolume(renderer);
        }
    }

    #endregion

    // TODO copy unmodified array to new space for modification on modification
    // TODO respond to grid bounds changing, etc

    #region Volume Deregistration

    public Boolean DeregisterVolume(GameObject gameObject)
    {
        if (gameObject == null) return false;
        Renderer renderer = gameObject.GetComponent<Renderer>();
        return DeregisterVolume(renderer);
    }

    public Boolean DeregisterVolume(Renderer renderer)
    {
        if (renderer == null) return false;

        var mpb = new MaterialPropertyBlock();
        renderer.GetPropertyBlock(mpb);
        if (!mpb.HasProperty("_VoxelVolumeID")) return false;
        long volumeId = (long)mpb.GetFloat("_VoxelVolumeID");

        return Free(volumeId);
    }

    #endregion

    #region Volume Registration

    public Boolean RegisterVolume(GameObject gameObject)
    {
        if (gameObject == null) return false;
        Renderer renderer = gameObject.GetComponent<Renderer>();
        return RegisterVolume(renderer);
    }

    public Boolean RegisterVolume(Renderer renderer)
    {
        if (renderer == null) return false;
        var mat = renderer.sharedMaterial;
        if (mat == null) return false;
        if (mat.shader != voxelShader) return false;
        VoxelVolumeBaker voxelVolume = renderer.GetComponentInParent<VoxelVolumeBaker>();
        if (voxelVolume == null) return false;
        String originalVoxelTextureId = voxelVolume.originalVoxelTextureId;
        Boolean modified = voxelVolume.modified;

        RegisterVolume(renderer, mat, originalVoxelTextureId, modified);
        return true;
    }

    private void RegisterVolume(Renderer renderer, Material sourceMaterial, String sourceTopologyId, Boolean modified)
    {
        Texture3D colorTex = sourceMaterial.GetTexture("_ColorTexture") as Texture3D;
        Texture3D hitTex = sourceMaterial.GetTexture("_HitTexture") as Texture3D;
        Vector3 gridDims = sourceMaterial.GetVector("_GridDimensions");

        int width = (int)gridDims.x;
        int height = (int)gridDims.y;
        int depth = (int)gridDims.z;

        int size = width * height * depth;

        int offset = -1;
        long id = 0;

        // Memory sharing only used for unmodified voxels
        Boolean usesSharedMemSpace = false;
        if (sourceTopologyIdToAllocationId.TryGetValue(sourceTopologyId, out long existingSharedAllocationId))
        {
            if (allocations.TryGetValue(existingSharedAllocationId, out Allocation existingSharedAllocation))
            {
                if ((existingSharedAllocation.size == size) && (!modified))
                {
                    totalVolumes++;
                    sharedMemoryVolumeRiders++;
                    if (existingSharedAllocation.consumers == 1)
                    {
                        sharedAllocations++;
                    }

                    offset = existingSharedAllocation.offset;
                    id = existingSharedAllocationId;
                    existingSharedAllocation.consumers = existingSharedAllocation.consumers + 1;
                    allocations[existingSharedAllocationId] = existingSharedAllocation;
                    usesSharedMemSpace = true;
                }
                else
                {
                    Debug.LogWarning("Found unmodified shared allocation, but it was a different size. ID: " + sourceTopologyId 
                        + ", Sizes: " + size + " vs " + existingSharedAllocation.size + ". Assigning new allocation.");
                }
            }
        }

        if (!usesSharedMemSpace)
        {
            offset = Allocate(size, out id);
            UploadVoxelData(offset, size, colorTex, hitTex);
            if (!modified)
            {
                sourceTopologyIdToAllocationId[sourceTopologyId] = id;
            }
        }

        var mpb = new MaterialPropertyBlock();
        renderer.GetPropertyBlock(mpb);

        mpb.SetInt("_VoxelVolumeOffset", offset);
        mpb.SetFloat("_VoxelVolumeID", id);
        mpb.SetVector("_GridDimensions", gridDims);

        renderer.sharedMaterial = runtimeMaterial;
        renderer.SetPropertyBlock(mpb);
    }

    private void UploadVoxelData(int offset, int size, Texture3D colorTex, Texture3D hitTex)
    {
        var colors = colorTex.GetPixelData<Color32>(0);
        var hits = hitTex.GetPixelData<byte>(0);

        uint[] packedValues = new uint[size];

        for (int i = 0; i < size; i++)
        {
            Color32 c = colors[i];
            byte h = hits[i];
            packedValues[i] =
                ((uint)h ) |
                ((uint)c.b << 8) |
                ((uint)c.g << 16) |
                ((uint)c.r << 24);
        }

        voxels.SetData(packedValues, 0, offset, size);
    }

    #endregion

    #region Allocation

    private int Allocate(int requestedSize, out long id)
    {
        totalVolumes++;

        // 1. Search free regions
        freeRegions.Sort((a, b) =>
        {
            int sizeCompare = a.size.CompareTo(b.size);
            if (sizeCompare != 0) return sizeCompare;
            return a.offset.CompareTo(b.offset);
        });

        foreach (var region in freeRegions)
        {
            if (region.size >= requestedSize)
            {
                RemoveFreeRegion(region.offset, region.size);

                int remainder = region.size - requestedSize;

                if (remainder > 0)
                {
                    AddFreeRegion(region.offset + requestedSize, remainder);
                }
                freeSum -= requestedSize;

                id = nextVoxelVolumeID++;
                allocations[id] = new Allocation
                {
                    offset = region.offset,
                    size = requestedSize,
                    consumers = 1
                };

                UpdateDebugStats();
                return region.offset;
            }
        }

        // 2. Try tail allocation
        if (allocationsTail + requestedSize <= maxVoxels)
        {
            int offset = allocationsTail;
            allocationsTail += requestedSize;

            id = nextVoxelVolumeID++;
            allocations[id] = new Allocation
            {
                offset = offset,
                size = requestedSize,
                consumers = 1
            };

            UpdateDebugStats();
            return offset;
        }

        throw new Exception("VoxelVolumeRegistry: Out of voxel buffer memory.");
    }

    public bool Free(long voxelVolumeID)
    {
        if (!allocations.TryGetValue(voxelVolumeID, out var alloc))
            return false;

        totalVolumes--;
        alloc.consumers--;

        if (alloc.consumers > 0)
        {
            sharedMemoryVolumeRiders--;
            if (alloc.consumers == 1)
            {
                sharedAllocations--;
            }

            allocations[voxelVolumeID] = alloc;
            return false;
        }

            allocations.Remove(voxelVolumeID);

        int newOffset = alloc.offset;
        int newSize = alloc.size;
        freeSum += newSize;

        int endIndex = alloc.offset + alloc.size - 1;

        // Merge with previous
        if (endingFreeOffsetsToSize.TryGetValue(alloc.offset - 1, out int prevSize))
        {
            int prevOffset = alloc.offset - prevSize;
            RemoveFreeRegion(prevOffset, prevSize);
            newOffset = prevOffset;
            newSize += prevSize;
        }

        // Merge with next
        if (startingFreeOffsetsToSize.TryGetValue(endIndex + 1, out int nextSize))
        {
            RemoveFreeRegion(endIndex + 1, nextSize);
            newSize += nextSize;
        }

        AddFreeRegion(newOffset, newSize);

        UpdateDebugStats();
        return true;
    }

    private void AddFreeRegion(int offset, int size)
    {
        freeRegions.Add((offset, size));
        startingFreeOffsetsToSize[offset] = size;
        endingFreeOffsetsToSize[offset + size - 1] = size;
    }

    private void RemoveFreeRegion(int offset, int size)
    {
        freeRegions.Remove((offset, size));
        startingFreeOffsetsToSize.Remove(offset);
        endingFreeOffsetsToSize.Remove(offset + size - 1);
    }

    #endregion

    #region Debug Stats

    private void UpdateDebugStats()
    {
        totalAllocations = allocations.Count;
        uniqueAllocations = totalAllocations - sharedAllocations;
        sharedMemoryVolumes = sharedMemoryVolumeRiders + sharedAllocations;

        uniqueAllocationPercent = totalAllocations == 0
            ? 0
            : (float)uniqueAllocations / totalAllocations * 100f;

        usagePercent = allocationsTail == 0
            ? 0
            : (float)allocationsTail / maxVoxels * 100f;

        fragmentationPercent = allocationsTail == 0
            ? 0
            : (float)freeSum / allocationsTail * 100f;
    }

    #endregion
}
