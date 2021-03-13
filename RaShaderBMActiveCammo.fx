//#include "shaders/RaCommon.fx"
//#include "shaders/RaShaderBMCommon.fx"

string reqVertexElement[] = {
    "PositionPacked",
    "NormalPacked8",
    "Bone4Idcs",
    "TBasePacked2D"
};

string GlobalParameters[] = {
    "ViewProjection",
};


string InstanceParameters[] = {
    "World",
    "AlphaBlendEnable",
    "DepthWrite",
    "CullMode",
    "AlphaTest",
    "AlphaTestRef",
    "GeomBones",
    "PosUnpack",
    "TexUnpack",
    "NormalUnpack"
};

#define NUM_LIGHTS 1
#define NUM_TEXSETS 1
#define TexBasePackedInd 0

#include "shaders/RaCommon.fx"
#include "shaders/RaDefines.fx"
#include "shaders/RaShaderBMCommon.fx"

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
    vec4 HPos : POSITION;
    vec2 Tex1 : TEXCOORD0;
};

mat4x3 getSkinnedWorldMatrix(BMVariableVSInput input)
{
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;
    return GeomBones[IndexArray[0]];
}

vec4 getWorldPos(BMVariableVSInput input)
{
    vec4 unpackedPos = input.Pos * PosUnpack;
    return vec4(mul(unpackedPos, getSkinnedWorldMatrix(input)), 1.0);
}

BMVariableVSOutput vs(BMVariableVSInput input)
{
    BMVariableVSOutput Out = (BMVariableVSOutput)0;

    Out.HPos = mul(getWorldPos(input), ViewProjection);	// output HPOS
    Out.Tex1 = input.TexDiffuse * TexUnpack;
    return Out;
}


float4 ps(BMVariableVSOutput indata) : COLOR
{
    return vec2(0.0, 1.0).xxxy;
}

float4 ps_brokenCamo(BMVariableVSOutput indata) : COLOR
{
    return vec4(indata.Tex1, 1.0, 1.0);
}

technique defaultTechnique
{
    pass P0
    {
        vertexShader = compile vs_2_0 vs();
        pixelShader = compile ps_2_0 ps();

        #ifdef ENABLE_WIREFRAME
            FillMode = WireFrame;
        #endif
        ColorWriteEnable = ALPHA;

    }
}

technique BrokenCamouflage
{
    pass P0
    {
        vertexShader = compile vs_2_0 vs();
        pixelShader = compile ps_2_0 ps_brokenCamo();

        #ifdef ENABLE_WIREFRAME
            FillMode = WireFrame;
        #endif
    }
}