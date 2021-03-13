#include "shaders/datatypes.fx"

texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
// texture texture2 : TEXLAYER2;
// texture texture3 : TEXLAYER3;

sampler sampler0point = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler1point = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
// sampler sampler2 = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
// sampler sampler3 = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler0bilin = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
// sampler sampler0aniso = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = ANISOTROPIC; MagFilter = ANISOTROPIC; MaxAnisotropy = 8; };

dword dwStencilRef : STENCILREF = 0;
dword dwStencilPass : STENCILPASS = 1; // KEEP

mat4x4 convertPosTo8BitMat : CONVERTPOSTO8BITMAT;

vec4 scaleDown2x2SampleOffsets[4] : SCALEDOWN2X2SAMPLEOFFSETS;
vec4 scaleDown4x4SampleOffsets[16] : SCALEDOWN4X4SAMPLEOFFSETS;
vec4 scaleDown4x4LinearSampleOffsets[4] : SCALEDOWN4X4LINEARSAMPLEOFFSETS;
vec4 gaussianBlur5x5CheapSampleOffsets[13] : GAUSSIANBLUR5X5CHEAPSAMPLEOFFSETS;
scalar gaussianBlur5x5CheapSampleWeights[13] : GAUSSIANBLUR5X5CHEAPSAMPLEWEIGHTS;
vec4 gaussianBlur15x15HorizontalSampleOffsets[15] : GAUSSIANBLUR15X15HORIZONTALSAMPLEOFFSETS;
scalar gaussianBlur15x15HorizontalSampleWeights[15] : GAUSSIANBLUR15X15HORIZONTALSAMPLEWEIGHTS;
vec4 gaussianBlur15x15VerticalSampleOffsets[15] : GAUSSIANBLUR15X15VERTICALSAMPLEOFFSETS;
scalar gaussianBlur15x15VerticalSampleWeights[15] : GAUSSIANBLUR15X15VERTICALSAMPLEWEIGHTS;
vec4 growablePoisson13SampleOffsets[12] : GROWABLEPOISSON13SAMPLEOFFSETS;

scalar glowHorizOffsets[5] : GLOWHORIZOFFSETS;
scalar glowHorizWeights[5] : GLOWHORIZWEIGHTS;
scalar glowVertOffsets[5] : GLOWVERTOFFSETS;
scalar glowVertWeights[5] : GLOWVERTWEIGHTS;

scalar bloomSize : BLOOMSIZE;
scalar bloomWeightScale : BLOOMWEIGHTSCALE;
scalar contrastAmount : CONTRAST;

vec2 camouflageOffset : CAMOUFLAGEOFFSET;

vec2 texelSize : TEXELSIZE;

