#line 2 "TerrainShader_Hi.fx"

// -- Hi Terrain

//Special samplers for dynamic filtering types
sampler dsampler3Wrap = sampler_state {
    Texture = (texture3);
    AddressU = WRAP;
    AddressV = WRAP;
    MipFilter = FILTER_TRN_MIP;
    MinFilter = FILTER_TRN_DIFF_MIN;
    MagFilter = FILTER_TRN_DIFF_MAG;
    #ifdef FILTER_TRN_DIFF_MAX_ANISOTROPY
        MaxAnisotropy = FILTER_TRN_DIFF_MAX_ANISOTROPY;
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

struct Hi_VS2PS_FullDetail
{
    float4 Pos               : POSITION;
    float4 Tex0              : TEXCOORD0;
    float4 Tex1              : TEXCOORD1;
    float4 BlendValueAndFade : TEXCOORD2; // tl: texcoord because we don't want clamping
    float4 Tex3              : TEXCOORD3;
    float2 Tex5              : TEXCOORD4;
    float2 Tex6              : TEXCOORD5;
    float4 FogAndFade2       : COLOR0;
};

float4 Hi_PS_FullDetail(Hi_VS2PS_FullDetail indata) : COLOR
{
    #if LIGHTONLY
        float4 accumlights = tex2Dproj(sampler1ClampPoint, indata.Tex1);
        float4 light = 2 * accumlights.w * vSunColor + accumlights;
        float4 component = tex2D(sampler2Clamp, indata.Tex0.xy);
        float chartcontrib = dot(vComponentsel, component);
        return chartcontrib*light;
    #else
        #if DEBUGTERRAIN
            return float4(0,0,1,1);
        #endif

        float3 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);
        float4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);

        //tl: 2* moved later in shader to avoid clamping at -+2.0 in ps1.4
        float3 light = 2*accumlights.w * vSunColor.rgb + accumlights.rgb;

        float4 component = tex2D(sampler2Clamp, indata.Tex6);
        float chartcontrib = dot(vComponentsel, component);
        float3 detailmap = tex2D(dsampler3Wrap, indata.Tex3.xy);
        #if HIGHTERRAIN
            float4 lowComponent = tex2D(sampler5Clamp, indata.Tex6);
            float4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex5.xy);
            float4 xplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.xy);
            float4 zplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex0.wz);
            float lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x*indata.FogAndFade2.y);
        #else
            float4 yplaneLowDetailmap = tex2D(ssampler4Wrap, indata.Tex5.xy);

            //tl: do lerp in 1 MAD by precalculating constant factor in vShader
            float lowDetailmap = lerp(yplaneLowDetailmap.x, yplaneLowDetailmap.z, indata.BlendValueAndFade.y);
        #endif

        #if HIGHTERRAIN
            float mounten =    (xplaneLowDetailmap.y * indata.BlendValueAndFade.x) +
                                (yplaneLowDetailmap.x * indata.BlendValueAndFade.y) +
                                (zplaneLowDetailmap.y * indata.BlendValueAndFade.z)	;

            lowDetailmap *= (4 * lerp(0.5, mounten, lowComponent.z));
            float3 bothDetailmap = detailmap * lowDetailmap;
            float3 detailout = lerp(2*bothDetailmap, lowDetailmap, indata.BlendValueAndFade.w);
        #else
            //tl: lerp optimized to handle 2*c*low + (2-2c)*detail, factors sent from vs
            float3 detailout = lowDetailmap*indata.BlendValueAndFade.x + detailmap*indata.BlendValueAndFade.z;
        #endif

        float3 outColor = detailout * colormap * light * 2;
        float3 fogOutColor = lerp(FogColor, outColor, indata.FogAndFade2.x);
        return float4(chartcontrib * fogOutColor, chartcontrib);
    #endif
}

