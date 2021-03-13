#line 2 "BundledMesh.fx"
#include "shaders/datatypes.fx"
// #include "shaders/common.dfx"

// UNIFORM INPUTS
mat4x4 viewProjMatrix : WorldViewProjection;     // : register(vs_2_0, c0);
mat4x4 viewInverseMatrix : ViewI;                // : register(vs_2_0, c8);
mat4x3 mOneBoneSkinning[52]: matONEBONESKINNING; // : register(c15) < bool sparseArray = true; int arrayStart = 15; >;
mat4x4 viewMatrix : ViewMatrix;
mat4x4 viewITMatrix : ViewITMatrix;

vec4 ambColor : Ambient = { 0.0f, 0.0f, 0.0f, 1.0f };
vec4 diffColor : Diffuse = { 1.0f, 1.0f, 1.0f, 1.0f };
vec4 specColor : Specular = { 0.0f, 0.0f, 0.0f, 1.0f };

mat4x4 vpLightMat : vpLightMat;
mat4x4 vpLightTrapezMat : vpLightTrapezMat;
vec4 PosUnpack : POSUNPACK;

vec2 vTexProjOffset : TEXPROJOFFSET;
vec2 zLimitsInv : ZLIMITSINV;

scalar shadowAlphaThreshold : SHADOWALPHATHRESHOLD;
mat4x4 mLightVP : LIGHTVIEWPROJ;
vec4 vViewportMap : VIEWPORTMAP;

dword dwStencilRef : STENCILREF = 0;
vec4 eyePos : EYEPOS = { 0.0f, 0.0f, 1.0f, 0.25f };
scalar altitudeFactor : ALTITUDEFACTOR = 0.7f;

texture texture0: TEXLAYER0;
texture texture1: TEXLAYER1;
texture texture2: TEXLAYER2;
texture texture3: TEXLAYER3;
texture texture4: TEXLAYER4;

// SHADOW BUFFER DATA
/*
    texture ShadowMap: ShadowMapTex;
    sampler ShadowMapSampler = sampler_state
    {
        Texture = ( ShadowMap );
        AddressU = CLAMP;
        AddressV = CLAMP;
        MinFilter = POINT;
        MagFilter = POINT;
        MipFilter = NONE;
    };

    texture ShadowMapOccluder:	ShadowMapOccluderTex;
    sampler ShadowMapOccluderSampler = sampler_state
    {
        Texture = ( ShadowMapOccluder );
        AddressU = CLAMP;
        AddressV = CLAMP;
        MinFilter = POINT;
        MagFilter = POINT;
        MipFilter = NONE;
    };
*/

mat4x4 ViewPortMatrix : ViewPortMatrix;
vec4 ViewportMap : ViewportMap;

bool alphaBlendEnable:	AlphaBlendEnable;

sampler sampler0 = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler1 = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler2 = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler3 = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
// sampler sampler3 = sampler_state { Texture = (texture3); };
sampler sampler1point = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler2point = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };

