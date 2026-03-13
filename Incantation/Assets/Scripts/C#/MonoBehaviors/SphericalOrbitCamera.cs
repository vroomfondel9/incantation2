using UnityEngine;

public class SphericalOrbitCamera : MonoBehaviour
{
    [Header("Rotation Settings")]
    public bool clockwise = true;

    public bool lockedX = false;
    public bool lockedY = true;
    public bool lockedZ = false;

    [Range(1, 60)]
    public uint revolutionTime = 15;

    public float starupDelay = 0.5f;

    private float startTime;
    private bool startedMoving = false;

    private float sphereRadius;
    private float angle;

    void Start()
    {
        startTime = Time.time;
    }

    void Update()
    {
        EnforceSingleAxisLock();

        if (!startedMoving)
        {
            if (Time.time - startTime >= starupDelay)
            {
                sphereRadius = transform.position.magnitude;
                InitializeAngleFromCurrentPosition();
                startedMoving = true;
            }
            return;
        }

        if (!AnyAxisLocked())
            return;

        float angularSpeed = (2f * Mathf.PI) / Mathf.Max(1f, revolutionTime);

        if (clockwise)
            angle -= angularSpeed * Time.deltaTime;
        else
            angle += angularSpeed * Time.deltaTime;

        UpdatePosition();
        transform.LookAt(Vector3.zero);
    }

    void EnforceSingleAxisLock()
    {
        if (lockedX)
        {
            lockedY = false;
            lockedZ = false;
        }
        else if (lockedY)
        {
            lockedX = false;
            lockedZ = false;
        }
        else if (lockedZ)
        {
            lockedX = false;
            lockedY = false;
        }
    }

    bool AnyAxisLocked()
    {
        return lockedX || lockedY || lockedZ;
    }

    void InitializeAngleFromCurrentPosition()
    {
        Vector3 pos = transform.position;

        if (lockedX)
            angle = Mathf.Atan2(pos.z, pos.y);
        else if (lockedY)
            angle = Mathf.Atan2(pos.x, pos.z);
        else if (lockedZ)
            angle = Mathf.Atan2(pos.y, pos.x);
    }

    void UpdatePosition()
    {
        Vector3 pos = transform.position;

        if (lockedX)
        {
            float x = pos.x;
            float r = Mathf.Sqrt(Mathf.Max(0f, sphereRadius * sphereRadius - x * x));

            float y = r * Mathf.Cos(angle);
            float z = r * Mathf.Sin(angle);

            transform.position = new Vector3(x, y, z);
        }
        else if (lockedY)
        {
            float y = pos.y;
            float r = Mathf.Sqrt(Mathf.Max(0f, sphereRadius * sphereRadius - y * y));

            float x = r * Mathf.Cos(angle);
            float z = r * Mathf.Sin(angle);

            transform.position = new Vector3(x, y, z);
        }
        else if (lockedZ)
        {
            float z = pos.z;
            float r = Mathf.Sqrt(Mathf.Max(0f, sphereRadius * sphereRadius - z * z));

            float x = r * Mathf.Cos(angle);
            float y = r * Mathf.Sin(angle);

            transform.position = new Vector3(x, y, z);
        }
    }
}
