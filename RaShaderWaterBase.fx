#include "shaders/datatypes.fx"
#include "shaders/raCommon.fx"

#define ASM14

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

vec4 LightMapOffset;

scalar WaterHeight;

Light Lights[1];

vec4	WorldSpaceCamPos;
vec4	WaterScroll;

scalar	WaterCycleTime;

vec4	SpecularColor;
scalar	SpecularPower;
vec4	WaterColor;
vec4	PointColor;

#ifdef DEBUG
#define _WaterColor vec4(1,0,0,1)
#else
#define _WaterColor WaterColor
#endif

texture	CubeMap;
sampler CubeMapSampler = sampler_state
{
    Texture = (CubeMap);
    MipFilter = LINEAR; //Rasterizing speedup
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
        MipFilter = LINEAR; //Rasterizing speedup
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
        MipFilter = LINEAR; //Rasterizing speedup
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
        MipFilter = LINEAR; //Rasterizing speedup
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
    vec4   Pos         : POSITION;
    scalar Fog         : FOG;
    #ifdef USE_3DTEXTURE
        vec3 Tex       : TEXCOORD0;
    #else
        #ifdef PS13
            vec2 Tex0  : TEXCOORD0;
            vec2 Tex1  : TEXCOORD3;
        #else
            vec2 Tex   : TEXCOORD0;
        #endif
    #endif
    #ifndef NO_LIGHTMAP
        vec2 lmtex     : TEXCOORD1;
    #endif
        vec3 Position  : TEXCOORD2;
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


VS_OUTPUT_WATER waterVertexShader(
    vec4 inPos : POSITION0,
    vec2 lmtex : TEXCOORD1
)
{
    VS_OUTPUT_WATER Out; // = (VS_OUTPUT_WATER)0;

    vec4 wPos = mul(inPos, World);
    Out.Pos = mul(wPos, ViewProjection);

    #ifdef PIXEL_CAMSPACE
        Out.Position = wPos;
    #else
        Out.Position = -(WorldSpaceCamPos - wPos) * 0.02;
    #endif

    #ifdef USE_3DTEXTURE
        vec3 tex;
        tex.xy = (wPos.xz / vec2(29.13, 31.81));//+ frameTime*1;
        tex.xy += (WaterScroll.xy * WaterCycleTime);
        tex.z = WaterCycleTime*10 + (tex.x*0.7 + tex.y*1.13); //(inPos.x + inPos.y) / 100;
    #else
        vec2 tex;
        tex.xy = (wPos.xz / vec2(99.13, 71.81));//+ frameTime*1;
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

#define INV_LIGHTDIR vec3(0.4,0.5,0.6)

vec4 Water(in VS_OUTPUT_WATER VsData) : COLOR
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
        #ifdef PS13
            vec3 TN = tex2D(WaterMapSampler0, VsData.Tex0);//, tex2D(WaterMapSampler1, VsData.Tex1), WaterCycleTime);
        #else
            vec3 TN = lerp(tex2D(WaterMapSampler0, VsData.Tex), tex2D(WaterMapSampler1, VsData.Tex), WaterCycleTime);
        #endif
    #endif

    #ifdef TANGENTSPACE_NORMALS
        TN.rbg = normalize((TN.rgb * 2) - 1);
    #else
        TN.rgb = (TN.rgb * 2)-1;
    #endif

    #ifdef USE_FRESNEL
        #ifdef FRESNEL_NORMALMAP
            vec4 TN2 = vec4(TN, 1);
        #else
            vec4 TN2 = vec4(0,1,0,0);
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
        scalar lerpMod = -(1 - saturate(shadFac+SHADOW_FACTOR));


    #ifdef USE_SPECULAR
        finalColor.rgb = (specular * SpecularColor * shadFac) + lerp(_WaterColor, envcol, COLOR_ENVMAP_RATIO + lerpMod);
    #else
        finalColor.rgb = lerp(_WaterColor, envcol, COLOR_ENVMAP_RATIO + lerpMod);
    #endif

    #ifdef USE_FRESNEL
        finalColor.a =  lightmap.r * fresnel + _WaterColor.w;
    #else
        finalColor.a = lightmap.r + _WaterColor.w;
    #endif

    return finalColor;
}

#ifndef ASM14
    vec4 Water14(in VS_OUTPUT_WATER VsData) : COLOR
    {
        vec4 finalColor;

        #ifdef NO_LIGHTMAP // F85BD0
            vec4 lightmap = PointColor; //vec4(1, StaticGloss, 0.8, 1);
        #else
            vec4 lightmap = tex2D(LightMapSampler, VsData.lmtex);
        #endif

        vec4 t0 = tex2D(WaterMapSampler0, VsData.Tex);
        vec4 t1 = tex2D(WaterMapSampler1, VsData.Tex);
        vec4 TN = lerp(t0, t1, WaterCycleTime);

        TN.rgb = (TN.rgb * 2)-1;

        vec3 reflection = reflect(VsData.Position, TN);
        vec3 envcol = texCUBE(CubeMapSampler, reflection);

        return float4(envcol, 1);

        scalar shadFac = lightmap.g;//
        scalar lerpMod = -(1 - saturate(shadFac+SHADOW_FACTOR));

        finalColor.rgb = lerp(WaterColor, envcol, COLOR_ENVMAP_RATIO + lerpMod);

        float a = 2;

        finalColor.a = lightmap.r * a;

        return finalColor;
    }
#endif

technique defaultShader
{
    pass P0
    {
        vertexshader = compile vs_1_1 waterVertexShader();
        #ifdef PS_20
            pixelshader = compile PSMODEL Water();
        #else
            #ifdef ASM14
                Sampler[0] = (WaterMapSampler0);
                Sampler[1] = (WaterMapSampler1);
                Sampler[2] = (CubeMapSampler);
                Sampler[3] = (LightMapSampler);
                PixelShaderConstantF[0] = (WaterCycleTime);
                PixelShaderConstantF[1] = (WaterColor);
                PixelShaderConstantF[2] = (WaterScroll);
                PixelShaderConstantF[3] = (PointColor);

                PixelShader = asm
                {
                    ps_1_4

                    texld r0, t0
                    texld r1, t0
                    texcrd r2.xyz, t2

                    lrp r3.rgb, c0.x, r1, r0 // r3 = lerp() between the 2 water normal maps
                    dp3 r1.w, r2, r3_bx2
                    mad r0.xyz, r3_bx2, -r1_x2.w, r2

                    phase

                    texld r2, r0

                    #ifdef NO_LIGHTMAP // F85BD0
                        mov	r3,c3
                    #else
                        texld r3, t1
                    #endif

                    add_d2	r1.g, r3.g, c2.z
                    lrp	r0.rgb, r1.g, r2, c1
                    +add r0.w, r3.r, c1.w
                };
            #else
                pixelshader = compile ps_1_4 Water14();
            #endif
        #endif

        fogenable		= true;
        #ifdef ENABLE_WIREFRAME
            FillMode     = WireFrame;
        #endif
        CullMode         = NONE;
        AlphaBlendEnable = true;
        AlphaTestEnable  = true;
        alpharef = 1;

        SrcBlend		= SRCALPHA;
        DestBlend		= INVSRCALPHA;
    }
}
