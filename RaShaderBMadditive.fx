
#include "shaders/RaCommon.fx"
#include "shaders/RaShaderBMCommon.fx"

string GenerateStructs[] =
{
	"reqVertexElement",
	"GlobalParameters",
	"TemplateParameters",
	"InstanceParameters"
};

string reqVertexElement[] =
{
 	"PositionPacked",
 	"NormalPacked8",
	"Bone4Idcs",
	"TBasePacked2D"
};

//
// this is the common global parameters
//
string GlobalParameters[] =
{
	"ViewProjection",
	"FogRange",
	"FogColor",
	"WorldSpaceCamPos", // should be as an "inverted specialized" instead
	"GlobalTime"
};

//
// this is the common template parameters
//
string TemplateParameters[] =
{
	"DiffuseMap",
	"PosUnpack",
	"TexUnpack",
	"NormalUnpack"
};

//
// this is the common instance parameters
//
string InstanceParameters[] =
{
	"GeomBones",
	"Transparency",
	"simpleUVTranslation",
	"HemiMapConstantColor",
};



struct VS_IN
{
	vec4 Pos			: POSITION;
	vec3 Normal			: NORMAL;
	vec4 BlendIndices	: BLENDINDICES;
	vec2 Tex			: TEXCOORD0;
};


struct VS_OUT
{
	vec4 Pos				: POSITION0;
	vec2 Tex				: TEXCOORD0;
	scalar Fog				: FOG;
};


mat4x3 getSkinnedWorldMatrix(VS_IN input)
{
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;
	return GeomBones[IndexArray[0]];
}

mat3x3 getSkinnedUVMatrix(VS_IN input)
{
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;
	return (mat3x3)UserData.uvMatrix[IndexArray[3]];
}

float getBinormalFlipping(VS_IN input)
{
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;
	return IndexArray[2] * -2.0f + 1.0f;
}

vec4 getWorldPos(VS_IN input)
{
	vec4 unpackedPos = input.Pos * PosUnpack;
	return vec4(mul(unpackedPos, getSkinnedWorldMatrix(input)), 1);
}










VS_OUT vs(VS_IN indata)
{
	VS_OUT Out = (VS_OUT)0;
	vec4 worldPos = getWorldPos(indata);
	Out.Pos = mul(worldPos, ViewProjection);
	Out.Fog = calcFog(Out.Pos.w);
	Out.Tex = indata.Tex * TexUnpack + frac(GlobalTime * simpleUVTranslation); // indata.Tex;
	return Out;
}


float4 ps(VS_OUT indata) : COLOR
{
	vec4 outCol = tex2D(DiffuseMapSampler, indata.Tex);
	outCol.a *= Transparency.a;
	return outCol;
}


technique defaultTechnique
{
	pass P0
	{
		vertexShader	= compile vs_3_0 vs();
		pixelShader		= compile ps_3_0 ps();

		ZEnable				= false;
		AlphaBlendEnable	= true;
		SrcBlend			= SRCALPHA;
		DestBlend			= ONE;
		ZWriteEnable		= false;
		Fogenable			= false;
	}
}

technique depthAndFog
{
	pass P0
	{
		vertexShader	= compile vs_3_0 vs();
		pixelShader		= compile ps_3_0 ps();

		ZEnable				= true;
		AlphaBlendEnable	= true;
		SrcBlend			= SRCALPHA;
		DestBlend			= ONE;
		ZWriteEnable		= false;
		Fogenable			= true;
	}
}



