#line 2 "TerrainShader_Shared.fx"
// Basic morphed technique

sampler ssampler0Clamp = sampler_state {
    Texture = (texture0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MipFilter = POINT;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler ssampler3Wrap = sampler_state {
    Texture = (texture3);
    AddressU = WRAP;
    AddressV = WRAP;
    MipFilter = POINT;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler ssampler4Wrap = sampler_state {
    Texture = (texture4);
    AddressU = WRAP;
    AddressV = WRAP;
    MipFilter = POINT;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

// void geoMorphPosition(inout vec4 wPos, in vec4 MorphDelta, out scalar yDelta, out scalar interpVal)
void geoMorphPosition(inout vec4 wPos, in vec4 MorphDelta, in scalar morphDeltaAdderSelector, out scalar yDelta, out scalar interpVal)
{
    //tl: This is now based on squared values (besides camPos)
    //tl: This assumes that input wPos.w == 1 to work correctly! (it always is)
    //tl: This all works out because camera height is set to height+1 so
    //    camVec becomes (cx, cheight+1, cz) - (vx, 1, vz)
    //tl: YScale is now pre-multiplied into morphselector

    vec3 camVec = vCamerapos.xwz-wPos.xwz;
    // vec2 camVec = vCamerapos.xz-wPos.xz;
    scalar cameraDist = dot(camVec, camVec);
    interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);

    yDelta = (dot(vMorphDeltaSelector, MorphDelta) * interpVal) + dot(vMorphDeltaAdder[morphDeltaAdderSelector*256], MorphDelta);
    //	yDelta = (dot(vMorphDeltaSelector, MorphDelta) * interpVal) + dot(vMorphDeltaAdder[morphDeltaAdderSelector], MorphDelta);
    wPos.y = wPos.y - yDelta;
}

vec4 projToLighting(vec4 hPos)
{
    vec4 tex;

    // tl: This has been rearranged optimally (I believe) into 1 MUL and 1 MAD,
    //     don't change this without thinking twice.
    //     ProjOffset now includes screen->texture bias as well as half-texel offset
    //     ProjScale is screen->texture scale/invert operation
    // tex = (hpos.x * 0.5 + 0.5 + htexel, hpos.y * -0.5 + 0.5 + htexel, hpos.z, hpos.w)
    tex = hPos * vTexProjScale + (vTexProjOffset * hPos.w);

    return tex;
}


struct Shared_APP2VS_Default
{
    vec4 Pos0 : POSITION0;
    vec4 Pos1 : POSITION1;
    vec4 MorphDelta : POSITION2;
    vec3 Normal : NORMAL;
};

struct Shared_VS2PS_ZFillLightmap
{
    vec4 Pos  : POSITION;
    vec2 Tex0 : TEXCOORD0;
};


// tl: this has now been replaced by inline assembly (because HLSL can't optimize this perfectly)
// vec4 Shared_PS_ZFillLightmap(Shared_VS2PS_ZFillLightmap indata) : COLOR

Shared_VS2PS_ZFillLightmap Shared_VS_ZFillLightmap(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_ZFillLightmap outdata;

    vec4 wPos;
    // wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    // tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.Tex0 = 0.0;
        return outdata;
    #endif

    scalar yDelta, interpVal;
    // geoMorphPosition(wPos, indata.MorphDelta, yDelta, interpVal);
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    outdata.Pos = mul(wPos, mViewProj);
    outdata.Tex0 = (indata.Pos0.xy * ScaleBaseUV * vColorLightTex.x) + vColorLightTex.y;

    return outdata;
}

float4 Shared_PS_ZFillLightmap(Shared_VS2PS_ZFillLightmap input) : COLOR
{
    // Sampler[1] = (sampler0Clamp);
    float4 lightmap = tex2D(sampler0Clamp, input.Tex0); // texld r1, t0
    float4 o; // r0.xyzw
    o.xyz = lightmap.zzz * vGIColor; // mul r0.xyz, r1.z, c0
    o.w = saturate(lightmap.y) // +mov_sat r0.w, r1.y
    return o;
}

// Learnt registers from here. The more you fqing know
// https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-variable-register
float4 col : register(c0);
float4 Shared_PS_ZFillLightmap2() : COLOR
{
    return col;
}

struct Shared_VS2PS_PointLight
{
    vec4 Pos   : POSITION;
    vec2 Tex0  : TEXCOORD0;
    vec4 Color : COLOR0;
};

vec4 Shared_PS_PointLight(Shared_VS2PS_PointLight indata) : COLOR
{
    return indata.Color * 0.5;
}

Shared_VS2PS_PointLight Shared_VS_PointLight(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_PointLight outdata;

    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    // tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    scalar yDelta, interpVal;
    // geoMorphPosition(wPos, indata.MorphDelta, yDelta, interpVal);
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    outdata.Pos = mul(wPos, mViewProj);
    // 	outdata.Tex0 = indata.Pos0.xy * ScaleBaseUV;
    outdata.Tex0 = (indata.Pos0.xy * ScaleBaseUV * vColorLightTex.x) + vColorLightTex.y;

    // tl: uncompress normal
    indata.Normal = indata.Normal * 2 - 1;
    outdata.Color = vec4(calcPVPointTerrain(wPos.xyz, indata.Normal), 0);

    return outdata;
}

struct Shared_VS2PS_LowDetail
{
    vec4    Pos   : POSITION;
    vec2    Tex0a : TEXCOORD0;
    vec2    Tex0b : TEXCOORD3;
    vec4    Tex1  : TEXCOORD1;
    #if HIGHTERRAIN
        vec2 Tex2a : TEXCOORD2;
        vec2 Tex2b : TEXCOORD4;
        vec2 Tex3  : TEXCOORD5;
    #endif
    vec4    BlendValueAndWater : COLOR0;
    scalar  Fog : FOG;
};

//#define LIGHTONLY 1
vec4 Shared_PS_LowDetail(Shared_VS2PS_LowDetail indata) : COLOR
{

    //	return indata.Tex1;
    #if DEBUGTERRAIN
        return 1.0;
    #endif

    vec4 accumlights = tex2Dproj(sampler1ClampPoint_BoundToStage1, indata.Tex1);
    vec4 light = 2.0 * accumlights.w * vSunColor + accumlights;

    #if LIGHTONLY
        return light;
    #endif

    #if HIGHTERRAIN

    vec4 colormap = tex2D(sampler0Clamp, indata.Tex0a.xy);
    vec4 lowComponent = tex2D(sampler5Clamp, indata.Tex3);

    vec4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex0b);
    vec4 xplaneLowDetailmap = tex2D(sampler4Wrap2, indata.Tex2a);
    vec4 zplaneLowDetailmap = tex2D(sampler4Wrap3, indata.Tex2b);

    scalar mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), indata.BlendValueAndWater.xyz);
    vec4 outColor = 4.0 * colormap * light * 2.0 * lerp(0.5, yplaneLowDetailmap.z, lowComponent.x) * lerp(0.5, mounten, lowComponent.z);

    return lerp(outColor, terrainWaterColor, indata.BlendValueAndWater.w);
    #else
        vec4 colormap = tex2D(ssampler0Clamp, indata.Tex0a.xy);
        vec4 yplaneLowDetailmap = tex2D(ssampler4Wrap, indata.Tex0b);

        vec4 outColor = colormap * light * 2;
        outColor = 2.0 * outColor * lerp(yplaneLowDetailmap.x, yplaneLowDetailmap.z, indata.BlendValueAndWater.y);

        return vec4(lerp(outColor.rgb, terrainWaterColor, indata.BlendValueAndWater.w), 1.0);
    #endif
}

