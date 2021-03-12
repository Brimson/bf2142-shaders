#line 2 "TerrainShader_nv3x.fx"

// -- Basic morphed technique

struct APP2VS_BM_Dx9
{
    vec4 Pos0 : POSITION0;
    vec4 Pos1 : POSITION1;
    vec4 MorphDelta : POSITION2;
    vec2 TexCoord0 : TEXCOORD0;
    vec3 Normal : NORMAL;
};

struct VS2PS_BM_Dx9_Base
{
    vec4 Pos : POSITION;
    vec2 Tex0 : TEXCOORD0;
};

vec4 psDx9_BM_Base(VS2PS_BM_Dx9_Base indata) : COLOR
{
    vec4 lightmap = tex2D(sampler0Clamp, indata.Tex0);
    vec4 light = (lightmap.z * vGIColor) * 0.5;
    light.w = saturate(lightmap.y);
    return light;
}

VS2PS_BM_Dx9_Base vsDx9_BM_Base(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9_Base outdata;

    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    // wPos.yw = indata.Pos1.xw;

    scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
    scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
    wPos.y -= yDelta * vScaleTransY.x;

    outdata.Pos = mul(wPos, mViewProj);
    outdata.Tex0 = indata.TexCoord0;

    return outdata;
}

struct VS2PS_BM_Dx9_PPPt
{
    vec4 Pos : POSITION;
    vec3 wPos : TEXCOORD0;
    vec3 Normal : TEXCOORD1;
};

vec4 psDx9_BM_PPPt(VS2PS_BM_Dx9_PPPt indata) : COLOR
{
    return vec4(calcPVPointTerrain(indata.wPos, indata.Normal), 0.0) * 0.5;
}

VS2PS_BM_Dx9_PPPt vsDx9_BM_PPPt(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9_PPPt outdata;


    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    // wPos.yw = indata.Pos1.xw;

    scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
    scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
    wPos.y -= yDelta * vScaleTransY.x;

    outdata.Pos = mul(wPos, mViewProj);
    outdata.Normal = indata.Normal;
    outdata.wPos = wPos.xyz;

    return outdata;
}


struct VS2PS_BM_Dx9
{
    vec4 Pos : POSITION;
    vec2 Tex0 : TEXCOORD0;
    vec4 Color : COLOR0;
};

vec4 psDx9_BM_Pt(VS2PS_BM_Dx9 indata) : COLOR
{
    return indata.Color * 0.5;
}

VS2PS_BM_Dx9 vsDx9_BM_Pt(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9 outdata;

    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    // wPos.yw = indata.Pos1.xw;

    scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
    scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
    wPos.y -= yDelta * vScaleTransY.x;

    outdata.Pos = mul(wPos, mViewProj);
    outdata.Tex0 = indata.TexCoord0;
    outdata.Color = vec4(calcPVPointTerrain(wPos.xyz, indata.Normal), 0);

    return outdata;
}

vec4 psDx9_BM_Sp(VS2PS_BM_Dx9 indata) : COLOR
{
    return indata.Color * 0.5;
}

VS2PS_BM_Dx9 vsDx9_BM_Sp(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9 outdata;

    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    // wPos.yw = indata.Pos1.xw;

    scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
    scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
    wPos.y -= yDelta * vScaleTransY.x;

    outdata.Pos = mul(wPos, mViewProj);
    outdata.Tex0 = indata.TexCoord0;
    outdata.Color = vec4(calcPVSpot(spotLight, wPos, indata.Normal), 0);

    return outdata;
}

technique Dx9Style_BM_States <bool Restore = true;> {
    pass BeginStates
    {
        CullMode = CW;
    }

    pass EndStates { }
}

struct VS2PS_BM_Dx9_MulDFast
{
    vec4 Pos : POSITION;
    vec2 Tex0 : TEXCOORD0;
    vec4 Tex1 : TEXCOORD1;
    scalar Fog : FOG;
};

vec4 psDx9_BM_MulDFast(VS2PS_BM_Dx9_MulDFast indata) : COLOR
{
    // return indata.BlendValue.x;

    vec4 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);
    vec4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);
    vec4 light = (accumlights.w * vSunColor) + accumlights * 2.0;

    return colormap * light;
}