struct APP2VS_blit
{
    vec2 Pos : POSITION0;
    vec2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_blit
{
    vec4 Pos : POSITION;
    vec2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_4TapFilter
{
    vec4 Pos : POSITION;
    vec2 FilterCoords[4] : TEXCOORD0;
};

VS2PS_blit vsDx9_blit(APP2VS_blit indata)
{
    VS2PS_blit outdata;
    outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

struct VS2PS_Down4x4Filter14
{
    vec4 Pos : POSITION;
    vec2 TexCoord0 : TEXCOORD0;
    vec2 TexCoord1 : TEXCOORD1;
    vec2 TexCoord2 : TEXCOORD2;
    vec2 TexCoord3 : TEXCOORD3;
};


struct VS2PS_5SampleFilter
{
    vec4 Pos : POSITION;
    vec2 TexCoord0 : TEXCOORD0;
    vec4 FilterCoords[2] : TEXCOORD1;
};

struct VS2PS_5SampleFilter14
{
    vec4 Pos : POSITION;
    vec2 FilterCoords[5] : TEXCOORD0;
};

struct VS2PS_12SampleFilter
{
    vec4 Pos : POSITION;
    vec2 TexCoord0 : TEXCOORD0;
    vec4 FilterCoords[6] : TEXCOORD1;
};



VS2PS_Down4x4Filter14 vsDx9_Down4x4Filter14(APP2VS_blit indata)
{
    VS2PS_Down4x4Filter14 outdata;
    outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0 + scaleDown4x4SampleOffsets[0];
    outdata.TexCoord1 = indata.TexCoord0 + scaleDown4x4SampleOffsets[4] * 2.0;
    outdata.TexCoord2 = indata.TexCoord0 + scaleDown4x4SampleOffsets[8] * 2.0;
    outdata.TexCoord3 = indata.TexCoord0 + scaleDown4x4SampleOffsets[12] * 2.0;
    return outdata;
}

VS2PS_blit vsDx9_blitMagnified(APP2VS_blit indata)
{
    VS2PS_blit outdata;
    outdata.Pos = vec4(indata.Pos.xy * 1.1, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

VS2PS_4TapFilter vsDx9_4TapFilter(APP2VS_blit indata, uniform vec4 offsets[4])
{
    VS2PS_4TapFilter outdata;
    outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);

    for (int i = 0; i < 4; ++i)
    {
        outdata.FilterCoords[i] = indata.TexCoord0 + offsets[i].xy;
    }

    return outdata;
}



VS2PS_5SampleFilter vsDx9_5SampleFilter(APP2VS_blit indata, uniform scalar offsets[5], uniform bool horizontal)
{
    VS2PS_5SampleFilter outdata;

    outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);


    if(horizontal)
    {
        outdata.TexCoord0 = indata.TexCoord0 + float2(offsets[4],0);
    }
    else
    {
        outdata.TexCoord0 = indata.TexCoord0 + float2(0,offsets[4]);
    }

    for(int i=0; i<2; ++i)
    {
        if(horizontal)
        {
            outdata.FilterCoords[i].xy = indata.TexCoord0.xy + float2(offsets[i*2],0);
            outdata.FilterCoords[i].zw = indata.TexCoord0.xy + float2(offsets[i*2+1],0);
        }
        else
        {
            outdata.FilterCoords[i].xy = indata.TexCoord0.xy + float2(0,offsets[i*2]);
            outdata.FilterCoords[i].zw = indata.TexCoord0.xy + float2(0,offsets[i*2+1]);
        }
    }

    return outdata;
}


VS2PS_12SampleFilter vsDx9_12SampleFilter(APP2VS_blit indata, uniform bool horizontal)
{


    VS2PS_12SampleFilter outdata;
    outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);
    float scale = bloomSize;
    outdata.TexCoord0 = indata.TexCoord0;

    for(int i=0; i<3; ++i)
    {
        if(horizontal)
        {
            outdata.FilterCoords[i].xy = indata.TexCoord0.xy + float2(0.01 * scale * (i+1),0);
            outdata.FilterCoords[i].zw = indata.TexCoord0.xy + float2(0.015 * scale * (i+1),0);
        }
        else
        {
            outdata.FilterCoords[i].xy = indata.TexCoord0.xy + float2(0,0.01 * scale * (i+1));
            outdata.FilterCoords[i].zw = indata.TexCoord0.xy + float2(0,0.015 * scale * (i+1));
        }
    }

    for(int j=3; j<6; ++j)
    {
        if(horizontal)
        {
            outdata.FilterCoords[j].xy = indata.TexCoord0.xy + float2(-0.01 * scale * (6 - j),0);
            outdata.FilterCoords[j].zw = indata.TexCoord0.xy + float2(-0.015 * scale * (6 - j),0);
        }
        else
        {
            outdata.FilterCoords[j].xy = indata.TexCoord0.xy + float2(0,-0.01 * scale * (6 - j));
            outdata.FilterCoords[j].zw = indata.TexCoord0.xy + float2(0,-0.015 * scale * (6 - j));
        }
    }


    return outdata;
}


VS2PS_5SampleFilter14 vsDx9_5SampleFilter14(APP2VS_blit indata, uniform scalar offsets[5], uniform bool horizontal)
{
    VS2PS_5SampleFilter14 outdata;
     outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);

    for(int i=0; i<5; ++i)
    {
        if(horizontal)
        {
            outdata.FilterCoords[i] = indata.TexCoord0 + float2(offsets[i],0);
        }
        else
        {
            outdata.FilterCoords[i] = indata.TexCoord0 + float2(0,offsets[i]);
        }
    }

    return outdata;
}




vec4 psDx9_FSBMPassThrough(VS2PS_blit indata) : COLOR
{
    return tex2D(sampler0point, indata.TexCoord0);
}

vec4 psDx9_FSBMPassThroughBilinear(VS2PS_blit indata) : COLOR
{
    return tex2D(sampler0bilin, indata.TexCoord0);
}

vec4 psDx9_FSBMPassThroughSaturateAlpha(VS2PS_blit indata) : COLOR
{
    vec4 color =  tex2D(sampler0point, indata.TexCoord0);
    color.a = 1.f;
    return color;
}


vec4 psDx9_FSBMCopyOtherRGBToAlpha(VS2PS_blit indata) : COLOR
{
    vec4 color = tex2D(sampler0point, indata.TexCoord0);

    vec3 avg = 1.0/3;

    color.a = dot(avg, color);

    return color;
}


vec4 psDx9_FSBMConvertPosTo8Bit(VS2PS_blit indata) : COLOR
{
    vec4 viewPos = tex2D(sampler0point, indata.TexCoord0);
    viewPos /= 50;
    viewPos = viewPos * 0.5 + 0.5;
    return viewPos;
}

vec4 psDx9_FSBMConvertNormalTo8Bit(VS2PS_blit indata) : COLOR
{
    return normalize(tex2D(sampler0point, indata.TexCoord0)) * 0.5 + 0.5;
    // return tex2D(sampler0point, indata.TexCoord0).a;
}

vec4 psDx9_FSBMConvertShadowMapFrontTo8Bit(VS2PS_blit indata) : COLOR
{
    vec4 depths = tex2D(sampler0point, indata.TexCoord0);
    return depths;
}

vec4 psDx9_FSBMConvertShadowMapBackTo8Bit(VS2PS_blit indata) : COLOR
{
    return -tex2D(sampler0point, indata.TexCoord0);
}

vec4 psDx9_FSBMScaleUp4x4LinearFilter(VS2PS_blit indata) : COLOR
{
    return tex2D(sampler0bilin, indata.TexCoord0);
}

vec4 psDx9_FSBMScaleDown2x2Filter(VS2PS_blit indata) : COLOR
{
    vec4 accum;
    accum  = tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[0]) * 0.25;
    accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[1]) * 0.25;
    accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[2]) * 0.25;
    accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[3]) * 0.25;
    return accum;
}

