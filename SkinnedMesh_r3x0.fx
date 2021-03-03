

struct APP2VS_fullMRT
{
	vec4	Pos 		: POSITION;    
	vec3	Normal 		: NORMAL;
	scalar	BlendWeights	: BLENDWEIGHT;
	vec4	BlendIndices 	: BLENDINDICES;    
	vec2	TexCoord0 	: TEXCOORD0;
};

struct VS2PS_ZAndDiffuse
{
	vec4	Pos				: POSITION;
	vec2	Tex0			: TEXCOORD0;
};

struct VS2PS_fullMRT
{
	vec4	Pos				: POSITION;
	vec2	Tex0			: TEXCOORD0;
	vec3	GroundUVAndLerp	: COLOR0;
    	vec4	wPos			: TEXCOORD1;
	vec4 Mat1				: TEXCOORD2;
	vec3 Mat2				: TEXCOORD3;
	vec3 Mat3				: TEXCOORD4;
	vec4 Mat1_			: TEXCOORD5;
	vec3 Mat2_			: TEXCOORD6;
	vec3 Mat3_			: TEXCOORD7;
};

struct PS2FB_fullMRT
{
    vec4	Col0 		: COLOR0;
    vec4	Col1 		: COLOR1;
    vec4	Col2 		: COLOR2;
};

