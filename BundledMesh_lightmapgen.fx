
float4 blackColor() : COLOR
{
    return float4(0.0, 0.0, 0.0, 1.0);
}

technique lightmapGeneration
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = true;
        AlphaBlendEnable = false;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_0 bumpSpecularVertexShaderBlinn1(viewProjMatrix,
                                                                     viewInverseMatrix,
                                                                     lightPos);
        PixelShader = compile ps_2_0 blackColor();
    }
}