vec4 psDx9_FSBMScaleDown4x4Filter(VS2PS_blit indata) : COLOR
{
    vec4 accum = 0;

    for(int tap = 0; tap < 16; ++tap)
        accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown4x4SampleOffsets[tap]);

    return accum * 0.0625; // div 16
}

vec4 psDx9_FSBMScaleDown4x4Filter14(VS2PS_Down4x4Filter14 indata) : COLOR
{
    vec4 accum;
    accum  = tex2D(sampler0bilin, indata.TexCoord0) * 0.25;
    accum += tex2D(sampler0bilin, indata.TexCoord1) * 0.25;
    accum += tex2D(sampler0bilin, indata.TexCoord2) * 0.25;
    accum += tex2D(sampler0bilin, indata.TexCoord3) * 0.25;
    return accum;
}

vec4 psDx9_FSBMScaleDown4x4LinearFilter(VS2PS_blit indata) : COLOR
{
    vec4 accum;
    accum  = tex2D(sampler0bilin, indata.TexCoord0 + scaleDown4x4LinearSampleOffsets[0]) * 0.25;
    accum += tex2D(sampler0bilin, indata.TexCoord0 + scaleDown4x4LinearSampleOffsets[1]) * 0.25;
    accum += tex2D(sampler0bilin, indata.TexCoord0 + scaleDown4x4LinearSampleOffsets[2]) * 0.25;
    accum += tex2D(sampler0bilin, indata.TexCoord0 + scaleDown4x4LinearSampleOffsets[3]) * 0.25;
    return accum;
}

vec4 psDx9_FSBMGaussianBlur5x5CheapFilter(VS2PS_blit indata) : COLOR
{
    vec4 accum = 0;

    for(int tap = 0; tap < 13; ++tap)
        accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur5x5CheapSampleOffsets[tap]) * gaussianBlur5x5CheapSampleWeights[tap];

    return accum;
}

vec4 psDx9_FSBMGaussianBlur15x15HorizontalFilter(VS2PS_blit indata) : COLOR
{
    vec4 accum = 0;

    for(int tap = 0; tap < 15; ++tap)
        accum += tex2D(sampler0bilin, indata.TexCoord0 + gaussianBlur15x15HorizontalSampleOffsets[tap]) * gaussianBlur15x15HorizontalSampleWeights[tap];

    return accum;
}

