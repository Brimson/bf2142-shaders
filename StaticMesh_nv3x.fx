#line 2 "StaticMesh_nv3x.fx"

// Light stuff

struct appdata_ZOnly
{
    float4 Pos          : POSITION;
    float4 BlendIndices : BLENDINDICES;
};

struct VS_OUT_Base2
{
    float4 HPos : POSITION;
    float4 col  : DIFFUSE;
};

// VS_OUT_Base2 vsZOnly(appdata_ZOnly input)
float4 vsZOnly(appdata_ZOnly input) : POSITION
{
    float3 Pos = input.Pos;
    return mul(float4(Pos.xyz, 1.0f), viewProjMatrix);
}

float4 psZOnly() : COLOR
{
    return float4(0.0, 0.0, 0.0, 1.0);
}

technique ZOnly
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = 0;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_0 vsZOnly();
        PixelShader = compile ps_2_0 psZOnly();
    }
}


struct appdata_Base
{
    float4 Pos          : POSITION;
    float4 BlendIndices : BLENDINDICES;
};

struct VS_OUT_Base
{
    float4 HPos : POSITION;
};

VS_OUT_Base vsBase(appdata_Base input)
{
    VS_OUT_Base Out;
    Out.HPos = mul(input.Pos, transpose(viewProjMatrix));
    return Out;
}

float4 psBase(VS_OUT_Base indata) : COLOR
{
    return 0.5;
}

float4 psBaseAT(VS_OUT_Base indata) : COLOR
{
    float4 baseAT = 1.0;
    return baseAT.a;
}

technique ZOnlyBaseAT
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = 0;
        AlphaTestEnable = TRUE;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_0 vsBase();
        PixelShader = compile ps_2_0 psBaseAT();
     }
}

technique OnePassbase
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBase();
        PixelShader = compile ps_2_0 psBase();
    }
}

technique OnePassbasealpha
{
    pass p0
    {
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        VertexShader = compile vs_2_0 vsBase();
        PixelShader = compile ps_2_0 psBase();
    }
}


struct appdata_BaseLM
{
    float4 Pos          : POSITION;
    float4 BlendIndices : BLENDINDICES;
    float2 TexCoordDiff : TEXCOORD0;
    float2 TexCoordLMap : TEXCOORD1;
};

struct VS_OUT_BaseLM
{
    float4 HPos     : POSITION;
    float2 Tex0Diff : TEXCOORD0;
    float2 Tex1LMap : TEXCOORD1;
};

VS_OUT_BaseLM vsBaseLM(appdata_BaseLM input)
{
    VS_OUT_BaseLM Out;

    Out.HPos = mul(input.Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1LMap = (input.TexCoordLMap*lightmapOffset.xy) + lightmapOffset.zw;
    return Out;
}


float4 psBaseLM(VS_OUT_BaseLM indata) : COLOR
{
    return tex2D(samplerWrap1, indata.Tex1LMap) * tex2D(samplerWrap0, indata.Tex0Diff);
}

technique OnePassbaseLM
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseLM();
        PixelShader = compile ps_2_0 psBaseLM();
    }
}

struct appdata_BaseDetail
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
};

struct VS_OUT_BaseDetail
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
};

VS_OUT_BaseDetail vsBaseDetail(appdata_BaseDetail input)
{
    VS_OUT_BaseDetail Out;

    Out.HPos = mul(input.Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    return Out;
}

float4 psBaseDetail(VS_OUT_BaseDetail indata) : COLOR
{
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 base = tex2D(samplerWrap0, indata.Tex0Diff);
    // AddSigned
    // float4 color = base + ((detail * detail.a)-0.5);
    // Just plain Mul
    float4 color = base * detail;
    color.a = detail.a;
    return color;
}

technique OnePassbasedetail
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetail();
        PixelShader = compile ps_2_0 psBaseDetail();
    }
}

struct appdata_BaseDetailLM
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordLMap   : TEXCOORD2;
};

struct VS_OUT_BaseDetailLM
{
    float4 HPos         : POSITION;
    float2 Tex0Diff     : TEXCOORD0;
    float2 Tex1Detail   : TEXCOORD1;
    float2 Tex2LMap     : TEXCOORD2;
};

