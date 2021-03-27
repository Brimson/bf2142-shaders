#line 2 "RoadCompiled.fx"
#include "shaders/raCommon.fx"

float4x4	mWorldViewProj : WorldViewProjection;
float fTexBlendFactor : TexBlendFactor;
float2 vFadeoutValues : FadeOut;
float4 vLocalEyePos : LocalEye;
float4 vCameraPos : CAMERAPOS;
float vScaleY : SCALEY;
float4 vSunColor : SUNCOLOR;
float4 vGIColor : GICOLOR;

float4 vTexProjOffset : TEXPROJOFFSET;
float4 vTexProjScale : TEXPROJSCALE;

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
    float4 Pos : POSITION;
    float2 Tex0 : TEXCOORD0;
    float2 Tex1 : TEXCOORD1;
    float Alpha : TEXCOORD2;
};

struct VS2PS
{
    float4 Pos : POSITION;
    float3 Tex0AndZFade : TEXCOORD0;
    float2 Tex1 : TEXCOORD1;
    float4 PosTex : TEXCOORD2;
    float Fog : FOG;
};

float4 projToLighting(float4 hPos)
{
    /*
        tl: This has been rearranged optimally (I believe) into 1 MUL and 1 MAD,
            don't change this without thinking twice.
            ProjOffset now includes screen->texture bias as well as half-texel offset
            ProjScale is screen->texture scale/invert operation
        tex = (hpos.x * 0.5 + 0.5 + htexel, hpos.y * -0.5 + 0.5 + htexel, hpos.z, hpos.w)
    */
    float4 tex;
    tex = hPos * vTexProjScale + (vTexProjOffset * hPos.w);
    return tex;
}

VS2PS RoadCompiledVS(APP2VS input)
{
    VS2PS outdata;

    float4 wPos = input.Pos;

    float cameraDist = length(vLocalEyePos - input.Pos);
    float interpVal = saturate(cameraDist * vFadeoutValues.x - vFadeoutValues.y);
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

float4 RoadCompiledPS(VS2PS indata) : COLOR0
{
    float4 t0 = tex2D(sampler0, indata.Tex0AndZFade);
    float4 t1 = tex2D(sampler1, indata.Tex1.xy * 0.1);
    float4 accumlights = tex2Dproj(sampler2, indata.PosTex);
    float4 light = ((accumlights.w * vSunColor * 2.0) + accumlights) * 2.0;

    float4 final;
    final.rgb = lerp(t1, t0, fTexBlendFactor);
    final.a = t0.a * indata.Tex0AndZFade.z;
    final.rgb *= light.xyz;
    return final;
}

struct VS2PSDx9
{
    float4 Pos          : POSITION;
    float3 Tex0AndZFade : TEXCOORD0;
    float2 Tex1         : TEXCOORD1;
};

VS2PSDx9 RoadCompiledVSDx9(APP2VS input)
{
    VS2PSDx9 outdata;
    outdata.Pos = mul(input.Pos, mWorldViewProj);

    outdata.Tex0AndZFade.xy = input.Tex0;
    outdata.Tex1 = input.Tex1;

    float3 dist = (vLocalEyePos - input.Pos);
    outdata.Tex0AndZFade.z = dot(dist, dist);
    outdata.Tex0AndZFade.z = (outdata.Tex0AndZFade.z - vFadeoutValues.x) * vFadeoutValues.y;
    outdata.Tex0AndZFade.z = 1.0 - saturate(outdata.Tex0AndZFade.z);

    return outdata;
}

float4 RoadCompiledPSDx9(VS2PSDx9 indata) : COLOR0
{
    float4 t0 = tex2D(sampler0, indata.Tex0AndZFade);
    float4 t1 = tex2D(sampler1, indata.Tex1);

    float4 final;
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

float4 RoadCompiledPS_LightingOnly(VS2PS indata) : COLOR0
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
