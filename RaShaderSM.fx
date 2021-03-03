//
// -- New, better, "cleaner" skinning code.
//

#include "shaders/RaCommon.fx"
#include "shaders/RaShaderSMCommon.fx"

// Debug data
//#define _HASNORMALMAP_ 0
//#define _OBJSPACENORMALMAP_ 1
//#define _HASENVMAP_ 0

//#define _USEHEMIMAP_ 1
//#define _HASSHADOW_ 0

//#define _POINTLIGHT_ 0

// Dep.checks, etc
#if _POINTLIGHT_
	#define _HASENVMAP_ 0
	#define _USEHEMIMAP_ 0
	#define _HASSHADOW_ 0
#endif

//tl: Make this _not_ compile for ps1.3 && ATI because 1.4 is way more efficient in this case.
//    Do, however keep it compiling as ps1.3 for NVIDIA (because it's slower on NV3X in this shader :-|)
//    (yes, this _is_ ugly! kill me! No, really!)
#if PSVERSION == 13 && ATI
	FOOBAR
#endif

//tl: TEMP - REMOVEME! Force shadowed techniques on NVIDIA to 2.x shaders (in wait of feedback on HLSL tex2dproj bug)
#if NVIDIA && _HASSHADOW_ && PSVERSION < 20
	FOOBAR
#endif

//tl: Only allow 4 samples if model is 2.a/2.b
#if PSVERSION == 20
	#define NUMOCCLUSIONSAMPLES 1
#else
	#define NUMOCCLUSIONSAMPLES 4
#endif

// Only apply per-pixel hemi for rapath 0
#if _USEHEMIMAP_ && RAPATH == 0
	#define _USEPERPIXELHEMIMAP_ 1
#else
	#define _USEPERPIXELHEMIMAP_ 0
#endif
#define _USEPERPIXELNORMALIZE_ 1
#define _USERENORMALIZEDTEXTURES_ 1

// Always 2 for now, test with 1!
#define NUMBONES 2

struct SMVariableVSInput
{
	vec4	Pos 			: POSITION;    
	vec3	Normal 			: NORMAL;
	scalar	BlendWeights		: BLENDWEIGHT;
	vec4	BlendIndices 		: BLENDINDICES;    
	vec2	TexCoord0		: TEXCOORD0;
    	vec3	Tan			: TANGENT;
};

struct SMVariableVSOutput
{
	vec4	Pos					: POSITION;
	vec4	DiffuseAndHemiLerp	: COLOR0;
	vec4	Specular			: COLOR1;
	vec2	Tex0				: TEXCOORD0;
	vec3	GroundUVOrWPos		: TEXCOORD1;
#if _HASNORMALMAP_
	vec3	LightVec			: TEXCOORD2;
	#if _HASSHADOW_ || _HASSHADOWOCCLUSION_
		vec4	ShadowMat		: TEXCOORD4;
	#endif
#elif _HASSHADOW_ || _HASSHADOWOCCLUSION_
	vec4	ShadowMat			: TEXCOORD2;
#endif
	vec4	HalfVecAndOccShadow	: TEXCOORD3;
	scalar	Fog					: FOG;

#if _USEPERPIXELHEMIMAP_
	// Used only for per-pixel hemi
	vec3	TexToWorld0			: TEXCOORD5;
	vec3	TexToWorld1			: TEXCOORD6;
	vec3	TexToWorld2			: TEXCOORD7;
#endif
};

scalar getBlendWeight(SMVariableVSInput input, uniform int bone)
{
	if(bone == 0)
		return input.BlendWeights;
	else
		return 1.0 - input.BlendWeights;
}

mat4x3 getBoneMatrix(SMVariableVSInput input, uniform int bone)
{
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;	
	return MatBones[IndexArray[bone]];
}

float getBinormalFlipping(SMVariableVSInput input)
{
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;	
	return 1.f + IndexArray[2] * -2.f;
}

mat3x3 getTangentBasis(SMVariableVSInput input)
{
	float flip = getBinormalFlipping(input);
	vec3 binormal = normalize(cross(input.Tan, input.Normal)) * flip;
	return mat3x3(input.Tan, binormal, input.Normal);
}

vec3 skinPos(SMVariableVSInput input, vec4 Vec, uniform int numBones = NUMBONES)
{
	vec3 skinnedPos = mul(Vec, getBoneMatrix(input, 0));
	if(numBones > 1)
	{
		skinnedPos *= getBlendWeight(input, 0);
		skinnedPos += mul(Vec, getBoneMatrix(input, 1)) * getBlendWeight(input, 1);
	}
	return skinnedPos;
}