sampler samplerNormal2 = sampler_state { Texture = (texture2); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
samplerCUBE samplerCube2 = sampler_state { Texture = (texture2); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
samplerCUBE samplerCube3 = sampler_state { Texture = (texture3); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
samplerCUBE samplerCube4 = sampler_state { Texture = (texture4); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

sampler sampler2Aniso = sampler_state
{
    Texture = (texture2);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = Anisotropic;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    MaxAnisotropy = 8;
};

vec4 lightPos : LightPosition;

// vec4 eyePos;

vec4 lightDir : LightDirection;

// offset x/y heightmapsize z / hemilerpbias w
vec4 hemiMapInfo : HemiMapInfo;

// scalar heightmapSize : HeightmapSize;
// scalar hemiLerpBias : HemiLerpBias;
scalar normalOffsetScale : NormalOffsetScale;

vec4 skyColor : SkyColor;
vec4 ambientColor : AmbientColor;
vec4 sunColor : SunColor;

scalar attenuationSqrInv : AttenuationSqrInv;
vec4 lightColor : LightColor;
scalar coneAngle : ConeAngle;

vec4 paraboloidValues : ParaboloidValues;
vec4 paraboloidZValues : ParaboloidZValues;

mat4x3 uvMatrix[8]: UVMatrix;

sampler diffuseSampler = sampler_state
{
    Texture = <texture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    // MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler normalSampler = sampler_state
{
    Texture = <texture1>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    // MipMapLodBias = 0;
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

struct appdata
{
    vec4 Pos          : POSITION;
    vec3 Normal       : NORMAL;
    vec4 BlendIndices : BLENDINDICES;
    vec2 TexCoord     : TEXCOORD0;
    vec3 Tan          : TANGENT;
    vec3 Binorm       : BINORMAL;
};

struct appdataDiffuseZ
{
    vec4 Pos          : POSITION;
    vec4 BlendIndices : BLENDINDICES;
    vec2 TexCoord     : TEXCOORD0;
};

struct appdataDiffuseZAnimatedUV
{
    vec4 Pos          : POSITION;
    vec4 BlendIndices : BLENDINDICES;
    vec2 TexCoord0    : TEXCOORD0;
    vec2 TexCoord1    : TEXCOORD1;
};

struct appdataAnimatedUV
{
    vec4 Pos          : POSITION;
    vec3 Normal       : NORMAL;
    vec4 BlendIndices : BLENDINDICES;
    vec2 TexCoord0    : TEXCOORD0;
    vec2 TexCoord1    : TEXCOORD1;
    vec3 Tan          : TANGENT;
    vec3 Binorm       : BINORMAL;
};

struct VS_OUTPUT
{
    vec4 HPos      : POSITION;
    vec2 NormalMap : TEXCOORD0;
    vec3 LightVec  : TEXCOORD1;
    vec3 HalfVec   : TEXCOORD2;
    vec2 DiffMap   : TEXCOORD3;
    float Fog      : FOG;
};

struct VS_OUTPUT20
{
    vec4 HPos     : POSITION;
    vec2 Tex0     : TEXCOORD0;
    vec3 LightVec : TEXCOORD1;
    vec3 HalfVec  : TEXCOORD2;
    float Fog     : FOG;
};

struct VS_OUTPUTSS
{
    vec4 HPos      : POSITION;
    vec4 TanNormal : COLOR0;
    vec4 TanLight  : COLOR1;
    vec2 NormalMap : TEXCOORD0;
    vec3 LightVec  : TEXCOORD1;
    vec3 HalfVec   : TEXCOORD2;
    vec2 DiffMap   : TEXCOORD3;
    float Fog      : FOG;
};

struct VS_OUTPUT2
{
    vec4 HPos     : POSITION;
    vec2 TexCoord : TEXCOORD0;
    vec4 Diffuse  : COLOR;
    float Fog     : FOG;
};


VS_OUTPUT bumpSpecularVertexShaderBlinn1(appdata input,
                                        uniform mat4x4 ViewProj,
                                        uniform mat4x4 ViewInv,
                                        uniform vec4 LightPos)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    vec4 Constants = vec4(0.5, 0.5, 0.5, 1.0);

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    vec3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(vec4(Pos.xyz, 1.0f), ViewProj);

    // Cross product to create BiNormal
    vec3 binormal = normalize(cross(input.Tan, input.Normal));

    // Need to calculate the WorldI based on each matBone skinning world matrix
    mat3x3 TanBasis = mat3x3(input.Tan, binormal, input.Normal);

    // Calculate WorldTangent directly... inverse is the transpose for affine rotations
    mat3x3 worldI = transpose(mul(TanBasis, mOneBoneSkinning[IndexArray[0]]));

    // Pass-through texcoords
    Out.NormalMap = input.TexCoord;
    Out.DiffMap = input.TexCoord;

    // Transform Light pos to Object space
    // vec4 matsLightDir = vec4(0.2, 0.8, -0.2, 1.);
    // vec3 matsLightDir = vec3(0.0, 1.0, 0.0);
    vec3 matsLightDir = vec3(0.5, 0.5, 0.0);
    vec3 normalizedTanLightVec = normalize(mul(matsLightDir, worldI));

    Out.LightVec = normalizedTanLightVec;

    // Transform eye pos to tangent space
    vec3 worldEyeVec = ViewInv[3].xyz - Pos;
    vec3 tanEyeVec = mul(worldEyeVec, worldI);

    Out.HalfVec = normalize(normalizedTanLightVec + normalize(tanEyeVec));
    Out.Fog = 0.0; // calcFog(Out.HPos.w);

    return Out;
}

VS_OUTPUT20 bumpSpecularVertexShaderBlinn20(appdata input,
                                            uniform mat4x4 ViewProj,
                                            uniform mat4x4 ViewInv,
                                            uniform vec4 LightPos)
{
    VS_OUTPUT20 Out = (VS_OUTPUT20)0;

    vec4 Constants = vec4(0.5, 0.5, 0.5, 1.0);

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    vec3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(vec4(Pos.xyz, 1.0), ViewProj);

    // Cross product to create BiNormal
    vec3 binormal = normalize(cross(input.Tan, input.Normal));

    // Need to calculate the WorldI based on each matBone skinning world matrix
    mat3x3 TanBasis = mat3x3(input.Tan, binormal, input.Normal);

    // Calculate WorldTangent directly... inverse is the transpose for affine rotations
    mat3x3 worldI = transpose(mul(TanBasis, mOneBoneSkinning[IndexArray[0]]));

    // Pass-through texcoords
    Out.Tex0 = input.TexCoord;

    // Transform Light pos to Object space
    // vec4 matsLightDir = vec4(0.2, 0.8, -0.2, 1.0);
    // vec3 matsLightDir = vec3(0.0, 1.0, 0.0);
    vec3 matsLightDir = vec3(0.5, 0.5, 0.0);
    vec3 normalizedTanLightVec = normalize(mul(matsLightDir, worldI));

    Out.LightVec = normalizedTanLightVec;

    // Transform eye pos to tangent space
    vec3 worldEyeVec = ViewInv[3].xyz - Pos;
    vec3 tanEyeVec = mul(worldEyeVec, worldI);

    Out.HalfVec = normalize(normalizedTanLightVec + normalize(tanEyeVec));
    Out.Fog = 0.0; // calcFog(Out.HPos.w);

    return Out;
}

vec4 PShade2(VS_OUTPUT20 i) : COLOR
{
    vec4 cosang, tDiffuse, tNormal, col, tShadow;
    vec3 tLight;

    // Sample diffuse texture and Normal map
    tDiffuse = tex2D( diffuseSampler, i.Tex0 );

    // sample tLight  (_bx2 = 2 * source � 1)
    tNormal = tex2D(normalSampler, i.Tex0) * 2.0 - 1.0;
    tLight = i.LightVec * 2.0 - 1.0;

    // return vec4(tLight.xyz,1.f);

    // DP Lighting in tangent space (where normal map is based)
    // Modulate with Diffuse texture
    col = dot(tNormal.xyz, tLight ) * tDiffuse;

    // N.H for specular term
    cosang = dot( tNormal.xyz, i.HalfVec);
    // Raise to a power for falloff
    cosang = pow(cosang, 32.0) * tNormal.w; // try changing the power to 255!

    // return vec4(tNormal.www, 1.0);
    // return vec4(cosang.xyz, 1.0);
    // return vec4(col.xyz, 1.0);
    // Sample shadow texture
    tShadow = tex2D( sampler3, i.Tex0 );

    // return vec4(tShadow.xyz,1.0);
    // Add to diffuse lit texture value
    vec4 res = (col + cosang) * tShadow;
    // vec4 res = col * tShadow;
    return vec4(res.xyz, tDiffuse.w);
}

VS_OUTPUT2 diffuseVertexShader(appdata input,
                               uniform mat4x4 ViewProj,
                               uniform mat4x4 ViewInv,
                               uniform vec4 LightPos,
                               uniform vec4 EyePos)
{
    VS_OUTPUT2 Out = (VS_OUTPUT2)0;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    // vec3 Pos = input.Pos;
    vec3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(vec4(Pos.xyz, 1.0), ViewProj);
    // Out.HPos = mul(input.Pos, WorldViewProj);

    vec3 Normal = input.Normal;
    // vec3 Normal = mul(input.Normal, mOneBoneSkinning[IndexArray[0]]);
    Normal = normalize(Normal);

    // Pass-through texcoords
    Out.TexCoord = input.TexCoord;

    // Need to calculate the WorldI based on each matBone skinning world matrix
    // There must be a more efficient way to do this...
    // Inverse is simplified to M-1 = Rt * T,
    // where Rt is the transpose of the rotaional part and T is the translation
    mat4x4 worldI;
    mat3x3 R;
    R[0] = vec3(mOneBoneSkinning[IndexArray[0]][0].xyz);
    R[1] = vec3(mOneBoneSkinning[IndexArray[0]][1].xyz);
    R[2] = vec3(mOneBoneSkinning[IndexArray[0]][2].xyz);
    mat3x3 Rtranspose = transpose(R);
    vec3 T = mul(mOneBoneSkinning[IndexArray[0]][3],Rtranspose);
    worldI[0] = vec4(Rtranspose[0].xyz,T.x);
    worldI[1] = vec4(Rtranspose[1].xyz,T.y);
    worldI[2] = vec4(Rtranspose[2].xyz,T.z);
    worldI[3] = vec4(0.0, 0.0, 0.0, 1.0);

    // Transform Light pos to Object space
    vec3 matsLightDir = vec3(0.2, 0.8, -0.2);
    vec3 lightDirObjSpace = mul(-matsLightDir, worldI);
    vec3 normalizedLightVec = normalize(lightDirObjSpace);

    scalar color = 0.8 + max(0.0, dot(Normal, normalizedLightVec));
    Out.Diffuse = vec4(color, color, color, 1.0);
    Out.Fog = 0.0; // calcFog(Out.HPos.w);

    return Out;
}

float4 bumpSpecularPixelShaderBlinn1(VS_OUTPUT input) : COLOR
{
    /*
        Few things to consider:
        - texm3x2pad and texm3x2tex depend on eachother
        - Do (x * 2.0 - 1.0) because that's translated from HLSL's _bx2 registry modifier:
          https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx9-graphics-reference-asm-ps-registers-modifiers-signed-scale
    */

    const float ambient = float4(0.4, 0.4, 0.4, 1.0);
    const float diffuse = 1.0;
    const float specular = 1.0;

    float4 NormalMap = tex2D(normalSampler, input.NormalMap);
    float u = dot(input.NormalMap * 2.0 - 1.0, input.LightVec);
    float v = dot(input.NormalMap * 2.0 - 1.0, input.HalfVec);
    float4 gloss = tex2D(diffuseSampler, float2(u, v));
    float4 DiffuseMap = tex2D(diffuseSampler, input.DiffMap);

    float4 output;
    output = saturate(gloss * diffuse + ambient);
    output *= DiffuseMap;

    float spec = NormalMap.a * gloss.a;
    return saturate(spec * specular + output);
}

float4 diffusePixelShader(VS_OUTPUT2 input) : COLOR
{
    float4 diffuse = tex2D(diffuseSampler, input.TexCoord);
    return diffuse * input.Diffuse;
}

technique Full_States < bool Restore = true; >
{
    pass BeginStates
    {
        AlphaTestEnable = TRUE;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        Sampler[1] = <dummySampler>;
        Sampler[2] = <colorLUTSampler>;
    }

    pass EndStates { }
}

technique Full
{
    pass p0
    {
        VertexShader = compile vs_2_0 bumpSpecularVertexShaderBlinn1(viewProjMatrix,
                                                                     viewInverseMatrix,
                                                                     lightPos);
        PixelShader = compile ps_2_0 bumpSpecularPixelShaderBlinn1();
    }
}

technique Full20
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = true;
        AlphaBlendEnable = false;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_0 bumpSpecularVertexShaderBlinn20(viewProjMatrix,
                                                                      viewInverseMatrix,
                                                                      lightPos);
        PixelShader = compile ps_2_0 PShade2();
    }
}

technique t1
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = true;
        // CullMode = NONE;
        AlphaBlendEnable = false;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;
        // FillMode = WIREFRAME;

        VertexShader = compile vs_2_0 diffuseVertexShader(viewProjMatrix,
                                                          viewInverseMatrix,
                                                          lightPos,
                                                          eyePos);
        PixelShader = compile ps_2_0 diffusePixelShader();
    }
}


struct VS_OUTPUT_Alpha
{
    vec4 HPos       : POSITION;
    vec2 DiffuseMap : TEXCOORD0;
    vec4 Tex1       : TEXCOORD1;
    float Fog       : FOG;
};

struct VS_OUTPUT_AlphaEnvMap
{
    vec4 HPos                : POSITION;
    vec2 DiffuseMap          : TEXCOORD0;
    vec4 TexPos              : TEXCOORD1;
    vec2 NormalMap           : TEXCOORD2;
    vec4 TanToCubeSpace1     : TEXCOORD3;
    vec4 TanToCubeSpace2     : TEXCOORD4;
    vec4 TanToCubeSpace3     : TEXCOORD5;
    vec4 EyeVecAndReflection : TEXCOORD6;
    float Fog                : FOG;
};

VS_OUTPUT_Alpha vsAlpha(appdata input, uniform mat4x4 ViewProj)
{
    VS_OUTPUT_Alpha Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    vec3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(vec4(Pos.xyz, 1.0), ViewProj);

    Out.DiffuseMap = input.TexCoord.xy;

    // Hacked to only support 800/600
    Out.Tex1.xy = Out.HPos.xy / Out.HPos.w;
    Out.Tex1.xy = Out.Tex1.xy * 0.5 + 0.5;
    Out.Tex1.y = 1.0 - Out.Tex1.y;
    Out.Tex1.xy += vTexProjOffset;
    // Out.Tex1.x += 0.000625;
    // Out.Tex1.y += 0.000833;
    Out.Tex1.xy = Out.Tex1.xy * Out.HPos.w;
    Out.Tex1.zw = Out.HPos.zw;
    Out.Fog = 0.0; // calcFog(Out.HPos.w);

    return Out;
}

vec4 psAlpha(VS_OUTPUT_Alpha indata) : COLOR
{
    vec4 projlight = tex2Dproj(sampler1, indata.Tex1);
    vec4 OutCol;
    OutCol = tex2D(sampler0, indata.DiffuseMap);
    OutCol.rgb *= projlight.rgb;
    OutCol.rgb += projlight.a;
    return OutCol;
}

VS_OUTPUT_AlphaEnvMap vsAlphaEnvMap(appdata input, uniform mat4x4 ViewProj)
{
    VS_OUTPUT_AlphaEnvMap Out = (VS_OUTPUT_AlphaEnvMap)0;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    vec3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(vec4(Pos.xyz, 1.0), ViewProj);

    // Hacked to only support 800/600
    Out.TexPos.xy = Out.HPos.xy/Out.HPos.w;
    Out.TexPos.xy = Out.TexPos.xy * 0.5 + 0.5;
    Out.TexPos.y = 1.0 - Out.TexPos.y;
    Out.TexPos.xy += vTexProjOffset;
    // Out.Tex1.x += 0.000625;
    // Out.Tex1.y += 0.000833;
    Out.TexPos.xy = Out.TexPos.xy * Out.HPos.w;
    Out.TexPos.zw = Out.HPos.zw;

    // Pass-through texcoords
    Out.DiffuseMap = input.TexCoord;
    Out.NormalMap = input.TexCoord;
    // Cross product to create BiNormal
    vec3 binormal = normalize(cross(input.Tan, input.Normal));

    // Need to calculate the TanToCubeState based on each matBone skinning world matrix
    mat3x3 TanToObjectBasis;
    TanToObjectBasis[0] = vec3(input.Tan.x, binormal.x, input.Normal.x);
    TanToObjectBasis[1] = vec3(input.Tan.y, binormal.y, input.Normal.y);
    TanToObjectBasis[2] = vec3(input.Tan.z, binormal.z, input.Normal.z);
    Out.TanToCubeSpace1.x = dot(mOneBoneSkinning[IndexArray[0]][0].xyz,TanToObjectBasis[0]);
    Out.TanToCubeSpace1.y = dot(mOneBoneSkinning[IndexArray[0]][1].xyz,TanToObjectBasis[0]);
    Out.TanToCubeSpace1.z = dot(mOneBoneSkinning[IndexArray[0]][2].xyz,TanToObjectBasis[0]);
    Out.TanToCubeSpace2.x = dot(mOneBoneSkinning[IndexArray[0]][0].xyz,TanToObjectBasis[1]);
    Out.TanToCubeSpace2.y = dot(mOneBoneSkinning[IndexArray[0]][1].xyz,TanToObjectBasis[1]);
    Out.TanToCubeSpace2.z = dot(mOneBoneSkinning[IndexArray[0]][2].xyz,TanToObjectBasis[1]);
    Out.TanToCubeSpace3.x = dot(mOneBoneSkinning[IndexArray[0]][0].xyz,TanToObjectBasis[2]);
    Out.TanToCubeSpace3.y = dot(mOneBoneSkinning[IndexArray[0]][1].xyz,TanToObjectBasis[2]);
    Out.TanToCubeSpace3.z = dot(mOneBoneSkinning[IndexArray[0]][2].xyz,TanToObjectBasis[2]);
    // Transform eye pos to tangent space
    Out.EyeVecAndReflection.xyz = Pos - eyePos.xyz;
    Out.EyeVecAndReflection.w = eyePos.w;
    Out.Fog = 0;//calcFog(Out.HPos.w);
    return Out;
}

vec4 psAlphaEnvMap(VS_OUTPUT_AlphaEnvMap indata) : COLOR
{
    vec4 accumLight = tex2Dproj(sampler1, indata.TexPos);
    vec4 outCol;
    outCol = tex2D(sampler0, indata.DiffuseMap);
    outCol.rgb *= accumLight.rgb;
    vec4 normalmap = tex2D(sampler2, indata.NormalMap);
    vec3 expandedNormal = normalmap.xyz * 2.0 - 1.0;
    vec3 worldNormal;
    worldNormal.x = dot(indata.TanToCubeSpace1.xyz,expandedNormal);
    worldNormal.y = dot(indata.TanToCubeSpace2.xyz,expandedNormal);
    worldNormal.z = dot(indata.TanToCubeSpace3.xyz,expandedNormal);
    vec3 lookup = reflect(normalize(indata.EyeVecAndReflection.xyz), normalize(worldNormal));
    // return vec4(lookup.rgb, 1.0);
    vec3 envmapColor = texCUBE(samplerCube3,lookup) * normalmap.a * indata.EyeVecAndReflection.w;

    outCol.rgb += accumLight.a + envmapColor;
    return outCol;
}

technique alpha
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        CullMode = NONE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        AlphaTestEnable = TRUE;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_0 vsAlpha(viewProjMatrix);
        PixelShader = compile ps_2_0 psAlpha();
    }

    pass p1EnvMap
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        CullMode = NONE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        AlphaTestEnable = TRUE;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_0 vsAlphaEnvMap(viewProjMatrix);
        PixelShader = compile ps_2_0 psAlphaEnvMap();
    }
}

