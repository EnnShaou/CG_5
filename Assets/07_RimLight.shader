Shader "Unlit/05_Fixed_WithRim_Toggle"
{
    Properties
    {
        _MainTex ("テクスチャ", 2D) = "white" {}
        _Color ("基本色", Color) = (1,1,1,1)

        // --- ディフューズ設定 ---
        [Toggle(_USE_DIFFUSE)] _UseDiffuse("Diffuse", Float) = 1
        _DiffuseThreshold ("_DiffuseThreshold", Range(0,1)) = 0.5
        _DiffuseThresMax ("_DiffuseThresMax", Range(0,0.05)) = 0.0

        // --- スペキュラー設定 ---
        [Toggle(_USE_SPECULAR)] _UseSpecular("Specular", Float) = 1
        _SpecularThresholdWidth("_SpecularThresholdWidth", Range(0,0.1)) = 0
        _SpecularThreshold ("_SpecularThreshold", Range(0,1)) = 0.5

        // --- リムライト設定 ---
        [Toggle(_USE_RIM)] _UseRim("Rim", Float) = 1
        _RimColor("_RimColor", Color) = (1,1,1,1)
        _RimPower("_RimPower", Range(0.1,1)) = 0.7
        _RimIntensity("_RimIntensity", Range(0,2)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // --- 各トグルの分岐 ---
            #pragma multi_compile _ _USE_DIFFUSE
            #pragma multi_compile _ _USE_SPECULAR
            #pragma multi_compile _ _USE_RIM
            #pragma multi_compile _ _USE_AMBIENT

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;

            float _DiffuseThreshold;
            float _DiffuseThresMax;
            float _SpecularThresholdWidth;
            float _SpecularThreshold;

            fixed4 _RimColor;
            float _RimPower;
            float _RimIntensity;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // --- 基本設定 ---
                i.normal = normalize(i.normal);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                // --- 環境光 ---

                 fixed4   ambient = _Color * 0.1;
          

                // --- ディフューズ光 ---
                fixed4 diffuse = 0;
                #ifdef _USE_DIFFUSE
                    float intensity = saturate(dot(normalize(i.normal), _WorldSpaceLightPos0));
                    intensity = smoothstep(_DiffuseThreshold, _DiffuseThreshold + _DiffuseThresMax, intensity);
                    diffuse = _Color * intensity * _LightColor0;
                #endif

                // --- スペキュラー光 ---
                fixed4 specular = 0;
                #ifdef _USE_SPECULAR
                    float3 reflectDir = -lightDir + 2 * i.normal * dot(i.normal, lightDir);
                    float spec = pow(saturate(dot(reflectDir, viewDir)), 20);
                    spec = smoothstep(_SpecularThreshold, _SpecularThreshold + _SpecularThresholdWidth, spec);
                    specular = spec * _LightColor0;
                #endif

                // --- リムライト ---
                fixed4 rimLight = 0;
                #ifdef _USE_RIM
                    float rim = 1.0 - step(_RimPower, dot(viewDir, i.normal));
                    rimLight = _RimColor * rim * _RimIntensity;
                #endif

                // --- テクスチャ合成 ---
                fixed4 texColor = tex2D(_MainTex, i.uv);
                fixed4 finalColor = (ambient + diffuse + specular + rimLight) * texColor;

                return saturate(finalColor);
            }
            ENDCG
        }
    }
}
