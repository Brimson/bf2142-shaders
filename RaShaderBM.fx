
#include "shaders/RaCommon.fx"
#include "shaders/RaDefines.fx"
#include "shaders/RaShaderBMCommon.fx"

// Dependencies and sanity checks
//Tmp
#ifndef _HASUVANIMATION_
#define _HASUVANIMATION_ 0
#endif
#ifndef _HASNORMALMAP_
#define _HASNORMALMAP_ 0
#endif
#ifndef _HASGIMAP_
#define _HASGIMAP_ 0
#endif
#ifndef _HASENVMAP_
#define _HASENVMAP_ 0
#endif
#if _HASENVMAP_
	#define _FRESNELVALUES_ 1
#else
	#define _FRESNELVALUES_ 0
#endif
#ifndef _USEHEMIMAP_
#define _USEHEMIMAP_ 0
#endif
#ifndef _HASSHADOW_
#define _HASSHADOW_ 0
#endif
#ifndef _HASCOLORMAPGLOSS_
#define _HASCOLORMAPGLOSS_ 0
#endif
#ifndef _HASDOT3ALPHATEST_
#define _HASDOT3ALPHATEST_ 0
#endif

//resolve illegal combo GI + ENVMAP
#if _HASGIMAP_ && _HASENVMAP_
 # define _HASENVMAP_ 0
#endif

// Lighting stuff
// tl: turn this off for lower rapath settings
#if RAPATH >= 2
	#define _USEPERPIXELNORMALIZE_ 0
	#define _USERENORMALIZEDTEXTURES_ 0
#else
	#define _USEPERPIXELNORMALIZE_ 1
	#define _USERENORMALIZEDTEXTURES_ 1
#endif

#if _HASNORMALMAP_ || _HASCOLORMAPGLOSS_
	// Need to do perpixel light for bumped material
	// and it's reasonable to have it for per-pixel glossing as well
	#define _HASPERPIXELLIGHTING_ 1
#else
	#define _HASPERPIXELLIGHTING_ 0
#endif

#if _POINTLIGHT_
	// Disable these code portions for point lights
	#define _HASGIMAP_ 0
	#define _HASENVMAP_ 0
	#define _USEHEMIMAP_ 0
	#define _HASSHADOW_ 0
	// Do per-pixel, and do not per-vertex normalize
	#define _HASPERPIXELLIGHTING_ 1
	#define _USEPERPIXELNORMALIZE_ 1
	#define _USERENORMALIZEDTEXTURES_ 0
	// We'd still like fresnel, though
	#define _FRESNELVALUES_ 1
#endif

//tl: We now allocate color interpolators for vertex lighting to avoid redundant texture ops

// Setup interpolater mappings
#if _USEHEMIMAP_
	#define __HEMINTERPIDX 0
#endif
#if _HASSHADOW_
	#define __SHADOWINTERPIDX _USEHEMIMAP_
#endif
#if _FRESNELVALUES_
	#define __ENVMAPINTERPIDX _USEHEMIMAP_+_HASSHADOW_
#endif
#if _HASPERPIXELLIGHTING_
	#define __LVECINTERPIDX _USEHEMIMAP_+_HASSHADOW_+_FRESNELVALUES_
	#define __HVECINTERPIDX _USEHEMIMAP_+_HASSHADOW_+_FRESNELVALUES_+1
	#if !_HASNORMALMAP_
		#define __WNORMALINTERPIDX _USEHEMIMAP_+_HASSHADOW_+_FRESNELVALUES_+2
	#endif
#else
//	#define __DIFFUSEINTERPIDX _USEHEMIMAP_+_HASSHADOW_+_FRESNELVALUES_
//	#define __SPECULARINTERPIDX _USEHEMIMAP_+_HASSHADOW_+_FRESNELVALUES_+1
#endif
#if _HASSHADOWOCCLUSION_
	#define __OCCSHADOWINTERPIDX _USEHEMIMAP_+_HASSHADOW_+_FRESNELVALUES_+(2*_HASPERPIXELLIGHTING_)+(_HASPERPIXELLIGHTING_&&!_HASNORMALMAP_)
#endif