VS_OUT_BaseDetailLM vsBaseDetailLM(appdata_BaseDetailLM input)
{
    VS_OUT_BaseDetailLM Out;

    Out.HPos = mul(input.Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2LMap = input.TexCoordLMap * lightmapOffset.xy + lightmapOffset.zw;
    return Out;
}

float4 psBaseDetailLM(VS_OUT_BaseDetailLM indata) : COLOR
{
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 base = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 lightmap = tex2D(samplerWrap2, indata.Tex2LMap);
    // AddSigned
    //float4 color = base + ((detail * detail.a)-0.5);
    // Just MUL
    //return float4(indata.Tex2LMap.x,indata.Tex2LMap.y,0,1);
    float4 color = base * detail * lightmap;
    color.a = detail.a;
    return color;
}

technique OnePassbasedetailLM
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailLM();
        PixelShader = compile ps_2_0 psBaseDetailLM();
    }
}

struct appdata_BaseDetailDirt
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordDirt   : TEXCOORD2;
};

struct VS_OUT_BaseDetailDirt
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Dirt   : TEXCOORD2;
};

VS_OUT_BaseDetailDirt vsBaseDetailDirt(appdata_BaseDetailDirt input)
{
    VS_OUT_BaseDetailDirt Out;

    Out.HPos = mul(input.Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Dirt = input.TexCoordDirt;
    return Out;
}

float4 psBaseDetailDirt(VS_OUT_BaseDetailDirt indata) : COLOR
{
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 base = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 dirt = tex2D(samplerWrap2, indata.Tex2Dirt);
    // AddSigned
    float4 color = base * detail * dirt;
    color.a = detail.a;
    return color;
}

technique OnePassbasedetaildirt
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailDirt();
        PixelShader = compile ps_2_0 psBaseDetailDirt();
    }
}

struct appdata_BaseDetailDirtLM
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordDirt   : TEXCOORD2;
    float2 TexCoordLMap   : TEXCOORD3;
};

struct VS_OUT_BaseDetailDirtLM
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Dirt   : TEXCOORD2;
    float2 Tex3LMap   : TEXCOORD3;
};

VS_OUT_BaseDetailDirtLM vsBaseDetailDirtLM(appdata_BaseDetailDirtLM input)
{
    VS_OUT_BaseDetailDirtLM Out;

    Out.HPos = mul(input.Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Dirt = input.TexCoordDirt;
    Out.Tex3LMap = input.TexCoordLMap*lightmapOffset.xy + lightmapOffset.zw;
    return Out;
}

float4 psBaseDetailDirtLM(VS_OUT_BaseDetailDirtLM indata) : COLOR
{
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 base = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 dirt = tex2D(samplerWrap2, indata.Tex2Dirt);
    float4 lightmap = tex2D(samplerWrap3, indata.Tex3LMap);
    // AddSigned
    float4 color = base * detail * dirt * lightmap;
    color.a = detail.a;
    return color;
}

technique OnePassbasedetaildirtLM
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailDirtLM();
        PixelShader = compile ps_2_0 psBaseDetailDirtLM();
    }
}

struct appdata_BaseDetailCrack
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordCrack  : TEXCOORD2;
};

struct VS_OUT_BaseDetailCrack
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Crack  : TEXCOORD2;
};

VS_OUT_BaseDetailCrack vsBaseDetailCrack(appdata_BaseDetailCrack input)
{
    VS_OUT_BaseDetailCrack Out;

    Out.HPos = mul(input.Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Crack = input.TexCoordCrack;
    return Out;
}

float4 psBaseDetailCrack(VS_OUT_BaseDetailCrack indata) : COLOR
{
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 base = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 crack = tex2D(samplerWrap2, indata.Tex2Crack);

    float4 color = base * detail * (1.0 - crack.a);
    color.rgb = crack.rgb * crack.a + color.rgb;
    color.a = detail.a;
    return color;
}

technique OnePassbasedetailcrack
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailCrack();
        PixelShader = compile ps_2_0 psBaseDetailCrack();
    }
}

struct appdata_BaseDetailCrackLM
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordCrack  : TEXCOORD2;
    float2 TexCoordLMap   : TEXCOORD3;
};

struct VS_OUT_BaseDetailCrackLM
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Crack  : TEXCOORD2;
    float2 Tex3LMap   : TEXCOORD3;
};

