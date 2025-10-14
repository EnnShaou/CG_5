Shader "Unlit/NewUnlitShader"
{
    Properties{
        
            _Color("Color",Color)=(0,0,0,0)
        }
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"//¹âÔ´(É«¤Ê¤É)
            fixed4 _Color;
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
               float4 vertex : SV_POSITION;
               float4 worldPosition : TEXCOORD1;
               float3 normal : NORMAL;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
               
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 eyeDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition);
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                i.normal = normalize(i.normal);
                float3 reflectDir = -lightDir+ 2 * i.normal * dot(i.normal,lightDir);
                fixed4 specular = pow(saturate(dot(reflectDir,eyeDir)),20)*_LightColor0;
                return specular * _Color;
            }
            ENDCG
        }
    }
}
