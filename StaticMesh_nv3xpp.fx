#line 2 "StaticMesh_nv3xpp.fx"

struct appdata_Basendetail
{
    float4 Pos          : POSITION;
    float4 BlendIndices : BLENDINDICES;
    float3 Normal       : NORMAL;
    float2 TexCoordDiff : TEXCOORD0;
    float3 Tan          : TANGENT;
};

struct VS_OUT_Basendetail
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Normal : TEXCOORD1;
    float3 LightVec   : TEXCOORD2;
    float3 HalfVec    : TEXCOORD3;
};

void vsBumpSpecularBlinn(float3 Normal, float3 Tan, float3 Pos, int Index, out float3 LightVec, out float3 HalfVec)
{
    // Cross product to create BiNormal
    float3 binormal = normalize(cross(Tan, Normal));

    // Need to calculate the WorldI based on each matBone skinning world matrix
    float3x3 TanBasis = float3x3(Tan, binormal, Normal);

    // Calculate WorldTangent directly... inverse is the transpose for affine rotations
    float3x3 worldI = TanBasis;
    worldI = transpose(mul(worldI, worldMatrix));

    // Transform Light dir to Object space
    float3 normalizedTanLightVec = normalize(mul(-lightDir, worldI));

    LightVec = normalizedTanLightVec;

    // Transform eye pos to tangent space
    float3 worldPos = mul(Pos, worldMatrix);
    float3 worldEyeVec = eyePos - worldPos;
    float3 tanEyeVec = mul(worldEyeVec, worldI);

    HalfVec = (normalizedTanLightVec + normalize(tanEyeVec))*0.5;
}

VS_OUT_Basendetail vsBasendetail(appdata_Basendetail input)
{
    VS_OUT_Basendetail Out;

    float3 Pos = input.Pos;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Normal = input.TexCoordDiff;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psBasendetail(VS_OUT_Basendetail indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 expandedNormal = tex2D(samplerWrap1, indata.Tex1Normal);
    expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;

    float2 intensityuv = float2(dot(normalize(indata.LightVec),expandedNormal), dot(normalize(indata.HalfVec),expandedNormal));
    float4 intensity = tex2D(samplerClamp2, intensityuv);

    float4 outColor;
    outColor.rgb = intensity * sunColor * color + intensity.a*expandedNormal.a*dot(sunColor, 0.33);
    outColor.a = color.a;
    return outColor;
}

technique OnePassbasendetail
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBasendetail();
        PixelShader = compile ps_2_0 psBasendetail();
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


struct appdata_BaseLMndetail
{
    float4 Pos          : POSITION;
    float4 BlendIndices : BLENDINDICES;
    float3 Normal       : NORMAL;
    float2 TexCoordDiff : TEXCOORD0;
    float2 TexCoordLMap : TEXCOORD1;
    float3 Tan          : TANGENT;
};

struct VS_OUT_BaseLMndetail
{
    float4 HPos     : POSITION;
    float2 Tex0Diff : TEXCOORD0;
    float2 Tex1LMap : TEXCOORD1;
    float3 LightVec : TEXCOORD2;
    float3 HalfVec  : TEXCOORD3;
};

VS_OUT_BaseLMndetail vsBaseLMndetail(appdata_BaseLMndetail input)
{
    VS_OUT_BaseLMndetail Out;

    float3 Pos = input.Pos;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1LMap = (input.TexCoordLMap*lightmapOffset.xy) + lightmapOffset.zw;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psBaseLMndetail(VS_OUT_BaseLMndetail indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);

    float4 expandedNormal = tex2D(samplerWrap1, indata.Tex0Diff);
    expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;

    float2 intensityuv = float2(dot(normalize(indata.LightVec),expandedNormal), dot(normalize(indata.HalfVec),expandedNormal));
    float4 intensity = tex2D(samplerClamp2, intensityuv);
    float4 lightmap = tex2D(samplerWrap3, indata.Tex1LMap);
    intensity *= lightmap.a;

    float4 outColor;
    outColor.rgb = ((intensity*sunColor) + lightmap) * color + (intensity.a*expandedNormal.a*dot(sunColor, 0.33));
    outColor.a = color.a;
    return outColor;
}

technique OnePassbaseLMndetail
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseLMndetail();
        PixelShader = compile ps_2_0 psBaseLMndetail();
    }
}