VS2PS_BM_Dx9_MulDFast vsDx9_BM_MulDFast(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9_MulDFast outdata;

    vec4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    wPos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;

    outdata.Pos = mul(wPos, mViewProj);

    outdata.Tex0.xy = indata.TexCoord0;
    outdata.Tex1.xy = outdata.Pos.xy/outdata.Pos.w;
    outdata.Tex1.xy = outdata.Tex1.xy * 0.5 + 0.5;
    outdata.Tex1.y = 1.0 - outdata.Tex1.y;
    outdata.Tex1.xy += vTexProjOffset;
    outdata.Tex1.xy = outdata.Tex1.xy * outdata.Pos.w;
    outdata.Tex1.zw = outdata.Pos.zw;

    outdata.Fog = calcFog(outdata.Pos.w);

    return outdata;
}

struct VS2PS_BM_Dx9_MulD
{
    vec4 Pos    : POSITION;
    vec2 Tex0a  : TEXCOORD0;
    vec2 Tex0b  : TEXCOORD3;
    vec4 Tex1   : TEXCOORD1;
    vec2 Tex2a  : TEXCOORD2;
    vec2 Tex2b  : TEXCOORD4;
    vec4 BlendValueAndWater : COLOR0;
    scalar	Fog : FOG;
};

vec4 psDx9_BM_MulD2(VS2PS_BM_Dx9_MulD indata) : COLOR
{
    // return indata.BlendValue.x;
    vec4 colormap = tex2D(sampler0Clamp, indata.Tex0a);
    vec4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);
    vec4 light = ((accumlights.w * vSunColor) + accumlights) * 2.0;
    return colormap * light;
}

vec4 psDx9_BM_MulD(VS2PS_BM_Dx9_MulD indata) : COLOR
{
    vec4 colormap = tex2D(sampler0Clamp, indata.Tex0a);
    vec4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);
    vec4 light = ((accumlights.w * vSunColor) + accumlights) * 2.0;

    vec4 lowComponent = tex2D(sampler5Clamp, indata.Tex0a);

    vec4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex0b);
    vec4 xplaneLowDetailmap = tex2D(sampler4Wrap2, indata.Tex2a);
    vec4 zplaneLowDetailmap = tex2D(sampler4Wrap3, indata.Tex2b);

    scalar mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x,zplaneLowDetailmap.y), indata.BlendValueAndWater.xyz);

    vec4 outColor = colormap * light * 4.0 * lerp(0.5, yplaneLowDetailmap.z, lowComponent.x) * lerp(0.5, mounten, lowComponent.z);
    return lerp(terrainWaterColor, outColor, indata.BlendValueAndWater.w);
}

VS2PS_BM_Dx9_MulD vsDx9_BM_MulD(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9_MulD outdata;

    vec4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    wPos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;

    scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
    scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
    wPos.y -= yDelta * vScaleTransY.x;

    outdata.BlendValueAndWater.w = 1.0 - saturate((waterHeight - wPos.y) / 3.0f);

    vec3 tex = vec3(indata.Pos0.y * vTexScale.z, -(indata.Pos1.x - yDelta) * vTexScale.y, indata.Pos0.x * vTexScale.x);
    vec2 xPlaneTexCord = tex.xy;
    vec2 yPlaneTexCord = tex.zx;
    vec2 zPlaneTexCord = tex.zy;

    outdata.Pos = mul(wPos, mViewProj);

    outdata.Tex0a = indata.TexCoord0; // frac(yPlaneTexCord);

    outdata.Tex0b = yPlaneTexCord * vFarTexTiling.z;
    outdata.Tex2a = xPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex2a.y += vFarTexTiling.w;
    outdata.Tex2b = zPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex2b.y += vFarTexTiling.w;

    outdata.BlendValueAndWater.xyz = saturate(abs(indata.Normal) - vBlendMod);
    scalar tot = dot(1.0, outdata.BlendValueAndWater.xyz);
    outdata.BlendValueAndWater.xyz /= tot;

    outdata.Tex1.xy = outdata.Pos.xy/outdata.Pos.w;
    outdata.Tex1.xy = outdata.Tex1.xy * 0.5 + 0.5;
    outdata.Tex1.y = 1.0 - outdata.Tex1.y;
    outdata.Tex1.xy += vTexProjOffset;
    outdata.Tex1.xy = outdata.Tex1.xy * outdata.Pos.w;
    outdata.Tex1.zw = outdata.Pos.zw;

    outdata.Fog = calcFog(outdata.Pos.w);

    outdata.Tex0a = indata.TexCoord0; // frac(yPlaneTexCord);

    return outdata;
}

