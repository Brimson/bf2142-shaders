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
float glowStrength : GLOWSTRENGTH;
vec3 contrastPolynom : CONTRASTPOLYNOM;
//float brighten : BRIGHTEN;

vec4 colorTransformMat[3] : COLORTRANSFORMMATRIX;

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

scalar NPixels : NPIXLES = 1.0;
vec2 ScreenSize : VIEWPORTSIZE = {800,600};
scalar Glowness : GLOWNESS = 3.0;
scalar Cutoff : cutoff = 0.8;


struct APP2VS_Quad
{
    vec2	Pos : POSITION0;
    vec2	TexCoord0 : TEXCOORD0;
};

struct VS2PS_Quad
{
    vec4	Pos 		: POSITION;
    vec2	TexCoord0	: TEXCOORD0;
};

struct VS2PS_Quad2
{
    vec4	Pos 		: POSITION;
    vec2	TexCoord0	: TEXCOORD0;
    vec2	TexCoord1	: TEXCOORD1;
};

struct PS2FB_Combine
{
    vec4	Col0 		: COLOR0;
};

VS2PS_Quad vsDx9_OneTexcoord(APP2VS_Quad indata)
{
	VS2PS_Quad outdata;	
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0;
	return outdata;
}

VS2PS_Quad2 vsDx9_Tinnitus(APP2VS_Quad indata)
{
	VS2PS_Quad2 outdata;	
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);
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
		
		VertexShader = compile vs_1_1 vsDx9_Tinnitus();
		//PixelShader = compile PS2_EXT psDx9_Tinnitus();
		PixelShader = compile ps_1_4 psDx9_Tinnitus();
	}
}


//PS2FB_Combine 
vec4 psDx9_Soften(VS2PS_Quad2 indata):COLOR
{
	
	vec4 sample0 = tex2D(sampler0bilin, indata.TexCoord0);
	//vec4 sample1 = tex2D(sampler1bilin, indata.TexCoord0);
	//vec4 sample2 = tex2D(sampler2bilin, indata.TexCoord0);
	//vec4 sample3 = tex2D(sampler3bilin, indata.TexCoord0);
	vec4 backbuffer = tex2D(sampler4, indata.TexCoord0);

	//vec4 accum = sample0;*0.25;// + sample1*0.3;
	//return sample0;
	
	
	
	vec4 accum;// = lerp(sample3, sample2, 0.5);
	//accum = lerp(accum, sample1, 0.5);
	//accum = lerp(accum, sample0, 0.5);
	
	
	//accum = accum + sample1*0.25;
	//accum = accum + sample2*0.25;
	//accum = accum + sample3*0.25;
	//accum = accum + (accum - sample1)*0.5;
	//accum = accum + (accum - sample2)*0.2;
	//accum = accum + (accum - sample3)*0.1;
	//accum = lerp(accum,backbuffer,0.7);
	//return accum *0.7;
	accum = saturate(backbuffer + sample0 * glowStrength); 
	//accum = lerp(backbuffer, sample0, 0.1);
	
	//return sample0;
	//return backbuffer;
	return accum;//outdata;
}

struct VS2PS_ColorTransform
{
    vec4	Pos 		: POSITION;
    vec2	TexCoord0	: TEXCOORD0;
    vec3	ColorTransformRow0	: TEXCOORD1;
    vec3	ColorTransformRow1	: TEXCOORD2;
    vec3	ColorTransformRow2	: TEXCOORD3;
    vec3	ContrastPolynom		: TEXCOORD4;
};


VS2PS_ColorTransform vsDx9_ColorTransform(VS2PS_ColorTransform indata)
{
	VS2PS_ColorTransform outdata;	
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0;
 	outdata.ColorTransformRow0 = colorTransformMat[0];
 	outdata.ColorTransformRow1 = colorTransformMat[1];
 	outdata.ColorTransformRow2 = colorTransformMat[2];
	outdata.ContrastPolynom = contrastPolynom;
	return outdata;
}

vec4 psDx9_ColorTransform14(VS2PS_ColorTransform indata):COLOR
{
	float4 backbuffer = tex2D(sampler0bilinwrap,indata.TexCoord0);
	vec3 accum = indata.ColorTransformRow0.xyz * backbuffer.r + indata.ColorTransformRow1.xyz * backbuffer.g + indata.ColorTransformRow2.xyz * backbuffer.b;
	vec3 accum2 = accum * accum;
	accum = indata.ContrastPolynom.r * accum + indata.ContrastPolynom.g * accum2 + indata.ContrastPolynom.b;
	return float4(accum, backbuffer.a);
}

