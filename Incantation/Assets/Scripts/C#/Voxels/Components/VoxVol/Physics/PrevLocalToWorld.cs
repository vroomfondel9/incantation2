using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using Unity.Entities;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components.Physics.RigidBody
{
    // The LocalToWorld from the previous physics step. Used to
    // compute how far a Rigid Body has moved since the last simulation step
    // and whether continuous collision detection is needed
    public struct PrevLocalToWorld : IComponentData
    {
        public float4x4 Value;
    }
}