struct appdata_BaseDetailndetail
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float3 Normal         : NORMAL;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float3 Tan            : TANGENT;
};

struct VS_OUT_BaseDetailndetail
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float3 LightVec   : TEXCOORD2;
    float3 HalfVec    : TEXCOORD3;
};

VS_OUT_BaseDetailndetail vsBaseDetailndetail(appdata_BaseDetailndetail input)
{
    VS_OUT_BaseDetailndetail Out;

    float3 Pos = input.Pos;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psBaseDetailndetail(VS_OUT_BaseDetailndetail indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);

    float4 expandedNormal = tex2D(samplerWrap2, indata.Tex1Detail);
    expandedNormal.xyz = expandedNormal.xyz * 2.0 - 1.0;

    float2 intensityuv = float2(dot(normalize(indata.LightVec),expandedNormal), dot(normalize(indata.HalfVec),expandedNormal));
    float4 intensity = tex2D(samplerClamp3, intensityuv);

    float4 outColor;
    outColor.rgb = intensity * sunColor * color * detail + intensity.a*expandedNormal.a*dot(sunColor, 0.33);
    outColor.a = detail.a;
    return outColor;
}

technique OnePassbasedetailndetail
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailndetail();
        PixelShader = compile ps_2_0 psBaseDetailndetail();
    }
}

struct appdata_BaseDetailLMndetail
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float3 Normal         : NORMAL;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordLMap   : TEXCOORD2;
    float3 Tan            : TANGENT;
};

struct VS_OUT_BaseDetailLMndetail
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2LMap   : TEXCOORD2;
    float3 LightVec   : TEXCOORD3;
    float3 HalfVec    : TEXCOORD4;
};

VS_OUT_BaseDetailLMndetail vsBaseDetailLMndetail(appdata_BaseDetailLMndetail input)
{
    VS_OUT_BaseDetailLMndetail Out;

    float3 Pos = input.Pos;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2LMap = (input.TexCoordLMap*lightmapOffset.xy) + lightmapOffset.zw;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psBaseDetailLMndetail(VS_OUT_BaseDetailLMndetail indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);

    float4 expandedNormal = tex2D(samplerWrap2, indata.Tex1Detail);
    expandedNormal.xyz = expandedNormal.xyz * 2.0 - 1.0;

    float2 intensityuv = float2(dot(normalize(indata.LightVec),expandedNormal), dot(normalize(indata.HalfVec),expandedNormal));
    float4 intensity = tex2D(samplerClamp3, intensityuv);
    float4 lightmap = tex2D(samplerWrap4, indata.Tex2LMap);
    intensity *= lightmap.a;

    float4 outColor;
    outColor.rgb = ((intensity * sunColor) + lightmap) * color * detail + intensity.a * expandedNormal.a * dot(sunColor, 0.33);
    outColor.a = detail.a;
    return outColor;
}

technique OnePassbasedetailLMndetail
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailLMndetail();
        PixelShader = compile ps_2_0 psBaseDetailLMndetail();
    }
}

struct appdata_BaseDetailDirtndetail
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float3 Normal         : NORMAL;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordDirt   : TEXCOORD2;
    float3 Tan            : TANGENT;
};

struct VS_OUT_BaseDetailDirtndetail
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Dirt   : TEXCOORD2;
    float3 LightVec   : TEXCOORD3;
    float3 HalfVec    : TEXCOORD4;
};

