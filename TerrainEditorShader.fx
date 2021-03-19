#line 2 "TerrainShader.fx"
#include "shaders/raCommon.fx"
#define POINT_WATER_BIAS 2

float4x4 mViewProj: matVIEWPROJ;
float4  vScaleTransXZ : SCALETRANSXZ;
float4  vScaleTransY : SCALETRANSY;

float4  vSunColor : SUNCOLOR;
float4  vGIColor : GICOLOR;
float4  vPointColor: POINTCOLOR;
float   detailFadeMod : DETAILFADEMOD;
float4  vTexOffset : TEXOFFSET;
float2  vSETBiFixTex : SETBIFIXTEX;
float2  vSETBiFixTex2 : SETBIFIXTEX2;
float2  vBiFixTex : BIFIXTEX;

float3  vBlendMod : BLENDMOD = float3(0.2, 0.5, 0.2);
float   waterHeight : WaterHeight;

float4 terrainWaterColor : TerrainWaterColor;

texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
texture texture2 : TEXLAYER2;

sampler sampler0 = sampler_state
{
    Texture = (texture0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler sampler0_point = sampler_state
{
    Texture = (texture0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
};

sampler sampler1 = sampler_state
{
    Texture = (texture1);
    AddressU = WRAP;
    AddressV = WRAP;
    MipFilter = LINEAR;
    MinFilter = ANISOTROPIC;
    MagFilter = LINEAR;
};

sampler sampler1Clamp = sampler_state
{
    Texture = (texture1);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler sampler1_point = sampler_state
{
    Texture = (texture1);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
};

sampler sampler2 = sampler_state
{
    Texture = (texture2);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

struct VS2PS
{
    float4  Pos : POSITION;
    float2  Tex0 : TEXCOORD0;
    float2  Tex1 : TEXCOORD2;
    float   Fog : TEXCOORD1;
    float4  Color : COLOR;
};

struct PS2FB
{
    float4 Col : COLOR;
};

float4 PShader(VS2PS indata) : COLOR
{
    float4 cmap = tex2D(sampler0, indata.Tex0);
    float4 lightmap = tex2D(sampler1Clamp, indata.Tex1);
    float4 light = (lightmap.y * vSunColor * 4.0) + (lightmap.z * vGIColor * 2.0) + (lightmap.x * indata.Color * 2.0);
    float4 outColor = cmap * light;
    outColor.a = 1.0f;

    return lerp(FogColor, outColor, indata.Fog);
}

float4 PShaderLightOnly(VS2PS indata) : COLOR
{
    float4 lightmap = tex2D(sampler1Clamp, indata.Tex1);
    float4 light = (lightmap.y * vSunColor * 4.0) + (lightmap.z * vGIColor * 2.0)  + (lightmap.x * vPointColor * 2.0);
    light.a = 1.0f;
    return light*0.5;
}

float4 PShaderHemimapLightOnly(VS2PS indata) : COLOR
{
    float4 lightmap = tex2D(sampler1Clamp, indata.Tex1);
    float4 light = (lightmap.y * vSunColor * 4.0) + (lightmap.z * vGIColor * 2.0)  + (lightmap.x * vPointColor * 2.0);
    light.a = 1.0f;
    return pow(lightmap.y * 2.0, 2.0);
}

// NOTE : We can actually optimize the 1.0 mov out of this through a singular MAD

float4 PShaderColorOnly(VS2PS indata) : COLOR
{
    float4 color = tex2D(sampler0, indata.Tex0);
    color.a = 1.0f;
    return color;
}

float4 PShaderColorOnlyPointFiler(VS2PS indata) : COLOR
{
    float4 color = tex2D(sampler0_point, indata.Tex0);
    color.a = 1.0f;
    return color;
}

struct APP2VS
{
    float2	Pos0 : POSITION0;
    float2	TexCoord0 : TEXCOORD0;
    float4	Pos1 : POSITION1;
};

VS2PS vs(APP2VS indata)
{
    VS2PS outdata;

    outdata.Pos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    outdata.Pos.y = indata.Pos1.x * vScaleTransY.x + vScaleTransY.z;
    outdata.Pos.w = 1.0;

    outdata.Color = vPointColor * saturate(outdata.Pos.y - waterHeight - POINT_WATER_BIAS);

    outdata.Pos = mul(outdata.Pos, mViewProj);
    outdata.Tex0 = indata.TexCoord0;
    outdata.Tex1 = indata.TexCoord0 * vBiFixTex.x + vBiFixTex.y;
    outdata.Fog = saturate(calcFog(outdata.Pos.w));

    return outdata;
}





technique t0 <
    int DetailLevel = DLUltraHigh+DLVeryHigh;
    int Compatibility = CMPR300+CMPNV3X;
>
{
    pass p0
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        FogEnable = FALSE;
        VertexShader = compile vs_2_0 vs();
        PixelShader = compile ps_2_0 PShader();
    }

    pass p1 // LightOnly
    {
        AlphaTestEnable = FALSE;
        AlphaBlendEnable = FALSE;
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vs();
        PixelShader = compile ps_2_0 PShaderLightOnly();
    }

    pass p2 // ColorOnly
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vs();
        PixelShader = compile ps_2_0 PShaderColorOnly();
    }
    pass p3 // ColorOnly PointFiler
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vs();
        PixelShader = compile ps_2_0 PShaderColorOnlyPointFiler();
    }

    pass p4 // Hemimap LightOnly
    {
        AlphaTestEnable = FALSE;
        AlphaBlendEnable = FALSE;
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vs();
        PixelShader = compile ps_2_0 PShaderHemimapLightOnly();
    }
}



// Editor techniques


struct VS2PSEditorGrid
{
    float4	Pos : POSITION;
    float2	Tex0 : TEXCOORD0;
    float2	Tex1 : TEXCOORD1;
};

VS2PSEditorGrid vsEditorGrid(APP2VS indata)
{
    VS2PSEditorGrid outdata;

    outdata.Pos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    outdata.Pos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    outdata.Pos = mul(outdata.Pos, mViewProj);
    outdata.Tex0 = indata.TexCoord0;
    outdata.Tex1 = indata.TexCoord0 * 128;

    return outdata;
}

float4 psEditorGrid(VS2PSEditorGrid indata) : COLOR
{
    float4 cmap = tex2D(sampler0, indata.Tex0);
    float4 grid = tex2D(sampler1, indata.Tex1);
    return cmap * grid;
}

technique EditorGrid
{
    pass p0
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        FogEnable = FALSE;

        MaxAnisotropy[1] = 4;
        MipMapLodBias[1] = -1.5;

        VertexShader = compile vs_2_0 vsEditorGrid();
        PixelShader = compile ps_2_0 psEditorGrid();
    }
}


struct VS2PSEditorTopoGrid
{
    float4	Pos : POSITION;
    float2	Tex1 : TEXCOORD1;
    float4	Col : COLOR0;
};

VS2PSEditorTopoGrid vsEditorTopoGrid(APP2VS indata)
{
    VS2PSEditorTopoGrid outdata;

    float4 Pos;
    Pos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    Pos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    outdata.Pos = mul(Pos, mViewProj);
    outdata.Tex1 = indata.TexCoord0 * 128;
    outdata.Col = indata.Pos1.x / 65535;
    return outdata;
}

float4 psEditorTopoGrid(VS2PSEditorTopoGrid indata) : COLOR
{
    float4 grid = tex2D(sampler1, indata.Tex1);
    float4 ret = indata.Col;
    ret += float4(0.0, 0.0, 0.3, 1.0);
    ret *= grid;
    return ret;
}

technique EditorTopoGrid
{
    pass p0
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        FogEnable = FALSE;

        MipMapLodBias[0] = -0.5;
        MaxAnisotropy[0] = 8;

        VertexShader = compile vs_2_0 vsEditorTopoGrid();
        PixelShader = compile ps_2_0 psEditorTopoGrid();
    }
}

