#include "shaders/datatypes.fx"

texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
texture texture2 : TEXLAYER2;
texture texture3 : TEXLAYER3;
texture texture4 : TEXLAYER4;
texture texture5 : TEXLAYER5;
texture texture6 : TEXLAYER6;

scalar backbufferLerpbias : BACKBUFFERLERPBIAS;
vec2 sampleoffset : SAMPLEOFFSET;
vec2 fogStartAndEnd : FOGSTARTANDEND;
vec3 fogColor : FOGCOLOR;

sampler sampler0 = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler1 = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler2 = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler3 = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler4 = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler5 = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler6 = sampler_state { Texture = (texture6); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };

sampler sampler0bilin = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler1bilin = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler2bilin = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler3bilin = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler4bilin = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler5bilin = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

scalar NPixels : NPIXLES = 1.0;
vec2 ScreenSize : VIEWPORTSIZE = {800,600};
scalar Glowness : GLOWNESS = 3.0;
scalar Cutoff : cutoff = 0.8;


struct APP2VS_Quad
{
    vec2 Pos : POSITION0;
    vec2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_Quad
{
    vec4 Pos : POSITION;
    vec2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_Quad2
{
    vec4 Pos : POSITION;
    vec2 TexCoord0 : TEXCOORD0;
    vec2 TexCoord1 : TEXCOORD1;
};

struct PS2FB_Combine
{
    vec4 Col0 : COLOR0;
};

VS2PS_Quad vsDx9_OneTexcoord(APP2VS_Quad indata)
{
    VS2PS_Quad outdata;
    outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

VS2PS_Quad2 vsDx9_Tinnitus(APP2VS_Quad indata)
{
    VS2PS_Quad2 outdata;
    outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    outdata.TexCoord1 = vec2(indata.TexCoord0.x - sampleoffset.x, indata.TexCoord0.y - sampleoffset.y);
    return outdata;
}

PS2FB_Combine psDx9_Tinnitus(VS2PS_Quad2 indata)
{
    PS2FB_Combine outdata;

    vec4 sample0 = tex2D(sampler0bilin, indata.TexCoord1);
    vec4 sample1 = tex2D(sampler1bilin, indata.TexCoord1);
    vec4 sample2 = tex2D(sampler2bilin, indata.TexCoord1);
    vec4 sample3 = tex2D(sampler3bilin, indata.TexCoord1);
    vec4 backbuffer = tex2D(sampler4, indata.TexCoord0);

    vec4 accum = sample0 * 0.5;
    accum += sample1 * 0.25;
    accum += sample2 * 0.125;
    accum += sample3 * 0.0675;

    accum = lerp(accum,backbuffer,backbufferLerpbias);
    //accum.r += (0.25*(1-backbufferLerpbias));

    outdata.Col0 = accum;

    return outdata;
}

technique Tinnitus
{
    pass opaque
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_2_0 vsDx9_Tinnitus();
        PixelShader = compile ps_2_0 psDx9_Tinnitus();
    }
}

vec4 psDx9_Glow(VS2PS_Quad indata) : COLOR
{
    return tex2D(sampler0bilin, indata.TexCoord0);
}

vec4 psDx9_GlowMaterial(VS2PS_Quad indata) : COLOR
{
    vec4 diffuse =  tex2D(sampler0bilin, indata.TexCoord0);
    //return (1-diffuse.a);
    return vec4(diffuse.rgb*(1-diffuse.a),1);
}

technique GlowMaterial
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCCOLOR;
        DestBlend = ONE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 0x80;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_0 vsDx9_OneTexcoord();
        PixelShader = compile ps_2_0 psDx9_GlowMaterial();
    }
}




technique Glow
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCCOLOR;
        DestBlend = ONE;

        VertexShader = compile vs_2_0 vsDx9_OneTexcoord();
        PixelShader = compile ps_2_0 psDx9_Glow();
    }
}

vec4 psDx9_Fog(VS2PS_Quad indata) : COLOR
{
    vec3 wPos = tex2D(sampler0, indata.TexCoord0);
    scalar uvCoord =  saturate((wPos.zzzz-fogStartAndEnd.r)/fogStartAndEnd.g);//fogColorAndViewDistance.a);
    return saturate(vec4(fogColor.rgb,uvCoord));
    // vec2 fogcoords = vec2(uvCoord, 0.0);
    return tex2D(sampler1, vec2(uvCoord, 0.0)) * fogColor.rgbb;
}


technique Fog
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        // SrcBlend = SRCCOLOR;
        // DestBlend = ZERO;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        // StencilEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 0x00;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_0 vsDx9_OneTexcoord();
        PixelShader = compile ps_2_0 psDx9_Fog();
    }
}