Hi_VS2PS_FullDetail Hi_VS_FullDetail(Shared_APP2VS_Default indata)
{
    Hi_VS2PS_FullDetail outdata = (Hi_VS2PS_FullDetail)0;

    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    wPos.yw = (indata.Pos1.xw * vScaleTransY.xy);

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.Tex0 = float4(0,0,0,0);
        outdata.Tex1 = float4(0,0,0,0);
        outdata.BlendValueAndFade = float4(0,0,0,0);
        outdata.Tex3 = float4(0,0,0,0);
        outdata.Tex5.xy = float2(0,0);
        outdata.FogAndFade2 = float4(0,0,0,0);
        return outdata;
    #endif

    float yDelta, interpVal;
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    //tl: uncompress normal
    indata.Normal = indata.Normal * 2 - 1;

    float3 tex = float3(indata.Pos0.y * vTexScale.z, wPos.y * vTexScale.y, indata.Pos0.x * vTexScale.x);
    float2 yPlaneTexCord = tex.zx;
    #if HIGHTERRAIN
        float2 xPlaneTexCord = tex.xy;
        float2 zPlaneTexCord = tex.zy;
    #endif

    outdata.Tex0.xy = (yPlaneTexCord*vColorLightTex.x) + vColorLightTex.y;
    outdata.Tex6 = (yPlaneTexCord*vDetailTex.x) + vDetailTex.y;

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
        outdata.BlendValueAndFade.xz = interpVal * float2(2, -2) + float2(0, 2);
    #endif

    #if HIGHTERRAIN
        outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
        float tot = dot(1, outdata.BlendValueAndFade.xyz);
        outdata.BlendValueAndFade.xyz /= tot;
    #elif MIDTERRAIN
        //tl: use squared yNormal as blend val. pre-multiply with fade value.
        outdata.BlendValueAndFade.yw = pow(indata.Normal.y,8) /** indata.Normal.y*/ * outdata.FogAndFade2.y;

        //tl: pre calculate half-lerp against constant, result is 2 ps instruction lerp distributed
        //    to 1 vs MAD and 1 ps MAD
        outdata.FogAndFade2.z = outdata.BlendValueAndFade.y*-0.5 + 0.5;
    #endif

    outdata.Tex1 = projToLighting(outdata.Pos);
    return outdata;
}

struct Hi_VS2PS_FullDetailMounten
{
    float4 Pos : POSITION;
    float4 Tex0 : TEXCOORD0;
    float4 Tex1 : TEXCOORD1;
    float4 BlendValueAndFade : TEXCOORD2; //tl: texcoord because we don't want clamping
    #if HIGHTERRAIN
        float4 Tex3 : TEXCOORD6;
    #endif
    float2 Tex5 : TEXCOORD5;
    float4 Tex6 : TEXCOORD3;
    float2 Tex7 : TEXCOORD4;
    float4 FogAndFade2 : COLOR0;
};

float4 Hi_PS_FullDetailMounten(Hi_VS2PS_FullDetailMounten indata) : COLOR
{
    #if LIGHTONLY
        float4 accumlights = tex2Dproj(sampler1ClampPoint, indata.Tex1);
        float4 light = 2 * accumlights.w * vSunColor + accumlights;
        float4 component = tex2D(sampler2Clamp, indata.Tex0.xy);
        float chartcontrib = dot(vComponentsel, component);
        return chartcontrib*light;
    #else
        #if DEBUGTERRAIN
            return float4(1,0,0,1);
        #endif
        float3 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);

        float4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);

        //tl: 2* moved later in shader to avoid clamping at -+2.0 in ps1.4
        float3 light = 2*accumlights.w * vSunColor.rgb + accumlights.rgb;

        float4 component = tex2D(sampler2Clamp, indata.Tex7);
        float chartcontrib = dot(vComponentsel, component);

        #if HIGHTERRAIN
            float3 yplaneDetailmap = tex2D(dsampler3Wrap, indata.Tex6.xy);
            float3 xplaneDetailmap = tex2D(dsampler6Wrap, indata.Tex0.wz);
            float3 zplaneDetailmap = tex2D(dsampler6Wrap, indata.Tex6.wz);
            float3 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex5.xy);
            float3 xplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.xy);
            float3 zplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.wz);

            float3 lowComponent = tex2D(sampler5Clamp, indata.Tex7);

            float3 detailmap =    (xplaneDetailmap * indata.BlendValueAndFade.x) +
                                (yplaneDetailmap * indata.BlendValueAndFade.y) +
                                (zplaneDetailmap * indata.BlendValueAndFade.z);

            float lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x * indata.FogAndFade2.y);
            float mounten =    (xplaneLowDetailmap.y * indata.BlendValueAndFade.x) +
                                (yplaneLowDetailmap.x * indata.BlendValueAndFade.y) +
                                (zplaneLowDetailmap.y * indata.BlendValueAndFade.z);
            lowDetailmap *= (4 * lerp(0.5, mounten, lowComponent.z));

            float3 bothDetailmap = detailmap * lowDetailmap;
            float3 detailout = lerp(2*bothDetailmap, lowDetailmap, indata.BlendValueAndFade.w);
        #else
            float3 yplaneDetailmap = tex2D(ssampler3Wrap, indata.Tex6.xy);
            float3 yplaneLowDetailmap = tex2D(ssampler4Wrap, indata.Tex5.xy);

            float lowDetailmap = lerp(yplaneLowDetailmap.x, yplaneLowDetailmap.z, indata.BlendValueAndFade.y);

            //tl: lerp optimized to handle 2*c*low + (2-2c)*detail, factors sent from vs
            //tl: dont use detail mountains
            float3 detailout = lowDetailmap*indata.BlendValueAndFade.x + lowDetailmap*yplaneDetailmap*indata.BlendValueAndFade.z;
        #endif

        float3 outColor = detailout * colormap * light * 2;
        float3 fogOutColor = lerp(FogColor, outColor, indata.FogAndFade2.x);
        return float4(chartcontrib * fogOutColor, chartcontrib);
    #endif
}

