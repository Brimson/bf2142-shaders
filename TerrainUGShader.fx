#line 2 "TerrainUGShader.fx"
#include "shaders/datatypes.fx"


mat4x4	mViewProj: matVIEWPROJ;
mat4x4	mLightVP : LIGHTVIEWPROJ;
vec4	vScaleTransXZ : SCALETRANSXZ;
vec4	vScaleTransY : SCALETRANSY;
vec4	vShadowTexCoordScaleAndOffset : SHADOWTEXCOORDSCALEANDOFFSET;
vec4	vViewportMap : VIEWPORTMAP;

texture	texture2 : TEXLAYER2;

sampler sampler2Point = sampler_state { Texture = (texture2); MinFilter = POINT; MagFilter = POINT; };

struct APP2VS_BM_Dx9
{
    vec4	Pos0 : POSITION0;
    vec4	Pos1 : POSITION1;
    vec4	MorphDelta : POSITION2;
    vec2	TexCoord0 : TEXCOORD0;
    vec3	Normal : NORMAL;
};

struct VS2PS_DynamicShadowmap
{
    vec4	Pos : POSITION;
    vec4	ShadowTex : TEXCOORD1;
};


vec4 psDynamicShadowmap(VS2PS_DynamicShadowmap indata) : COLOR
{
	vec2 texel = vec2(1.0/1024.0, 1.0/1024.0);
	vec4 samples;
	indata.ShadowTex.xy = clamp(indata.ShadowTex.xy, vViewportMap.xy, vViewportMap.zw);
	samples.x = tex2D(sampler2Point, indata.ShadowTex);
	samples.y = tex2D(sampler2Point, indata.ShadowTex + vec2(texel.x, 0));
	samples.z = tex2D(sampler2Point, indata.ShadowTex + vec2(0, texel.y));
	samples.w = tex2D(sampler2Point, indata.ShadowTex + texel);

	vec4 cmpbits = samples >= saturate(indata.ShadowTex.z);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));

	return  1-saturate(4-indata.ShadowTex.z)+avgShadowValue.x;
}

VS2PS_DynamicShadowmap vsDynamicShadowmap(APP2VS_BM_Dx9 indata)
{
	VS2PS_DynamicShadowmap outdata;
	
	vec4 wPos;
	wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
	wPos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;

 	outdata.Pos = mul(wPos, mViewProj);

	outdata.ShadowTex = mul(wPos, mLightVP);
	outdata.ShadowTex.z -= 0.007;

	return outdata;
}

technique Dx9Style_BM
{
	pass DynamicShadowmap	//p0
	{
		CullMode = CW;
		//ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
		
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;
		
 		AlphaBlendEnable = TRUE;
 		SrcBlend = DESTCOLOR;
 		DestBlend = ZERO;
 		
		VertexShader = compile vs_1_1 vsDynamicShadowmap();
		PixelShader = compile PS2_EXT psDynamicShadowmap();
	}
}

