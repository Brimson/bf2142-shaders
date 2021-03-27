
texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
texture texture2 : TEXLAYER2;
texture texture3 : TEXLAYER3;
texture texture4 : TEXLAYER4;
texture texture5 : TEXLAYER5;
texture texture6 : TEXLAYER6;

float backbufferLerpbias : BACKBUFFERLERPBIAS;
float2 sampleoffset : SAMPLEOFFSET;
float2 fogStartAndEnd : FOGSTARTANDEND;
float3 fogColor : FOGCOLOR;
float glowStrength : GLOWSTRENGTH;
float3 contrastPolynom : CONTRASTPOLYNOM;

float4 colorTransformMat[3] : COLORTRANSFORMMATRIX;

sampler sampler0 = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler1 = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler2 = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler3 = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler4 = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler5 = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler6 = sampler_state { Texture = (texture6); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };

sampler sampler2wrap = sampler_state { Texture = (texture2); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; };

sampler sampler0bilin = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler1bilin = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler2bilin = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler3bilin = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler4bilin = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler5bilin = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler sampler0bilinwrap = sampler_state { Texture = (texture0); AddressU = WRAP; AddressV = WRAP; AddressW = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler1bilinwrap = sampler_state { Texture = (texture1); AddressU = WRAP; AddressV = WRAP; AddressW = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler2bilinwrap = sampler_state { Texture = (texture2); AddressU = WRAP; AddressV = WRAP; AddressW = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler3bilinwrap = sampler_state { Texture = (texture3); AddressU = WRAP; AddressV = WRAP; AddressW = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler4bilinwrap = sampler_state { Texture = (texture4); AddressU = WRAP; AddressV = WRAP; AddressW = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler5bilinwrap = sampler_state { Texture = (texture5); AddressU = WRAP; AddressV = WRAP; AddressW = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; };

float NPixels : NPIXLES = 1.0;
float2 ScreenSize : VIEWPORTSIZE = { 800, 600 };
float Glowness : GLOWNESS = 3.0;
float Cutoff : cutoff = 0.8;

struct APP2VS_Quad
{
    float2 Pos       : POSITION0;
    float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_Quad
{
    float4 Pos       : POSITION;
    float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_Quad2
{
    float4 Pos       : POSITION;
    float2 TexCoord0 : TEXCOORD0;
    float2 TexCoord1 : TEXCOORD1;
};

struct PS2FB_Combine
{
    float4 Col0 : COLOR0;
};

VS2PS_Quad vsDx9_OneTexcoord(APP2VS_Quad indata)
{
    VS2PS_Quad outdata;
    outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

VS2PS_Quad2 vsDx9_Tinnitus(APP2VS_Quad indata)
{
    VS2PS_Quad2 outdata;
    outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    outdata.TexCoord1 = float2(indata.TexCoord0.x - sampleoffset.x, indata.TexCoord0.y - sampleoffset.y);
    return outdata;
}

PS2FB_Combine psDx9_Tinnitus(VS2PS_Quad2 indata)
{
    PS2FB_Combine outdata;

    float4 sample0 = tex2D(sampler0bilin, indata.TexCoord1);
    float4 sample1 = tex2D(sampler1bilin, indata.TexCoord1);
    float4 sample2 = tex2D(sampler2bilin, indata.TexCoord1);
    float4 sample3 = tex2D(sampler3bilin, indata.TexCoord1);
    float4 backbuffer = tex2D(sampler4, indata.TexCoord0);

    float4 accum = sample0 * 0.5;
    accum += sample1 * 0.25;
    accum += sample2 * 0.125;
    accum += sample3 * 0.0675;
    accum = lerp(accum,backbuffer, backbufferLerpbias);

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


// PS2FB_Combine
float4 psDx9_Soften(VS2PS_Quad2 indata):COLOR
{

    float4 sample0 = tex2D(sampler0bilin, indata.TexCoord0);
    float4 backbuffer = tex2D(sampler4, indata.TexCoord0);

    float4 accum;
    accum = saturate(backbuffer + sample0 * glowStrength);
    return accum;;
}

struct VS2PS_ColorTransform
{
    float4 Pos                : POSITION;
    float2 TexCoord0          : TEXCOORD0;
    float3 ColorTransformRow0 : TEXCOORD1;
    float3 ColorTransformRow1 : TEXCOORD2;
    float3 ColorTransformRow2 : TEXCOORD3;
    float3 ContrastPolynom    : TEXCOORD4;
};

VS2PS_ColorTransform vsDx9_ColorTransform(VS2PS_ColorTransform indata)
{
    VS2PS_ColorTransform outdata;
    outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    outdata.ColorTransformRow0 = colorTransformMat[0];
    outdata.ColorTransformRow1 = colorTransformMat[1];
    outdata.ColorTransformRow2 = colorTransformMat[2];
    outdata.ContrastPolynom = contrastPolynom;
    return outdata;
}

float4 psDx9_ColorTransform14(VS2PS_ColorTransform indata):COLOR
{
    float4 backbuffer = tex2D(sampler0bilinwrap,indata.TexCoord0);
    float3 accum  = indata.ColorTransformRow0.xyz * backbuffer.r;
         accum += indata.ColorTransformRow1.xyz * backbuffer.g;
         accum += indata.ColorTransformRow2.xyz * backbuffer.b;
    float3 accum2 = accum * accum;
    accum  = indata.ContrastPolynom.r * accum;
    accum += indata.ContrastPolynom.g * accum2;
    accum += indata.ContrastPolynom.b;
    return float4(accum, backbuffer.a);
}

technique ColorTransform
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = FALSE;

        VertexShader = compile vs_2_0 vsDx9_ColorTransform();
        PixelShader = compile ps_2_0 psDx9_ColorTransform14();
    }
}

float time_0_X : FRACTIME;
float time_0_X_256 : FRACTIME256;
float sin_time_0_X : FRACSINE;

float interference : INTERFERENCE;
float distortionRoll : DISTORTIONROLL;
float distortionScale : DISTORTIONSCALE;
float distortionFreq : DISTORTIONFREQ;

float4 psDx9_CameraEffect(VS2PS_ColorTransform indata):COLOR
{
    float lerpFactor = tex2D(sampler1bilinwrap, indata.TexCoord0).r * 0.5;
    float2 temp = (indata.TexCoord0 -0.5);
    float2 fisheyeTexCoord = ((indata.TexCoord0) - (temp*temp*temp)*lerpFactor);
    float4 scanline = tex2D(sampler2wrap,float2(indata.TexCoord0.x,(indata.TexCoord0.y-time_0_X)));

    float4 backbuffer1 = tex2D(sampler0bilinwrap, float2(indata.TexCoord0.x + scanline.r * 0.03, indata.TexCoord0.y));
    float4 backbuffer = tex2D(sampler0bilinwrap, float2(fisheyeTexCoord.x + scanline.r * 0.03, fisheyeTexCoord.y));

    float3 accum  = indata.ColorTransformRow0.xyz * backbuffer.r;
         accum += indata.ColorTransformRow1.xyz * backbuffer.g;
         accum += indata.ColorTransformRow2.xyz * backbuffer.b;
    float3 accum2 = accum * accum;
    accum = indata.ContrastPolynom.r * accum + indata.ContrastPolynom.g * accum2 + indata.ContrastPolynom.b;
    return float4(accum, backbuffer.a);
}
technique CameraEffect
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = FALSE;

        VertexShader = compile vs_2_0 vsDx9_ColorTransform();
        PixelShader = compile ps_2_0 psDx9_CameraEffect();
    }
}

float4 psDx9_EMP20(VS2PS_Quad2 indata):COLOR
{
    float2 img = indata.TexCoord0;
    float4 offset = tex2D(sampler1, float2(0.0,frac(indata.TexCoord0.y*interference))) -0.5;
    img.x = frac(img.x + offset.r * distortionRoll);

    float4 noise1 = tex2D(sampler1, frac(indata.TexCoord0*distortionScale* time_0_X_256));
    float4 backbuffer = tex2D(sampler4bilinwrap, img);

    float3 accum  = colorTransformMat[0].xyz * backbuffer.r;
         accum += colorTransformMat[1].xyz * backbuffer.g;
         accum += colorTransformMat[2].xyz * backbuffer.b;

    noise1 -= 0.5;
    noise1 = max(0.0, noise1.r *2.0);
    accum -= noise1;
    accum.r += noise1 * 0.3;
    accum = contrastPolynom.r * accum + contrastPolynom.g * pow(accum, 2.0) + contrastPolynom.b;
    return float4(accum, backbuffer.a);
}

technique Soften
{
    pass opaque
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = FALSE;

        // TODO: Shouldn't use the Tinnitus vs. Could use a much simpler vs
        VertexShader = compile vs_2_0 vsDx9_Tinnitus();
        PixelShader = compile ps_2_0 psDx9_Soften();
    }
}

technique EMP
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = FALSE;

        // TODO: Shouldn't use the Tinnitus vs. Could use a much simpler vs
        VertexShader = compile vs_2_0 vsDx9_Tinnitus();
        PixelShader = compile ps_2_0 psDx9_EMP20();
    }
}

float4 psDx9_Contrast(VS2PS_Quad2 indata):COLOR
{
    float4 backbuffer = tex2D(sampler4, indata.TexCoord0);

    float sat = 0.0;
    float3 lumVec = float3(0.3086, 0.6094, 0.0820);
    float4x4 color =	{1.0,0.0,0.0,0.0,
                         0.0,1.0,0.0,0.0,
                         0.0,0.0,1.0,0.0,
                         0.0,0.0,0.0,1.0};

    float invSat = 1.0 - sat;

    float4x4 luminance2 =	{invSat*lumVec.r + sat, invSat*lumVec.g, invSat*lumVec.b, 0.0,
                             invSat*lumVec.r, invSat*lumVec.g + sat, invSat*lumVec.b, 0.0,
                             invSat*lumVec.r, invSat*lumVec.g, invSat*lumVec.b + sat, 0.0,
                             0.0,		 	  0.0,				0.0,				  1.0};

    float4 accum = mul(luminance2, backbuffer);
    accum -= 0.5;
    accum = backbuffer + accum;
    accum.r += 0.05;
    accum = saturate(accum);
    return accum;
}


technique Contrast
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = FALSE;

        // TODO: Shouldn't use the Tinnitus vs. Could use a much simpler vs
        VertexShader = compile vs_2_0 vsDx9_Tinnitus();
        PixelShader = compile ps_2_0 psDx9_Contrast();
    }
}

