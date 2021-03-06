# bf2142-shaders

## About

Remember to clear the shader cache at `...\Documents\Battlefield 2142\mods\bf2142` before installing

**Tested on:**
- Windows 10 64-bit
- RX 580

**Todo:**
- Cleanup and organize shader formatting for readability
- Learn more about HLSL and porting asm (especially vs_1_1 asm)
- Encourage shader compiler to use dot-product calculations instead of `MAD + MUL`
- Replace many `MUL + ADD` calculations found in vanilla shaders with `MAD`
- Use optimization techniques from https://www.gdcvault.com/play/1018182/Low-Level-Thinking-in-High
- Support vs_2_0 and ps_2_0 if possible

**Sources used for this project:**
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
Decals.fx            | Stable
Font.fx              | Stable
FSQuadDrawer.fx      | Stable
FXCommon.fx          | Stable
LightGeom.fx         | Stable
LightManager_r3x0.fx | Stable
LoadingScreen.fx     | Stable

Particles                    | Status | Note
---------------------------- | ------ | ----
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
RaShaderBM.fx                     | Stable
RaShaderBM.mfx                    | Stable
RaShaderBMActiveCammo.fx          | Stable
RaShaderBMadditive.fx             | Stable
RaShaderBMCommon.fx               | Stable
RaShaderBMZOnly.fx                | Stable
RaShaderDefault.fx                | Stable
RaShaderEditorRoad.fx             | Stable
RaShaderEditorRoadDetail.fx       | Stable
RaShaderLeaf.fx                   | Stable
RaShaderLeafOG.fx                 | Stable
RaShaderLeafPointLight.fx         | Stable
RaShaderLeafPointLightShadowed.fx | Stable
RaShaderLeafShadowed.fx           | Stable
RaShaderRoad.fx                   | Stable
RaShaderRoadDetail.fx             | Stable
RaShaderRoadDetailNoBlend.fx      | Stable

RaShaderSM/STM                    | Status   | Note
--------------------------------- | -------- | ----
RaShaderSM.fx                     | Stable
RaShaderSM.mfx                    | Stable
RaShaderSMActiveCamo.fx           | Stable
RaShaderSMCommon.fx               | Stable
RaShaderSTM.fx                    | Unstable | Output is very bright if `ps_2_0`
RaShaderSTM.mfx                   | Stable
RaShaderSTMCommon.fx              | Stable
RaShaderTrunkOG.fx                |
RaShaderTrunkSTMBase.fx           | Stable
RaShaderTrunkSTMBaseShadowed.fx   | Stable
RaShaderTrunkSTMDetail.fx         |
RaShaderTrunkSTMDetailShadowed.fx | Stable

RaShaderWater                 | Status   | Note
----------------------------- | -------- | ----
RaShaderWater.fx              | Stable
RaShaderWater2D.fx            | Stable
RaShaderWater3D.fx            | Stable
RaShaderWaterBase.fx          | Unstable | Doesn't work if forcing the high-end shader
RaShaderWaterDistant2D.fx     | Stable
RaShaderWaterDistant3D.fx     | Stable
RaShaderWaterHighEnd3D.fx     | Stable
RaShaderWaterSurrounding2D.fx | Stable
RaShaderWaterSurrounding3D.fx | Stable
RaShaderWaterSurrounding3D.fx | Stable

SkinnedMesh + Misc        | Status | Note
------------------------- | ------ | ----
Road.fx                   | Stable
RoadCompiled.fx           | Stable
SimpleAlphaBlendShader.fx | Stable
SkinnedMesh_dx9.dfx       | Stable
SkinnedMesh_r3x0.fx       | Stable
SkinnedMesh.fx            | Stable
SkyDome.fx                | Stable
SplineShader.fx           | Stable

StaticMesh + Misc         | Status | Note
------------------------- | ------ | ----
StaticMesh_debug.fx       | Stable
StaticMesh_dx9.dfx        | Stable
StaticMesh_editor.fx      | Stable
StaticMesh_lightmapgen.fx | Stable
StaticMesh_nv3x.fx        | Stable
StaticMesh_nv3xpp.fx      | Stable
StaticMesh_r3x0.fx        | Stable
StaticMesh.dfx            | Stable
StaticMesh.fx             | Stable
STM1_4.fx                 | Stable
SunFog.fx                 | Stable
SwiffMenu.fx              | Stable

Terrain                        | Status | Note
------------------------------ | ------ | ----
TerrainEditorShader.fx         | Stable
TerrainShader_backup.fx        | Stable
TerrainShader_debug.fx         | Stable
TerrainShader_Hi.fx            | Stable
TerrainShader_Low.fx           | Stable
TerrainShader_nv3x_leftover.fx | Stable
TerrainShader_nv3x.fx          | Stable
TerrainShader_r3x0.fx          | Stable
TerrainShader_Shared.fx        | Stable
TerrainShader.fx               | Stable
TerrainUGShader.fx             | Stable

Misc                          | Status | Note
----------------------------- | ------ | ----
Trail.fx                      | Stable
TreeBillboard.fx              | Stable
TreeMesh.fx                   | Stable
TreeMeshBillboardGenerator.fx | Stable
Undergrowth.fx                | Stable
