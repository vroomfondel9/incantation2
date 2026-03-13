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

            foreach (var (effect, overrideColor, entity) in
                     SystemAPI.Query<RefRW<VolumeWideConstantColorOverrideEffect>, RefRW<VolumeWideConstantColorOverride>>()
                               .WithEntityAccess())
            {
                ref var eff = ref effect.ValueRW;
                ref var ovr = ref overrideColor.ValueRW;

                // 1. Subtract deltaTime
                eff.remainingTime -= (int)deltaTimeMs;

                // 2. Transition from easing to completion
                if ((eff.remainingTime <= 0) && (eff.Easing))
                {
                    eff.Easing = false;
                    eff.remainingTime = eff.completionDuration;
                }

                // 3. Handle completion functions
                if ((eff.remainingTime <= 0) && (!eff.Easing))
                {
                    switch (eff.completionFunction)
                    {
                        case CompletionFunction.REPEAT:
                            eff.remainingTime = eff.easingDuration;
                            eff.Easing = true;
                            break;

                        case CompletionFunction.REMOVE_EFFECT_ONLY:
                            ecb.RemoveComponent<VolumeWideConstantColorOverrideEffect>(entity);
                            continue;

                        case CompletionFunction.REMOVE:
                            ecb.RemoveComponent<VolumeWideConstantColorOverrideEffect>(entity);
                            ecb.RemoveComponent<VolumeWideConstantColorOverride>(entity);
                            continue;
                    }
                }

                if (eff.Easing)
                {
                    // 4. Compute blend fraction
                    float blendDenom = eff.Easing ? eff.easingDuration : eff.completionDuration;
                    float blend = blendDenom > 0 ? (float)eff.remainingTime / blendDenom : 1f;

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
                    ovr.A = alpha;
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