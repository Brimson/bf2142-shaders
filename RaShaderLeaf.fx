
// Speed to always add to wind, decrease for less movement
#define WIND_ADD 5
#define LEAF_MOVEMENT 1024

#ifndef _HASSHADOW_
    #define _HASSHADOW_ 0
#endif

#include "shaders/RaCommon.fx"
#include "Shaders/Math.fx"

float4   OverGrowthAmbient;
Light  Lights[1];
float4   PosUnpack;
float2   NormalUnpack;
float TexUnpack;
float ObjRadius = 2;

struct VS_OUTPUT
{
    float4 Pos   : POSITION0;
    float2 Tex0  : TEXCOORD0;
    float3 tex1  : TEXCOORD1;
    #if _HASSHADOW_
        float4 TexShadow : TEXCOORD2;
    #endif
    float4 Color : COLOR0;
    float Fog : FOG;
};

texture	DiffuseMap;
sampler DiffuseMapSampler = sampler_state
{
    Texture = (DiffuseMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = WRAP;
    AddressV = WRAP;
    MipMapLodBias = 0;
};

// INPUTS TO THE VERTEX SHADER FROM THE APP
string reqVertexElement[] =
{
    #ifdef OVERGROWTH // tl: TODO - Compress overgrowth patches as well.
        "Position",
        "Normal",
        "TBase2D"
    #else
        "PositionPacked",
        "NormalPacked8",
        "TBasePacked2D"
    #endif
};

VS_OUTPUT basicVertexShader
(
    float4 inPos  : POSITION0,
    float3 normal : NORMAL,
    float2 tex0   : TEXCOORD0
)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    #ifndef OVERGROWTH
        inPos *= PosUnpack;
        WindSpeed += WIND_ADD;
        inPos.xyz +=  sin((GlobalTime / (ObjRadius + inPos.y)) * WindSpeed) * (ObjRadius + inPos.y) * (ObjRadius + inPos.y) / LEAF_MOVEMENT;// *  WindSpeed / 16384;//clamp(abs(inPos.z * inPos.x), 0, WindSpeed);
    #endif

    Out.Pos	= mul1(inPos, WorldViewProjection);

    Out.Fog	= calcFog(Out.Pos.w);
    Out.Tex0.xy = tex0;

    #ifdef OVERGROWTH
        Out.Tex0.xy /= 32767.0f;
        normal = normal * 2.0f - 1.0f;
    #else
        normal = normal * NormalUnpack.x + NormalUnpack.y;
        Out.Tex0.xy *= TexUnpack;
    #endif

    #ifdef _POINTLIGHT_
        float3 lightVec = float3(Lights[0].pos.xyz - inPos);
        float LdotN	= 1.0;
    #else
        float LdotN = saturate((dot(normal, -Lights[0].dir) + 0.6) / 1.4);
    #endif

    #ifdef OVERGROWTH
        Out.Color.rgb = Lights[0].color * (inPos.w / 32767) * LdotN* (inPos.w / 32767);
        OverGrowthAmbient *= (inPos.w / 32767);
    #else
        Out.Color.rgb = Lights[0].color * LdotN;
    #endif

    Out.tex1 = 0.0;

    #if _HASSHADOW_
        Out.TexShadow = calcShadowProjection(float4(inPos.xyz, 1.0));
        Out.tex1 = CEXP(OverGrowthAmbient.rgb) * 0.5;
    #elif !defined(_POINTLIGHT_)
        Out.tex1 = OverGrowthAmbient.rgb * 1/CEXP(1);
    #endif

    #ifdef _POINTLIGHT_
        Out.Color.rgb *= 1.0 - saturate(dot(lightVec, lightVec) * Lights[0].attenuation);
        Out.Color.rgb *= calcFog(Out.Pos.w);
    #endif

    #if defined(OVERGROWTH) && HASALPHA2MASK
        Out.Color.a = Transparency.a * 2.0;
    #else
        Out.Color.a = Transparency.a;
    #endif

    Out.Color = Out.Color * 0.5;

    return Out;
}