VS_OUT_BaseDetailCrackLM vsBaseDetailCrackLM(appdata_BaseDetailCrackLM input)
{
    VS_OUT_BaseDetailCrackLM Out;

    Out.HPos = mul(input.Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Crack = input.TexCoordCrack;
    Out.Tex3LMap = input.TexCoordLMap * lightmapOffset.xy + lightmapOffset.zw;
    return Out;
}

float4 psBaseDetailCrackLM(VS_OUT_BaseDetailCrackLM indata) : COLOR
{
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 base = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 crack = tex2D(samplerWrap2, indata.Tex2Crack);
    float4 lightmap = tex2D(samplerWrap3, indata.Tex3LMap);
    float4 color = base * detail * (1.0 - crack.a);
    color.rgb = crack.rgb * crack.a + color.rgb;
    color.rgb = color.rgb * lightmap.rgb;
    color.a = detail.a;
    return color;
}

technique OnePassbasedetailcrackLM
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailCrackLM();
        PixelShader = compile ps_2_0 psBaseDetailCrackLM();
    }
}

struct appdata_BaseDetailDirtCrack
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordDirt   : TEXCOORD2;
    float2 TexCoordCrack  : TEXCOORD3;
};

struct VS_OUT_BaseDetailDirtCrack
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Dirt   : TEXCOORD2;
    float2 Tex3Crack  : TEXCOORD3;
};

VS_OUT_BaseDetailDirtCrack vsBaseDetailDirtCrack(appdata_BaseDetailDirtCrack input)
{
    VS_OUT_BaseDetailDirtCrack Out;

    Out.HPos = mul(input.Pos, viewProjMatrix);
    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Dirt = input.TexCoordDirt;
    Out.Tex3Crack = input.TexCoordCrack;
    return Out;
}

float4 psBaseDetailDirtCrack(VS_OUT_BaseDetailDirtCrack indata) : COLOR
{
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 base = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 dirt = tex2D(samplerWrap2, indata.Tex2Dirt);
    float4 crack = tex2D(samplerWrap3, indata.Tex3Crack);

    float4 color = base * detail * dirt * (1-crack.a);
    color.rgb = crack.rgb*crack.a + color.rgb;
    color.a = detail.a;
    return color;
}

technique OnePassbasedetaildirtcrack
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailDirtCrack();
        PixelShader = compile ps_2_0 psBaseDetailDirtCrack();
    }
}

struct appdata_BaseDetailDirtCrackLM
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordDirt   : TEXCOORD2;
    float2 TexCoordCrack  : TEXCOORD3;
    float2 TexCoordLMap   : TEXCOORD4;
};

struct VS_OUT_BaseDetailDirtCrackLM
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Dirt   : TEXCOORD2;
    float2 Tex3Crack  : TEXCOORD3;
    float2 Tex4LMap   : TEXCOORD4;
};

VS_OUT_BaseDetailDirtCrackLM vsBaseDetailDirtCrackLM(appdata_BaseDetailDirtCrackLM input)
{
    VS_OUT_BaseDetailDirtCrackLM Out;

    Out.HPos = mul(input.Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Dirt = input.TexCoordDirt;
    Out.Tex3Crack = input.TexCoordCrack;
    Out.Tex4LMap = (input.TexCoordLMap * lightmapOffset.xy) + lightmapOffset.zw;
    return Out;
}

float4 psBaseDetailDirtCrackLM(VS_OUT_BaseDetailDirtCrackLM indata) : COLOR
{
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 base = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 dirt = tex2D(samplerWrap2, indata.Tex2Dirt);
    float4 crack = tex2D(samplerWrap3, indata.Tex3Crack);
    float4 lightmap = tex2D(samplerWrap4, indata.Tex4LMap);

    float4 color = base * detail * dirt * (1.0 - crack.a);
    color.rgb = crack.rgb*crack.a + color.rgb;
    color.rgb = color.rgb * lightmap.rgb;
    color.a = detail.a;
    return color;
}

technique OnePassbasedetaildirtcrackLM
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailDirtCrackLM();
        PixelShader = compile ps_2_0 psBaseDetailDirtCrackLM();
    }
}



struct appdata_LightmapOnly
{
    float4 Pos          : POSITION;
    float4 BlendIndices : BLENDINDICES;
    float2 TexCoordLMap : TEXCOORD0;
};

struct VS_OUT_LightmapOnly
{
    float4 HPos : POSITION;
    float2 Tex0 : TEXCOORD0;
};