float4 psDx9_ThermopticCamouflage() :COLOR
{
    return 0.0;
}

technique ThermopticCamouflage
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_2_0 vsDx9_OneTexcoord();
        PixelShader = compile ps_2_0 psDx9_ThermopticCamouflage();
    }
}

float4 psDx9_Glow(VS2PS_Quad indata) : COLOR
{
    return tex2D(sampler0bilin, indata.TexCoord0);
}

float4 psDx9_GlowMaterial(VS2PS_Quad indata) : COLOR
{
    float4 diffuse =  tex2D(sampler0bilin, indata.TexCoord0);
    return glowStrength * float4(diffuse.rgb * (1.0 - diffuse.a), 1.0);
}

technique GlowMaterial
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
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

float4 psDx9_Fog(VS2PS_Quad indata) : COLOR
{
    float3 wPos = tex2D(sampler0, indata.TexCoord0);
    float uvCoord =  saturate((wPos.zzzz - fogStartAndEnd.r) / fogStartAndEnd.g);
    return saturate(float4(fogColor.rgb,uvCoord));
    return tex2D(sampler1, float2(uvCoord, 0.0)) * fogColor.rgbb;
}

technique Fog
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

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

// TVEffect specific...

VS2PS_Quad2 vs_TVEffect( APP2VS_Quad indata )
{
   VS2PS_Quad2 output;
   // RenderMonkeyHACK Clean up inaccuracies
   indata.Pos.xy = sign(indata.Pos.xy);
   output.Pos = float4(indata.Pos.xy, 0.0, 1.0);
   output.TexCoord0 = indata.Pos.xy;
   output.TexCoord1 = indata.TexCoord0;
   return output;
}

