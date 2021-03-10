
// vec4	PosUnpack : POSUNPACK;
// float TexUnpack : TEXUNPACK;

struct VS_OUT_LightmapGen {
    vec4 HPos       : POSITION;
    vec2 Tex0Diff   : TEXCOORD0;
};

struct appdata_LightmapGen {
    vec4 Pos : POSITION;
    vec2 TexCoordDiff : TEXCOORD0;
};

VS_OUT_LightmapGen vsLightmapBase(appdata_LightmapGen input)
{
    VS_OUT_LightmapGen Out;

    // Compensate for lack of UBYTE4 on Geforce3
    // int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    // int IndexArray[4] = (int[4])IndexVector;

    vec4 Pos = input.Pos  * PosUnpack;//mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(float4(Pos.xyz, 1.0f), viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff * TexUnpack;
    return Out;
}

struct appdata_LightmapGen2 {
    vec4 Pos : POSITION;
    vec3 Normal : NORMAL;
    vec2 TexCoordDiff : TEXCOORD0;
};

VS_OUT_LightmapGen vsLightmapBase2(appdata_LightmapGen2 input)
{
    VS_OUT_LightmapGen Out;

    // Compensate for lack of UBYTE4 on Geforce3
    // int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    // int IndexArray[4] = (int[4])IndexVector;

    vec4 Pos = input.Pos * PosUnpack;//mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(float4(Pos.xyz, 1.0f), viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff * TexUnpack;
    return Out;
}

float4 psLightmapGen(VS_OUT_LightmapGen indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);
    color.rgb = 0;
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

        VertexShader = compile vs_3_0 vsLightmapBase();
        PixelShader = compile ps_3_0 psLightmapGen();
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

        VertexShader = compile vs_3_0 vsLightmapBase2();
        PixelShader = compile ps_3_0 psLightmapGen();
    }
}

float4 psLightmapBase() : COLOR
{
    /*
        Original asm
        ps.1.1
        def c0,0,0,0,1
        mov r0, c0 // Output pure black color for lightmap generation
    */
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

        VertexShader = compile vs_3_0 vsLightmapBase();
        PixelShader = compile ps_3_0 psLightmapBase();
    }
}