Shared_VS2PS_LowDetail Shared_VS_LowDetail(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_LowDetail outdata;

    vec4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    // tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.Tex0a.xy = 0.0;
        outdata.Tex0b = 0.0;;
        outdata.Tex1 = 0.0;;
    #if HIGHTERRAIN
        outdata.Tex2a = 0.0;;
        outdata.Tex2b = 0.0;;
    #endif
        outdata.BlendValueAndWater = 0.0;;
        outdata.Fog = 1.0;
        return outdata;
    #endif

    scalar yDelta, interpVal;
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);
    // geoMorphPosition(wPos, indata.MorphDelta, yDelta, interpVal);

    // tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    // tl: uncompress normal
    indata.Normal = indata.Normal * 2 - 1;

    outdata.Tex0a.xy = (indata.Pos0.xy * ScaleBaseUV * vColorLightTex.x) + vColorLightTex.y;


    //tl: changed a few things with this factor:
    // - using (1-a) is unnecessary, we can just invert the lerp in the ps instead.
    // - saturate is unneeded because color interpolators are clamped [0,1] before the pixel shader
    // - by pre-multiplying the waterHeight, we can change the (wh-wp)*c to (-wp*c)+whc i.e. from ADD+MUL to MAD
     outdata.BlendValueAndWater.w = (wPos.y/-3.0) + waterHeight;

    #if HIGHTERRAIN
        vec3 tex = vec3(indata.Pos0.y * vTexScale.z, wPos.y * vTexScale.y, indata.Pos0.x * vTexScale.x);
        vec2 xPlaneTexCord = tex.xy;
        vec2 yPlaneTexCord = tex.zx;
        vec2 zPlaneTexCord = tex.zy;

        outdata.Tex3 = yPlaneTexCord * vDetailTex.x + vDetailTex.y;
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
        scalar tot = dot(1.0, outdata.BlendValueAndWater.xyz);
        outdata.BlendValueAndWater.xyz /= tot;
    #else
    //	outdata.BlendValueAndWater.xyz = indata.Normal.y * indata.Normal.y;
        outdata.BlendValueAndWater.xyz = pow(indata.Normal.y,8);
    #endif

    outdata.Tex1 = projToLighting(outdata.Pos);
    outdata.Fog = calcFog(outdata.Pos.w);

    // outdata.Tex1 = interpVal;
    // outdata.Tex1 = vec4(vMorphDeltaAdder[indata.Pos0.z*256], 1) * 256*256;

    return outdata;
}

