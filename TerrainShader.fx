#line 2 "TerrainShader.fx"

#if !NVIDIA
    #if HIGHTERRAIN
        #define PSVERSION 21
    #elif MIDTERRAIN
        #define PSVERSION 21
    #else
        #define PSVERSION 21
    #endif
#endif

#if NVIDIA
    #define SHADOWPSMODEL ps_2_0
    #define SHADOWVERSION 21
#else
    #define SHADOWPSMODEL ps_2_0
    #define SHADOWVERSION 21
#endif

#include "shaders/datatypes.fx"
#include "shaders/raCommon.fx"

// -- Shared stuff

mat4x4  mViewProj: matVIEWPROJ;
mat4x4  mView: matVIEW;
vec4    vScaleTransXZ : SCALETRANSXZ;
vec4    vScaleTransY : SCALETRANSY;
scalar  ScaleBaseUV : SCALEBASEUV;
vec4    vShadowTexCoordScaleAndOffset : SHADOWTEXCOORDSCALEANDOFFSET;

vec4 vMorphDeltaSelector : MORPHDELTASELECTOR;
vec2 vNearFarMorphLimits : NEARFARMORPHLIMITS;

vec4 vDebugColor : DEBUGCELLCOLOR;

vec4 vCamerapos : CAMERAPOS;

vec3 vComponentsel : COMPONENTSELECTOR;

vec4 vSunColor : SUNCOLOR;
vec4 vGIColor : GICOLOR;

vec4    vSunDirection : SUNDIRECTION;
vec4    vLightPos1 : LIGHTPOS1;
vec4    vLightCol1 : LIGHTCOL1;
scalar  LightAttSqrInv1 : LIGHTATTSQRINV1;
vec4    vLightPos2 : LIGHTPOS2;
vec4    vLightCol2 : LIGHTCOL2;
scalar  LightAttSqrInv2 : LIGHTATTSQRINV2;

vec4 vTexProjOffset : TEXPROJOFFSET;
vec4 vTexProjScale : TEXPROJSCALE;

float4 vTexCordXSel : TEXCORDXSEL;
float4 vTexCordYSel : TEXCORDYSEL;
float4 vTexScale : TEXSCALE;
float4 vNearTexTiling : NEARTEXTILING;
float4 vFarTexTiling : FARTEXTILING;

vec4 vYPlaneTexScaleAndFarTile : YPLANETEXSCALEANDFARTILE;

float3 vBlendMod : BLENDMOD = float3(0.2, 0.5, 0.2);

float waterHeight : WaterHeight;
float4 terrainWaterColor : TerrainWaterColor;

mat4x4  mLightVP : LIGHTVIEWPROJ;
mat4x4  mLightVPOrtho : LIGHTVIEWPROJORTHO;
vec4    vViewportMap : VIEWPORTMAP;

float4x4 vSTTransXZ : STTRANSXZ;
float4   vSTFarTexTiling : STFARTEXTILING;
float4   vSTTexScale : STTEXSCALE;
vec4     vSTScaleTransY : STSCALETRANSY;

vec2 vColorLightTex : COLORLIGHTTEX;
vec2 vDetailTex : DETAILTEX;
vec2 vSTColorLightTex : STCOLORLIGHTTEX;
vec2 vSTLowDetailTex : STLOWDETAILTEX;

float3	vMorphDeltaAdder[3] : MORPHDELTAADDER;

texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
texture texture2 : TEXLAYER2;
texture texture3 : TEXLAYER3;
texture texture4 : TEXLAYER4;
texture texture5 : TEXLAYER5;
texture texture6 : TEXLAYER6;

sampler sampler0Clamp = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler1Clamp = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler2Clamp = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler3Clamp = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler2PointClamp = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = POINT; };
sampler sampler2Point = sampler_state { Texture = (texture2); MinFilter = POINT; MagFilter = POINT; };
sampler sampler4Clamp = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler5Clamp = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler0Wrap = sampler_state { Texture = (texture0); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler1Wrap = sampler_state { Texture = (texture1); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler2Wrap = sampler_state { Texture = (texture2); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler3Wrap = sampler_state { Texture = (texture3); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler4Wrap = sampler_state { Texture = (texture4); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler4Wrap2 = sampler_state { Texture = (texture4); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler4Wrap3 = sampler_state { Texture = (texture4); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler5Wrap = sampler_state { Texture = (texture5); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler6Wrap = sampler_state { Texture = (texture6); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler3 = sampler_state { Texture = (texture3); };
sampler sampler4 = sampler_state { Texture = (texture4); };
sampler sampler0ClampPoint = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler1ClampPoint = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler2ClampPoint = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler3ClampPoint = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
samplerCUBE sampler6Cube = sampler_state { Texture = (texture6); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

sampler sampler1ClampPoint_BoundToStage1 : register(s1) = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };

#include "Shaders/commonVertexLight.fx"
#include "Shaders/TerrainShader_Shared.fx"
#if HIGHTERRAIN || MIDTERRAIN
    #include "Shaders/TerrainShader_Hi.fx"
#endif
    #include "Shaders/TerrainShader_Low.fx"
