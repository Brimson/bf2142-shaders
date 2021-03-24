#line 2 "RoadCompiled.fx"
#include "shaders/raCommon.fx"

mat4x4	mWorldViewProj : WorldViewProjection;
scalar fTexBlendFactor : TexBlendFactor;
vec2 vFadeoutValues : FadeOut;
vec4 vLocalEyePos : LocalEye;
vec4 vCameraPos : CAMERAPOS;
scalar vScaleY : SCALEY;
vec4 vSunColor : SUNCOLOR;
vec4 vGIColor : GICOLOR;

vec4 vTexProjOffset : TEXPROJOFFSET;
vec4 vTexProjScale : TEXPROJSCALE;

texture detail0 : TEXLAYER3;
texture detail1 : TEXLAYER4;
texture lighting : TEXLAYER2;

sampler sampler0 = sampler_state
{
    Texture = (detail0);
    AddressU = CLAMP;
    AddressV = WRAP;
    MipFilter = FILTER_ROAD_MIP;
    MinFilter = FILTER_ROAD_DIFF_MIN;
    MagFilter = FILTER_ROAD_DIFF_MAG;
    #ifdef FILTER_ROAD_DIFF_MAX_ANISOTROPY
        MaxAnisotropy = FILTER_ROAD_DIFF_MAX_ANISOTROPY;
    #endif
};

sampler sampler1 = sampler_state
{
    Texture = (detail1);
    AddressU = WRAP;
    AddressV = WRAP;
    MipFilter = FILTER_ROAD_MIP;
    MinFilter = FILTER_ROAD_DIFF_MIN;
    MagFilter = FILTER_ROAD_DIFF_MAG;
    #ifdef FILTER_ROAD_DIFF_MAX_ANISOTROPY
        MaxAnisotropy = FILTER_ROAD_DIFF_MAX_ANISOTROPY;
    #endif
};

sampler sampler2 = sampler_state
{
    Texture = (lighting);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};

struct APP2VS
{
    vec4 Pos : POSITION;
    vec2 Tex0 : TEXCOORD0;
    vec2 Tex1 : TEXCOORD1;
    scalar Alpha : TEXCOORD2;
};

struct VS2PS
{
    vec4 Pos : POSITION;
    vec3 Tex0AndZFade : TEXCOORD0;
    vec2 Tex1 : TEXCOORD1;
    vec4 PosTex : TEXCOORD2;
    scalar Fog : FOG;
};

vec4 projToLighting(vec4 hPos)
{
    /*
        tl: This has been rearranged optimally (I believe) into 1 MUL and 1 MAD,
            don't change this without thinking twice.
            ProjOffset now includes screen->texture bias as well as half-texel offset
            ProjScale is screen->texture scale/invert operation
        tex = (hpos.x * 0.5 + 0.5 + htexel, hpos.y * -0.5 + 0.5 + htexel, hpos.z, hpos.w)
    */
    vec4 tex;
    tex = hPos * vTexProjScale + (vTexProjOffset * hPos.w);
    return tex;
}

VS2PS RoadCompiledVS(APP2VS input)
{
    VS2PS outdata;

    vec4 wPos = input.Pos;

    scalar cameraDist = length(vLocalEyePos - input.Pos);
    scalar interpVal = saturate(cameraDist * vFadeoutValues.x - vFadeoutValues.y);
    wPos.y += 0.01;

    outdata.Pos = mul(wPos, mWorldViewProj);
    outdata.PosTex = projToLighting(outdata.Pos);

    outdata.Tex0AndZFade.xy = input.Tex0;
    outdata.Tex1.xy = input.Tex1;

    outdata.Tex0AndZFade.z = 1.0 - saturate(cameraDist * vFadeoutValues.x - vFadeoutValues.y);
    outdata.Tex0AndZFade.z *= input.Alpha;

    outdata.Fog = calcFog(outdata.Pos.w);

    return outdata;
}

vec4 RoadCompiledPS(VS2PS indata) : COLOR0
{
    vec4 t0 = tex2D(sampler0, indata.Tex0AndZFade);
    vec4 t1 = tex2D(sampler1, indata.Tex1.xy * 0.1);
    vec4 accumlights = tex2Dproj(sampler2, indata.PosTex);
    vec4 light = ((accumlights.w * vSunColor * 2.0) + accumlights) * 2.0;

    vec4 final;
    final.rgb = lerp(t1, t0, fTexBlendFactor);
    final.a = t0.a * indata.Tex0AndZFade.z;
    final.rgb *= light.xyz;
    return final;
}

struct VS2PSDx9
{
    vec4 Pos          : POSITION;
    vec3 Tex0AndZFade : TEXCOORD0;
    vec2 Tex1         : TEXCOORD1;
};

VS2PSDx9 RoadCompiledVSDx9(APP2VS input)
{
    VS2PSDx9 outdata;
    outdata.Pos = mul(input.Pos, mWorldViewProj);

    outdata.Tex0AndZFade.xy = input.Tex0;
    outdata.Tex1 = input.Tex1;

    vec3 dist = (vLocalEyePos - input.Pos);
    outdata.Tex0AndZFade.z = dot(dist, dist);
    outdata.Tex0AndZFade.z = (outdata.Tex0AndZFade.z - vFadeoutValues.x) * vFadeoutValues.y;
    outdata.Tex0AndZFade.z = 1.0 - saturate(outdata.Tex0AndZFade.z);

    return outdata;
}

vec4 RoadCompiledPSDx9(VS2PSDx9 indata) : COLOR0
{
    vec4 t0 = tex2D(sampler0, indata.Tex0AndZFade);
    vec4 t1 = tex2D(sampler1, indata.Tex1);

    vec4 final;
    final.rgb = lerp(t1, t0, fTexBlendFactor);
    final.a = t0.a * indata.Tex0AndZFade.z;
    return final;
}

technique roadcompiledFull
<
    int DetailLevel = DLHigh + DLNormal + DLLow + DLAbysmal;
    int Compatibility = CMPR300 + CMPNV2X;
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 1 },
        { 0, D3DDECLTYPE_FLOAT1, D3DDECLUSAGE_TEXCOORD, 2 },
        DECLARATION_END	// End macro
    };
    int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
    pass NV3x
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        FogEnable = true;
        VertexShader = compile vs_2_0 RoadCompiledVS();
        PixelShader = compile ps_2_0 RoadCompiledPS();
    }

    pass DirectX9
    {
        AlphaBlendEnable = FALSE;
        DepthBias = -0.0001f;
        SlopeScaleDepthBias = -0.00001f;
        ZEnable = FALSE;
        VertexShader = compile vs_2_0 RoadCompiledVSDx9();
        PixelShader = compile ps_2_0 RoadCompiledPSDx9();
    }
}

vec4 RoadCompiledPS_LightingOnly(VS2PS indata) : COLOR0
{
    return 0;
}

technique roadcompiledLightingOnly
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 1 },
        { 0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_POSITION, 1 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        DepthBias = -0.000025;
        ZEnable = FALSE;

        VertexShader = compile vs_2_0 RoadCompiledVS();
        PixelShader = compile ps_2_0 RoadCompiledPS_LightingOnly();
    }
}