struct Shared_VS2PS_DynamicShadowmap
{
    vec4 Pos : POSITION;
    vec4 ShadowTex : TEXCOORD1;
    vec2 Z : TEXCOORD2;
};


vec4 Shared_PS_DynamicShadowmap(Shared_VS2PS_DynamicShadowmap indata) : COLOR
{
    #if NVIDIA
        scalar avgShadowValue = tex2Dproj(sampler2PointClamp, indata.ShadowTex);
    #else
        scalar avgShadowValue = tex2Dproj(sampler2PointClamp, indata.ShadowTex) == 1.0;
        // scalar avgShadowValue = getShadowFactor(ShadowMapSampler, indata.ShadowTex);
        // scalar avgShadowValue = 0.5;
    #endif
    return  avgShadowValue.x;
    // return 1.0 - saturate(4.0 - indata.Z.x) + avgShadowValue.x;
}

Shared_VS2PS_DynamicShadowmap Shared_VS_DynamicShadowmap(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_DynamicShadowmap outdata;

    vec4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    // tl: Trans is always 0, and MADs cost more than MULs in certain cards.
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
    vec4 Pos : POSITION;
    vec2 Tex0 : TEXCOORD0;
    vec4 ShadowTex : TEXCOORD1;
    vec2 Z : TEXCOORD2;
};

Shared_VS2PS_DirectionalLightShadows Shared_VS_DirectionalLightShadows(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_DirectionalLightShadows outdata;

    vec4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    //tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    scalar yDelta, interpVal;
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);
    outdata.ShadowTex = mul(wPos, mLightVP);
    scalar sZ = mul(wPos, mLightVPOrtho).z;
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
    vec4 Pos : POSITION;
    vec4 WaterAndFog : COLOR0;
};

