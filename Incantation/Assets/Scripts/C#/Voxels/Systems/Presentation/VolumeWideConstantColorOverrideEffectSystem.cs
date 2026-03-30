using Incantation.Engine.Voxels.Components;
using System.Runtime.CompilerServices;
using Unity.Burst;
using Unity.Collections;
using Unity.Entities;
using Unity.Jobs;
using Unity.Mathematics;

namespace Incantation.Engine.Voxels.Systems
{
    [UpdateInGroup(typeof(PresentationSystemGroup))]
    [BurstCompile]
    public partial struct VolumeWideConstantColorOverrideEffectSystem : ISystem
    {
        [BurstCompile]
        public void OnUpdate(ref SystemState state)
        {
            float deltaTimeMs = state.WorldUnmanaged.Time.DeltaTime * 1000f; // Convert seconds to milliseconds

            var ecb = new EntityCommandBuffer(Allocator.Temp);

            foreach (var (effectsRO, overrideColor, entity) in
                     SystemAPI.Query<DynamicBuffer<VolumeWideConstantColorOverrideEffect>, RefRW<VolumeWideConstantColorOverride>>()
                               .WithEntityAccess())
            {
                var effects = effectsRO;

                uint maxAlpha = 0;
                uint3 maxAlphaColor = new uint3(0, 0, 0);

                for (var i = effects.Length - 1; i >= 0; i--)
                {
                    var eff = effects[i];

                    // 1. Subtract deltaTime
                    eff.remainingTime -= deltaTimeMs;

                    // 2. Transition from easing to completion
                    if ((eff.remainingTime <= 0) && (eff.Easing))
                    {
                        eff.Easing = false;
                        eff.remainingTime = eff.completionDuration - math.abs(eff.remainingTime);
                    }

                    // 3. Handle completion functions
                    if ((eff.remainingTime <= 0) && (!eff.Easing))
                    {
                        switch (eff.completionFunction)
                        {
                            case CompletionFunction.REPEAT:
                                eff.remainingTime = eff.easingDuration - math.abs(eff.remainingTime);
                                eff.Easing = true;
                                break;

                            case CompletionFunction.REMOVE:
                                effects.RemoveAt(i);
                                continue;
                        }
                    }

                    if (eff.Easing)
                    {
                        // 4. Compute blend fraction
                        float blend = eff.easingDuration > 0 ? (float)eff.remainingTime / eff.easingDuration : 1f;
                        blend = math.saturate(1.0f - blend);

                        // 5. Apply InOut if needed
                        if (eff.InOut)
                        {
                            blend *= 2;
                            blend = (blend > 1) ? 1 - (blend - 1) : blend;
                        }

                        // 6. Apply easing function
                        blend = ApplyEasing(blend, eff.easingFunction);

                        // 7. Interpolate alpha and update override
                        uint alpha = (uint)math.lerp(eff.startAlpha, eff.endAlpha, blend);

                        // 8. For multiple effects simultaenously, max wins
                        if (alpha > maxAlpha)
                        {
                            maxAlpha = alpha;
                            maxAlphaColor = new uint3(eff.R, eff.G, eff.B);
                        }
                    }

                    effects[i] = eff;
                }

                if (maxAlpha > 0.0f)
                {
                    ref var ovr = ref overrideColor.ValueRW;

                    ovr.A = maxAlpha;
                    ovr.R = maxAlphaColor.x;
                    ovr.G = maxAlphaColor.y;
                    ovr.B = maxAlphaColor.z;
                }
            }

            ecb.Playback(state.EntityManager);
            ecb.Dispose();
        }

        // Easing implementations
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        private static float ApplyEasing(float t, EasingFunction easing)
        {
            switch (easing)
            {
                default:
                case EasingFunction.LINEAR: return t;

                case EasingFunction.QUAD: return t * t;

                case EasingFunction.CUBIC: return t * t * t;

                case EasingFunction.SINE: return 1f - math.cos(t * math.PI / 2f);
            }
        }
    }
}