//#define MAX_INTERPS (_USEHEMIMAP_+_HASSHADOW_+_FRESNELVALUES_+2 + (_HASPERPIXELLIGHTING_&&!_HASNORMALMAP_) )
#define MAX_INTERPS (_USEHEMIMAP_+_HASSHADOW_+_FRESNELVALUES_+ (2*_HASPERPIXELLIGHTING_) + (_HASPERPIXELLIGHTING_&&!_HASNORMALMAP_) + _HASSHADOWOCCLUSION_)

// Rod's magic numbers ;-)
#define refractionIndexRatio 	0.15
#define R0	(pow(1.0 - refractionIndexRatio, 2.0) / pow(1.0 + refractionIndexRatio, 4.0))


struct BMVariableVSInput
{
   	vec4	Pos				: POSITION;    
	vec3	Normal			: NORMAL;
	vec4  	BlendIndices	: BLENDINDICES;  
	vec2	TexDiffuse		: TEXCOORD0;
	vec2	TexUVRotCenter	: TEXCOORD1;
	vec3 	Tan				: TANGENT;
};

struct BMVariableVSOutput
{
	vec4	HPos						: POSITION;
#if _POINTLIGHT_ || !_HASPERPIXELLIGHTING_
	vec4	SpecularLightOrPointFog	: COLOR1;
#endif
#if !_HASPERPIXELLIGHTING_
	vec4	DiffuseLight				: COLOR0;
#endif
	vec2	TexDiffuse			: TEXCOORD0;
#if MAX_INTERPS
	vec4	Interpolated[MAX_INTERPS]			: TEXCOORD1;
#endif
	float	Fog						: FOG;
};

mat4x3 getSkinnedWorldMatrix(BMVariableVSInput input)
{
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;
	return GeomBones[IndexArray[0]];
}

mat3x3 getSkinnedUVMatrix(BMVariableVSInput input)
{
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;
	return (mat3x3)UserData.uvMatrix[IndexArray[3]];
}

float getBinormalFlipping(BMVariableVSInput input)
{
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;
	return 1.f + IndexArray[2] * -2.f;
}

vec4 getWorldPos(BMVariableVSInput input)
{
	vec4 unpackedPos = input.Pos * PosUnpack;
	return vec4(mul(unpackedPos, getSkinnedWorldMatrix(input)), 1);
}


vec3 getWorldNormal(BMVariableVSInput input)
{
	vec3 unpackedNormal = input.Normal * NormalUnpack.x + NormalUnpack.y;
	return mul(unpackedNormal, getSkinnedWorldMatrix(input)); //tl: We don't scale/shear objects
}

vec4 calcGroundUVAndLerp(BMVariableVSInput input)
{
	// HemiMapConstants: offset x/y heightmapsize z / hemilerpbias w

	vec4 GroundUVAndLerp = 0;
	GroundUVAndLerp.xy	= ((getWorldPos(input) + (HemiMapConstants.z/2) + getWorldNormal(input) * 1).xz - HemiMapConstants.xy) / HemiMapConstants.z;
	GroundUVAndLerp.y	= 1 - GroundUVAndLerp.y;
	
	// localHeight scale, 1 for top and 0 for bottom
	scalar localHeight = (getWorldPos(input).y - GeomBones[0][3][1]) * InvHemiHeightScale;
	
	scalar offset		= (localHeight * 2 - 1) + HeightOverTerrain;
	offset				= clamp(offset, -2 * (1 - HeightOverTerrain), 0.8); // For TL: seems like taking this like away doesn't change much, take it out?
	GroundUVAndLerp.z	= clamp((getWorldNormal(input).y + offset) * 0.5 + 0.5, 0, 0.9);

	return GroundUVAndLerp;
}

vec4 calcUVRotation(BMVariableVSInput input)
{
	// TODO: (ROD) Gotta rotate the tangent space as well as the uv
	vec2 uv = mul(vec3(input.TexUVRotCenter * TexUnpack, 1.0), getSkinnedUVMatrix(input)).xy + input.TexDiffuse * TexUnpack;
	return vec4(uv.x, uv.y, 0, 1);
}

