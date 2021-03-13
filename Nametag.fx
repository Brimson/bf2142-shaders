#line 2 "Nametag.fx"

float4x4 mWorldViewProj : WorldViewProjection;
float    fTexBlendFactor : TexBlendFactor;
float2   vFadeoutValues : FadeOut;
float4   vLocalEyePos : LocalEye;

float4 Transformations[64] : TransformationArray;
// dep: this is a suboptimal Camp EA hack; rewrite this
float  Alphas[64] : AlphaArray;
float4 Colors[9] : ColorArray;
float4 fAspectMul : AspectMul;

float4 fArrowMult = float4(1.05, 1.05, 1.0, 1.0);

float4 ArrowTrans : ArrowTransformation;
float4 ArrowRot : ArrowRotation; // this is a 2x2 rotation matrix [X Y] [Z W]

float4 IconRot : IconRotation;
// float4 FIconRot : FIconRotation;
float2 iconTexOffset : IconTexOffset;
float4 iconFlashTexScaleOffset : IconFlashTexScaleOffset;

int colorIndex1 : ColorIndex1;
int colorIndex2 : ColorIndex2;
int colorIndex3 : ColorIndex3;

int alphaIndex : AlphaIndex;

float4 HealthBarTrans : HealthBarTrans;
float  fHealthValue : HealthValue;

float crossFadeValue : CrossFadeValue;
float fAspectComp = 4.0/3.0;

texture detail0 : TEXLAYER0;
texture detail1 : TEXLAYER1;
texture detail2 : TEXLAYER2;