float4 camerapos : CAMERAPOS;
float3 componentsel : COMPONENTSELECTOR;
float2 vNearFarMorphLimits : NEARFARMORPHLIMITS;
texture texture3 : TEXLAYER3;
texture texture4 : TEXLAYER4;
texture texture5 : TEXLAYER5;
texture texture6 : TEXLAYER6;

float4 vTexScale : TEXSCALE;
float4 vNearTexTiling : NEARTEXTILING;
float4 vFarTexTiling : FARTEXTILING;


sampler sampler0Clamp = sampler_state
{
    Texture = (texture0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler sampler1Wrap = sampler_state
{
    Texture = (texture1);
    AddressU = WRAP;
    AddressV = WRAP;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler sampler2Clamp = sampler_state
{
    Texture = (texture2);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler sampler3Wrap = sampler_state
{
    Texture = (texture3);
    AddressU = WRAP;
    AddressV = WRAP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

sampler sampler3Clamp = sampler_state
{
    Texture = (texture3);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler sampler4Clamp = sampler_state
{
    Texture = (texture4);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

sampler sampler5Clamp = sampler_state
{
    Texture = (texture5);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

sampler sampler6Clamp = sampler_state
{
    Texture = (texture6);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

struct APP2VSEditorDetailTextured
{
    float4 Pos0 : POSITION0;
    float2 TexCoord0 : TEXCOORD0;
    float4 Pos1 : POSITION1;
    float3 Normal : NORMAL;
};

struct VS2PSEditorDetailTextured
{
    float4 Pos : POSITION;
    float2 Tex0 : TEXCOORD0;
    float2 Tex1 : TEXCOORD1;
    float2 Tex2 : TEXCOORD2;
    float2 Tex3 : TEXCOORD3;
    float2 Tex4 : TEXCOORD4;
    float4 BlendValueAndFade : TEXCOORD5;
    float3 FogAndWaterFadeAndFade2 : TEXCOORD6;
    float2 BiFixTex : TEXCOORD7;
};

VS2PSEditorDetailTextured vsEditorDetailTextured(APP2VSEditorDetailTextured indata)
{
    VS2PSEditorDetailTextured outdata;

    float4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;

    outdata.FogAndWaterFadeAndFade2.y = 1 - saturate((waterHeight - wPos.y) / 3.0f);
    outdata.Pos = mul(wPos, mViewProj);

    float cameraDist = length(wPos.xz - camerapos.xz) + camerapos.w;

    float3 tex = float3((indata.Pos0.y * vTexScale.z), -(((indata.Pos1.x) * vTexScale.y)) , (indata.Pos0.x * vTexScale.x));
    float2 xPlaneTexCord = tex.xy;
    float2 yPlaneTexCord = tex.zx;
    float2 zPlaneTexCord = tex.zy;

    outdata.Tex0 = yPlaneTexCord;
    outdata.BiFixTex = (yPlaneTexCord * vBiFixTex.x) + vBiFixTex.y;

    outdata.Tex1 = yPlaneTexCord * vNearTexTiling.z;

    outdata.Tex2 = yPlaneTexCord * vFarTexTiling.z;
    outdata.Tex3.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex3.y += vFarTexTiling.w;
    outdata.Tex4.xy = zPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex4.y += vFarTexTiling.w;

    outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
    float tot = dot(1, outdata.BlendValueAndFade.xyz);
    outdata.BlendValueAndFade.xyz /= tot;

    float interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    outdata.BlendValueAndFade.w = saturate(interpVal * detailFadeMod);
    outdata.FogAndWaterFadeAndFade2.z = 0.5 + interpVal * 0.5;

    outdata.FogAndWaterFadeAndFade2.x = saturate(calcFog(outdata.Pos.w));

    return outdata;
}

float4 psEditorDetailTextured(VS2PSEditorDetailTextured indata) : COLOR
{
    float4 staticColormap = tex2D(sampler0Clamp, indata.BiFixTex);
    float4 component = tex2D(sampler2Clamp, indata.BiFixTex);
    float4 lowComponent = tex2D(sampler5Clamp, indata.BiFixTex);
    float4 detailmap = tex2D(sampler1Wrap, indata.Tex1);
    float4 yplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex2);
    float4 xplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex3);
    float4 zplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex4);

    float4 lightmap = tex2D(sampler4Clamp, indata.BiFixTex);
    float4 light = (lightmap.y * vSunColor * 4.0) + (lightmap.z * vGIColor * 2.0) + (lightmap.x * vPointColor);

    float3 blendValue = indata.BlendValueAndFade.xyz;
    float fade = indata.BlendValueAndFade.w;

    float4 colormap = staticColormap;

    float chartcontrib = dot(componentsel, component.xyz);

    float4 lowDetailmap = lerp(1.0, yplaneLowDetailmap.z, lowComponent.x * indata.FogAndWaterFadeAndFade2.z);
    float mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), blendValue.xyz);
    lowDetailmap *= lerp(1.0, mounten, lowComponent.z);

    float4 bothDetailmap = detailmap * lowDetailmap;
    float4 detailout = 2.0 * lerp(bothDetailmap, 0.5 * lowDetailmap, fade);

    float4 outColor = detailout * colormap * light;

    float4 waterOutColor = lerp(terrainWaterColor, outColor, indata.FogAndWaterFadeAndFade2.y);
    float4 fogWaterOutColor = lerp(FogColor, waterOutColor, indata.FogAndWaterFadeAndFade2.x);

    fogWaterOutColor.a = 1.0f;
    return  chartcontrib * fogWaterOutColor;
}

float4 psEditorDetailTexturedColorOnly(VS2PSEditorDetailTextured indata) : COLOR
{
    float4 staticColormap = tex2D(sampler0Clamp, indata.BiFixTex);
    float4 component = tex2D(sampler2Clamp, indata.BiFixTex);
    float4 lowComponent = tex2D(sampler5Clamp, indata.BiFixTex);
    float4 detailmap = tex2D(sampler1Wrap, indata.Tex1);
    float4 yplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex2);
    float4 xplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex3);
    float4 zplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex4);

    float3 blendValue = indata.BlendValueAndFade.xyz;
    float fade = indata.BlendValueAndFade.w;

    float4 colormap = staticColormap;

    float chartcontrib = dot(componentsel, component.xyz);

    float4 lowDetailmap = lerp(1.0, yplaneLowDetailmap.z, lowComponent.x*indata.FogAndWaterFadeAndFade2.z);
    float mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), blendValue.xyz);
    lowDetailmap *= lerp(1.0, mounten, lowComponent.z);

    float4 bothDetailmap = detailmap * lowDetailmap;
    float4 detailout = 2.0 * lerp(bothDetailmap, 0.5 * lowDetailmap, fade);

    float4 outColor = detailout * colormap;

    float4 waterOutColor = lerp(terrainWaterColor, outColor, indata.FogAndWaterFadeAndFade2.y);
    float4 fogWaterOutColor = lerp(FogColor, waterOutColor, indata.FogAndWaterFadeAndFade2.x);

    fogWaterOutColor.a = 1.0f;
    return  chartcontrib * fogWaterOutColor;
}


