#include "Shaders/Math.fx"

float4x4 World;
float4x4 ViewProjection;
int textureFactor = 0xffAFFFaF;
bool alphaBlendEnable = false;

// VS/PS

string reqVertexElement[] =
{
    "Position"
};

float4 vertexShader(float3 inPos: POSITION0) : POSITION0
{
    return mul1(inPos, mul(World, ViewProjection));
}

float4 shader() : COLOR
{
    return float4(0.9, 0.4, 0.8, 1.0);
};

struct VS_OUTPUT
{
    float4 Pos	: POSITION0;
};

string InstanceParameters[] =
{
    "World",
    "ViewProjection"
};

technique defaultShader
{
    pass P0
    {
        vertexShader = compile vs_2_0 vertexShader();
        pixelshader  = compile ps_2_0 shader();
        #ifdef ENABLE_WIREFRAME
            FillMode = WireFrame;
        #endif
        SrcBlend  = srcalpha;
        DestBlend = invsrcalpha;
        fogenable = false;
        CullMode  = NONE;
        AlphaBlendEnable= <alphaBlendEnable>;
        AlphaTestEnable = false;
    }
}
