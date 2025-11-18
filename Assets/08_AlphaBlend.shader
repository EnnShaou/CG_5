Shader "Unlit/08_AlphaBlend"
{
    Properties
    {
        _Color("Color",Color)=(1,1,1,0.3)
         _MainTex ("テクスチャ", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "Queue"="Transparent" }

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            // 顶点到片元结构体
             struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // 顶点着色器
            v2f vert(appdata v) 
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_Target
            {
                 fixed4 texColor = tex2D(_MainTex, i.uv);
                return _Color*texColor;
            }

            ENDCG
        }
    }
}