Hi_VS2PS_FullDetailMounten Hi_VS_FullDetailMounten(Shared_APP2VS_Default indata)
{
    Hi_VS2PS_FullDetailMounten outdata;

    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    //tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.Tex0 = float4(0,0,0,0);
        outdata.Tex1 = float4(0,0,0,0);
        outdata.BlendValueAndFade = float4(0,0,0,0);
        outdata.Tex3 = float4(0,0,0,0);
        outdata.Tex5.xy = float2(0,0);
        outdata.Tex6 = float4(0,0,0,0);
        outdata.FogAndFade2 = float4(0,0,0,0);
        return outdata;
    #endif

    float yDelta, interpVal;
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    //tl: uncompress normal
    indata.Normal = indata.Normal * 2 - 1;

    float3 tex = float3(indata.Pos0.y * vTexScale.z, wPos.y * vTexScale.y, indata.Pos0.x * vTexScale.x);
    float2 xPlaneTexCord = tex.xy;
    float2 yPlaneTexCord = tex.zx;
    float2 zPlaneTexCord = tex.zy;

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
        //tl: optimized so we can do more advanced lerp in same number of instructions
        //    factors are 2c and (2-2c) which equals a lerp()*2
        //    Don't use w, it's harder to access from ps1.4
        //    outdata.BlendValueAndFade.xz = interpVal * float2(2, -2) + float2(0, 2);
        outdata.BlendValueAndFade.xz = interpVal * float2(1, -2) + float2(1, 2);
    #endif

    #if HIGHTERRAIN
            outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
            float tot = dot(1, outdata.BlendValueAndFade.xyz);
            outdata.BlendValueAndFade.xyz /= tot;
    #else
        //tl: use squared yNormal as blend val. pre-multiply with fade value.
        //    outdata.BlendValueAndFade.yw = indata.Normal.y * indata.Normal.y * outdata.FogAndFade2.y;
        outdata.BlendValueAndFade.yw = pow(indata.Normal.y,8);

        //tl: pre calculate half-lerp against constant, result is 2 ps instruction lerp distributed
        //    to 1 vs MAD and 1 ps MAD
        //    outdata.FogAndFade2.z = outdata.BlendValueAndFade.y*-0.5 + 0.5;
    #endif
    outdata.Tex1 = projToLighting(outdata.Pos);
    return outdata;
}

struct Hi_VS2PS_FullDetailWithEnvMap
{
    float4	Pos : POSITION;
    float4	Tex0 : TEXCOORD0;
    float4	Tex1 : TEXCOORD1;
    float4	Tex3 : TEXCOORD3;
    float4	BlendValueAndFade : COLOR0;
    float3	Tex5 : TEXCOORD2;
    float2	Tex6 : TEXCOORD5;
    float3	EnvMap : TEXCOORD4;
    float4	FogAndFade2 : COLOR1;
};

