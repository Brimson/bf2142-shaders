#line 2 "DebugD3DXMeshShapeShader.fx"

float4x4 mWorldViewProj : WorldViewProjection;
float4x4 world : World;

string Category = "Effects\\Lighting";

texture texture0 : TEXLAYER0;
sampler sampler0 = sampler_state
{
    Texture = (texture0);
    AddressU = WRAP;
    AddressV = WRAP;
    MinFilter = ANISOTROPIC;
    MagFilter = LINEAR;
    MaxAnisotropy = 8;
    MipFilter = LINEAR;
};

float TextureScale : TEXTURESCALE;
float4 LhtDir = { 1.0f, 0.0f, 0.0f, 1.0f }; // light Direction
float4 lightDiffuse = { 1.0f, 1.0f, 1.0f, 1.0f }; // Light Diffuse
float4 MaterialAmbient : MATERIALAMBIENT = { 0.5f, 0.5f, 0.5f, 1.0f };
float4 MaterialDiffuse : MATERIALDIFFUSE = { 1.0f, 1.0f, 1.0f, 1.0f };
float4 ConeSkinValues : CONESKINVALUES;

struct APP2VS
{
    float4 Pos    : POSITION;
    float3 Normal : NORMAL;
    float4 Color  : COLOR;
};

struct VS2PS
{
    float4 Pos     : POSITION;
    float4 Diffuse : COLOR;
};

struct VS2PS_Grid
{
    float4 Pos     : POSITION;
    float4 Diffuse : COLOR;
    float2 Tex     : TEXCOORD0;
};

struct PS2FB
{
    float4 Col : COLOR;
};

float3 Diffuse(float3 Normal,uniform float4 lhtDir)
{
    float CosTheta;

    // N.L Clamped
    CosTheta = max(0.0f, dot(Normal, lhtDir.xyz));

    // propogate float result to vector
    return (CosTheta);
}

VS2PS VShader(
    APP2VS indata,
    uniform float4x4 wvp,
    uniform float4 materialAmbient,
    uniform float4 materialDiffuse,
    uniform float4 lhtDir
)
{
    VS2PS outdata;
     float3 Pos;
     Pos = mul(indata.Pos, world);
    outdata.Pos = mul(float4(Pos.xyz, 1.0f), wvp);

    // Lighting. Shade (Ambient + etc.)
    outdata.Diffuse.xyz = materialAmbient.xyz + Diffuse(indata.Normal,lhtDir) * materialDiffuse.xyz;
    outdata.Diffuse.w = MaterialAmbient.a;

    return outdata;
}

VS2PS CM_VShader(
    APP2VS indata,
    uniform float4x4 wvp,
    uniform float4 materialAmbient,
    uniform float4 materialDiffuse,
    uniform float4 lhtDir)
{
    VS2PS outdata;

    float3 Pos;
     Pos = mul(indata.Pos, world);
    outdata.Pos = mul(float4(Pos.xyz, 1.0f), wvp);

    outdata.Diffuse.xyz = materialAmbient.xyz + 0.1f*Diffuse(indata.Normal,float4(-1.f,-1.f,1.f,0.f)) * materialDiffuse.xyz;
    outdata.Diffuse.w = 0.8f;

    return outdata;
}

VS2PS ED_VShader(
    APP2VS indata,
    uniform float4x4 wvp,
    uniform float4 materialAmbient,
    uniform float4 materialDiffuse,
    uniform float4 lhtDir)
{
    VS2PS outdata;

     float4 Pos = indata.Pos;

    float4 tempPos = indata.Pos;
    tempPos.z += 0.5f;
    float radScale = lerp(ConeSkinValues.x, ConeSkinValues.y, tempPos.z);
    Pos.xy *= radScale;

    Pos = mul(Pos, world);
    outdata.Pos = mul(Pos, mWorldViewProj);

    outdata.Diffuse.xyz = materialAmbient.xyz;
    outdata.Diffuse.w = MaterialAmbient.a;

    return outdata;
}