struct VS2PS_BM_Dx9_MulDDetail
{
    vec4 Pos : POSITION;
    vec4 Tex0 : TEXCOORD0;
    vec4 Tex1 : TEXCOORD1;
    vec4 Tex3 : TEXCOORD3;
    vec4 BlendValueAndFade : COLOR0;
    vec2 Tex5 : TEXCOORD6;
    vec2 FogAndWater : COLOR1;
};

vec4 psDx9_BM_MulDDetail(VS2PS_BM_Dx9_MulDDetail indata) : COLOR
{
    vec4 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);

    vec4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);
    vec4 light = ((accumlights.w * vSunColor) + accumlights)*2;

    vec4 component = tex2D(sampler2Clamp, indata.Tex0.xy);
    vec4 detailmap = tex2D(sampler3Wrap, indata.Tex0.wz);

    vec4 lowComponent = tex2D(sampler5Clamp, indata.Tex0.xy);
    scalar chartcontrib = dot(vComponentsel, component);

    vec4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex5);
    vec4 xplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.xy);
    vec4 zplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.wz);

    vec4 lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x);
    scalar mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), indata.BlendValueAndFade.xyz);
    lowDetailmap *= (4.0 * lerp(0.5, mounten, lowComponent.z));

    vec4 bothDetailmap = detailmap * lowDetailmap;
    vec4 detailout = lerp(2*bothDetailmap, lowDetailmap, indata.BlendValueAndFade.w);

    vec4 outColor = detailout * colormap * light;
    vec4 waterOutColor = lerp(terrainWaterColor, outColor, indata.FogAndWater.y);
    vec4 fogWaterOutColor = lerp(fogColor, waterOutColor, indata.FogAndWater.x);

    // return light * chartcontrib;

    return  chartcontrib * fogWaterOutColor;
}

VS2PS_BM_Dx9_MulDDetail vsDx9_BM_MulDDetail(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9_MulDDetail outdata;

    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    // wPos.yw = indata.Pos1.xw;

    scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
    scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
    wPos.y -= yDelta * vScaleTransY.x;

    outdata.FogAndWater.y = 1.0 - saturate((waterHeight - wPos.y) / 3.0f);

    vec3 tex = vec3(indata.Pos0.y * vTexScale.z, -(indata.Pos1.x - yDelta) * vTexScale.y, indata.Pos0.x * vTexScale.x);
    vec2 xPlaneTexCord = tex.xy;
    vec2 yPlaneTexCord = tex.zx;
    vec2 zPlaneTexCord = tex.zy;

    outdata.Pos = mul(wPos, mViewProj);

    outdata.Tex0.xy = yPlaneTexCord;
    outdata.Tex0.wz = yPlaneTexCord.xy * vNearTexTiling.z;

    outdata.Tex5 = yPlaneTexCord * vFarTexTiling.z;
    outdata.Tex3.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex3.y += vFarTexTiling.w;
    outdata.Tex3.wz = zPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex3.z += vFarTexTiling.w;

    outdata.BlendValueAndFade.w = interpVal;

    outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
    scalar tot = dot(1.0, outdata.BlendValueAndFade.xyz);
    outdata.BlendValueAndFade.xyz /= tot;

    outdata.Tex1.xy = outdata.Pos.xy/outdata.Pos.w;
    outdata.Tex1.xy = outdata.Tex1.xy * 0.5 + 0.5;
    outdata.Tex1.y = 1.0 - outdata.Tex1.y;
    outdata.Tex1.xy += vTexProjOffset;
    outdata.Tex1.xy = outdata.Tex1.xy * outdata.Pos.w;
    outdata.Tex1.zw = outdata.Pos.zw;

    outdata.FogAndWater.x = calcFog(outdata.Pos.w);

    return outdata;
}

