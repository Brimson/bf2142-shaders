#line 2 "TerrainShader_Hi.fx"
// Hi Terrain

//Special samplers for dynamic filtering types
sampler dsampler3Wrap = sampler_state {
    Texture = (texture3);
    AddressU = WRAP;
    AddressV = WRAP;
    MipFilter = FILTER_TRN_MIP;
    MinFilter = FILTER_TRN_DIFF_MIN;
    MagFilter = FILTER_TRN_DIFF_MAG;
    #ifdef FILTER_TRN_DIFF_MAX_ANISOTROPY
        MaxAnisotropy 	= FILTER_TRN_DIFF_MAX_ANISOTROPY;
    #endif
};

sampler dsampler4Wrap = sampler_state {
    Texture = (texture4);
    AddressU = WRAP;
    AddressV = WRAP;
    MipFilter = FILTER_TRN_MIP;
    MinFilter = FILTER_TRN_DIFF_MIN;
    MagFilter = FILTER_TRN_DIFF_MAG;
    #ifdef FILTER_TRN_DIFF_MAX_ANISOTROPY
        MaxAnisotropy = FILTER_TRN_DIFF_MAX_ANISOTROPY;
    #endif
};

sampler dsampler6Wrap = sampler_state {
    Texture = (texture6);
    AddressU = WRAP;
    AddressV = WRAP;
    MipFilter = FILTER_TRN_MIP;
    MinFilter = FILTER_TRN_DIFF_MIN;
    MagFilter = FILTER_TRN_DIFF_MAG;
    #ifdef FILTER_TRN_DIFF_MAX_ANISOTROPY
        MaxAnisotropy = FILTER_TRN_DIFF_MAX_ANISOTROPY;
    #endif
};

#define SHADOWVERSION 30

struct Hi_VS2PS_FullDetail
{
    vec4 Pos : POSITION;
    vec4 Tex0 : TEXCOORD0;
    vec4 Tex1 : TEXCOORD1;
    vec4 BlendValueAndFade : TEXCOORD2; // tl: texcoord because we don't want clamping
    vec4 Tex3 : TEXCOORD3;
    vec2 Tex5 : TEXCOORD4;
    vec2 Tex6 : TEXCOORD5;
    vec4 FogAndFade2 : COLOR0;
};

// #define LIGHTONLY 1
vec4 Hi_PS_FullDetail(Hi_VS2PS_FullDetail indata) : COLOR
{
    // return vec4(0,0,0.25,1);
    #if LIGHTONLY
        vec4 accumlights = tex2Dproj(sampler1ClampPoint, indata.Tex1);
        vec4 light = 2.0 * accumlights.w * vSunColor + accumlights;
        vec4 component = tex2D(sampler2Clamp, indata.Tex0.xy);
        scalar chartcontrib = dot(vComponentsel, component);
        return chartcontrib*light;
    #else
        #if DEBUGTERRAIN
            return vec4(0.0, 0.0, 1.0, 1.0);
        #endif
        vec3 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);

        vec4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);

        //tl: 2* moved later in shader to avoid clamping at -+2.0 in ps1.4
        vec3 light = 2*accumlights.w * vSunColor.rgb + accumlights.rgb;

        vec4 component = tex2D(sampler2Clamp, indata.Tex6);
        scalar chartcontrib = dot(vComponentsel, component);
        vec3 detailmap = tex2D(dsampler3Wrap, indata.Tex3.xy);

        #if HIGHTERRAIN
            vec4 lowComponent = tex2D(sampler5Clamp, indata.Tex6);
            vec4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex5.xy);
            vec4 xplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.xy);
            vec4 zplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex0.wz);
            scalar lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x*indata.FogAndFade2.y);
        #else
            vec4 yplaneLowDetailmap = tex2D(ssampler4Wrap, indata.Tex5.xy);

            // tl: do lerp in 1 MAD by precalculating constant factor in vShader
            // scalar lowDetailmap = yplaneLowDetailmap.z * indata.BlendValueAndFade.y + indata.FogAndFade2.z;
            scalar lowDetailmap = lerp(yplaneLowDetailmap.x, yplaneLowDetailmap.z, indata.BlendValueAndFade.y);
        #endif

        #if HIGHTERRAIN
            scalar mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), indata.BlendValueAndFade.xyz);
            lowDetailmap *= (4.0 * lerp(0.5, mounten, lowComponent.z));

            vec3 bothDetailmap = detailmap * lowDetailmap;
            vec3 detailout = lerp(2.0 * bothDetailmap, lowDetailmap, indata.BlendValueAndFade.w);
        #else
            // tl: lerp optimized to handle 2*c*low + (2-2c)*detail, factors sent from vs
            vec3 detailout = lowDetailmap * indata.BlendValueAndFade.x + detailmap * indata.BlendValueAndFade.z;
        #endif

        vec3 outColor = detailout * colormap * light * 2.0;
        vec3 fogOutColor = lerp(FogColor, outColor, indata.FogAndFade2.x);
        return vec4(chartcontrib * fogOutColor, chartcontrib);
    #endif
}