struct VS2PSEditorDetailTexturedPlaneMapping
{
    float4	Pos : POSITION;
    float4	Tex0AndBiFixTex : TEXCOORD0;
    float2	Tex1 : TEXCOORD1;
    float2	Tex2 : TEXCOORD2;
    float2	Tex3 : TEXCOORD3;
    float2	Tex4 : TEXCOORD4;
    float4	BlendValueAndFade : TEXCOORD5;
    float3	Tex5AndFade2 : TEXCOORD6;
    float4	Tex6AndFogAndWaterFade : TEXCOORD7;
};

VS2PSEditorDetailTexturedPlaneMapping vsEditorDetailTexturedPlaneMapping(APP2VSEditorDetailTextured indata)
{
    VS2PSEditorDetailTexturedPlaneMapping outdata;

    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    wPos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;

    outdata.Tex6AndFogAndWaterFade.w = 1.0 - saturate((waterHeight - wPos.y) / 3.0f);

    outdata.Pos = mul(wPos, mViewProj);

    float cameraDist = length(wPos.xz - camerapos.xz) + camerapos.w;

    float3 tex = float3(indata.Pos0.y * vTexScale.z, -(indata.Pos1.x * vTexScale.y), indata.Pos0.x * vTexScale.x);
    float2 xPlaneTexCord = tex.xy;
    float2 yPlaneTexCord = tex.zx;
    float2 zPlaneTexCord = tex.zy;

    outdata.Tex0AndBiFixTex.xy = yPlaneTexCord;
    outdata.Tex0AndBiFixTex.zw = yPlaneTexCord * vBiFixTex.x + vBiFixTex.y;
    outdata.Tex1 = yPlaneTexCord * vNearTexTiling.z;
    outdata.Tex5AndFade2.xy = xPlaneTexCord.xy * vNearTexTiling.xy;
    outdata.Tex5AndFade2.y += vNearTexTiling.w;
    outdata.Tex6AndFogAndWaterFade.xy = zPlaneTexCord.xy * vNearTexTiling.xy;
    outdata.Tex6AndFogAndWaterFade.y += vNearTexTiling.w;

    outdata.Tex2 = yPlaneTexCord * vFarTexTiling.z;
    outdata.Tex3.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex3.y += vFarTexTiling.w;
    outdata.Tex4.xy = zPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex4.y += vFarTexTiling.w;

    outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
    float tot = dot(outdata.BlendValueAndFade.xyz, 1.0);
    outdata.BlendValueAndFade.xyz /= tot;

    float interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    outdata.BlendValueAndFade.w = saturate(interpVal * detailFadeMod);
    outdata.Tex5AndFade2.z = 0.5 + interpVal * 0.5;

    outdata.Tex6AndFogAndWaterFade.z = saturate(calcFog(outdata.Pos.w));

    return outdata;
}