struct VS2PS_BM_Dx9_MulDDetailMounten
{
    vec4 Pos : POSITION;
    vec4 Tex0 : TEXCOORD0;
    vec4 Tex1 : TEXCOORD1;
    vec4 Tex3 : TEXCOORD3;
    vec4 BlendValueAndFade : COLOR0;
    vec2 Tex5 : TEXCOORD5;
    vec4 Tex6 : TEXCOORD6;
    vec2 FogAndWater : COLOR1;
};

vec4 psDx9_BM_MulDDetailMounten(VS2PS_BM_Dx9_MulDDetailMounten indata) : COLOR
{
    vec4 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);

    vec4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);
    vec4 light = ((accumlights.w * vSunColor) + accumlights) * 2.0;

    vec4 component = tex2D(sampler2Clamp, indata.Tex0.xy);
    vec4 yplaneDetailmap = tex2D(sampler3Wrap, indata.Tex0.wz);
    vec4 xplaneDetailmap = tex2D(sampler6Wrap, indata.Tex6.xy);
    vec4 zplaneDetailmap = tex2D(sampler6Wrap, indata.Tex6.wz);

    vec4 lowComponent = tex2D(sampler5Clamp, indata.Tex0.xy);
    scalar chartcontrib = dot(vComponentsel, component);

    vec4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex5);
    vec4 xplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.xy);
    vec4 zplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.wz);

    vec4 lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x);
    scalar mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), indata.BlendValueAndFade.xyz);

    lowDetailmap *= (4.0 * lerp(0.5, mounten, lowComponent.z));

    vec4 detailmap = (xplaneDetailmap * indata.BlendValueAndFade.x) +
                     (yplaneDetailmap * indata.BlendValueAndFade.y) +
                     (zplaneDetailmap * indata.BlendValueAndFade.z);

    vec4 bothDetailmap = detailmap * lowDetailmap;
    vec4 detailout = lerp(2.0 * bothDetailmap, lowDetailmap, indata.BlendValueAndFade.w);

    vec4 outColor = detailout * colormap * light;
    vec4 waterOutColor = lerp(terrainWaterColor, outColor, indata.FogAndWater.y);
    vec4 fogWaterOutColor = lerp(fogColor, waterOutColor, indata.FogAndWater.x);
    return  chartcontrib * fogWaterOutColor;
}

VS2PS_BM_Dx9_MulDDetailMounten vsDx9_BM_MulDDetailMounten(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9_MulDDetailMounten outdata;

    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    // wPos.yw = indata.Pos1.xw;

    scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
    scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
    wPos.y -= yDelta * vScaleTransY.x;

    outdata.FogAndWater.y = 1.0 - saturate((waterHeight - wPos.y) / 3.0f);

    vec3 tex = vec3(indata.Pos0.y * vTexScale.z, -(indata.Pos1.x - yDelta) * vTexScale.y, indata.Pos0.x * vTexScale.x);
    vec2 xPlaneTexCord = tex.xy;
    vec2 yPlaneTexCord = tex.zx;
    vec2 zPlaneTexCord = tex.zy;

    outdata.Pos = mul(wPos, mViewProj);

    outdata.Tex0.xy = yPlaneTexCord;
    outdata.Tex0.wz = yPlaneTexCord.xy * vNearTexTiling.z;
    outdata.Tex6.xy = xPlaneTexCord.xy * vNearTexTiling.xy;
    outdata.Tex6.y += vNearTexTiling.w;
    outdata.Tex6.wz = zPlaneTexCord.xy * vNearTexTiling.xy;
    outdata.Tex6.z += vNearTexTiling.w;

    outdata.Tex5 = yPlaneTexCord * vFarTexTiling.z;
    outdata.Tex3.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex3.y += vFarTexTiling.w;
    outdata.Tex3.wz = zPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex3.z += vFarTexTiling.w;

    outdata.BlendValueAndFade.w = interpVal;

    outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
    scalar tot = dot(1.0, outdata.BlendValueAndFade.xyz);
    outdata.BlendValueAndFade.xyz /= tot;

    outdata.Tex1.xy = outdata.Pos.xy / outdata.Pos.w;
    outdata.Tex1.xy = outdata.Tex1.xy * 0.5 + 0.5;
    outdata.Tex1.y = 1.0 - outdata.Tex1.y;
    outdata.Tex1.xy += vTexProjOffset;
    outdata.Tex1.xy = outdata.Tex1.xy * outdata.Pos.w;
    outdata.Tex1.zw = outdata.Pos.zw;

    outdata.FogAndWater.x = calcFog(outdata.Pos.w);

    return outdata;
}