Hi_VS2PS_FullDetail Hi_VS_FullDetail(Shared_APP2VS_Default indata)
{
    Hi_VS2PS_FullDetail outdata = (Hi_VS2PS_FullDetail)0;

    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy; // + vScaleTransY.zw;

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.Tex0 = 0.0;
        outdata.Tex1 = 0.0;
        outdata.BlendValueAndFade = 0.0;
        outdata.Tex3 = 0.0;
        outdata.Tex5.xy = 0.0;
        outdata.FogAndFade2 = 0.0;
        return outdata;
    #endif

    scalar yDelta, interpVal;
    // geoMorphPosition(wPos, indata.MorphDelta, yDelta, interpVal);
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    //tl: uncompress normal
    indata.Normal = indata.Normal * 2.0 - 1.0;

    vec3 tex = vec3(indata.Pos0.y * vTexScale.z, wPos.y * vTexScale.y, indata.Pos0.x * vTexScale.x);
    vec2 yPlaneTexCord = tex.zx;
    #if HIGHTERRAIN
        vec2 xPlaneTexCord = tex.xy;
        vec2 zPlaneTexCord = tex.zy;
    #endif

    outdata.Tex0.xy = yPlaneTexCord * vColorLightTex.x + vColorLightTex.y;
    outdata.Tex6 = yPlaneTexCord * vDetailTex.x + vDetailTex.y;

    //tl: Switched tex0.wz for tex3.xy to easier access it from 1.4
    outdata.Tex3.xy = yPlaneTexCord.xy * vNearTexTiling.z;
    outdata.Tex5.xy = yPlaneTexCord * vFarTexTiling.z;

    #if HIGHTERRAIN
        outdata.Tex0.wz = xPlaneTexCord.xy * vFarTexTiling.xy;
        outdata.Tex0.z += vFarTexTiling.w;
        outdata.Tex3.wz = zPlaneTexCord.xy * vFarTexTiling.xy;
        outdata.Tex3.z += vFarTexTiling.w;
    #endif

    outdata.FogAndFade2.x = calcFog(outdata.Pos.w);
    outdata.FogAndFade2.yzw = 0.5+interpVal*0.5;

    #if HIGHTERRAIN
        outdata.BlendValueAndFade.w = interpVal;
    #elif MIDTERRAIN
        // tl: optimized so we can do more advanced lerp in same number of instructions
        // factors are 2c and (2-2c) which equals a lerp()*2
        // Don't use w, it's harder to access from ps1.4
        outdata.BlendValueAndFade.xz = interpVal * vec2(2, -2) + vec2(0, 2);
    #endif

    #if HIGHTERRAIN
        outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
        scalar tot = dot(1, outdata.BlendValueAndFade.xyz);
        outdata.BlendValueAndFade.xyz /= tot;
    #elif MIDTERRAIN
        //tl: use squared yNormal as blend val. pre-multiply with fade value.
        outdata.BlendValueAndFade.yw = pow(indata.Normal.y,8) /** indata.Normal.y*/ * outdata.FogAndFade2.y;

        //tl: pre calculate half-lerp against constant, result is 2 ps instruction lerp distributed
        //    to 1 vs MAD and 1 ps MAD
        outdata.FogAndFade2.z = outdata.BlendValueAndFade.y * -0.5 + 0.5;
    #endif

    outdata.Tex1 = projToLighting(outdata.Pos);
    // outdata.Tex1 = vec4(vMorphDeltaAdder[indata.Pos0.z*256], 1) * 256*256;

    return outdata;
}