VS2PS VShader2(
    APP2VS indata,
    uniform float4x4 wvp,
    uniform float4 materialAmbient,
    uniform float4 materialDiffuse,
    uniform float4 lhtDir)
{
    VS2PS outdata;
    float3 Pos;
    Pos = mul(indata.Pos, world);
    outdata.Pos = mul(float4(Pos.xyz, 1.0f), wvp);
    outdata.Diffuse.xyz = materialAmbient.xyz;
    outdata.Diffuse.w = 0.3f;
    return outdata;
}

VS2PS_Grid VShader_Grid(
    APP2VS indata,
    uniform float4x4 wvp,
    uniform float4 materialAmbient,
    uniform float4 materialDiffuse,
    uniform float4 lhtDir,
    uniform float textureScale)
{
    VS2PS_Grid outdata;

    float3 Pos;
    Pos = mul(indata.Pos, world);
    outdata.Pos = mul(float4(Pos.xyz, 1.0f), wvp);

    // Lighting. Shade (Ambient + etc.)
    outdata.Diffuse.xyz = materialAmbient.xyz + Diffuse(indata.Normal,lhtDir) * materialDiffuse.xyz;
    outdata.Diffuse.w = MaterialAmbient.a;

    outdata.Tex = indata.Pos.xz * 0.5 + 0.5;
    outdata.Tex *= textureScale;

    return outdata;
}

PS2FB PShader_Grid(VS2PS_Grid indata)
{
    PS2FB outdata;
    float4 tex = tex2D(sampler0, indata.Tex);
    outdata.Col.rgb = tex * indata.Diffuse;
    outdata.Col.a = (1.0 - tex.b);
    return outdata;
}

PS2FB PShader(VS2PS indata)
{
    PS2FB outdata;
    outdata.Col = indata.Diffuse;
    return outdata;
}

VS2PS OccVShader(APP2VS indata, uniform float4x4 wvp)
{
    VS2PS outdata;
    float4 Pos;
    Pos = mul(indata.Pos, world);
    outdata.Pos = mul(Pos, wvp);
    outdata.Diffuse = 1.0;
    return outdata;
}

float4 OccPShader(VS2PS indata) : COLOR
{
    return float4(1.0, 0.5, 0.5, 0.5);
}

PS2FB PShaderMarked(VS2PS indata)
{
    PS2FB outdata;
    outdata.Col = indata.Diffuse;
    return outdata;
}

technique t0
<
    int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
    int Compatibility = CMPR300+CMPNV2X;
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        VertexShader = compile vs_2_0 VShader(mWorldViewProj,MaterialAmbient,MaterialDiffuse,LhtDir);
        PixelShader = compile ps_2_0 PShader();
    }
}

technique occluder
<
    int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
    int Compatibility = CMPR300+CMPNV2X;
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        ZWriteEnable = TRUE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;

        VertexShader = compile vs_2_0 OccVShader(mWorldViewProj);
        PixelShader = compile ps_2_0 OccPShader();
    }
}

technique EditorDebug
<
    int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
    int Compatibility = CMPR300+CMPNV2X;
>
{
    pass p0
    {
        CullMode = NONE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FillMode = SOLID;
        ZWriteEnable = 1;
        ZEnable = TRUE;
        ShadeMode = FLAT;
        ZFunc = LESSEQUAL;


        VertexShader = compile vs_2_0 ED_VShader(mWorldViewProj,MaterialAmbient,MaterialDiffuse,LhtDir);
        PixelShader = compile ps_2_0 PShader();
    }
    pass p1
    {
        CullMode = CW;
        ZEnable = TRUE;
        FillMode = WIREFRAME;

        VertexShader = compile vs_2_0 ED_VShader(mWorldViewProj,MaterialAmbient/2,MaterialDiffuse/2,LhtDir);
        PixelShader = compile ps_2_0 PShader();
    }
}

