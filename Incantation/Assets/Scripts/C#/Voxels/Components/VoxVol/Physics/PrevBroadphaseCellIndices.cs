using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using Unity.Entities;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components.Physics.RigidBody
{
    // Values represent cell indices where the AABB extents fall.
    // This should cover all cells occupied by this AABB.
    public struct PrevBroadphaseCellIndices : IComponentData
    {
        public uint minExtentCellIndex;
        public uint maxExtentCellIndex;
    }
}