vec4 Shared_PS_UnderWater(Shared_VS2PS_UnderWater indata) : COLOR
{
    #if DEBUGTERRAIN
        return vec4(1.0, 1.0, 0.0, 1.0);
    #endif
    //tl: use color interpolator instead of texcoord, it makes this shader much shorter!
    vec4 fogWaterOutColor = lerp(FogColor, terrainWaterColor, indata.WaterAndFog.y);
    fogWaterOutColor.a = indata.WaterAndFog.x;

    return fogWaterOutColor;
}

Shared_VS2PS_UnderWater Shared_VS_UnderWater(Shared_APP2VS_Default indata)
{
    Shared_VS2PS_UnderWater outdata;

    vec4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    // tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.WaterAndFog = 0.0;
        return outdata;
    #endif

    scalar yDelta, interpVal;
    // geoMorphPosition(wPos, indata.MorphDelta, yDelta, interpVal);
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    // tl: changed a few things with this factor:
    // - saturate is unneeded because color interpolators are clamped [0,1] before the pixel shader
    // - by pre-multiplying the waterHeight, we can change the (wh-wp)*c to (-wp*c)+whc i.e. from ADD+MUL to MAD
    outdata.WaterAndFog.x = (wPos.y/-3.0) + waterHeight;
    // outdata.WaterAndFog.x = saturate((waterHeight*3 - wPos.y)/3.0f);

    outdata.WaterAndFog.yzw = calcFog(outdata.Pos.w);

    return outdata;
}













// Surrounding Terrain

struct Shared_APP2VS_STNormal
{
    vec2 Pos0 : POSITION0;
    vec2 TexCoord0 : TEXCOORD0;
    vec4 Pos1 : POSITION1;
    vec3 Normal : NORMAL;
};

struct Shared_VS2PS_STNormal
{
    vec4 Pos : POSITION;
    vec2 ColorLightTex : TEXCOORD0;
    vec2 Tex1 : TEXCOORD1;
    vec2 Tex2 : TEXCOORD2;
    vec2 Tex3 : TEXCOORD3;
    vec2 LowDetailTex : TEXCOORD4;
    scalar Fog : Fog;
    vec3 BlendValue : TEXCOORD5;
};

Shared_VS2PS_STNormal Shared_VS_STNormal(Shared_APP2VS_STNormal indata)
{
    Shared_VS2PS_STNormal outdata;

    outdata.Pos.xz = mul(vec4(indata.Pos0.xy,0,1), vSTTransXZ).xy;
    outdata.Pos.yw = indata.Pos1.xw * vSTScaleTransY.xy + vSTScaleTransY.zw;
    outdata.ColorLightTex = indata.TexCoord0 * vSTColorLightTex.x + vSTColorLightTex.y;
    outdata.LowDetailTex = indata.TexCoord0 * vSTLowDetailTex.x + vSTLowDetailTex.y;

    // vec3 tex = vec3(indata.Pos0.y * vSTTexScale.z, -(indata.Pos1.x * vSTTexScale.y) , indata.Pos0.x * vSTTexScale.x);
    vec3 tex = vec3(outdata.Pos.z * vSTTexScale.z, -(indata.Pos1.x * vSTTexScale.y) , outdata.Pos.x * vSTTexScale.x);
    vec2 xPlaneTexCord = tex.xy;
    vec2 yPlaneTexCord = tex.zx;
    vec2 zPlaneTexCord = tex.zy;

    vec4 wPos = outdata.Pos;
    outdata.Pos = mul(wPos, mViewProj);
    outdata.Fog = calcFog(outdata.Pos.w);

    outdata.Tex1.xy = yPlaneTexCord * vSTFarTexTiling.z;
    outdata.Tex2.xy = xPlaneTexCord.xy * vSTFarTexTiling.xy;
    outdata.Tex2.y += vSTFarTexTiling.w;
    outdata.Tex3.xy = zPlaneTexCord.xy * vSTFarTexTiling.xy;
    outdata.Tex3.y += vSTFarTexTiling.w;

    outdata.BlendValue.xyz = saturate(abs(indata.Normal) - vBlendMod);
    scalar tot = dot(1, outdata.BlendValue.xyz);
    outdata.BlendValue.xyz /= tot;

    return outdata;
}

