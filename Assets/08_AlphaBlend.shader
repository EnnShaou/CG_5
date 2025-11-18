Shader "Unlit/08_AlphaBlend"
{
    Properties
    {
        _Color("Color",Color)=(1,1,1,0.3)
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

            // 顶点到片元结构体
            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            // 顶点着色器
            v2f vert(float4 v : POSITION)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v);
                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_Target
            {
                return _Color;
            }

            ENDCG
        }
    }
}