vec3 skinVec(SMVariableVSInput input, vec3 Vec, uniform int numBones = NUMBONES)
{
	vec3 skinnedVec = mul(Vec, getBoneMatrix(input, 0));
	if(numBones > 1)
	{
		skinnedVec *= getBlendWeight(input, 0);
		skinnedVec += mul(Vec, getBoneMatrix(input, 1)) * getBlendWeight(input, 1);
	}
	return skinnedVec;
}

vec3 skinVecToObj(SMVariableVSInput input, vec3 Vec, uniform int numBones = NUMBONES)
{
	vec3 skinnedVec = mul(Vec, transpose(getBoneMatrix(input, 0)));
	if(numBones > 1)
	{
		skinnedVec *= getBlendWeight(input, 0);
		skinnedVec += mul(Vec, transpose(getBoneMatrix(input, 1))) * getBlendWeight(input, 1);
	}

	return skinnedVec;
}

vec3 skinVecToTan(SMVariableVSInput input, vec3 Vec, uniform int numBones = NUMBONES)
{
	mat3x3 tanBasis = getTangentBasis(input);

	mat3x3 toTangent0 = transpose(mul(tanBasis, getBoneMatrix(input, 0)));
	vec3 skinnedVec = mul(Vec, toTangent0);
	
	if(numBones > 1)
	{
		skinnedVec *= getBlendWeight(input, 0);
		mat3x3 toTangent1 = transpose(mul(tanBasis, getBoneMatrix(input, 1)));
		skinnedVec += mul(Vec, toTangent1) * getBlendWeight(input, 1);
	}

	return skinnedVec;
}

vec4 skinPosition(SMVariableVSInput input)
{
	return vec4(skinPos(input, input.Pos), 1);
}

vec3 skinNormal(SMVariableVSInput input, uniform int numBones = NUMBONES)
{
	vec3 skinnedNormal = skinVec(input, input.Normal);
	if(numBones > 1)
	{
		// Re-normalize skinned normal
		skinnedNormal = normalize(skinnedNormal);
	}
	return skinnedNormal;
}

vec4 getWorldPos(SMVariableVSInput input)
{
	return mul(skinPosition(input), World);
}

vec3 getWorldNormal(SMVariableVSInput input)
{
	return mul(skinNormal(input), World);
}

vec4 calcGroundUVAndLerp(vec3 wPos, vec3 wNormal)
{
	// HemiMapConstants: offset x/y heightmapsize z / hemilerpbias w

	vec4 GroundUVAndLerp = 0;
	GroundUVAndLerp.xy	= ((wPos + (HemiMapConstants.z/2) + wNormal).xz - HemiMapConstants.xy) / HemiMapConstants.z;
	GroundUVAndLerp.y	= 1 - GroundUVAndLerp.y;
	
	// localHeight scale, 1 for top and 0 for bottom
	scalar localHeight = (wPos.y - (World[3][1] - 0.5)) * 0.5/*InvHemiHeightScale*/;
	
	scalar offset		= (localHeight * 2 - 1) + HeightOverTerrain;
	offset				= clamp(offset, -2 * (1 - HeightOverTerrain), 0.8); // For TL: seems like taking this like away doesn't change much, take it out?
	GroundUVAndLerp.z	= clamp((wNormal.y + offset) * 0.5 + 0.5, 0, 0.9);
	
	return GroundUVAndLerp;
}

vec3 skinLightVec(SMVariableVSInput input, vec3 lVec)
{
#if _OBJSPACENORMALMAP_ || !_HASNORMALMAP_
	return skinVecToObj(input, lVec, 1);
#else
	return skinVecToTan(input, lVec, 1);
#endif
}

// NOTE: This returns un-normalized for point, because point needs to be attenuated.
vec3 getLightVec(SMVariableVSInput input)
{
#if _POINTLIGHT_
	return (Lights[0].pos - skinPosition(input).xyz);
#else
	return -Lights[0].dir;
#endif
}

