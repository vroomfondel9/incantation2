using System.Runtime.CompilerServices;
using Unity.Entities;
using Unity.Mathematics;
using Unity.Rendering;

namespace Incantation.Engine.Voxels.Components
{
    /*
     * Packed ARGB material override for the shader property "_VolumeWideColorOverride".
     *
     * The value is stored as a 32-bit packed integer reinterpreted as a float with the
     * following byte layout (MSB → LSB):
     *
     *     [ A | R | G | B ]
     *      31          0
     *
     * Meaning:
     *   bits 31–24 : Alpha
     *   bits 23–16 : Red
     *   bits 15–8  : Green
     *   bits 7–0   : Blue
     *
     * This component is typically paired with another ECS component named
     * VolumeWideConstantColorOverrideEffect which describes how this value changes
     * over time (blending, pulsing, fades, etc.). This component itself only stores
     * the GPU-facing packed value.
     */

    [MaterialProperty("_VolumeWideColorOverride")]
    public struct VolumeWideConstantColorOverride : IComponentData
    {
        public float packedValue;

        // Masks
        const uint A_MASK = 0xFF000000u;
        const uint R_MASK = 0x00FF0000u;
        const uint G_MASK = 0x0000FF00u;
        const uint B_MASK = 0x000000FFu;

        // Shifts
        const int A_SHIFT = 24;
        const int R_SHIFT = 16;
        const int G_SHIFT = 8;
        const int B_SHIFT = 0;

        // -----------------------------
        // Channel properties
        // -----------------------------

        public uint A
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            get => (math.asuint(packedValue) >> A_SHIFT) & 0xFFu;
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                uint v = math.asuint(packedValue);
                v = (v & ~A_MASK) | ((value & 0xFFu) << A_SHIFT);
                packedValue = math.asfloat(v);
            }
        }

        public uint R
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            get => (math.asuint(packedValue) >> R_SHIFT) & 0xFFu;
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                uint v = math.asuint(packedValue);
                v = (v & ~R_MASK) | ((value & 0xFFu) << R_SHIFT);
                packedValue = math.asfloat(v);
            }
        }

        public uint G
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            get => (math.asuint(packedValue) >> G_SHIFT) & 0xFFu;
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                uint v = math.asuint(packedValue);
                v = (v & ~G_MASK) | ((value & 0xFFu) << G_SHIFT);
                packedValue = math.asfloat(v);
            }
        }

        public uint B
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            get => (math.asuint(packedValue) >> B_SHIFT) & 0xFFu;
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                uint v = math.asuint(packedValue);
                v = (v & ~B_MASK) | ((value & 0xFFu) << B_SHIFT);
                packedValue = math.asfloat(v);
            }
        }

        // -----------------------------
        // Pack / Unpack Helpers
        // -----------------------------

        public static float Pack(uint r, uint g, uint b)
        {
            uint v = ((r & 0xFFu) << R_SHIFT) |
                     ((g & 0xFFu) << G_SHIFT) |
                     ((b & 0xFFu) << B_SHIFT);

            return math.asfloat(v);
        }

        public static uint PackUint(uint r, uint g, uint b)
        {
            return ((r & 0xFFu) << R_SHIFT) |
                   ((g & 0xFFu) << G_SHIFT) |
                   ((b & 0xFFu) << B_SHIFT);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public VolumeWideConstantColorOverride(uint r, uint g, uint b)
        {
            uint packed = ((r & 0xFFu) << R_SHIFT) |
                          ((g & 0xFFu) << G_SHIFT) |
                          ((b & 0xFFu) << B_SHIFT);

            packedValue = math.asfloat(packed);
        }
    }
}