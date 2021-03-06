#line 2 "TreeMesh.fx"
#include "Shaders/Math.fx"

float4x4 mvpMatrix : WorldViewProjection; // : register(vs_2_0, c0);
float4x4 worldIMatrix : WorldI;           // : register(vs_2_0, c4);
float4x4 viewInverseMatrix : ViewI;       // : register(vs_2_0, c8);

// Sprite parameters
float4x4 worldViewMatrix : WorldView;
float4x4 projMatrix : Projection;
float4 spriteScale :  SpriteScale;
float4 shadowSpherePoint : ShadowSpherePoint;
float4 boundingboxScaledInvGradientMag : BoundingboxScaledInvGradientMag;
float4 invBoundingBoxScale : InvBoundingBoxScale;
float4 shadowColor : ShadowColor;

float4 ambColor : Ambient = { 0.0f, 0.0f, 0.0f, 1.0f };
float4 diffColor : Diffuse = { 1.0f, 1.0f, 1.0f, 1.0f };
float4 specColor : Specular = { 0.0f, 0.0f, 0.0f, 1.0f };

texture texture0: TEXLAYER0;
texture texture1: TEXLAYER1;
texture texture2: TEXLAYER2;
texture texture3: TEXLAYER3;

sampler sampler0 = sampler_state { Texture = (texture0); };
sampler sampler1 = sampler_state { Texture = (texture1); };
sampler sampler2 = sampler_state { Texture = (texture2); AddressU=CLAMP; AddressV=CLAMP; };
sampler sampler3 = sampler_state { Texture = (texture3); };

float4 eyePos : EyePosition = { 0.0f, 0.0f, 1.0f, 0.0f };

float4 lightPos : LightPosition
<
    string Object = "PointLight";
    string Space = "World";
> = { 0.0f, 0.0f, 1.0f, 1.0f };

float4 lightDir : LightDirection;
float heightmapSize : HeightmapSize;
float normalOffsetScale : NormalOffsetScale;
float hemiLerpBias : HemiLerpBias;
float4 skyColor : SkyColor;
float4 ambientColor : AmbientColor;
float4 sunColor : SunColor;

float attenuationSqrInv : AttenuationSqrInv;
float4 lightColor : LightColor;
float coneAngle : ConeAngle;