struct VS_OUTPUT_AlphaScope
{
    vec4 HPos         : POSITION;
    vec3 Tex0AndTrans : TEXCOORD0;
    vec2 Tex1         : TEXCOORD1;
    float Fog         : FOG;
};

VS_OUTPUT_AlphaScope vsAlphaScope(appdata input, uniform mat4x4 ViewProj)
{
    VS_OUTPUT_AlphaScope Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    vec3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(vec4(Pos.xyz, 1.0), ViewProj);

    vec3 wNormal = mul(input.Normal, mOneBoneSkinning[IndexArray[0]]);
    vec3 worldEyeVec = normalize(viewInverseMatrix[3].xyz - Pos);

    scalar f = dot(wNormal, worldEyeVec);
    // f = step(0.99, f) * f;
    f = smoothstep(0.965, 1.0, f);
    Out.Tex0AndTrans.z = f;

    Out.Tex0AndTrans.xy = input.TexCoord;

    Out.Tex1.xy = Out.HPos.xy / Out.HPos.w;
    Out.Tex1.xy = Out.Tex1.xy * 0.5 + 0.5;
    Out.Tex1.y = 1.0 - Out.Tex1.y;
    Out.Fog = 0.0; // calcFog(Out.HPos.w);

    return Out;
}

float4 psAlphaScope(VS_OUTPUT_AlphaScope input) : COLOR
{
    float3 coords = input.Tex0AndTrans;
    float4 accum = tex2D(sampler1, input.Tex1);
    float4 diff = tex2D(sampler0, coords.xy);
    diff.rgb = diff * accum;
    diff.a = (1.0 - coords.b) * diff.a;
    return diff;
}

