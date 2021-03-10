#include "shaders/datatypes.fx"
#include "shaders/raCommon.fx"

/*
    #define USE_FRESNEL
    #define USE_SPECULAR
    #define USE_SHADOWS
    #define PIXEL_CAMSPACE
    #define USE_3DTEXTURE
    #define PS_20
*/

// Affects how transparency is claculated depending on camera height.
// Try increasing/decreasing ADD_ALPHA slighty for different results
#define MAX_HEIGHT 20
#define ADD_ALPHA 0.75

// Darkness of water shadows - Lower means darker
#define SHADOW_FACTOR 0.75

// Higher value means less transparent water
#define BASE_TRANSPARENCY 1.5F

// Like specular - higher values gives smaller, more distinct area of transparency
#define POW_TRANSPARENCY 30.F

// How much of the texture color to use (vs envmap color)
#define COLOR_ENVMAP_RATIO 0.4F

// Modifies heightalpha (for tweaking transparancy depending on depth)
#define APOW 1.3

// Wether to use normalmap for transparency calculation or not
// #define FRESNEL_NORMALMAP

/*
    scalar uvLevelAddX;
    scalar uvLevelMulX;
    scalar uvLevelAddY;
    scalar uvLevelMulY;
*/

vec4 LightMapOffset;

scalar WaterHeight;

Light Lights[1];

vec4 WorldSpaceCamPos;
vec4 WaterScroll;

scalar	WaterCycleTime;

vec4 SpecularColor;
scalar SpecularPower;
vec4 WaterColor;
vec4 PointColor;

#ifdef DEBUG
    #define _WaterColor vec4(1,0,0,1)
#else
    #define _WaterColor WaterColor
#endif

texture	CubeMap;
sampler CubeMapSampler = sampler_state
{
    Texture = (CubeMap);
    MipFilter = LINEAR; // Rasterizing speedup
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
    AddressW  = WRAP;
    MipMapLodBias = 0;
};

#ifdef USE_3DTEXTURE

texture	WaterMap;
sampler WaterMapSampler = sampler_state
{
    Texture = (WaterMap);
    MipFilter = LINEAR; // Rasterizing speedup
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
    AddressW  = WRAP;
    MipMapLodBias = 0;
};

#else

texture	WaterMapFrame0;
sampler WaterMapSampler0 = sampler_state
{
    Texture = (WaterMapFrame0);
    MipFilter = LINEAR; // Rasterizing speedup
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
    MipMapLodBias = 0;
};

texture	WaterMapFrame1;
sampler WaterMapSampler1 = sampler_state
{
    Texture = (WaterMapFrame1);
    MipFilter = LINEAR; // Rasterizing speedup
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
    MipMapLodBias = 0;
};

#endif