sampler diffuseSampler = sampler_state
{
    Texture = <texture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler normalSampler = sampler_state
{
    Texture = <texture1>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler dummySampler = sampler_state
{
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler colorLUTSampler = sampler_state
{
    Texture = <texture2>;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler diffuseAlphaSampler = sampler_state
{
    Texture = <texture3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct appdata
{
    float4 Pos       : POSITION;
    float3 Normal    : NORMAL;
    float2 TexCoord  : TEXCOORD0;
    float2 TexCoord1 : TEXCOORD1;
    float4 Tan       : TANGENT;
};

struct appdata2
{
    float4 Pos          : POSITION;
    float3 Normal       : NORMAL;
    float2 TexCoord     : TEXCOORD0;
    float2 Width_height : TEXCOORD1;
    float4 Tan          : TANGENT;
};

struct VS_OUTPUT
{
    float4 HPos      : POSITION;
    float2 TexCoord  : TEXCOORD0;
    float2 TexCoord2 : TEXCOORD1;
    float4 LightVec  : TEXCOORD2;
    float4 HalfVec   : TEXCOORD3;
    float4 Diffuse   : COLOR;
};

struct VS_OUTPUT2
{
    float4 HPos     : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Diffuse  : COLOR;
};

VS_OUTPUT bumpSpecularVertexShaderBlinn1
(
    appdata input,
    uniform float4x4 WorldViewProj,
    uniform float4x4 WorldIT,
    uniform float4x4 ViewInv,
    uniform float4 LightPos,
    uniform float4 EyePos
)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    Out.HPos = mul(input.Pos, WorldViewProj);

    // Cross product to create BiNormal
    float3 binormal = cross(input.Tan, input.Normal);
    binormal = normalize(binormal);

    // Pass-through texcoords
    Out.TexCoord = input.TexCoord;
    Out.TexCoord2 = input.TexCoord;

    // Transform Light pos to Object space
    float3 matsLightDir = float3(0.2f, 0.8f, -0.2f);
    float3 lightDirObjSpace = mul(-matsLightDir, WorldIT);
    float3 normalizedLightVec = normalize(lightDirObjSpace);

    // TANGENT SPACE LIGHT
    // This way of geting the tangent space data changes the coordinate system
    float3 tanLightVec = float3(dot(-normalizedLightVec, input.Tan),
                                dot(-normalizedLightVec, binormal),
                                dot(-normalizedLightVec, input.Normal));

    // Compress L' in tex2... don't compress, autoclamp >0
    float3 normalizedTanLightVec = normalize(tanLightVec);
    Out.LightVec = float4((0.5f + normalizedTanLightVec * 0.5f).xyz, 0.0f);

    // Transform eye pos to tangent space
    float4 matsEyePos = float4(0.0f, 0.0f, 1.0f, 0.0f);
    float4 worldPos = mul(matsEyePos, ViewInv);

    float3 objPos = mul1(worldPos.xyz, WorldIT);
    float3 tanPos = float3( dot(objPos, input.Tan),
                            dot(objPos, binormal),
                            dot(objPos, input.Normal));

    float3 halfVector = normalize(normalizedTanLightVec + tanPos);
    // Compress H' in tex3... don't compress, autoclamp > 0
    Out.HalfVec = float4((0.5f + -halfVector * 0.5f).xyz, 1.0f);
    float color = 0.8f + max(0.0f, dot(input.Normal, normalizedLightVec));
    Out.Diffuse = float4(color, color, color, 1.0f);

    return Out;
}

VS_OUTPUT2 spriteVertexShader
(
    appdata2 input,
    uniform float4x4 WorldView,
    uniform float4x4 Proj,
    uniform float4 SpriteScale,
    uniform float4 ShadowSpherePoint,
    uniform float4 InvBoundingBoxScale,
    uniform float4 BoundingboxScaledInvGradientMag,
    uniform float4 ShadowColor,
    uniform float4 LightColor
)
{
    VS_OUTPUT2 Out = (VS_OUTPUT2)0;
    float4 pos =  mul(input.Pos, WorldView);
    float4 scaledPos = float4(float2(input.Width_height.xy * SpriteScale.xy), 0.0, 0.0) + (pos);
    Out.HPos = mul(scaledPos, Proj);
    Out.TexCoord = input.TexCoord;

    // lighting calc
    float4 eyeSpaceSherePoint = mul(ShadowSpherePoint, WorldView);
    float4 shadowSpherePos = scaledPos * InvBoundingBoxScale;
    float4 eyeShadowSperePos = eyeSpaceSherePoint * InvBoundingBoxScale;
    float4 vectorMagnitude = normalize(shadowSpherePos - eyeShadowSperePos);
    float shadowFactor = vectorMagnitude * BoundingboxScaledInvGradientMag;
    shadowFactor = min(shadowFactor, 1.0);
    float3 shadowColorInt = ShadowColor * (1.0 - shadowFactor);
    float3 color = LightColor * shadowFactor + shadowColorInt;
    Out.Diffuse =  float4(color, 1.0f);

    return Out;
}

struct OUT_vsBumpSpecularHemiAndSunPV
{
    float4 HPos            : POSITION;
    float2 NormalMap       : TEXCOORD0;
    float3 LightVec        : TEXCOORD1;
    float3 HalfVec         : TEXCOORD2;
    float3 GroundUVAndLerp : TEXCOORD3;
    float2 DiffuseAlpha    : TEXCOORD4;
};

OUT_vsBumpSpecularHemiAndSunPV vsBumpSpecularHemiAndSunPV
(
    appdata input,
    uniform float4x4 ViewProj,
    uniform float4x4 ViewInv,
    uniform float4 LightDir,
    uniform float HeightmapSize,
    uniform float NormalOffsetScale
)
{
    OUT_vsBumpSpecularHemiAndSunPV Out = (OUT_vsBumpSpecularHemiAndSunPV)0;

    Out.HPos = mul1(input.Pos, ViewProj);

    // Hemi lookup values
    float3 AlmostNormal = input.Normal.xyz;
    Out.GroundUVAndLerp.xy = (input.Pos + (HeightmapSize * 0.5) + AlmostNormal).xz / HeightmapSize;
    Out.GroundUVAndLerp.z = AlmostNormal.y * 0.5 + 0.5;

    // Cross product to create BiNormal
    float3 binormal = normalize(cross(input.Tan, input.Normal));

    // Need to calculate the WorldI based on each matBone skinning world matrix
    float3x3 TanBasis = float3x3(input.Tan.xyz, binormal, input.Normal.xyz);

    // Pass-through texcoords
    Out.NormalMap = input.TexCoord;

    // Transform Light dir to Object space, lightdir is already in object space.
    float3 normalizedTanLightVec = normalize(mul(-LightDir, TanBasis));

    Out.LightVec = normalizedTanLightVec;

    // Transform eye pos to tangent space
    float3 worldEyeVec = ViewInv[3].xyz - input.Pos.xyz;
    float3 tanEyeVec = mul(worldEyeVec, TanBasis);

    Out.HalfVec = normalize(normalizedTanLightVec + normalize(tanEyeVec));

    return Out;
}

float4 psBumpSpecularHemiAndSunPV(  OUT_vsBumpSpecularHemiAndSunPV indata,
                                    uniform float4 SkyColor,
                                    uniform float4 AmbientColor,
                                    uniform float4 SunColor) : COLOR
{
    float4 normalmap = tex2D(sampler0, indata.NormalMap);
    float3 expandedNormal = normalmap.xyz * 2.0 - 1.0;
    float4 diffuse = tex2D(sampler3, indata.NormalMap);
    float2 intensityuv = float2(dot(indata.LightVec, expandedNormal), dot(indata.HalfVec, expandedNormal));

    float4 intensity = tex2D(sampler2, intensityuv);
    float realintensity = intensity.b + intensity.a * normalmap.a;
    realintensity *= SunColor;

    float4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
    float4 hemicolor = lerp(groundcolor, SkyColor, indata.GroundUVAndLerp.z - hemiLerpBias);
    float4 result = AmbientColor * hemicolor + (realintensity * groundcolor.a * groundcolor.a);
    result.a = diffuse.a;
    return result;
}

technique HemiAndSun_States <bool Restore = true;>
{
    pass BeginStates
    {
        AlphaTestEnable = TRUE;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        // Normal
        AddressU[0] = WRAP;
        AddressV[0] = WRAP;
        MipFilter[0] = LINEAR;
        MinFilter[0] = LINEAR;
        MagFilter[0] = LINEAR;

        // GroundHemi
        AddressU[1] = CLAMP;
        AddressV[1] = CLAMP;
        MinFilter[1] = LINEAR;
        MagFilter[1] = LINEAR;

        // LUT
        AddressU[2] = CLAMP;
        AddressV[2] = CLAMP;
        MinFilter[2] = LINEAR;
        MagFilter[2] = LINEAR;

        // Diffuse
        AddressU[3] = WRAP;
        AddressV[3] = WRAP;
        MipFilter[3] = LINEAR;
        MinFilter[3] = LINEAR;
        MagFilter[3] = LINEAR;
    }

    pass EndStates {}
}

technique HemiAndSun
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        VertexShader = compile vs_2_0 vsBumpSpecularHemiAndSunPV(   mvpMatrix,
                                                                    viewInverseMatrix,
                                                                    lightDir,
                                                                    heightmapSize,
                                                                    normalOffsetScale);
        PixelShader = compile ps_2_0 psBumpSpecularHemiAndSunPV(skyColor, ambientColor, sunColor);
    }
}

struct OUT_vsBumpSpecularPointLight
{
    float4 HPos           : POSITION;
    float2 NormalMap      : TEXCOORD0;
    float3 LightVec       : TEXCOORD1;
    float3 HalfVec        : TEXCOORD2;
    float3 ObjectLightVec : TEXCOORD3;
};

OUT_vsBumpSpecularPointLight vsBumpSpecularPointLight
(
    appdata input,
    uniform float4x4 ViewProj,
    uniform float4x4 ViewInv,
    uniform float4 LightPos
)
{
    OUT_vsBumpSpecularPointLight Out = (OUT_vsBumpSpecularPointLight)0;

    Out.HPos = mul1(input.Pos, ViewProj);

    // Cross product to create BiNormal
    float3 binormal = normalize(cross(input.Tan, input.Normal));

    // Need to calculate the WorldI based on each matBone skinning world matrix
    float3x3 TanBasis = float3x3( input.Tan.xyz, binormal, input.Normal.xyz);

    // Pass-through texcoords
    Out.NormalMap = input.TexCoord;

    // Transform Light vec to Tangentspace space
    float3 lvec = LightPos-input.Pos;
    Out.ObjectLightVec = lvec;
    float3 tanLightVec = mul(lvec, TanBasis);

    Out.LightVec = tanLightVec;

    // Transform eye pos to tangent space
    float3 objEyeVec = ViewInv[3].xyz - input.Pos.xyz;
    float3 tanEyeVec = mul(objEyeVec, TanBasis);

    Out.HalfVec = normalize(normalize(tanLightVec) + normalize(tanEyeVec));

    return Out;
}

float4 psBumpSpecularPointLight(OUT_vsBumpSpecularPointLight indata,
                                uniform float AttenuationSqrInv,
                                uniform float4 LightColor) : COLOR
{
    float4 normalmap = tex2D(sampler0, indata.NormalMap);
    float3 expandedNormal = normalmap.xyz * 2.0 - 1.0;
    float4 diffuse = tex2D(sampler3, indata.NormalMap);

    float3 normalizedLVec = normalize(indata.LightVec);
    float2 intensityuv = float2(dot(normalizedLVec,expandedNormal), dot(indata.HalfVec,expandedNormal));
    float4 realintensity = intensityuv.r + pow(intensityuv.g, 36.0) * normalmap.a;
    realintensity *= LightColor;

    float attenuation = saturate(1.0 - dot(indata.ObjectLightVec, indata.ObjectLightVec) * AttenuationSqrInv);
    float4 result = attenuation * realintensity;
    result.a = diffuse.a;
    return result;
}

technique PointLight_States <bool Restore = true;>
{
    pass BeginStates
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = DESTALPHA;
        DestBlend = ONE;

        // Normal
        AddressU[0] = WRAP;
        AddressV[0] = WRAP;
        MipFilter[0] = LINEAR;
        MinFilter[0] = LINEAR;
        MagFilter[0] = LINEAR;
    }

    pass EndStates {}
}

technique PointLight
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = DESTALPHA;
        DestBlend = ONE;

        // Normal
        AddressU[0] = WRAP;
        AddressV[0] = WRAP;
        MipFilter[0] = LINEAR;
        MinFilter[0] = LINEAR;
        MagFilter[0] = LINEAR;

        VertexShader = compile vs_2_0 vsBumpSpecularPointLight(mvpMatrix, viewInverseMatrix, lightPos);
        PixelShader = compile ps_2_0 psBumpSpecularPointLight(attenuationSqrInv, lightColor);
    }
}

