struct VS_OUT_LightmapGen
{
    float4 HPos     : POSITION;
    float2 Tex0Diff : TEXCOORD0;
};

struct appdata_LightmapGen
{
    float4 Pos          : POSITION;
    float2 TexCoordDiff : TEXCOORD0;
};

VS_OUT_LightmapGen vsLightmapBase(appdata_LightmapGen input)
{
    VS_OUT_LightmapGen Out;

    float4 Pos = input.Pos  * PosUnpack;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff * TexUnpack;
    return Out;
}

struct appdata_LightmapGen2
{
    float4 Pos          : POSITION;
    float3 Normal       : NORMAL;
    float2 TexCoordDiff : TEXCOORD0;
};

VS_OUT_LightmapGen vsLightmapBase2(appdata_LightmapGen2 input)
{
    VS_OUT_LightmapGen Out;
    float4 Pos = input.Pos * PosUnpack;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff * TexUnpack;
    return Out;
}

float4 psLightmapGen(VS_OUT_LightmapGen indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);
    color.rgb = 0.0;
    return color; // output only alpha
}

technique lightmapGenerationAlphaTest
{
    pass p0
    {
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ZEnable = true;
        ZWriteEnable = true;
        AlphaBlendEnable = false;
        CullMode = NONE;

        VertexShader = compile vs_2_0 vsLightmapBase();
        PixelShader = compile ps_2_0 psLightmapGen();
    }

    pass p1
    {
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ZEnable = true;
        ZWriteEnable = true;
        AlphaBlendEnable = false;
        CullMode = NONE;

        VertexShader = compile vs_2_0 vsLightmapBase2();
        PixelShader = compile ps_2_0 psLightmapGen();
    }
}

float4 psLightmapBase() : COLOR
{
    // Output pure black color for lightmap generation
    return float4(0.0, 0.0, 0.0, 1.0);
}

technique lightmapGeneration
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = true;
        AlphaBlendEnable = false;
        AlphaTestEnable = false;
        AlphaRef = 0;
        AlphaFunc = GREATER;
        CullMode = NONE;

        VertexShader = compile vs_2_0 vsLightmapBase();
        PixelShader = compile ps_2_0 psLightmapBase();
    }
}
