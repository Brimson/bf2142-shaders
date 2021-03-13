//
// UGLY QUICK TAKE on 1_4 compatible staticmeshshader.
//
#include "shaders/RaCommon.fx"
#include "shaders/RaShaderSTMCommon.fx"

#define skyNormal vec3(0.78,0.52,0.65)
//#define STATICSUNCOLOR	 float3(0.62,0.60,0.51)
//#define STATICSKYCOLOR   float3(0.46,0.47,0.48)
#define SPECULARCOLOR 	float3(0.3,0.3,0.35)


// Stuff that should go into the general category
/*Light Lights[1];
// Texture indexes, should be based on actual mapping
#define TexLightMapInd		0
#define TexBaseInd		1
#define TexDetailInd	2
#define TexDirtInd		3
#define TexCrackInd		4

#define NUM_TEXSETS 5
#define NUM_LIGHTS 1


#define _LIGHTMAP_	1
#define _BASE_		1
#define  _DETAIL_	1
#define  _DIRT_		1
#define  _CRACK_		1
#define  _PARALLAXDETAIL_	1
#define  _NBASE_		1
#define  _NDETAIL_	1
#define  _NCRACK_	1
#define  _SHADOW_	1

#define	_DIRLIGHT_	1
#define _POINTLIGHT_	0

*/

#define  _PARALLAXDETAIL_ 	0
#define  _NBASE_		0
#define  _NDETAIL_		0
#define  _CRACK_		0
#define  _NCRACK_		0
#define  _SHADOW_		0

//#define  _POINTLIGHT_		0

#if ( _NBASE_||_NDETAIL_ || _NCRACK_ || _PARALLAXDETAIL_)
#define PPD
#endif

struct VS_IN
{
	vec4 Pos					: POSITION;
	vec3 Normal					: NORMAL;
#ifdef PPD
	vec3 Tan					: TANGENT;
#endif
	vec4 TexSets[NUM_TEXSETS]	: TEXCOORD0;
};


struct VS_OUT
{
	vec4 Pos					: POSITION0;
	vec4 InvDot					: COLOR0;
	scalar PointLightFog				: COLOR1;
	vec4 TanLightVec				: TEXCOORD0;
	vec3 TanEyeVec					: TEXCOORD1;	
	vec2 TexBase 					: TEXCOORD2;
	vec2 TexLMap	 				: TEXCOORD3;
	vec2 TexDetail					: TEXCOORD4;		
	vec2 TexDirt					: TEXCOORD5;

#if (_SHADOW_)
	vec4 TexShadow					: TEXCOORD6;
#endif
#if (_CRACK_)
	vec2 TexCrack					: TEXCOORD7;		
#endif
	scalar Fog					: FOG;
};

// common vars
Light		Lights[NUM_LIGHTS];

//
// common vertex shader methods
//
void 
calculateTangentVectors(vec3 Normal, vec3 Tan, vec3 objPos, vec3 objEyePos, out vec4 tanLVec, out vec3 tanEVec)
{
	// Cross product to create BiNormal
	vec3 binormal = normalize(cross(Tan, Normal));
	
	// calculate the objI
	mat3x3 TanBasis = mat3x3(Tan, binormal, Normal);
	mat3x3 objI = transpose(TanBasis);

	// Transform light dir to tan space
	//$TODO: dependant on lighttype
	// if pointlight/spot
#if _POINTLIGHT_
	tanLVec = float4(mul(Lights[0].pos.xyz - objPos, objI), Lights[0].attenuation);
#else
	// direction
	tanLVec = vec4(mul(-Lights[0].dir, objI), 1);
#endif
	
	// Transform eye pos to tangent space	
	vec3 objEyeVec = objEyePos - objPos;
	tanEVec = mul(objEyeVec, objI);
} 