struct VS2PS_BM_Dx9_MulDDetailWithEnvMap
{
    vec4 Pos : POSITION;
    vec4 Tex0 : TEXCOORD0;
    vec4 Tex1 : TEXCOORD1;
    vec4 Tex3 : TEXCOORD3;
    vec4 BlendValueAndFade : COLOR0;
    vec2 Tex5 : TEXCOORD6;
    vec3 EnvMap : TEXCOORD7;
    vec2 FogAndWater : COLOR1;
};

vec4 psDx9_BM_MulDDetailWithEnvMap(VS2PS_BM_Dx9_MulDDetailWithEnvMap indata) : COLOR
{
    vec4 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);

    vec4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);
    vec4 light = (accumlights.w * vSunColor + accumlights) * 2.0;

    vec4 component = tex2D(sampler2Clamp, indata.Tex0.xy);
    vec4 detailmap = tex2D(sampler3Wrap, indata.Tex0.wz);

    vec4 envmapColor = texCUBE(sampler6Cube, indata.EnvMap);

    vec4 lowComponent = tex2D(sampler5Clamp, indata.Tex0.xy);
    scalar chartcontrib = dot(vComponentsel, component);

    vec4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex5);
    vec4 xplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.xy);
    vec4 zplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.wz);

    vec4 lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x);
    scalar mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), indata.BlendValueAndFade.xyz);
    lowDetailmap *= (4.0 * lerp(0.5, mounten, lowComponent.z));

    vec4 bothDetailmap = 2.0 * detailmap * lowDetailmap;
    vec4 detailout = lerp(lowDetailmap, bothDetailmap, indata.BlendValueAndFade.w);
    vec4 outColor = lerp(detailout * colormap * light, envmapColor, detailmap.w * indata.BlendValueAndFade.w);
    // vec4 outColor = lerp(detailout * colormap * light, envmapColor, indata.EnvMap.w * detailmap.w * indata.BlendValueAndFade.w);
    // outColor = indata.EnvMap.w;

    vec4 waterOutColor = lerp(terrainWaterColor, outColor, indata.FogAndWater.y);
    vec4 fogWaterOutColor = lerp(fogColor, waterOutColor, indata.FogAndWater.x);
    return  chartcontrib * fogWaterOutColor;
}

VS2PS_BM_Dx9_MulDDetailWithEnvMap vsDx9_BM_MulDDetailWithEnvMap(APP2VS_BM_Dx9 indata)
{
    VS2PS_BM_Dx9_MulDDetailWithEnvMap outdata;

    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    // wPos.yw = indata.Pos1.xw;

    scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
    scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
    wPos.y -= yDelta * vScaleTransY.x;

    outdata.FogAndWater.y = 1.0 - saturate((waterHeight - wPos.y) / 3.0f);

    vec3 tex = vec3(indata.Pos0.y * vTexScale.z, -(indata.Pos1.x - yDelta) * vTexScale.y, indata.Pos0.x * vTexScale.x);
    vec2 xPlaneTexCord = tex.xy;
    vec2 yPlaneTexCord = tex.zx;
    vec2 zPlaneTexCord = tex.zy;

    outdata.Pos = mul(wPos, mViewProj);

    outdata.Tex0.xy = yPlaneTexCord;
    outdata.Tex0.wz = yPlaneTexCord.xy * vNearTexTiling.z;

    outdata.Tex5 = yPlaneTexCord * vFarTexTiling.z;
    outdata.Tex3.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex3.y += vFarTexTiling.w;
    outdata.Tex3.wz = zPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex3.z += vFarTexTiling.w;

    outdata.BlendValueAndFade.w = 1.0 - interpVal;

    outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
    scalar tot = dot(1.0, outdata.BlendValueAndFade.xyz);
    outdata.BlendValueAndFade.xyz /= tot;

    outdata.Tex1.xy = outdata.Pos.xy/outdata.Pos.w;
    outdata.Tex1.xy = outdata.Tex1.xy * 0.5 + 0.5;
    outdata.Tex1.y = 1.0 - outdata.Tex1.y;
    outdata.Tex1.xy += vTexProjOffset;
    outdata.Tex1.xy = outdata.Tex1.xy * outdata.Pos.w;
    outdata.Tex1.zw = outdata.Pos.zw;

    outdata.FogAndWater.x = calcFog(outdata.Pos.w);

    // Environment map
    // scalar dist = length(wPos.xyz - vCamerapos.xyz);
    vec3 worldEyeVec = normalize(wPos.xyz - vCamerapos.xyz);
    outdata.EnvMap = normalize(reflect(worldEyeVec, vec3(0.0, 1.0, 0.0)));
    // outdata.EnvMap.xyz = normalize(reflect(worldEyeVec, vec3(0,1,0)));
    // outdata.EnvMap.w = saturate((1 - abs(worldEyeVec.y + 0.5)) + saturate(1 - 5/dist)); //dot(float3(0,1,0), worldEyeVec);

    return outdata;
}




