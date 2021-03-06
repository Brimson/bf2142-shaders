
string GenerateStructs[] =
{
    "reqVertexElement",
    "GlobalParameters",
    "TemplateParameters",
    "InstanceParameters"
};

// this is the common vertexElement members
string reqVertexElement[] =
{
     "Position",
     "Normal",
    "Bone4Idcs",
    "Bone2Weights",
    "TBase2D",
    "TangentSpace"
};

// this is the common global parameters
string GlobalParameters[] =
{
    "SpecularPower",
    "FogRange",
    "FogColor"
};


string TemplateParameters[] =
{
    "DiffuseMap",
};

// this is the common instance parameters
string InstanceParameters[] =
{
    "AlphaTest",
    "AlphaTestRef",
    "ObjectSpaceCamPos",
    "Lights",
    "MatBones",
    "WorldViewProjection",
    "World",
    "Transparency",
    "HemiMapConstantColor"
};

#include "shaders/RaCommon.fx"
#include "shaders/RaDefines.fx"
#include "shaders/RaShaderSMCommon.fx"

// Always 2 for now, test with 1!
#define NUMBONES 2

struct SMVariableVSInput
{
    float4   Pos          : POSITION;
    float3   Normal       : NORMAL;
    float BlendWeights : BLENDWEIGHT;
    float4   BlendIndices : BLENDINDICES;
    float2   TexCoord0    : TEXCOORD0;
    float3   Tan          : TANGENT;
};

struct SMVariableVSOutput
{
    float4   Pos  : POSITION;
    float2   Tex0 : TEXCOORD0;
    float Fog : FOG;
};

float getBlendWeight(SMVariableVSInput input, uniform int bone)
{
    if(bone == 0)
        return input.BlendWeights;
    else
        return 1.0 - input.BlendWeights;
}

float4x3 getBoneMatrix(SMVariableVSInput input, uniform int bone)
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
    return 1.0f + IndexArray[2] * -2.0f;
}

float3x3 getTangentBasis(SMVariableVSInput input)
{
    float flip = getBinormalFlipping(input);
    float3 binormal = normalize(cross(input.Tan, input.Normal)) * flip;
    return float3x3(input.Tan, binormal, input.Normal);
}

float3 skinPos(SMVariableVSInput input, float4 Vec, uniform int numBones = NUMBONES)
{
    float3 skinnedPos = mul(Vec, getBoneMatrix(input, 0));
    if(numBones > 1)
    {
        skinnedPos *= getBlendWeight(input, 0);
        skinnedPos += mul(Vec, getBoneMatrix(input, 1)) * getBlendWeight(input, 1);
    }
    return skinnedPos;
}

float3 skinVec(SMVariableVSInput input, float3 Vec, uniform int numBones = NUMBONES)
{
    float3 skinnedVec = mul(Vec, getBoneMatrix(input, 0));
    if(numBones > 1)
    {
        skinnedVec *= getBlendWeight(input, 0);
        skinnedVec += mul(Vec, getBoneMatrix(input, 1)) * getBlendWeight(input, 1);
    }
    return skinnedVec;
}

float3 skinVecToObj(SMVariableVSInput input, float3 Vec, uniform int numBones = NUMBONES)
{
    float3 skinnedVec = mul(Vec, transpose(getBoneMatrix(input, 0)));
    if(numBones > 1)
    {
        skinnedVec *= getBlendWeight(input, 0);
        skinnedVec += mul(Vec, transpose(getBoneMatrix(input, 1))) * getBlendWeight(input, 1);
    }

    return skinnedVec;
}

float3 skinVecToTan(SMVariableVSInput input, float3 Vec, uniform int numBones = NUMBONES)
{
    float3x3 tanBasis = getTangentBasis(input);

    float3x3 toTangent0 = transpose(mul(tanBasis, getBoneMatrix(input, 0)));
    float3 skinnedVec = mul(Vec, toTangent0);

    if(numBones > 1)
    {
        skinnedVec *= getBlendWeight(input, 0);
        float3x3 toTangent1 = transpose(mul(tanBasis, getBoneMatrix(input, 1)));
        skinnedVec += mul(Vec, toTangent1) * getBlendWeight(input, 1);
    }

    return skinnedVec;
}

float4 skinPosition(SMVariableVSInput input)
{
    return float4(skinPos(input, input.Pos), 1);
}

float3 skinNormal(SMVariableVSInput input, uniform int numBones = NUMBONES)
{
    float3 skinnedNormal = skinVec(input, input.Normal);
    if(numBones > 1)
    {
        // Re-normalize skinned normal
        skinnedNormal = normalize(skinnedNormal);
    }
    return skinnedNormal;
}

float4 getWorldPos(SMVariableVSInput input)
{
    return mul(skinPosition(input), World);
}

float3 getWorldNormal(SMVariableVSInput input)
{
    return mul(skinNormal(input), World);
}





SMVariableVSOutput vs(SMVariableVSInput input)
{
    SMVariableVSOutput Out = (SMVariableVSOutput)0;
    float4 objSpacePosition = skinPosition(input);
    Out.Pos = mul(objSpacePosition, WorldViewProjection);
    Out.Tex0 = input.TexCoord0;
    Out.Fog = calcFog(Out.Pos.w);
    return Out;
}

float4 ps_BrokenCamouflage(SMVariableVSOutput input) : COLOR
{
    float3 color = float3(input.Tex0.x,input.Tex0.y, 1.0);
    return float4(color,1.0);
}

float4 ps_Camouflage(SMVariableVSOutput input) : COLOR
{
    return float4(0.0, 0.0, 0.0, 1.0);
}

technique Camouflage
{
    pass
    {
        VertexShader = compile vs_2_0 vs();
        PixelShader = compile ps_2_0 ps_Camouflage();
        ColorWriteEnable = ALPHA;
    }
}

technique BrokenCamouflage
{
    pass
    {
        VertexShader = compile vs_2_0 vs();
        PixelShader = compile ps_2_0 ps_BrokenCamouflage();
    }
}

