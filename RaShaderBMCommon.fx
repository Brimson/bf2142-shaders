#include "shaders/dataTypes.fx"

// common BundledMesh samplers

texture	HemiMap;
sampler HemiMapSampler = sampler_state
{
    Texture = (HemiMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

texture	GIMap;
sampler GIMapSampler = sampler_state
{
    Texture = (GIMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
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

texture	DiffuseMap;
sampler DiffuseMapSampler = sampler_state
{
    Texture = (DiffuseMap);
    MipFilter = LINEAR;
    MinFilter = FILTER_BM_DIFF_MIN;
    MagFilter = FILTER_BM_DIFF_MAG;
    #ifdef FILTER_BM_DIFF_MAX_ANISOTROPY
        MaxAnisotropy 	= FILTER_BM_DIFF_MAX_ANISOTROPY;
    #endif
    AddressU = WRAP;
    AddressV = WRAP;
};

texture	NormalMap;
sampler NormalMapSampler = sampler_state
{
    Texture = (NormalMap);
    MipFilter = FILTER_BM_NORM_MIP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
};

vec4 ObjectSpaceCamPos;
vec4 WorldSpaceCamPos;

bool AlphaBlendEnable = false;
int  AlphaTestRef     = 0;
bool DepthWrite       = 1;
bool DoubleSided      = 2;

int SrcBlend  = 5;
int DestBlend = 6;

vec2 simpleUVTranslation;

vec4 DiffuseColor;
vec4 DiffuseColorAndAmbient;
vec4 SpecularColor;
scalar SpecularPower;
vec4 StaticGloss;
vec4 Ambient;

vec4 HemiMapConstantColor;
vec4 HemiMapSkyColor;

float InvHemiHeightScale = 100;
float HeightOverTerrain = 0.0;
float Reflectivity;

mat4x3 GeomBones[52];

struct
{
    mat4x4 uvMatrix[7]	: UVMatrix;
} UserData;

Light Lights[1];
vec4 PosUnpack;
scalar TexUnpack;
vec2 NormalUnpack;