struct Hi_VS2PS_FullDetailMounten
{
    vec4 Pos : POSITION;
    vec4 Tex0 : TEXCOORD0;
    vec4 Tex1 : TEXCOORD1;
    vec4 BlendValueAndFade : TEXCOORD2; // tl: texcoord because we don't want clamping
    #if HIGHTERRAIN
        vec4 Tex3 : TEXCOORD6;
    #endif
    vec2 Tex5 : TEXCOORD5;
    vec4 Tex6 : TEXCOORD3;
    vec2 Tex7 : TEXCOORD4;
    vec4 FogAndFade2 : COLOR0;
};

vec4 Hi_PS_FullDetailMounten(Hi_VS2PS_FullDetailMounten indata) : COLOR
{
    #if LIGHTONLY
        vec4 accumlights = tex2Dproj(sampler1ClampPoint, indata.Tex1);
        vec4 light = 2.0 * accumlights.w * vSunColor + accumlights;
        vec4 component = tex2D(sampler2Clamp, indata.Tex0.xy);
        scalar chartcontrib = dot(vComponentsel, component);
        return chartcontrib*light;
    #else
        #if DEBUGTERRAIN
            return vec4(1.0, 0.0, 0.0, 1.0);
        #endif
            vec3 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);

            vec4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);

            //tl: 2* moved later in shader to avoid clamping at -+2.0 in ps1.4
            vec3 light = 2*accumlights.w * vSunColor.rgb + accumlights.rgb;

            vec4 component = tex2D(sampler2Clamp, indata.Tex7);
            scalar chartcontrib = dot(vComponentsel, component);

        #if HIGHTERRAIN
            vec3 yplaneDetailmap = tex2D(dsampler3Wrap, indata.Tex6.xy);
            vec3 xplaneDetailmap = tex2D(dsampler6Wrap, indata.Tex0.wz);
            vec3 zplaneDetailmap = tex2D(dsampler6Wrap, indata.Tex6.wz);
            vec3 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex5.xy);
            vec3 xplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.xy);
            vec3 zplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.wz);

            vec3 lowComponent = tex2D(sampler5Clamp, indata.Tex7);

            vec3 detailmap = (xplaneDetailmap * indata.BlendValueAndFade.x) +
                             (yplaneDetailmap * indata.BlendValueAndFade.y) +
                             (zplaneDetailmap * indata.BlendValueAndFade.z);

            scalar lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x * indata.FogAndFade2.y);
            scalar mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), indata.BlendValueAndFade.xyz);
            lowDetailmap *= (4.0 * lerp(0.5, mounten, lowComponent.z));

            vec3 bothDetailmap = detailmap * lowDetailmap;
            vec3 detailout = lerp(2.0 * bothDetailmap, lowDetailmap, indata.BlendValueAndFade.w);
        #else
            vec3 yplaneDetailmap = tex2D(ssampler3Wrap, indata.Tex6.xy);
            vec3 yplaneLowDetailmap = tex2D(ssampler4Wrap, indata.Tex5.xy);
            scalar lowDetailmap = lerp(yplaneLowDetailmap.x, yplaneLowDetailmap.z, indata.BlendValueAndFade.y);

            // tl: lerp optimized to handle 2*c*low + (2-2c)*detail, factors sent from vs
            // tl: dont use detail mountains
            vec3 detailout = lowDetailmap * indata.BlendValueAndFade.x + lowDetailmap * yplaneDetailmap * indata.BlendValueAndFade.z;
            // vec3 detailout = lowDetailmap*2;
        #endif

        vec3 outColor = detailout * colormap * light * 2;
        vec3 fogOutColor = lerp(FogColor, outColor, indata.FogAndFade2.x);
        return vec4(chartcontrib * fogOutColor, chartcontrib);
    #endif
}

