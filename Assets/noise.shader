Shader "Custom/Noise_Perlin_FBM"
{
    Properties
    {
        [MainColor] _BaseColor ("Base Color", Color) = (1,1,1,1)
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}

        _NoiseScale ("Noise Scale", Range(1,50)) = 10
        _NoiseStrength ("Noise Strength", Range(0,1)) = 1
        _Octaves ("FBM Octaves", Range(1,6)) = 4
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _NoiseScale;
                float _NoiseStrength;
                int _Octaves;
            CBUFFER_END

            // =========================
            // Perlin Noise
            // =========================

            float2 hash2(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)),
                           dot(p, float2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453) * 2 - 1;
            }

            float fade(float t)
            {
                return t * t * t * (t * (t * 6 - 15) + 10);
            }

            float perlinNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);

                float2 g00 = hash2(i);
                float2 g10 = hash2(i + float2(1, 0));
                float2 g01 = hash2(i + float2(0, 1));
                float2 g11 = hash2(i + float2(1, 1));

                float n00 = dot(g00, f);
                float n10 = dot(g10, f - float2(1, 0));
                float n01 = dot(g01, f - float2(0, 1));
                float n11 = dot(g11, f - float2(1, 1));

                float2 u = float2(fade(f.x), fade(f.y));

                return lerp(
                    lerp(n00, n10, u.x),
                    lerp(n01, n11, u.x),
                    u.y
                );
            }

            // =========================
            // Fractal Sum (FBM)
            // =========================

            float fbm(float2 p)
            {
                float value = 0.0;
                float amplitude = 0.5;
                float frequency = 1.0;

                for (int i = 0; i < _Octaves; i++)
                {
                    value += amplitude * perlinNoise(p * frequency);
                    frequency *= 2.0;
                    amplitude *= 0.5;
                }

                return value;
            }

            // =========================

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half4 col =
                    SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv)
                    * _BaseColor;

                float2 noiseUV = IN.uv * _NoiseScale;

                // フラクタル和
                float noise = fbm(noiseUV);

                // 映射到 0~1
                noise = noise * 0.5 + 0.5;

                col.rgb = lerp(col.rgb, col.rgb * noise, _NoiseStrength);

                return col;
            }
            ENDHLSL
        }
    }
}
