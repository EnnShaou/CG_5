Shader "Unlit/Test02_Fixed"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SubTex ("Sub Texture", 2D) = "white" {}
        _MaskTex ("Mask Texture", 2D) = "black" {}

        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _SpecTex ("Specular Map", 2D) = "white" {}
        _Shininess ("Shininess", Range(1,64)) = 16
        _MainColor ("Main Color", Color) = (1,1,1,1)
        _SubColor  ("Sub Color", Color)  = (1,1,1,1)
        _SpecIntensity ("Spec Intensity", Range(0,2)) = 1
        _SpecRange ("Specular Range", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags 
        { 
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

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
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _SubTex;
            sampler2D _MaskTex;
            sampler2D _SpecTex;

            float4 _MainTex_ST;
            float4 _SpecTex_ST;

            float4 _SpecColor;
            float _Shininess;

            float4 _MainColor;
            float4 _SubColor;
            float _SpecIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // ===== Texture Blend =====
                fixed4 main = tex2D(_MainTex, i.uv * _MainTex_ST.xx) * _MainColor;
                fixed4 sub  = tex2D(_SubTex, i.uv ) * _SubColor;
                fixed4 mask = tex2D(_MaskTex, i.uv);

                fixed4 col = lerp(main, sub, mask.r);

                // ===== Lighting vectors =====
                float3 N = normalize(i.worldNormal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 H = normalize(L + V);

                // ===== Specular =====
                float specMask = tex2D(_SpecTex, i.uv).r;
                float spec = pow(saturate(dot(N, H)), _Shininess);

                fixed3 specular = spec * specMask * _SpecColor.rgb * _SpecIntensity;

                // ===== Final =====
                fixed4 finalColor;
                finalColor.rgb = col.rgb + specular;
                finalColor.a   = col.a*_SpecColor.a;

                return finalColor;
            }
            ENDCG
        }
    }
}