struct OUT_vsBumpSpecularSpotLight
{
    float4 HPos      : POSITION;
    float2 NormalMap : TEXCOORD0;
    float3 LightVec  : TEXCOORD1;
    float3 HalfVec   : TEXCOORD2;
    float3 LightDir  : TEXCOORD3;
};

OUT_vsBumpSpecularSpotLight vsBumpSpecularSpotLight
(
    appdata input,
    uniform float4x4 ViewProj,
    uniform float4x4 ViewInv,
    uniform float4 LightPos,
    uniform float4 LightDir
)
{
    OUT_vsBumpSpecularSpotLight Out = (OUT_vsBumpSpecularSpotLight)0;

    // Compensate for lack of UBYTE4 on Geforce3
    Out.HPos = mul1(input.Pos, ViewProj);

    // Cross product to create BiNormal
    float3 binormal = normalize(cross(input.Tan, input.Normal));

    // Need to calculate the WorldI based on each matBone skinning world matrix
    float3x3 TanBasis = float3x3( input.Tan.xyz, binormal, input.Normal.xyz);

    // Pass-through texcoords
    Out.NormalMap = input.TexCoord;

    // Transform Light vec to Object space
    float3 lvec = LightPos-input.Pos.xyz;
    float3 tanLightVec = mul(lvec, TanBasis);
    Out.LightVec = tanLightVec;

    // Transform eye pos to tangent space
    // Gottcha ViewInv[3].xyz is in worldspace... must rewrite..
    float3 objEyeVec = ViewInv[3].xyz - input.Pos.xyz;
    float3 tanEyeVec = mul(objEyeVec, TanBasis);

    Out.HalfVec = normalize(normalize(tanLightVec) + normalize(tanEyeVec));

    // Light direction in tan space
    Out.LightDir = mul(-LightDir, TanBasis);

    return Out;
}