Hi_VS2PS_FullDetailMounten Hi_VS_FullDetailMounten(Shared_APP2VS_Default indata)
{
    Hi_VS2PS_FullDetailMounten outdata;

    vec4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    // tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.Tex0 = 0.0;
        outdata.Tex1 =0.0;
        outdata.BlendValueAndFade = 0.0;
        outdata.Tex3 = 0.0;
        outdata.Tex5.xy = 0.0;
        outdata.Tex6 = 0.0;
        outdata.FogAndFade2 = 0.0;
        return outdata;
    #endif

    scalar yDelta, interpVal;
    // geoMorphPosition(wPos, indata.MorphDelta, yDelta, interpVal);
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    // tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    // tl: uncompress normal
    indata.Normal = indata.Normal * 2 - 1;

    vec3 tex = vec3(indata.Pos0.y * vTexScale.z, wPos.y * vTexScale.y, indata.Pos0.x * vTexScale.x);
    vec2 xPlaneTexCord = tex.xy;
    vec2 yPlaneTexCord = tex.zx;
    vec2 zPlaneTexCord = tex.zy;

    outdata.Tex0.xy = (yPlaneTexCord*vColorLightTex.x) + vColorLightTex.y;
    outdata.Tex7 = (yPlaneTexCord*vDetailTex.x) + vDetailTex.y;

    outdata.Tex6.xy = yPlaneTexCord.xy * vNearTexTiling.z;
    outdata.Tex0.wz = xPlaneTexCord.xy * vNearTexTiling.xy;
    outdata.Tex0.z += vNearTexTiling.w;
    outdata.Tex6.wz = zPlaneTexCord.xy * vNearTexTiling.xy;
    outdata.Tex6.z += vNearTexTiling.w;

    outdata.Tex5.xy = yPlaneTexCord * vFarTexTiling.z;

    outdata.FogAndFade2.x = calcFog(outdata.Pos.w);
    outdata.FogAndFade2.yzw = 0.5+interpVal*0.5;

    #if HIGHTERRAIN
        outdata.Tex3.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
        outdata.Tex3.y += vFarTexTiling.w;
        outdata.Tex3.wz = zPlaneTexCord.xy * vFarTexTiling.xy;
        outdata.Tex3.z += vFarTexTiling.w;
        outdata.BlendValueAndFade.w = interpVal;
    #else
        //tl:   optimized so we can do more advanced lerp in same number of instructions
        //      factors are 2c and (2-2c) which equals a lerp()*2
        //      Don't use w, it's harder to access from ps1.4
        //      outdata.BlendValueAndFade.xz = interpVal * vec2(2, -2) + vec2(0, 2);
        outdata.BlendValueAndFade.xz = interpVal * vec2(1, -2) + vec2(1, 2);
        //      outdata.BlendValueAndFade = interpVal * vec4(2, 0, -2, 0) + vec4(0, 0, 2, 0);
        //      outdata.BlendValueAndFade.w = interpVal;
    #endif

    #if HIGHTERRAIN
        outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
        scalar tot = dot(1.0, outdata.BlendValueAndFade.xyz);
        outdata.BlendValueAndFade.xyz /= tot;
    #else
        //tl: use squared yNormal as blend val. pre-multiply with fade value.
        //    outdata.BlendValueAndFade.yw = indata.Normal.y * indata.Normal.y * outdata.FogAndFade2.y;
        outdata.BlendValueAndFade.yw = pow(indata.Normal.y, 8.0);

        //tl: pre calculate half-lerp against constant, result is 2 ps instruction lerp distributed
        //    to 1 vs MAD and 1 ps MAD
        //    outdata.FogAndFade2.z = outdata.BlendValueAndFade.y*-0.5 + 0.5;
    #endif

    outdata.Tex1 = projToLighting(outdata.Pos);
    return outdata;
}