technique collisionMesh
<
    int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
    int Compatibility = CMPR300+CMPNV2X;
>
{
    pass p0
    {
        CullMode = NONE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        DepthBias = -0.00001;
        ZWriteEnable = 1;
        ZEnable = TRUE;
        ShadeMode = FLAT;
        ZFunc = LESSEQUAL;


        VertexShader = compile vs_2_0 CM_VShader(mWorldViewProj,MaterialAmbient,MaterialDiffuse,LhtDir);
        PixelShader = compile ps_2_0 PShader();
    }
    pass p1
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        ZWriteEnable = 1;
        DepthBias=-0.000018;

        ZEnable = TRUE;
        FillMode = WIREFRAME;

        VertexShader = compile vs_2_0 CM_VShader(mWorldViewProj,MaterialAmbient/2,MaterialDiffuse/2,LhtDir);
        PixelShader = compile ps_2_0 PShader();
    }
    pass p2
    {
        FillMode = SOLID;
    }
}

technique marked
<
    int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
    int Compatibility = CMPR300+CMPNV2X;
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        VertexShader = compile vs_2_0 VShader(mWorldViewProj,MaterialAmbient,MaterialDiffuse,LhtDir);
        PixelShader = compile ps_2_0 PShaderMarked();
    }
}

technique gamePlayObject
<
    int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
    int Compatibility = CMPR300+CMPNV2X;
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        ZEnable = TRUE;

        VertexShader = compile vs_2_0 VShader2(mWorldViewProj,MaterialAmbient,MaterialDiffuse,LhtDir);
        PixelShader = compile ps_2_0 PShader();
    }
}


technique bounding
<
    int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
    int Compatibility = CMPR300+CMPNV2X;
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        ZWriteEnable = 0;
        ZEnable = FALSE;
        CullMode = NONE;
        FillMode = WIREFRAME;

        VertexShader = compile vs_2_0 VShader2(mWorldViewProj,MaterialAmbient,MaterialDiffuse,LhtDir);
        PixelShader = compile ps_2_0 PShaderMarked();
    }
}

technique grid
<
    int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
    int Compatibility = CMPR300+CMPNV2X;
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        VertexShader = compile vs_2_0 VShader_Grid(mWorldViewProj,MaterialAmbient,MaterialDiffuse,LhtDir,TextureScale);
        PixelShader = compile ps_2_0 PShader_Grid();
    }
}

VS2PS vsPivot(APP2VS indata)
{
    VS2PS outdata;
    float4 Pos = indata.Pos;
    float radScale = lerp(ConeSkinValues.x, ConeSkinValues.y, Pos.z+0.5);
    Pos.xy *= radScale;
    Pos = mul(Pos, world);
    outdata.Pos = mul(Pos, mWorldViewProj);

    // Lighting. Shade (Ambient + etc.)
    outdata.Diffuse.rgb = MaterialAmbient.rgb;
    outdata.Diffuse.a = MaterialAmbient.a;

    return outdata;
}

VS2PS vsPivotBox(APP2VS indata)
{
    VS2PS outdata;

    float4 Pos = indata.Pos;
    Pos = mul(Pos, world);
    outdata.Pos = mul(Pos, mWorldViewProj);

    // Lighting. Shade (Ambient + etc.)
    outdata.Diffuse.rgb = MaterialAmbient.rgb;
    outdata.Diffuse.a = MaterialAmbient.a;

    return outdata;
}

VS2PS vsSpotLight(APP2VS indata)
{
    VS2PS outdata;

    float4 Pos = indata.Pos;
    Pos.z += 0.5;
    float radScale = lerp(ConeSkinValues.x, ConeSkinValues.y, Pos.z);
    Pos.xy *= radScale;

    Pos = mul(Pos, world);
    outdata.Pos = mul(Pos, mWorldViewProj);

    // Lighting. Shade (Ambient + etc.)
    outdata.Diffuse.rgb = MaterialAmbient.rgb;
    outdata.Diffuse.a = MaterialAmbient.a;

    return outdata;
}

