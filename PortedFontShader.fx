
float4 alpha : BLENDALPHA;
texture texture0: TEXLAYER0;
sampler sampler0 = sampler_state
{
    Texture = (texture0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

struct APP2VS
{
    float4 HPos : POSITION;
    float3 Col : COLOR;
    float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS
{
    float4 HPos : POSITION;
    float3 Col : COLOR;
    float2 Tex0 : TEXCOORD0;
};

VS2PS HPosVS(APP2VS indata)
{
    VS2PS outdata;
    outdata.HPos = indata.HPos;
    outdata.Col = indata.Col;
    outdata.Tex0 = indata.TexCoord0;
    return outdata;
}

technique Text_States <bool Restore = true;> {
    pass BeginStates {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        // SrcBlend = INVSRCCOLOR;
        // DestBlend = SRCCOLOR;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
    }

    pass EndStates { }
}

float4 HPosPS(VS2PS input) : COLOR
{
    const float4 rgb = float2(1.0, 0.0).xxxy; // def c0, 1, 1, 1, 0
    float4 o = tex2D(sampler0, input.Tex0); // tex t0
    o = dot(o, rgb); // dp3 r0, t0, c0
    o.rgb *= input.Col; // mul r0.rgb, t0, v0
    return o;
}

technique Text <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_POSITION, 0,
        0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0,
        0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        Texture[0] = (texture0);
        AddressU[0] = CLAMP;
        AddressV[0] = CLAMP;
        MipFilter[0] = LINEAR;
        MinFilter[0] = LINEAR;
        MagFilter[0] = LINEAR;

        VertexShader = compile vs_3_0 HPosVS();
        PixelShader = compile ps_3_0 HPosPS();
    }
}

technique Overlay_States <bool Restore = true;> {
    pass BeginStates {
        CullMode = NONE;
        ZEnable = FALSE;

        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
    }

    pass EndStates {
    }
}

technique Overlay <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_POSITION, 0,
        0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0,
        0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0,
        DECLARATION_END	// End macro
    };
    int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
    pass p0
    {
        TextureFactor = (alpha);
        Texture[0] = (texture0);
        AddressU[0] = WRAP;
        AddressV[0] = WRAP;
        MipFilter[0] = LINEAR;
        MinFilter[0] = LINEAR;
        MagFilter[0] = LINEAR;

        ColorOp[0] = SELECTARG1;
        ColorArg1[0] = TEXTURE;
        AlphaOp[0] = MODULATE;
        AlphaArg1[0] = TEXTURE;
        AlphaArg2[0] = TFACTOR;
        ColorOp[1] = DISABLE;
        AlphaOp[1] = DISABLE;

        VertexShader = compile vs_3_0 HPosVS();
        PixelShader = NULL;
    }
}
