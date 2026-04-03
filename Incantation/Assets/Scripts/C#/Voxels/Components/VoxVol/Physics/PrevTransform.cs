using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using Unity.Entities;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components.Physics.RigidBody
{
    // The LocalTransform from the previous physics step. Used to
    // compute how far a Rigid Body has moved since the last simulation step
    // and whether continuous collision detection is needed
    public struct PrevTransform : IComponentData
    {
        public float3 Position;
        public quaternion Rotation;
    }
}