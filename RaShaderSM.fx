
// -- New, better, "cleaner" skinning code.

#include "shaders/RaCommon.fx"
#include "shaders/RaShaderSMCommon.fx"

// Dep.checks, etc
#if _POINTLIGHT_
    #define _HASENVMAP_ 0
    #define _USEHEMIMAP_ 0
    #define _HASSHADOW_ 0
#endif

//tl: Only allow 4 samples if model is 2.a/2.b
#if PSVERSION == 20
    #define NUMOCCLUSIONSAMPLES 1
#else
    #define NUMOCCLUSIONSAMPLES 4
#endif

// Only apply per-pixel hemi for rapath 0
#if _USEHEMIMAP_ && RAPATH == 0
    #define _USEPERPIXELHEMIMAP_ 1
#else
    #define _USEPERPIXELHEMIMAP_ 0
#endif

#define _USEPERPIXELNORMALIZE_ 1
#define _USERENORMALIZEDTEXTURES_ 1

// Always 2 for now, test with 1!
#define NUMBONES 2

struct SMVariableVSInput
{
    float4   Pos          : POSITION;
    float3   Normal       : NORMAL;
    float BlendWeights : BLENDWEIGHT;
    float4   BlendIndices : BLENDINDICES;
    float2   TexCoord0    : TEXCOORD0;
    float3   Tan          : TANGENT;
};

struct SMVariableVSOutput
{
    float4 Pos                : POSITION;
    float4 DiffuseAndHemiLerp : COLOR0;
    float4 Specular           : COLOR1;
    float2 Tex0               : TEXCOORD0;
    float3 GroundUVOrWPos     : TEXCOORD1;

    #if _HASNORMALMAP_
        float3 LightVec       : TEXCOORD2;
        #if _HASSHADOW_ || _HASSHADOWOCCLUSION_
            float4 ShadowMat  : TEXCOORD4;
        #endif
    #elif _HASSHADOW_ || _HASSHADOWOCCLUSION_
        float4 ShadowMat      : TEXCOORD2;
    #endif

    float4   HalfVecAndOccShadow : TEXCOORD3;
    float Fog                 : FOG;

    #if _USEPERPIXELHEMIMAP_
        // Used only for per-pixel hemi
        float3 TexToWorld0 : TEXCOORD5;
        float3 TexToWorld1 : TEXCOORD6;
        float3 TexToWorld2 : TEXCOORD7;
    #endif
};

float getBlendWeight(SMVariableVSInput input, uniform int bone)
{
    if(bone == 0)
        return input.BlendWeights;
    else
        return 1.0 - input.BlendWeights;
}

float4x3 getBoneMatrix(SMVariableVSInput input, uniform int bone)
{
    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;
    return MatBones[IndexArray[bone]];
}

float getBinormalFlipping(SMVariableVSInput input)
{
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;
    return 1.0f + IndexArray[2] * -2.0f;
}

float3x3 getTangentBasis(SMVariableVSInput input)
{
    float flip = getBinormalFlipping(input);
    float3 binormal = normalize(cross(input.Tan, input.Normal)) * flip;
    return float3x3(input.Tan, binormal, input.Normal);
}

float3 skinPos(SMVariableVSInput input, float4 Vec, uniform int numBones = NUMBONES)
{
    float3 skinnedPos = mul(Vec, getBoneMatrix(input, 0));
    if(numBones > 1)
    {
        skinnedPos *= getBlendWeight(input, 0);
        skinnedPos += mul(Vec, getBoneMatrix(input, 1)) * getBlendWeight(input, 1);
    }
    return skinnedPos;
}

float3 skinVec(SMVariableVSInput input, float3 Vec, uniform int numBones = NUMBONES)
{
    float3 skinnedVec = mul(Vec, getBoneMatrix(input, 0));
    if(numBones > 1)
    {
        skinnedVec *= getBlendWeight(input, 0);
        skinnedVec += mul(Vec, getBoneMatrix(input, 1)) * getBlendWeight(input, 1);
    }
    return skinnedVec;
}

