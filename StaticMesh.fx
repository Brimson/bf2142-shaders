#line 2 "StaticMesh.fx"
#include "shaders/datatypes.fx"
#include "Shaders/commonVertexLight.fx"

// UNIFORM INPUTS
mat4x4 viewProjMatrix : WorldViewProjection;
mat4x4 worldViewMatrix : WorldView;
mat4x4 worldViewITMatrix : WorldViewIT;
mat4x4 viewInverseMatrix : ViewI;
mat4x4 worldMatrix : World;

vec4 ambColor : Ambient = { 0.0, 0.0, 0.0, 1.0 };
vec4 diffColor : Diffuse = { 1.0, 1.0, 1.0, 1.0 };
vec4 specColor : Specular = { 0.0, 0.0, 0.0, 1.0 };
vec4 fuzzyLightScaleValue : FuzzyLightScaleValue = { 1.75, 1.75, 1.75, 1.0 };
vec4 lightmapOffset : LightmapOffset;
scalar dropShadowClipheight : DROPSHADOWCLIPHEIGHT;
vec4 parallaxScaleBias : PARALLAXSCALEBIAS;

mat4x4 vpLightMat : vpLightMat;
mat4x4 vpLightTrapezMat : vpLightTrapezMat;
vec4 PosUnpack : POSUNPACK;
scalar TexUnpack : TEXUNPACK;

bool alphaTest : AlphaTest = false;

vec4 paraboloidValues : ParaboloidValues;
vec4 paraboloidZValues : ParaboloidZValues;

texture texture0: TEXLAYER0;
texture texture1: TEXLAYER1;
texture texture2: TEXLAYER2;
texture texture3: TEXLAYER3;
texture texture4: TEXLAYER4;
texture texture5: TEXLAYER5;
texture texture6: TEXLAYER6;
texture texture7: TEXLAYER7;