float4 basicPixelShader(VS_OUTPUT VsOut) : COLOR
{
    float4 diffuseMap = tex2D(DiffuseMapSampler, VsOut.Tex0.xy);

    #if _HASSHADOW_
        float4 vertexColor = float4(VsOut.Color.rgb, VsOut.Color.a * 2.0);
        vertexColor.rgb *= getShadowFactor(ShadowMapSampler, VsOut.TexShadow, 1, 20);
        vertexColor.rgb += VsOut.tex1;
    #else
        float4 vertexColor = float4(VsOut.Color.rgb, VsOut.Color.a*2);
        vertexColor.rgb += VsOut.tex1;
    #endif

    //tl: use compressed color register to avoid this being compiled as a 2.0 shader.
    float4 outCol = diffuseMap * vertexColor * 2.0;

    return outCol;
};

string GlobalParameters[] =
{
    #if _HASSHADOW_
        "ShadowMap",
    #endif
        "GlobalTime",
        "FogRange",
    #ifndef _POINTLIGHT_
        "FogColor",
    #endif
};

string InstanceParameters[] =
{
    #if _HASSHADOW_
        "ShadowProjMat",
        "ShadowTrapMat",
    #endif
        "WorldViewProjection",
        "World",
        "Transparency",
        "WindSpeed",
        "Lights",
    #ifndef _POINTLIGHT_
        "OverGrowthAmbient"
    #endif
};

string TemplateParameters[] =
{
    "DiffuseMap",
    "PosUnpack",
    "NormalUnpack",
    "TexUnpack"
};

float4 basicPixelShader_other(VS_OUTPUT input) : COLOR
{
    // tex2Dproj() ?
    float4 diffuseMap = tex2D(DiffuseMapSampler, input.Tex0);
    float4 shadowMap = tex2D(ShadowMapSampler, input.tex1);
    float4 output;
    output.xyz = input.Color * shadowMap * 4.0;
    output.xyz += OverGrowthAmbient;
    output.xyz *= diffuseMap;
    output.w += (input.Color.w * diffuseMap.w * 4.0);
    #if defined(OVERGROWTH) && HASALPHA2MASK
        output.w *= diffuseMap.w * 2.0;
    #endif
}

float4 basicPixelShader_other_nomask(VS_OUTPUT input) : COLOR
{
    float4 diffuseMap = tex2D(DiffuseMapSampler, input.Tex0);
    float4 output;

    #ifdef _POINTLIGHT_
        output.rgb = input.Color + input.Color;
        output.a = input.Color.a;
        output = diffuseMap * output;
    #else
        output = diffuseMap * input.Color * 4.0;
    #endif

    #if defined(OVERGROWTH) && HASALPHA2MASK
        output.a = output.a * diffuseMap.a * 4.0;
    #endif

    return output;
}

technique defaultTechnique
{
    pass P0
    {
        VertexShader = compile vs_2_0 basicVertexShader();

        #if _HASSHADOW_
            #if !NVIDIA
                PixelShader = compile ps_2_0 basicPixelShader();
            #else
                PixelShader = compile ps_2_0 basicPixelShader_other();
            #endif
        #else
            #if 1//HASALPHA2MASK
                PixelShader	= compile ps_2_0 basicPixelShader();
            #else
                PixelShader = compile ps_2_0 basicPixelShader_other_nomask();
            #endif
        #endif

        #ifdef ENABLE_WIREFRAME
            FillMode = WireFrame;
        #endif

        #if HASALPHA2MASK
            Alpha2Mask = 1;
        #endif

        AlphaTestEnable = true;
        AlphaRef        = 127;
        SrcBlend        = < srcBlend >;
        DestBlend       = < destBlend >;

        #ifdef _POINTLIGHT_
            FogEnable        = false;
            AlphaBlendEnable = true;
            SrcBlend         = one;
            DestBlend        = one;
        #else
            AlphaBlendEnable = false;
            FogEnable        = true;
        #endif

        CullMode			= NONE;
    }
}