float4 psEditorDetailTexturedPlaneMapping(VS2PSEditorDetailTexturedPlaneMapping indata) : COLOR
{
    float4 staticColormap = tex2D(sampler0Clamp, indata.Tex0AndBiFixTex.zw);
    float4 component = tex2D(sampler2Clamp, indata.Tex0AndBiFixTex.zw);
    float4 lowComponent = tex2D(sampler5Clamp, indata.Tex0AndBiFixTex.zw);
    float4 yplaneDetailmap = tex2D(sampler1Wrap, indata.Tex1);
    float4 xplaneDetailmap = tex2D(sampler1Wrap, indata.Tex5AndFade2.xy);
    float4 zplaneDetailmap = tex2D(sampler1Wrap, indata.Tex6AndFogAndWaterFade.xy);
    float4 yplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex2);
    float4 xplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex3);
    float4 zplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex4);

    float4 lightmap = tex2D(sampler4Clamp, indata.Tex0AndBiFixTex.zw);
    float4 light = (lightmap.y * vSunColor * 4.0) + (lightmap.z * vGIColor * 2.0) + (lightmap.x * vPointColor);

    float3 blendValue = indata.BlendValueAndFade.xyz;
    float fade = indata.BlendValueAndFade.w;

    float4 colormap = staticColormap;

    float chartcontrib = dot(componentsel, component.xyz);

    float4 lowDetailmap = lerp(1.0, yplaneLowDetailmap.z, lowComponent.x*indata.Tex5AndFade2.z);
    float mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), blendValue.xyz);
    lowDetailmap *= lerp(1.0, mounten, lowComponent.z);

    float4 detailmap = (xplaneDetailmap * blendValue.x) + (yplaneDetailmap * blendValue.y) + (zplaneDetailmap * blendValue.z);

    float4 bothDetailmap = detailmap * lowDetailmap;
    float4 detailout = 2.0 * lerp(bothDetailmap, 0.5 * lowDetailmap, fade);

    float4 outColor = detailout * colormap * light;
    float4 waterOutColor = lerp(terrainWaterColor, outColor, indata.Tex6AndFogAndWaterFade.w);
    float4 fogWaterOutColor = lerp(FogColor, waterOutColor, indata.Tex6AndFogAndWaterFade.z);
    fogWaterOutColor.a = 1.0f;
    return  chartcontrib * fogWaterOutColor;
}