struct Hi_VS2PS_FullDetailWithEnvMap
{
    vec4 Pos : POSITION;
    vec4 Tex0 : TEXCOORD0;
    vec4 Tex1 : TEXCOORD1;
    vec4 Tex3 : TEXCOORD3;
    vec4 BlendValueAndFade : COLOR0;
    vec3 Tex5 : TEXCOORD2;
    vec2 Tex6 : TEXCOORD5;
    vec3 EnvMap : TEXCOORD4;
    vec4 FogAndFade2 : COLOR1;
};

vec4 Hi_PS_FullDetailWithEnvMap(Hi_VS2PS_FullDetailWithEnvMap indata) : COLOR
{
    #if LIGHTONLY
        vec4 accumlights = tex2Dproj(sampler1ClampPoint, indata.Tex1);
        vec4 light = 2.0 * accumlights.w * vSunColor + accumlights;
        vec4 component = tex2D(sampler2Clamp, indata.Tex0.xy);
        scalar chartcontrib = dot(vComponentsel, component);
        return chartcontrib*light;
    #else
        #if DEBUGTERRAIN
            return vec4(0,1,0,1);
        #endif

        vec3 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);
        vec4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);

        //tl: 2* moved later in shader to avoid clamping at -+2.0 in ps1.4
        vec3 light = 2*accumlights.w * vSunColor.rgb + accumlights.rgb;

        vec4 component = tex2D(sampler2Clamp, indata.Tex6);
        scalar chartcontrib = dot(vComponentsel, component);
        vec4 detailmap = tex2D(dsampler3Wrap, indata.Tex3.xy);

        #if HIGHTERRAIN
            vec4 lowComponent = tex2D(sampler5Clamp, indata.Tex6);
            vec4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex5.xy);
            vec4 xplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.xy);
            vec4 zplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex0.wz);
            scalar lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x*indata.FogAndFade2.y);
        #else
            vec4 yplaneLowDetailmap = tex2D(ssampler4Wrap, indata.Tex5.xy);

            //tl: do lerp in 1 MAD by precalculating constant factor in vShader
            scalar lowDetailmap = 2*yplaneLowDetailmap.z * indata.BlendValueAndFade.y + indata.FogAndFade2.z;
        #endif

        #if HIGHTERRAIN
            scalar mounten = dot(float3(xplaneLowDetailmap.y, yplaneLowDetailmap.x, zplaneLowDetailmap.y), indata.BlendValueAndFade.xyz);
            lowDetailmap *= (4 * lerp(0.5, mounten, lowComponent.z));

            vec3 bothDetailmap = detailmap * lowDetailmap;
            vec3 detailout = lerp(2*bothDetailmap, lowDetailmap, indata.BlendValueAndFade.w);
        #else
            // tl: lerp optimized to handle 2*c*low + (2-2c)*detail, factors sent from vs
            vec3 detailout = lowDetailmap * indata.BlendValueAndFade.x + 2.0 * detailmap * indata.BlendValueAndFade.z;
        #endif

        vec3 outColor = detailout * colormap * light;

        vec4 envmapColor = texCUBE(sampler6Cube, indata.EnvMap);
        #if HIGHTERRAIN
            outColor = lerp(outColor, envmapColor, detailmap.w * (1.0 - indata.BlendValueAndFade.w)) * 2.0;
        #else
            outColor = lerp(outColor, envmapColor, detailmap.w * (1.0 - indata.FogAndFade2.y)) * 2.0;
        #endif

        outColor = lerp(FogColor, outColor, indata.FogAndFade2.x);
        return vec4(chartcontrib * outColor, chartcontrib);
    #endif
}

