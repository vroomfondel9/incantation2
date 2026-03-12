using Unity.Entities;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components.Physics.RigidBody
{
    public struct PhysicsMass : IComponentData
    {
        public float InverseMass;
        // Generally 3x3 matrix, but stored in principal-axis diagonal form which is just the diagonals of that matrix
        public float3 InverseInertia;
        // World coordinate offsets from center of volume
        public float3 CenterOfMass;
    }
}