sampler sampler0_point = sampler_state
{
    Texture = (detail0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};

sampler sampler1_point = sampler_state
{
    Texture = (detail1);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};

sampler sampler2_point = sampler_state
{
    Texture = (detail2);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};

sampler sampler0_bilin = sampler_state
{
    Texture = (detail0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
};

sampler sampler1_bilin = sampler_state
{
    Texture = (detail1);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
};

sampler sampler2_bilin = sampler_state
{
    Texture = (detail2);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
};

struct APP2VS
{
    float4 Pos   : POSITION;
    float2 Tex0  : TEXCOORD0;
    int4 Indices : BLENDINDICES0;
};

struct VS2PS
{
    float4 Pos  : POSITION;
    float2 Tex0 : TEXCOORD0;
    float2 Tex1 : TEXCOORD1;
    float4 Col  : COLOR;
};

struct VS3PS
{
    float4 Pos  : POSITION;
    float2 Tex0 : TEXCOORD0;
    float2 Tex1 : TEXCOORD1;
    float2 Tex2 : TEXCOORD2;
    float4 Col  : COLOR;
    float4 Col1 : COLOR1;
};

struct VS2PS2TEXT
{
    float4 Pos  : POSITION;
    float2 Tex0 : TEXCOORD0;
    float2 Tex1 : TEXCOORD1;
    float4 Col0 : COLOR0;
    float4 Col1 : COLOR1;
};

VS2PS vsNametag(APP2VS input)
{
    VS2PS output = (VS2PS)0;

    float4 indexedTrans = Transformations[input.Indices.x];

    output.Pos.xyz = input.Pos + indexedTrans;
    output.Pos.w = 1.0;

    output.Tex0 = input.Tex0;

    output.Col = lerp(Colors[input.Indices.y], Colors[input.Indices.z], crossFadeValue);
    output.Col.a = Alphas[input.Indices.x];
    output.Col.a *= 1.0 - saturate(indexedTrans.w * vFadeoutValues.x + vFadeoutValues.y);

    return output;
}

VS2PS vsNametag_arrow(APP2VS input)
{
    VS2PS output = (VS2PS)0;

    // does a 2x2 matrix 2d rotation of the local vertex coordinates in screen space
    output.Pos.x = dot(input.Pos, float3(ArrowRot.x, ArrowRot.y, 0.0));
    output.Pos.y = dot(input.Pos, float3(ArrowRot.z, ArrowRot.w, 0.0));
    output.Pos.z = 0.0;
    output.Pos.xyz *= fAspectMul;
    output.Pos.xyz += ArrowTrans * fArrowMult;
    output.Pos.w = 1.0;

    output.Tex0 = input.Tex0;

    output.Col = Colors[input.Indices.y];
    output.Col.a = 0.5;

    return output;
}

VS2PS2TEXT vsNametag_healthbar(APP2VS input)
{
    VS2PS2TEXT output = (VS2PS2TEXT)0;

    output.Pos.xyz = input.Pos + HealthBarTrans;
    output.Pos.w = 1.0;

    output.Tex0 = input.Tex0;
    output.Tex1 = input.Tex0;

    output.Col0.rgb = input.Tex0.x;
    output.Col0.a = 1.0 - saturate(HealthBarTrans.w * vFadeoutValues.x + vFadeoutValues.y);

    float4 Col0 = Colors[colorIndex1];
    float4 Col1 = Colors[colorIndex2];
    output.Col1 = lerp(Col0, Col1, crossFadeValue);

    return output;
}

VS2PS vsNametag_vehicleIcons(APP2VS input)
{
    VS2PS output = (VS2PS)0;

    float3 tempPos = input.Pos;

    // since indata is aspectcompensated we need to compensate for that
    tempPos.y /= fAspectComp;

    float3 rotPos;
    rotPos.x = dot(tempPos, float3(IconRot.x, IconRot.z, 0.0));
    rotPos.y = dot(tempPos, float3(IconRot.y, IconRot.w, 0.0));
    rotPos.z = input.Pos.z;

    // fix aspect again
    rotPos.y *= fAspectComp;

    output.Pos.xyz = rotPos + HealthBarTrans;
    output.Pos.w = 1.0;

    output.Tex0 = input.Tex0 + iconTexOffset;
    output.Tex1 = input.Tex0 * iconFlashTexScaleOffset.xy + iconFlashTexScaleOffset.zw;

    float4 Col0 = Colors[colorIndex1];
    float4 Col1 = Colors[colorIndex2];

    output.Col = lerp(Col0, Col1, crossFadeValue);
    output.Col.a = Alphas[alphaIndex];
    output.Col.a *= 1.0 - saturate(HealthBarTrans.w * vFadeoutValues.x + vFadeoutValues.y);

    return output;
}

VS2PS vsNametag_barIcons(APP2VS input)
{
    VS2PS output = (VS2PS)0;

    float3 tempPos = input.Pos;

    // since indata is aspectcompensated we need to compensate for that
    tempPos.y /= fAspectComp;

    float3 rotPos;
    rotPos.x = dot(tempPos, float3(IconRot.x, IconRot.z, 0.0));
    rotPos.y = dot(tempPos, float3(IconRot.y, IconRot.w, 0.0));
    rotPos.z = input.Pos.z;

    // fix aspect again
    rotPos.y *= fAspectComp;

    output.Pos.xyz = rotPos + HealthBarTrans;
    output.Pos.w = 1.0;

    output.Tex0 = input.Tex0 + iconTexOffset;
    output.Tex1 = input.Tex0 * iconFlashTexScaleOffset.xy + iconFlashTexScaleOffset.zw;

    float4 Col0 = Colors[colorIndex1];
    float4 Col1 = Colors[colorIndex2];

    output.Col = lerp(Col0, Col1, crossFadeValue);
    output.Col.a = 1.0;
    output.Col.a *= 1.0 - saturate(HealthBarTrans.w * vFadeoutValues.x + vFadeoutValues.y);

    return output;
}

VS3PS vsNametag_selectableVehicleIcons(APP2VS input)
{
    VS3PS output = (VS3PS)0;

    float3 tempPos = input.Pos;

    // since indata is aspectcompensated we need to compensate for that
    tempPos.y /= fAspectComp;

    float3 rotPos;
    rotPos.x = dot(tempPos, float3(IconRot.x, IconRot.z, 0.0));
    rotPos.y = dot(tempPos, float3(IconRot.y, IconRot.w, 0.0));
    rotPos.z = input.Pos.z;

    // fix aspect again
    rotPos.y *= fAspectComp;

    output.Pos.xyz = rotPos + HealthBarTrans;
    output.Pos.w = 1.0;

    output.Tex0 = input.Tex0 + iconTexOffset;
    output.Tex1 = input.Tex0 + iconTexOffset;
    output.Tex2 = input.Tex0 * iconFlashTexScaleOffset.xy + iconFlashTexScaleOffset.zw;

    float4 Col0 = Colors[colorIndex1];
    float4 Col1 = Colors[colorIndex2];
    float4 Col2 = Colors[colorIndex3];

    output.Col = lerp(Col0, Col1, crossFadeValue);
    output.Col.a *= 1.0 - saturate(HealthBarTrans.w * vFadeoutValues.x + vFadeoutValues.y);
    output.Col1 = Col2;

    return output;
}

float4 psNametag_icon(VS2PS indata) : COLOR0
{
    float4 tx0 = tex2D(sampler0_bilin, indata.Tex0);
    float4 tx1 = tex2D(sampler1_bilin, indata.Tex1);
    return lerp(tx0, tx1, crossFadeValue) * indata.Col;
}

float4 psNametag_selectableIcon(VS3PS indata) : COLOR0
{
    float4 tx0 = tex2D(sampler0_bilin, indata.Tex0);
    float4 tx1 = tex2D(sampler1_bilin, indata.Tex1);
    float4 tx2 = tex2D(sampler2_bilin, indata.Tex2);
    float4 result = lerp(tx1, tx2, crossFadeValue);
    result.rgb *= indata.Col.rgb;
    result.rgb = lerp(tx0.a*indata.Col1.rgb, result.rgb, result.a);
    result.a += tx0.a;
    return result;
}

float4 psNametag(VS2PS indata) : COLOR0
{
    float4 tx0 = tex2D(sampler0_point, indata.Tex0);
    return tx0 * indata.Col;
}

float4 psNametag_arrow(VS2PS indata) : COLOR0
{
    float4 tx0 = tex2D(sampler0_bilin, indata.Tex0);
    float4 result = tx0 * indata.Col;
    return result;
}

float4 psNametag_healthbar(VS2PS2TEXT indata) : COLOR0
{
    float4 tx0 = tex2D(sampler0_point, indata.Tex0);
    float4 tx1 = tex2D(sampler1_point, indata.Tex1);
    return lerp(tx0, tx1, fHealthValue<indata.Col0.b) * indata.Col0.a * indata.Col1;
}

float4 psNametag_healthbarVert(VS2PS2TEXT indata) : COLOR0
{
    float4 tx0 = tex2D(sampler0_point, indata.Tex0);
    float4 tx1 = tex2D(sampler1_point, indata.Tex1);
    return lerp(tx1, tx0, (1.0f - fHealthValue)<indata.Col0.b) * indata.Col0.a * indata.Col1;
}

technique nametag
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_BLENDINDICES, 0 },
        DECLARATION_END	// End macro
    };
    int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        CullMode = NONE;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;

        VertexShader = compile vs_2_0 vsNametag();
        PixelShader = compile ps_2_0 psNametag();
    }
}