technique alphascope
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        CullMode = NONE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        AlphaTestEnable = TRUE;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_0 vsAlphaScope(viewProjMatrix);
        PixelShader = compile ps_2_0 psAlphaScope();
    }
}

vec4 calcShadowProjCoords(vec4 Pos, mat4x4 matTrap, mat4x4 matLight)
{
    vec4 shadowcoords = mul(Pos, matTrap);
    vec2 lightZW = mul(Pos, matLight).zw;
    shadowcoords.z = (lightZW.x * shadowcoords.w) / lightZW.y; // (zL * wT) / wL == zL / wL post homo
    return shadowcoords;
}


struct VS2PS_ShadowMap
{
    vec4 HPos  : POSITION;
    vec2 PosZW : TEXCOORD0;
};

struct VS2PS_ShadowMapAlpha
{
    vec4 HPos      : POSITION;
    vec4 Tex0PosZW : TEXCOORD0;
};

VS2PS_ShadowMap vsShadowMap(appdata input)
{
    VS2PS_ShadowMap Out = (VS2PS_ShadowMap)0;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    vec4 unpackPos = vec4(input.Pos.xyz * PosUnpack, 1.0);
    vec3 Pos = mul(unpackPos, mOneBoneSkinning[IndexArray[0]]);

    Out.HPos = calcShadowProjCoords(vec4(Pos.xyz, 1.0), vpLightTrapezMat, vpLightMat);
    Out.PosZW = Out.HPos.zw;

    return Out;
}