vec4 psDx9_FSBMGaussianBlur15x15VerticalFilter(VS2PS_blit indata) : COLOR
{
    vec4 accum = 0;

    for(int tap = 0; tap < 15; ++tap)
        accum += tex2D(sampler0bilin, indata.TexCoord0 + gaussianBlur15x15VerticalSampleOffsets[tap]) * gaussianBlur15x15VerticalSampleWeights[tap];

    return accum;
}

vec4 psDx9_FSBMGaussianBlur15x15HorizontalFilter2(VS2PS_blit indata) : COLOR
{
    vec4 accum = 0;

    for(int tap = 0; tap < 15; ++tap)
        accum += tex2D(sampler0bilin, indata.TexCoord0 + 2*gaussianBlur15x15HorizontalSampleOffsets[tap]) * gaussianBlur15x15HorizontalSampleWeights[tap];

    return accum;
}

vec4 psDx9_FSBMGaussianBlur15x15VerticalFilter2(VS2PS_blit indata) : COLOR
{
    vec4 accum = 0;

    for(int tap = 0; tap < 15; ++tap)
        accum += tex2D(sampler0bilin, indata.TexCoord0 + 2*gaussianBlur15x15VerticalSampleOffsets[tap]) * gaussianBlur15x15VerticalSampleWeights[tap];

    return accum;
}

vec4 psDx9_FSBMGrowablePoisson13Filter(VS2PS_blit indata) : COLOR
{
    vec4 accum = 0;
    scalar samples = 1;

    accum = tex2D(sampler0point, indata.TexCoord0);
    for(int tap = 0; tap < 11; ++tap)
    {
//		vec4 v = tex2D(sampler0point, indata.TexCoord0 + growablePoisson13SampleOffsets[tap]*1);
        vec4 v = tex2D(sampler0point, indata.TexCoord0 + growablePoisson13SampleOffsets[tap] * 0.1 * accum.a);
        if(v.a > 0)
        {
            accum.rgb += v;
            samples += 1;
        }
    }

//return tex2D(sampler0point, indata.TexCoord0);
    return accum / samples;
}

vec4 psDx9_FSBMGrowablePoisson13AndDilationFilter(VS2PS_blit indata) : COLOR
{
    vec4 center = tex2D(sampler0point, indata.TexCoord0);

    vec4 accum = 0;
    if(center.a > 0)
    {
        accum.rgb = center;
        accum.a = 1.0;
    }

    for(int tap = 0; tap < 11; ++tap)
    {
        scalar scale = 3*(center.a);
        if(scale == 0)
            scale = 1.5;
        vec4 v = tex2D(sampler0point, indata.TexCoord0 + growablePoisson13SampleOffsets[tap]*scale);
        if(v.a > 0)
        {
            accum.rgb += v;
            accum.a += 1.0;
        }
    }

//	if(center.a == 0)
//	{
//		accum.gb = center.gb;
//		accum.r / accum.a;
//		return accum;
//	}
//	else
        return accum / accum.a;
}

vec4 psDx9_FSBMScaleUpBloomFilter(VS2PS_blit indata) : COLOR
{
    scalar offSet = 0.01;

    vec4 close = tex2D(sampler0point, indata.TexCoord0);
    /*
        close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x - offSet*4.5), indata.TexCoord0.y));
        close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x - offSet*3.5), indata.TexCoord0.y));
        close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x - offSet*2.5), indata.TexCoord0.y));
        close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x - offSet*1.5), indata.TexCoord0.y));
        close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x + offSet*1.5), indata.TexCoord0.y));
        close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x + offSet*2.5), indata.TexCoord0.y));
        close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x + offSet*3.5), indata.TexCoord0.y));
        close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x + offSet*4.5), indata.TexCoord0.y));

        close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*4.5));
        close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*3.5));
        close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*2.5));
        close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*1.5));
        close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*1.5));
        close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*2.5));
        close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*3.5));
        //close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*4.5));

        return close / 16;
    */
    return close;
}


vec4 psDx9_FSBMClear(VS2PS_blit indata) : COLOR
{
    return 0.0;
}