texture LightMap;
sampler LightMapSampler = sampler_state
{
    Texture = (LightMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV  = CLAMP;
    MipMapLodBias = 0;
};

struct VS_OUTPUT_WATER
{
    vec4 Pos : POSITION;
    // vec4 Color : COLOR;
    scalar Fog : FOG;
    #ifdef USE_3DTEXTURE
        vec3 Tex : TEXCOORD0;
    #else
        vec2 Tex : TEXCOORD0;
    #endif
    #ifndef NO_LIGHTMAP
        vec2 lmtex : TEXCOORD1;
    #endif
        vec3 Position : TEXCOORD2;
    #ifdef USE_SHADOWS
        vec4 TexShadow : TEXCOORD3;
    #endif
};

string reqVertexElement[] =
{
    "Position",
    "TLightMap2D"
};

string GlobalParameters[] =
{
    "WorldSpaceCamPos",
    "FogRange",
    "FogColor",
    "WaterCycleTime",
    "WaterScroll",
    #ifdef USE_3DTEXTURE
        "WaterMap",
    #else
        "WaterMapFrame0",
        "WaterMapFrame1",
    #endif
    "WaterHeight",
    "WaterColor"
    // "ShadowMap"
};

string InstanceParameters[] =
{
    "ViewProjection",
    "CubeMap",
    "LightMap",
    "LightMapOffset",
    #ifdef USE_SPECULAR
        "SpecularColor",
        "SpecularPower",
    #endif

    #ifdef USE_SHADOWS
        "ShadowProjMat",
        "ShadowTrapMat",
        "ShadowMap",
    #endif
    "PointColor",
    "Lights",
    "World"
};


VS_OUTPUT_WATER waterVertexShader(vec4 inPos : POSITION0, vec2 lmtex : TEXCOORD1)
{
    VS_OUTPUT_WATER Out;// = (VS_OUTPUT_WATER)0;

    vec4 wPos		= mul(inPos, World);

    // float h = (WorldSpaceCamPos.y - WaterHeight);
    // wPos.y += h/500;

    Out.Pos		= mul(wPos, ViewProjection);

    #ifdef PIXEL_CAMSPACE
        Out.Position = wPos;
    #else
        Out.Position = -(WorldSpaceCamPos - wPos) * 0.02;
    #endif

    #ifdef USE_3DTEXTURE
        vec3 tex;
        tex.xy = wPos.xz / vec2(29.13, 31.81);//+ frameTime*1;
        tex.xy += (WaterScroll.xy * WaterCycleTime);
        tex.z = WaterCycleTime * 10.0 + dot(tex.xy, vec2(0.7, 1.13)); //(inPos.x + inPos.y) / 100;
    #else
        vec2 tex;
        tex.xy = (wPos.xz / vec2(99.13, 71.81));//+ frameTime*1;
        // tex.xy += WaterCycleTime;
    #endif

    #ifdef PS13
        Out.Tex0 = tex;
        Out.Tex1 = tex;
    #else
        #ifdef USE_3DTEXTURE
            Out.Tex = tex;
        #else
            Out.Tex = tex;
        #endif
    #endif


    #ifndef NO_LIGHTMAP
        Out.lmtex.xy = lmtex.xy * LightMapOffset.xy + LightMapOffset.zw;
    #endif
        Out.Fog = calcFog(Out.Pos.w);

    #ifdef USE_SHADOWS
        Out.TexShadow = calcShadowProjection(wPos);
    #endif

    return Out;
}

#define INV_LIGHTDIR vec3(0.4, 0.5, 0.6)

vec4 waterPixelShader(in VS_OUTPUT_WATER VsData) : COLOR
{
    vec4 finalColor;

    #ifdef NO_LIGHTMAP // F85BD0
        vec4 lightmap = PointColor; //vec4(1, StaticGloss, 0.8, 1);
    #else
        vec4 lightmap = tex2D(LightMapSampler, VsData.lmtex);
    #endif

    #ifdef USE_3DTEXTURE
        vec3 TN = tex3D(WaterMapSampler, VsData.Tex);
    #else
        vec3 TN = lerp(tex2D(WaterMapSampler0, VsData.Tex), tex2D(WaterMapSampler1, VsData.Tex), WaterCycleTime);
    #endif

    #ifdef TANGENTSPACE_NORMALS
        TN.rbg = normalize(TN.rgb * 2.0 - 1.0);
    #else
        TN.rgb = TN.rgb * 2.0 - 1.0;
    #endif

    #ifdef USE_FRESNEL
        #ifdef FRESNEL_NORMALMAP
            vec4 TN2 = vec4(TN, 1);
        #else
            vec4 TN2 = vec2(0,1).xyxx;
        #endif
    #endif

    #ifdef PIXEL_CAMSPACE
        vec3 lookup = -(WorldSpaceCamPos - VsData.Position);
    #else
        vec3 lookup = VsData.Position;
    #endif

    vec3 reflection = reflect(lookup, TN);
    vec3 envcol = texCUBE(CubeMapSampler, reflection);

    #ifdef USE_SPECULAR
        scalar specular = saturate(dot(-Lights[0].dir, normalize(reflection)));
        specular = pow(specular, SpecularPower) * SpecularColor.a;
    #endif

    #ifdef USE_FRESNEL
        scalar fresnel = BASE_TRANSPARENCY - pow(dot(normalize(lookup), TN2), POW_TRANSPARENCY);
    #endif

    scalar shadFac = lightmap.g;
    #ifdef USE_SHADOWS
        shadFac *= getShadowFactor(ShadowMapSampler, VsData.TexShadow);
    #endif
    scalar lerpMod = -(1.0 - saturate(shadFac + SHADOW_FACTOR));


    #ifdef USE_SPECULAR
        finalColor.rgb = (specular * SpecularColor * shadFac) + lerp(_WaterColor, envcol, COLOR_ENVMAP_RATIO + lerpMod);
        // finalColor.rgb = (specular * SpecularColor * shadFac) + lerp(_WaterColor, envcol, saturate(lightmap.g * 0.5 + 0.1));
    #else
        finalColor.rgb = lerp(_WaterColor, envcol, COLOR_ENVMAP_RATIO + lerpMod);
    #endif

    #ifdef USE_FRESNEL
        finalColor.a =  lightmap.r * fresnel + _WaterColor.w; // - 0.15;//pow(lightmap.r, 1.0);// * 0.5;
    #else
        finalColor.a = lightmap.r + _WaterColor.w; // * 0.9; //fresnel * pow(lightmap.r, APOW);
    #endif

    return finalColor;
}

technique defaultShader
{
    pass P0
    {
        vertexshader	= compile vs_3_0 waterVertexShader();
        pixelshader		= compile ps_3_0 waterPixelShader();
        fogenable		= true;
        #ifdef ENABLE_WIREFRAME
            FillMode = WireFrame;
        #endif
        CullMode		= NONE;
        AlphaBlendEnable= true;
        AlphaTestEnable = true;
        alpharef = 1;
        // depthfunct = always;

        SrcBlend		= SRCALPHA;
        DestBlend		= INVSRCALPHA;
    }
}