VS_OUT_LightmapOnly vsLightmapOnly(appdata_LightmapOnly input)
{
    VS_OUT_LightmapOnly Out;

    Out.HPos = mul(input.Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0 = (input.TexCoordLMap*lightmapOffset.xy) + lightmapOffset.zw;

    return Out;
}

float4 psLightmapOnly(VS_OUT_LightmapOnly indata) : COLOR
{
    return tex2D(samplerWrap0, indata.Tex0);
}

technique LightmapOnly
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_BLENDINDICES, 0},
        { 1, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsLightmapOnly();
        PixelShader = compile ps_2_0 psLightmapOnly();
    }
}


struct appdata_Light
{
    float4 Pos          : POSITION;
    float4 BlendIndices : BLENDINDICES;
    float4 Normal       : NORMAL;
};

struct VS_OUT_PointLight
{
    float4 HPos  : POSITION;
    float4 Color : COLOR;
};

VS_OUT_PointLight vsPointLight(appdata_Light input)
{
    VS_OUT_PointLight Out;

    float3 wPos = input.Pos;
    Out.HPos = mul(float4(wPos.xyz, 1.0f), viewProjMatrix);

    float3 wNormal = input.Normal;
    Out.Color = float4(calcPVPoint(pointLight, wPos, wNormal), 1);
    return Out;
}

float4 psPointLight(VS_OUT_PointLight indata) : COLOR
{
    return indata.Color;
}

technique PointLight
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 1, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZWriteEnable = FALSE;
        ZFunc = EQUAL;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;

        VertexShader = compile vs_2_0 vsPointLight();
        PixelShader = compile ps_2_0 psPointLight();
    }
}

struct VS_OUT_SpotLight {
    float4 HPos     : POSITION;
    float4 Color    : COLOR;
};

VS_OUT_SpotLight vsSpotLight(appdata_Light input)
{
    VS_OUT_SpotLight Out;

    float3 wPos = input.Pos;
    Out.HPos = mul(float4(wPos.xyz, 1.0f), viewProjMatrix);

    float3 wNormal = input.Normal;
    Out.Color = float4(calcPVSpot(spotLight, wPos, wNormal), 1);

    return Out;
}

float4 psSpotLight(VS_OUT_SpotLight indata) : COLOR
{
    return indata.Color;
}

technique SpotLight
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 1, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZWriteEnable = FALSE;
        ZFunc = EQUAL;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;

        VertexShader = compile vs_2_0 vsSpotLight();
        PixelShader = compile ps_2_0 psSpotLight();
    }
}

technique base
{
    pass p0
    {
        ZWriteEnable = FALSE;
        ZFunc = ALWAYS; // EQUAL;

        AlphaBlendEnable = FALSE;
        SrcBlend = DESTCOLOR;
        DestBlend = ZERO;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBase();
        PixelShader = compile ps_2_0 psBase();
    }
}

technique basedetail
{
    pass p0
    {
        ZWriteEnable = FALSE;
        ZFunc = EQUAL;

        AlphaBlendEnable = TRUE;
        SrcBlend = DESTCOLOR;
        DestBlend = ZERO;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetail();
        PixelShader = compile ps_2_0 psBaseDetail();
    }
}

technique basedetaildirt
{
    pass p0
    {
        ZWriteEnable = FALSE;
        ZFunc = EQUAL;

        AlphaBlendEnable = TRUE;
        SrcBlend = DESTCOLOR;
        DestBlend = ZERO;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailDirt();
        PixelShader = compile ps_2_0 psBaseDetailDirt();
    }
}

technique basedetailcrack
{
    pass p0
    {
        ZWriteEnable = FALSE;
        ZFunc = EQUAL;

        AlphaBlendEnable = TRUE;
        SrcBlend = DESTCOLOR;
        DestBlend = ZERO;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailCrack();
        PixelShader = compile ps_2_0 psBaseDetailCrack();
    }
}

technique basedetaildirtcrack
{
    pass p0
    {
        ZWriteEnable = FALSE;
        ZFunc = EQUAL;

        AlphaBlendEnable = TRUE;
        SrcBlend = DESTCOLOR;
        DestBlend = ZERO;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailDirtCrack();
        PixelShader = compile ps_2_0 psBaseDetailDirtCrack();
    }
}

