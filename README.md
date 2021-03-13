# bf2142-shaders

Shader Model 3.0 update for Battlefield 2142

Todo:
- Cleanup and organize shader formatting for readability
- Learn more about HLSL and porting asm (especially vs_1_1 asm)
- Encourage shader compiler to use dot-product calculations instead of `MAD + MUL`
- Replace many `MUL + ADD` calculations found in vanilla shaders with `MAD`
- Use optimization techniques from https://www.gdcvault.com/play/1018182/Low-Level-Thinking-in-High
- Support vs_3_0 and ps_3_0 if possible

Sources used for this project:
- Project Reality's `shaders_client.zip` as reference
- https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx9-graphics-reference-asm
- http://developer.download.nvidia.com/assets/gamedev/docs/GDC2K1_DX8_Pixel_Shaders.pdf