vec4 psDx9_FSBMExtractGlowFilter(VS2PS_blit indata) : COLOR
{
    vec4 color = tex2D(sampler0point, indata.TexCoord0);
    float glowStrength = abs(color.a - 1.0) * color.a;
    // float glowStrength = saturate((color.a - 0.9)*10.0);
    color.rgb *= glowStrength * 2.0;;
    // color.a = 1;

    return color;
}


vec4 psDx9_FSBMExtractCamouflage(VS2PS_blit indata) : COLOR
{
    vec4 color = tex2D(sampler0bilin, indata.TexCoord0);
    float temp = max(0.4, color.a) - 0.5; // saturate(color.a - 0.9); // *4.0; // 1.0 * color.a; / /clamp((color.a - 0.1)*20.0, 0.0, 1.0);
    color.a = temp * 2.0; // + temp * 2.0; // + 2.0 * temp;
    // color.rgb *= color.a;//glowStrength;
    // color.a = 1.0;

    return color;
}



vec4 psDx9_FSBMLargeBloomFilter(VS2PS_12SampleFilter indata, uniform bool horizontal) : COLOR
{
    float scale = bloomWeightScale;
    vec4 color = 1.0 * scale *tex2D(sampler0bilin, indata.TexCoord0);
    color += 0.45 * scale * tex2D(sampler0bilin, indata.FilterCoords[0].xy);
    color += 0.35 * scale *tex2D(sampler0bilin, indata.FilterCoords[0].zw);
    color += 0.30 * scale *tex2D(sampler0bilin, indata.FilterCoords[1].xy);
    color += 0.25 * scale *tex2D(sampler0bilin, indata.FilterCoords[1].zw);
    color += 0.20 * scale *tex2D(sampler0bilin, indata.FilterCoords[2].xy);
    color += 0.15 * scale *tex2D(sampler0bilin, indata.FilterCoords[2].zw);

    color += 0.15 * scale *tex2D(sampler0bilin, indata.FilterCoords[3].xy);
    color += 0.20 * scale *tex2D(sampler0bilin, indata.FilterCoords[3].zw);
    color += 0.25 * scale *tex2D(sampler0bilin, indata.FilterCoords[4].xy);
    color += 0.30 * scale *tex2D(sampler0bilin, indata.FilterCoords[4].zw);
    color += 0.35 * scale *tex2D(sampler0bilin, indata.FilterCoords[5].xy);
    color += 0.45 * scale *tex2D(sampler0bilin, indata.FilterCoords[5].zw);

    return color *0.9;
}


vec4 psDx9_FSBMGlowFilter(VS2PS_5SampleFilter indata, uniform scalar weights[5], uniform bool horizontal) : COLOR
{
    vec4 color = weights[0] * tex2D(sampler0bilin, indata.FilterCoords[0].xy);
    color += weights[1] * tex2D(sampler0bilin, indata.FilterCoords[0].zw);
    color += weights[2] * tex2D(sampler0bilin, indata.FilterCoords[1].xy);
    color += weights[3] * 0.5 * tex2D(sampler0bilin, indata.FilterCoords[1].zw);
    color += weights[4] * 0.5 * tex2D(sampler0bilin, indata.TexCoord0);

    // color += 0.125 * tex2D(sampler0bilin, indata.FilterCoords[0].zw + vec2(0.03, 0.0));
    // color += 0.125 * tex2D(sampler0bilin, indata.FilterCoords[0].zw + vec2(0.0,0.03));
    // color += 0.125 * tex2D(sampler0bilin, indata.FilterCoords[0].zw + vec2(0.05, 0.0));
    // color += 0.125 * tex2D(sampler0bilin, indata.FilterCoords[0].zw + vec2(0.0,0.05));

    return color; // * vec4(1.0,0.7,0.7,1.0);
}

vec4 psDx9_FSBMGlowFilter14(VS2PS_5SampleFilter14 indata, uniform scalar weights[5]) : COLOR
{
    vec4 color = weights[0] * tex2D(sampler0bilin, indata.FilterCoords[0].xy);
    color += weights[1] * tex2D(sampler0bilin, indata.FilterCoords[1].xy);
    color += weights[2] * tex2D(sampler0bilin, indata.FilterCoords[2].xy);
    color += weights[3] * tex2D(sampler0bilin, indata.FilterCoords[3].xy);
    color += weights[4] * tex2D(sampler0bilin, indata.FilterCoords[4].xy);

    return color;
}