technique ColorTransform
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		StencilEnable = FALSE;
		
		VertexShader = compile vs_1_1 vsDx9_ColorTransform();
		PixelShader = compile ps_1_4 psDx9_ColorTransform14();
		
	}
}


scalar time_0_X : FRACTIME;
scalar time_0_X_256 : FRACTIME256;
float sin_time_0_X : FRACSINE;

float interference : INTERFERENCE; // = 0.050000;
float distortionRoll : DISTORTIONROLL; // = 0.100000;
float distortionScale : DISTORTIONSCALE; // = 0.500000;
float distortionFreq : DISTORTIONFREQ; //= 0.500000;




vec4 psDx9_CameraEffect(VS2PS_ColorTransform indata):COLOR
{
	float lerpFactor = tex2D(sampler1bilinwrap, indata.TexCoord0).r*0.5;
	vec2 temp = (indata.TexCoord0 -0.5);
	vec2 fisheyeTexCoord = ((indata.TexCoord0) - (temp*temp*temp)*lerpFactor);
	float4 scanline = tex2D(sampler2wrap,vec2(indata.TexCoord0.x,(indata.TexCoord0.y-time_0_X)));
	
	float4 backbuffer1 = tex2D(sampler0bilinwrap, vec2(indata.TexCoord0.x+scanline.r*0.03, indata.TexCoord0.y));
	float4 backbuffer = tex2D(sampler0bilinwrap,vec2(fisheyeTexCoord.x+scanline.r*0.03, fisheyeTexCoord.y));
	
	vec3 accum = indata.ColorTransformRow0.xyz * backbuffer.r + indata.ColorTransformRow1.xyz * backbuffer.g + indata.ColorTransformRow2.xyz * backbuffer.b;
	vec3 accum2 = accum * accum;
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
		
		VertexShader = compile vs_1_1 vsDx9_ColorTransform();
		PixelShader = compile ps_2_0 psDx9_CameraEffect();	
	}
}

vec4 psDx9_EMP20(VS2PS_Quad2 indata):COLOR
{
	
	//float4 text = tex2D(sampler1bilin, indata.TexCoord0)
	float2 img = indata.TexCoord0;
	float4 offset = tex2D(sampler1, vec2(0.0,frac(indata.TexCoord0.y*interference))) -0.5;//*time_0_X_256;
	//img.y += time_0_X * interference;//frac(img.y + time_0_X);
	
	//img.x +=  sin((1-img.y)*distortionFreq) * time_0_X * distortionScale;//
	//img.x +=  sin((img.y));// * (-img.y);
	//img.y = frac(img.y + distortionRoll * time_0_X);
	img.x = frac(img.x + offset.r*distortionRoll); 
	//img.y = frac(img.y + offset.b);
	
	float4 noise1 = tex2D(sampler1, frac(indata.TexCoord0*distortionScale* time_0_X_256));// + time);
	
	float4 backbuffer = tex2D(sampler4bilinwrap, img);
	
	vec3 accum = colorTransformMat[0].xyz * backbuffer.r + colorTransformMat[1].xyz * backbuffer.g + colorTransformMat[2].xyz * backbuffer.b;
	//accum = max(accum, vec4(0.5,0.5,0.5,0.0));
	
	//accum = saturate(accum*1.2);
	noise1 -= 0.5;
	noise1 = max(0.0, noise1.r *2.0);
	accum -= noise1; 
	accum.r += noise1*0.3;
	//accum -= 0.5;
	//accum = max(accum, 0.0);
	//accum = abs(accum) *2.0;
	//noise1 = max(0.5, noise1.r);
	//accum.g *= noise1;
	//accum = lerp(accum, noise1, (1-noise1) * static_interference);
	
	accum = contrastPolynom.r * accum + contrastPolynom.g * pow(accum, 2) + contrastPolynom.b;// * pow(accum, 3) + brighten;
	
	return float4(accum, backbuffer.a);
	
}

