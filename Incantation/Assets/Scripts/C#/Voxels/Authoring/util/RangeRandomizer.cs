using Incantation.Engine.Voxels.Authoring;
using Unity.Mathematics;
using UnityEngine;

namespace Incantation.Engine.Voxels.Authoring
{
    public static class RangeRandomizer
    {
        public static uint GlobalSeed = 0x9F6ABC1u;

        public static Unity.Mathematics.Random CreateRandom(Object obj)
        {
            uint objectHash = (uint)obj.GetInstanceID();
            uint seed = math.hash(new uint2(GlobalSeed, objectHash));

            if (seed == 0) seed = 1;

            return new Unity.Mathematics.Random(seed);
        }

        public static float3 RandomDirectionSpread(
            ref Unity.Mathematics.Random rng,
            float3 basis,
            RangeRandomization randomization,
            float2 minSpread,
            float2 maxSpread)
        {
            float magnitude = math.length(basis);

            if (magnitude == 0f)
            {
                return float3.zero;
            }

            float3 dir = math.normalize(basis);

            float2 spread = RandomFloat2(
                ref rng,
                randomization,
                minSpread,
                maxSpread);

            quaternion rot = math.mul(
                quaternion.RotateY(math.radians(spread.x)),
                quaternion.RotateX(math.radians(spread.y))
            );

            float3 rotated = math.rotate(rot, dir);

            return rotated * magnitude;
        }

        public static float3 RandomFloat3(
            ref Unity.Mathematics.Random rng,
            RangeRandomization mode,
            float3 min,
            float3 max)
        {
            switch (mode)
            {
                case RangeRandomization.None:
                    return min;

                case RangeRandomization.Uniform:
                    return rng.NextFloat3(min, max);

                case RangeRandomization.Gaussian:
                    return GaussianFloat3(ref rng, min, max);

                default:
                    return min;
            }
        }

        public static float2 RandomFloat2(
            ref Unity.Mathematics.Random rng,
            RangeRandomization mode,
            float2 min,
            float2 max)
        {
            switch (mode)
            {
                case RangeRandomization.None:
                    return min;

                case RangeRandomization.Uniform:
                    return rng.NextFloat2(min, max);

                case RangeRandomization.Gaussian:
                    return GaussianFloat2(ref rng, min, max);

                default:
                    return min;
            }
        }

        public static float RandomFloat(
            ref Unity.Mathematics.Random rng,
            RangeRandomization mode,
            float min,
            float max)
        {
            switch (mode)
            {
                case RangeRandomization.None:
                    return min;

                case RangeRandomization.Uniform:
                    return rng.NextFloat(min, max);

                case RangeRandomization.Gaussian:
                    return GaussianFloat(ref rng, min, max);

                default:
                    return min;
            }
        }

        public static long RandomLong(
            ref Unity.Mathematics.Random rng,
            RangeRandomization mode,
            long min,
            long max)
        {
            if (min == max)
                return min;

            switch (mode)
            {
                case RangeRandomization.None:
                    return min;

                case RangeRandomization.Uniform:
                    {
                        int value = rng.NextInt((int)min, (int)max + 1);
                        return value;
                    }

                case RangeRandomization.Gaussian:
                    {
                        float mean = (min + max) * 0.5f;
                        float sigma = (max - min) / 6f;

                        float g = Gaussian(ref rng, mean, sigma);
                        g = math.clamp(g, min, max);

                        return (long)math.round(g);
                    }

                default:
                    return min;
            }
        }

        static float3 GaussianFloat3(ref Unity.Mathematics.Random rng, float3 min, float3 max)
        {
            float3 mean = (min + max) * 0.5f;
            float3 sigma = (max - min) / 6f;

            return new float3(
                Gaussian(ref rng, mean.x, sigma.x),
                Gaussian(ref rng, mean.y, sigma.y),
                Gaussian(ref rng, mean.z, sigma.z)
            );
        }

        static float2 GaussianFloat2(ref Unity.Mathematics.Random rng, float2 min, float2 max)
        {
            float2 mean = (min + max) * 0.5f;
            float2 sigma = (max - min) / 6f;

            return new float2(
                Gaussian(ref rng, mean.x, sigma.x),
                Gaussian(ref rng, mean.y, sigma.y)
            );
        }

        static float GaussianFloat(ref Unity.Mathematics.Random rng, float min, float max)
        {
            float mean = (min + max) * 0.5f;
            float sigma = (max - min) / 6f;

            return Gaussian(ref rng, mean, sigma);
        }

        static float Gaussian(ref Unity.Mathematics.Random rng, float mean, float sigma)
        {
            float u1 = rng.NextFloat();
            float u2 = rng.NextFloat();

            float mag = math.sqrt(-2f * math.log(u1));
            float z0 = mag * math.cos(2f * math.PI * u2);

            return mean + sigma * z0;
        }
    }
}