float4 psSpotLight(VS2PS indata) : COLOR
{
    return indata.Diffuse;
}

technique spotlight
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        CullMode = NONE;
        ColorWriteEnable = 0;
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        VertexShader = compile vs_2_0 vsSpotLight();
        PixelShader = compile ps_2_0 psSpotLight();
    }
    pass p1
    {
        ColorWriteEnable = Red|Blue|Green|Alpha;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        ZFunc = EQUAL;
        ZWriteEnable = FALSE;

        VertexShader = compile vs_2_0 vsSpotLight();
        PixelShader = compile ps_2_0 psSpotLight();
    }
}

technique pivotBox
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        ZWriteEnable = 0;
        ZEnable = FALSE;

        VertexShader = compile vs_2_0 vsPivotBox();
        PixelShader = compile ps_2_0 psSpotLight();
    }
    pass p1
    {
        ColorWriteEnable = Red|Blue|Green|Alpha;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        ZFunc = EQUAL;
        ZWriteEnable = FALSE;

        VertexShader = compile vs_2_0 vsPivotBox();
        PixelShader = compile ps_2_0 psSpotLight();
    }
}

technique pivot
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        ZWriteEnable = 0;
        ZEnable = FALSE;

        VertexShader = compile vs_2_0 vsPivot();
        PixelShader = compile ps_2_0 psSpotLight();
    }
    pass p1
    {
        ColorWriteEnable = Red|Blue|Green|Alpha;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        ZFunc = EQUAL;
        ZWriteEnable = FALSE;

        VertexShader = compile vs_2_0 vsPivot();
        PixelShader = compile ps_2_0 psSpotLight();
    }
}

struct APP2VS_F
{
    float4 Pos : POSITION;
    float4 Col : COLOR;
};

struct VS2PS_F
{
    float4 Pos : POSITION;
    float4 Col : COLOR;
};

VS2PS_F vsFrustum(APP2VS_F indata)
{
    VS2PS_F outdata;
    outdata.Pos = mul(indata.Pos, mWorldViewProj);
    outdata.Col = indata.Col;
    return outdata;
}

float4 psFrustum(VS2PS_F indata, uniform float alphaval) : COLOR
{
    return float4(indata.Col.rgb, indata.Col.a*alphaval);
}

technique wirefrustum
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = ONE;
        ZEnable = TRUE;
        ZFunc = GREATER;
        ZWriteEnable = FALSE;
        CullMode = NONE;
        FillMode = SOLID;

        VertexShader = compile vs_2_0 vsFrustum();
        PixelShader = compile ps_2_0 psFrustum(0.025);
    }
    pass p1
    {
        AlphaBlendEnable = FALSE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = FALSE;
        CullMode = NONE;
        FillMode = SOLID;

        VertexShader = compile vs_2_0 vsFrustum();
        PixelShader = compile ps_2_0 psFrustum(1);
    }
}

technique solidfrustum
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = ONE;
        ZEnable = TRUE;
        ZFunc = GREATER;
        ZWriteEnable = FALSE;
        CullMode = NONE;
        FillMode = SOLID;

        VertexShader = compile vs_2_0 vsFrustum();
        PixelShader = compile ps_2_0 psFrustum(0.25);
    }
    pass p1
    {
        AlphaBlendEnable = FALSE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = FALSE;
        CullMode = NONE;
        FillMode = SOLID;

        VertexShader = compile vs_2_0 vsFrustum();
        PixelShader = compile ps_2_0 psFrustum(1);
    }
}

technique projectorfrustum
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = ONE;

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;

        ZWriteEnable = FALSE;

        VertexShader = compile vs_2_0 vsFrustum();
        PixelShader = compile ps_2_0 psFrustum(1);
    }
}
