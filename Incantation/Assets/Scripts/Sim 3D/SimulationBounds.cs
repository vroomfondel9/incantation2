using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Mathematics;

/* The area in which the simulation takes place. Defines the bounds of the simulation.
 * This is similar to the parent simulation's transform, but it's aware of the uniform grid
 * and automatically reshapes itself to the closest power of two of the grid, to ensure it can
 * always be evenly divided.*/
public class SimulationBounds
{
    float gridCellSize;
    uint3 gridDimensions;

    Vector3 position;
    Quaternion rotation;
    Vector3 parentScale;

    public SimulationBounds(Transform parentTransform, float gridCellSize) 
    {
        bool created = create(parentTransform, gridCellSize);

        if (!created) throw new ArgumentException("Invalid simulation bounds provided. Probably gridCellSize is 0.");
    }

    public bool update(Transform parentTransform, float gridCellSize)
    {
        bool updated = false;

        if (needsUpdate(parentTransform, gridCellSize))
        {
            updated = create(parentTransform, gridCellSize);
        }

        return updated;
    }

    private bool isValid(Transform parentTransform, float gridCellSize)
    {
        return gridCellSize != 0;
    }

    private bool create(Transform parentTransform, float gridCellSize)
    {
        bool valid = isValid(parentTransform, gridCellSize);

        if (valid)
        {
            this.gridCellSize = math.abs(gridCellSize);

            uint3 dimensionsFractional = new uint3(
                (uint)math.floor(parentTransform.localScale.x / gridCellSize),
                (uint)math.floor(parentTransform.localScale.y / gridCellSize),
                (uint)math.floor(parentTransform.localScale.z / gridCellSize)
            );
            int3 prevLog2 = math.floorlog2(dimensionsFractional);
            this.gridDimensions = new uint3(
                (uint)Mathf.Pow(2, prevLog2.x),
                (uint)Mathf.Pow(2, prevLog2.y),
                (uint)Mathf.Pow(2, prevLog2.z)
            );

            this.position = parentTransform.position;
            this.rotation = parentTransform.rotation;
            this.parentScale = math.abs(parentTransform.localScale);
        }
        else
        {
            Debug.LogWarning("Invalid simulation bounds provided. Ignoring.");
        }

        return valid;
    }

    private bool needsUpdate(Transform parentTransform, float gridCellSize)
    {
        return ((this.position != parentTransform.position) ||
                (this.rotation != parentTransform.rotation) ||
                    (this.parentScale != parentTransform.localScale) ||
                        (this.gridCellSize != gridCellSize));
    }

    public uint3 getDimensions()
    {
        return this.gridDimensions;
    }

    public uint getCellTotal()
    {
        return this.gridDimensions.x * this.gridDimensions.y * this.gridDimensions.z;
    }

    public Vector3 getPosition()
    {
        return this.position;
    }

    public Quaternion getRotation()
    {
        return this.rotation;
    }

    public Vector3 getScale()
    {
        return new Vector3(
            this.gridDimensions.x * this.gridCellSize,
            this.gridDimensions.y * this.gridCellSize,
            this.gridDimensions.z * this.gridCellSize
        );
    }

    public Matrix4x4 getLocalToWorldMatrix()
    {
        Matrix4x4 lToW = new Matrix4x4();
        lToW.SetTRS(getPosition(), getRotation(), getScale());

        return lToW;
    }

    public Matrix4x4 getWorldToLocalMatrix()
    {
        Matrix4x4 lToW = getLocalToWorldMatrix();
        return lToW.inverse;
    }

    public float getCellSize()
    {
        return this.gridCellSize;
    }
}