float4 Hi_PS_FullDetailWithEnvMap(Hi_VS2PS_FullDetailWithEnvMap indata) : COLOR
{
    #if LIGHTONLY
        float4 accumlights = tex2Dproj(sampler1ClampPoint, indata.Tex1);
        float4 light = 2 * accumlights.w * vSunColor + accumlights;
        float4 component = tex2D(sampler2Clamp, indata.Tex0.xy);
        float chartcontrib = dot(vComponentsel, component);
        return chartcontrib*light;
    #else
        #if DEBUGTERRAIN
            return float4(0,1,0,1);
        #endif
        float3 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);

        float4 accumlights = tex2Dproj(sampler1Clamp, indata.Tex1);

        //tl: 2* moved later in shader to avoid clamping at -+2.0 in ps1.4
        float3 light = 2*accumlights.w * vSunColor.rgb + accumlights.rgb;

        float4 component = tex2D(sampler2Clamp, indata.Tex6);
        float chartcontrib = dot(vComponentsel, component);
        float4 detailmap = tex2D(dsampler3Wrap, indata.Tex3.xy);

        #if HIGHTERRAIN
            float4 lowComponent = tex2D(sampler5Clamp, indata.Tex6);
            float4 yplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex5.xy);
            float4 xplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex3.xy);
            float4 zplaneLowDetailmap = tex2D(sampler4Wrap, indata.Tex0.wz);
            float lowDetailmap = lerp(0.5, yplaneLowDetailmap.z, lowComponent.x*indata.FogAndFade2.y);
        #else
            float4 yplaneLowDetailmap = tex2D(ssampler4Wrap, indata.Tex5.xy);

            //tl: do lerp in 1 MAD by precalculating constant factor in vShader
            float lowDetailmap = 2*yplaneLowDetailmap.z * indata.BlendValueAndFade.y + indata.FogAndFade2.z;
        #endif

        #if HIGHTERRAIN
            float mounten =	(xplaneLowDetailmap.y * indata.BlendValueAndFade.x) +
                                (yplaneLowDetailmap.x * indata.BlendValueAndFade.y) +
                                (zplaneLowDetailmap.y * indata.BlendValueAndFade.z)	;

            lowDetailmap *= (4 * lerp(0.5, mounten, lowComponent.z));
            float3 bothDetailmap = detailmap * lowDetailmap;
            float3 detailout = lerp(2*bothDetailmap, lowDetailmap, indata.BlendValueAndFade.w);
        #else
            //tl: lerp optimized to handle 2*c*low + (2-2c)*detail, factors sent from vs
            float3 detailout = lowDetailmap*indata.BlendValueAndFade.x + 2*detailmap*indata.BlendValueAndFade.z;
        #endif

        float3 outColor = detailout * colormap * light;

        float4 envmapColor = texCUBE(sampler6Cube, indata.EnvMap);
        #if HIGHTERRAIN
            outColor = lerp(outColor, envmapColor, detailmap.w * (1-indata.BlendValueAndFade.w)) * 2;
        #else
            outColor = lerp(outColor, envmapColor, detailmap.w * (1-indata.FogAndFade2.y)) * 2;
        #endif

        outColor = lerp(FogColor, outColor, indata.FogAndFade2.x);
        return float4(chartcontrib * outColor, chartcontrib);
    #endif
}