technique Soften
{
	pass opaque
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		StencilEnable = FALSE;
		
		
		//TODO: Shouldn't use the Tinnitus vs. Could use a much simpler vs
		VertexShader = compile vs_1_1 vsDx9_Tinnitus();
		PixelShader = compile ps_1_4 psDx9_Soften();
	}
}


technique EMP
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		StencilEnable = FALSE;

		//TODO: Shouldn't use the Tinnitus vs. Could use a much simpler vs
		VertexShader = compile vs_1_1 vsDx9_Tinnitus();
		PixelShader = compile ps_2_0 psDx9_EMP20();	
	}
}



vec4 psDx9_Contrast(VS2PS_Quad2 indata):COLOR
{
	
	//vec4 sample0 = tex2D(sampler0bilin, indata.TexCoord0);
	float4 backbuffer = tex2D(sampler4, indata.TexCoord0);
	
	

	//vec4 accum = sample0;
	
	//accum = lerp(accum,backbuffer,0.7);

	float sat = 0.0;
	vec3 lumVec = vec3(0.3086, 0.6094, 0.0820);
	float4x4 color =	{1.0,0.0,0.0,0.0,
						 0.0,1.0,0.0,0.0,
						 0.0,0.0,1.0,0.0,
						 0.0,0.0,0.0,1.0};

	/*float4x4 luminance =	{0.3086,0.3086,0.3086,0.0,
							 0.6094,0.6094,0.6094,0.0,
							 0.0820,0.0820,0.0820,0.0,
							 0.0,	0.0,   0.0,   1.0};
	*/					 
	float invSat = 1.0 - sat;
	/*float4x4 luminance =	{invSat*lumVec.r + sat, invSat*lumVec.r, invSat*lumVec.r, 0.0,
							 invSat*lumVec.g, invSat*lumVec.g + sat, invSat*lumVec.g, 0.0,
							 invSat*lumVec.b + sat, invSat*lumVec.b, invSat*lumVec.b + sat, 0.0,
							 0.0,	0.0,   0.0,   1.0};
	*/
	
	float4x4 luminance2 =	{invSat*lumVec.r + sat, invSat*lumVec.g, invSat*lumVec.b, 0.0,
							 invSat*lumVec.r, invSat*lumVec.g + sat, invSat*lumVec.b, 0.0,
							 invSat*lumVec.r, invSat*lumVec.g, invSat*lumVec.b + sat, 0.0,
							 0.0,		 	  0.0,				0.0,				  1.0};
	
	//color = mul(luminance2, color);
	/*
	float roffset = 0.1;
	float goffset = 0.1;
	float boffset = 0.0;
	
	float4x4 offset =	{1.0,0.0,0.0,roffset,
						 0.0,1.0,0.0,goffset,
						 0.0,0.0,1.0,boffset,
						 0.0,0.0,0.0,1.0};
	*/
	//vec4 accum = mul(colorTransformMat,backbuffer);
	//backbuffer.a = 1.0;
	//accum = mul(offset, backbuffer);
	vec4 accum = mul(luminance2, backbuffer);
	accum -= 0.5;
	accum = backbuffer + accum;
	accum.r += 0.05;
	accum = saturate(accum);
	//vec4 accum = mul(offset, backbuffer);
	
	//return vec4(0.0,0.0,0.0,1.0);
	//return backbuffer;
	
	return accum;//outdata;
}


technique Contrast
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		StencilEnable = FALSE;
		
		
		//TODO: Shouldn't use the Tinnitus vs. Could use a much simpler vs
		VertexShader = compile vs_1_1 vsDx9_Tinnitus();
		PixelShader = compile ps_1_4 psDx9_Contrast();	
	}
}

vec4 psDx9_ThermopticCamouflage() :COLOR
{
	return vec4(0.0,0.0,0.0,0.0);
}

technique ThermopticCamouflage
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_OneTexcoord();
		PixelShader = compile ps_1_4 psDx9_ThermopticCamouflage();
		
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
	// temporary test, should be removed
	return glowStrength * /*diffuse + */vec4(diffuse.rgb*(1-diffuse.a),1);
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
	

		
		VertexShader = compile vs_1_1 vsDx9_OneTexcoord();
		PixelShader = compile ps_1_1 psDx9_GlowMaterial();
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
		
		
		VertexShader = compile vs_1_1 vsDx9_OneTexcoord();
		PixelShader = compile ps_1_1 psDx9_Glow();
	}
}

