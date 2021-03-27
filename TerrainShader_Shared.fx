#line 2 "TerrainShader_Shared.fx"

// -- Basic morphed technique

sampler ssampler0Clamp = sampler_state
{
    Texture = (texture0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MipFilter = POINT;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler ssampler3Wrap = sampler_state
{
    Texture = (texture3);
    AddressU = WRAP;
    AddressV = WRAP;
    MipFilter = POINT;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler ssampler4Wrap = sampler_state
{
    Texture = (texture4);
    AddressU = WRAP;
    AddressV = WRAP;
    MipFilter = POINT;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

void geoMorphPosition(inout float4 wPos, in float4 MorphDelta, in float morphDeltaAdderSelector, out float yDelta, out float interpVal)
{
    //tl: This is now based on squared values (besides camPos)
    //tl: This assumes that input wPos.w == 1 to work correctly! (it always is)
    //tl: This all works out because camera height is set to height+1 so
    //    camVec becomes (cx, cheight+1, cz) - (vx, 1, vz)
    //tl: YScale is now pre-multiplied into morphselector

    float3 camVec = vCamerapos.xwz-wPos.xwz;
    float cameraDist = dot(camVec, camVec);
    interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);

    yDelta = (dot(vMorphDeltaSelector, MorphDelta) * interpVal) + dot(vMorphDeltaAdder[morphDeltaAdderSelector*256], MorphDelta);
    wPos.y = wPos.y - yDelta;
}

float4 projToLighting(float4 hPos)
{
    //tl: This has been rearranged optimally (I believe) into 1 MUL and 1 MAD,
    //    don't change this without thinking twice.
    //    ProjOffset now includes screen->texture bias as well as half-texel offset
    //    ProjScale is screen->texture scale/invert operation
    // tex = (hpos.x * 0.5 + 0.5 + htexel, hpos.y * -0.5 + 0.5 + htexel, hpos.z, hpos.w)
    float4 tex;
    tex = hPos * vTexProjScale + (vTexProjOffset * hPos.w);
    return tex;
}


struct Shared_APP2VS_Default
{
    float4 Pos0       : POSITION0;
    float4 Pos1       : POSITION1;
    float4 MorphDelta : POSITION2;
    float3 Normal     : NORMAL;
};

struct Shared_VS2PS_ZFillLightmap
{
    float4 Pos  : POSITION;
    float2 Tex0 : TEXCOORD0;
};

//tl: this has now been replaced by inline assembly (because HLSL can't optimize this perfectly)
//float4 Shared_PS_ZFillLightmap(Shared_VS2PS_ZFillLightmap indata) : COLOR

Shared_VS2PS_ZFillLightmap Shared_VS_ZFillLightmap(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_ZFillLightmap outdata;

    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    // tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.Tex0 = float2(0,0);
        return outdata;
    #endif

    float yDelta, interpVal;
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    outdata.Pos = mul(wPos, mViewProj);
    outdata.Tex0 = (indata.Pos0.xy * ScaleBaseUV * vColorLightTex.x) + vColorLightTex.y;

    return outdata;
}

struct Shared_VS2PS_PointLight
{
    float4 Pos   : POSITION;
    float2 Tex0  : TEXCOORD0;
    float4 Color : COLOR0;
};

float4 Shared_PS_PointLight(Shared_VS2PS_PointLight indata) : COLOR
{
    return indata.Color * 0.5;
}

Shared_VS2PS_PointLight Shared_VS_PointLight(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_PointLight outdata;

    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    //tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    float yDelta, interpVal;
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    outdata.Pos = mul(wPos, mViewProj);
    outdata.Tex0 = (indata.Pos0.xy * ScaleBaseUV * vColorLightTex.x) + vColorLightTex.y;

    //tl: uncompress normal
    indata.Normal = indata.Normal * 2.0 - 1.0;
    outdata.Color = float4(calcPVPointTerrain(wPos.xyz, indata.Normal), 0);

    return outdata;
}

struct Shared_VS2PS_LowDetail
{
    float4 Pos   : POSITION;
    float2 Tex0a : TEXCOORD0;
    float2 Tex0b : TEXCOORD3;
    float4 Tex1  : TEXCOORD1;
    #if HIGHTERRAIN
        float2 Tex2a : TEXCOORD2;
        float2 Tex2b : TEXCOORD4;
        float2 Tex3  : TEXCOORD5;
    #endif
    float4 BlendValueAndWater : COLOR0;
    float Fog : FOG;
};

//#define LIGHTONLY 1
float4 Shared_PS_LowDetail(Shared_VS2PS_LowDetail indata) : COLOR
{
    #if DEBUGTERRAIN
        return 1.0;
    #endif
        float4 accumlights = tex2Dproj(sampler1ClampPoint_BoundToStage1, indata.Tex1);
        float4 light = 2 * accumlights.w * vSunColor + accumlights;
    #if LIGHTONLY
        return light;
    #endif

    #if HIGHTERRAIN
        float4 colormap = tex2D(sampler0Clamp, indata.Tex0a.xy);
        float4 lowComponent = tex2D(sampler5Clamp, indata.Tex3);

        float4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex0b);
        float4 xplaneLowDetailmap = tex2D(sampler4Wrap2, indata.Tex2a);
        float4 zplaneLowDetailmap = tex2D(sampler4Wrap3, indata.Tex2b);

        float mounten =    (xplaneLowDetailmap.y * indata.BlendValueAndWater.x) +
                            (yplaneLowDetailmap.x * indata.BlendValueAndWater.y) +
                            (zplaneLowDetailmap.y * indata.BlendValueAndWater.z);
        float4 outColor = 4 * colormap * light * 2 * lerp(0.5, yplaneLowDetailmap.z, lowComponent.x) * lerp(0.5, mounten, lowComponent.z);
        return lerp(outColor, terrainWaterColor, indata.BlendValueAndWater.w);
    #else
        float4 colormap = tex2D(ssampler0Clamp, indata.Tex0a.xy);
        float4 yplaneLowDetailmap = tex2D(ssampler4Wrap, indata.Tex0b);

        float4 outColor = colormap * light * 2;
        outColor = 2 * outColor * lerp(yplaneLowDetailmap.x, yplaneLowDetailmap.z, indata.BlendValueAndWater.y);

        return float4(lerp(outColor.rgb, terrainWaterColor, indata.BlendValueAndWater.w),1);
    #endif
}

Shared_VS2PS_LowDetail Shared_VS_LowDetail(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_LowDetail outdata;

    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    //tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.Tex0a.xy = 0.0;
        outdata.Tex0b = 0.0;
        outdata.Tex1 = 0.0;
    #if HIGHTERRAIN
        outdata.Tex2a = 0.0;
        outdata.Tex2b = 0.0;
    #endif
        outdata.BlendValueAndWater = 0.0;
        outdata.Fog = 1.0;
        return outdata;
    #endif

    float yDelta, interpVal;
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    //tl: uncompress normal
    indata.Normal = indata.Normal * 2 - 1;

    outdata.Tex0a.xy = (indata.Pos0.xy * ScaleBaseUV*vColorLightTex.x) + vColorLightTex.y;

    //tl: changed a few things with this factor:
    // - using (1-a) is unnecessary, we can just invert the lerp in the ps instead.
    // - saturate is unneeded because color interpolators are clamped [0,1] before the pixel shader
    // - by pre-multiplying the waterHeight, we can change the (wh-wp)*c to (-wp*c)+whc i.e. from ADD+MUL to MAD
    outdata.BlendValueAndWater.w = (wPos.y/-3.0) + waterHeight;

    #if HIGHTERRAIN
        float3 tex = float3(indata.Pos0.y * vTexScale.z, wPos.y * vTexScale.y, indata.Pos0.x * vTexScale.x);
        float2 xPlaneTexCord = tex.xy;
        float2 yPlaneTexCord = tex.zx;
        float2 zPlaneTexCord = tex.zy;

        outdata.Tex3 = (yPlaneTexCord*vDetailTex.x) + vDetailTex.y;
        outdata.Tex0b = yPlaneTexCord * vFarTexTiling.z;
        outdata.Tex2a = xPlaneTexCord.xy * vFarTexTiling.xy;
        outdata.Tex2a.y += vFarTexTiling.w;
        outdata.Tex2b = zPlaneTexCord.xy * vFarTexTiling.xy;
        outdata.Tex2b.y += vFarTexTiling.w;
    #else
        //tl: vYPlaneTexScaleAndFarTile = vTexScale * vFarTexTiling.z  //CPU pre-multiplied
        outdata.Tex0b = indata.Pos0.xy * vYPlaneTexScaleAndFarTile.xz;
    #endif

    #if HIGHTERRAIN
        outdata.BlendValueAndWater.xyz = saturate(abs(indata.Normal) - vBlendMod);
        float tot = dot(1, outdata.BlendValueAndWater.xyz);
        outdata.BlendValueAndWater.xyz /= tot;
    #else
        outdata.BlendValueAndWater.xyz = pow(indata.Normal.y,8);
    #endif

    outdata.Tex1 = projToLighting(outdata.Pos);
    outdata.Fog = calcFog(outdata.Pos.w);
    return outdata;
}

struct Shared_VS2PS_DynamicShadowmap
{
    float4 Pos       : POSITION;
    float4 ShadowTex : TEXCOORD1;
    float2 Z         : TEXCOORD2;
};

float4 Shared_PS_DynamicShadowmap(Shared_VS2PS_DynamicShadowmap indata) : COLOR
{
    #if NVIDIA
        float avgShadowValue = tex2Dproj(sampler2PointClamp, indata.ShadowTex);
    #else
        float avgShadowValue = tex2Dproj(sampler2PointClamp, indata.ShadowTex) == 1.0;
    #endif
    return  avgShadowValue.x;
}

Shared_VS2PS_DynamicShadowmap Shared_VS_DynamicShadowmap(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_DynamicShadowmap outdata;

    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    //tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    outdata.Pos = mul(wPos, mViewProj);

    outdata.ShadowTex = mul(wPos, mLightVP);
    outdata.ShadowTex.z = 0.999 * outdata.ShadowTex.w;
    outdata.Z.xy = outdata.ShadowTex.z;
    outdata.ShadowTex.z = 0.999 * outdata.ShadowTex.w;

    return outdata;
}






struct Shared_VS2PS_DirectionalLightShadows
{
    float4 Pos       : POSITION;
    float2 Tex0      : TEXCOORD0;
    float4 ShadowTex : TEXCOORD1;
    float2 Z         : TEXCOORD2;
};

Shared_VS2PS_DirectionalLightShadows Shared_VS_DirectionalLightShadows(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_DirectionalLightShadows outdata;

    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    //tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    float yDelta, interpVal;
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);
    outdata.ShadowTex = mul(wPos, mLightVP);
    float sZ = mul(wPos, mLightVPOrtho).z;
    outdata.Z.xy = outdata.ShadowTex.z;
    #if NVIDIA
        outdata.ShadowTex.z = sZ * outdata.ShadowTex.w;
    #else
        outdata.ShadowTex.z = sZ;
    #endif

    outdata.Tex0 = (indata.Pos0.xy * ScaleBaseUV * vColorLightTex.x) + vColorLightTex.y;

    return outdata;
}






struct Shared_VS2PS_UnderWater
{
    float4	Pos : POSITION;
    float4	WaterAndFog : COLOR0;
};

float4 Shared_PS_UnderWater(Shared_VS2PS_UnderWater indata) : COLOR
{
    #if DEBUGTERRAIN
        return float4(1.0, 1.0, 0.0, 1.0);
    #endif
    //tl: use color interpolator instead of texcoord, it makes this shader much shorter!
    float4 fogWaterOutColor = lerp(FogColor, terrainWaterColor, indata.WaterAndFog.y);
    fogWaterOutColor.a = indata.WaterAndFog.x;

    return fogWaterOutColor;
}

Shared_VS2PS_UnderWater Shared_VS_UnderWater(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_UnderWater outdata;

    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    //tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.WaterAndFog = 0.0;
        return outdata;
    #endif

    float yDelta, interpVal;
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    //tl: changed a few things with this factor:
    // - saturate is unneeded because color interpolators are clamped [0,1] before the pixel shader
    // - by pre-multiplying the waterHeight, we can change the (wh-wp)*c to (-wp*c)+whc i.e. from ADD+MUL to MAD
    outdata.WaterAndFog.x = (wPos.y/-3.0) + waterHeight;
    outdata.WaterAndFog.yzw = calcFog(outdata.Pos.w);

    return outdata;
}











// Surrounding Terrain

struct Shared_APP2VS_STNormal
{
    float2 Pos0      : POSITION0;
    float2 TexCoord0 : TEXCOORD0;
    float4 Pos1      : POSITION1;
    float3 Normal    : NORMAL;
};

struct Shared_VS2PS_STNormal
{
    float4	Pos           : POSITION;
    float2	ColorLightTex : TEXCOORD0;
    float2	Tex1          : TEXCOORD1;
    float2	Tex2          : TEXCOORD2;
    float2	Tex3          : TEXCOORD3;
    float2	LowDetailTex  : TEXCOORD4;
    float	Fog           : FOG;
    float3	BlendValue    : TEXCOORD5;
};

Shared_VS2PS_STNormal Shared_VS_STNormal(Shared_APP2VS_STNormal indata)
{
    Shared_VS2PS_STNormal outdata;

    outdata.Pos.xz = mul(float4(indata.Pos0.xy, 0.0, 1.0), vSTTransXZ).xy;
    outdata.Pos.yw = (indata.Pos1.xw * vSTScaleTransY.xy) + vSTScaleTransY.zw;
    outdata.ColorLightTex = (indata.TexCoord0*vSTColorLightTex.x) + vSTColorLightTex.y;
    outdata.LowDetailTex = (indata.TexCoord0*vSTLowDetailTex.x) + vSTLowDetailTex.y;

    float3 tex = float3(outdata.Pos.z * vSTTexScale.z, -(indata.Pos1.x * vSTTexScale.y) , outdata.Pos.x * vSTTexScale.x);
    float2 xPlaneTexCord = tex.xy;
    float2 yPlaneTexCord = tex.zx;
    float2 zPlaneTexCord = tex.zy;

    float4 wPos = outdata.Pos;
    outdata.Pos = mul(wPos, mViewProj);
    outdata.Fog = calcFog(outdata.Pos.w);

    outdata.Tex1.xy = yPlaneTexCord * vSTFarTexTiling.z;
    outdata.Tex2.xy = xPlaneTexCord.xy * vSTFarTexTiling.xy;
    outdata.Tex2.y += vSTFarTexTiling.w;
    outdata.Tex3.xy = zPlaneTexCord.xy * vSTFarTexTiling.xy;
    outdata.Tex3.y += vSTFarTexTiling.w;

    outdata.BlendValue.xyz = saturate(abs(indata.Normal) - vBlendMod);
    float tot = dot(1.0, outdata.BlendValue.xyz);
    outdata.BlendValue.xyz /= tot;

    return outdata;
}

float4 Shared_PS_STNormal(Shared_VS2PS_STNormal indata) : COLOR
{
    float4 colormap = tex2D(sampler0Clamp, indata.ColorLightTex);

    float4 lowComponent = tex2D(sampler5Clamp, indata.LowDetailTex);
    float4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex1.xy);
    float4 xplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex2);
    float4 zplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3);

    float4 lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x);
    float mounten =    (xplaneLowDetailmap.y * indata.BlendValue.x) +
                        (yplaneLowDetailmap.x * indata.BlendValue.y) +
                        (zplaneLowDetailmap.y * indata.BlendValue.z);
    lowDetailmap *= lerp(0.5, mounten, lowComponent.z);
    float4 outColor = lowDetailmap * colormap * 4;
    return outColor;
}