float3 skinVecToObj(SMVariableVSInput input, float3 Vec, uniform int numBones = NUMBONES)
{
    float3 skinnedVec = mul(Vec, transpose(getBoneMatrix(input, 0)));
    if(numBones > 1)
    {
        skinnedVec *= getBlendWeight(input, 0);
        skinnedVec += mul(Vec, transpose(getBoneMatrix(input, 1))) * getBlendWeight(input, 1);
    }

    return skinnedVec;
}

float3 skinVecToTan(SMVariableVSInput input, float3 Vec, uniform int numBones = NUMBONES)
{
    float3x3 tanBasis = getTangentBasis(input);

    float3x3 toTangent0 = transpose(mul(tanBasis, getBoneMatrix(input, 0)));
    float3 skinnedVec = mul(Vec, toTangent0);

    if(numBones > 1)
    {
        skinnedVec *= getBlendWeight(input, 0);
        float3x3 toTangent1 = transpose(mul(tanBasis, getBoneMatrix(input, 1)));
        skinnedVec += mul(Vec, toTangent1) * getBlendWeight(input, 1);
    }

    return skinnedVec;
}

float4 skinPosition(SMVariableVSInput input)
{
    return float4(skinPos(input, input.Pos), 1);
}

float3 skinNormal(SMVariableVSInput input, uniform int numBones = NUMBONES)
{
    float3 skinnedNormal = skinVec(input, input.Normal);
    if(numBones > 1)
    {
        // Re-normalize skinned normal
        skinnedNormal = normalize(skinnedNormal);
    }
    return skinnedNormal;
}

float4 getWorldPos(SMVariableVSInput input)
{
    return mul(skinPosition(input), World);
}

float3 getWorldNormal(SMVariableVSInput input)
{
    return mul(skinNormal(input), World);
}

float4 calcGroundUVAndLerp(float3 wPos, float3 wNormal)
{
    float4 GroundUVAndLerp = 0;
    GroundUVAndLerp.xy	= ((wPos + (HemiMapConstants.z * 0.5) + wNormal).xz - HemiMapConstants.xy) / HemiMapConstants.z;
    GroundUVAndLerp.y	= 1.0 - GroundUVAndLerp.y;

    // localHeight scale, 1 for top and 0 for bottom
    float localHeight = (wPos.y - (World[3][1] - 0.5)) * 0.5;

    float offset     = (localHeight * 2.0 - 1.0) + HeightOverTerrain;
    offset            = clamp(offset, -2.0 * (1.0 - HeightOverTerrain), 0.8); // For TL: seems like taking this like away doesn't change much, take it out?
    GroundUVAndLerp.z = clamp((wNormal.y + offset) * 0.5 + 0.5, 0.0, 0.9);

    return GroundUVAndLerp;
}

float3 skinLightVec(SMVariableVSInput input, float3 lVec)
{
    #if _OBJSPACENORMALMAP_ || !_HASNORMALMAP_
        return skinVecToObj(input, lVec, 1);
    #else
        return skinVecToTan(input, lVec, 1);
    #endif
}

// NOTE: This returns un-normalized for point, because point needs to be attenuated.
float3 getLightVec(SMVariableVSInput input)
{
    #if _POINTLIGHT_
        return (Lights[0].pos - skinPosition(input).xyz);
    #else
        return -Lights[0].dir;
    #endif
}