VS_OUT_BaseDetailDirtndetail vsBaseDetailDirtndetail(appdata_BaseDetailDirtndetail input)
{
    VS_OUT_BaseDetailDirtndetail Out;

    float3 Pos = input.Pos;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Dirt = input.TexCoordDirt;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psBaseDetailDirtndetail(VS_OUT_BaseDetailDirtndetail indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 dirt = tex2D(samplerWrap2, indata.Tex2Dirt);
    float4 expandedNormal = tex2D(samplerWrap3, indata.Tex1Detail);
    expandedNormal.xyz = (expandedNormal.xyz * 2.0) - 1.0;
    float2 intensityuv = float2(dot(normalize(indata.LightVec),expandedNormal), dot(normalize(indata.HalfVec),expandedNormal));
    float4 intensity = tex2D(samplerClamp4, intensityuv);

    float4 outColor;
    outColor.rgb = intensity * sunColor * color * detail * dirt + intensity.a*expandedNormal.a*dot(sunColor, 0.33);
    outColor.a = detail.a;
    return outColor;
}

technique OnePassbasedetaildirtndetail
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailDirtndetail();
        PixelShader = compile ps_2_0 psBaseDetailDirtndetail();
    }
}

struct appdata_BaseDetailDirtLMndetail
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float3 Normal         : NORMAL;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordDirt   : TEXCOORD2;
    float2 TexCoordLMap   : TEXCOORD3;
    float3 Tan            : TANGENT;
};

struct VS_OUT_BaseDetailDirtLMndetail
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Dirt   : TEXCOORD2;
    float2 Tex3LMap   : TEXCOORD3;
    float3 LightVec   : TEXCOORD4;
    float3 HalfVec    : TEXCOORD5;
};

VS_OUT_BaseDetailDirtLMndetail vsBaseDetailDirtLMndetail(appdata_BaseDetailDirtLMndetail input)
{
    VS_OUT_BaseDetailDirtLMndetail Out;

    float3 Pos = input.Pos;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Dirt = input.TexCoordDirt;
    Out.Tex3LMap = (input.TexCoordLMap*lightmapOffset.xy) + lightmapOffset.zw;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psBaseDetailDirtLMndetail(VS_OUT_BaseDetailDirtLMndetail indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 dirt = tex2D(samplerWrap2, indata.Tex2Dirt);

    float4 expandedNormal = tex2D(samplerWrap3, indata.Tex1Detail);
    expandedNormal.xyz = (expandedNormal.xyz * 2.0) - 1.0;

    float2 intensityuv = float2(dot(normalize(indata.LightVec),expandedNormal), dot(normalize(indata.HalfVec),expandedNormal));
    float4 intensity = tex2D(samplerClamp4, intensityuv);
    float4 lightmap = tex2D(samplerWrap5, indata.Tex3LMap);
    intensity *= lightmap.a;

    float4 outColor;
    outColor.rgb = ((intensity * sunColor) + lightmap) * color * detail * dirt + intensity.a * expandedNormal.a * dot(sunColor, 0.333);
    outColor.a = detail.a;
    return outColor;
}

technique OnePassbasedetaildirtLMndetail
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailDirtLMndetail();
        PixelShader = compile ps_2_0 psBaseDetailDirtLMndetail();
    }
}

struct appdata_BaseDetailCrackndetailncrack
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float3 Normal         : NORMAL;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordCrack  : TEXCOORD2;
    float3 Tan            : TANGENT;
};

struct VS_OUT_BaseDetailCrackndetailncrack
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Crack  : TEXCOORD2;
    float3 LightVec   : TEXCOORD3;
    float3 HalfVec    : TEXCOORD4;
};

VS_OUT_BaseDetailCrackndetailncrack vsBaseDetailCrackndetailncrack(appdata_BaseDetailCrackndetailncrack input)
{
    VS_OUT_BaseDetailCrackndetailncrack Out;

    float3 Pos = input.Pos;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Crack = input.TexCoordCrack;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psBaseDetailCrackndetailncrack(VS_OUT_BaseDetailCrackndetailncrack indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 crack = tex2D(samplerWrap2, indata.Tex2Crack);

    float4 expandedNormal = tex2D(samplerWrap3, indata.Tex1Detail) * (1.0 - crack.a);
    float4 expandedCrackNormal = tex2D(samplerWrap4, indata.Tex2Crack) * crack.a;
    expandedNormal = expandedNormal + expandedCrackNormal;
    expandedNormal.xyz = expandedNormal.xyz * 2.0 - 1.0;

    float2 intensityuv = float2(dot(normalize(indata.LightVec),expandedNormal), dot(normalize(indata.HalfVec),expandedNormal));
    float4 intensity = tex2D(samplerClamp5, intensityuv);

    float3 maskedColor = color * detail * (1.0 - crack.a);
    maskedColor = crack.rgb*crack.a + maskedColor.rgb;

    float4 outColor;
    outColor.rgb = intensity * sunColor * maskedColor + intensity.a*expandedNormal.a*dot(sunColor, 0.33);
    outColor.a = detail.a;
    return outColor;
}

technique OnePassbasedetailcrackndetailncrack
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailCrackndetailncrack();
        PixelShader = compile ps_2_0 psBaseDetailCrackndetailncrack();
    }
}

