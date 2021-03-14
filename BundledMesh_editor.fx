
float4 diffusePixelShader_marked(VS_OUTPUT2 input) : COLOR
{
    const float4 ambient = float4(0.0, 0.0, 0.8, 0.0);
    float4 diffuse = tex2D(diffuseSampler, input.TexCoord);
    return saturate(diffuse * input.Diffuse + ambient);
}

float4 diffusePixelShader_submarked(VS_OUTPUT2 input) : COLOR
{
    const float4 ambient = float4(0.0, 0.0, 0.4, 0.0);
    float4 diffuse = tex2D(diffuseSampler, input.TexCoord);
    return saturate(diffuse * input.Diffuse + ambient);
}

float4 diffusePixelShader_subPartHighlight(VS_OUTPUT2 input) : COLOR
{
    const float4 ambient = float4(0.2f, 0.5f, 0.5f, 0.45f);
    float4 diffuse = tex2D(diffuseSampler, input.TexCoord);
    return saturate(diffuse * input.Diffuse + ambient);
}

technique marked
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = true;
        CullMode = NONE;
        AlphaBlendEnable = true;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_0 diffuseVertexShader(viewProjMatrix,
                                                          viewInverseMatrix,
                                                          lightPos,
                                                          eyePos);
        PixelShader = compile ps_2_0 diffusePixelShader_marked();
    }
}

technique submarked
{
    pass p0
    {

        ZEnable = true;
        ZWriteEnable = true;
        CullMode = NONE;
        AlphaBlendEnable = false;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_0 diffuseVertexShader(viewProjMatrix,
                                                          viewInverseMatrix,
                                                          lightPos,
                                                          eyePos);
        PixelShader = compile ps_2_0 diffusePixelShader_submarked();
    }
}

technique subPartHighlight
<
    int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
    int Compatibility = CMPR300+CMPNV2X;
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FillMode = SOLID;
        ZEnable = TRUE;
        ZFunc = EQUAL;
        ZWriteEnable = FALSE;

        VertexShader = compile vs_2_0 diffuseVertexShader(viewProjMatrix,
                                                          viewInverseMatrix,
                                                          lightPos,
                                                          eyePos);
        PixelShader = compile ps_2_0 diffusePixelShader_subPartHighlight();
    }
}
