#include "shaders/RaDefines.fx"
#include "shaders/dataTypes.fx"

#ifdef DISABLE_DIFFUSEMAP
    #ifdef DISABLE_BUMPMAP
        #ifndef DISABLE_SPECULAR
            #define DRAW_ONLY_SPEC
        #endif
    #endif
#endif

#ifdef DRAW_ONLY_SPEC
    #define DEFAULT_DIFFUSE_MAP_COLOR vec4(0.0, 0.0, 0.0, 1.0)
#else
    #define DEFAULT_DIFFUSE_MAP_COLOR 1.0
#endif

// VARIABLES
struct Light
{
    float3 pos;
    float3 dir;
    float4 color;
    float4 specularColor;
    float attenuation;
};

int srcBlend = 5;
int destBlend = 6;
bool alphaBlendEnable = true;

int alphaRef = 20;
int CullMode = 3; // D3DCULL_CCW

scalar GlobalTime;
scalar WindSpeed = 0;

vec4 HemiMapConstants;

//tl: This is a scalar replicated to a vec4 to make 1.3 shaders more efficient (they can't access .rg directly)
vec4 Transparency = 1.0f;

mat4x4 World : World;
mat4x4 ViewProjection;
mat4x4 WorldViewProjection;

bool AlphaTest = false;

vec4 FogRange : fogRange;
vec4 FogColor : fogColor;

scalar calcFog(scalar w)
{
    half2 fogVals = w * FogRange.xy + FogRange.zw;
    half close = max(fogVals.y, FogColor.w);
    half far = pow(fogVals.x, 3.0);
    return close-far;
}

#define NO_VAL vec3(1.0, 1.0, 0.0)

vec4 showChannel
(
    vec3 diffuse = NO_VAL,
    vec3 normal = NO_VAL,
    scalar specular = 0,
    scalar alpha = 0,
    vec3 shadow = 0,
    vec3 environment = NO_VAL
)
{
    vec4 returnVal = vec4(0.0, 1.0, 1.0, 0.0);
    #ifdef DIFFUSE_CHANNEL
        returnVal = vec4(diffuse, 1.0);
    #endif

    #ifdef NORMAL_CHANNEL
        returnVal = vec4(normal, 1.0);
    #endif

    #ifdef SPECULAR_CHANNEL
        returnVal = vec4(specular, specular, specular, 1.0);
    #endif

    #ifdef ALPHA_CHANNEL
        returnVal = vec4(alpha, alpha, alpha, 1.0);
    #endif

    #ifdef ENVIRONMENT_CHANNEL
        returnVal = vec4(environment, 1.0);
    #endif

    #ifdef SHADOW_CHANNEL
        returnVal = vec4(shadow, 1.0);
    #endif

    return returnVal;
}



// Common dynamic shadow stuff

#if !defined(SHADOWVERSION) && defined(PSVERSION)
    #define SHADOWVERSION PSVERSION
#elif !defined(SHADOWVERSION)
    #define SHADOWVERSION 0
#endif

mat4x4 ShadowProjMat : ShadowProjMatrix;
mat4x4 ShadowOccProjMat : ShadowOccProjMatrix;
mat4x4 ShadowTrapMat : ShadowTrapMatrix;

texture ShadowMap : SHADOWMAP;
sampler ShadowMapSampler
#ifdef _CUSTOMSHADOWSAMPLER_
    : register(_CUSTOMSHADOWSAMPLER_)
#endif
= sampler_state
{
    Texture = (ShadowMap);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
    AddressW = Clamp;
};

texture ShadowOccluderMap : SHADOWOCCLUDERMAP;
sampler ShadowOccluderMapSampler
= sampler_state
{
    Texture = (ShadowOccluderMap);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
    AddressW = Clamp;
};

//tl: Make _sure_ pos and matrices are in same space!
vec4 calcShadowProjection(vec4 pos, uniform scalar BIAS = -0.003, uniform bool ISOCCLUDER = false)
{
    vec4 texShadow1 =  mul(pos, ShadowTrapMat);

    vec2 texShadow2;
    if(ISOCCLUDER)
        texShadow2 = mul(pos, ShadowOccProjMat).zw;
    else
        texShadow2 = mul(pos, ShadowProjMat).zw;

    texShadow2.x += BIAS;
    #if !NVIDIA
        texShadow1.z = texShadow2.x;
    #else
        texShadow1.z = (texShadow2.x*texShadow1.w) / texShadow2.y; // (zL*wT)/wL == zL/wL post homo
    #endif

    return texShadow1;
}