struct appdata_BaseDetailCrackLMndetailncrack
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float3 Normal         : NORMAL;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordCrack  : TEXCOORD2;
    float2 TexCoordLMap   : TEXCOORD3;
    float3 Tan            : TANGENT;
};

struct VS_OUT_BaseDetailCrackLMndetailncrack
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Crack  : TEXCOORD2;
    float2 Tex3LMap   : TEXCOORD3;
    float3 LightVec   : TEXCOORD4;
    float3 HalfVec    : TEXCOORD5;
};

VS_OUT_BaseDetailCrackLMndetailncrack vsBaseDetailCrackLMndetailncrack(appdata_BaseDetailCrackLMndetailncrack input)
{
    VS_OUT_BaseDetailCrackLMndetailncrack Out;

    float3 Pos = input.Pos;//mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Crack = input.TexCoordCrack;
    Out.Tex3LMap = (input.TexCoordLMap*lightmapOffset.xy) + lightmapOffset.zw;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psBaseDetailCrackLMndetailncrack(VS_OUT_BaseDetailCrackLMndetailncrack indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 crack = tex2D(samplerWrap2, indata.Tex2Crack);

    float4 expandedNormal = tex2D(samplerWrap3, indata.Tex1Detail) * (1.0 - crack.a);
    float4 expandedCrackNormal = tex2D(samplerWrap4, indata.Tex2Crack) * crack.a;
    expandedNormal = expandedNormal + expandedCrackNormal;
    expandedNormal.xyz = (expandedNormal.xyz * 2.0) - 1.0;

    float2 intensityuv = float2(dot(normalize(indata.LightVec),expandedNormal), dot(normalize(indata.HalfVec),expandedNormal));
    float4 intensity = tex2D(samplerClamp5, intensityuv);
    float4 lightmap = tex2D(samplerWrap6, indata.Tex3LMap);
    intensity *= lightmap.a;

    float3 maskedColor = color * detail * (1-crack.a);
    maskedColor = crack.rgb*crack.a + maskedColor.rgb;

    float4 outColor;
    outColor.rgb = (intensity* sunColor + lightmap) * maskedColor + intensity.a*expandedNormal.a * dot(sunColor, 0.33);
    outColor.a = detail.a;
    return outColor;
}

technique OnePassbasedetailcrackLMndetailncrack
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailCrackLMndetailncrack();
        PixelShader = compile ps_2_0 psBaseDetailCrackLMndetailncrack();
    }
}

struct appdata_BaseDetailDirtCrackndetailncrack
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float3 Normal         : NORMAL;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordDirt   : TEXCOORD2;
    float2 TexCoordCrack  : TEXCOORD3;
    float3 Tan            : TANGENT;
};

struct VS_OUT_BaseDetailDirtCrackndetailncrack
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Dirt   : TEXCOORD2;
    float2 Tex3Crack  : TEXCOORD3;
    float3 LightVec   : TEXCOORD4;
    float3 HalfVec    : TEXCOORD5;
};

