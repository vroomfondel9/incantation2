using Unity.Entities;
using Unity.Mathematics;
using Unity.Rendering;
using System.Runtime.CompilerServices;

namespace Incantation.Engine.Voxels.Components
{
    /*
        GridDimensions packing layout (MSB → LSB)

        31..........24 | 23......16 | 15.......8 | 7.......0
        -----------------------------------------------------
            unused         X byte        Y byte       Z byte

        Stored as a packed uint.

        The uint bits are reinterpreted as a float using math.asfloat()
        so Shader Graph can receive the value through a float property.

        CPU access should always go through the provided accessors.

        Shader unpack example:

            uint bits = asuint(_GridDimensions);

            uint x = (bits >> 16) & 0xFF;
            uint y = (bits >> 8)  & 0xFF;
            uint z = bits & 0xFF;
    */

    [MaterialProperty("_GridDimensions")]
    public struct GridDimensions : IComponentData
    {
        public float floatValue;

        const int X_SHIFT = 16;
        const int Y_SHIFT = 8;
        const int Z_SHIFT = 0;

        const uint BYTE_MASK = 0xFFu;

        /*--------------------------------------------------------------
        Raw packed uint access
        --------------------------------------------------------------*/

        public uint Packed
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get => math.asuint(floatValue);

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set => floatValue = math.asfloat(value);
        }

        /*--------------------------------------------------------------
        X component
        --------------------------------------------------------------*/

        public uint X
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get
            {
                return ((math.asuint(floatValue) >> X_SHIFT) & BYTE_MASK);
            }

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                uint bits = math.asuint(floatValue);
                bits = (bits & ~(BYTE_MASK << X_SHIFT)) | (value << X_SHIFT);
                floatValue = math.asfloat(bits);
            }
        }

        /*--------------------------------------------------------------
        Y component
        --------------------------------------------------------------*/

        public uint Y
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get
            {
                return ((math.asuint(floatValue) >> Y_SHIFT) & BYTE_MASK);
            }

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                uint bits = math.asuint(floatValue);
                bits = (bits & ~(BYTE_MASK << Y_SHIFT)) | (value << Y_SHIFT);
                floatValue = math.asfloat(bits);
            }
        }

        /*--------------------------------------------------------------
        Z component
        --------------------------------------------------------------*/

        public uint Z
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get
            {
                return ((math.asuint(floatValue) >> Z_SHIFT) & BYTE_MASK);
            }

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                uint bits = math.asuint(floatValue);
                bits = (bits & ~(BYTE_MASK << Z_SHIFT)) | (value << Z_SHIFT);
                floatValue = math.asfloat(bits);
            }
        }

        /*--------------------------------------------------------------
        uint3 accessor
        --------------------------------------------------------------*/

        public uint3 XYZ
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get
            {
                uint bits = math.asuint(floatValue);

                return new uint3(
                    (bits >> X_SHIFT) & BYTE_MASK,
                    (bits >> Y_SHIFT) & BYTE_MASK,
                    (bits >> Z_SHIFT) & BYTE_MASK
                );
            }

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                uint packed =
                    ((value.x & BYTE_MASK) << X_SHIFT) |
                    ((value.y & BYTE_MASK) << Y_SHIFT) |
                    ((value.z & BYTE_MASK) << Z_SHIFT);

                floatValue = math.asfloat(packed);
            }
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public GridDimensions(uint x, uint y, uint z)
        {
            uint packed =
                (x << X_SHIFT) |
                (y << Y_SHIFT) |
                (z << Z_SHIFT);

            floatValue = math.asfloat(packed);
        }
    }
}