SMVariableVSOutput vs(SMVariableVSInput input)
{
	SMVariableVSOutput Out = (SMVariableVSOutput)0;
	
	vec4 objSpacePosition = skinPosition(input);
	
	Out.Pos = mul(objSpacePosition, WorldViewProjection);
	Out.Tex0 = input.TexCoord0;
	
#if (_USEHEMIMAP_ && !_USEPERPIXELHEMIMAP_) || (_USEHEMIMAP_ && !_HASNORMALMAP_)
	Out.GroundUVOrWPos = calcGroundUVAndLerp(getWorldPos(input), getWorldNormal(input));
	Out.DiffuseAndHemiLerp.w = Out.GroundUVOrWPos.z;
#elif _USEPERPIXELHEMIMAP_
	#if _OBJSPACENORMALMAP_
		mat3x3 objToTexture0 = getBoneMatrix(input, 0);
	#else
		mat3x3 objToTexture0 = mul(getTangentBasis(input), getBoneMatrix(input, 0));
	#endif
	mat3x3 worldToTexture0 = mul(objToTexture0, World);
	worldToTexture0 = transpose(worldToTexture0);
	Out.TexToWorld0 = worldToTexture0[0];
	Out.TexToWorld1 = worldToTexture0[1];
	Out.TexToWorld2 = worldToTexture0[2];
	Out.GroundUVOrWPos = getWorldPos(input);
#endif

	vec3 objEyeVec = normalize(ObjectSpaceCamPos.xyz - objSpacePosition.xyz);
	vec3 lVec = skinLightVec(input, getLightVec(input));
	vec3 hVec = normalize(lVec) + normalize(skinLightVec(input, objEyeVec));
#if _HASNORMALMAP_
	Out.LightVec = lVec;
	#if !_POINTLIGHT_
		Out.LightVec = normalize(Out.LightVec);
		Out.Fog = calcFog(Out.Pos.w);
	#endif
	Out.HalfVecAndOccShadow.xyz = normalize(hVec);
#else
	vec4 lighting = lit(dot(normalize(lVec), input.Normal), dot(normalize(hVec), input.Normal), SpecularPower);
	Out.DiffuseAndHemiLerp.rgb = (lighting.y * Lights[0].color) * 0.5;
	#if _POINTLIGHT_
		Out.Specular.rgb = (lighting.z * Lights[0].color * /*StaticGloss*/0.15) * 0.5;
	#else
		Out.Specular.rgb = (lighting.z * Lights[0].specularColor * /*StaticGloss*/0.15) * 0.5;
		Out.Fog = calcFog(Out.Pos.w);
	#endif
#endif
	
#if _HASSHADOW_ || _HASSHADOWOCCLUSION_
	Out.ShadowMat = calcShadowProjection(getWorldPos(input));
#endif
#if _HASSHADOWOCCLUSION_
	Out.HalfVecAndOccShadow.w = calcShadowProjection(getWorldPos(input), -0.003, true).z;
#endif

	return Out;
}