float4 psEditorDetailTexturedPlaneMappingColorOnly(VS2PSEditorDetailTexturedPlaneMapping indata) : COLOR
{
    float4 staticColormap = tex2D(sampler0Clamp, indata.Tex0AndBiFixTex.zw);
    float4 component = tex2D(sampler2Clamp, indata.Tex0AndBiFixTex.zw);
    float4 lowComponent = tex2D(sampler5Clamp, indata.Tex0AndBiFixTex.zw);
    float4 yplaneDetailmap = tex2D(sampler1Wrap, indata.Tex1);
    float4 xplaneDetailmap = tex2D(sampler1Wrap, indata.Tex5AndFade2.xy);
    float4 zplaneDetailmap = tex2D(sampler1Wrap, indata.Tex6AndFogAndWaterFade.xy);
    float4 yplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex2);
    float4 xplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex3);
    float4 zplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex4);

    float3 blendValue = indata.BlendValueAndFade.xyz;
    float fade = indata.BlendValueAndFade.w;

    float4 colormap = staticColormap;

    float chartcontrib = dot(componentsel, component.xyz);

    float4 lowDetailmap = lerp(1.0, yplaneLowDetailmap.z, lowComponent.x*indata.Tex5AndFade2.z);
    float mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), blendValue.xyz);
    lowDetailmap *= lerp(1.0, mounten, lowComponent.z);

    float4 detailmap = (xplaneDetailmap * blendValue.x) + (yplaneDetailmap * blendValue.y) + (zplaneDetailmap * blendValue.z);

    float4 bothDetailmap = detailmap * lowDetailmap;
    float4 detailout = 2.0 * lerp(bothDetailmap, 0.5 * lowDetailmap, fade);

    float4 outColor = detailout * colormap;
    float4 waterOutColor = lerp(terrainWaterColor, outColor, indata.Tex6AndFogAndWaterFade.w);
    float4 fogWaterOutColor = lerp(FogColor, waterOutColor, indata.Tex6AndFogAndWaterFade.z);
    fogWaterOutColor.a = 1.0f;
    return  chartcontrib * fogWaterOutColor;
}




struct VS2PSEditorDetailTexturedWithEnvMap
{
    float4 Pos : POSITION;
    float4 Tex0AndBiFixTex : TEXCOORD0;
    float2 Tex1 : TEXCOORD1;
    float2 Tex2 : TEXCOORD2;
    float2 Tex3 : TEXCOORD3;
    float2 Tex4 : TEXCOORD4;
    float4 BlendValueAndFade : TEXCOORD5;
    float3 FogAndWaterFadeAndFade2 : TEXCOORD6;
    float3 EnvMap : TEXCOORD7;
};

