#line 2 "TerrainShader.fx"

// Shared stuff

float4x4 mViewProj: matVIEWPROJ;
float4   vScaleTransXZ : SCALETRANSXZ;
float4   vScaleTransY : SCALETRANSY;

float4 vMorphDeltaSelector : MORPHDELTASELECTOR;
float2 vNearFarMorphLimits : NEARFARMORPHLIMITS;

float4 vDebugColor : DEBUGCELLCOLOR;

float3 vCamerapos : CAMERAPOS;

float3 vComponentsel : COMPONENTSELECTOR;

float4 vSunColor : SUNCOLOR;
float4 vSunDirection : SUNDIRECTION;
float4 vLightPos1 : LIGHTPOS1;
float4 vLightCol1 : LIGHTCOL1;
float  LightAttSqrInv1 : LIGHTATTSQRINV1;
float4 vLightPos2 : LIGHTPOS2;
float4 vLightCol2 : LIGHTCOL2;
float  LightAttSqrInv2 : LIGHTATTSQRINV2;

texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
texture texture2 : TEXLAYER2;
texture texture3 : TEXLAYER3;
texture texture4 : TEXLAYER4;

sampler sampler0Clamp = sampler_state { Texture = (texture0); MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler1Clamp = sampler_state { Texture = (texture1); MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler2Clamp = sampler_state { Texture = (texture2); };
sampler sampler0Wrap = sampler_state { Texture = (texture0); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler1Wrap = sampler_state { Texture = (texture1); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler2Wrap = sampler_state { Texture = (texture2); AddressU = WRAP; AddressV = WRAP; };
sampler sampler3 = sampler_state { Texture = (texture3); };
sampler sampler4 = sampler_state { Texture = (texture4); };


// -- Basic morphed technique

struct APP2VS_BM_Dx9
{
    float4 Pos0       : POSITION0;
    float2 TexCoord0  : TEXCOORD0;
    float4 Pos1       : POSITION1;
    float4 MorphDelta : POSITION2;
    float3 Normal     : NORMAL;
};

struct APP2VS_BM_Dx8
{
    float4 Pos0       : POSITION0;
    float4 Pos1       : POSITION1;
    float4 MorphDelta : POSITION2;
};

struct VS2PS_BM_Dx9_Base
{
    float4 Pos  : POSITION;
    float2 Tex0 : TEXCOORD0;
};

struct VS2PS_BM_Dx9
{
    float4 Pos   : POSITION;
    float2 Tex0  : TEXCOORD0;
    float4 Color : COLOR;
};

struct VS2PS_BM_Dx8
{
    float4 Pos  : POSITION;
    float2 Tex0 : TEXCOORD0;
};

struct LightSourceData
{
    float3 pos;
    float  attSqrInv;
    float3 col;
    float  coneAngle;
    float3 dir;
    float  oneminusconeAngle;
};

LightSourceData lightSources[3] : LightSourceArray;

float4 psDx9_BM_Base(VS2PS_BM_Dx9_Base indata) : COLOR
{
    return tex2D(sampler0Clamp, indata.Tex0) + 0.5;
}

VS2PS_BM_Dx9_Base vsDx9_BM_Base(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9_Base outdata;

    float4 WorldPos;
    WorldPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    WorldPos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;

    float cameraDist = length(WorldPos.xyz - vCamerapos);
    float interpVal = cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y;
    interpVal = saturate(interpVal);

    WorldPos.y -= indata.MorphDelta.x * vScaleTransY.x * interpVal;

    outdata.Pos = mul(WorldPos, mViewProj);
    outdata.Tex0 = indata.TexCoord0;

    return outdata;
}

float4 psDx9_BM_Pt(VS2PS_BM_Dx9 indata) : COLOR
{
    return vMorphDeltaSelector * vDebugColor + 0.1;
    return vMorphDeltaSelector * 0.5 + tex2D(sampler0Clamp, indata.Tex0) + vDebugColor;
    float4 lightmap = tex2D(sampler0Clamp, indata.Tex0);
    return lightmap + indata.Color;
}

float4 psDx9_BM_Sp(VS2PS_BM_Dx9 indata) : COLOR
{
    return indata.Color;
}

VS2PS_BM_Dx9 vsDx9_BM_Pt(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9 outdata;

    float4 WorldPos;
    WorldPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    WorldPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;

    float cameraDist = length(WorldPos.xyz - vCamerapos);
    float interpVal = cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y;
    interpVal = saturate(interpVal);

    WorldPos.y -= indata.MorphDelta.x * vScaleTransY.x * interpVal;

    outdata.Pos = mul(WorldPos, mViewProj);
    outdata.Tex0 = indata.TexCoord0;

    // Accumulate vlights
    outdata.Color = 0;
    for(int i = 0; i < 0; ++i)
    {
        float3 lvec = lightSources[i].pos - WorldPos.xyz;
        float radialAtt = saturate(1.0 - dot(lvec, lvec) * lightSources[i].attSqrInv);
        lvec = normalize(lvec);
        float intensity = dot(lvec, indata.Normal) * radialAtt;
        outdata.Color.rgb += intensity * lightSources[i].col;
    }

    return outdata;
}

VS2PS_BM_Dx9 vsDx9_BM_Sp(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9 outdata;

    float4 WorldPos;
    WorldPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    WorldPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;

    float cameraDist = length(WorldPos.xyz - vCamerapos);
    float interpVal = cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y;
    interpVal = saturate(interpVal);

    WorldPos.y -= indata.MorphDelta.x * vScaleTransY.x * interpVal;

    outdata.Pos = mul(WorldPos, mViewProj);
    outdata.Tex0 = indata.TexCoord0;

    // Accumulate vlights
    outdata.Color = 0;
    for(int i = 0; i < 3; ++i)
    {
        float3 lvec = lightSources[i].pos - WorldPos.xyz;
        float radialAtt = saturate(1 - dot(lvec, lvec)*lightSources[i].attSqrInv);
        lvec = normalize(lvec);
        float intensity = dot(lvec, indata.Normal) * radialAtt;
        float conicalAtt = saturate(dot(lvec, lightSources[i].dir)-lightSources[i].oneminusconeAngle) / lightSources[i].coneAngle;
        intensity *= conicalAtt;
        outdata.Color.rgb += intensity * lightSources[i].col;
    }

    return outdata;
}

float4 psDx8_BM(VS2PS_BM_Dx8 indata) : COLOR
{
    return tex2D(sampler0Clamp, indata.Tex0);
}

VS2PS_BM_Dx8 vsDx8_BM(APP2VS_BM_Dx8 indata)
{
    VS2PS_BM_Dx8 outdata;

    float4 inpos = D3DCOLORtoUBYTE4(indata.Pos0);

    outdata.Pos.xz = (inpos.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    outdata.Pos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;

    float cameraDist = length(outdata.Pos.xyz - vCamerapos);
    float interpVal = cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y;
    interpVal = saturate(interpVal);

    outdata.Pos.y -= indata.MorphDelta.x * vScaleTransY.x * interpVal;
    outdata.Pos = mul(outdata.Pos, mViewProj);
    outdata.Tex0 = inpos.xy / 128;

    return outdata;
}



// -- Basic morphed techniques

technique Dx9Style_BM_States <bool Restore = true;> {
    pass BeginStates
    {
        CullMode = CW;
    }

    pass EndStates { }
}

technique Dx9Style_BM
{
    pass base
    {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_2_0 vsDx9_BM_Base();
        PixelShader = compile ps_2_0 psDx9_BM_Base();
    }

    pass point
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = INVDESTCOLOR;
        FillMode = WIREFRAME;
        VertexShader = compile vs_2_0 vsDx9_BM_Pt();
        PixelShader = compile ps_1_4 psDx9_BM_Pt();
    }

    pass spot
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;

        VertexShader = compile vs_2_0 vsDx9_BM_Sp();
        PixelShader = compile ps_2_0 psDx9_BM_Sp();
    }
}

technique Dx8Style_BM
{
    pass p0
    {
        CullMode = CW;
        AddressU[0] = CLAMP;
        AddressV[0] = CLAMP;
        MipFilter[0] = LINEAR;
        MinFilter[0] = LINEAR;
        MagFilter[0] = LINEAR;

        VertexShader = compile vs_2_0 vsDx8_BM();
        PixelShader = compile ps_2_0 psDx8_BM();
    }
}



// -- Detail textured techniques

struct APP2VS_DT_Dx9
{
    float4 Pos0       : POSITION0;
    float2 TexCoord0  : TEXCOORD0;
    float4 Pos1       : POSITION1;
    float4 MorphDelta : POSITION2;
};

struct APP2VS_DT_Dx8
{
    float4 Pos0       : POSITION0;
    float4 Pos1       : POSITION1;
    float4 MorphDelta : POSITION2;
};

struct VS2PS_DT_Dx8
{
    float4 Pos  : POSITION;
    float2 Tex0 : TEXCOORD0;
    float2 Tex1 : TEXCOORD1;
    float2 Tex2 : TEXCOORD2;
    float4 Col  : COLOR;
};

struct VS2PS_DT_Dx9
{
    float4 Pos              : POSITION;
    float4 Tex0And1         : TEXCOORD0;
    float4 PosTex           : TEXCOORD1;
    float4 ColorAndFadeLerp : COLOR;
};

float4 psDx9_DT(VS2PS_DT_Dx9 indata) : COLOR
{
    float4 component = tex2D(sampler0Clamp, indata.Tex0And1.xy);
    float4 detailmap = tex2D(sampler1Wrap, indata.Tex0And1.zw);

    float chartcontrib = dot(vComponentsel, component.xyz);
    float4 detailcontrib = chartcontrib * detailmap;
    return 1;
    return lerp(detailcontrib, chartcontrib, indata.ColorAndFadeLerp.w);
}

VS2PS_DT_Dx9 vsDx9_DT(APP2VS_DT_Dx9 indata)
{
    VS2PS_DT_Dx9 outdata;

    float4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;

    float cameraDist = length(wPos.xyz - vCamerapos);
    float interpVal = cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y;
    interpVal = saturate(interpVal);

    wPos.y -= indata.MorphDelta.x * vScaleTransY.x * interpVal;

     outdata.Pos = mul(wPos, mViewProj);

    outdata.PosTex.xy = outdata.Pos.xy/outdata.Pos.w;
    outdata.PosTex.xy = outdata.PosTex.xy * 0.5 + 0.5;
    outdata.PosTex.y = 1.0 - outdata.PosTex.y;
    outdata.PosTex.zw = outdata.Pos.zw;

    outdata.Tex0And1.xy = indata.TexCoord0;
    outdata.Tex0And1.zw = indata.TexCoord0 * 32;

    outdata.ColorAndFadeLerp.w = (-50.0 + length(wPos.xyz - vCamerapos)) / 140;
    outdata.ColorAndFadeLerp.rgb = float3(1.0, 0.0, 1.0);

    return outdata;
}



struct VS2PS_DT2_Dx9
{
    float4 Pos        : POSITION;
    float4 Tex0AndPos : TEXCOORD0;
};

float4 psDx9_DT2(VS2PS_DT2_Dx9 indata) : COLOR
{
    float4 colormap = tex2D(sampler0Clamp, indata.Tex0AndPos.xy);
    float4 lightaccum = tex2D(sampler1Clamp, indata.Tex0AndPos.zw);
    return 1;
    return lightaccum * colormap;
}


VS2PS_DT2_Dx9 vsDx9_DT2(APP2VS_DT_Dx9 indata)
{
    VS2PS_DT2_Dx9 outdata;

    float4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;

    float cameraDist = length(wPos.xyz - vCamerapos);
    float interpVal = cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y;
    interpVal = saturate(interpVal);
    wPos.y -= indata.MorphDelta.x * vScaleTransY.x * interpVal;

    outdata.Pos = mul(wPos, mViewProj);
    outdata.Tex0AndPos.zw = outdata.Pos.xy/outdata.Pos.w;
    outdata.Tex0AndPos.zw = outdata.Tex0AndPos.zw * 0.5 + 0.5;
    outdata.Tex0AndPos.w = 1.0 - outdata.Tex0AndPos.w;
    outdata.Tex0AndPos.xy = indata.TexCoord0;
    return outdata;
}
VS2PS_DT_Dx8 vsDx8_DT(APP2VS_DT_Dx8 indata)
{
    VS2PS_DT_Dx8 outdata;

    float4 inpos = D3DCOLORtoUBYTE4(indata.Pos0);
    float4 wPos;
    wPos.xz = inpos.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    outdata.Pos = mul(wPos, mViewProj);

    outdata.Tex0 = inpos.xy / 128.0;
    outdata.Tex1 = outdata.Tex0 * 32.0;
    outdata.Tex2 = outdata.Tex0;

    outdata.Col = (-50.0 + length(wPos.xyz - vCamerapos)) / 140.0;

    return outdata;
}

technique Dx9Style_DT_States <bool Restore = true;>
{
    pass BeginStates { CullMode = CW; }
    pass EndStates { }
}

technique Dx9Style_DT
{
    pass p0detailpass
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;

        ZWriteEnable = FALSE;
        ZFunc = EQUAL;

        VertexShader = compile vs_2_0 vsDx9_DT();
        PixelShader = compile ps_2_0 psDx9_DT();
    }

    pass p1basicpass
    {
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_2_0 vsDx9_DT2();
        PixelShader = compile ps_2_0 psDx9_DT2();
    }

    pass p2basicpass2
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = DESTCOLOR;
        DestBlend = ZERO;

        VertexShader = compile vs_2_0 vsDx9_DT2();
        PixelShader = compile ps_2_0 psDx9_DT2();
    }
}


//$ TL -- dbg ------------------------

struct VSTanOut
{
    float4 HPos    : POSITION;
    float4 Diffuse : COLOR;
};

VSTanOut vsShowTanBasis(float4 Pos : POSITION, float4 Col : COLOR)
{
    VSTanOut Out;
    Pos.y += 0.15;
    Out.HPos = mul(Pos, mViewProj);
    Out.Diffuse = Col;
    return Out;
}

float4 psShowTanBasis(float4 Col : COLOR) : COLOR
{
    return Col;
}

technique showTangentBasis
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = false;

        VertexShader = compile vs_2_0 vsShowTanBasis();
        PixelShader = compile ps_2_0 psShowTanBasis();
    }
}