SMVariableVSOutput vs(SMVariableVSInput input)
{
    SMVariableVSOutput Out = (SMVariableVSOutput)0;

    float4 objSpacePosition = skinPosition(input);

    Out.Pos = mul(objSpacePosition, WorldViewProjection);
    Out.Tex0 = input.TexCoord0;

    #if (_USEHEMIMAP_ && !_USEPERPIXELHEMIMAP_) || (_USEHEMIMAP_ && !_HASNORMALMAP_)
        Out.GroundUVOrWPos = calcGroundUVAndLerp(getWorldPos(input), getWorldNormal(input));
        Out.DiffuseAndHemiLerp.w = Out.GroundUVOrWPos.z;
    #elif _USEPERPIXELHEMIMAP_
        #if _OBJSPACENORMALMAP_
            float3x3 objToTexture0 = getBoneMatrix(input, 0);
        #else
            float3x3 objToTexture0 = mul(getTangentBasis(input), getBoneMatrix(input, 0));
        #endif
        float3x3 worldToTexture0 = mul(objToTexture0, World);
        worldToTexture0 = transpose(worldToTexture0);
        Out.TexToWorld0 = worldToTexture0[0];
        Out.TexToWorld1 = worldToTexture0[1];
        Out.TexToWorld2 = worldToTexture0[2];
        Out.GroundUVOrWPos = getWorldPos(input);
    #endif

    float3 objEyeVec = normalize(ObjectSpaceCamPos.xyz - objSpacePosition.xyz);
    float3 lVec = skinLightVec(input, getLightVec(input));
    float3 hVec = normalize(lVec) + normalize(skinLightVec(input, objEyeVec));

    #if _HASNORMALMAP_
        Out.LightVec = lVec;
        #if !_POINTLIGHT_
            Out.LightVec = normalize(Out.LightVec);
            Out.Fog = calcFog(Out.Pos.w);
        #endif
        Out.HalfVecAndOccShadow.xyz = normalize(hVec);
    #else
        float4 lighting = lit(dot(normalize(lVec), input.Normal), dot(normalize(hVec), input.Normal), SpecularPower);
        Out.DiffuseAndHemiLerp.rgb = (lighting.y * Lights[0].color) * 0.5;
        #if _POINTLIGHT_
            Out.Specular.rgb = (lighting.z * Lights[0].color * 0.15) * 0.5;
        #else
            Out.Specular.rgb = (lighting.z * Lights[0].specularColor * 0.15) * 0.5;
            Out.Fog = calcFog(Out.Pos.w);
        #endif
    #endif

    #if _HASSHADOW_ || _HASSHADOWOCCLUSION_
        Out.ShadowMat = calcShadowProjection(getWorldPos(input));
    #endif
    #if _HASSHADOWOCCLUSION_
        Out.HalfVecAndOccShadow.w = calcShadowProjection(getWorldPos(input), -0.003, true).z;
    #endif

    return Out;
}