mat3x3 createWorld2TanMat(BMVariableVSInput input)
{
	// Cross product * flip to create BiNormal
	float flip = getBinormalFlipping(input);
	vec3 unpackedNormal = input.Normal * NormalUnpack.x + NormalUnpack.y;
	vec3 unpackedTan = input.Tan * NormalUnpack.x + NormalUnpack.y;
	vec3 binormal = normalize(cross(unpackedTan, unpackedNormal)) * flip;

	// Need to calculate the WorldI based on each matBone skinning world matrix
	mat3x3 TanBasis = mat3x3(unpackedTan, binormal, unpackedNormal);

	// Calculate WorldTangent directly... inverse is the transpose for affine rotations
	mat3x3 worldI = transpose(mul(TanBasis, getSkinnedWorldMatrix(input)));

	return worldI;
}

// NOTE: This returns un-normalized for point, because point needs to be attenuated.
vec3 getLightVec(BMVariableVSInput input)
{
#if _POINTLIGHT_
	return (Lights[0].pos - getWorldPos(input).xyz);
#else
	vec3 lvec = -Lights[0].dir;
	#if _HASCOCKPIT_
		//tl: Skin lighting vector to part to create static cockpit lighting
		lvec = mul(lvec, getSkinnedWorldMatrix(input));
	#endif
	return lvec;
#endif
}

BMVariableVSOutput vs(BMVariableVSInput input)
{
	BMVariableVSOutput Out = (BMVariableVSOutput)0;

	vec4 worldPos = getWorldPos(input);
	Out.HPos = mul(worldPos, ViewProjection);	// output HPOS

#if _HASUVANIMATION_
	Out.TexDiffuse.xy = calcUVRotation(input);				// pass-through rotate coords
#else
	Out.TexDiffuse.xy = input.TexDiffuse * TexUnpack + frac(GlobalTime * simpleUVTranslation); 		// pass-through texcoord
#endif

#if _USEHEMIMAP_
	Out.Interpolated[__HEMINTERPIDX] = calcGroundUVAndLerp(input);
#endif

#if _HASSHADOW_
	Out.Interpolated[__SHADOWINTERPIDX] = calcShadowProjection(getWorldPos(input));
#endif
#if _HASSHADOWOCCLUSION_
	Out.Interpolated[__OCCSHADOWINTERPIDX] = calcShadowProjection(getWorldPos(input), -0.003, true);
#endif
	
	vec3 worldEyeVec = normalize(WorldSpaceCamPos.xyz - getWorldPos(input).xyz);
	
#if _HASPERPIXELLIGHTING_ && _HASNORMALMAP_					// Do tangent space bumped pixel lighting
	mat3x3 world2TanMat = createWorld2TanMat(input);
	vec3 tanEyeVec = mul(worldEyeVec, world2TanMat);
	vec3 tanLightVec = mul(getLightVec(input), world2TanMat);
	Out.Interpolated[__LVECINTERPIDX].xyz = tanLightVec;
	Out.Interpolated[__HVECINTERPIDX].xyz = normalize(tanLightVec) + normalize(tanEyeVec);	
	#if !_USEPERPIXELNORMALIZE_				// normalize HVec as well because pixel shader won't
		Out.Interpolated[__LVECINTERPIDX].xyz = normalize(tanLightVec);
		Out.Interpolated[__HVECINTERPIDX].xyz = normalize(Out.Interpolated[__HVECINTERPIDX].xyz);
	#endif	
#elif _HASPERPIXELLIGHTING_				// Do world space non-bumped pixel lighting
	//tl: Object space would be cheaper, but more cumbersome
	Out.Interpolated[__LVECINTERPIDX].xyz = getLightVec(input);
	Out.Interpolated[__HVECINTERPIDX].xyz = getLightVec(input) + normalize(WorldSpaceCamPos-getWorldPos(input));
	Out.Interpolated[__WNORMALINTERPIDX].xyz = getWorldNormal(input);
	#if !_USEPERPIXELNORMALIZE_			// normalize HVec as well because pixel shader won't
		Out.Interpolated[__HVECINTERPIDX].xyz = normalize(Out.Interpolated[__HVECINTERPIDX].xyz);
		Out.Interpolated[__WNORMALINTERPIDX].xyz = normalize(Out.Interpolated[__WNORMALINTERPIDX].xyz);
	#endif
#else 		// Do vertex lighting
	scalar ndotl = dot(getLightVec(input), getWorldNormal(input));
	//scalar ndoth = dot(normalize(getLightVec(input)+worldEyeVec), getWorldNormal(input));
	scalar vdotr = dot(reflect(-getLightVec(input), getWorldNormal(input)), worldEyeVec);
	vec4 lighting = lit(ndotl, vdotr, SpecularPower);
	#if _POINTLIGHT_
		scalar attenuation = length(Lights[0].pos - getWorldPos(input)) * Lights[0].attenuation;
		lighting.yz *= attenuation;
	#endif
	Out.DiffuseLight.xyz = lighting.y * Lights[0].color;
#if !_USEHEMIMAP_
	Out.DiffuseLight.xyz += HemiMapConstantColor;
#endif
	Out.DiffuseLight.w = lighting.y;
	Out.DiffuseLight *= 0.5;
	Out.SpecularLightOrPointFog = lighting.z * Lights[0].specularColor;
	#if _HASSTATICGLOSS_
		Out.SpecularLightOrPointFog = clamp(Out.SpecularLightOrPointFog, 0, StaticGloss);
	#endif
	Out.SpecularLightOrPointFog *= 0.5;	
#endif

#if _FRESNELVALUES_
	Out.Interpolated[__ENVMAPINTERPIDX].xyz	= -reflect(worldEyeVec, getWorldNormal(input));
	Out.Interpolated[__ENVMAPINTERPIDX].w = pow((R0 + (1.0 - R0) * (1.0 - dot(worldEyeVec, getWorldNormal(input)))), 2);
#endif

#if _POINTLIGHT_
	Out.SpecularLightOrPointFog = calcFog(Out.HPos.w);
#else
	Out.Fog = calcFog(Out.HPos.w); 		//always fog
#endif
	
	return Out;
}