VS_OUT_BaseDetailDirtCrackndetailncrack vsBaseDetailDirtCrackndetailncrack(appdata_BaseDetailDirtCrackndetailncrack input)
{
    VS_OUT_BaseDetailDirtCrackndetailncrack Out;

    float3 Pos = input.Pos;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Dirt = input.TexCoordDirt;
    Out.Tex3Crack = input.TexCoordCrack;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psBaseDetailDirtCrackndetailncrack(VS_OUT_BaseDetailDirtCrackndetailncrack indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 dirt = tex2D(samplerWrap2, indata.Tex2Dirt);
    float4 crack = tex2D(samplerWrap3, indata.Tex3Crack);

    float4 expandedNormal = tex2D(samplerWrap4, indata.Tex1Detail) * (1-crack.a);
    float4 expandedCrackNormal = tex2D(samplerWrap5, indata.Tex3Crack) * crack.a;
    expandedNormal = expandedNormal + expandedCrackNormal;
    expandedNormal.xyz = (expandedNormal.xyz * 2.0) - 1.0;

    float2 intensityuv = float2(dot(normalize(indata.LightVec),expandedNormal), dot(normalize(indata.HalfVec),expandedNormal));
    float4 intensity = tex2D(samplerClamp6, intensityuv);

    float3 maskedColor = color * detail * dirt * (1.0 - crack.a);
    maskedColor = crack.rgb * crack.a + maskedColor.rgb;

    float4 outColor;
    outColor.rgb = (intensity * sunColor) * maskedColor + intensity.a * expandedNormal.a * dot(sunColor, 0.333);
    outColor.a = detail.a;
    return outColor;
}

technique OnePassbasedetaildirtcrackndetailncrack
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailDirtCrackndetailncrack();
        PixelShader = compile ps_2_0 psBaseDetailDirtCrackndetailncrack();
    }
}

struct appdata_BaseDetailDirtCrackLMndetailncrack
{
    float4 Pos            : POSITION;
    float4 BlendIndices   : BLENDINDICES;
    float3 Normal         : NORMAL;
    float2 TexCoordDiff   : TEXCOORD0;
    float2 TexCoordDetail : TEXCOORD1;
    float2 TexCoordDirt   : TEXCOORD2;
    float2 TexCoordCrack  : TEXCOORD3;
    float2 TexCoordLMap   : TEXCOORD4;
    float3 Tan            : TANGENT;
};

struct VS_OUT_BaseDetailDirtCrackLMndetailncrack
{
    float4 HPos       : POSITION;
    float2 Tex0Diff   : TEXCOORD0;
    float2 Tex1Detail : TEXCOORD1;
    float2 Tex2Dirt   : TEXCOORD2;
    float2 Tex3Crack  : TEXCOORD3;
    float2 Tex4LMap   : TEXCOORD4;
    float3 LightVec   : TEXCOORD5;
    float3 HalfVec    : TEXCOORD6;
};

VS_OUT_BaseDetailDirtCrackLMndetailncrack vsBaseDetailDirtCrackLMndetailncrack(appdata_BaseDetailDirtCrackLMndetailncrack input)
{
    VS_OUT_BaseDetailDirtCrackLMndetailncrack Out;

    float3 Pos = input.Pos;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Diff = input.TexCoordDiff;
    Out.Tex1Detail = input.TexCoordDetail;
    Out.Tex2Dirt = input.TexCoordDirt;
    Out.Tex3Crack = input.TexCoordCrack;
    Out.Tex4LMap = (input.TexCoordLMap*lightmapOffset.xy) + lightmapOffset.zw;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psBaseDetailDirtCrackLMndetailncrack(VS_OUT_BaseDetailDirtCrackLMndetailncrack indata) : COLOR
{
    float4 color = tex2D(samplerWrap0, indata.Tex0Diff);
    float4 detail = tex2D(samplerWrap1, indata.Tex1Detail);
    float4 dirt = tex2D(samplerWrap2, indata.Tex2Dirt);
    float4 crack = tex2D(samplerWrap3, indata.Tex3Crack);
    float4 expandedNormal = tex2D(samplerWrap4, indata.Tex1Detail) * (1.0 - crack.a);
    float4 expandedCrackNormal = tex2D(samplerWrap5, indata.Tex3Crack) * crack.a;
    expandedNormal = expandedNormal + expandedCrackNormal;
    expandedNormal.xyz = (expandedNormal.xyz * 2.0) - 1.0;
    float2 intensityuv = float2(dot(normalize(indata.LightVec),expandedNormal), dot(normalize(indata.HalfVec),expandedNormal));
    float4 intensity = tex2D(samplerClamp6, intensityuv);
    float4 lightmap = tex2D(samplerWrap7, indata.Tex4LMap);
    intensity *= lightmap.a;
    float3 maskedColor = color * detail * dirt * (1.0 - crack.a);
    maskedColor = crack.rgb*crack.a + maskedColor.rgb;

    float4 outColor;
    outColor.rgb = ((intensity*sunColor)+lightmap) * maskedColor + intensity.a*expandedNormal.a*dot(sunColor, 0.33);
    outColor.a = detail.a;
    return outColor;
}

technique OnePassbasedetaildirtcrackLMndetailncrack
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;
        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBaseDetailDirtCrackLMndetailncrack();
        PixelShader = compile ps_2_0 psBaseDetailDirtCrackLMndetailncrack();
    }
}



