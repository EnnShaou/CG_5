Shader "Unlit/02_"
{
   Properties{
        
            _Color("Color",Color)=(1,1,1,1)
        }
    SubShader
    {
       

        Pass
        { 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"//光源(色など)
            fixed4 _Color;
            struct appdata
            {
            float4 vertex : POSITION; //頂点座標
            float3 normal : NORMAL; //法線
            };

            struct v2f
            {
            float4 vertex : SV_POSITION; //スクリーン座標
            float3 normal : NORMAL; //法線
            };

            v2f vert(appdata v){
               
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i):SV_Target{

                float intensity=saturate(dot(normalize(i.normal),_WorldSpaceLightPos0));
                
                return _Color * intensity * _LightColor0;
            }

            ENDCG
        }
    }
}