float4 ps(SMVariableVSOutput input) : COLOR
{
    #if _HASNORMALMAP_
        float4 normal = tex2D(NormalMapSampler, input.Tex0);
        normal.xyz = normal.xyz * 2.0 - 1.0;
        #if _USERENORMALIZEDTEXTURES_
            normal.xyz = normalize(normal.xyz);
        #endif

        #ifdef NORMAL_CHANNEL
            return float4(normal.xyz * 0.5 + 0.5, 1.0);
        #endif

        float gloss = normal.a;
        float3 lightVec = input.LightVec;

        #if _POINTLIGHT_
            float attenuation = 1.0 - saturate(length(lightVec) * Lights[0].attenuation);
            lightVec = normalize(lightVec);
        #else
            const float attenuation = 1.0;
        #endif

        float dot3Light = saturate(dot(lightVec, normal));
        float specular = pow(saturate(dot(normalize(input.HalfVecAndOccShadow.xyz), normal)), SpecularPower);

        specular *= gloss;
        dot3Light *= attenuation;
        specular *= attenuation;
    #endif

    // Remember, optimize for HWSM and ps1.3 (yes, it can be done!)
    #if _HASSHADOW_
        float dirShadow = getShadowFactor(ShadowMapSampler, input.ShadowMat);
    #else
        float dirShadow = 1.0;
    #endif

    #if _HASSHADOWOCCLUSION_
        float4 shadowOccMat = input.ShadowMat;
        shadowOccMat.z = input.HalfVecAndOccShadow.w;
        float dirOccShadow = getShadowFactor(ShadowOccluderMapSampler, shadowOccMat, NUMOCCLUSIONSAMPLES);
        dirShadow *= dirOccShadow;
    #endif

    #if (_USEHEMIMAP_ && !_USEPERPIXELHEMIMAP_) || (_USEHEMIMAP_ && !_HASNORMALMAP_)
        float4 groundcolor = tex2D(HemiMapSampler, input.GroundUVOrWPos.xy);
        float3 hemicolor   = lerp(groundcolor, HemiMapSkyColor, input.DiffuseAndHemiLerp.w)* HemiMapConstantColor.xyz;
    #elif _USEPERPIXELHEMIMAP_ && !_NOTHING_
        float3 wNormal;
        wNormal.x = dot(input.TexToWorld0, normal);
        wNormal.y = dot(input.TexToWorld1, normal);
        wNormal.z = dot(input.TexToWorld2, normal);
        float3 GroundUVAndLerp = calcGroundUVAndLerp(input.GroundUVOrWPos, wNormal);
        float4 groundcolor     = tex2D(HemiMapSampler, GroundUVAndLerp.xy);
        float3 hemicolor       = lerp(groundcolor, HemiMapSkyColor, GroundUVAndLerp.z)*HemiMapConstantColor.xyz;
    #else
        const float3 hemicolor = HemiMapConstantColor.xyz; // "old"  -- expose a per-level "static hemi" value (ambient mod)
        float4 groundcolor = 1.0;
    #endif

    #if _HASHEMIOCCLUSION_
        dirShadow *= groundcolor.a;
    #endif

    float4 diffuseTex = tex2D(DiffuseMapSampler, input.Tex0);

    #ifdef	DIFFUSE_CHANNEL
        return diffuseTex;
    #endif

    float4 outColor;

    #if _HASNORMALMAP_
        dot3Light *= dirShadow;
        specular *= dirShadow;

        #if _POINTLIGHT_
            outColor.rgb = dot3Light * Lights[0].color;
        #else
            outColor.rgb = (dot3Light * Lights[0].color) + hemicolor;
        #endif
        #ifdef SHADOW_CHANNEL
            return float4(outColor.rgb, 1);
        #endif
        outColor.rgb *= diffuseTex;
        #if _POINTLIGHT_
            outColor.rgb += specular * Lights[0].specularColor;
        #else
            outColor.rgb += specular * Lights[0].specularColor;
        #endif
    #else
        #if _POINTLIGHT_
            outColor.rgb = input.DiffuseAndHemiLerp * 2.0;
        #else
            outColor.rgb = (input.DiffuseAndHemiLerp * 2.0) * dirShadow + hemicolor;
        #endif
        outColor.rgb *= diffuseTex;
        outColor.rgb += (input.Specular.rgb * 2.0) * dirShadow;
    #endif

    outColor.a = diffuseTex.a*Transparency.a;

    return outColor;
}

float4 ps_other(SMVariableVSOutput input) : COLOR
{
    float4 diffuseMap = tex2D(DiffuseMapSampler, input.Tex0);
    const float4 color = float4(0.212500006, 0.212500006, 0.200000003, 0.0);
    float4 output;
    output.xyz = input.DiffuseAndHemiLerp + color;
    output.w = diffuseMap * Transparency;
    output.xyz = (diffuseMap * output + input.Specular) * 2.0;
    return output;
}

technique defaultTechnique
{
    pass
    {
        AlphaTestEnable = (AlphaTest);
        AlphaRef        = (AlphaTestRef);
        #if _POINTLIGHT_
            AlphaBlendEnable = TRUE;
            SrcBlend         = ONE;
            DestBlend        = ONE;
            fogenable        = false;
        #else
            AlphaBlendEnable = FALSE;
            FogEnable        = TRUE;
        #endif

        VertexShader = compile vs_2_0 vs();

        #if 1
            PixelShader = compile ps_2_0 ps();
        #else
            PixelShader = compile ps_2_0 ps_other();
        #endif
    }
}