struct appdata_LightmapAndSunndetail
{
    float4 Pos                     : POSITION;
    float3 Normal                  : NORMAL;
    float2 TexCoordNormalDetailMap : TEXCOORD0;
    float2 TexCoordLMap            : TEXCOORD1;
    float3 Tan                     : TANGENT;
};

struct VS_OUT_LightmapAndSunndetail
{
    float4 HPos       : POSITION;
    float2 Tex0Normal : TEXCOORD0;
    float2 Tex1LMap   : TEXCOORD1;
    float3 LightVec   : TEXCOORD2;
    float3 HalfVec    : TEXCOORD3;
};

VS_OUT_LightmapAndSunndetail vsLightmapAndSunndetail(appdata_LightmapAndSunndetail input)
{
    VS_OUT_LightmapAndSunndetail Out;

    float3 Pos = input.Pos;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Normal = input.TexCoordNormalDetailMap;
    Out.Tex1LMap = (input.TexCoordLMap*lightmapOffset.xy) + lightmapOffset.zw;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psLightmapAndSunndetail(VS_OUT_LightmapAndSunndetail indata) : COLOR
{
    float4 expandedNormal = tex2D(samplerWrap0, indata.Tex0Normal);
    expandedNormal.xyz = (expandedNormal.xyz * 2.0) - 1.0;
    float2 intensityuv = float2(dot(normalize(indata.LightVec), expandedNormal), dot(normalize(indata.HalfVec), expandedNormal));
    float4 intensity = tex2D(samplerClamp1, intensityuv);
    float4 lightmap = tex2D(samplerWrap2, indata.Tex1LMap);
    intensity *= lightmap.a;

    float4 outColor;
    outColor.rgb = (intensity * sunColor + lightmap) + intensity.a * expandedNormal.a * dot(sunColor, 0.333);
    outColor.a = 1.0f;
    return outColor;
}

technique LightmapAndSunndetail
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 1, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0},
        { 2, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 3, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 1 },
        { 4, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_TANGENT, 0 },
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

        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;


        VertexShader = compile vs_2_0 vsLightmapAndSunndetail();
        PixelShader = compile ps_2_0 psLightmapAndSunndetail();
    }
}

struct appdata_LightmapAndSunndetailncrack
{
    float4 Pos                     : POSITION;
    float3 Normal                  : NORMAL;
    float2 TexCoordNormalDetailMap : TEXCOORD0;
    float2 TexCoordNormalCrackMap  : TEXCOORD1;
    float2 TexCoordLMap            : TEXCOORD2;
    float3 Tan                     : TANGENT;
};

struct VS_OUT_LightmapAndSunndetailncrack
{
    float4 HPos       : POSITION;
    float2 Tex0Crack  : TEXCOORD0;
    float2 Tex1Normal : TEXCOORD1;
    float2 Tex2LMap   : TEXCOORD2;
    float3 LightVec   : TEXCOORD3;
    float3 HalfVec    : TEXCOORD4;
};

VS_OUT_LightmapAndSunndetailncrack vsLightmapAndSunndetailncrack(appdata_LightmapAndSunndetailncrack input)
{
    VS_OUT_LightmapAndSunndetailncrack Out;

    float3 Pos = input.Pos;
    Out.HPos = mul1(Pos, viewProjMatrix);

    // Pass-through texcoords
    Out.Tex0Crack = input.TexCoordNormalCrackMap;
    Out.Tex1Normal = input.TexCoordNormalDetailMap;
    Out.Tex2LMap = (input.TexCoordLMap*lightmapOffset.xy) + lightmapOffset.zw;

    vsBumpSpecularBlinn(input.Normal, input.Tan, Pos, 0, Out.LightVec, Out.HalfVec);

    return Out;
}

