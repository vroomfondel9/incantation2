using UnityEngine;
using System.Collections.Generic;

[ExecuteAlways]
public class VoxelGridSpawner : MonoBehaviour
{
    [Header("Prefab")]
    public GameObject prefab = null;

    [Header("Grid Dimensions")]
    public Vector3Int dimensions = new Vector3Int(2, 2, 2);

    [Header("Spacing Between Objects (World Space)")]
    public Vector3 margins = Vector3.zero;

    [Header("Spaces the camera closer or farther away from computed framing value")]
    public float cameraDistanceMultiplier = 1.0f;

    [Header("Computed Values (Read Only)")]
    [SerializeField] private string voxelsPerObject = "0";
    [SerializeField] private string totalObjects = "0";
    [SerializeField] private string totalVoxels = "0";

    private readonly List<GameObject> spawnedObjects = new List<GameObject>();

    private Vector3 originalCameraPosition;
    private Quaternion originalCameraRotation;
    private bool cameraStateStored = false;

    private Camera mainCamera;

    void OnValidate()
    {
        dimensions.x = Mathf.Max(0, dimensions.x);
        dimensions.y = Mathf.Max(0, dimensions.y);
        dimensions.z = Mathf.Max(0, dimensions.z);

        UpdateTotals();
    }

    void UpdateTotals()
    {
        long objCount = (long)dimensions.x * dimensions.y * dimensions.z;
        totalObjects = objCount.ToString("N0");

        if (prefab == null)
        {
            totalVoxels = "-1";
            return;
        }

        Renderer renderer = prefab.GetComponentInChildren<Renderer>();
        if (renderer == null || renderer.sharedMaterial == null)
        {
            totalVoxels = "-1";
            return;
        }

        if (!renderer.sharedMaterial.HasProperty("_GridDimensions"))
        {
            totalVoxels = "-1";
            return;
        }

        Vector3 gridDims = renderer.sharedMaterial.GetVector("_GridDimensions");

        long voxPerObj =
            (long)gridDims.x *
            (long)gridDims.y *
            (long)gridDims.z;
        voxelsPerObject = voxPerObj.ToString("N0");

        long voxelCount = objCount * voxPerObj;
        totalVoxels = voxelCount.ToString("N0");

    }

    void Start()
    {
        if (!Application.isPlaying)
            return;

        if (prefab == null)
        {
            Debug.LogError("VoxelGridSpawner: Prefab is not assigned.");
            return;
        }

        UpdateTotals();
        SpawnGrid();
        FrameCamera();
    }

    void SpawnGrid()
    {
        Quaternion snappedRotation = SnapRotationTo90(prefab.transform.rotation);
        Vector3 prefabScale = prefab.transform.lossyScale;

        Vector3 objectSize = prefabScale;
        Vector3 spacing = objectSize + margins;

        Vector3 totalSize = new Vector3(
            (dimensions.x - 1) * spacing.x,
            (dimensions.y - 1) * spacing.y,
            (dimensions.z - 1) * spacing.z
        );

        Vector3 startOffset = -totalSize * 0.5f;

        for (int x = 0; x < dimensions.x; x++)
        {
            for (int y = 0; y < dimensions.y; y++)
            {
                for (int z = 0; z < dimensions.z; z++)
                {
                    Vector3 offset = new Vector3(
                        x * spacing.x,
                        y * spacing.y,
                        z * spacing.z
                    );

                    Vector3 worldPos = transform.position + startOffset + offset;

                    GameObject obj = Instantiate(prefab, worldPos, snappedRotation);
                    obj.transform.localScale = prefab.transform.localScale;

                    spawnedObjects.Add(obj);
                }
            }
        }

        prefab.SetActive(false);
    }

    void FrameCamera()
    {
        mainCamera = Camera.main;
        if (mainCamera == null)
            return;

        originalCameraPosition = mainCamera.transform.position;
        originalCameraRotation = mainCamera.transform.rotation;
        cameraStateStored = true;

        Quaternion snappedRotation = SnapRotationTo90(prefab.transform.rotation);
        Vector3 prefabScale = prefab.transform.lossyScale;
        Vector3 objectSize = prefabScale;
        Vector3 spacing = objectSize + margins;

        Vector3 totalSize = new Vector3(
            dimensions.x * spacing.x,
            dimensions.y * spacing.y,
            dimensions.z * spacing.z
        );

        Vector3 center = transform.position;

        // Half-extents of full grid
        Vector3 halfExtents = totalSize * 0.5f;

        // 3D hypotenuse (distance from center to far corner)
        float boundingRadius = halfExtents.magnitude;

        float distance;

        if (mainCamera.orthographic)
        {
            // For ortho, we need to fit vertical size.
            mainCamera.orthographicSize = boundingRadius;
            distance = 10f; // arbitrary depth offset
        }
        else
        {
            float fov = mainCamera.fieldOfView * Mathf.Deg2Rad;

            // Fit bounding sphere fully inside frustum
            distance = boundingRadius / Mathf.Sin(fov * 0.5f);
        }

        Vector3 cameraPos = center + Vector3.back * distance * cameraDistanceMultiplier;


        mainCamera.transform.position = cameraPos;
        mainCamera.transform.LookAt(center);
    }

    Quaternion SnapRotationTo90(Quaternion q)
    {
        Vector3 euler = q.eulerAngles;

        euler.x = Mathf.Round(euler.x / 90f) * 90f;
        euler.y = Mathf.Round(euler.y / 90f) * 90f;
        euler.z = Mathf.Round(euler.z / 90f) * 90f;

        return Quaternion.Euler(euler);
    }

    void OnDestroy()
    {
        if (!Application.isPlaying)
            return;

        Cleanup();
    }

    void OnApplicationQuit()
    {
        Cleanup();
    }

    void Cleanup()
    {
        foreach (var obj in spawnedObjects)
        {
            if (obj != null)
                Destroy(obj);
        }

        spawnedObjects.Clear();

        if (prefab != null)
            prefab.SetActive(true);

        if (cameraStateStored && mainCamera != null)
        {
            mainCamera.transform.position = originalCameraPosition;
            mainCamera.transform.rotation = originalCameraRotation;
        }
    }
}