struct VS2PS_DirectionalLightShadows
{
    vec4 Pos : POSITION;
    vec2 Tex0 : TEXCOORD0;
    vec4 ShadowTex : TEXCOORD1;
};



vec4 psDirectionalLightShadows(VS2PS_DirectionalLightShadows indata) : COLOR
{
    vec4 lightmap = tex2D(sampler0Clamp, indata.Tex0);

    vec4 texel = vec4(1.0/1024.0, 1.0/1024.0, 0.0, 0.0);
    vec4 samples;
    samples.x = tex2Dproj(sampler2PointClamp, indata.ShadowTex);
    samples.y = tex2Dproj(sampler2PointClamp, indata.ShadowTex + vec4(texel.x, 0.0, 0.0, 0.0));
    samples.z = tex2Dproj(sampler2PointClamp, indata.ShadowTex + vec4(0.0, texel.y, 0.0, 0.0));
    samples.w = tex2Dproj(sampler2PointClamp, indata.ShadowTex + texel);

    vec4 cmpbits = samples == 1.f;
    scalar avgShadowValue = dot(cmpbits, 0.25);

    vec4 light = saturate(lightmap.z * vGIColor) * 0.5;
    if (avgShadowValue < lightmap.y)
        light.w = 1.0 - saturate(4.0 - indata.ShadowTex.z) + avgShadowValue.x;
    else
        light.w = lightmap.y;

    return light;
}

vec4 psDirectionalLightShadowsNV(VS2PS_DirectionalLightShadows indata) : COLOR
{
    return vec4(indata.Tex0.x, indata.Tex0.y, 0, 0);
    vec2 texel = vec2(1.0/1024.0, 1.0/1024.0);
    scalar avgShadowValue = tex2Dproj(sampler2Clamp, indata.ShadowTex); // HW percentage closer filtering.

    vec4 shadow = saturate(avgShadowValue.x * 0.6 + 0.4);
    vec4 lightmap = tex2D(sampler0Clamp, indata.Tex0);
    return min(shadow, lightmap);
}

VS2PS_DirectionalLightShadows vsDirectionalLightShadows(APP2VS_BM_Dx9 indata)
{
    VS2PS_DirectionalLightShadows outdata;

    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    // wPos.yw = indata.Pos1.xw;

    scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
    scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
    scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
    wPos.y -= yDelta * vScaleTransY.x;

    outdata.Pos = mul(wPos, mViewProj);
    outdata.ShadowTex = mul(wPos, mLightVP);
    outdata.Tex0 = indata.TexCoord0;

    return outdata;
}

struct VS2PS_DynamicShadowmap
{
    vec4 Pos : POSITION;
    vec4 ShadowTex : TEXCOORD1;
};