float4 psLightmapAndSunndetailncrack(VS_OUT_LightmapAndSunndetailncrack indata) : COLOR
{
    float4 crack = tex2D(samplerWrap0, indata.Tex0Crack);
    float4 expandedNormal = tex2D(samplerWrap1, indata.Tex1Normal) * (1.0 - crack.a);
    float4 expandedCrackNormal = tex2D(samplerWrap2, indata.Tex0Crack) * crack.a;
    expandedNormal = expandedNormal + expandedCrackNormal;
    expandedNormal.xyz = (expandedNormal.xyz * 2.0) - 1.0;

    float2 intensityuv = float2(dot(normalize(indata.LightVec),expandedNormal), dot(normalize(indata.HalfVec),expandedNormal));
    float4 intensity = tex2D(samplerClamp3, intensityuv);
    float4 lightmap = tex2D(samplerWrap4, indata.Tex2LMap);
    intensity *= lightmap.a;

    float4 outColor;
    outColor.rgb = ((intensity*sunColor) + lightmap) + intensity.a*expandedNormal.a*dot(sunColor, 0.33);
    outColor.a = 1.0f;
    return outColor;
}

technique LightmapAndSunndetailncrack
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 1, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0},
        { 2, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 3, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 1 },
        { 4, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 2 },
        { 5, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_TANGENT, 0 },
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

        AlphaTestEnable = <alphaTest>;
        AlphaRef = 50;
        AlphaFunc = GREATER;


        VertexShader = compile vs_2_0 vsLightmapAndSunndetailncrack();
        PixelShader = compile ps_2_0 psLightmapAndSunndetailncrack();
    }
}



void vsBumpSpecularBlinnPointLight(float3 Normal, float3 Tan, float3 Pos, int Index, out float3 LightVec, out float3 HalfVec, out float2 LightDist)
{
    // Cross product to create BiNormal
    float3 binormal = normalize(cross(Tan, Normal));

    // Need to calculate the WorldI based on each matBone skinning world matrix
    float3x3 TanBasis = float3x3(Tan, binormal, Normal);

    // Calculate WorldTangent directly... inverse is the transpose for affine rotations
    float3x3 worldI = TanBasis;//mul(TanBasis, mOneBoneSkinning[Index]);
    worldI = transpose(mul(worldI, worldMatrix));

    // Transform Light vec to Object space
    float3 worldPos = mul(Pos, worldMatrix);
    float3 lvec = lightPosAndAttSqrInv.xyz-worldPos;

    // Transform Light dir to Object space
    LightVec = mul(lvec, worldI);
    float lightDist = length(LightVec);
    lightDist *= lightPosAndAttSqrInv.w;
    LightDist = float2(lightDist, 0.0);

    // Transform eye pos to tangent space
    float3 worldEyeVec = eyePos - worldPos;
    float3 tanEyeVec = mul(worldEyeVec, worldI);

    HalfVec = (LightVec + normalize(tanEyeVec)) * 0.5;
}



struct appdata_vsBumpSpecularPointLightndetail
{
    float4 Pos                     : POSITION;
    float4 Normal                  : NORMAL;
    float2 TexCoordNormalDetailMap : TEXCOORD0;
    float3 Tan                     : TANGENT;
};

struct VS_OUT_vsBumpSpecularPointLightndetail
{
    float4 HPos       : POSITION;
    float2 Tex0Normal : TEXCOORD0;
    float3 LightVec   : TEXCOORD1;
    float3 HalfVec    : TEXCOORD2;
    float2 LightDist  : TEXCOORD3;
};

VS_OUT_vsBumpSpecularPointLightndetail vsBumpSpecularPointLightndetail(appdata_vsBumpSpecularPointLightndetail input)
{
    VS_OUT_vsBumpSpecularPointLightndetail Out;

    float3 wPos = input.Pos;
    Out.HPos = mul1(wPos, viewProjMatrix);

    Out.Tex0Normal = input.TexCoordNormalDetailMap;

    vsBumpSpecularBlinnPointLight(input.Normal, input.Tan, wPos, 0, Out.LightVec, Out.HalfVec, Out.LightDist);

    return Out;
}

