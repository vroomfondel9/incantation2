using Unity.Entities;
using System;

namespace Incantation.Engine.Voxels.Systems.Physics.Support
{
    public struct PotentiallyCollidingPair : IEquatable<PotentiallyCollidingPair>
    {
        public Entity A;
        public Entity B;

        public PotentiallyCollidingPair(Entity a, Entity b)
        {
            if (a.Index < b.Index)
            {
                A = a;
                B = b;
            }
            else
            {
                A = b;
                B = a;
            }
        }

        public bool Equals(PotentiallyCollidingPair other)
        {
            return (A.Equals(other.A) && B.Equals(other.B)) ||
                   (A.Equals(other.B) && B.Equals(other.A));
        }

        public override bool Equals(object obj)
        {
            return obj is PotentiallyCollidingPair other && Equals(other);
        }

        public override int GetHashCode()
        {
            // Entity.GetHashCode() already mixes index + version
            int hashA = A.GetHashCode();
            int hashB = B.GetHashCode();

            // Commutative combination so (A,B) == (B,A)
            return hashA ^ hashB ^ (hashA + hashB);
        }
    }
}