
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

// this is the common global parameters
string GlobalParameters[] =
{
    "ViewProjection",
    "FogRange",
    "FogColor",
    "WorldSpaceCamPos", // should be as an "inverted specialized" instead
    "GlobalTime"
};

// this is the common template parameters
string TemplateParameters[] =
{
    "DiffuseMap",
    "PosUnpack",
    "TexUnpack",
    "NormalUnpack"
};

// this is the common instance parameters
string InstanceParameters[] =
{
    "GeomBones",
    "Transparency",
    "simpleUVTranslation",
    "HemiMapConstantColor",
};

struct VS_IN
{
    float4 Pos          : POSITION;
    float3 Normal       : NORMAL;
    float4 BlendIndices : BLENDINDICES;
    float2 Tex          : TEXCOORD0;
};

struct VS_OUT
{
    float4 Pos   : POSITION0;
    float2 Tex   : TEXCOORD0;
    float Fog : FOG;
};

float4x3 getSkinnedWorldMatrix(VS_IN input)
{
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;
    return GeomBones[IndexArray[0]];
}

float3x3 getSkinnedUVMatrix(VS_IN input)
{
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;
    return (float3x3)UserData.uvMatrix[IndexArray[3]];
}

float getBinormalFlipping(VS_IN input)
{
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;
    return 1.0f + IndexArray[2] * -2.0f;
}

float4 getWorldPos(VS_IN input)
{
    float4 unpackedPos = input.Pos * PosUnpack;
    return float4(mul(unpackedPos, getSkinnedWorldMatrix(input)), 1);
}





VS_OUT vs(VS_IN indata)
{
    VS_OUT Out = (VS_OUT)0;
    float4 worldPos = getWorldPos(indata);
    Out.Pos = mul(worldPos, ViewProjection);
    Out.Fog = calcFog(Out.Pos.w);
    Out.Tex = indata.Tex * TexUnpack + frac(GlobalTime * simpleUVTranslation);
    return Out;
}

float4 ps(VS_OUT indata) : COLOR
{
    float4 outCol = tex2D(DiffuseMapSampler, indata.Tex);
    outCol.a *= Transparency.a;
    return outCol;
}

technique defaultTechnique
{
    pass P0
    {
        vertexShader = compile vs_2_0 vs();
        pixelShader  = compile ps_2_0 ps();

        ZEnable          = false;
        AlphaBlendEnable = true;
        SrcBlend         = SRCALPHA;
        DestBlend        = ONE;
        ZWriteEnable     = false;
        Fogenable        = false;
    }
}

technique depthAndFog
{
    pass P0
    {
        vertexShader = compile vs_2_0 vs();
        pixelShader  = compile ps_2_0 ps();

        ZEnable          = true;
        AlphaBlendEnable = true;
        SrcBlend         = SRCALPHA;
        DestBlend        = ONE;
        ZWriteEnable     = false;
        Fogenable        = true;

    }
}