vec4 ps(BMVariableVSOutput input) : COLOR
{
	//return vec4(1,0,0,1);//DestBlend * 0.3;	
#if _FINDSHADER_
	return 1;
#endif
	vec4 outColor = (vec4)1;

	vec4 texDiffuse = tex2D(DiffuseMapSampler, input.TexDiffuse);
	
#ifdef	DIFFUSE_CHANNEL
	return texDiffuse;
#endif

#if _HASPERPIXELLIGHTING_
	vec3 normal = 0;
	#if _HASNORMALMAP_
		vec4 tanNormal = tex2D(NormalMapSampler, input.TexDiffuse);
		tanNormal.xyz = tanNormal.xyz * 2 - 1;
		#if _USERENORMALIZEDTEXTURES_
			tanNormal.xyz = normalize(tanNormal.xyz);
		#endif
		normal = tanNormal;
	#else
		normal = input.Interpolated[__WNORMALINTERPIDX];
		#if _USEPERPIXELNORMALIZE_
			normal = fastNormalize(normal, NRMCUBE);
		#endif
	#endif

	#ifdef NORMAL_CHANNEL
		return vec4(normal*0.5+0.5, 1);
	#endif

	vec3 lightVec = input.Interpolated[__LVECINTERPIDX];
	#if _POINTLIGHT_
		scalar attenuation = 1 - saturate(dot(lightVec,lightVec) * Lights[0].attenuation);
	#endif
	//tl: don't normalize if lvec is world space sun direction
	#if _USEPERPIXELNORMALIZE_ && (_HASNORMALMAP_ || _POINTLIGHT_)
		lightVec = fastNormalize(lightVec);
	#endif
	
	vec4 dot3Light = saturate(dot(lightVec, normal));

	vec3 halfVec = input.Interpolated[__HVECINTERPIDX];
	#if _USEPERPIXELNORMALIZE_
		halfVec = fastNormalize(halfVec, (NVIDIA || RAPATH < 1) ? NRMMATH : NRMCUBE);
	#endif

	vec3 specular = tex2D(SpecLUT64Sampler, dot(halfVec, normal));

	#if _HASCOLORMAPGLOSS_
		scalar gloss = texDiffuse.a;
	#elif !_HASSTATICGLOSS_ && _HASNORMALMAP_
		scalar gloss = tanNormal.a;		
	#else
		scalar gloss = StaticGloss;
	#endif

	#if !_POINTLIGHT_
		dot3Light *= Lights[0].color;
	#endif

	specular *= gloss;

	#ifdef SHADOW_CHANNEL
		return vec4(dot3Light+specular, 1);
	#endif

#else
	vec3 dot3Light = input.DiffuseLight.rgb * 2;
	vec3 specular = input.SpecularLightOrPointFog.rgb * 2;

	#if _HASCOLORMAPGLOSS_
		vec3 gloss = texDiffuse.a;
	#else
		vec3 gloss = StaticGloss;
	#endif
	specular *= gloss;
#endif //perpixlight

#if _HASSHADOW_
	scalar dirShadow = getShadowFactor(ShadowMapSampler, input.Interpolated[__SHADOWINTERPIDX]).r;
#else
	scalar dirShadow = 1.f;
#endif
#if _HASSHADOWOCCLUSION_
	scalar dirOccShadow = getShadowFactor(ShadowOccluderMapSampler, input.Interpolated[__OCCSHADOWINTERPIDX]);
#else
	scalar dirOccShadow = 1.f;
#endif

#if _USEHEMIMAP_
	vec4 groundcolor	= tex2D(HemiMapSampler, input.Interpolated[__HEMINTERPIDX].xy);
 	vec3 hemicolor		= lerp(groundcolor, HemiMapSkyColor, input.Interpolated[__HEMINTERPIDX].z) * HemiMapConstantColor.xyz;
	#if _HASHEMIOCCLUSION_
		dirOccShadow = groundcolor.a;
	#endif
#elif _HASPERPIXELLIGHTING_
	scalar hemicolor = Lights[0].color.w;
#else
	//tl: by setting this to 0, hlsl will remove it from the compiled code (in an addition).
	//    for non-hemi'ed materials, a static ambient will be added to sun color in vertex shader
	const vec3 hemicolor = 0.0;
#endif
	// killing both spec and dot3 if we are in shadows
	dot3Light *= dirShadow * dirOccShadow;
	specular *= dirShadow * dirOccShadow;

#if _HASGIMAP_
	vec4 GI = tex2D(GIMapSampler, input.TexDiffuse);
#else
	const vec4 GI = 1;
#endif

#if _POINTLIGHT_
	outColor.rgb = dot3Light;
#else
	outColor.rgb = hemicolor + dot3Light;
#endif

	vec4 diffuseCol = texDiffuse;
	
#if _FRESNELVALUES_
	//tl: Will hlsl auto-distribute these into pre/vs/ps, or leave them as they are?
	scalar fres = input.Interpolated[__ENVMAPINTERPIDX].w;
	
	#if _HASENVMAP_
		// NOTE: eyePos.w is just a reflection scaling value. Why do we have this besides the reflectivity (gloss map)data?
		vec3 envmapColor = texCUBE(CubeMapSampler, input.Interpolated[__ENVMAPINTERPIDX].xyz);
		diffuseCol.rgb = lerp(diffuseCol, envmapColor, gloss / 4);
	#endif

	diffuseCol.a = lerp(diffuseCol.a, 1, fres);
#endif

	outColor.rgb *= diffuseCol * GI;
	outColor.rgb += specular * GI;

#if _HASDOT3ALPHATEST_
	outColor.a = dot(texDiffuse.rgb, 1);
#else
	#if _HASCOLORMAPGLOSS_
		outColor.a = 1.f;
	#else
		outColor.a = diffuseCol.a;
	#endif
#endif

#if _POINTLIGHT_
	outColor.rgb *= attenuation * input.SpecularLightOrPointFog;
	outColor.a *= attenuation;
#endif

	outColor.a *= Transparency.a;
	
	return outColor;
}


technique defaultTechnique//Variable
{
	pass p0
	{
		VertexShader	= compile VSMODEL vs();
		PixelShader		= compile PSMODEL ps();
	

//#if NVIDIA && defined(PSVERSION) && PSVERSION <= 14
//		TextureTransformFlags[0] = PROJECTED;
//#endif

#ifdef ENABLE_WIREFRAME
		FillMode		= WireFrame;
#endif

		AlphaTestEnable		= (AlphaTest);
		AlphaRef			= (AlphaTestRef);
#if _POINTLIGHT_
		AlphaBlendEnable	= true;
		SrcBlend			= SRCALPHA;
		DestBlend			= ONE;
		Fogenable			= false;		
#else
		AlphaBlendEnable	= ( AlphaBlendEnable );
		SrcBlend			= (SrcBlend);//SRCALPHA;
		DestBlend			= (DestBlend);//INVSRCALPHA;
		ZWriteEnable		= (DepthWrite);
		Fogenable			= true;
#endif
		
	}
}

