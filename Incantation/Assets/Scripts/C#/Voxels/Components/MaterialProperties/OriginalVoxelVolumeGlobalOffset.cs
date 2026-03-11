using Unity.Entities;
using Unity.Mathematics;
using Unity.Rendering;
using System.Runtime.CompilerServices;

namespace Incantation.Engine.Voxels.Components
{
    /*
        OriginalVoxelVolumeGlobalOffset

        Purpose
        -------
        Represents a global offset into a voxel array. The value may span the
        entire uint range (0 → 4,294,967,295).

        Shader Graph only allows float material properties, so this value is
        stored internally as a float while actually representing a packed uint.

        The bits of the uint are reinterpreted as a float using math.asfloat()
        when sent to the GPU. No numeric conversion occurs — the bit pattern
        remains identical.

        Layout
        ------
        31...............................0
        ----------------------------------
                full 32-bit uint offset

        CPU access should always use the provided accessors to avoid treating
        the float value numerically.

        Shader unpack example:

            uint offset = asuint(_OriginalVoxelVolumeGlobalOffset);

        This restores the exact original uint with zero precision loss.
    */

    [MaterialProperty("_OriginalVoxelVolumeGlobalOffset")]
    public struct OriginalVoxelVolumeGlobalOffset : IComponentData
    {
        public float floatValue;

        /*--------------------------------------------------------------
        Raw packed uint access
        --------------------------------------------------------------*/

        public uint Value
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get => math.asuint(floatValue);

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set => floatValue = math.asfloat(value);
        }

        /*--------------------------------------------------------------
        Constructor
        --------------------------------------------------------------*/
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public OriginalVoxelVolumeGlobalOffset(uint value)
        {
            floatValue = math.asfloat(value);
        }
    }
}