Hi_VS2PS_FullDetailWithEnvMap Hi_VS_FullDetailWithEnvMap(Shared_APP2VS_Default indata)
{
    Hi_VS2PS_FullDetailWithEnvMap outdata = (Hi_VS2PS_FullDetailWithEnvMap)0;

    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    wPos.yw = (indata.Pos1.xw * vScaleTransY.xy);// + vScaleTransY.zw;

    #if DEBUGTERRAIN
        outdata.Pos = mul(wPos, mViewProj);
        outdata.Tex0 = float4(0,0,0,0);
        outdata.Tex1 = float4(0,0,0,0);
        outdata.BlendValueAndFade = float4(0,0,0,0);
        outdata.Tex3 = float4(0,0,0,0);
        outdata.Tex5.xy = float2(0,0);
        outdata.EnvMap = float3(0,0,0);
        outdata.FogAndFade2 = float4(0,0,0,0);
        return outdata;
    #endif

    float yDelta, interpVal;
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    //tl: uncompress normal
    indata.Normal = indata.Normal * 2 - 1;

    float3 tex = float3(indata.Pos0.y * vTexScale.z, wPos.y * vTexScale.y, indata.Pos0.x * vTexScale.x);
    float2 yPlaneTexCord = tex.zx;
    #if HIGHTERRAIN
        float2 xPlaneTexCord = tex.xy;
        float2 zPlaneTexCord = tex.zy;
    #endif

    outdata.Tex0.xy = (yPlaneTexCord*vColorLightTex.x) + vColorLightTex.y;
    outdata.Tex6 = (yPlaneTexCord*vDetailTex.x) + vDetailTex.y;

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
    outdata.FogAndFade2.yzw = 0.5 + interpVal * 0.5;

    #if HIGHTERRAIN
        outdata.BlendValueAndFade.w = interpVal;
    #elif MIDTERRAIN
        //tl: optimized so we can do more advanced lerp in same number of instructions
        //    factors are 2c and (2-2c) which equals a lerp()*2
        //    Don't use w, it's harder to access from ps1.4
        outdata.BlendValueAndFade.xz = interpVal * float2(2, -2) + float2(0, 2);
    #endif

    #if HIGHTERRAIN
        outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - vBlendMod);
        float tot = dot(1, outdata.BlendValueAndFade.xyz);
        outdata.BlendValueAndFade.xyz /= tot;
    #elif MIDTERRAIN
        //tl: use squared yNormal as blend val. pre-multiply with fade value.
        outdata.BlendValueAndFade.yw = indata.Normal.y * indata.Normal.y * outdata.FogAndFade2.y;

        outdata.FogAndFade2.y = interpVal;
        outdata.FogAndFade2.z = outdata.BlendValueAndFade.y*-0.5 + 0.5;
    #endif

    outdata.Tex1 = projToLighting(outdata.Pos);

    // Environment map
    // tl: no need to normalize, reflection works with long vectors,
    //     and cube maps auto-normalize.
    outdata.EnvMap = reflect(wPos.xyz - vCamerapos.xyz, float3(0,1,0));

    return outdata;
}








struct Hi_VS2PS_PerPixelPointLight
{
    float4 Pos    : POSITION;
    float3 wPos   : TEXCOORD0;
    float3 Normal : TEXCOORD1;
};

float4 Hi_PS_PerPixelPointLight(Hi_VS2PS_PerPixelPointLight indata) : COLOR
{
    return float4(calcPVPointTerrain(indata.wPos, indata.Normal), 0) * 0.5;
}

Hi_VS2PS_PerPixelPointLight Hi_VS_PerPixelPointLight(Shared_APP2VS_Default indata)
{
    Hi_VS2PS_PerPixelPointLight outdata;

    float4 wPos;
    wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
    //tl: Trans is always 0, and MADs cost more than MULs in certain cards.
    wPos.yw = indata.Pos1.xw * vScaleTransY.xy;

    float yDelta, interpVal;
    geoMorphPosition(wPos, indata.MorphDelta, indata.Pos0.z, yDelta, interpVal);

    //tl: output HPos as early as possible.
    outdata.Pos = mul(wPos, mViewProj);

    //tl: uncompress normal
    indata.Normal = indata.Normal * 2 - 1;

    outdata.Normal = indata.Normal;
    outdata.wPos = wPos.xyz;

    return outdata;
}


float4 Hi_PS_DirectionalLightShadows(Shared_VS2PS_DirectionalLightShadows indata) : COLOR
{
    float4 lightmap = tex2D(sampler0Clamp, indata.Tex0);

    float4 avgShadowValue = getShadowFactor(ShadowMapSampler, indata.ShadowTex);

    float4 light = saturate(lightmap.z * vGIColor * 2.0) * 0.5;
    if (avgShadowValue.z < lightmap.y)
        light.w = avgShadowValue.z;
    else
        light.w = lightmap.y;

    return light;
}














