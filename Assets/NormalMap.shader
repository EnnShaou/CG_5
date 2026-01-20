Shader "Custom/NormalMap_URP"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalScale("Normal Strength", Range(0,2)) = 1
        _Smoothness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0

    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

     Pass
{
    Name "ForwardLit"
    Tags { "LightMode"="UniversalForward" }

    HLSLPROGRAM
    #pragma vertex vert
    #pragma fragment frag

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    struct Attributes
    {
        float4 positionOS : POSITION;
        float3 normalOS   : NORMAL;
        float4 tangentOS  : TANGENT;
        float2 uv         : TEXCOORD0;
    };

    struct Varyings
    {
        float4 positionHCS : SV_POSITION;
        float2 uv          : TEXCOORD0;
        float3 normalWS    : TEXCOORD1;
        float3 tangentWS   : TEXCOORD2;
        float3 bitangentWS : TEXCOORD3;
        float3 positionWS  : TEXCOORD4;
    };

    TEXTURE2D(_BaseMap);      SAMPLER(sampler_BaseMap);
    TEXTURE2D(_NormalMap);    SAMPLER(sampler_NormalMap);

    CBUFFER_START(UnityPerMaterial)
        half4 _BaseColor;
        float4 _BaseMap_ST;
        float  _NormalScale;
        float _Smoothness;
        float _Metallic;

    CBUFFER_END

    Varyings vert (Attributes IN)
    {
        Varyings OUT;
        OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
        OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

        OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
        OUT.normalWS   = TransformObjectToWorldNormal(IN.normalOS);
        OUT.tangentWS  = TransformObjectToWorldDir(IN.tangentOS.xyz);
        OUT.bitangentWS = cross(OUT.normalWS, OUT.tangentWS) * IN.tangentOS.w;

        return OUT;
    }

    half4 frag (Varyings IN) : SV_Target
{
    half3 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).rgb * _BaseColor.rgb;

    // Normal
    half3 normalTS = UnpackNormalScale(
        SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv),
        _NormalScale
    );

    half3x3 TBN = half3x3(
        normalize(IN.tangentWS),
        normalize(IN.bitangentWS),
        normalize(IN.normalWS)
    );
    half3 normalWS = normalize(mul(normalTS, TBN));

    half3 viewDir = normalize(GetWorldSpaceViewDir(IN.positionWS));

    // ===== PBR Parameters =====
    half perceptualRoughness = 1.0 - _Smoothness;
    half roughness = max(0.04, perceptualRoughness * perceptualRoughness);
    half3 F0 = lerp(0.04.xxx, albedo, _Metallic);

    // Main Light
    Light light = GetMainLight();
    half3 L = normalize(light.direction);
    half3 H = normalize(L + viewDir);

    half NdotL = saturate(dot(normalWS, L));
    half NdotV = saturate(dot(normalWS, viewDir));
    half NdotH = saturate(dot(normalWS, H));
    half VdotH = saturate(dot(viewDir, H));

    // GGX Normal Distribution
    half a2 = roughness * roughness;
    half D = a2 / (PI * pow(NdotH * NdotH * (a2 - 1) + 1, 2));

    // Smith Geometry
    half k = roughness * 0.5;
    half Gv = NdotV / (NdotV * (1 - k) + k);
    half Gl = NdotL / (NdotL * (1 - k) + k);
    half G = Gv * Gl;

    // Fresnel
    half3 F = F0 + (1 - F0) * pow(1 - VdotH, 5);

    half3 specular = (D * G * F) / max(0.001, 4 * NdotL * NdotV);

    half3 kS = F;
    half3 kD = (1 - kS) * (1 - _Metallic);

    half3 diffuse = kD * albedo / PI;

    // Direct lighting
    half3 direct = (diffuse + specular) * light.color * NdotL;

    // Indirect lighting
    half3 ambient = SampleSH(normalWS) * albedo;

    half3 finalColor = direct + ambient;
    return half4(finalColor, 1);
}


    ENDHLSL
}

    }
}