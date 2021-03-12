#line 2 "TreeMeshBillboardGenerator.fx"

float4x4 mvpMatrix : WorldViewProjection;// : register(vs_3_0, c0);
float4x4 worldIMatrix : WorldI;// : register(vs_3_0, c4);
float4x4 viewInverseMatrix : ViewI; //: register(vs_3_0, c8);
//float4x3 mOneBoneSkinning[52]: matONEBONESKINNING; //: register(vs_3_0, c15);

// Sprite parameters
float4x4 worldViewMatrix : WorldView;
float4x4 projMatrix : Projection;
float4 spriteScale :  SpriteScale;
float4 shadowSpherePoint : ShadowSpherePoint;
float4 boundingboxScaledInvGradientMag : BoundingboxScaledInvGradientMag;
float4 invBoundingBoxScale : InvBoundingBoxScale;
float4 shadowColor : ShadowColor;
float4 lightColor : LightColor;

float4 ambColor : Ambient = {0.0f, 0.0f, 0.0f, 1.0f};
float4 diffColor : Diffuse = {1.0f, 1.0f, 1.0f, 1.0f};
float4 specColor : Specular = {0.0f, 0.0f, 0.0f, 1.0f};

dword colorWriteEnable : ColorWriteEnable;

texture diffuseTexture: TEXLAYER0
<
    string File = "default_color.dds";
    string TextureType = "2D";
>;

texture normalTexture: TEXLAYER1
<
    string File = "bumpy_flipped.dds";
    string TextureType = "2D";
>;

texture colorLUT: TEXLAYER2
<
    string File = "default_sdgbmfbf_color_lut.dds";
    string TextureType = "2D";
>;

// texture normalTexture: NormalMap;
// texture colorLUT: LUTMap;

float4 eyePos : EyePosition = {0.0f, 0.0f, 1.0f, 0.0f};

float4 lightPos : LightPosition
<
    string Object = "PointLight";
    string Space = "World";
> = {0.0f, 0.0f, 1.0f, 1.f};



struct appdata
{
    float4 Pos : POSITION;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
    float2 TexCoord1 : TEXCOORD1;
    float4 Tan : TANGENT;
};

struct appdata2
{
    float4 Pos : POSITION;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
    float2 Width_height : TEXCOORD1;
    float4 Tan : TANGENT;
};

struct VS_OUTPUT
{
    float4 HPos		: POSITION;
    float2 TexCoord	: TEXCOORD0;
    float2 TexCoord2: TEXCOORD1;
    float4 LightVec	: TEXCOORD2;
    float4 HalfVec	: TEXCOORD3;
    float4 Diffuse	: COLOR;
};

struct VS_OUTPUT2
{
    float4 HPos		: POSITION;
    float2 TexCoord	: TEXCOORD0;
    float4 Diffuse	: COLOR;
};