vec4 ps(SMVariableVSOutput input) : COLOR
{
#if _HASNORMALMAP_
	vec4 normal = tex2D(NormalMapSampler, input.Tex0);
	normal.xyz = normal.xyz * 2 - 1;
	#if _USERENORMALIZEDTEXTURES_
		normal.xyz = normalize(normal.xyz);
	#endif
#ifdef NORMAL_CHANNEL
	return vec4(normal.xyz*0.5+0.5, 1);
#endif

	scalar gloss = normal.a;

	vec3 lightVec = input.LightVec;
	#if _POINTLIGHT_
		scalar attenuation = 1 - saturate(length(lightVec) * Lights[0].attenuation);
		lightVec = normalize(lightVec);
	#else
		const scalar attenuation = 1.0;
	#endif

	scalar dot3Light = saturate(dot(lightVec, normal));
	scalar specular = pow(saturate(dot(normalize(input.HalfVecAndOccShadow.xyz), normal)), SpecularPower);
	
	specular *= gloss;

	dot3Light *= attenuation;
	specular *= attenuation;
#endif	

// Remember, optimize for HWSM and ps1.3 (yes, it can be done!)
#if _HASSHADOW_
	scalar dirShadow = getShadowFactor(ShadowMapSampler, input.ShadowMat);
#else
	scalar dirShadow = 1.0;
#endif

#if _HASSHADOWOCCLUSION_
	vec4 shadowOccMat = input.ShadowMat;
	shadowOccMat.z = input.HalfVecAndOccShadow.w;
	scalar dirOccShadow = getShadowFactor(ShadowOccluderMapSampler, shadowOccMat, NUMOCCLUSIONSAMPLES);
	dirShadow *= dirOccShadow;
#endif

#if (_USEHEMIMAP_ && !_USEPERPIXELHEMIMAP_) || (_USEHEMIMAP_ && !_HASNORMALMAP_)
	vec4 groundcolor	= tex2D(HemiMapSampler, input.GroundUVOrWPos.xy);
 	vec3 hemicolor		= lerp(groundcolor, HemiMapSkyColor, input.DiffuseAndHemiLerp.w)* HemiMapConstantColor.xyz;
#elif _USEPERPIXELHEMIMAP_ && !_NOTHING_
	vec3 wNormal;
	wNormal.x = dot(input.TexToWorld0, normal);
	wNormal.y = dot(input.TexToWorld1, normal);
	wNormal.z = dot(input.TexToWorld2, normal);
	vec3 GroundUVAndLerp = calcGroundUVAndLerp(input.GroundUVOrWPos, wNormal);
	vec4 groundcolor	= tex2D(HemiMapSampler, GroundUVAndLerp.xy);
 	vec3 hemicolor		= lerp(groundcolor, HemiMapSkyColor, GroundUVAndLerp.z)*HemiMapConstantColor.xyz;
#else
	const vec3 hemicolor = HemiMapConstantColor.xyz; //"old"  -- expose a per-level "static hemi" value (ambient mod)
	vec4 groundcolor = 1;
#endif

#if _HASHEMIOCCLUSION_
	dirShadow *= groundcolor.a;
#endif

	vec4 diffuseTex = tex2D(DiffuseMapSampler, input.Tex0);

#ifdef	DIFFUSE_CHANNEL
	return diffuseTex;
#endif
	vec4 outColor;
	
#if _HASNORMALMAP_
	dot3Light *= dirShadow;
	specular *= dirShadow;
	
	#if _POINTLIGHT_
		outColor.rgb = dot3Light * Lights[0].color;
	#else
		outColor.rgb = (dot3Light * Lights[0].color) + hemicolor;
	#endif
	#ifdef SHADOW_CHANNEL
		return vec4(outColor.rgb, 1);
	#endif
	outColor.rgb *= diffuseTex;
	#if _POINTLIGHT_
		outColor.rgb += specular * Lights[0].specularColor;
	#else
		outColor.rgb += specular * Lights[0].specularColor;
	#endif
#else
	#if _POINTLIGHT_
		outColor.rgb = input.DiffuseAndHemiLerp * 2;
	#else
		outColor.rgb = (input.DiffuseAndHemiLerp * 2) * dirShadow + hemicolor;
	#endif
	outColor.rgb *= diffuseTex;
	outColor.rgb += (input.Specular.rgb * 2) * dirShadow;
#endif

	outColor.a = diffuseTex.a*Transparency.a;

	return outColor;
}
/*
vec4 ps_BrokenCamouflage(SMVariableVSOutput input) : COLOR
{
	vec3 color = vec3(input.Tex0.x,input.Tex0.y, 1.0);
	return vec4(color,1.0);
}

vec4 ps_Camouflage(SMVariableVSOutput input) : COLOR
{
	return vec4(0.0,0.0,0.0,1.0);
}
*/
technique defaultTechnique //VariableTechnique
{
	pass
	{
		AlphaTestEnable		= (AlphaTest);
		AlphaRef			= (AlphaTestRef);
#if _POINTLIGHT_
		AlphaBlendEnable= TRUE;
		SrcBlend		= ONE;
		DestBlend		= ONE;
		fogenable = false;
#else
		AlphaBlendEnable	= FALSE;
		FogEnable		= TRUE;
#endif

		VertexShader = compile VSMODEL vs();
#if 1
		PixelShader = compile PSMODEL ps();
#elif 0
//tl: please leave this debug stuff in until we got a mail reply from microsoft.
        PixelShaderConstantF[0] = (Transparency);
        PixelShaderConstantF[1] = (HemiMapSkyColor);
        Sampler[0] = (DiffuseMapSampler);
        Sampler[1] = (HemiMapSampler);
		PixelShader = asm {
            //   Transparency      c0       1
            //   HemiMapSkyColor   c1       1
            //   DiffuseMapSampler s0       1
            //   HemiMapSampler    s1       1
            //
            
                ps_1_3
                tex t0
                tex t1
                lrp_d2 r0.xyz, v0.w, c1, t1
                add r0.xyz, r0, v0
              + mul r0.w, t0.w, c0.w
                mad_x2 r0.xyz, t0, r0, v1
		};
#elif 0
        PixelShaderConstantF[0] = (Transparency);
        Sampler[0] = (DiffuseMapSampler);
		PixelShader = asm {
                ps_1_3
                def c1, 0.212500006, 0.212500006, 0.200000003, 0
                tex t0
                add r0.xyz, v0, c1
              + mul r0.w, t0.w, c0.w
                mad_x2 r0.xyz, t0, r0, v1
		};
#endif
	}
}
/*
technique BrokenCamouflage
{
	pass
	{
		VertexShader = compile VSMODEL vs();
		PixelShader = compile PSMODEL ps_BrokenCamouflage();
	}
}

technique Camouflage
{
	pass
	{
		VertexShader = compile VSMODEL vs();
		PixelShader = compile PSMODEL ps_Camouflage();
		ColorWriteEnable = ALPHA;
	}
}
*/