float4 psBumpSpecularSpotLight( OUT_vsBumpSpecularSpotLight indata,
                                uniform float AttenuationSqrInv,
                                uniform float4 LightColor,
                                uniform float LightConeAngle) : COLOR
{
    float offCenter = dot(normalize(indata.LightVec), indata.LightDir);
    float conicalAtt = saturate(offCenter - (1.0 - LightConeAngle)) / LightConeAngle;

    float4 normalmap = tex2D(sampler0, indata.NormalMap);
    float3 expandedNormal = normalmap.xyz * 2.0 - 1.0;

    float3 normalizedLVec = normalize(indata.LightVec);
    float2 intensityuv = float2(dot(normalizedLVec,expandedNormal), dot(indata.HalfVec,expandedNormal));
    float4 realintensity = intensityuv.r + pow(intensityuv.g, 36.0) * normalmap.a;
    realintensity *= LightColor;
    float radialAtt = 1.0 - saturate(dot(indata.LightVec, indata.LightVec) * AttenuationSqrInv);
    return realintensity * conicalAtt * radialAtt;
}

technique SpotLight_States <bool Restore = true;>
{
    pass BeginStates
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = DESTALPHA;
        DestBlend = ONE;

        // Normal
        AddressU[0] = WRAP;
        AddressV[0] = WRAP;
        MipFilter[0] = LINEAR;
        MinFilter[0] = LINEAR;
        MagFilter[0] = LINEAR;
    }

    pass EndStates {}
}

