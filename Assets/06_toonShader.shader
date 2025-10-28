Shader "Unlit/05_Fixed"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _DiffuseThreshold ("Diffuse Threshold", Range(0,1)) = 0.5
        _DiffuseThresMax ("Diffuse Thres Max", Range(0,0.5)) = 0.0
        _SpecularThresholdWidth("_SpecularThresholdWidth", Range(0,0.1))=0
        _SpecularThreshold ("Specular Threshold", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _DiffuseThreshold;
            float _DiffuseThresMax;
            float _SpecularThresholdWidth;
            float _SpecularThreshold;

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
                fixed4 ambient = _Color * 0.1;

                float intensity = saturate(dot(normalize(i.normal), _WorldSpaceLightPos0));
                intensity = smoothstep(_DiffuseThreshold, _DiffuseThreshold+_DiffuseThresMax, intensity);

                fixed4 diffuse = _Color * intensity * _LightColor0;

                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                i.normal = normalize(i.normal);

                float3 reflectDir = -lightDir+2*i.normal*dot(i.normal,lightDir);
                float spec = pow(saturate(dot(reflectDir, viewDir)), 20);
                spec = smoothstep(_SpecularThreshold, _SpecularThreshold + _SpecularThresholdWidth, spec);
                fixed4 specular = spec * _LightColor0;

                fixed4 texColor = tex2D(_MainTex, i.uv);

                fixed4 finalColor = (ambient + diffuse + specular) * texColor;

                return saturate(finalColor);
            }
            ENDCG
        }
    }
}
