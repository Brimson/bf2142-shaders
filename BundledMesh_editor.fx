
float4 diffusePixelShaderMarked(VS_OUTPUT2 input) : COLOR
{
    const float4 ambient = float4(0.0, 0.8, 0.0, 0.0).xxyx;    // def c0,0,0,0.8,0 :: ambient
    // Sampler[0] = <diffuseSampler>;
    float4 diffuseMap = tex2D(diffuseSampler, input.TexCoord); // tex t0
    return saturate(diffuseMap * input.Diffuse + ambient);     // mad_sat r0, t0, v0, c0
}

technique marked
{
    pass p0
    {

        ZEnable = true;
        ZWriteEnable = true;
        // ZWriteEnable = false;
        // FillMode = WIREFRAME;
        CullMode = NONE;
        AlphaBlendEnable = true;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_3_0 diffuseVertexShader(viewProjMatrix,
                                                          viewInverseMatrix,
                                                          lightPos,
                                                          eyePos);
        PixelShader = compile ps_3_0 diffusePixelShaderMarked();
    }
}

float4 diffusePixelShaderSubMarked(VS_OUTPUT2 input) : COLOR
{
    // Sampler[0] = <diffuseSampler>;
    float4 diffuseMap = tex2D(diffuseSampler, input.TexCoord);  // tex t0
    const float4 ambient = float4(0.0, 0.4, 0.0, 0.0);          // def c0,0,0,0.4,0 :: ambient
    return saturate(diffuseMap * input.Diffuse + ambient);      // mad_sat r0, t0, v0, c0
}

technique submarked
{
    pass p0
    {

        ZEnable = true;
        ZWriteEnable = true;
        // ZWriteEnable = false;
        // FillMode = WIREFRAME;
        CullMode = NONE;
        AlphaBlendEnable = false;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_3_0 diffuseVertexShader(viewProjMatrix,
                                                          viewInverseMatrix,
                                                          lightPos,
                                                          eyePos);
        PixelShader = compile ps_3_0 diffusePixelShaderSubMarked();
    }
}

float4 diffusePixelShaderSubPartHighlight() : COLOR
{
    /*
        Previous asm, don't know what the t0 was used for.
        ps.1.1
        def c0,0.2f,0.5f,0.5f,0.45f // ambient
        tex t0
        mov r0, c0
    */
    return float4(0.2f, 0.5f, 0.5f, 0.45f);
}

technique subPartHighlight
<
    int DetailLevel = DLHigh + DLNormal + DLLow + DLAbysmal;
    int Compatibility = CMPR300 + CMPNV2X;
>
{
    pass p0
    {
        // CullMode = NONE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FillMode = SOLID;
        // DepthBias=-0.001;
        // ZEnable = TRUE;
        // ShadeMode = FLAT;
        // ZFunc = EQUAL;
        // FillMode = WIREFRAME;
        ZEnable = TRUE;
        ZFunc = EQUAL;
        ZWriteEnable = FALSE;

        VertexShader = compile vs_3_0 diffuseVertexShader(viewProjMatrix,viewInverseMatrix,lightPos,eyePos);
        PixelShader = compile ps_3_0 diffusePixelShaderSubPartHighlight();
    }
}