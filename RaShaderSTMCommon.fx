#include "shaders/dataTypes.fx"

#define nbase 0x1
#define ndetail 0x10

// common staticMesh samplers
texture	LightMap;
sampler LightMapSampler = sampler_state
{
    Texture = (LightMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
    MipMapLodBias = 0;
};

texture	DetailMap;
sampler DetailMapSampler = sampler_state
{
    Texture   = (DetailMap);
    MipFilter = LINEAR;
    MinFilter = FILTER_STM_DIFF_MIN;
    MagFilter = FILTER_STM_DIFF_MAG;
    #ifdef FILTER_STM_DIFF_MAX_ANISOTROPY
        MaxAnisotropy 	= FILTER_STM_DIFF_MAX_ANISOTROPY;
    #endif
    AddressU = WRAP;
    AddressV = WRAP;
};

texture DirtMap;
sampler DirtMapSampler = sampler_state
{
    Texture = (DirtMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

texture CrackMap;
sampler CrackMapSampler = sampler_state
{
    Texture = (CrackMap);
    MipFilter = LINEAR;
    MinFilter = FILTER_STM_DIFF_MIN;
    MagFilter = FILTER_STM_DIFF_MAG;
    #ifdef FILTER_STM_DIFF_MAX_ANISOTROPY
        MaxAnisotropy = FILTER_STM_DIFF_MAX_ANISOTROPY;
    #endif
    AddressU = WRAP;
    AddressV = WRAP;
};

texture CrackNormalMap;
sampler CrackNormalMapSampler = sampler_state
{
    Texture = (CrackNormalMap);
    MipFilter = FILTER_STM_NORM_MIP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

texture	DiffuseMap;
sampler DiffuseMapSampler = sampler_state
{
    Texture = (DiffuseMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

texture	NormalMap;
sampler NormalMapSampler = sampler_state
{
    Texture = (NormalMap);
    MipFilter = FILTER_STM_NORM_MIP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

texture	CubeMap;
sampler CubeMapSampler = sampler_state
{
    Texture = (CubeMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
    AddressW  = WRAP;
};

vec4 ObjectSpaceCamPos;
vec4 PosUnpack;
scalar TexUnpack;
vec2 NormalUnpack;
vec4 LightMapOffset;
bool AlphaBlendEnable;
vec4 StaticSkyColor;
vec4 StaticSpecularColor;
vec4 PointColor;
vec4 StaticSunColor;
vec4 SinglePointColor;
vec4 ParallaxScaleBias;
scalar  StaticGloss;
