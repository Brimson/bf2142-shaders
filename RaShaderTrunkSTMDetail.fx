#include "shaders/dataTypes.fx"
#include "shaders/RaCommon.fx"

#ifndef _HASSHADOW_
    #define _HASSHADOW_ 0
#endif

vec4   OverGrowthAmbient;
Light  Lights[1];
vec4   PosUnpack;
vec2   NormalUnpack;
scalar TexUnpack;

struct VS_OUTPUT
{
    vec4 Pos   : POSITION0;
    vec2 Tex0  : TEXCOORD0;
    vec2 Tex1  : TEXCOORD1;
    #if _HASSHADOW_
        vec4 TexShadow : TEXCOORD2;
    #endif
    vec4 Color : COLOR0;
    scalar Fog : FOG;
};

texture	DetailMap;
sampler DetailMapSampler = sampler_state
{
    Texture = (DetailMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
    MipMapLodBias = 0;
};


texture	DiffuseMap;
sampler DiffuseMapSampler = sampler_state
{
    Texture = (DiffuseMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
    MipMapLodBias = 0;
};

// INPUTS TO THE VERTEX SHADER FROM THE APP
string reqVertexElement[] =
{
    "PositionPacked",
    "NormalPacked8",
    "TBasePacked2D"
    #ifndef BASEDIFFUSEONLY
        , "TDetailPacked2D"
    #endif
};

VS_OUTPUT basicVertexShader
(
    vec4 inPos  : POSITION0,
    vec3 normal : NORMAL,
    vec2 tex0   : TEXCOORD0
    #ifndef BASEDIFFUSEONLY
        , vec2 tex1 : TEXCOORD1
    #endif
)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    inPos  *= PosUnpack;
    Out.Pos = mul(vec4(inPos.xyz, 1.0), WorldViewProjection);

    Out.Fog  = calcFog(Out.Pos.w);
    Out.Tex0 = tex0 * TexUnpack;

    #ifndef BASEDIFFUSEONLY
        Out.Tex1 = tex1 * TexUnpack;
    #endif

    normal = normal * NormalUnpack.x + NormalUnpack.y;

    scalar LdotN = saturate(dot(normal, -Lights[0].dir));
    Out.Color.rgb = Lights[0].color * LdotN;
    Out.Color.a = Transparency;

    #if _HASSHADOW_
        Out.TexShadow = calcShadowProjection(vec4(inPos.xyz, 1.0));
    #else
        Out.Color.rgb += OverGrowthAmbient / exp(1.0);
    #endif

    Out.Color = Out.Color * 0.5;

    return Out;
}

vec4 basicPixelShader(VS_OUTPUT VsOut) : COLOR
{
    vec3 vertexColor = exp(VsOut.Color);

    #ifdef BASEDIFFUSEONLY
        vec4 diffuseMap = tex2D(DiffuseMapSampler, VsOut.Tex0);
    #else
        vec4 diffuseMap = tex2D(DiffuseMapSampler, VsOut.Tex0) * tex2D(DetailMapSampler, VsOut.Tex1);
    #endif

    #if _HASSHADOW_
        vertexColor.rgb *= getShadowFactor(ShadowMapSampler, VsOut.TexShadow, 1, PSVERSION);
        vertexColor.rgb += OverGrowthAmbient * 0.5;
    #endif

    //tl: use compressed color register to avoid this being compiled as a 2.0 shader.
    vec4 outColor = vec4(vertexColor.rgb * diffuseMap * 4.0, VsOut.Color.a * 2.0);

    return outColor;
};

string GlobalParameters[] =
{
    #if _HASSHADOW_
        "ShadowMap",
    #endif
    "FogRange",
    "FogColor"
};

string TemplateParameters[] =
{
    "PosUnpack",
    "NormalUnpack",
    "TexUnpack",
    "DiffuseMap"
    #ifndef BASEDIFFUSEONLY
        ,"DetailMap"
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
    "ViewProjection",
    "Transparency",
    "Lights",
    "OverGrowthAmbient"
};

// WIP: Need to fix overly bright ambient!

float4 basicPixelShader_other(VS_OUTPUT input) : COLOR
{
    float4 diffuseMap = tex2D(DiffuseMapSampler, input.Tex0);
    float4 detailMap = tex2D(DetailMapSampler, input.Tex1);
    float4 output;
    output.xyz = diffuseMap * detailMap;
    output.xyz = output * input.Color * 2.0;
    output.w = input.Color.w;
    return output;
}

technique defaultTechnique
{
    pass P0
    {
        VertexShader = compile vs_2_0 basicVertexShader();
        #if 1
            TextureTransFormFlags[2] = PROJECTED;
            PixelShader = compile ps_2_0 basicPixelShader();
        #else
            PixelShader = compile ps_2_0 basicPixelShader_other();
        #endif

        #ifdef ENABLE_WIREFRAME
            FillMode = WireFrame;
        #endif

        AlphaTestEnable = < AlphaTest >;
        AlphaRef        = 127; // temporary hack by johan because "m_shaderSettings.m_alphaTestRef = 127" somehow doesn't work
        fogenable       = true;
    }
}