vec4 Shared_PS_STNormal(Shared_VS2PS_STNormal indata) : COLOR
{
    vec4 colormap = tex2D(sampler0Clamp, indata.ColorLightTex);

    vec4 lowComponent = tex2D(sampler5Clamp, indata.LowDetailTex);
    vec4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex1.xy);
    vec4 xplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex2);
    vec4 zplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3);

    vec4 lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x);
    scalar mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), BlendValue.xyz);
    lowDetailmap *= lerp(0.5, mounten, lowComponent.z);

    vec4 outColor = lowDetailmap * colormap * 4;

    return outColor;
}

/*
    struct Shared_APP2VS_STFast
    {
        vec2 Pos0 : POSITION0;
        vec2 TexCoord0 : TEXCOORD0;
        vec4 Pos1 : POSITION1;
    };

    struct Shared_VS2PS_STFast
    {
        vec4 Pos : POSITION;
        vec2 Tex0 : TEXCOORD0;
        scalar Fog : Fog;
    };

    Shared_VS2PS_STFast Shared_VS_STFast(Shared_APP2VS_STFast indata)
    {
        Shared_VS2PS_STFast outdata;
        outdata.Pos.xz = mul(vec4(indata.Pos0.xy, 0.0, 1.0), vSTTransXZ).xy;
        outdata.Pos.yw = indata.Pos1.xw * vSTScaleTransY.xy + vSTScaleTransY.zw;
        outdata.Tex0 = indata.TexCoord0;
        outdata.Pos = mul(outdata.Pos, mViewProj);
        outdata.Fog = calcFog(outdata.Pos.w);
        return outdata;
    }

    vec4 Shared_PS_STFast(Shared_VS2PS_STFast indata) : COLOR
    {
        return tex2D(sampler0Clamp, indata.Tex0);
    }
*/










// Surrounding Terrain

technique Shared_SurroundingTerrain
{
    pass p0 // Normal
    {
        CullMode = CW;
        // FillMode = WIREFRAME;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;
        FogEnable = true;
        VertexShader = compile vs_1_1 Shared_VS_STNormal();
        PixelShader = compile ps_1_4 Shared_PS_STNormal();
    }
    /*
        pass p1 // Fast
        {
            CullMode = CW;
            ZEnable = TRUE;
            ZWriteEnable = TRUE;
            ZFunc = LESSEQUAL;
            AlphaBlendEnable = FALSE;
            FogEnable = true;
            VertexShader = compile vs_1_1 Shared_VS_STFast();
            PixelShader = compile ps_1_4 Shared_PS_STFast();
        }
    */
}












mat4x4 vpLightMat : vpLightMat;
mat4x4 vpLightTrapezMat : vpLightTrapezMat;

struct HI_APP2VS_OccluderShadow
{
    vec4 Pos0 : POSITION0;
    vec4 Pos1 : POSITION1;
};

struct HI_VS2PS_OccluderShadow
{
    vec4 Pos : POSITION;
    vec2 PosZX : TEXCOORD0;
};

vec4 calcShadowProjCoords(vec4 Pos, mat4x4 matTrap, mat4x4 matLight)
{
    vec4 shadowcoords = mul(Pos, matTrap);
    scalar lightZ = mul(Pos, matLight).z;
    shadowcoords.z = lightZ*shadowcoords.w;
    return shadowcoords;
}

HI_VS2PS_OccluderShadow Hi_VS_OccluderShadow(HI_APP2VS_OccluderShadow indata)
{
    HI_VS2PS_OccluderShadow outdata;
    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;
    outdata.Pos = calcShadowProjCoords(wPos, vpLightTrapezMat, vpLightMat);
    outdata.PosZX = outdata.Pos.zw;
    return outdata;
}

vec4 Hi_PS_OccluderShadow(HI_VS2PS_OccluderShadow indata) : COLOR
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

        VertexShader = compile vs_1_1 Hi_VS_OccluderShadow();
        PixelShader = compile SHADOWPSMODEL Hi_PS_OccluderShadow();
    }
}