VS2PS_ZAndDiffuse vsZAndDiffuse(APP2VS_fullMRT indata, uniform int NumBones)
{
	VS2PS_ZAndDiffuse outdata;
	
	scalar LastWeight = 0.0;
	vec3 Pos = 0.0;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		Pos += mul(indata.Pos, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	Pos += mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	
	vec4 pos4 = vec4(Pos.xyz, 1.0);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(pos4, mWorldViewProj); 

	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

vec4 psZAndDiffuse(VS2PS_ZAndDiffuse  indata) : COLOR
{
	return tex2D(sampler0, indata.Tex0);
}

VS2PS_fullMRT vsFullMRT(APP2VS_fullMRT indata, uniform int NumBones)
{
	VS2PS_fullMRT outdata;
	
	scalar LastWeight = 0.0;
	vec3 Pos = 0.0;
	vec3 Normal = 0.0;    
	vec3 SkinnedLVec = 0.0;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		Pos += mul(indata.Pos, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		Normal += mul(indata.Normal, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	Pos += mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	Normal += mul(indata.Normal, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	
	// Normalize normals
	Normal = normalize(Normal);
	
	vec4 pos4 = vec4(Pos.xyz, 1.0);
	
	mat3x3 mBone1 = transpose((mat3x3)mBoneArray[IndexArray[0]]);
	mat3x3 mBone2 = transpose((mat3x3)mBoneArray[IndexArray[1]]);
	outdata.Mat1.xyz = mBone1[0];
	outdata.Mat1.w = BlendWeightsArray[0];
	outdata.Mat2 = mBone1[1];
	outdata.Mat3 = mBone1[2];
	outdata.Mat1_.xyz = mBone2[0];
	outdata.Mat1_.w = 1 - BlendWeightsArray[0];
	outdata.Mat2_ = mBone2[1];
	outdata.Mat3_ = mBone2[2];

	// Transform position into view and then projection space
	outdata.Pos = mul(pos4, mWorldViewProj); 

 	// Hemi lookup values
	vec4 wPos = mul(pos4, mWorld); 
 	outdata.GroundUVAndLerp.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;

	outdata.wPos = mul(pos4, mWorldView);

	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

PS2FB_fullMRT psFullMRT(VS2PS_fullMRT indata)
{
	PS2FB_fullMRT outdata;
	
	vec4 groundcolor = tex2D(sampler0, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, skyColor, indata.GroundUVAndLerp.z);
	vec4 expnormal = tex2D(sampler1, indata.Tex0);
	expnormal.rgb = (expnormal * 2) - 1;

	outdata.Col0 = ambientColor*hemicolor;
	outdata.Col1 = indata.wPos;

	vec3 normal;
	normal.x = dot(expnormal, indata.Mat1.xyz) * indata.Mat1.w;
	normal.y = dot(expnormal, indata.Mat2.xyz) * indata.Mat1.w;
	normal.z = dot(expnormal, indata.Mat3.xyz) * indata.Mat1.w;
	normal.x += dot(expnormal, indata.Mat1_.xyz) * indata.Mat1_.w;
	normal.y += dot(expnormal, indata.Mat2_.xyz) * indata.Mat1_.w;
	normal.z += dot(expnormal, indata.Mat3_.xyz) * indata.Mat1_.w;
	outdata.Col2.x = dot(normal, mWorldViewI[0].xyz);
	outdata.Col2.y = dot(normal, mWorldViewI[1].xyz);
	outdata.Col2.z = dot(normal, mWorldViewI[2].xyz);
	outdata.Col2.w = expnormal.a;

	return outdata;
}

// Max 2 bones skinning supported!
VertexShader vsArrayFullMRT[2] = { compile vs_1_1 vsFullMRT(1), compile vs_1_1 vsFullMRT(2) };

technique fullMRT
{
	pass zdiffuse
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;

		VertexShader = compile vs_1_1 vsZAndDiffuse(2);
		PixelShader = compile ps_1_1 psZAndDiffuse();
	}

	pass mrt
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = EQUAL;

		StencilEnable = FALSE;

		VertexShader = (vsArrayFullMRT[1]);
		PixelShader = compile ps_2_0 psFullMRT();
	}
}

//----------- pp tangent based lighting

struct APP2VS_fullMRTtangent
{
	vec4	Pos 		: POSITION;    
	vec3	Normal 		: NORMAL;
	scalar	BlendWeights	: BLENDWEIGHT;
	vec4	BlendIndices 	: BLENDINDICES;    
	vec2	TexCoord0 	: TEXCOORD0;
    vec3  Tan : TANGENT;
};


VS2PS_fullMRT vsFullMRTtangent(APP2VS_fullMRTtangent indata, uniform int NumBones)
{
	VS2PS_fullMRT outdata;
	
	scalar LastWeight = 0.0;
	vec3 Pos = 0.0;
	vec3 Normal = 0.0;    
	vec3 SkinnedLVec = 0.0;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    

	vec3 binormal = normalize(cross(indata.Tan, indata.Normal));
	mat3x3 TanBasis = mat3x3( indata.Tan, 
					binormal, 
					indata.Normal);
	mat3x3 worldI;	
	mat3x3 mat;	
	
	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		Pos += mul(indata.Pos, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		Normal += mul(indata.Normal, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	Pos += mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	Normal += mul(indata.Normal, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	
	// Normalize normals
	Normal = normalize(Normal);
	
	vec4 pos4 = vec4(Pos.xyz, 1.0);
	
	// Calculate WorldTangent directly... inverse is the transpose for affine rotations
	mat3x3 mBone1 = transpose(mul(TanBasis, mBoneArray[IndexArray[0]]));
	mat3x3 mBone2 = transpose(mul(TanBasis, mBoneArray[IndexArray[1]]));
	outdata.Mat1.xyz = mBone1[0];
	outdata.Mat1.w = BlendWeightsArray[0];
	outdata.Mat2 = mBone1[1];
	outdata.Mat3 = mBone1[2];
	outdata.Mat1_.xyz = mBone2[0];
	outdata.Mat1_.w = 1 - BlendWeightsArray[0];
	outdata.Mat2_ = mBone2[1];
	outdata.Mat3_ = mBone2[2];

	// Transform position into view and then projection space
	outdata.Pos = mul(pos4, mWorldViewProj); 

 	// Hemi lookup values
	vec4 wPos = mul(pos4, mWorld); 
 	outdata.GroundUVAndLerp.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;

	outdata.wPos = mul(pos4, mWorldView);
	 	
	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

// Max 2 bones skinning supported!
VertexShader vsArrayFullMRTtangent[2] = { compile vs_1_1 vsFullMRTtangent(1), compile vs_1_1 vsFullMRTtangent(2) };

technique fullMRTtangent
{
	pass zdiffuse
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;

		VertexShader = compile vs_1_1 vsZAndDiffuse(2);
		PixelShader = compile ps_1_1 psZAndDiffuse();
	}
	pass mrt
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = EQUAL;

		StencilEnable = FALSE;

		VertexShader = (vsArrayFullMRTtangent[1]);
		PixelShader = compile ps_2_0 psFullMRT();
	}
}

struct VS2PS_fullMRTskinpre
{
	vec4	Pos				: POSITION;
	vec2	Tex0			: TEXCOORD0;
	vec4 Mat1				: TEXCOORD1;
	vec3 Mat2				: TEXCOORD2;
	vec3 Mat3				: TEXCOORD3;
	vec4 Mat1_			: TEXCOORD4;
	vec3 Mat2_			: TEXCOORD5;
	vec3 Mat3_			: TEXCOORD6;
	vec3 ObjEyeVec		: TEXCOORD7;
};

VS2PS_fullMRTskinpre vsFullMRTskinpre(APP2VS_fullMRT indata, uniform int NumBones)
{
	VS2PS_fullMRTskinpre outdata;

	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	vec3 Pos = mul(indata.Pos, mBoneArray[IndexArray[0]]) * BlendWeightsArray[0];
	Pos += mul(indata.Pos, mBoneArray[IndexArray[1]]) * (1-BlendWeightsArray[0]);
	outdata.ObjEyeVec = normalize(objectEyePos-Pos);

	mat3x3 mBone1 = transpose((mat3x3)mBoneArray[IndexArray[0]]);
	mat3x3 mBone2 = transpose((mat3x3)mBoneArray[IndexArray[1]]);
	outdata.Mat1.xyz = mBone1[0];
	outdata.Mat1.w = BlendWeightsArray[0];
	outdata.Mat2 = mBone1[1];
	outdata.Mat3 = mBone1[2];
	outdata.Mat1_.xyz = mBone2[0];
	outdata.Mat1_.w = 1 - BlendWeightsArray[0];
	outdata.Mat2_ = mBone2[1];
	outdata.Mat3_ = mBone2[2];

	outdata.Pos.xy = indata.TexCoord0 * vec2(2,-2) - vec2(1, -1);
	outdata.Pos.zw = vec2(0, 1);
	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

vec4 psFullMRTskinpre(VS2PS_fullMRTskinpre indata) : COLOR
{
	vec4 expnormal = tex2D(sampler0, indata.Tex0);
	expnormal.rgb = (expnormal * 2) - 1;

	vec3 normal;
	normal.x = dot(expnormal, indata.Mat1.xyz) * indata.Mat1.w;
	normal.y = dot(expnormal, indata.Mat2.xyz) * indata.Mat1.w;
	normal.z = dot(expnormal, indata.Mat3.xyz) * indata.Mat1.w;
	normal.x += dot(expnormal, indata.Mat1_.xyz) * indata.Mat1_.w;
	normal.y += dot(expnormal, indata.Mat2_.xyz) * indata.Mat1_.w;
	normal.z += dot(expnormal, indata.Mat3_.xyz) * indata.Mat1_.w;

	scalar wrapDiff = dot(normal, -sunLightDir) + 0.5;
	wrapDiff = saturate(wrapDiff / 1.5);

	scalar rimDiff = 1-dot(normal, indata.ObjEyeVec);
	rimDiff = pow(rimDiff,3);

	rimDiff *= saturate(0.75-saturate(dot(indata.ObjEyeVec, -sunLightDir)));
	
	return vec4(wrapDiff.rrr + rimDiff, expnormal.a);
}

struct VS2PS_fullMRTskinpreshadowed
{
	vec4	Pos				: POSITION;
	vec4 Tex0AndHZW		: TEXCOORD0;
	vec4 Mat1				: TEXCOORD1;
	vec3 Mat2				: TEXCOORD2;
	vec3 Mat3				: TEXCOORD3;
	vec4 Mat1_			: TEXCOORD4;
	vec3 Mat2_			: TEXCOORD5;
	vec3 Mat3_			: TEXCOORD6;
	vec4 ShadowTex		: TEXCOORD7;
	vec3 ObjEyeVec		: COLOR;
};

VS2PS_fullMRTskinpreshadowed vsFullMRTskinpreshadowed(APP2VS_fullMRT indata, uniform int NumBones)
{
	VS2PS_fullMRTskinpreshadowed outdata;

	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	vec3 Pos = mul(indata.Pos, mBoneArray[IndexArray[0]]) * BlendWeightsArray[0];
	Pos += mul(indata.Pos, mBoneArray[IndexArray[1]]) * (1-BlendWeightsArray[0]);
	outdata.ObjEyeVec = normalize(objectEyePos-Pos);

//	vec4 hPos = mul(vec4(Pos, 1), mWorldViewProj); 
//	outdata.Tex0AndHZW.zw = hPos.zw;
	outdata.ShadowTex = mul(vec4(Pos, 1), mLightVP);
	outdata.ShadowTex.xy = clamp(outdata.ShadowTex.xy, vViewportMap.xy, vViewportMap.zw);

//	vec4 vPos = mul(vec4(Pos, 1), mWorldView);
//	outdata.ShadowTex = mul(vPos, mLightVP2);
//	vec4 wPos = mul(vec4(Pos, 1), mWorld);
//	outdata.ShadowTex = mul(wPos, mLightVP3);
//	//outdata.ShadowTex.xyz /= outdata.ShadowTex.w;
//	outdata.ShadowTex.xy = (outdata.ShadowTex.xy + 1) / 2;
//	outdata.ShadowTex.y = 1-outdata.ShadowTex.y;
	outdata.ShadowTex.z -= 0.007;
outdata.ShadowTex.xy = clamp(outdata.ShadowTex.xy, vViewportMap.xy, vViewportMap.zw);

	mat3x3 mBone1 = transpose((mat3x3)mBoneArray[IndexArray[0]]);
	mat3x3 mBone2 = transpose((mat3x3)mBoneArray[IndexArray[1]]);
	outdata.Mat1.xyz = mBone1[0];
	outdata.Mat1.w = BlendWeightsArray[0];
	outdata.Mat2 = mBone1[1];
	outdata.Mat3 = mBone1[2];
	outdata.Mat1_.xyz = mBone2[0];
	outdata.Mat1_.w = 1 - BlendWeightsArray[0];
	outdata.Mat2_ = mBone2[1];
	outdata.Mat3_ = mBone2[2];

	outdata.Pos.xy = indata.TexCoord0 * vec2(2,-2) - vec2(1, -1);
	outdata.Pos.zw = vec2(0, 1);
	outdata.Tex0AndHZW/*.xy*/ = indata.TexCoord0.xyyy;
	
	return outdata;
}

vec4 psFullMRTskinpreshadowed(VS2PS_fullMRTskinpreshadowed indata) : COLOR
{
	vec4 expnormal = tex2D(sampler0, indata.Tex0AndHZW);
	expnormal.rgb = (expnormal * 2) - 1;

	vec3 normal;
	normal.x = dot(expnormal, indata.Mat1.xyz) * indata.Mat1.w;
	normal.y = dot(expnormal, indata.Mat2.xyz) * indata.Mat1.w;
	normal.z = dot(expnormal, indata.Mat3.xyz) * indata.Mat1.w;
	normal.x += dot(expnormal, indata.Mat1_.xyz) * indata.Mat1_.w;
	normal.y += dot(expnormal, indata.Mat2_.xyz) * indata.Mat1_.w;
	normal.z += dot(expnormal, indata.Mat3_.xyz) * indata.Mat1_.w;

	scalar wrapDiff = dot(normal, -sunLightDir) + 0.5;
	wrapDiff = saturate(wrapDiff / 1.5);

	scalar rimDiff = 1-dot(normal, indata.ObjEyeVec);
	rimDiff = pow(rimDiff,3);
	rimDiff *= saturate(0.75-saturate(dot(indata.ObjEyeVec, -sunLightDir)));

	vec2 texel = vec2(1.0/1024.0, 1.0/1024.0);
	vec4 samples;
	samples.x = tex2D(sampler2point, indata.ShadowTex);
	samples.y = tex2D(sampler2point, indata.ShadowTex + vec2(texel.x, 0));
	samples.z = tex2D(sampler2point, indata.ShadowTex + vec2(0, texel.y));
	samples.w = tex2D(sampler2point, indata.ShadowTex + texel);
	
	vec4 staticSamples;
	staticSamples.x = tex2D(sampler1, indata.ShadowTex + vec2(-texel.x*1, -texel.y*2)).b;
	staticSamples.y = tex2D(sampler1, indata.ShadowTex + vec2( texel.x*1, -texel.y*2)).b;
	staticSamples.z = tex2D(sampler1, indata.ShadowTex + vec2(-texel.x*1,  texel.y*2)).b;
	staticSamples.w = tex2D(sampler1, indata.ShadowTex + vec2( texel.x*1,  texel.y*2)).b;
	staticSamples.x = dot(staticSamples.xyzw, 0.25);
	
	vec4 cmpbits = samples > saturate(indata.ShadowTex.z);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));

	scalar totShadow = avgShadowValue.x*staticSamples.x;
	scalar totDiff = wrapDiff + rimDiff;
	return vec4(totDiff, totShadow, saturate(totShadow+0.35), expnormal.a);
}

vec4 psFullMRTskinpreshadowedNV(VS2PS_fullMRTskinpreshadowed indata) : COLOR
{
	vec4 expnormal = tex2D(sampler0, indata.Tex0AndHZW);
	expnormal.rgb = (expnormal * 2) - 1;

	vec3 normal;
	normal.x = dot(expnormal, indata.Mat1.xyz) * indata.Mat1.w;
	normal.y = dot(expnormal, indata.Mat2.xyz) * indata.Mat1.w;
	normal.z = dot(expnormal, indata.Mat3.xyz) * indata.Mat1.w;
	normal.x += dot(expnormal, indata.Mat1_.xyz) * indata.Mat1_.w;
	normal.y += dot(expnormal, indata.Mat2_.xyz) * indata.Mat1_.w;
	normal.z += dot(expnormal, indata.Mat3_.xyz) * indata.Mat1_.w;

	scalar wrapDiff = dot(normal, -sunLightDir) + 0.5;
	wrapDiff = saturate(wrapDiff / 1.5);

	scalar rimDiff = 1-dot(normal, indata.ObjEyeVec);
	rimDiff = pow(rimDiff,3);
	rimDiff *= saturate(0.75-saturate(dot(indata.ObjEyeVec, -sunLightDir)));

	vec2 texel = vec2(1.0/1024.0, 1.0/1024.0);
	/*
	vec4 samples;
	samples.x = tex2D(sampler2point, indata.ShadowTex);
	samples.y = tex2D(sampler2point, indata.ShadowTex + vec2(texel.x, 0));
	samples.z = tex2D(sampler2point, indata.ShadowTex + vec2(0, texel.y));
	samples.w = tex2D(sampler2point, indata.ShadowTex + texel);*/
	scalar avgShadowValue = tex2Dproj(sampler2, indata.ShadowTex); // HW percentage closer filtering.
	
	vec4 staticSamples;
	staticSamples.x = tex2D(sampler1, indata.ShadowTex + vec2(-texel.x*1, -texel.y*2)).b;
	staticSamples.y = tex2D(sampler1, indata.ShadowTex + vec2( texel.x*1, -texel.y*2)).b;
	staticSamples.z = tex2D(sampler1, indata.ShadowTex + vec2(-texel.x*1,  texel.y*2)).b;
	staticSamples.w = tex2D(sampler1, indata.ShadowTex + vec2( texel.x*1,  texel.y*2)).b;
	staticSamples.x = dot(staticSamples.xyzw, 0.25);
	
	//vec4 cmpbits = samples > saturate(indata.ShadowTex.z);
	//scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));

	scalar totShadow = avgShadowValue.x*staticSamples.x;
	scalar totDiff = wrapDiff + rimDiff;
	return vec4(totDiff, totShadow, saturate(totShadow+0.35), expnormal.a);
}

VS2PS_fullMRT vsFullMRTskinapply(APP2VS_fullMRT indata, uniform int NumBones)
{
	VS2PS_fullMRT outdata;
	
	scalar LastWeight = 0.0;
	vec3 Pos = 0.0;
	vec3 Normal = 0.0;    
	vec3 SkinnedLVec = 0.0;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		Pos += mul(indata.Pos, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		Normal += mul(indata.Normal, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	Pos += mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	Normal += mul(indata.Normal, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	
	// Normalize normals
	Normal = normalize(Normal);
	
	vec4 pos4 = vec4(Pos.xyz, 1.0);
	
	mat3x3 mBone1 = transpose((mat3x3)mBoneArray[IndexArray[0]]);
	mat3x3 mBone2 = transpose((mat3x3)mBoneArray[IndexArray[1]]);
	outdata.Mat1.xyz = mBone1[0];
	outdata.Mat1.w = BlendWeightsArray[0];
	outdata.Mat2 = mBone1[1];
	outdata.Mat3 = mBone1[2];
	outdata.Mat1_.xyz = mBone2[0];
	outdata.Mat1_.w = 1 - BlendWeightsArray[0];
	outdata.Mat2_ = mBone2[1];
	outdata.Mat3_ = mBone2[2];

	// Transform position into view and then projection space
	outdata.Pos = mul(pos4, mWorldViewProj); 

 	// Hemi lookup values
	vec4 wPos = mul(pos4, mWorld); 
 	outdata.GroundUVAndLerp.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;

	outdata.wPos = mul(pos4, mWorldView);

	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

PS2FB_fullMRT psFullMRTskinapply(VS2PS_fullMRT indata)
{
	PS2FB_fullMRT outdata;
	
	vec4 groundcolor = tex2D(sampler0, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, skyColor, indata.GroundUVAndLerp.z);
	vec4 expnormal = tex2D(sampler1, indata.Tex0);
	expnormal.rgb = (expnormal * 2) - 1;
	vec4 diffuse = tex2D(sampler2, indata.Tex0);
	vec4 diffuseLight = tex2D(sampler3, indata.Tex0);

	vec3 normal;
	normal.x = dot(expnormal, indata.Mat1.xyz) * indata.Mat1.w;
	normal.y = dot(expnormal, indata.Mat2.xyz) * indata.Mat1.w;
	normal.z = dot(expnormal, indata.Mat3.xyz) * indata.Mat1.w;
	normal.x += dot(expnormal, indata.Mat1_.xyz) * indata.Mat1_.w;
	normal.y += dot(expnormal, indata.Mat2_.xyz) * indata.Mat1_.w;
	normal.z += dot(expnormal, indata.Mat3_.xyz) * indata.Mat1_.w;

	outdata.Col0.rgb = ambientColor*hemicolor + diffuseLight.r*diffuseLight.b*sunColor;
	outdata.Col0.a = diffuseLight.g;
//outdata.Col0 = diffuseLight;
	outdata.Col1 = indata.wPos;
	outdata.Col2.x = dot(normal, mWorldViewI[0].xyz);
	outdata.Col2.y = dot(normal, mWorldViewI[1].xyz);
	outdata.Col2.z = dot(normal, mWorldViewI[2].xyz);
	outdata.Col2.w = diffuse.w;

	return outdata;
}

technique fullMRThumanskinNV
{
	pass pre
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_1_1 vsFullMRTskinpre(2);
		PixelShader = compile ps_2_0 psFullMRTskinpre();
	}
	pass preshadowed
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_1_1 vsFullMRTskinpreshadowed(2);
		PixelShader = compile ps_2_0 psFullMRTskinpreshadowedNV();
	}
	pass apply
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;

		VertexShader = compile vs_1_1 vsFullMRTskinapply(2);
		PixelShader = compile ps_2_0 psFullMRTskinapply();
	}
}

technique fullMRThumanskin
{
	pass pre
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_1_1 vsFullMRTskinpre(2);
		PixelShader = compile ps_2_0 psFullMRTskinpre();
	}
	pass preshadowed
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_1_1 vsFullMRTskinpreshadowed(2);
		PixelShader = compile ps_2_0 psFullMRTskinpreshadowed();
	}
	pass apply
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;

		VertexShader = compile vs_1_1 vsFullMRTskinapply(2);
		PixelShader = compile ps_2_0 psFullMRTskinapply();
	}
}

