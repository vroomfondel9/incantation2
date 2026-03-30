using System.Runtime.CompilerServices;
using Unity.Entities;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Components
{
    /*
     * Controls the transition between voxel base colors and a voxel volume-wide color
     * override. This effect is typically used together with the
     * VolumeWideConstantColorOverride material property component, which holds the
     * packed RGBA value sent to the shader.
     *
     * The effect defines how the alpha of the volume-wide color changes over time,
     * including easing behavior and what should happen when the transition completes.
     *
     * easingTime        : Duration of the easing phase (milliseconds).
     * completionTime    : Total time the override should stay after easing is complete before the completion function is called.
     * easingFunction    : The easing curve used to interpolate the transition.
     * flags             : LS bit stores `InOut`, LS bit +1 stores `isEasing`.
     * completionFunction: Determines what happens when completionTime is finished.
     */
    [InternalBufferCapacity(0)]
    public struct VolumeWideConstantColorOverrideEffect : IBufferElementData
    {
        public float easingDuration;
        public float completionDuration;
        public float remainingTime;
        public EasingFunction easingFunction;
        private byte flags;
        public CompletionFunction completionFunction;
        private byte endA;
        private byte startA;
        private byte r;
        private byte g;
        private byte b;

        // -----------------------------
        // Flag accessors (hot loop friendly)
        // -----------------------------

        const byte IN_OUT_BIT = 1 << 0; // LS bit
        const byte ISEASING_BIT = 1 << 1; // LS bit + 1

        public bool InOut
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get
            {
                return (flags & IN_OUT_BIT) != 0;
            }

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                flags = (byte)((flags & ~IN_OUT_BIT) | (value ? IN_OUT_BIT : 0));
            }
        }

        public bool Easing
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get
            {
                return (flags & ISEASING_BIT) != 0;
            }

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                flags = (byte)((flags & ~ISEASING_BIT) | (value ? ISEASING_BIT : 0));
            }
        }

        public uint endAlpha
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get
            {
                return (uint)endA;
            }

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                endA = (byte)value;
            }
        }

        public uint startAlpha
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get
            {
                return (uint)startA;
            }

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                startA = (byte)value;
            }
        }

        public uint R
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get
            {
                return (uint)r;
            }

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                r = (byte)value;
            }
        }

        public uint G
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get
            {
                return (uint)g;
            }

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                g = (byte)value;
            }
        }

        public uint B
        {
            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            readonly get
            {
                return (uint)b;
            }

            [MethodImpl(MethodImplOptions.AggressiveInlining)]
            set
            {
                b = (byte)value;
            }
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public VolumeWideConstantColorOverrideEffect(uint red, uint green, uint blue,
            float startAlpha, float endAlpha, bool inOut, int easingDur, EasingFunction easingFun, 
                int completionDur, CompletionFunction completionFun)
        {
            r = (byte)red;
            g = (byte)green;
            b = (byte)blue;

            startA = (byte)((uint)math.round(startAlpha * 255));
            endA = (byte)((uint)math.round(endAlpha * 255));

            flags = (byte)(inOut ? ISEASING_BIT | IN_OUT_BIT : ISEASING_BIT);

            easingDuration = easingDur;
            completionDuration = completionDur;
            remainingTime = easingDur;

            easingFunction = easingFun;
            completionFunction = completionFun;
        }
    }

    public enum EasingFunction : byte
    {
        LINEAR = 0,
        QUAD,
        CUBIC,
        SINE
    }

    public enum CompletionFunction : byte
    {
        REPEAT = 0,
        REMOVE
    }
}