// Surrounding Terrain

technique Shared_SurroundingTerrain
{
    pass p0 // Normal
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;
        FogEnable = true;
        VertexShader = compile vs_2_0 Shared_VS_STNormal();
        PixelShader = compile ps_2_0 Shared_PS_STNormal();
    }
}










float4x4 vpLightMat : vpLightMat;
float4x4 vpLightTrapezMat : vpLightTrapezMat;

struct HI_APP2VS_OccluderShadow
{
    float4 Pos0 : POSITION0;
    float4 Pos1 : POSITION1;
};

struct HI_VS2PS_OccluderShadow
{
    float4 Pos   : POSITION;
    float2 PosZX : TEXCOORD0;
};

float4 calcShadowProjCoords(float4 Pos, float4x4 matTrap, float4x4 matLight)
{
    float4 shadowcoords = mul(Pos, matTrap);
    float lightZ = mul(Pos, matLight).z;
    shadowcoords.z = lightZ*shadowcoords.w;
    return shadowcoords;
}

HI_VS2PS_OccluderShadow Hi_VS_OccluderShadow(HI_APP2VS_OccluderShadow indata)
{
    HI_VS2PS_OccluderShadow outdata;
    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;
    outdata.Pos = calcShadowProjCoords(wPos, vpLightTrapezMat, vpLightMat);
    outdata.PosZX = outdata.Pos.zw;
    return outdata;
}

float4 Hi_PS_OccluderShadow(HI_VS2PS_OccluderShadow indata) : COLOR
{
    #if NVIDIA
        return 0.5;
    #else
        return indata.PosZX.x/indata.PosZX.y;
    #endif
}


technique TerrainOccludershadow
{
    pass occludershadow	//p16
    {
        CullMode = NONE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESS;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        FogEnable = FALSE;

        #if NVIDIA
                ColorWriteEnable = 0;
        #else
                ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        #endif

        VertexShader = compile vs_2_0 Hi_VS_OccluderShadow();
        PixelShader = compile ps_2_0 Hi_PS_OccluderShadow();
    }
}

// New ps_2_0 Shaders

float4 Shared_PS_ZFillLightmap(Shared_VS2PS_ZFillLightmap input) : COLOR
{
    float4 t0 = tex2D(sampler0Clamp, input.Tex0);
    float4 output = 0.0;
    output.xyz = t0.z * vGIColor;
    output.w = saturate(t0.y);
    return output;
}

float4 ZFillLightmapColor : register(c0);
float4 Shared_PS_ZFillLightmap2(Shared_VS2PS_ZFillLightmap input) : COLOR
{
    return ZFillLightmapColor;
}
