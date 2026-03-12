using Unity.Entities;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components.Physics.RigidBody
{
    public struct PhysicsForce : IComponentData
    {
        public float3 Force;
        public float3 Torque;
    }
}