texture texture7 : TEXLAYER7;
samplerCUBE sampler7Cube = sampler_state
{
    Texture = (texture7);
    AddressU = WRAP;
    AddressV = WRAP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

float refractionIndexRatio = 0.15;
static float R0 = pow(1.0 - refractionIndexRatio, 2.0) / pow(1.0 + refractionIndexRatio, 2.0);


VS2PSEditorDetailTexturedWithEnvMap vsEditorDetailTexturedWithEnvMap(APP2VSEditorDetailTextured indata)
{
    VS2PSEditorDetailTexturedWithEnvMap outdata;

    float4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;

    outdata.FogAndWaterFadeAndFade2.y = 1.0 - saturate((waterHeight - wPos.y) / 3.0f);

    outdata.Pos = mul(wPos, mViewProj);

    float cameraDist = length(wPos.xz - camerapos.xz) + camerapos.w;

    float3 tex = float3(indata.Pos0.y * vTexScale.z, -(indata.Pos1.x * vTexScale.y) , indata.Pos0.x * vTexScale.x);
    float2 xPlaneTexCord = tex.xy;
    float2 yPlaneTexCord = tex.zx;
    float2 zPlaneTexCord = tex.zy;

    outdata.Tex0AndBiFixTex.xy = yPlaneTexCord;
    outdata.Tex1 = yPlaneTexCord * vNearTexTiling.z;
    outdata.Tex0AndBiFixTex.zw = (yPlaneTexCord * vBiFixTex.x) + vBiFixTex.y;

    outdata.Tex2 = yPlaneTexCord * vFarTexTiling.z;
    outdata.Tex3.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex3.y += vFarTexTiling.w;
    outdata.Tex4.xy = zPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex4.y += vFarTexTiling.w;

    outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
    float tot = dot(1.0, outdata.BlendValueAndFade.xyz);
    outdata.BlendValueAndFade.xyz /= tot;

    float interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    outdata.BlendValueAndFade.w = saturate(interpVal * detailFadeMod);
    outdata.FogAndWaterFadeAndFade2.z = 0.5 + interpVal * 0.5;

    outdata.FogAndWaterFadeAndFade2.x = saturate(calcFog(outdata.Pos.w));

    // Environment map
    float3 worldEyeVec = normalize(wPos.xyz - camerapos.xyz);
    outdata.EnvMap = normalize(reflect(worldEyeVec, float3(0.0, 1.0, 0.0)));

    outdata.FogAndWaterFadeAndFade2.y = 1.0;

    return outdata;
}

float4 psEditorDetailTexturedWithEnvMap(VS2PSEditorDetailTexturedWithEnvMap indata) : COLOR
{
    float4 staticColormap = tex2D(sampler0Clamp, indata.Tex0AndBiFixTex.zw);
    float4 component = tex2D(sampler2Clamp, indata.Tex0AndBiFixTex.zw);
    float4 lowComponent = tex2D(sampler5Clamp, indata.Tex0AndBiFixTex.zw);
    float4 detailmap = tex2D(sampler1Wrap, indata.Tex1);
    float4 yplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex2);
    float4 xplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex3);
    float4 zplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex4);
    float4 envmapColor = texCUBE(sampler7Cube, indata.EnvMap);

    float4 lightmap = tex2D(sampler4Clamp, indata.Tex0AndBiFixTex.zw);
    float4 light = (lightmap.y * vSunColor * 4.0) + (lightmap.z * vGIColor * 2.0) + (lightmap.x * vPointColor);

    float3 blendValue = indata.BlendValueAndFade.xyz;
    float fade = indata.BlendValueAndFade.w;

    float4 colormap = staticColormap;

    float chartcontrib = dot(componentsel, component.xyz);

    float4 lowDetailmap = lerp(1.0, yplaneLowDetailmap.z, lowComponent.x * indata.FogAndWaterFadeAndFade2.z);
    float mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), blendValue.xyz);
    lowDetailmap *= lerp(1.0, mounten, lowComponent.z);

    float4 bothDetailmap = detailmap * lowDetailmap;
    float4 detailout = 2.0 * lerp(bothDetailmap, 0.5 * lowDetailmap, fade);

    float4 outColor = detailout * colormap * light;
    float4 waterOutColor = lerp(terrainWaterColor, outColor, indata.FogAndWaterFadeAndFade2.y);
    float4 fogWaterOutColor = lerp(FogColor, waterOutColor, indata.FogAndWaterFadeAndFade2.x);
    fogWaterOutColor.a = 1.0f;
    return  chartcontrib * fogWaterOutColor;
}

float4 psEditorDetailTexturedWithEnvMapColorOnly(VS2PSEditorDetailTexturedWithEnvMap indata) : COLOR
{
    float4 staticColormap = tex2D(sampler0Clamp, indata.Tex0AndBiFixTex.zw);
    float4 component = tex2D(sampler2Clamp, indata.Tex0AndBiFixTex.zw);
    float4 lowComponent = tex2D(sampler5Clamp, indata.Tex0AndBiFixTex.zw);
    float4 detailmap = tex2D(sampler1Wrap, indata.Tex1);
    float4 yplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex2);
    float4 xplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex3);
    float4 zplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex4);
    float4 envmapColor = texCUBE(sampler7Cube, indata.EnvMap);

    float3 blendValue = indata.BlendValueAndFade.xyz;
    float fade = indata.BlendValueAndFade.w;

    float4 colormap = staticColormap;

    float chartcontrib = dot(componentsel, component.xyz);

    float4 lowDetailmap = lerp(1.0, yplaneLowDetailmap.z, lowComponent.x * indata.FogAndWaterFadeAndFade2.z);
    float mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), blendValue.xyz);
    lowDetailmap *= lerp(1.0, mounten, lowComponent.z);

    float4 bothDetailmap = detailmap * lowDetailmap;
    float4 detailout = 2.0 * lerp(bothDetailmap, 0.5 * lowDetailmap, fade);

    float4 outColor = detailout * colormap;
    float4 waterOutColor = lerp(terrainWaterColor, outColor, indata.FogAndWaterFadeAndFade2.y);
    float4 fogWaterOutColor = lerp(FogColor, waterOutColor, indata.FogAndWaterFadeAndFade2.x);
    fogWaterOutColor.a = 1.0f;
    return chartcontrib * fogWaterOutColor;
}



technique EditorDetailTextured
{
    pass topDownMapping
    {
        CullMode = CW;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsEditorDetailTextured();
        PixelShader = compile ps_2_0 psEditorDetailTextured();
    }

    pass planeMapping
    {
        CullMode = CW;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsEditorDetailTexturedPlaneMapping();
        PixelShader = compile ps_2_0 psEditorDetailTexturedPlaneMapping();
    }

    pass topDownMappingWithEnvMap
    {
        CullMode = CW;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsEditorDetailTexturedWithEnvMap();
        PixelShader = compile ps_2_0 psEditorDetailTexturedWithEnvMap();
    }

    pass topDownMappingColorOnly
    {
        CullMode = CW;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsEditorDetailTextured();
        PixelShader = compile ps_2_0 psEditorDetailTexturedColorOnly();
    }

    pass planeMappingColorOnly
    {
        CullMode = CW;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsEditorDetailTexturedPlaneMapping();
        PixelShader = compile ps_2_0 psEditorDetailTexturedPlaneMappingColorOnly();
    }

    pass topDownMappingWithEnvMapColorOnly
    {
        CullMode = CW;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsEditorDetailTexturedWithEnvMap();
        PixelShader = compile ps_2_0 psEditorDetailTexturedWithEnvMapColorOnly();
    }

}