float4 psBumpSpecularPointLightndetail(VS_OUT_vsBumpSpecularPointLightndetail indata) : COLOR
{
    float4 normalmap = tex2D(samplerWrap0, indata.Tex0Normal);
    float3 expandedNormal = normalmap.xyz * 2.0 - 1.0;

    float3 normalizedLVec = normalize(indata.LightVec);
    float2 intensityuv = float2(dot(normalizedLVec,expandedNormal), dot(indata.HalfVec,expandedNormal));
    float4 intensity = tex2D(samplerClamp1, intensityuv);

    float4 radialAtt = tex1D(samplerClamp2, indata.LightDist.r);
    return radialAtt * intensity * lightColor + intensity.a * normalmap.a*dot(lightColor, 0.33);
}

technique PointLightndetail
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 1, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        { 2, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 3, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_TANGENT, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;

        ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

        VertexShader = compile vs_2_0 vsBumpSpecularPointLightndetail();
        PixelShader = compile ps_2_0 psBumpSpecularPointLightndetail();
    }
}

struct appdata_vsBumpSpecularPointLightndetailncrack
{
    float4 Pos                     : POSITION;
    float4 Normal                  : NORMAL;
    float2 TexCoordNormalDetailMap : TEXCOORD0;
    float2 TexCoordNormalCrackMap  : TEXCOORD1;
    float3 Tan                     : TANGENT;
};

struct VS_OUT_vsBumpSpecularPointLightndetailncrack
{
    float4 HPos            : POSITION;
    float2 Tex0Normal      : TEXCOORD0;
    float2 Tex1NormalCrack : TEXCOORD1;
    float3 LightVec        : TEXCOORD2;
    float3 HalfVec         : TEXCOORD3;
    float2 LightDist       : TEXCOORD4;
};

VS_OUT_vsBumpSpecularPointLightndetailncrack vsBumpSpecularPointLightndetailncrack(appdata_vsBumpSpecularPointLightndetailncrack input)
{
    VS_OUT_vsBumpSpecularPointLightndetailncrack Out;

    float3 wPos = input.Pos;
    Out.HPos = mul1(wPos, viewProjMatrix);

    Out.Tex0Normal = input.TexCoordNormalDetailMap;
    Out.Tex1NormalCrack = input.TexCoordNormalCrackMap;

    vsBumpSpecularBlinnPointLight(input.Normal, input.Tan, wPos, 0, Out.LightVec, Out.HalfVec, Out.LightDist);

    return Out;
}

float4 psBumpSpecularPointLightndetailncrack(VS_OUT_vsBumpSpecularPointLightndetailncrack indata) : COLOR
{
    float4 crack = tex2D(samplerWrap0, indata.Tex1NormalCrack);
    float4 expandedNormal = tex2D(samplerWrap1, indata.Tex0Normal) * (1.0 - crack.a);
    float4 expandedCrackNormal = tex2D(samplerWrap2, indata.Tex1NormalCrack) * crack.a;
    expandedNormal = expandedNormal + expandedCrackNormal;
    expandedNormal.xyz = (expandedNormal.xyz * 2.0) - 1.0;

    float3 normalizedLVec = normalize(indata.LightVec);
    float2 intensityuv = float2(dot(normalizedLVec,expandedNormal), dot(indata.HalfVec,expandedNormal));
    float4 intensity = tex2D(samplerClamp3, intensityuv);

    float4 radialAtt = tex1D(samplerClamp2, indata.LightDist.r);
    return radialAtt * intensity * lightColor + intensity.a * expandedNormal.a * dot(lightColor, 0.33);
}

technique PointLightndetailncrack
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 1, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        { 2, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 3, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 1 },
        { 4, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_TANGENT, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;

        VertexShader = compile vs_2_0 vsBumpSpecularPointLightndetailncrack();
        PixelShader = compile ps_2_0 psBumpSpecularPointLightndetailncrack();
    }
}