vec4 psDynamicShadowmap(VS2PS_DynamicShadowmap indata) : COLOR
{
    scalar avgShadowValue = tex2Dproj(sampler2PointClamp, indata.ShadowTex) == 1.0;
    return 1.0 - saturate(4.0 - indata.ShadowTex.z) + avgShadowValue.x;
}

VS2PS_DynamicShadowmap vsDynamicShadowmap(APP2VS_BM_Dx9 indata)
{
    VS2PS_DynamicShadowmap outdata;

    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy + vScaleTransY.zw;
    // wPos.yw = indata.Pos1.xw;

    outdata.Pos = mul(wPos, mViewProj);
    outdata.ShadowTex = mul(wPos, mLightVP);

    return outdata;
}

technique Dx9Style_BM
{
    pass baseLightmap // p0
    {
        CullMode = CW;
        // ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;
        FogEnable = false;
        VertexShader = compile vs_3_0 vsDx9_BM_Base();
        PixelShader = compile ps_3_0 psDx9_BM_Base();
    }

    pass pointlight // p1
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        VertexShader = compile vs_3_0 vsDx9_BM_Pt();
        PixelShader = compile ps_3_0 psDx9_BM_Pt();
    }

    pass spotlight // p2
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;

        VertexShader = compile vs_3_0 vsDx9_BM_Sp();
        PixelShader = compile ps_3_0 psDx9_BM_Sp();
    }

    pass mulDiffuse // p3
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        // FogEnable = false;
        FogEnable = true;
        SrcBlend = ONE;
        DestBlend = ONE;
        VertexShader = compile vs_3_0 vsDx9_BM_MulD();
        PixelShader = compile ps_3_0 psDx9_BM_MulD();
        // PixelShader = compile ps_3_0 psDx9_BM_MulD();
    }

    pass mulDiffuseDetail //p4
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        // ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = false;
        VertexShader = compile vs_3_0 vsDx9_BM_MulDDetail();
        PixelShader = compile ps_3_0 psDx9_BM_MulDDetail();
    }

    pass mulDiffuseDetailMounten // p5
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        FogEnable = false;
        // ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        VertexShader = compile vs_3_0 vsDx9_BM_MulDDetailMounten();
        PixelShader = compile ps_3_0 psDx9_BM_MulDDetailMounten();
    }

    pass { } // p6 tunnels (removed)
    pass DirectionalLightShadows //p7
    {
        CullMode = CW;
        // ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;
        SrcBlend = DESTCOLOR;
        DestBlend = ZERO;
        VertexShader = compile vs_3_0 vsDirectionalLightShadows();
        PixelShader = compile ps_3_0 psDirectionalLightShadows();
    }

    pass DirectionalLightShadowsNV	//p8
    {
        CullMode = CW;
        // ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = DESTCOLOR;
        DestBlend = ZERO;
        VertexShader = compile vs_3_0 vsDirectionalLightShadows();
        PixelShader = compile ps_3_0 psDirectionalLightShadowsNV();
    }

    pass DynamicShadowmap	//p9
    {
        CullMode = CW;
        // ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = DESTCOLOR;
        DestBlend = ZERO;
        VertexShader = compile vs_3_0 vsDynamicShadowmap();
        PixelShader = compile ps_3_0 psDynamicShadowmap();
    }

    pass  {} // p10

    pass mulDiffuseDetailWithEnvMap	//p11
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        // ColsorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = false;
        VertexShader = compile vs_3_0 vsDx9_BM_MulDDetailWithEnvMap();
        PixelShader = compile ps_3_0 psDx9_BM_MulDDetailWithEnvMap();
    }

    pass mulDiffuseFast		//p12
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        // FogEnable = false;
        FogEnable = true;
        VertexShader = compile vs_3_0 vsDx9_BM_MulDFast();
        PixelShader = compile ps_3_0 psDx9_BM_MulDFast();
    }

    pass PPPointlight		//p13
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        VertexShader = compile vs_3_0 vsDx9_BM_PPPt();
        PixelShader = compile ps_3_0 psDx9_BM_PPPt();
    }
}
























// Surrounding Terrain

struct STAPP2VSNormal
{
    vec2	Pos0 : POSITION0;
    vec2	TexCoord0 : TEXCOORD0;
    vec4	Pos1 : POSITION1;
    vec3	Normal : NORMAL;
};

