Shader "Unlit/BlendMaskSpecular"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _SubTex ("Sub Texture", 2D) = "white" {}
        _MaskTex ("Mask Texture", 2D) = "black" {}

        _SpecTex ("Specular Map", 2D) = "white" {}
        _SpecColor ("Specular Color", Color) = (0,0,0,0)
        _Shininess ("Shininess", Range(0, 64)) = 16

        _Mode ("Mode 0=Blend, 1=Mask, 2=Specular", Range(0,2)) = 0
    }

    SubShader
    {
        Tags {"RenderType"="Transparent" "Queue"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            //=====================================================
            // 数据结构
            //=====================================================
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
                float3 normal : NORMAL;
                float3 wPos: TEXCOORD1;
            };

            //=====================================================
            // 属性变量
            //=====================================================
            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _SubTex;
            sampler2D _MaskTex;

            sampler2D _SpecTex;
            float4 _SpecTex_ST;
            float4 _SpecColor;
            float _Shininess;

            float _Mode;

            //=====================================================
            // 顶点着色器
            //=====================================================
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
                return o;
            }

            //=====================================================
            // 像素着色器
            //=====================================================
            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 main = tex2D(_MainTex, i.uv);
                fixed4 sub  = tex2D(_SubTex,  i.uv);
                fixed4 mask = tex2D(_MaskTex, i.uv);

                //-------------------------------------------------
                // 模式 0：テクスチャブレンド
                //-------------------------------------------------
                if (_Mode == 0)
                {
                    return lerp(sub,main,mask.r);
                }

                //-------------------------------------------------
                // 模式 1：透明化マスク
                //-------------------------------------------------
                if (_Mode == 1)
                {
                    // mask.r 控制透明度，黑透明，白不透明
                   clip(0.5-mask.r);
                   return main;
                }

                //-------------------------------------------------
                // 模式 2：スペキュラマップ
                //-------------------------------------------------
                if (_Mode == 2)
                {
                    fixed4 aColor=_SpecColor*0.3;
                    fixed4 bColor=_SpecColor;
                    fixed4 sColor=fixed4(1,1,1,1);
                    float eyeDir=normalize(_WorldSpaceCameraPos.xyz - i.wPos);
                    float3 halfVec=normalize(_WorldSpaceLightPos0+eyeDir);
                    float intensity=saturate(dot(normalize(i.normal),halfVec));
                    float phong=pow(intensity,1);
                    fixed4 maskColor=tex2D(_SpecTex,i.uv*_SpecTex_ST.xy);

                    return aColor+bColor+intensity+maskColor.r*phong*sColor;
                }

                // 默认返回 main
                return main;
            }

            ENDCG
        }
    }
}