vec4 psDx9_FSBMCamouflageBlur(VS2PS_blit indata) : COLOR
{
    vec4 src = tex2D(sampler0bilin, indata.TexCoord0);
    vec2 img = indata.TexCoord0;
    img += camouflageOffset;
    // img.x +=0.02;
    // img.y += 0.02;
    vec4 src1 = tex2D(sampler0bilin, img);


    float sat = 0.0;
    vec3 lumVec = vec3(0.3086, 0.6094, 0.0820);
    float4x4 color =	{1.0,0.0,0.0,0.0,
                         0.0,1.0,0.0,0.0,
                         0.0,0.0,1.0,0.0,
                         0.0,0.0,0.0,1.0};

    float invSat = 1.0 - sat;


    float4x4 luminance2 =	{invSat*lumVec.r + sat, invSat*lumVec.g, invSat*lumVec.b, 0.0,
                             invSat*lumVec.r, invSat*lumVec.g + sat, invSat*lumVec.b, 0.0,
                             invSat*lumVec.r, invSat*lumVec.g, invSat*lumVec.b + sat, 0.0,
                             0.0,		 	  0.0,				0.0,				  1.0};


    vec4 accum = mul(luminance2, src1);
    accum -= 0.5;
    accum = src1 + accum * 0.1;

    return vec4(accum.rgb, src.a);

    return src;
}

vec4 psDx9_FSBMContrast(VS2PS_blit indata) : COLOR
{
    vec4 src = tex2D(sampler0bilin, indata.TexCoord0);
    src = saturate(src * src *src);
    float sat = 0.0;
    vec3 lumVec = vec3(0.3086, 0.6094, 0.0820);
    float invSat = 1.0 - sat;

    float4x4 luminance2 =	{invSat*lumVec.r + sat, invSat*lumVec.g, invSat*lumVec.b, 0.0,
                             invSat*lumVec.r, invSat*lumVec.g + sat, invSat*lumVec.b, 0.0,
                             invSat*lumVec.r, invSat*lumVec.g, invSat*lumVec.b + sat, 0.0,
                             0.0,		 	  0.0,				0.0,				  1.0};


    vec4 accum = mul(luminance2, src);

    // accum -= 1.7;
    accum -= contrastAmount;
    return accum;

    // accum  = src +accum * contrastAmount;
    // return accum;
    // accum.rgb = accum.r;
    // return accum;
}


