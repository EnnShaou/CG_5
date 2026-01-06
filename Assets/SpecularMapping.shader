Shader "Unlit/NewUnlitShader_Fixed"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
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

            // ===== 顶点输入 =====
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv     : TEXCOORD0;
            };

            // ===== 顶点到片元 =====
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex   = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal   = UnityObjectToWorldNormal(v.normal);
                o.uv       = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 环境 / 漫反射 / 高光
                fixed4 aColor = _Color * 0.3;
                fixed4 dColor = _Color;
                fixed4 sColor = fixed4(1,1,1,1);

                float3 N = normalize(i.normal);
                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 H = normalize(L + V);

                float intensity = saturate(dot(N, H));
                float phong = pow(intensity, 20);

                fixed4 maskColor = tex2D(_MainTex, i.uv);

                fixed4 finalColor =
                    aColor +
                    dColor * intensity +
                    maskColor.r * phong * sColor;

                return finalColor;
            }
            ENDCG
        }
    }
}
