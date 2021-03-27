#line 2 "Decals.fx"
#include "shaders/RaCommon.fx"

// UNIFORM INPUTS
float4x4 worldViewProjection : WorldViewProjection;
float4x3 instanceTransformations[10]: InstanceTransformations;
float4x4 shadowTransformations[10] : ShadowTransformations;
float4 shadowViewPortMaps[10] : ShadowViewPortMaps;

float4 ambientColor : AmbientColor;
float4 sunColor : SunColor;
float4 sunDirection : SunDirection;
float4 worldCamPos : WorldCamPos;

float2 decalFadeDistanceAndInterval : DecalFadeDistanceAndInterval = float2(100.f, 30.f);

texture texture0: TEXLAYER0;
texture texture1: HemiMapTexture;
texture shadowMapTex: ShadowMapTex;

texture normalMap: NormalMap;

sampler sampler0 = sampler_state
{
    Texture = (texture0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

sampler sampler1 = sampler_state
{
    Texture = (texture1);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

sampler sampler2 = sampler_state
{
    Texture = (normalMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

struct appdata
{
    float4 Pos                            : POSITION;
    float4 Normal                         : NORMAL;
    float4 Tangent                        : TANGENT;
    float4 Binormal                       : BINORMAL;
    float4 Color                          : COLOR;
    float4 TexCoordsInstanceIndexAndAlpha : TEXCOORD0;
};

struct OUT_vsDecal
{
    float4 HPos     : POSITION;
    float2 Texture0 : TEXCOORD0;
    float3 Color    : TEXCOORD1;
    float3 Diffuse  : TEXCOORD2;
    float4 Alpha    : COLOR0;
    float Fog    : FOG;
};

OUT_vsDecal vsDecal(appdata input)
{
    OUT_vsDecal Out;

    int index = input.TexCoordsInstanceIndexAndAlpha.z;

    float3 Pos = mul(input.Pos, instanceTransformations[index]);
    Out.HPos = mul(float4(Pos.xyz, 1.0f), worldViewProjection);

    float3 worldNorm = mul(input.Normal.xyz, (float3x3)instanceTransformations[index]);
    Out.Diffuse = saturate(dot(worldNorm, -sunDirection)) * sunColor;

    float alpha = 1.0f - saturate((Out.HPos.z - decalFadeDistanceAndInterval.x) / decalFadeDistanceAndInterval.y);
    alpha *= input.TexCoordsInstanceIndexAndAlpha.w;
    Out.Alpha = alpha;
    Out.Color = input.Color;

    Out.Texture0 = input.TexCoordsInstanceIndexAndAlpha.xy;

    Out.Fog = calcFog(Out.HPos.w);

    return Out;
}

float4 psDecal(OUT_vsDecal indata) : COLOR
{
    float3 lighting =  ambientColor + indata.Diffuse;
    float4 outColor = tex2D(sampler0, indata.Texture0);

    outColor.rgb *= indata.Color * lighting;
    outColor.a *= indata.Alpha;
    return outColor;
}



struct OUT_vsDecalShadowed
{
    float4 HPos        : POSITION;
    float2 Texture0    : TEXCOORD0;
    float4 TexShadow   : TEXCOORD1;
    float4 ViewPortMap : TEXCOORD2;
    float3 Color       : TEXCOORD3;
    float3 Diffuse     : TEXCOORD4;
    float4 Alpha       : COLOR0;
    float Fog       : FOG;
};

struct OUT_vsDecalNormalMapped
{
    float4 HPos       : POSITION;
    float2 Texture0   : TEXCOORD0;
    float3 TanHalfVec : TEXCOORD1;
    float3 TanSunDir  : TEXCOORD2;
    float3 TanEyeVec  : TEXCOORD4;
    float3 Color      : TEXCOORD3;
    float4 Alpha      : COLOR0;
    float Fog      : FOG;
};

OUT_vsDecalShadowed vsDecalShadowed(appdata input)
{
    OUT_vsDecalShadowed Out;

    int index = input.TexCoordsInstanceIndexAndAlpha.z;

    float3 Pos = mul(input.Pos, instanceTransformations[index]);
    Out.HPos = mul(float4(Pos.xyz, 1.0f), worldViewProjection);

    float3 worldNorm = mul(input.Normal.xyz, (float3x3)instanceTransformations[index]);
    Out.Diffuse = saturate(dot(worldNorm, -sunDirection)) * sunColor;

    float3 color = input.Color;
    float alpha = 1.0f - saturate((Out.HPos.z - decalFadeDistanceAndInterval.x)/decalFadeDistanceAndInterval.y);
    alpha *= input.TexCoordsInstanceIndexAndAlpha.w;

    Out.Alpha = alpha;
    Out.Color = color;
    Out.ViewPortMap = 0.0;
    Out.TexShadow = 0.0;
    Out.TexShadow.z -= 0.007;
    Out.Texture0 = input.TexCoordsInstanceIndexAndAlpha.xy;
    Out.Fog = calcFog(Out.HPos.w);

    return Out;
}

OUT_vsDecalNormalMapped vsDecalNormalMapped(appdata input)
{
    OUT_vsDecalNormalMapped Out;

    int index = input.TexCoordsInstanceIndexAndAlpha.z;

    float3 Pos = mul(input.Pos, instanceTransformations[index]);
    float3 Tan = normalize(mul(input.Tangent.xyz, (float3x3)instanceTransformations[index]));
    float3 Binormal = normalize(mul(-input.Binormal.xyz, (float3x3)instanceTransformations[index]));
    float3 worldNorm = normalize(mul(input.Normal.xyz, (float3x3)instanceTransformations[index]));
    Out.HPos = mul(float4(Pos.xyz, 1.0f), worldViewProjection);

    float3x3 worldTanMatrix = float3x3(input.Tangent.xyz, -input.Binormal.xyz, input.Normal.xyz);

    float3 sunDir = mul(-sunDirection, instanceTransformations[index]);

    float3x3 worldI = transpose(mul(worldTanMatrix, instanceTransformations[index]));

    float alpha = 1.0f - saturate((Out.HPos.z - decalFadeDistanceAndInterval.x)/decalFadeDistanceAndInterval.y);
    alpha *= input.TexCoordsInstanceIndexAndAlpha.w;
    Out.Alpha = alpha;

    Out.Color = input.Color;
    Out.TanSunDir = normalize(mul(-sunDirection, worldI));

    float3 centerPos = mul(Pos.xyz, instanceTransformations[index]);
    float3 centerEyeVec = normalize(mul((worldCamPos - centerPos), worldI));

    float3 tanEyeVec = normalize(mul((worldCamPos - Pos), worldI));
    Out.TanEyeVec = tanEyeVec;

    float3 halfVec = normalize(Out.TanSunDir + tanEyeVec);
    Out.TanHalfVec = halfVec;

    Out.Texture0 = input.TexCoordsInstanceIndexAndAlpha.xy;
    Out.Fog = calcFog(Out.HPos.w);

    return Out;
}

float4 psDecalShadowed(	OUT_vsDecalShadowed indata) : COLOR
{
    float dirShadow = 1.0;
    float4 outColor = tex2D(sampler0, indata.Texture0);
    outColor.rgb *=  indata.Color;
    outColor.a *= indata.Alpha;
    float3 lighting = ambientColor.rgb + indata.Diffuse * dirShadow;
    outColor.rgb *= lighting;
    return outColor;
}

float4 psDecalNormalMapped(	OUT_vsDecalNormalMapped indata) : COLOR
{
    float2 newTexCoord = indata.Texture0;
    float4 norm = tex2D(sampler2, float2(newTexCoord.x, newTexCoord.y));
    norm.rgb = normalize((norm.rgb * 2.0) - 1.0);
    float3 sun = normalize(float3(indata.TanSunDir.x, -indata.TanSunDir.y, indata.TanSunDir.z));
    float light = saturate(dot(norm.rgb, sun));
    float spec = saturate(dot(norm.rgb, normalize(float3(indata.TanHalfVec.x, -indata.TanHalfVec.y, indata.TanHalfVec.z))));
    spec *= spec * spec;

    float4 outColor = tex2D(sampler0, newTexCoord);

    float4 finalColor = outColor;
    finalColor.a *= indata.Alpha;
    finalColor.rgb *= (ambientColor.rgb + light * sunColor.rgb + spec*norm.a);
    return finalColor;
}

technique Decal
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_TANGENT, 0},
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_BINORMAL, 0},
        { 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0 },
        { 0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_TEXCOORD, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaTestEnable = TRUE;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        AlphaRef = 0;
        AlphaFunc = GREATER;
        CullMode = CW;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = TRUE;

        VertexShader = compile vs_2_0 vsDecal();
        PixelShader = compile ps_2_0 psDecal();
    }

    pass p1
    {
        AlphaTestEnable = TRUE;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        AlphaRef = 0;
        AlphaFunc = GREATER;
        CullMode = CW;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = TRUE;

        VertexShader = compile vs_2_0 vsDecalShadowed();
        PixelShader = compile ps_2_0 psDecalShadowed();
    }

    pass p2
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        AlphaFunc = GREATER;
        CullMode = CW;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = TRUE;

        VertexShader = compile vs_2_0 vsDecalNormalMapped();
        PixelShader  = compile ps_2_0 psDecalNormalMapped();
    }
}