//tl: Make _sure_ pos and matrices are in same space!
vec4 calcShadowProjectionExact(vec4 pos, uniform scalar BIAS = -0.003)
{
    vec4 texShadow1 =  mul(pos, ShadowTrapMat);
    vec2 texShadow2 = mul(pos, ShadowProjMat).zw;
    texShadow2.x += BIAS;
    texShadow1.z = texShadow2.x;
    return texShadow1;
}

vec4 getShadowFactorNV(sampler shadowSampler, vec4 shadowCoords, uniform int NSAMPLES = 4, uniform int VERSION = SHADOWVERSION)
{
    return tex2Dproj(shadowSampler, shadowCoords);
}

vec4 getShadowFactorExactNV(sampler shadowSampler, vec4 shadowCoords, uniform int NSAMPLES = 4, uniform int VERSION = SHADOWVERSION)
{
    shadowCoords.z *= shadowCoords.w;
    return tex2Dproj(shadowSampler, shadowCoords);
}

vec4 getShadowFactorExactOther(sampler shadowSampler, vec4 shadowCoords, uniform int NSAMPLES = 4, uniform int VERSION = SHADOWVERSION)
{
    if(NSAMPLES == 1)
    {
        scalar samples = tex2Dproj(shadowSampler, shadowCoords).r;
        return samples >= saturate(shadowCoords.z);
    }
    else
    {
        vec4 texel = vec4(0.5 / 1024.0, 0.5 / 1024.0, 0.0, 0.0);
        vec4 samples = 0.0;
        samples.x = tex2Dproj(shadowSampler, shadowCoords).r;
        samples.y = tex2Dproj(shadowSampler, shadowCoords + vec4(texel.x, 0.0, 0.0, 0.0)).r;
        samples.z = tex2Dproj(shadowSampler, shadowCoords + vec4(0.0, texel.y, 0.0, 0.0)).r;
        samples.w = tex2Dproj(shadowSampler, shadowCoords + texel).r;
        vec4 cmpbits = samples >= saturate(shadowCoords.z);
        return dot(cmpbits, 0.25);
    }
}

//fks: special case for ATI heavy staticmesh-shaders with envmap
vec4 getShadowFactorLow(sampler shadowSampler, vec4 shadowCoords, uniform int NSAMPLES = 1, uniform int VERSION = SHADOWVERSION)
{
    return (tex2Dproj(shadowSampler, shadowCoords) >= saturate(shadowCoords.z));
}

// Currently fixed to 3 or 4.
vec4 getShadowFactor(sampler shadowSampler, vec4 shadowCoords, uniform int NSAMPLES = 4, uniform int VERSION = SHADOWVERSION)
{
    #if NVIDIA
        return getShadowFactorNV(shadowSampler, shadowCoords, NSAMPLES, VERSION);
    #else
        return getShadowFactorExactOther(shadowSampler, shadowCoords, NSAMPLES, VERSION);
    #endif
}

vec4 getShadowFactorExact(sampler shadowSampler, vec4 shadowCoords, uniform int NSAMPLES = 4, uniform int VERSION = SHADOWVERSION)
{
    #if NVIDIA
        return getShadowFactorExactNV(shadowSampler, shadowCoords, NSAMPLES, VERSION);
    #else
        return getShadowFactorExactOther(shadowSampler, shadowCoords, NSAMPLES, VERSION);
    #endif
}

texture SpecLUT64SpecularColor;
sampler SpecLUT64Sampler = sampler_state
{
    Texture = (SpecLUT64SpecularColor);
    MipFilter = NONE;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture NormalizationCube;
sampler NormalizationCubeSampler = sampler_state
{
    Texture = (NormalizationCube);
    MipFilter = POINT;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
    AddressW  = WRAP;
};

#define NRMDONTCARE 0
#define NRMCUBE		1
#define NRMMATH		2
#define NRMCHEAP	3
vec3 fastNormalize(vec3 invec, uniform int preferMethod = NRMDONTCARE)
{
    return normalize(invec);
}