technique Hi_Terrain
{
    pass ZFillLightmap // p0
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESS;
        AlphaBlendEnable = FALSE;
        FogEnable = false;

        #if IS_NV4X
            StencilEnable = true;
            StencilFunc   = NOTEQUAL;
            StencilRef    = 0xa;
            StencilPass   = KEEP;
            StencilZFail  = KEEP;
            StencilFail   = KEEP;
        #endif

        VertexShader = compile vs_2_0 Shared_VS_ZFillLightmap();
        PixelShader = compile ps_2_0 Shared_PS_ZFillLightmap();
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

        #if IS_NV4X
            StencilEnable = true;
            StencilFunc   = NOTEQUAL;
            StencilRef    = 0xa;
            StencilPass   = KEEP;
            StencilZFail  = KEEP;
            StencilFail   = KEEP;
        #endif

        VertexShader = compile vs_2_0 Shared_VS_PointLight();
        PixelShader = compile ps_2_0 Shared_PS_PointLight();
    }

    pass {} // spotlight (removed) p2

    pass LowDiffuse		//p3
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        FogEnable = true;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;

        #if IS_NV4X
            StencilEnable = true;
            StencilFunc   = NOTEQUAL;
            StencilRef    = 0xa;
            StencilPass   = KEEP;
            StencilZFail  = KEEP;
            StencilFail   = KEEP;
        #endif

        VertexShader = compile vs_2_0 Shared_VS_LowDetail();
        PixelShader = compile ps_2_0 Shared_PS_LowDetail();
    }
    pass FullDetail	// p4
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
        FogEnable = false;

        #if IS_NV4X
            StencilEnable = true;
            StencilFunc   = NOTEQUAL;
            StencilRef    = 0xa;
            StencilPass   = KEEP;
            StencilZFail  = KEEP;
            StencilFail   = KEEP;
        #endif

        VertexShader = compile vs_2_0 Hi_VS_FullDetail();
        PixelShader = compile ps_2_0 Hi_PS_FullDetail();
    }
    pass FullDetailMounten	//p5
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
            StencilEnable = true;
            StencilFunc   = NOTEQUAL;
            StencilRef    = 0xa;
            StencilPass   = KEEP;
            StencilZFail  = KEEP;
            StencilFail   = KEEP;
        #endif

        VertexShader = compile vs_2_0 Hi_VS_FullDetailMounten();
        PixelShader = compile ps_2_0 Hi_PS_FullDetailMounten();
    }
    pass {} // p6 tunnels (removed)
    pass DirectionalLightShadows // p7
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;

        #if IS_NV4X
            StencilEnable = true;
            StencilFunc   = NOTEQUAL;
            StencilRef    = 0xa;
            StencilPass   = KEEP;
            StencilZFail  = KEEP;
            StencilFail   = KEEP;
        #endif

        VertexShader = compile vs_2_0 Shared_VS_DirectionalLightShadows();
        PixelShader = compile ps_2_0 Hi_PS_DirectionalLightShadows();
    }

    pass {} // DirectionalLightShadowsNV (removed)	//p8

    pass DynamicShadowmap // p9
    {
        // obsolete
    }

    pass {} // p10

    pass FullDetailWithEnvMap // p11
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
        FogEnable = false;

        #if IS_NV4X
            StencilEnable = true;
            StencilFunc   = NOTEQUAL;
            StencilRef    = 0xa;
            StencilPass   = KEEP;
            StencilZFail  = KEEP;
            StencilFail   = KEEP;
        #endif

        VertexShader = compile vs_2_0 Hi_VS_FullDetailWithEnvMap();
        PixelShader = compile ps_2_0 Hi_PS_FullDetailWithEnvMap();
    }

    pass {} // mulDiffuseFast (removed) p12

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
            StencilEnable = true;
            StencilFunc   = NOTEQUAL;
            StencilRef    = 0xa;
            StencilPass   = KEEP;
            StencilZFail  = KEEP;
            StencilFail   = KEEP;
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
            StencilEnable = true;
            StencilFunc   = NOTEQUAL;
            StencilRef    = 0xa;
            StencilPass   = KEEP;
            StencilZFail  = KEEP;
            StencilFail   = KEEP;
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