Hi_VS2PS_FullDetailWithEnvMap Hi_VS_FullDetailWithEnvMap(Shared_APP2VS_Default indata)
{
    Hi_VS2PS_FullDetailWithEnvMap outdata = (Hi_VS2PS_FullDetailWithEnvMap)0;

    vec4 wPos;
    wPos.xz = indata.Pos0.xy * vScaleTransXZ.xy + vScaleTransXZ.zw;
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;// + vScaleTransY.zw;

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.Tex0 = 0.0;
        outdata.Tex1 = 0.0;
        outdata.BlendValueAndFade = 0.0;
        outdata.Tex3 = 0.0;
        outdata.Tex5.xy = 0.0;
        outdata.EnvMap = 0.0;
        outdata.FogAndFade2 = 0.0;
        return outdata;
    #endif

    scalar yDelta, interpVal;
    // geoMorphPosition(wPos, indata.MorphDelta, yDelta, interpVal);
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    //tl: uncompress normal
    indata.Normal = indata.Normal * 2 - 1;

    vec3 tex = vec3(indata.Pos0.y * vTexScale.z, wPos.y * vTexScale.y, indata.Pos0.x * vTexScale.x);
    vec2 yPlaneTexCord = tex.zx;
    #if HIGHTERRAIN
        vec2 xPlaneTexCord = tex.xy;
        vec2 zPlaneTexCord = tex.zy;
    #endif

    outdata.Tex0.xy = yPlaneTexCord * vColorLightTex.x + vColorLightTex.y;
    outdata.Tex6 = yPlaneTexCord * vDetailTex.x + vDetailTex.y;

    //tl: Switched tex0.wz for tex3.xy to easier access it from 1.4
    outdata.Tex3.xy = yPlaneTexCord.xy * vNearTexTiling.z;
    outdata.Tex5.xy = yPlaneTexCord * vFarTexTiling.z;

    #if HIGHTERRAIN
        outdata.Tex0.wz = xPlaneTexCord.xy * vFarTexTiling.xy;
        outdata.Tex0.z += vFarTexTiling.w;
        outdata.Tex3.wz = zPlaneTexCord.xy * vFarTexTiling.xy;
        outdata.Tex3.z += vFarTexTiling.w;
    #endif

    outdata.FogAndFade2.x = calcFog(outdata.Pos.w);
    outdata.FogAndFade2.yzw = 0.5+interpVal*0.5;

    #if HIGHTERRAIN
        outdata.BlendValueAndFade.w = interpVal;
    #elif MIDTERRAIN
        //tl: optimized so we can do more advanced lerp in same number of instructions
        //    factors are 2c and (2-2c) which equals a lerp()*2
        //    Don't use w, it's harder to access from ps1.4
        outdata.BlendValueAndFade.xz = interpVal * vec2(2, -2) + vec2(0, 2);
    #endif

    #if HIGHTERRAIN
        outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
        scalar tot = dot(1.0, outdata.BlendValueAndFade.xyz);
        outdata.BlendValueAndFade.xyz /= tot;
    #elif MIDTERRAIN
        // tl: use squared yNormal as blend val. pre-multiply with fade value.
        outdata.BlendValueAndFade.yw = indata.Normal.y * indata.Normal.y * outdata.FogAndFade2.y;

        outdata.FogAndFade2.y = interpVal;
        outdata.FogAndFade2.z = outdata.BlendValueAndFade.y * -0.5 + 0.5;
    #endif

    outdata.Tex1 = projToLighting(outdata.Pos);

    // Environment map
    // tl: no need to normalize, reflection works with long vectors,
    //     and cube maps auto-normalize.
    // outdata.EnvMap = reflect(wPos.xyz - vCamerapos.xyz, vec3(0,1,0));
    // outdata.EnvMap = vec3(1,-1,1)*wPos.xyz - vec3(1,-1,1)*vCamerapos.xyz;
    outdata.EnvMap = reflect(wPos.xyz - vCamerapos.xyz, vec3(0.0, 1.0, 0.0));

    return outdata;
}