technique Blit
{
    pass FSBMPassThrough
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThrough();
    }

    pass FSBMBlend
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThrough();
    }

    pass FSBMConvertPosTo8Bit
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMConvertPosTo8Bit();
    }

    pass FSBMConvertNormalTo8Bit
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMConvertNormalTo8Bit();
    }

    pass FSBMConvertShadowMapFrontTo8Bit
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMConvertShadowMapFrontTo8Bit();
    }

    pass FSBMConvertShadowMapBackTo8Bit
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMConvertShadowMapBackTo8Bit();
    }

    pass FSBMScaleUp4x4LinearFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleUp4x4LinearFilter();
    }

    pass FSBMScaleDown2x2Filter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown2x2Filter();
    }

    pass FSBMScaleDown4x4Filter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown4x4Filter();
    }

    pass FSBMScaleDown4x4LinearFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown4x4LinearFilter();
    }

    pass FSBMGaussianBlur5x5CheapFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMGaussianBlur5x5CheapFilter();
    }

    pass FSBMGaussianBlur15x15HorizontalFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMGaussianBlur15x15HorizontalFilter();//psDx9_FSBMGaussianBlur15x15HorizontalFilter2();
    }

    pass FSBMGaussianBlur15x15VerticalFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMGaussianBlur15x15VerticalFilter();//psDx9_FSBMGaussianBlur15x15VerticalFilter2();
    }

    pass FSBMGrowablePoisson13Filter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMGrowablePoisson13Filter();
    }

    pass FSBMGrowablePoisson13AndDilationFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMGrowablePoisson13AndDilationFilter();
    }

    pass FSBMScaleUpBloomFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleUpBloomFilter();
    }

    pass FSBMPassThroughSaturateAlpha
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThroughSaturateAlpha();
    }

    pass FSBMCopyOtherRGBToAlpha
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        ColorWriteEnable = ALPHA;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMCopyOtherRGBToAlpha();

    }

    pass FSBMClear
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blitMagnified();
        PixelShader = compile ps_3_0 psDx9_FSBMClear();
    }

    pass FSBMClearAlpha
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        ColorWriteEnable = ALPHA;

        VertexShader = compile vs_3_0 vsDx9_blitMagnified();
        PixelShader = compile ps_3_0 psDx9_FSBMClear();
    }

    pass FSBMPassThroughBilinearAdditive
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThroughBilinear();
    }

    pass FSBMExtractGlowFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMExtractGlowFilter();
    }

    pass FSBMExtractCamouflage
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMExtractCamouflage();
    }

    pass FSBMScaleDown4x4LinearFilterHorizontal
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_4TapFilter(scaleDown4x4LinearSampleOffsets);
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown4x4LinearFilter();
    }

    pass FSBMScaleDown4x4LinearFilterVertical
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_4TapFilter(scaleDown4x4LinearSampleOffsets);
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown4x4LinearFilter();
    }

    pass FSBMGlowHorizontalFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_5SampleFilter(glowHorizOffsets, true);
        PixelShader = compile ps_3_0 psDx9_FSBMGlowFilter(glowHorizWeights,true);
    }

    pass FSBMGlowVerticalFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_5SampleFilter(glowVertOffsets, false);
        PixelShader = compile ps_3_0 psDx9_FSBMGlowFilter(glowVertWeights,false);
    }

    pass FSBMCamouflageBlurPassThrough
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;//ONE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMCamouflageBlur();
    }

    pass FSBMContrastFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMContrast();
    }

    pass FSBMGlowHorizontalFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_12SampleFilter(true);
        PixelShader = compile ps_3_0 psDx9_FSBMLargeBloomFilter(true);
    }

    pass FSBMGlowVerticalFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_12SampleFilter(false);
        PixelShader = compile ps_3_0 psDx9_FSBMLargeBloomFilter(false);
    }
}