vec4 psShadowMap(VS2PS_ShadowMap indata) : COLOR
{
    return indata.PosZW.x / indata.PosZW.y;
}

VS2PS_ShadowMapAlpha vsShadowMapAlpha(appdata input)
{
    VS2PS_ShadowMapAlpha Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    vec4 unpackPos = input.Pos * PosUnpack;
    vec3 Pos = mul(unpackPos, mOneBoneSkinning[IndexArray[0]]);

    Out.HPos = calcShadowProjCoords(vec4(Pos.xyz, 1.0), vpLightTrapezMat, vpLightMat);
    Out.Tex0PosZW.xy = input.TexCoord;
    Out.Tex0PosZW.zw = Out.HPos.zw;
    return Out;
}

vec4 psShadowMapAlpha(VS2PS_ShadowMapAlpha indata) : COLOR
{
    clip(tex2D(sampler0, indata.Tex0PosZW.xy).a - shadowAlphaThreshold);
    return indata.Tex0PosZW.z / indata.Tex0PosZW.w;
}

vec4 psShadowMapAlphaNV(VS2PS_ShadowMapAlpha indata) : COLOR
{
    return tex2D(sampler0, indata.Tex0PosZW.xy).a - shadowAlphaThreshold;
}

VS2PS_ShadowMap vsShadowMapPoint(appdata input)
{
    VS2PS_ShadowMap Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    vec3 wPos = mul(input.Pos * PosUnpack, mOneBoneSkinning[IndexArray[0]]);
    vec3 hPos = wPos.xyz - lightPos;
    hPos.z *= paraboloidValues.x;

    // Out.PosZ = hPos.z/paraboloidValues.z + 0.5;

    scalar d = length(hPos.xyz);
    hPos.xyz /= d;
    hPos.z += 1.0;
    Out.HPos.x = hPos.x / hPos.z;
    Out.HPos.y = hPos.y / hPos.z;
    Out.HPos.z = d * paraboloidZValues.x + paraboloidZValues.y;
    Out.HPos.w = 1.0;

    Out.PosZW = Out.HPos.zw;

    return Out;
}