sampler diffuseSampler = sampler_state
{
    Texture = <diffuseTexture>;
    // Target = Texture2D;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler normalSampler = sampler_state
{
    Texture = <normalTexture>;
    // Target = Texture2D;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler dummySampler = sampler_state
{
    // Target = Texture2D;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler colorLUTSampler = sampler_state
{
    Texture = <colorLUT>;
    // Target = Texture2D;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
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
    //float4 worldPos = mul(EyePos, ViewInv);

    float3 objPos = mul(float4(worldPos.xyz, 1.0f), WorldIT);
    float3 tanPos = float3(dot(objPos,input.Tan),
                           dot(objPos,binormal),
                           dot(objPos,input.Normal));

    float3 halfVector = normalize(normalizedTanLightVec + tanPos);
    // Compress H' in tex3... don't compress, autoclamp >0
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
    float4 scaledPos = float4(float2(input.Width_height.xy * SpriteScale.xy), 0.0, 0.0) + pos;
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

float4 bumpSpecularPixelShaderBlinn1(VS_OUTPUT input) : COLOR
{
    float4 diffuse = tex2D(diffuseSampler, input.TexCoord);
    return diffuse * input.Diffuse;
}

technique trunk
{
    pass p0
    {
        ZEnable = true;
        // ZWriteEnable = true;
        ZWriteEnable = false;
        ColorWriteEnable = (colorWriteEnable);
        AlphaBlendEnable = false;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_3_0 bumpSpecularVertexShaderBlinn1(mvpMatrix,
                                                                     worldIMatrix,
                                                                     viewInverseMatrix,
                                                                     lightPos,
                                                                     eyePos);
        PixelShader = compile ps_3_0 bumpSpecularPixelShaderBlinn1();
    }
}

technique branch
{
    pass p0
    {

        ZEnable = true;
        // ZWriteEnable = true;
        ZWriteEnable = false;
        // FillMode = WIREFRAME;
        ColorWriteEnable = (colorWriteEnable);
        CullMode = NONE;
        AlphaBlendEnable = true;
        SrcBlend = D3DBLEND_SRCALPHA;
        DestBlend = D3DBLEND_INVSRCALPHA;

        AlphaTestEnable = false;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_3_0 bumpSpecularVertexShaderBlinn1(mvpMatrix,
                                                                     worldIMatrix,
                                                                     viewInverseMatrix,
                                                                     lightPos,
                                                                     eyePos);
        PixelShader = compile ps_3_0 bumpSpecularPixelShaderBlinn1();
    }
}

float4 spritePixelShader(VS_OUTPUT2 input) : COLOR
{
    float4 diffuse = tex2D(diffuseSampler, input.TexCoord);
    return diffuse * input.Diffuse;
}

technique sprite
{
    pass p0
    {

        ZEnable = true;
        // ZEnable = false;
        ZWriteEnable = false;
        // ZWriteEnable = false;
        // FillMode = WIREFRAME;
        CullMode = NONE;
        AlphaBlendEnable = true;
        SrcBlend = D3DBLEND_SRCALPHA;
        DestBlend = D3DBLEND_INVSRCALPHA;
        AlphaTestEnable = false;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_3_0 spriteVertexShader(worldViewMatrix,
                                                         projMatrix,
                                                         spriteScale,
                                                         shadowSpherePoint,
                                                         invBoundingBoxScale,
                                                         boundingboxScaledInvGradientMag,
                                                         shadowColor,
                                                         lightColor);
        PixelShader = compile ps_3_0 spritePixelShader();
    }
}

float4 ps_alpha(VS_OUTPUT input) : COLOR
{
    float4 diffuse = tex2D(diffuseSampler, input.TexCoord);
    return 1.0 - diffuse.aaaa;
}

technique alpha
{
    pass p0
    {
        ColorWriteEnable = (colorWriteEnable);
        AlphaBlendEnable = true;
        CullMode = NONE;
        ZWriteEnable = false;
        SrcBlend = D3DBLEND_DESTCOLOR;
        DestBlend = D3DBLEND_ZERO;
        AlphaTestEnable = false;

        VertexShader = compile vs_3_0 bumpSpecularVertexShaderBlinn1(mvpMatrix,
                                                                     worldIMatrix,
                                                                     viewInverseMatrix,
                                                                     lightPos,
                                                                     eyePos);
        PixelShader = compile ps_3_0 ps_alpha();
    }
}

float4 ps_alphaSprite(VS_OUTPUT2 input) : COLOR
{
    float4 diffuse = tex2D(diffuseSampler, input.TexCoord);
    return 1.0 - diffuse.aaaa;
}

technique alphaSprite
{
    pass p0
    {
        ColorWriteEnable = (colorWriteEnable);
        AlphaBlendEnable = true;
        CullMode = NONE;
        ZWriteEnable = false;
        SrcBlend = D3DBLEND_DESTCOLOR;
        DestBlend = D3DBLEND_ZERO;
        AlphaTestEnable = false;

        VertexShader = compile vs_3_0 spriteVertexShader(worldViewMatrix,
                                                         projMatrix,
                                                         spriteScale,
                                                         shadowSpherePoint,
                                                         invBoundingBoxScale,
                                                         boundingboxScaledInvGradientMag,
                                                         shadowColor,
                                                         lightColor);
        PixelShader = compile ps_3_0 ps_alphaSprite();
    }
}