void 
calculateNonTangentVectors(vec3 Normal, vec3 objPos, vec3 objEyePos, out vec4 tanLVec, out vec3 tanEVec)
{
	// Cross product to create BiNormal
	float3 Tan = float3(0,1,0);
	vec3 binormal = normalize(cross(Tan, Normal));
	
	// calculate the objI
	mat3x3 TanBasis = mat3x3(Tan, binormal, Normal);
	mat3x3 objI = transpose(TanBasis);

	// Transform light dir to tan space
	//$TODO: dependant on lighttype
	// if pointlight/spot
#if _POINTLIGHT_
	tanLVec = float4(mul(Lights[0].pos.xyz - objPos, objI), Lights[0].attenuation);
#else
	// direction
	//tanLVec = vec4(mul(-Lights[0].dir, objI), 1);
	tanLVec = vec4(Normal, saturate(dot(Normal, -Lights[0].dir)));
#endif
	
	// Transform eye pos to tangent space	
	vec3 objEyeVec = objEyePos - objPos;
	//tanEVec = mul(objEyeVec, objI);
	tanEVec = objEyeVec;
}


VS_OUT 
vsStaticMesh(VS_IN indata)
{
	VS_OUT Out = (VS_OUT)0;
 
 	// output pwosition early
 	Out.Pos	= mul(indata.Pos, mul(World, ViewProjection));
	Out.InvDot.x = 1-(saturate(dot(indata.Normal*0.2, -Lights[0].dir)));

#ifdef PPD
	calculateTangentVectors(indata.Normal, indata.Tan, indata.Pos, ObjectSpaceCamPos, Out.TanLightVec, Out.TanEyeVec);
#else
	calculateNonTangentVectors(indata.Normal, indata.Pos, ObjectSpaceCamPos, Out.TanLightVec, Out.TanEyeVec);
#endif
	Out.InvDot.y = Out.TanLightVec.a;
//#endif

#if	_LIGHTMAP_
	Out.TexLMap = indata.TexSets[TexLightMapInd].xy* LightMapOffset.xy + LightMapOffset.zw;
#endif

#if	_BASE_
	Out.TexBase = indata.TexSets[TexBaseInd].xy;
#endif

#if (_DETAIL_ || _NDETAIL_)
	Out.TexDetail = indata.TexSets[TexDetailInd].xy;
#endif

#if _DIRT_
	Out.TexDirt.xy = indata.TexSets[TexDirtInd].xy;
#endif

#if _CRACK_
	Out.TexCrack = indata.TexSets[TexCrackInd].xy;
#endif 

#if _SHADOW_
	vec4 TexShadow2 = mul(indata.Pos, ShadowProjMat);
	Out.TexShadow = mul(indata.Pos, ShadowTrapMat);
	Out.TexShadow.z = (TexShadow2.z/TexShadow2.w) * Out.TexShadow.w;
#endif
		
  	
#if _POINTLIGHT_
	Out.PointLightFog = calcFog(Out.Pos.w);
#else
	Out.Fog = calcFog(Out.Pos.w);
#endif

	return Out;
}


#if _PARALLAXDETAIL_
vec2 
calculateParallaxCoordinatesFromAlpha(vec2 inHeightTexCoords, sampler2D inHeightSampler, vec4 inScaleBias, vec3 inEyeVecNormalized)
{
	vec2 height = tex2D(inHeightSampler, inHeightTexCoords).aa;
	vec2 eyeVecN = inEyeVecNormalized.xy * vec2(1,-1);

	height = height * inScaleBias.xy + inScaleBias.wz;
	return inHeightTexCoords + height * eyeVecN.xy;
}
#endif


vec3
getCompositeDiffuse(VS_OUT indata, vec3 normTanEyeVec, out scalar alpha)
{
	vec3 totalDiffuse = 0;
	alpha = 1;

#if _BASE_
	vec4 base = tex2D(DiffuseMapSampler, indata.TexBase);
	alpha = base.a;
	totalDiffuse = base.rgb;
#endif


#if _PARALLAXDETAIL_
	vec4 detail = tex2D(DetailMapSampler, calculateParallaxCoordinatesFromAlpha(indata.TexDetail, DetailMapSampler, ParallaxScaleBias, normTanEyeVec));
#elif _DETAIL_
	vec4 detail = tex2D(DetailMapSampler, indata.TexDetail);
#endif

#if (_DETAIL_|| _PARALLAXDETAIL_)
	totalDiffuse.rgb *= detail.rgb;
	alpha *= detail.a;
#endif		


#if _DIRT_
	vec3 dirt = tex2D(DirtMapSampler, indata.TexDirt);
	totalDiffuse.rgb *= dirt;
#endif
		
#if _CRACK_
		crack = tex2D(CrackMapSampler, indata.TexCrack);
		totalDiffuse.rgb = lerp(totalDiffuse.rgb, crack.rgb, crack.a);
#endif
	
	return totalDiffuse;
}