PS2FB_Combine ps_TVEffect(VS2PS_Quad2 indata)
{
   PS2FB_Combine outdata;

   float2 pos = indata.TexCoord0;
   float2 img = indata.TexCoord1;

   // Interference ... just a texture filled with rand()
   float rand = tex2D(sampler2bilinwrap, float2(1.5 * pos) + time_0_X_256) - 0.2;

   // Some signed noise for the distortion effect
   float noisy = tex2D(sampler1bilinwrap, 0.5 * float2(0.5 * pos.y, 0.1 * time_0_X)) - 0.5;

   // Repeat a 1 - x^2 (0 < x < 1) curve and roll it with sinus.
   float dst = frac(pos.y * distortionFreq + distortionRoll * sin_time_0_X);
   dst *= (1.0 - dst);
   // Make sure distortion is highest in the center of the image
   dst /= 1.0 + distortionScale * abs(pos.y);

   // ... and finally distort
   img.x += distortionScale * noisy * dst;
   float4 image = dot(float3(0.3, 0.59, 0.11), tex2D(sampler0bilin, img));

   // Combine frame, distorted image and interference
   outdata.Col0 = interference * rand + image * 0.75 + 0.25;

   return outdata;
}

technique TVEffect
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = FALSE;

        VertexShader = compile vs_2_0 vs_TVEffect();
        PixelShader = compile ps_2_0 ps_TVEffect();
    }
}