struct Hi_VS2PS_PerPixelPointLight
{
    vec4 Pos : POSITION;
    vec3 wPos : TEXCOORD0;
    vec3 Normal : TEXCOORD1;
};

vec4 Hi_PS_PerPixelPointLight(Hi_VS2PS_PerPixelPointLight indata) : COLOR
{
    return vec4(calcPVPointTerrain(indata.wPos, indata.Normal), 0.0) * 0.5;
}

Hi_VS2PS_PerPixelPointLight Hi_VS_PerPixelPointLight(Shared_APP2VS_Default indata)
{
    Hi_VS2PS_PerPixelPointLight outdata;

    vec4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    // tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    scalar yDelta, interpVal;
    // geoMorphPosition(wPos, indata.MorphDelta, yDelta, interpVal);
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    //tl: uncompress normal
    indata.Normal = indata.Normal * 2.0 - 1.0;

    outdata.Normal = indata.Normal;
    outdata.wPos = wPos.xyz;

    return outdata;
}


vec4 Hi_PS_DirectionalLightShadows(Shared_VS2PS_DirectionalLightShadows indata) : COLOR
{
    vec4 lightmap = tex2D(sampler0Clamp, indata.Tex0);

    vec4 avgShadowValue = getShadowFactor(ShadowMapSampler, indata.ShadowTex);

    vec4 light = saturate(lightmap.z * vGIColor * 2.0) * 0.5;
    if (avgShadowValue.z < lightmap.y)
        // light.w = 1-saturate(4-indata.Z.x)+avgShadowValue.x;
        light.w = avgShadowValue.z;
    else
        light.w = lightmap.y;

    return light;
}














