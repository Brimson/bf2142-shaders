#line 2 "MeshParticleMesh.fx"
#include "shaders/FXCommon.fx"
#include "Shaders/Math.fx"

// UNIFORM INPUTS
float4x4 viewProjMatrix : WorldViewProjection;
float4 globalScale : GlobalScale;

struct appdata
{
    float4 Pos          : POSITION;
    float3 Normal       : NORMAL;
    float4 BlendIndices : BLENDINDICES;
    float2 TexCoord     : TEXCOORD0;
    float3 Tan          : TANGENT;
    float3 Binorm       : BINORMAL;
};

// once per system instance
// TemplateParameters
float4 m_color1AndLightFactor : COLOR1;
float4 m_color2 : COLOR2;
float4 m_colorBlendGraph : COLORBLENDGRAPH;
float4 m_transparencyGraph : TRANSPARENCYGRAPH;

float4 ageAndAlphaArray[52] : AgeAndAlphaArray;
float lightmapIntensityOffset : LightmapIntensityOffset;
float4x3 mOneBoneSkinning[52]: matONEBONESKINNING;

struct OUT_vsDiffuse
{
    float4 HPos                 : POSITION;
    float2 DiffuseMap           : TEXCOORD0;
    float2 GroundUV             : TEXCOORD1;
    float3 LerpAndLMapIntOffset : TEXCOORD2;
    float4 color                : COLOR0;
    float4 lightFactor          : COLOR1;
    float Fog                   : FOG;
};

OUT_vsDiffuse vsDiffuse
(
    appdata input,
    uniform float4x4 ViewProj
)
{
    OUT_vsDiffuse Out = (OUT_vsDiffuse)0;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float3 Pos = mul(input.Pos * globalScale, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul1(Pos, ViewProj);

    // Compute Cubic polynomial factors.
    float age = ageAndAlphaArray[IndexArray[0]][0];
    float4 pc = { age * age * age, age * age, age, 1.9f};

    float colorBlendFactor = min(dot(m_colorBlendGraph, pc), 1.0);
    float3 color = colorBlendFactor * m_color2.rgb;
    color += (1.0 - colorBlendFactor) * m_color1AndLightFactor.rgb;

    Out.lightFactor = m_color1AndLightFactor.a;
    Out.color.rgb = color;
    Out.color.a = ageAndAlphaArray[IndexArray[0]][1];

    // Pass-through texcoords
    Out.DiffuseMap.xy = input.TexCoord;
    // hemi lookup coords
    Out.GroundUV.xy = ((Pos.xyz + (hemiMapInfo.z * 0.5)).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
    Out.LerpAndLMapIntOffset = saturate(saturate((Pos.y - hemiShadowAltitude) * 0.1) + lightmapIntensityOffset);

    Out.Fog = calcFog(Out.HPos.w);

    return Out;
}

float4 psDiffuse(OUT_vsDiffuse indata) : COLOR
{
    float4 outColor = tex2D(diffuseSampler, indata.DiffuseMap.xy) * indata.color;
    float4 tLut = tex2D(lutSampler, indata.GroundUV);
    outColor.rgb *= calcParticleLighting(tLut.a, indata.LerpAndLMapIntOffset, indata.lightFactor.a);
    return outColor;
}

float4 psAdditive(OUT_vsDiffuse indata) : COLOR
{
    float4 outColor = tex2D(diffuseSampler, indata.DiffuseMap.xy) * indata.color;
    // mask with alpha since were doing an add
    outColor.rgb *= outColor.a;
    return outColor;
}

technique Diffuse
{
    pass p0
    {
        AlphaTestEnable = TRUE;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        AlphaRef = 0;
        AlphaFunc = GREATER;
        CullMode = CCW;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = TRUE;

        VertexShader = compile vs_2_0 vsDiffuse(viewProjMatrix);
        PixelShader = compile ps_2_0 psDiffuse();
    }
}

technique Additive
{
    pass p0
    {
        AlphaTestEnable = TRUE;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        AlphaRef = 0;
        AlphaFunc = GREATER;
        CullMode = NONE;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsDiffuse(viewProjMatrix);
        PixelShader = compile ps_2_0 psAdditive();
    }
}

technique DiffuseWithZWrite
{
    pass p0
    {
        AlphaTestEnable = TRUE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        AlphaRef = 0;
        AlphaFunc = GREATER;
        CullMode = CCW;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = TRUE;

        VertexShader = compile vs_2_0 vsDiffuse(viewProjMatrix);
        PixelShader = compile ps_2_0 psDiffuse();
    }
}
