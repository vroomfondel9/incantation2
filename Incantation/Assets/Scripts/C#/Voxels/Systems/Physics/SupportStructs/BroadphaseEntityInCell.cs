using Incantation.Engine.Voxels.Systems.Physics.Support;
using Unity.Entities;
namespace Incantation.Engine.Voxels.Systems.Physics.Support
{
    // In practice, this is used for queueing up removal requests because removal can't be done in parallel by design.
    public struct BroadphaseEntityInCell
    {
        public BroadphaseCell Cell;
        public Entity Entity;

        public BroadphaseEntityInCell(BroadphaseCell cell, Entity entity)
        {
            Cell = cell;
            Entity = entity;
        }
    }
}