struct APP2VS_vsEditorZFill
{
    float4	Pos0 : POSITION0;
    float2	TexCoord0 : TEXCOORD0;
    float4	Pos1 : POSITION1;
};

float4 vsEditorZFill(APP2VS_vsEditorZFill indata) : POSITION
{
    float4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    return mul(wPos, mViewProj);
}

float4 psEditorZFill() : COLOR
{
    return 0.0;
}

technique EditorDetailBasePass
{
    pass p0
    {
        CullMode = CW;

        ColorWriteEnable = 0;

        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;

        VertexShader = compile vs_2_0 vsEditorZFill();
        PixelShader = compile ps_2_0  psEditorZFill();
    }
}

struct VS2PSEditorUndergrowth
{
    float4 Pos : POSITION;
    float2 Tex0 : TEXCOORD0;
};

VS2PSEditorUndergrowth vsEditorUndergrowth(APP2VS indata)
{
    VS2PSEditorUndergrowth outdata;
    outdata.Pos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    outdata.Pos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    outdata.Pos = mul(outdata.Pos, mViewProj);
    outdata.Tex0 = indata.TexCoord0;
    return outdata;
}

float4 psEditorUndergrowth(VS2PSEditorUndergrowth indata) : COLOR
{
    return tex2D(sampler0_point, indata.Tex0);
}

technique EditorUndergrowth
{
    pass p0
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsEditorUndergrowth();
        PixelShader = compile ps_2_0 psEditorUndergrowth();
    }
}

technique EditorOvergrowth
{
    pass p0
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsEditorUndergrowth();
        PixelShader = compile ps_2_0 psEditorUndergrowth();
    }
}

technique EditorOvergrowthShadow
{
    pass p0
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsEditorUndergrowth();
        PixelShader = compile ps_2_0 psEditorUndergrowth();
    }
}

technique EditorMaterialmap
{
    pass p0
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsEditorUndergrowth();
        PixelShader = compile ps_2_0 psEditorUndergrowth();
    }
}

VS2PSEditorUndergrowth vsEditorHemimap(APP2VS indata)
{
    VS2PSEditorUndergrowth outdata;
    outdata.Pos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    outdata.Pos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    outdata.Pos = mul(outdata.Pos, mViewProj);
    outdata.Tex0 = indata.TexCoord0 * vTexOffset.zz + vTexOffset.xy;
    outdata.Tex0.y = 1.0 - outdata.Tex0.y;
    return outdata;
}

float4 psEditorHemimap(VS2PSEditorUndergrowth indata) : COLOR
{
    float4 hemimap = tex2D(sampler0, indata.Tex0);
    return float4(hemimap.rgb, 1.0);
}

float4 psEditorHemimapAlpha(VS2PSEditorUndergrowth indata) : COLOR
{
    float4 hemimap = tex2D(sampler0, indata.Tex0);
    return float4(hemimap.aaa, 1.0);
}

technique EditorHemimap
{
    pass p0
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsEditorHemimap();
        PixelShader = compile ps_2_0 psEditorHemimap();
    }

    pass p1
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsEditorHemimap();
        PixelShader = compile ps_2_0 psEditorHemimapAlpha();
    }

}

// Lightmap generation techniques
float4x4	vSETTransXZ : SETTRANSXZ;

PS2FB PShader_LightmapGeneration(VS2PS indata)
{
    PS2FB outdata;
    // Output pure black.
    outdata.Col = float4(0.0, 0.0, 0.0, 1.0);
    return outdata;
}

VS2PS VShader_LightmapGeneration_QP(APP2VS indata)
{
    VS2PS outdata;
    outdata.Pos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    outdata.Pos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    outdata.Pos = mul(outdata.Pos, mViewProj);
    outdata.Tex0 = indata.TexCoord0;
    outdata.Tex1 = indata.TexCoord0;
    outdata.Fog = saturate(calcFog(outdata.Pos.w));
    outdata.Color = 1.0;
    return outdata;
}

VS2PS VShader_LightmapGeneration_SP(APP2VS indata)
{
    VS2PS outdata;
    outdata.Pos.xz = mul(float4(indata.Pos0.xy, 0.0, 1.0), vSETTransXZ).xy;
    outdata.Pos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;
    outdata.Pos = mul(outdata.Pos, mViewProj);
    outdata.Tex0 = indata.TexCoord0;
    outdata.Tex1 = indata.TexCoord0;
    outdata.Fog = saturate(calcFog(outdata.Pos.w));
    outdata.Color = 1;
    return outdata;
}

technique lightmapGeneration <
    int DetailLevel = DLUltraHigh+DLVeryHigh;
    int Compatibility = CMPR300+CMPNV3X;
