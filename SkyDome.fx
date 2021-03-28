#line 2 "SkyDome.fx"
#include "Shaders/Math.fx"

// UNIFORM INPUTS
float4x4 viewProjMatrix : WorldViewProjection;
float4 texOffset : TEXOFFSET;
float4 texOffset2 : TEXOFFSET2;

float4 flareParams : FLAREPARAMS;
float4 underwaterFog : FogColor;

float2 fadeOutDist : CLOUDSFADEOUTDIST;
float2 cloudLerpFactors : CLOUDLERPFACTORS;

texture texture0: TEXLAYER0;
texture texture1: TEXLAYER1;
texture texture2: TEXLAYER2;

sampler samplerClamp = sampler_state
{
    Texture = <texture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler samplerWrap1 = sampler_state
{
    Texture = <texture1>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = WRAP;
    AddressV = WRAP;
};

sampler samplerWrap2 = sampler_state
{
    Texture = <texture2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = WRAP;
    AddressV = WRAP;
};

struct appdata
{
    float4 Pos          : POSITION;
    float4 BlendIndices : BLENDINDICES;
    float2 TexCoord     : TEXCOORD0;
    float2 TexCoord1    : TEXCOORD1;
};

struct appdataNoClouds
{
    float4 Pos          : POSITION;
    float4 BlendIndices : BLENDINDICES;
    float2 TexCoord     : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 HPos    : POSITION;
    float2 Tex0    : TEXCOORD0;
    float2 Tex1    : TEXCOORD1;
    float4 FadeOut : COLOR0;
};

struct VS_OUTPUTNoClouds
{
    float4 HPos : POSITION;
    float2 Tex0 : TEXCOORD0;
};

struct VS_OUTPUTDualClouds
{
    float4 HPos    : POSITION;
    float2 Tex0    : TEXCOORD0;
    float2 Tex1    : TEXCOORD1;
    float2 Tex2    : TEXCOORD2;
    float4 FadeOut : COLOR0;
};

VS_OUTPUT vsSkyDome(appdata input)
{
    VS_OUTPUT Out;
    Out.HPos = mul1(input.Pos, viewProjMatrix);
    Out.Tex0 = input.TexCoord;
    Out.Tex1 = input.TexCoord1.xy + texOffset.xy;
    float dist = length(input.Pos.xyz);
    Out.FadeOut = 1.0 - saturate((dist - fadeOutDist.x) / fadeOutDist.y); // tl: TODO - optimize out division
    Out.FadeOut *= input.Pos.y > 0;
    return Out;
}

VS_OUTPUTNoClouds vsSkyDomeNoClouds(appdataNoClouds input)
{
    VS_OUTPUTNoClouds Out;
    Out.HPos = mul1(input.Pos, viewProjMatrix);
    Out.Tex0 = input.TexCoord;
    return Out;
}

VS_OUTPUTDualClouds vsSkyDomeDualClouds(appdata input)
{
    VS_OUTPUTDualClouds Out;
    Out.HPos = mul1(input.Pos, viewProjMatrix);
    Out.Tex0 = input.TexCoord;
    Out.Tex1 = input.TexCoord1.xy + texOffset.xy;
    Out.Tex2 = input.TexCoord1.xy + texOffset2.xy;
    float dist = length(input.Pos.xyz);
    Out.FadeOut = 1.0 - saturate((dist - fadeOutDist.x) / fadeOutDist.y); // tl: TODO - optimize out division
    Out.FadeOut *= input.Pos.y > 0;
    return Out;
}

float4 psSkyDome(VS_OUTPUT indata) : COLOR
{
    float4 sky = tex2D(samplerClamp, indata.Tex0);
    float4 cloud = tex2D(samplerWrap1, indata.Tex1) * indata.FadeOut;
    return float4(lerp(sky,cloud,cloud.a).rgb, 1);
}

float4 psSkyDomeUnderWater(VS_OUTPUT indata) : COLOR
{
    return underwaterFog;
}

float4 psSkyDomeNoClouds(VS_OUTPUT indata) : COLOR
{
    return tex2D(samplerClamp, indata.Tex0);
}

float4 psSkyDomeDualClouds(VS_OUTPUTDualClouds indata) : COLOR
{
    float4 sky = tex2D(samplerClamp, indata.Tex0);
    float4 cloud = tex2D(samplerWrap1, indata.Tex1);
    float4 cloud2 = tex2D(samplerWrap2, indata.Tex2);
    float4 tmp = cloud * cloudLerpFactors.x + cloud2 * cloudLerpFactors.y;
    tmp *=  indata.FadeOut;
    return lerp(sky, tmp, tmp.a);
}

VS_OUTPUTNoClouds vsSkyDomeSunFlare(appdataNoClouds input)
{
    VS_OUTPUTNoClouds Out;
    Out.HPos = mul1(input.Pos, viewProjMatrix);
    Out.Tex0 = input.TexCoord;
    return Out;
}

float4 psSkyDomeSunFlare(VS_OUTPUT indata) : COLOR
{
    float3 rgb = tex2D(samplerClamp, indata.Tex0).rgb * flareParams[0];
    return float4(rgb, 1.0);
}

float4 psSkyDomeFlareOcclude(VS_OUTPUT indata) : COLOR
{
    float4 p = tex2D(samplerClamp, indata.Tex0);
    return float4(0.0, 1.0, 0.0, p.a);
}


technique SkyDomeUnderWater
{
    pass sky
    {
        AlphaBlendEnable = FALSE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;

        VertexShader = compile vs_2_0 vsSkyDome();
        PixelShader = compile ps_2_0 psSkyDomeUnderWater();
    }
}

technique SkyDomeNV3x
{
    pass sky
    {
        AlphaBlendEnable = FALSE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;

        VertexShader = compile vs_2_0 vsSkyDome();
        PixelShader = compile ps_2_0 psSkyDome();
    }
}

technique SkyDomeNV3xNoClouds
{
    pass sky
    {
        AlphaBlendEnable = FALSE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;

        VertexShader = compile vs_2_0 vsSkyDomeNoClouds();
        PixelShader = compile ps_2_0 psSkyDomeNoClouds();
    }
}

technique SkyDomeNV3xDualClouds
{
    pass sky
    {
        AlphaBlendEnable = FALSE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;

        VertexShader = compile vs_2_0 vsSkyDomeDualClouds();
        PixelShader = compile ps_2_0 psSkyDomeDualClouds();
    }
}

technique SkyDomeSunFlare
{
    pass sky
    {
        Zenable = FALSE;
        ZWriteEnable = FALSE;
        ZFunc = ALWAYS;
        CullMode = NONE;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        FogEnable = FALSE;
        VertexShader = compile vs_2_0 vsSkyDomeSunFlare();
        PixelShader = compile ps_2_0 psSkyDomeSunFlare();
    }
}

technique SkyDomeFlareOccludeCheck
{
    pass sky
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = ALWAYS;
        CullMode = NONE;
        ColorWriteEnable = 0;

        AlphaBlendEnable = TRUE;

        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        AlphaTestEnable = TRUE;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsSkyDomeSunFlare();
        PixelShader = compile ps_2_0 psSkyDomeFlareOcclude();
    }
}

technique SkyDomeFlareOcclude
{
    pass sky
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESS;
        CullMode = NONE;
        ColorWriteEnable = 0;

        AlphaBlendEnable = TRUE;

        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        AlphaTestEnable = TRUE;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsSkyDomeSunFlare();
        PixelShader = compile ps_2_0 psSkyDomeFlareOcclude();
    }
}
