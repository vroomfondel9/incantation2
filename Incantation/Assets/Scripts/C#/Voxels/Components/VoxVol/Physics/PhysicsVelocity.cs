using Unity.Entities;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components.Physics.RigidBody
{
    // Values in world space
    public struct PhysicsVelocity : IComponentData
    {
        public float3 Linear;
        public float3 Angular;
    }
}