>
{
    pass p0 // QuadPatchs
    {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        CullMode = CW;
        ZEnable = true;
        ZWriteEnable = true;
        FogEnable = FALSE;
        VertexShader = compile vs_2_0 VShader_LightmapGeneration_QP();
        PixelShader = compile ps_2_0 PShader_LightmapGeneration();
    }

    pass p0 // SurroundingPatchs
    {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        CullMode = CW;
        ZEnable = true;
        ZWriteEnable = true;
        FogEnable = FALSE;
        VertexShader = compile vs_2_0 VShader_LightmapGeneration_SP();
        PixelShader = compile ps_2_0 PShader_LightmapGeneration();
    }
}






struct SETVS2PS
{
    float4  Pos : POSITION;
    float   WaterFade : TEXCOORD0;
    float2  Tex1 : TEXCOORD1;
    float2  Tex2 : TEXCOORD2;
    float2  Tex3 : TEXCOORD3;
    float2  BiFixTex : TEXCOORD4;
    float2  BiFixTex2 : TEXCOORD6;
    float   Fog : FOG;
    float3  BlendValue : TEXCOORD5;
};

struct SETAPP2VS
{
    float2	Pos0 : POSITION0;
    float2	TexCoord0 : TEXCOORD0;
    float4	Pos1 : POSITION1;
    float3	Normal : NORMAL;
};

SETVS2PS vsSET(SETAPP2VS indata)
{
    SETVS2PS outdata;

    float4 wPos;
    wPos.xz = mul(float4(indata.Pos0.xy, 0.0, 1.0), vSETTransXZ).xy;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    outdata.BiFixTex = indata.TexCoord0 * vSETBiFixTex.x + vSETBiFixTex.y;
    outdata.BiFixTex2 = indata.TexCoord0 * vSETBiFixTex2.x + vSETBiFixTex2.y;
    outdata.WaterFade = 1.0 - saturate((waterHeight - wPos.y) / 3.0f);

    float3 tex = float3(wPos.z * vTexScale.z, -(indata.Pos1.x * vTexScale.y) , wPos.x * vTexScale.x);
    outdata.Pos = mul(wPos, mViewProj);

    float2 xPlaneTexCord = tex.xy;
    float2 yPlaneTexCord = tex.zx;
    float2 zPlaneTexCord = tex.zy;

    outdata.Fog = saturate(calcFog(outdata.Pos.w));

    outdata.Tex1 = yPlaneTexCord * vFarTexTiling.z;
    outdata.Tex2.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex2.y += vFarTexTiling.w;
    outdata.Tex3.xy = zPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex3.y += vFarTexTiling.w;

    outdata.BlendValue = saturate(abs(indata.Normal) - vBlendMod);
    float tot = dot(1.0, outdata.BlendValue);
    outdata.BlendValue /= tot;
    return outdata;
}

float4 psSETNormal(SETVS2PS indata) : COLOR
{
    float4 colormap = tex2D(sampler0Clamp, indata.BiFixTex2);

    float4 lightmap = tex2D(sampler1Clamp, indata.BiFixTex);
    float4 light = (lightmap.y * vSunColor * 4.0) + (lightmap.z * vGIColor * 2.0) + (lightmap.x * vPointColor);

    float4 lowComponent = tex2D(sampler4Clamp, indata.BiFixTex2);
    float4 yplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex1);
    float4 xplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex2);
    float4 zplaneLowDetailmap = 2.0 * tex2D(sampler3Wrap, indata.Tex3);

    float4 lowDetailmap = lerp(1, yplaneLowDetailmap.z, lowComponent.x);
    float mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), indata.blendValue.xyz);
    lowDetailmap *= lerp(1.0, mounten, lowComponent.z);

    float4 outColor = lowDetailmap * colormap * light;

    float4 waterOutColor = lerp(terrainWaterColor, outColor, indata.WaterFade);
    return waterOutColor;
}

float4 psSETColorLightingOnly(SETVS2PS indata) : COLOR
{
    float4 colormap = tex2D(sampler0_point, indata.BiFixTex2);

    float4 lightmap = tex2D(sampler1_point, indata.BiFixTex);
    float4 light = (lightmap.y * vSunColor * 4.0) + (lightmap.z * vGIColor * 2.0) + (lightmap.x * vPointColor);
    float4 outColor = colormap * light;

    float4 waterOutColor = lerp(terrainWaterColor, outColor, indata.WaterFade);
    return waterOutColor;
}

technique SurroundingEditorTerrain <
    int DetailLevel = DLUltraHigh + DLVeryHigh;
    int Compatibility = CMPR300 + CMPNV3X;
>
{
    pass p0 // Normal
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;
        FogEnable = TRUE;
        VertexShader = compile vs_2_0 vsSET();
        PixelShader = compile ps_2_0 psSETNormal();
    }
    pass p1 // ColorLighting Only
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;
        FogEnable = TRUE;
        VertexShader = compile vs_2_0 vsSET();
        PixelShader = compile ps_2_0 psSETColorLightingOnly();
    }
}
