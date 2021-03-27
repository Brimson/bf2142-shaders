
float4x4 wvp : WORLDVIEWPROJ;

float4 cellPositions[32] : CELLPOSITIONS;
float4 deviations[16] : DEVIATIONGROUPS;
float cellVisibility[32] : CELLVISIBILITY;

float4 particleColor: PARTICLECOLOR;

float4 systemPos : SYSTEMPOS;
float4 cameraPos : CAMERAPOS;

float3 fadeOutRange : FADEOUTRANGE;
float3 fadeOutDelta : FADEOUTDELTA;

float3 pointScale : POINTSCALE;
float particleSize : PARTICLESIZE;
float maxParticleSize : PARTICLEMAXSIZE;

texture texture0 : TEXTURE;

sampler sampler0 = sampler_state
{
    Texture = <texture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

struct VSINPUT
{
    float3 Pos      : POSITION;
    float4 Data     : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

// Point Technique

struct POINT_VSOUT
{
    float4 Pos: POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
    float pointSize : PSIZE;
};

POINT_VSOUT vsPoint(VSINPUT input)
{
    POINT_VSOUT output;

    // read the particle position and pertubate it based on cell and deviation groups
    float3 cellPos = cellPositions[input.Data.x];
    float3 deviation = deviations[input.Data.y];

    float3 particlePos = input.Pos + cellPos + deviation;

    // calculate the alpha blending based on system position
    float3 sysDelta = abs(systemPos.xyz - particlePos);

    sysDelta -= fadeOutRange;
    sysDelta /= fadeOutDelta;
    float alpha = 1.0f - length(saturate(sysDelta));

    float visibility = cellVisibility[input.Data.x];
    output.Color = float4(particleColor.rgb,particleColor.a*alpha*visibility);

    // calculate the point size using the camera position
    float3 camDelta = abs(cameraPos.xyz - particlePos);
    float camDist = length(camDelta);

    output.pointSize = min(particleSize * rsqrt(pointScale[0] + pointScale[1] * camDist), maxParticleSize);

    // output the final texture coordinates and projected position
    output.Pos = mul(float4(particlePos,1), wvp);
    output.TexCoord = input.TexCoord;

    return output;
}

float4 psPoint(POINT_VSOUT input) : COLOR
{
    float4 texCol = tex2D(sampler0, input.TexCoord);
    return texCol * input.Color;
}

technique Point
{
    pass p0
    {
        FogEnable = FALSE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = false;
        AlphaBlendEnable = TRUE;
        SrcBlend = SrcAlpha;
        DestBlend = One;
        CullMode = NONE;

        VertexShader = compile vs_2_0 vsPoint();
        PixelShader = compile ps_2_0 psPoint();
    }
}

// Line Technique

struct LINE_VSOUT
{
    float4 Pos: POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
};

LINE_VSOUT vsLine(VSINPUT input)
{
    LINE_VSOUT output;

    float3 cellPos = cellPositions[input.Data.x];
    float3 particlePos = input.Pos + cellPos;

    float3 camDelta = abs(systemPos.xyz-particlePos);
    camDelta -= fadeOutRange;
    camDelta /= fadeOutDelta;
    float alpha = 1.0f - length(saturate(camDelta));

    float visibility = cellVisibility[input.Data.x];
    output.Color = float4(particleColor.rgb,particleColor.a*alpha*visibility);

    output.Pos = mul(float4(particlePos, 1.0), wvp);
    output.TexCoord = input.TexCoord;

    return output;
}

float4 psLine(LINE_VSOUT input) : COLOR
{
    return input.Color;
}

technique Line
{
    pass p0
    {
        FogEnable = FALSE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = false;
        AlphaBlendEnable = TRUE;
        SrcBlend = SrcAlpha;
        DestBlend = One;
        CullMode = NONE;

        VertexShader = compile vs_2_0 vsLine();
        PixelShader = compile ps_2_0 psLine();
    }
}

// Debug Cell Technique

struct CELL_VSOUT
{
    float4 Pos: POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR0;
};

CELL_VSOUT vsCells(VSINPUT input)
{
    CELL_VSOUT output;

    float3 cellPos = cellPositions[input.Data.x];
    float3 particlePos = input.Pos + cellPos;
    float visibility = cellVisibility[input.Data.x];

    output.Color = float4(visibility, 1.0 - visibility, 1.0 - visibility, 1.0);
    output.Pos = mul(float4(particlePos, 1.0), wvp);
    output.TexCoord = input.TexCoord;
    return output;
}

float4 psCells(CELL_VSOUT input) : COLOR
{
    return input.Color;
}

technique Cells
{
    pass p0
    {
        FogEnable = FALSE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = false;
        AlphaBlendEnable = TRUE;
        SrcBlend = SrcAlpha;
        DestBlend = One;
        CullMode = NONE;

        VertexShader = compile vs_2_0 vsCells();
        PixelShader = compile ps_2_0 psCells();
    }
}
