#include "shaders/dataTypes.fx"

// common StaticMesh samplers


// Fallback stuff
string DeprecationList[] =
{
	{"hasnormalmap", "objspacenormalmap", ""},
	{"usehemimap", "hasenvmap", ""},
	{"hasshadow", ""},
	{"hascolormapgloss", ""},
};

texture	HemiMap;
sampler HemiMapSampler = sampler_state
{
	Texture = (HemiMap);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
	MipMapLodBias = 0;
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
	MipMapLodBias = 0;
};

texture	DiffuseMap;
sampler DiffuseMapSampler = sampler_state
{
	Texture = (DiffuseMap);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
	MipMapLodBias = 0;
};

texture	NormalMap;
sampler NormalMapSampler = sampler_state
{
	Texture = (NormalMap);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
	MipMapLodBias = 0;
};

vec4	ObjectSpaceCamPos;
vec4	WorldSpaceCamPos;

int		AlphaTestRef		= 0;
bool	DepthWrite			= 1;
bool	DoubleSided			= 2;

vec4 	DiffuseColor;
vec4 	SpecularColor;
scalar 	SpecularPower;
scalar	StaticGloss;
vec4 	Ambient;

vec4	HemiMapSkyColor;
vec4	HemiMapConstantColor;
float	HeightOverTerrain = 0;

float	Reflectivity;

mat4x3 MatBones[52];

Light Lights[1];