technique Blit_3_0
{
    pass FSBMPassThrough
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThrough();
    }

    pass FSBMBlend
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThrough();
    }

    pass FSBMConvertPosTo8Bit
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMConvertPosTo8Bit();
    }

    pass FSBMConvertNormalTo8Bit
    {
        /*
            ZEnable = FALSE;
            AlphaBlendEnable = FALSE;
            VertexShader = compile vs_3_0 vsDx9_blit();
            PixelShader = compile ps_3_0 psDx9_FSBMConvertNormalTo8Bit();
        */
    }

    pass FSBMConvertShadowMapFrontTo8Bit
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMConvertShadowMapFrontTo8Bit();
    }

    pass FSBMConvertShadowMapBackTo8Bit
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMConvertShadowMapBackTo8Bit();
    }

    pass FSBMScaleUp4x4LinearFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleUp4x4LinearFilter();
    }

    pass FSBMScaleDown2x2Filter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown2x2Filter();
    }

    pass FSBMScaleDown4x4Filter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_Down4x4Filter14();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown4x4Filter14();

    }

    pass FSBMScaleDown4x4LinearFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown4x4LinearFilter();
    }

    pass FSBMGaussianBlur5x5CheapFilter
    {
        /*
            ZEnable = FALSE;
            AlphaBlendEnable = FALSE;
            VertexShader = compile vs_3_0 vsDx9_blit();
            PixelShader = compile ps_3_0 psDx9_FSBMGaussianBlur5x5CheapFilter();
        */
    }

    pass FSBMGaussianBlur15x15HorizontalFilter
    {
        /*
            ZEnable = FALSE;
            AlphaBlendEnable = FALSE;
            VertexShader = compile vs_3_0 vsDx9_blit();
            PixelShader = compile ps_3_0 psDx9_FSBMGaussianBlur15x15HorizontalFilter();//psDx9_FSBMGaussianBlur15x15HorizontalFilter2();
        */
    }

    pass FSBMGaussianBlur15x15VerticalFilter
    {
        /*
            ZEnable = FALSE;
            AlphaBlendEnable = FALSE;
            VertexShader = compile vs_3_0 vsDx9_blit();
            PixelShader = compile ps_3_0 psDx9_FSBMGaussianBlur15x15VerticalFilter();//psDx9_FSBMGaussianBlur15x15VerticalFilter2();
        */
    }

    pass FSBMGrowablePoisson13Filter
    {
        /*
            ZEnable = FALSE;
            AlphaBlendEnable = FALSE;
            VertexShader = compile vs_3_0 vsDx9_blit();
            PixelShader = compile ps_3_0 psDx9_FSBMGrowablePoisson13Filter();
        */
    }

    pass FSBMGrowablePoisson13AndDilationFilter
    {
        /*
            ZEnable = FALSE;
            AlphaBlendEnable = FALSE;
            VertexShader = compile vs_3_0 vsDx9_blit();
            PixelShader = compile ps_3_0 psDx9_FSBMGrowablePoisson13AndDilationFilter();
        */
    }

    pass FSBMScaleUpBloomFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleUpBloomFilter();
    }

    pass FSBMPassThroughSaturateAlpha
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThroughSaturateAlpha();
    }

    pass FSBMCopyOtherRGBToAlpha
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        ColorWriteEnable = ALPHA;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMCopyOtherRGBToAlpha();

    }

    pass FSBMClear
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blitMagnified();
        PixelShader = compile ps_3_0 psDx9_FSBMClear();
    }

    pass FSBMClearAlpha
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        ColorWriteEnable = ALPHA;

        VertexShader = compile vs_3_0 vsDx9_blitMagnified();
        PixelShader = compile ps_3_0 psDx9_FSBMClear();
    }

    pass FSBMPassThroughBilinearAdditive
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThroughBilinear();
    }

    pass FSBMExtractGlowFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMExtractGlowFilter();
    }

    pass FSBMExtractCamouflage
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMExtractCamouflage();
    }

    pass FSBMScaleDown4x4LinearFilterHorizontal
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_4TapFilter(scaleDown4x4LinearSampleOffsets);
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown4x4LinearFilter();
    }

    pass FSBMScaleDown4x4LinearFilterVertical
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_4TapFilter(scaleDown4x4LinearSampleOffsets);
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown4x4LinearFilter();
    }

    pass FSBMGlowHorizontalFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_5SampleFilter14(glowHorizOffsets, true);
        PixelShader = compile ps_3_0 psDx9_FSBMGlowFilter14(glowHorizWeights);
    }

    pass FSBMGlowVerticalFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_5SampleFilter14(glowVertOffsets, false);
        PixelShader = compile ps_3_0 psDx9_FSBMGlowFilter14(glowVertWeights);
    }

    pass FSBMCamouflageBlurPassThrough
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMCamouflageBlur();
    }

    pass FSBMContrastFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMContrast();
    }

    pass FSBMLargeBloomHorizontalFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_5SampleFilter14(glowHorizOffsets, true);
        PixelShader = compile ps_3_0 psDx9_FSBMGlowFilter14(glowHorizWeights);
    }

    pass FSBMLargeBloomVerticalFilter
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_5SampleFilter14(glowVertOffsets, false);
        PixelShader = compile ps_3_0 psDx9_FSBMGlowFilter14(glowVertWeights);
    }
}


vec4 psDx9_StencilGather(VS2PS_blit indata) : COLOR
{
    return dwStencilRef / 255.0;
}

vec4 psDx9_StencilMap(VS2PS_blit indata) : COLOR
{
    vec4 stencil = tex2D(sampler0point, indata.TexCoord0);
    return tex1D(sampler1point, stencil.x / 255.0);
}

technique StencilPasses
{
    pass StencilGather
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;

        StencilEnable = TRUE;
        StencilRef = (dwStencilRef);
        StencilFunc = EQUAL;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_StencilGather();
    }

    pass StencilMap
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_StencilMap();
    }
}

float4 psZero() : COLOR
{
    return 0;
}

technique ResetStencilCuller
{
    pass NV4X
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = ALWAYS;

        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        ColorWriteEnable = 0;
        ColorWriteEnable1 = 0;
        ColorWriteEnable2 = 0;
        ColorWriteEnable3 = 0;

        StencilEnable = TRUE;
        StencilRef = (dwStencilRef);
        StencilMask = 0xFF;
        StencilWriteMask = 0xFF;
        StencilFunc = EQUAL;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = (dwStencilPass);
        TwoSidedStencilMode = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psZero();
    }
}