sampler samplerShadowAlpha = sampler_state
{
    Texture = <texture0>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

// sampler diffuseSampler = sampler_state
sampler samplerWrap0 = sampler_state
{
    Texture = <texture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

// sampler normalSampler = sampler_state
sampler samplerWrap1 = sampler_state
{
    Texture = <texture1>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap2 = sampler_state
{
    Texture = <texture2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap3 = sampler_state
{
    Texture = <texture3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap4 = sampler_state
{
    Texture = <texture4>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap5 = sampler_state
{
    Texture = <texture5>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap6 = sampler_state
{
    Texture = <texture6>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap7 = sampler_state
{
    Texture = <texture7>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrapAniso0 = sampler_state
{
    Texture = <texture0>;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerWrapAniso1 = sampler_state
{
    Texture = <texture1>;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerWrapAniso2 = sampler_state
{
    Texture = <texture2>;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrapAniso3 = sampler_state
{
    Texture = <texture3>;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerWrapAniso4 = sampler_state
{
    Texture = <texture4>;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerWrapAniso5 = sampler_state
{
    Texture = <texture5>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerWrapAniso6 = sampler_state
{
    Texture = <texture6>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerWrapAniso7 = sampler_state
{
    Texture = <texture7>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerClamp0 = sampler_state
{
    Texture = <texture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

// sampler normalSampler = sampler_state
sampler samplerClamp1 = sampler_state
{
    Texture = <texture1>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp2 = sampler_state
{
    Texture = <texture2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp3 = sampler_state
{
    Texture = <texture3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp4 = sampler_state
{
    Texture = <texture4>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp5 = sampler_state
{
    Texture = <texture5>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp6 = sampler_state
{
    Texture = <texture6>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp7 = sampler_state
{
    Texture = <texture7>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler sampler0clamppoint = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler1clamppoint = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler2clamppoint = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler3clamppoint = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler4clamppoint = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler5clamppoint = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler6clamppoint = sampler_state { Texture = (texture6); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };

sampler sampler0wrappoint = sampler_state { Texture = (texture0); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler1wrappoint = sampler_state { Texture = (texture1); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler2wrappoint = sampler_state { Texture = (texture2); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler3wrappoint = sampler_state { Texture = (texture3); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler4wrappoint = sampler_state { Texture = (texture4); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler5wrappoint = sampler_state { Texture = (texture5); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler6wrappoint = sampler_state { Texture = (texture6); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };

sampler colorLUTSampler = sampler_state
{
    Texture = <texture2>;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler dummySampler = sampler_state
{
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

vec4 lightPos : LightPosition  : register(vs_3_0, c12)
<
    string Object = "PointLight";
    string Space = "World";
> = { 0.0, 0.0, 1.0, 1.0 };

vec4 lightDir : LightDirection;
vec4 sunColor : SunColor;
vec4 eyePos : EyePos;
vec4 eyePosObjectSpace : EyePosObjectSpace;

struct appdata
{
    vec4 Pos : POSITION;
    vec3 Normal : NORMAL;
    vec2 TexCoord : TEXCOORD0;
    vec3 Tan    : TANGENT;
    vec3 Binorm : BINORMAL;
};

struct VS_OUTPUT
{
    vec4 HPos       : POSITION;
    vec2 NormalMap  : TEXCOORD0;
    vec3 LightVec   : TEXCOORD1;
    vec3 HalfVec    : TEXCOORD2;
    vec2 DiffMap    : TEXCOORD3;
};

struct VS_OUTPUTSS
{
    vec4 HPos       : POSITION;
    vec4 TanNormal  : COLOR0;
    vec4 TanLight   : COLOR1;
    vec2 NormalMap  : TEXCOORD0;
    vec3 LightVec   : TEXCOORD1;
    vec3 HalfVec    : TEXCOORD2;
    vec2 DiffMap    : TEXCOORD3;
};

struct VS_OUTPUT2
{
    vec4 HPos       : POSITION;
    vec2 TexCoord   : TEXCOORD0;
    vec4 Diffuse    : COLOR;
};

struct VS_OUTPUT3
{
    vec4 HPos       : POSITION;
    vec2 TexCoord   : TEXCOORD0;
};


VS_OUTPUT3 VSimpleShader(appdata input, uniform mat4x4 wvp)
{
    VS_OUTPUT3 outdata;
    outdata.HPos = mul(vec4(input.Pos.xyz, 1.0), wvp);
    outdata.TexCoord = input.TexCoord;
    return outdata;
}

float4 PSimpleShader(VS_OUTPUT3 input) : COLOR
{
    const float4 ambient = float4(1.0, 1.0, 1.0, 0.8);
    float4 NormalMap = tex2D(samplerWrap0, input.TexCoord);
    return NormalMap * ambient;
    /*
        NormalMap *= ambient;
        Normap.a *= ambient.x;
        return NormalMap;
    */
}

technique alpha_one
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = false;
        CullMode = NONE;
        AlphaBlendEnable = true;

        // SrcBlend = ONE;
        SrcBlend = SRCALPHA;
        DestBlend = ONE;

        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;
        // FillMode = WIREFRAME;

        VertexShader = compile vs_3_0 VSimpleShader(viewProjMatrix);
        PixelShader = compile ps_3_0 PSimpleShader();
    }
}

struct APPDATA_ShadowMap
{
    vec4 Pos : POSITION;
    vec2 Tex : TEXCOORD0;
};

struct VS2PS_ShadowMap
{
    vec4 Pos    : POSITION;
    vec2 PosZW  : TEXCOORD0;
};

struct VS2PS_ShadowMapAlpha
{
    vec4 Pos    : POSITION;
    vec2 Tex    : TEXCOORD0;
    vec2 PosZW  : TEXCOORD1;
};

vec4 calcShadowProjCoords(vec4 Pos, mat4x4 matTrap, mat4x4 matLight)
{
    vec4 shadowcoords = mul(Pos, matTrap);
    vec2 lightZW = mul(Pos, matLight).zw;
    shadowcoords.z = (lightZW.x * shadowcoords.w) / lightZW.y; // (zL*wT)/wL == zL/wL post homo
    return shadowcoords;
}

VS2PS_ShadowMap vsShadowMap(APPDATA_ShadowMap input)
{
    VS2PS_ShadowMap Out;
    vec4 unpackPos = vec4(input.Pos.xyz * PosUnpack, 1.0);
    vec4 wPos = mul(unpackPos, worldMatrix);
    Out.Pos = calcShadowProjCoords(wPos, vpLightTrapezMat, vpLightMat);
    Out.PosZW.xy = Out.Pos.zw;
    return Out;
}

VS2PS_ShadowMapAlpha vsShadowMapAlpha(APPDATA_ShadowMap input)
{
    VS2PS_ShadowMapAlpha Out;

    vec4 unpackPos = vec4(input.Pos.xyz * PosUnpack, 1.0);
    vec4 wPos = mul(unpackPos, worldMatrix);

    Out.Pos = calcShadowProjCoords(wPos, vpLightTrapezMat, vpLightMat);
    Out.PosZW.xy = Out.Pos.zw;
    Out.Tex = input.Tex * TexUnpack;

    return Out;
}

vec4 psShadowMap(VS2PS_ShadowMap indata) : COLOR
{
    // #if NVIDIA || NVIDIA_TYPE_SHADOW_SUPPORTED
    #if NVIDIA
        return 0;
    #else
        return indata.PosZW.x / indata.PosZW.y;
    #endif
}

vec4 psShadowMapAlpha(VS2PS_ShadowMapAlpha indata) : COLOR
{
    const float alphaRef = 96.0f / 255.0f;

    vec4 alpha = tex2D(samplerShadowAlpha, indata.Tex);

    //#if NVIDIA || NVIDIA_TYPE_SHADOW_SUPPORTED
    #if NVIDIA
        return alpha;
    #else
        clip(alpha.a - alphaRef);
        return indata.PosZW.x / indata.PosZW.y;
    #endif
}

VS2PS_ShadowMap vsShadowMapPoint(APPDATA_ShadowMap input)
{
    VS2PS_ShadowMap Out;

    // Compensate for lack of UBYTE4 on Geforce3
    // int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    // int IndexArray[4] = (int[4])IndexVector;

    vec4 oPos = input.Pos;//vec4(mul(input.Pos, mOneBoneSkinning[IndexArray[0]]), 1);
    //vec4 vPos = mul(oPos, viewProjMatrix);
    Out.Pos = mul(oPos, viewProjMatrix);

    Out.Pos.z *= paraboloidValues.x;
    Out.PosZW = Out.Pos.zwww * 0.1 + 0.5;

    scalar d = length(Out.Pos.xyz);
    Out.Pos.xyz /= d;
    Out.Pos.z += 1.0;
    Out.Pos.x /= Out.Pos.z;
    Out.Pos.y /= Out.Pos.z;
    Out.Pos.z = d * paraboloidZValues.x + paraboloidZValues.y;
    Out.Pos.w = 1.0;

    return Out;
}

vec4 psShadowMapPoint(VS2PS_ShadowMap indata) : COLOR
{
    clip(indata.PosZW.x - 0.5);
    return indata.PosZW.x - 0.5;
}

technique DrawShadowMap
{
    pass directionalspot
    {
        AlphaBlendEnable = FALSE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_3_0 vsShadowMap();
        PixelShader = compile ps_3_0 psShadowMap();
    }

    pass directionalspotalpha
    {
        AlphaBlendEnable = FALSE;

        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_3_0 vsShadowMapAlpha();
        PixelShader = compile ps_3_0 psShadowMapAlpha();
    }

    pass point
    {
        AlphaBlendEnable = FALSE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_3_0 vsShadowMapPoint();
        PixelShader = compile ps_3_0 psShadowMapPoint();
    }
}

// #if NVIDIA || NVIDIA_TYPE_SHADOW_SUPPORTED
#if NVIDIA
    technique DrawShadowMapNV
    {
        pass directionalspot
        {
            ColorWriteEnable = 0;//0x0000000F;

            AlphaTestEnable = FALSE;
            AlphaBlendEnable = FALSE;

            ZEnable = TRUE;
            ZWriteEnable = TRUE;
            ZFunc = LESSEQUAL;

            ScissorTestEnable = TRUE;

            VertexShader = compile vs_3_0 vsShadowMap();
            PixelShader = compile ps_3_0 psShadowMap();
        }

        pass directionalspotalpha
        {
            ColorWriteEnable = 0;//0x0000000F;

            AlphaTestEnable = TRUE;
            AlphaRef = 96;
            AlphaFunc = GREATER;
            AlphaBlendEnable = FALSE;

            ZEnable = TRUE;
            ZWriteEnable = TRUE;
            ZFunc = LESSEQUAL;

            ScissorTestEnable = TRUE;

            VertexShader = compile vs_3_0 vsShadowMapAlpha();
            PixelShader = compile ps_3_0 psShadowMapAlpha();
        }
    }
#endif

#include "Shaders/StaticMesh_nv3x.fx"
#include "Shaders/StaticMesh_nv3xpp.fx"
#include "Shaders/StaticMesh_r3x0.fx"
#include "Shaders/StaticMesh_editor.fx"
#include "Shaders/StaticMesh_debug.fx"
#include "Shaders/StaticMesh_lightmapgen.fx"