// This also includes the composite gloss map
vec4 
getCompositeNormals(VS_OUT indata, vec3 normTanEyeVec)
{
	vec4 totalNormal = 0;
	
#if	_NBASE_
	totalNormal = tex2D(NormalMapSampler, indata.TexBase);
#endif

#if _PARALLAXDETAIL_
	totalNormal = tex2D(NormalMapSampler, calculateParallaxCoordinatesFromAlpha(indata.TexDetail, DetailMapSampler, ParallaxScaleBias, normTanEyeVec));
#elif _NDETAIL_
	totalNormal = tex2D(NormalMapSampler, indata.TexDetail);
#endif


#if _NCRACK_
	vec4 cracknormal = tex2D(CrackNormalMapSampler, indata.TexCrack);
	scalar crackmask = tex2D(CrackMapSampler, indata.TexCrack).a;
	totalNormal = lerp(totalNormal, cracknormal, crackmask);
#endif

	totalNormal.xyz = totalNormal.xyz * 2 - 1;

	return totalNormal;
}


vec4 
getLightmap(VS_OUT indata)
{
#if _LIGHTMAP_
	return  tex2D(LightMapSampler, indata.TexLMap);
#else
	return float4(1,1,1,1);
#endif
}


vec3 
getDiffusePixelLighting(vec4 lightmap, vec3 compNormals, vec3 normalizedLightVec, VS_OUT indata)
{
	vec3 diffuse = saturate(dot(compNormals, normalizedLightVec)) * StaticSunColor;
	vec3 bumpedSky = lightmap.b * dot(compNormals, skyNormal) * StaticSkyColor;
#if 	_LIGHTMAP_
	// we add ambient here as well to get correct ambient for surfaces parallel to the sun
	vec3 bumpedDiff = diffuse + bumpedSky*indata.InvDot.x;
	diffuse = lerp(bumpedSky * indata.InvDot.x, bumpedDiff, lightmap.g);
	diffuse += lightmap.r * SinglePointColor;
#else
	diffuse *= lightmap.g;
	diffuse += bumpedSky;
#endif

	return diffuse;
}

float 
getSpecularPixelLighting(vec4 lightmap, vec4 compNormals, vec3 normalizedLightVec, vec3 normalizedEyeVec)
{
#if	(_FORCE_1_4_SHADERS_)
	vec3 halfVec = (normalizedLightVec + normalizedEyeVec)/2;
#else
	vec3 halfVec = normalize(normalizedLightVec + normalizedEyeVec);
#endif
	half specular = pow(dot((compNormals.xyz), halfVec), 32) * compNormals.a;
	
	// mask
	specular *= lightmap.g;
		
	return specular;
}

vec3
getDiffusePointPixelLighting(VS_OUT indata, vec3 compNormal, vec3 normLightVec)
{
	vec3 pointDiff = saturate(dot(compNormal.xyz, normLightVec)) * Lights[0].color;
	scalar sat = 1.0 - saturate(dot(indata.TanLightVec.xyz, indata.TanLightVec.xyz) * indata.TanLightVec.w);
	return saturate(pointDiff * sat) * indata.PointLightFog;// * indata.Fog;
}

