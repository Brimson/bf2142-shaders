#line 2 "Trail.fx"
#include "shaders/FXCommon.fx"

// UNIFORM INPUTS
uniform vec3 eyePos : EyePos;
uniform scalar fadeOffset : FresnelOffset = 0;

scalar PI = 3.1415926535897932384626433832795;
scalar fracTime : FracTime;
vec2 texelSize : TexelSize = { 1.0f/800.f, 1.0f/600.0f };

// Back buffer texture
uniform texture backbufferTexture: BackBufferTexture;

// Shimmering params
scalar shimmerIntensity : ShimmerIntensity = 0.75;
scalar shimmerPhases    : ShimmerPhases    = 20.0;

sampler backbufferSampler = sampler_state
{
    Texture = <backbufferTexture>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = FILTER_PARTICLE_MIP;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler trailDiffuseSampler = sampler_state
{
    Texture = <texture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = FILTER_PARTICLE_MIP;
    AddressU = Wrap;
    AddressV = Clamp;
};

sampler trailDiffuseSampler2 = sampler_state
{
    Texture = <texture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = FILTER_PARTICLE_MIP;
    AddressU = Wrap;
    AddressV = Clamp;
};

// constant array
struct TemplateParameters
{
    vec4 m_uvRangeLMapIntensiyAndParticleMaxSize;
    vec4 m_fadeInOutTileFactorAndUVOffsetVelocity;
    vec4 m_color1AndLightFactor;
    vec4 m_color2;
    vec4 m_colorBlendGraph;
    vec4 m_transparencyGraph;
    vec4 m_sizeGraph;
};

TemplateParameters tParameters : TemplateParameters;

struct appdata
{
    vec3 pos                                 : POSITION;
    vec3 localCoords                         : NORMAL0;
    vec3 tangent                             : NORMAL1;
    vec4 intensityAgeAnimBlendFactorAndAlpha : TEXCOORD0;
    vec4 uvOffsets                           : TEXCOORD1;
    vec2 texCoords                           : TEXCOORD2;
};

struct VS_TRAIL_OUTPUT
{
    vec4 HPos                        : POSITION;
    vec4 color                       : TEXCOORD3;
    vec3 animBFactorAndLMapIntOffset : COLOR0;
    vec4 lightFactorAndAlpha         : COLOR1;
    vec2 texCoords0                  : TEXCOORD0;
    vec2 texCoords1                  : TEXCOORD1;
    vec2 texCoords2                  : TEXCOORD2;
    scalar Fog                       : FOG;
};

VS_TRAIL_OUTPUT vsTrail(appdata input, uniform mat4x4 myWV, uniform mat4x4 myWP)
{

    VS_TRAIL_OUTPUT Out = (VS_TRAIL_OUTPUT)0;

    // Compute Cubic polynomial factors.
    scalar age = input.intensityAgeAnimBlendFactorAndAlpha[1];

    // FADE values
    scalar fadeIn = saturate(age/tParameters.m_fadeInOutTileFactorAndUVOffsetVelocity.x);
    scalar fadeOut = saturate((1.f - age)/tParameters.m_fadeInOutTileFactorAndUVOffsetVelocity.y);

    vec3 eyeVec = eyePos - input.pos;

    // project eyevec to tangent vector to get position on axis
    scalar tanPos = dot(eyeVec, input.tangent);

    // closest point to camera
    vec3 axisVec = eyeVec - (input.tangent * tanPos);
    axisVec = normalize(axisVec);

    // find rotation around axis
    vec3 norm = cross(input.tangent, input.localCoords*-1);

    scalar fadeFactor = dot(axisVec, norm);
    fadeFactor *= fadeFactor;
    fadeFactor += fadeOffset;
    fadeFactor *= fadeIn * fadeOut;

    // age factor polynomials
    vec4 pc = {age*age*age, age*age, age, 1.f};

    // comput size of particle using the constants of the templ[input.ageFactorAndGraphIndex.y]ate (mSizeGraph)
    scalar size = min(dot(tParameters.m_sizeGraph, pc), 1) * tParameters.m_uvRangeLMapIntensiyAndParticleMaxSize.w;

    // displace vertex
    vec4 pos = mul(vec4(input.pos.xyz + size*(input.localCoords.xyz*input.texCoords.y), 1), myWV);
    Out.HPos = mul(pos, myWP);

    scalar colorBlendFactor = min(dot(tParameters.m_colorBlendGraph, pc), 1);
    vec3 color = colorBlendFactor * tParameters.m_color2.rgb;
    color += (1 - colorBlendFactor) * tParameters.m_color1AndLightFactor.rgb;

    // lighting??

    scalar alphaBlendFactor = min(dot(tParameters.m_transparencyGraph, pc), 1) * input.intensityAgeAnimBlendFactorAndAlpha[3];
    alphaBlendFactor *= fadeFactor;

    Out.color.rgb = color/2;
    Out.lightFactorAndAlpha.b = alphaBlendFactor;

    Out.animBFactorAndLMapIntOffset.x = input.intensityAgeAnimBlendFactorAndAlpha[2];

    scalar lightMapIntensity = saturate(clamp((input.pos.y - hemiShadowAltitude) / 10.f, 0.f, 1.0f) + tParameters.m_uvRangeLMapIntensiyAndParticleMaxSize.z);
    Out.animBFactorAndLMapIntOffset.yz = lightMapIntensity;

    // compute texcoords for trail
    vec2 rotatedTexCoords = input.texCoords;

    rotatedTexCoords.x -= age * tParameters.m_fadeInOutTileFactorAndUVOffsetVelocity.w;
    rotatedTexCoords *= tParameters.m_uvRangeLMapIntensiyAndParticleMaxSize.xy;
    rotatedTexCoords.x *= tParameters.m_fadeInOutTileFactorAndUVOffsetVelocity.z / tParameters.m_uvRangeLMapIntensiyAndParticleMaxSize.w;

    // Bias texcoords.
    rotatedTexCoords.x += tParameters.m_uvRangeLMapIntensiyAndParticleMaxSize.x;
    rotatedTexCoords.y = tParameters.m_uvRangeLMapIntensiyAndParticleMaxSize.y - rotatedTexCoords.y;
    rotatedTexCoords.y *= 0.5f;

    // Offset texcoords
    vec4 uvOffsets = input.uvOffsets * OneOverShort;

    Out.texCoords0.xy = rotatedTexCoords.xy + uvOffsets.xy;
    Out.texCoords1 = rotatedTexCoords.xy + uvOffsets.zw;

    // hemi lookup coords
    Out.texCoords2.xy = ((input.pos + (hemiMapInfo.z/2)).xz - hemiMapInfo.xy) / hemiMapInfo.z;
    Out.texCoords2.y = 1 - Out.texCoords2.y;

    Out.lightFactorAndAlpha.a = tParameters.m_color1AndLightFactor.a;

    Out.Fog = calcFog(Out.HPos.w);

    return Out;
}

vec4 psTrailHigh(VS_TRAIL_OUTPUT input) : COLOR
{
    vec4 tDiffuse = tex2D( trailDiffuseSampler, input.texCoords0.xy);
    vec4 tDiffuse2 = tex2D( trailDiffuseSampler2, input.texCoords1);
    vec4 tLut = tex2D( lutSampler, input.texCoords2.xy);

    vec4 color = lerp(tDiffuse, tDiffuse2, input.animBFactorAndLMapIntOffset.x);
    color.rgb *= 2*input.color.rgb;
    color.rgb *= calcParticleLighting(tLut.a, input.animBFactorAndLMapIntOffset.z, input.lightFactorAndAlpha.a);
    color.a *= input.lightFactorAndAlpha.b;

    return color;
}

vec4 psTrailMedium(VS_TRAIL_OUTPUT input) : COLOR
{
    vec4 tDiffuse = tex2D(trailDiffuseSampler, input.texCoords0.xy);
    vec4 tDiffuse2 = tex2D(trailDiffuseSampler2, input.texCoords1);

    vec4 color = lerp(tDiffuse, tDiffuse2, input.animBFactorAndLMapIntOffset.x);
    color.rgb *= 2*input.color.rgb;
    color.rgb *= calcParticleLighting(1, input.animBFactorAndLMapIntOffset.z, input.lightFactorAndAlpha.a);
    color.a *= input.lightFactorAndAlpha.b;

    return color;
}

vec4 psTrailLow(VS_TRAIL_OUTPUT input) : COLOR
{
    vec4 color = tex2D( trailDiffuseSampler, input.texCoords0.xy);
    color.rgb *= 2*input.color.rgb;
    color.a *= input.lightFactorAndAlpha.b;

    return color;
}

vec4 psTrailShowFill(VS_TRAIL_OUTPUT input) : COLOR
{
    // apply sun fog
    vec4 color = effectSunColor.rrrr;
    return color;
}

// Ordinary technique

technique TrailLow
<
>
{
    pass p0
    {
        CullMode = NONE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = FALSE;
        StencilEnable = FALSE;
        StencilFunc = ALWAYS;
        StencilPass = ZERO;
        AlphaTestEnable = TRUE;
        AlphaRef = <alphaPixelTestRef>;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = TRUE;

        VertexShader = compile vs_2_0 vsTrail(viewMat, projMat);
        PixelShader = compile ps_2_0 psTrailLow();
    }
}
technique TrailMedium
<
>
{
    pass p0
    {
        CullMode = NONE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = FALSE;
        StencilEnable = FALSE;
        StencilFunc = ALWAYS;
        StencilPass = ZERO;
        AlphaTestEnable = TRUE;
        AlphaRef = <alphaPixelTestRef>;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = TRUE;

        VertexShader = compile vs_2_0 vsTrail(viewMat, projMat);
        PixelShader = compile ps_2_0 psTrailMedium();
    }
}
technique TrailHigh
<
>
{
    pass p0
    {
        CullMode = NONE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = FALSE;
        StencilEnable = FALSE;
        StencilFunc = ALWAYS;
        StencilPass = ZERO;
        AlphaTestEnable = TRUE;
        AlphaRef = <alphaPixelTestRef>;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = TRUE;

        VertexShader = compile vs_2_0 vsTrail(viewMat, projMat);
        PixelShader = compile ps_2_0 psTrailHigh();
    }
}
technique TrailShowFill
<
>
{
    pass p0
    {
        CullMode = NONE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = FALSE;
        StencilEnable = FALSE;
        StencilFunc = ALWAYS;
        StencilPass = ZERO;
        AlphaTestEnable = TRUE;
        AlphaRef = <alphaPixelTestRef>;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        FogEnable = TRUE;

        VertexShader = compile vs_2_0 vsTrail(viewMat, projMat);
        PixelShader = compile ps_2_0 psTrailShowFill();
    }
}

//	Heat Shimmer

struct VS_HEAT_SHIMMER_OUTPUT
{
    vec4 HPos                    : POSITION;
    vec2 texCoords0              : TEXCOORD0;
    vec3 texCoords1AndAlphaBlend : TEXCOORD1;
    scalar timingOffset          : COLOR;
};

VS_HEAT_SHIMMER_OUTPUT vsParticleHeatShimmer(appdata input, uniform mat4x4 myWV, uniform mat4x4 myWP)//,  uniform TemplateParameters templ[10])
{
    //vec4 pos = mul(vec4(input.pos.xyz,1), myWV);
    VS_HEAT_SHIMMER_OUTPUT Out = (VS_HEAT_SHIMMER_OUTPUT)0;

    scalar age = input.intensityAgeAnimBlendFactorAndAlpha[1];

    // FADE values
    scalar fadeIn = saturate(age/tParameters.m_fadeInOutTileFactorAndUVOffsetVelocity.x);
    scalar fadeOut = saturate((1.f - age)/tParameters.m_fadeInOutTileFactorAndUVOffsetVelocity.y);

    vec3 eyeVec = eyePos - input.pos;

    // project eyevec to tangent vector to get position on axis
    scalar tanPos = dot(eyeVec, input.tangent);

    // closest point to camera
    vec3 axisVec = eyeVec - (input.tangent * tanPos);
    axisVec = normalize(axisVec);

    // find rotation around axis
    vec3 norm = cross(input.tangent, input.localCoords*-1);

    scalar fadeFactor = dot(axisVec, norm);
    fadeFactor *= fadeFactor;
    fadeFactor += fadeOffset;
    fadeFactor *= fadeIn * fadeOut;

    // age factor polynomials
    vec4 pc = {age*age*age, age*age, age, 1.f};

    scalar alphaBlendFactor = min(dot(tParameters.m_transparencyGraph, pc), 1) * input.intensityAgeAnimBlendFactorAndAlpha[3];
    alphaBlendFactor *= fadeFactor;
    Out.texCoords1AndAlphaBlend.z = alphaBlendFactor;

    // comput size of particle using the constants of the templ[input.ageFactorAndGraphIndex.y]ate (mSizeGraph)
    scalar size = min(dot(tParameters.m_sizeGraph, pc), 1) * tParameters.m_uvRangeLMapIntensiyAndParticleMaxSize.w;

    // displace vertex
    vec4 pos = mul(vec4(input.pos.xyz + size*(input.localCoords.xyz*input.texCoords.y), 1), myWV);
    Out.HPos = mul(pos, myWP);

    // compute texcoords
    // Rotate and scale to correct u,v space and zoom in.
    vec2 texCoords = input.texCoords.xy * OneOverShort;

    // compute texcoords for trail
    vec2 rotatedTexCoords = input.texCoords;

    rotatedTexCoords.x -= age * tParameters.m_fadeInOutTileFactorAndUVOffsetVelocity.w;
    rotatedTexCoords *= tParameters.m_uvRangeLMapIntensiyAndParticleMaxSize.xy;
    rotatedTexCoords.x *= tParameters.m_fadeInOutTileFactorAndUVOffsetVelocity.z / tParameters.m_uvRangeLMapIntensiyAndParticleMaxSize.w;

    // Bias texcoords.
    rotatedTexCoords.x += tParameters.m_uvRangeLMapIntensiyAndParticleMaxSize.x;
    rotatedTexCoords.y = tParameters.m_uvRangeLMapIntensiyAndParticleMaxSize.y - rotatedTexCoords.y;
    rotatedTexCoords.y *= 0.5f;

    // Offset texcoords
    vec4 uvOffsets = input.uvOffsets * OneOverShort;
    Out.texCoords0.xy = rotatedTexCoords + uvOffsets.xy;

    Out.texCoords1AndAlphaBlend.xy = (vec2(Out.HPos.x,-Out.HPos.y)/Out.HPos.w+1.f)/2.f;
    Out.texCoords1AndAlphaBlend.xy += texelSize/2;

    // Set the timing offset for this instance
    Out.timingOffset = input.intensityAgeAnimBlendFactorAndAlpha.x;//input.intensityAndRandomIntensity.x;

    return Out;
}

float4 psParticleHeatShimmer(VS_HEAT_SHIMMER_OUTPUT input) : COLOR
{
    // perturb back buffer coords a bit
    scalar angle = (fracTime + input.timingOffset) * PI * 2.0;
    scalar coordsToAngle = PI * 2.0 * shimmerPhases;
    vec2 backbufferCoords = input.texCoords1AndAlphaBlend.xy
                            + float2(cos((input.texCoords1AndAlphaBlend.y) * coordsToAngle + angle) * texelSize.x * shimmerIntensity,
                                     sin((input.texCoords1AndAlphaBlend.x) * coordsToAngle + angle) * texelSize.y * shimmerIntensity);

    vec4 tBackBuffer = tex2D(backbufferSampler, backbufferCoords);
    vec4 tDiffuse = tex2D( diffuseSampler, input.texCoords0.xy);
    return vec4(tBackBuffer.rgb, 1.0);
    return vec4(tBackBuffer.rgb, tDiffuse.a * input.texCoords1AndAlphaBlend.z);
}

technique ParticleHeatShimmer
<
>
{
    pass p0
    {
        CullMode = NONE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = FALSE;
        StencilEnable = FALSE;
        StencilFunc = ALWAYS;
        StencilPass = ZERO;
        AlphaTestEnable = TRUE;
        AlphaRef = <alphaPixelTestRef>;
        AlphaBlendEnable = TRUE;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        FogEnable = FALSE;

        VertexShader = compile vs_2_0 vsParticleHeatShimmer(viewMat, projMat);
        PixelShader = compile ps_2_0 psParticleHeatShimmer();
    }
}