vec4 psShadowMapPoint(VS2PS_ShadowMap indata) : COLOR
{
    // return 0.5;
    clip(indata.PosZW.x);
    return indata.PosZW.x;
}

VS2PS_ShadowMapAlpha vsShadowMapPointAlpha(appdata input)
{
    VS2PS_ShadowMapAlpha Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    vec3 wPos = mul(input.Pos * PosUnpack, mOneBoneSkinning[IndexArray[0]]);
    vec3 hPos = wPos.xyz - lightPos;
    hPos.z *= paraboloidValues.x;

    // Out.PosZ = hPos.z/paraboloidValues.z + 0.5;

    scalar d = length(hPos.xyz);
    hPos.xyz /= d;
    hPos.z += 1.0;

    Out.HPos.x = hPos.x / hPos.z;
    Out.HPos.y = hPos.y / hPos.z;
    Out.HPos.z = d * paraboloidZValues.x + paraboloidZValues.y;
    Out.HPos.w = 1.0;

    Out.Tex0PosZW.xy = input.TexCoord;
    Out.Tex0PosZW.zw = Out.HPos.zw;

    return Out;
}

vec4 psShadowMapPointAlpha(VS2PS_ShadowMapAlpha indata) : COLOR
{
    clip(tex2D(sampler0, indata.Tex0PosZW.xy).a - shadowAlphaThreshold);
    clip(indata.Tex0PosZW.z);
    return indata.Tex0PosZW.z;
}