float4 
psStaticMesh(VS_OUT indata) : COLOR
{
#if _FINDSHADER_
	return float4(1,1,0.4,1);
#endif

#if (_POINTLIGHT_ )
	return 0;
#endif
	vec3 normEyeVec = indata.TanEyeVec;
#ifdef _USENORMALIZEDNORMALS		
	normalize(normEyeVec);
#endif
	scalar alpha;
	vec3 FinalColor =  getCompositeDiffuse(indata, normEyeVec, alpha);

	FinalColor *= 2;

#ifdef PPD
	vec4 compNormals = getCompositeNormals(indata, normEyeVec);
#else
	vec4 compNormals = float4(0,0,1,0);
#endif

	vec3 normLightVec = indata.TanLightVec.rgb;
#ifdef _USENORMALIZEDNORMALS	
	normalize(normLightVec);
#endif
		
#if _POINTLIGHT_
	vec3 diffuse = getDiffusePointPixelLighting(indata, compNormals, normLightVec);
	//scalar specular = getSpecularPointPixelLighting(indata, compNormals, normLightVec);
	FinalColor.rgb = (FinalColor.rgb * diffuse);// + (specular * SPECULARCOLOR);
#else
	// directional light + lightmap etc	
	vec4 lightmap = getLightmap(indata);
	
	#if _SHADOW_
		vec2 texel = vec2(1.0/1024.0, 1.0/1024.0);
		vec3 samples;

		samples.x = tex2Dproj(ShadowMapSampler, indata.TexShadow);
		samples.y = tex2Dproj(ShadowMapSampler, indata.TexShadow + vec4(texel.x, 0, 0, 0));
		samples.z = tex2Dproj(ShadowMapSampler, indata.TexShadow + vec4(0, texel.y, 0, 0));
	
		vec3 cmpbits = samples >= saturate(indata.TexShadow.z/indata.TexShadow.w);
		scalar dirShadow = dot(cmpbits, vec3(0.333, 0.333, 0.333));

		lightmap.g *= dirShadow;
	#else
		const scalar dirShadow = 1;
	#endif

	#ifdef PPD
		vec3 diffuse = getDiffusePixelLighting(lightmap, compNormals.rgb, normLightVec, indata);
	#else
		vec3 diffuse = indata.InvDot.y * StaticSunColor;
		vec3 bumpedSky = lightmap.b * skyNormal.z * StaticSkyColor;
		#if 	_LIGHTMAP_
			// we add ambient here as well to get correct ambient for surfaces parallel to the sun
			vec3 bumpedDiff = diffuse + bumpedSky*indata.InvDot.x;
			diffuse = lerp(bumpedSky * indata.InvDot.x, bumpedDiff, lightmap.g);
			diffuse += lightmap.r * SinglePointColor;
		#else
			diffuse *= lightmap.g;
			diffuse += bumpedSky;
		#endif
	#endif
		
		scalar specular = getSpecularPixelLighting(lightmap, compNormals, normLightVec, normEyeVec);
//return compNormals.rgbb;
		FinalColor.rgb = (FinalColor.rgb * diffuse) + (specular * SPECULARCOLOR);
#endif //#if _POINTLIGHT_
	return float4(FinalColor,alpha);	
};

technique defaultTechnique
{
	pass P0
	{
		vertexShader	= compile vs_1_1 vsStaticMesh();
		pixelShader	= compile ps_1_4 psStaticMesh();


#ifdef ENABLE_WIREFRAME
		FillMode		= WireFrame;
#endif

//
// $TODO: As it is now the alphablending/zwriting states are controlled by code
// this should be changed ASAP
//
#if _POINTLIGHT_
		//AlphaBlendEnable	= TRUE;
		//SrcBlend		= ONE;
		//DestBlend		= ONE;
		fogenable = false;
#else
		AlphaTestEnable = < AlphaTest >;
		AlphaBlendEnable= < AlphaBlendEnable >;
		fogenable = true;
#endif

		//AlphaRef		= < alphaRef >;
		//SrcBlend		= < srcBlend >;
		//DestBlend		= < destBlend >;

		AlphaRef = 127; // temporary hack by johan because "m_shaderSettings.m_alphaTestRef = 127" somehow doesn't work

		//fogenable = true;
	}
}
