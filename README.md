# bf2142-shaders

## About

DirectX 9.0 shader model update for Battlefield 2142

Remember to clear the shader cache at `...\Documents\Battlefield 2142\mods\bf2142`

Tested on:
- Windows 10 64-bit
- RX 580

Todo:
- Cleanup and organize shader formatting for readability
- Learn more about HLSL and porting asm (especially vs_1_1 asm)
- Encourage shader compiler to use dot-product calculations instead of `MAD + MUL`
- Replace many `MUL + ADD` calculations found in vanilla shaders with `MAD`
- Use optimization techniques from https://www.gdcvault.com/play/1018182/Low-Level-Thinking-in-High
- Support vs_2_0 and ps_2_0 if possible

Sources used for this project:
- Project Reality's `shaders_client.zip` as reference
- https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx9-graphics-reference-asm
- http://developer.download.nvidia.com/assets/gamedev/docs/GDC2K1_DX8_Pixel_Shaders.pdf

## Shader Status

BundleMesh                 | Status | Note
-------------------------- | ------ | ----
BundledMesh_debug.fx       | Stable
BundledMesh_editor.fx      | Stable
BundledMesh_lightmapgen.fx | Stable
BundledMesh_nv3x.fx        | Stable
BundledMesh_r3x0.fx        | Stable

Common               | Status | Note
-------------------- | ------ | ----
Common.dfx           | Stable
commonsamplers.dfx   | Stable
commonvertexlight.fx | Stable
datatypes.fx         | Stable

Debug                       | Status   | Note
--------------------------- | -------- | ----
DebugCircleShader.fx        | Unstable | Causes sun flickering if 2_x (perhaps due to zwrite)
DebugD3DXMeshShapeShader.fx | Unstable | Sun flickering
DebugLineGraph.fx           | Unstable | Sun flickering
DebugSphereShader.fx        | Unstable | Sun flickering

Lighting             | Status | Note
-------------------- | ------ | ----
Decals.fx            | Stable | Decal lighting only at light direction (same as vanilla)
Font.fx              | Stable
FSQuadDrawer.fx      | Stable
FXCommon.fx          | Stable
LightGeom.fx         | Stable
LightManager_r3x0.fx | Stable
LoadingScreen.fx     | Stable

Particles                    | Status | Note
---------------------------- | ------ | --------
MeshParticleMesh_nv3x.fx     | Stable
MeshParticleMesh.fx          | Stable
Nametag.fx                   | Stable
NonScreenAlignedParticles.fx | Stable
Particles.fx                 | Stable
PointSpriteParticles.fx      | Stable

PostProduction         | Status | Note
---------------------- | ------ | ----
PortedFontShader.fx    | Stable
PortedMenuShader.fx    | Stable
PostProduction_nv3x.fx | Stable
PostProduction_r3x0.fx | Stable
QuadGeom.fx            | Stable
RaCommon.fx            | Stable
RaDefines.fx           | Stable
Rain.fx                | Stable

RaShader                          | Status   | Note
--------------------------------- | -------- | ----
RaShader1Dif.fx                   | Stable
RaShader1Dif1BoneSkinned.fx       | Stable
RaShader2DifDet.fx                | Stable
RaShaderBM.fx                     | Broken   | Shows black when use 2.0+, slowdown if under 2.a
RaShaderBM.mfx                    | Unstable
RaShaderBMActiveCammo.fx          | Unstable
RaShaderBMadditive.fx             | Unstable
RaShaderBMCommon.fx               | Unstable
RaShaderBMZOnly.fx                | Unstable
RaShaderDefault.fx                | Stable
RaShaderEditorRoad.fx             | Stable
RaShaderEditorRoadDetail.fx       | Stable
RaShaderLeaf.fx                   | Broken   | 2_0+ update generate hiccups when particles are present
RaShaderLeafOG.fx                 | Broken
RaShaderLeafPointLight.fx         | Broken
RaShaderLeafPointLightShadowed.fx | Broken
RaShaderLeafShadowed.fx           | Broken
RaShaderRoad.fx                   | Stable
RaShaderRoadDetail.fx             | Stable
RaShaderRoadDetailNoBlend.fx      | Stable

RaShaderSM/STM                    | Status | Note
--------------------------------- | ------ | ----
RaShaderSM.fx                     | Broken | Lags and objects disappeares if forced 2_x
RaShaderSM.mfx                    | Stable |
RaShaderSMActiveCamo.fx           | Stable |
RaShaderSMCommon.fx               | Stable |
RaShaderSTM.fx                    |
RaShaderSTM.mfx                   |
RaShaderSTMCommon.fx              |
RaShaderTrunkOG.fx                |
RaShaderTrunkSTMBase.fx           |
RaShaderTrunkSTMBaseShadowed.fx   |
RaShaderTrunkSTMDetail.fx         |
RaShaderTrunkSTMDetailShadowed.fx |