vec4 psShadowMapNV(VS2PS_ShadowMap indata) : COLOR
{
    // return indata.PosZW.x / indata.PosZW.y;
    // return vec4(1.0, 0.0, 0.0, 1.0);
    return 0.0;
}

technique DrawShadowMapNV
{
    pass directionalspot
    {
        // ColorWriteEnable = 0; // for Fast-Z
        ColorWriteEnable = 0x0000000F;

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;

        ScissorTestEnable = TRUE;
        // CullMode = CW;

        VertexShader = compile vs_2_0 vsShadowMap();
        PixelShader = compile ps_2_0 psShadowMapNV();
    }

    pass directionalspotalpha
    {
        ColorWriteEnable = 0; // for Fast-Z

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_0 vsShadowMapAlpha();
        PixelShader = compile ps_2_0 psShadowMapAlphaNV();
    }

    pass point
    {
        ColorWriteEnable = 0; // for Fast-Z

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_0 vsShadowMapPoint();
        PixelShader = compile ps_2_0 psShadowMapNV();
    }

    pass pointalpha
    {
        ColorWriteEnable = 0; // for Fast-Z

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_0 vsShadowMapPointAlpha();
        PixelShader = compile ps_2_0 psShadowMapPointAlpha();
    }
}

technique DrawShadowMap
{
    pass directionalspot
    {
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        // CullMode = NONE;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_0 vsShadowMap();
        PixelShader = compile ps_2_0 psShadowMap();
    }

    pass directionalspotalpha
    {
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_0 vsShadowMapAlpha();
        PixelShader = compile ps_2_0  psShadowMapAlpha();
    }

    pass point
    {
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_0 vsShadowMapPoint();
        PixelShader = compile ps_2_0 psShadowMapPoint();
    }

    pass pointalpha
    {
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_0 vsShadowMapPointAlpha();
        PixelShader = compile ps_2_0  psShadowMapPointAlpha();
    }
}

// #include "Shaders/BundledMesh_nv3x.fx"
// #include "Shaders/BundledMesh_r3x0.fx"
#include "Shaders/BundledMesh_lightmapgen.fx"
// #include "Shaders/BundledMesh_editor.fx"
// #include "Shaders/BundledMesh_debug.fx"
// #include "Shaders/BundledMesh_leftover.fx"