technique nametag_arrow
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_BLENDINDICES, 0 },
        DECLARATION_END	// End macro
    };
    int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        CullMode = NONE;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;

        VertexShader = compile vs_2_0 vsNametag_arrow();
        PixelShader = compile ps_2_0 psNametag_arrow();
    }
}


technique nametag_healthbar
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_BLENDINDICES, 0 },
        DECLARATION_END	// End macro
    };
    int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        CullMode = NONE;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;

        VertexShader = compile vs_2_0 vsNametag_healthbar();
        PixelShader = compile ps_2_0 psNametag_healthbar();
    }
}

technique nametag_vehicleIcons
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_BLENDINDICES, 0 },
        DECLARATION_END	// End macro
    };
    int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        CullMode = NONE;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;

        VertexShader = compile vs_2_0 vsNametag_vehicleIcons();
        PixelShader = compile ps_2_0 psNametag_icon();
    }
}

technique nametag_barIcons
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_BLENDINDICES, 0 },
        DECLARATION_END	// End macro
    };
    int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        CullMode = NONE;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;

        VertexShader = compile vs_2_0 vsNametag_barIcons();
        PixelShader = compile ps_2_0 psNametag_icon();
    }
}

technique nametag_selectableVehicleIcons
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
        { 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_BLENDINDICES, 0 },
        DECLARATION_END	// End macro
    };
    int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        CullMode = NONE;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;

        VertexShader = compile vs_2_0 vsNametag_selectableVehicleIcons();
        PixelShader = compile ps_2_0 psNametag_selectableIcon();
    }
}