struct STVS2PSNormal
{
    vec4	Pos : POSITION;
    vec2	Tex0 : TEXCOORD0;
    vec2	Tex1 : TEXCOORD1;
    vec2	Tex2 : TEXCOORD2;
    vec2	Tex3 : TEXCOORD3;
    scalar	Fog : Fog;
    vec3	BlendValue : TEXCOORD5;
};

STVS2PSNormal vsSTNormal(STAPP2VSNormal indata)
{
    STVS2PSNormal outdata;

    outdata.Pos.xz = mul(vec4(indata.Pos0.xy,0,1), vSTTransXZ).xy;
    outdata.Pos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;
    outdata.Tex0 = indata.TexCoord0;

    //	vec3 tex = vec3((indata.Pos0.y * vTexScale.z), -(((indata.Pos1.x) * vTexScale.y)) , (indata.Pos0.x * vTexScale.x));
    vec3 tex = vec3(outdata.Pos.z * vTexScale.z, -(indata.Pos1.x * vTexScale.y) , outdata.Pos.x * vTexScale.x);
    vec2 xPlaneTexCord = tex.xy;
    vec2 yPlaneTexCord = tex.zx;
    vec2 zPlaneTexCord = tex.zy;

    outdata.Pos = mul(outdata.Pos, mViewProj);
    outdata.Fog = calcFog(outdata.Pos.w);

    outdata.Tex1 = yPlaneTexCord * vFarTexTiling.z;
    outdata.Tex2.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex2.y += vFarTexTiling.w;
    outdata.Tex3.xy = zPlaneTexCord.xy * vFarTexTiling.xy;
    outdata.Tex3.y += vFarTexTiling.w;

    outdata.BlendValue = saturate(abs(indata.Normal) - vBlendMod);
    scalar tot = dot(1.0, outdata.BlendValue);
    outdata.BlendValue /= tot;

    return outdata;
}

vec4 psSTNormal(STVS2PSNormal indata) : COLOR
{
    vec4 colormap = tex2D(sampler0Clamp, indata.Tex0);

    vec4 lowComponent = tex2D(sampler1Clamp, indata.Tex0);
    vec4 yplaneLowDetailmap = tex2D(sampler2Wrap, indata.Tex1);
    vec4 xplaneLowDetailmap = tex2D(sampler2Wrap, indata.Tex2);
    vec4 zplaneLowDetailmap = tex2D(sampler2Wrap, indata.Tex3);

    vec4 lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x);
    scalar mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), indata.BlendValue.xyz);
    lowDetailmap *= lerp(0.5, mounten, lowComponent.z);

    vec4 outColor = lowDetailmap * colormap * 4;

    return outColor;
}



struct STAPP2VSFast
{
    vec2	Pos0 : POSITION0;
    vec2	TexCoord0 : TEXCOORD0;
    vec4	Pos1 : POSITION1;
};

struct STVS2PSFast
{
    vec4	Pos : POSITION;
    vec2	Tex0 : TEXCOORD0;
    scalar	Fog : Fog;
};

STVS2PSFast vsSTFast(STAPP2VSFast indata)
{
    STVS2PSFast outdata;
    outdata.Pos.xz = mul(vec4(indata.Pos0.xy, 0.0, 1.0), vSTTransXZ).xy;
    outdata.Pos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;
    outdata.Tex0 = indata.TexCoord0;
    outdata.Pos = mul(outdata.Pos, mViewProj);
    outdata.Fog = calcFog(outdata.Pos.w);
    return outdata;
}

vec4 psSTFast(STVS2PSFast indata) : COLOR
{
    return tex2D(sampler0Clamp, indata.Tex0);
}

technique Dx9Style_SurroundingTerrain
{
    pass p0 // Normal
    {
        // FillMode = WIREFRAME;
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;
        FogEnable = true;
        VertexShader = compile vs_3_0 vsSTNormal();
        PixelShader = compile ps_3_0 psSTNormal();
    }

    pass p1 // Fast
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;
        FogEnable = true;
        VertexShader = compile vs_3_0 vsSTFast();
        PixelShader = compile ps_3_0 psSTFast();
    }
}