vec4 psDx9_Fog(VS2PS_Quad indata) : COLOR
{
	vec3 wPos = tex2D(sampler0, indata.TexCoord0);
	scalar uvCoord =  saturate((wPos.zzzz-fogStartAndEnd.r)/fogStartAndEnd.g);//fogColorAndViewDistance.a);
	return saturate(vec4(fogColor.rgb,uvCoord));
	//vec2 fogcoords = vec2(uvCoord, 0.0);
	return tex2D(sampler1, vec2(uvCoord, 0.0))*fogColor.rgbb;
}


technique Fog
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		//SrcBlend = SRCCOLOR;
		//DestBlend = ZERO;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		//StencilEnable = FALSE;
		
		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 0x00;
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_OneTexcoord();
		PixelShader = compile ps_2_0 psDx9_Fog();
	}
}

// TVEffect specific...

/*scalar time_0_X : FRACTIME;
scalar time_0_X_256 : FRACTIME256;
float sin_time_0_X : FRACSINE;

float interference : INTERFERENCE; // = 0.050000;
float distortionRoll : DISTORTIONROLL; // = 0.100000;
float distortionScale : DISTORTIONSCALE; // = 0.500000;
float distortionFreq : DISTORTIONFREQ; //= 0.500000;
*/
VS2PS_Quad2 vs_TVEffect( APP2VS_Quad indata )
{
   VS2PS_Quad2 output;

   // RenderMonkeyHACK Clean up inaccuracies
   indata.Pos.xy = sign(indata.Pos.xy);

   output.Pos = float4(indata.Pos.xy, 0, 1);
   output.TexCoord0 = indata.Pos.xy;
   output.TexCoord1 = indata.TexCoord0;

   return output;
}

PS2FB_Combine ps_TVEffect20(VS2PS_Quad2 indata) {

   PS2FB_Combine outdata;

   float2 pos = indata.TexCoord0;
   float2 img = indata.TexCoord1;

   // Interference ... just a texture filled with rand()
   float rand = tex2D(sampler2bilinwrap, float2(1.5 * pos) + time_0_X_256) - 0.2;

   // Some signed noise for the distortion effect
   float noisy = tex2D(sampler1bilinwrap, 0.5 * float2(0.5 * pos.y, 0.1 * time_0_X)) - 0.5;

   // Repeat a 1 - x^2 (0 < x < 1) curve and roll it with sinus.
   float dst = frac(pos.y * distortionFreq + distortionRoll * sin_time_0_X);
   dst *= (1 - dst);
   // Make sure distortion is highest in the center of the image
   dst /= 1 + distortionScale * abs(pos.y);

   // ... and finally distort
   img.x += distortionScale * noisy * dst;
   float4 image = /*float4(0.9, 1.1, 1.1, 0) * */dot(float3(0.3,0.59,0.11), tex2D(sampler0bilin, img));

   // Combine frame, distorted image and interference
   outdata.Col0 = interference * rand + image * 0.75 + 0.25;

   return outdata;
}

PS2FB_Combine ps_TVEffect14(VS2PS_Quad2 indata) {

   PS2FB_Combine outdata;

   float2 pos = indata.TexCoord0;
   float2 img = indata.TexCoord1;

   // Interference ... just a texture filled with rand()
   float rand = tex2D(sampler2bilinwrap, float2(1.5 * pos) + time_0_X_256) - 0.2;

   // Some signed noise for the distortion effect
   float noisy = tex2D(sampler1bilinwrap, 0.5 * float2(0.5 * pos.y, 0.1 * time_0_X)) - 0.5;
/*
   // Repeat a 1 - x^2 (0 < x < 1) curve and roll it with sinus.
   float dst = frac(pos.y * distortionFreq + distortionRoll * sin_time_0_X);
   dst *= (1 - dst);
   // Make sure distortion is highest in the center of the image
   dst /= 1 + distortionScale * abs(pos.y);

   // ... and finally distort
   img.x += distortionScale * noisy * dst;
*/   
   float4 image = dot(float3(0.3,0.59,0.11), tex2D(sampler0bilin, img));

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
		
		VertexShader = compile vs_1_1 vs_TVEffect();
#if PSVERSION >= 20
		PixelShader = compile ps_2_0 ps_TVEffect20();
#else		
		PixelShader = compile ps_1_4 ps_TVEffect14();
#endif		
	}
}
