#line 2 "Decals.fx"
#include "shaders/RaCommon.fx"

// UNIFORM INPUTS
mat4x4 worldViewProjection : WorldViewProjection;
mat4x3 instanceTransformations[10]: InstanceTransformations;
mat4x4 shadowTransformations[10] : ShadowTransformations;
vec4 shadowViewPortMaps[10] : ShadowViewPortMaps;

vec4 ambientColor : AmbientColor;
vec4 sunColor : SunColor;
vec4 sunDirection : SunDirection;
vec4 worldCamPos : WorldCamPos;

vec2 decalFadeDistanceAndInterval : DecalFadeDistanceAndInterval = vec2(100.f, 30.f);

texture texture0: TEXLAYER0;
texture texture1: HemiMapTexture;
texture shadowMapTex: ShadowMapTex;

texture normalMap: NormalMap;

sampler sampler0 = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler1 = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler2 = sampler_state { Texture = (normalMap); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

struct appdata
{
    vec4 Pos                            : POSITION;
    vec4 Normal                         : NORMAL;
    vec4 Tangent                        : TANGENT;
    vec4 Binormal                       : BINORMAL;
    vec4 Color                          : COLOR;
    vec4 TexCoordsInstanceIndexAndAlpha : TEXCOORD0;
};

struct OUT_vsDecal
{
    vec4 HPos     : POSITION;
    vec2 Texture0 : TEXCOORD0;
    vec3 Color    : TEXCOORD1;
    vec3 Diffuse  : TEXCOORD2;
    vec4 Alpha    : COLOR0;
    scalar Fog    : FOG;
};

OUT_vsDecal vsDecal(appdata input)
{
    OUT_vsDecal Out;

    int index = input.TexCoordsInstanceIndexAndAlpha.z;

    vec3 Pos = mul(input.Pos, instanceTransformations[index]);
    Out.HPos = mul(vec4(Pos.xyz, 1.0f), worldViewProjection);

    vec3 worldNorm = mul(input.Normal.xyz, (mat3x3)instanceTransformations[index]);
    Out.Diffuse = saturate(dot(worldNorm, -sunDirection)) * sunColor;

    scalar alpha = 1.0f - saturate((Out.HPos.z - decalFadeDistanceAndInterval.x)/decalFadeDistanceAndInterval.y);
    alpha *= input.TexCoordsInstanceIndexAndAlpha.w;
    Out.Alpha = alpha;
    Out.Color = input.Color;

    Out.Texture0 = input.TexCoordsInstanceIndexAndAlpha.xy;

    Out.Fog = calcFog(Out.HPos.w);

    return Out;
}

vec4 psDecal(	OUT_vsDecal indata) : COLOR
{
    vec3 lighting =  ambientColor + indata.Diffuse;
    vec4 outColor = tex2D(sampler0, indata.Texture0);

    outColor.rgb *= indata.Color * lighting;
    outColor.a *= indata.Alpha;
    return outColor;
}



struct OUT_vsDecalShadowed
{
    vec4 HPos        : POSITION;
    vec2 Texture0    : TEXCOORD0;
    vec4 TexShadow   : TEXCOORD1;
    vec4 ViewPortMap : TEXCOORD2;
    vec3 Color       : TEXCOORD3;
    vec3 Diffuse     : TEXCOORD4;
    vec4 Alpha       : COLOR0;
    scalar Fog       : FOG;
};

struct OUT_vsDecalNormalMapped
{
    vec4 HPos       : POSITION;
    vec2 Texture0   : TEXCOORD0;
    vec3 TanHalfVec : TEXCOORD1;
    vec3 TanSunDir  : TEXCOORD2;
    vec3 TanEyeVec  : TEXCOORD4;
    vec3 Color      : TEXCOORD3;
    vec4 Alpha      : COLOR0;
    scalar Fog      : FOG;
};

OUT_vsDecalShadowed vsDecalShadowed(appdata input)
{
    OUT_vsDecalShadowed Out;

    int index = input.TexCoordsInstanceIndexAndAlpha.z;

    vec3 Pos = mul(input.Pos, instanceTransformations[index]);
    Out.HPos = mul(vec4(Pos.xyz, 1.0f), worldViewProjection);

    vec3 worldNorm = mul(input.Normal.xyz, (mat3x3)instanceTransformations[index]);
    Out.Diffuse = saturate(dot(worldNorm, -sunDirection)) * sunColor;

    vec3 color = input.Color;
    scalar alpha = 1.0f - saturate((Out.HPos.z - decalFadeDistanceAndInterval.x)/decalFadeDistanceAndInterval.y);
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

    vec3 Pos = mul(input.Pos, instanceTransformations[index]);
    vec3 Tan = normalize(mul(input.Tangent.xyz, (mat3x3)instanceTransformations[index]));
    vec3 Binormal = normalize(mul(-input.Binormal.xyz, (mat3x3)instanceTransformations[index]));
    vec3 worldNorm = normalize(mul(input.Normal.xyz, (mat3x3)instanceTransformations[index]));
    Out.HPos = mul(vec4(Pos.xyz, 1.0f), worldViewProjection);

    float3x3 worldTanMatrix = float3x3(input.Tangent.xyz, -input.Binormal.xyz, input.Normal.xyz);

    vec3 sunDir = mul(-sunDirection, instanceTransformations[index]);

    mat3x3 worldI = transpose(mul(worldTanMatrix, instanceTransformations[index]));

    scalar alpha = 1.0f - saturate((Out.HPos.z - decalFadeDistanceAndInterval.x)/decalFadeDistanceAndInterval.y);
    alpha *= input.TexCoordsInstanceIndexAndAlpha.w;
    Out.Alpha = alpha;

    Out.Color = input.Color;
    Out.TanSunDir = normalize(mul(-sunDirection, worldI));

    vec3 centerPos = mul(Pos.xyz, instanceTransformations[index]);
    vec3 centerEyeVec = normalize(mul((worldCamPos - centerPos), worldI));

    vec3 tanEyeVec = normalize(mul((worldCamPos - Pos), worldI));
    Out.TanEyeVec = tanEyeVec;

    vec3 halfVec = normalize(Out.TanSunDir + tanEyeVec);
    Out.TanHalfVec = halfVec;

    Out.Texture0 = input.TexCoordsInstanceIndexAndAlpha.xy;
    Out.Fog = calcFog(Out.HPos.w);

    return Out;
}

vec4 psDecalShadowed(	OUT_vsDecalShadowed indata) : COLOR
{
    scalar dirShadow = 1.0;
    vec4 outColor = tex2D(sampler0, indata.Texture0);
    outColor.rgb *=  indata.Color;
    outColor.a *= indata.Alpha;
    vec3 lighting = ambientColor.rgb + indata.Diffuse * dirShadow;
    outColor.rgb *= lighting;
    return outColor;
}

vec4 psDecalNormalMapped(	OUT_vsDecalNormalMapped indata) : COLOR
{
    vec2 newTexCoord = indata.Texture0;
    vec4 norm = tex2D(sampler2, vec2(newTexCoord.x, newTexCoord.y));
    norm.rgb = normalize((norm.rgb * 2.0) - 1.0);
    vec3 sun = normalize(vec3(indata.TanSunDir.x, -indata.TanSunDir.y, indata.TanSunDir.z));
    float light = saturate(dot(norm.rgb, sun));
    float spec = saturate(dot(norm.rgb, normalize(vec3(indata.TanHalfVec.x, -indata.TanHalfVec.y, indata.TanHalfVec.z))));
    spec *= spec * spec;

    vec4 outColor = tex2D(sampler0, newTexCoord);

    vec4 finalColor = outColor;
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
        // FillMode = WireFrame;
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
        // FillMode = WireFrame;
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
        // FillMode = WireFrame;
        // AlphaTestEnable = TRUE;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        // AlphaRef = 0;
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