technique Hi_Terrain
{
    pass ZFillLightmap	// p0
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESS;
        AlphaBlendEnable = FALSE;
        FogEnable = false;

        #if IS_NV4X
            StencilEnable   = true;
            StencilFunc     = NOTEQUAL;
            StencilRef      = 0xa;
            StencilPass     = KEEP;
            StencilZFail    = KEEP;
            StencilFail     = KEEP;
        #endif

        VertexShader = compile vs_2_0 Shared_VS_ZFillLightmap();
        PixelShader = compile ps_2_0 Shared_PS_ZFillLightmap();
    }

    pass pointlight		//p1
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;

        #if IS_NV4X
            StencilEnable   = true;
            StencilFunc     = NOTEQUAL;
            StencilRef      = 0xa;
            StencilPass     = KEEP;
            StencilZFail    = KEEP;
            StencilFail     = KEEP;
        #endif

        VertexShader = compile vs_2_0 Shared_VS_PointLight();
        PixelShader = compile ps_2_0 Shared_PS_PointLight();
    }

    pass { } // spotlight (removed) p2
    pass LowDiffuse //p3
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        FogEnable = true;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        // FillMode = WireFrame;

        #if IS_NV4X
            StencilEnable   = true;
            StencilFunc     = NOTEQUAL;
            StencilRef      = 0xa;
            StencilPass     = KEEP;
            StencilZFail    = KEEP;
            StencilFail     = KEEP;
        #endif

        VertexShader = compile vs_2_0 Shared_VS_LowDetail();
        PixelShader = compile ps_2_0 Shared_PS_LowDetail();
    }

    pass FullDetail	//p4
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        AlphaTestEnable = TRUE;
        AlphaFunc = GREATER;
        AlphaRef = 0;
        // ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = false;
        // FillMode = WireFrame;

        #if IS_NV4X
            StencilEnable   = true;
            StencilFunc     = NOTEQUAL;
            StencilRef      = 0xa;
            StencilPass     = KEEP;
            StencilZFail    = KEEP;
            StencilFail     = KEEP;
        #endif

        VertexShader = compile vs_2_0 Hi_VS_FullDetail();
        PixelShader = compile ps_2_0 Hi_PS_FullDetail();
    }
    pass FullDetailMounten	// p5
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        FogEnable = false;

        #if IS_NV4X
            StencilEnable   = true;
            StencilFunc     = NOTEQUAL;
            StencilRef      = 0xa;
            StencilPass     = KEEP;
            StencilZFail    = KEEP;
            StencilFail     = KEEP;
        #endif

        VertexShader = compile vs_2_0 Hi_VS_FullDetailMounten();
        PixelShader = compile ps_2_0 Hi_PS_FullDetailMounten();
    }
    pass { } // p6 tunnels (removed)

    pass DirectionalLightShadows	//p7
    {
        CullMode = CW;
        //ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;

        #if IS_NV4X
            StencilEnable   = true;
            StencilFunc     = NOTEQUAL;
            StencilRef      = 0xa;
            StencilPass     = KEEP;
            StencilZFail    = KEEP;
            StencilFail     = KEEP;
        #endif

        VertexShader = compile vs_2_0 Shared_VS_DirectionalLightShadows();
        PixelShader = compile SHADOWPSMODEL Hi_PS_DirectionalLightShadows();
    }

    pass { } // DirectionalLightShadowsNV (removed) //p8

    pass DynamicShadowmap
    {
    //p9
    //obsolete
    }

    pass { } // p10

    pass FullDetailWithEnvMap	//p11
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        AlphaTestEnable = TRUE;
        AlphaFunc = GREATER;
        AlphaRef = 0;
        // ColsorWriteEnable = RED|BLUE|GREEN|ALPHA;
        FogEnable = false;

        #if IS_NV4X
            StencilEnable   = true;
            StencilFunc     = NOTEQUAL;
            StencilRef      = 0xa;
            StencilPass     = KEEP;
            StencilZFail    = KEEP;
            StencilFail     = KEEP;
        #endif

        VertexShader = compile vs_2_0 Hi_VS_FullDetailWithEnvMap();
        PixelShader = compile ps_2_0 Hi_PS_FullDetailWithEnvMap();
    }

    pass { } // mulDiffuseFast (removed) p12

    pass PerPixelPointlight // p13
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;

        #if IS_NV4X
            StencilEnable   = true;
            StencilFunc     = NOTEQUAL;
            StencilRef      = 0xa;
            StencilPass     = KEEP;
            StencilZFail    = KEEP;
            StencilFail     = KEEP;
        #endif

        VertexShader = compile vs_2_0 Hi_VS_PerPixelPointLight();
        PixelShader = compile ps_2_0 Hi_PS_PerPixelPointLight();
    }

    pass underWater // p14
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = TRUE;
        AlphaRef = 15; // tl: leave cap above 0 for better results
        AlphaFunc = GREATER;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = false;

        #if IS_NV4X
            StencilEnable   = true;
            StencilFunc     = NOTEQUAL;
            StencilRef      = 0xa;
            StencilPass     = KEEP;
            StencilZFail    = KEEP;
            StencilFail     = KEEP;
        #endif

        VertexShader = compile vs_2_0 Shared_VS_UnderWater();
        PixelShader = compile ps_2_0 Shared_PS_UnderWater();
    }

    pass ZFillLightmap2	// p15
    {
        // note: ColorWriteEnable is disabled in code for this
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESS;
        AlphaBlendEnable = FALSE;
        FogEnable = false;
        VertexShader = compile vs_2_0 Shared_VS_ZFillLightmap();
        PixelShader = compile ps_2_0 Shared_PS_ZFillLightmap2();
    }
}

