technique SpotLight
{
    pass p0
    {
        AlphaBlendEnable = TRUE;
        SrcBlend = DESTALPHA;
        DestBlend = ONE;

        // Normal
        AddressU[0] = WRAP;
        AddressV[0] = WRAP;
        MipFilter[0] = LINEAR;
        MinFilter[0] = LINEAR;
        MagFilter[0] = LINEAR;

        VertexShader = compile vs_2_0 vsBumpSpecularSpotLight(  mvpMatrix,
                                                                viewInverseMatrix,
                                                                lightPos, lightDir);
        PixelShader = compile ps_2_0 psBumpSpecularSpotLight(attenuationSqrInv, lightColor, coneAngle);
    }
}

struct OUT_vsBumpSpecularMulDiffuse
{
    float4 HPos       : POSITION;
    float2 DiffuseMap : TEXCOORD0;
};

OUT_vsBumpSpecularMulDiffuse vsBumpSpecularMulDiffuse
(
    appdata input,
    uniform float4x4 ViewProj,
    uniform float4x4 ViewInv
)
{
    OUT_vsBumpSpecularMulDiffuse Out = (OUT_vsBumpSpecularMulDiffuse)0;

    // Compensate for lack of UBYTE4 on Geforce3
    Out.HPos = mul1(input.Pos, ViewProj);

    // Pass-through texcoords
    Out.DiffuseMap = input.TexCoord;

    return Out;
}

float4 psBumpSpecularMulDiffuse(OUT_vsBumpSpecularMulDiffuse indata) : COLOR
{
    return tex2D(sampler0, indata.DiffuseMap);
}

technique MulDiffuse
{
    pass p0
    {
        ZFunc = EQUAL;
        ZWriteEnable = FALSE;

        AlphaBlendEnable = TRUE;
        SrcBlend = DESTCOLOR;
        DestBlend = INVSRCALPHA;

        // Diffuse
        AddressU[0] = WRAP;
        AddressV[0] = WRAP;
        MipFilter[0] = LINEAR;
        MinFilter[0] = LINEAR;
        MagFilter[0] = LINEAR;

        VertexShader = compile vs_2_0 vsBumpSpecularMulDiffuse(mvpMatrix, viewInverseMatrix);
        PixelShader = compile ps_2_0 psBumpSpecularMulDiffuse();
    }
}

float4 bumpSpecularPixelShaderBlinn1(VS_OUTPUT input) : COLOR
{
    float4 diffuseMap = tex2D(diffuseSampler, input.TexCoord);
    return diffuseMap * input.Diffuse;
}

technique trunk
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = true;
        AlphaBlendEnable = false;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_0 bumpSpecularVertexShaderBlinn1(   mvpMatrix,
                                                                        worldIMatrix,
                                                                        viewInverseMatrix,
                                                                        lightPos,
                                                                        eyePos);
        PixelShader = compile ps_2_0 bumpSpecularPixelShaderBlinn1();
    }
}

float4 spritePixelShader(VS_OUTPUT2 input) : COLOR
{
    float4 diffuseMap = tex2D(diffuseSampler, input.TexCoord);
    return diffuseMap * input.Diffuse;
}

technique sprite
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

        VertexShader = compile vs_2_0 spriteVertexShader(   worldViewMatrix,
                                                            projMatrix,
                                                            spriteScale,
                                                            shadowSpherePoint,
                                                            invBoundingBoxScale,
                                                            boundingboxScaledInvGradientMag,
                                                            shadowColor,
                                                            lightColor);
        PixelShader = compile ps_2_0 spritePixelShader();
    }
}
