float3 CameraPos : cameraPos;

float4 SunFogRange : sunFogRange;
float4 SunFogColor : sunFogColor;
float SunFogPower : sunFogPower = 1;
float3 SunPos : sunPos;

float calcSunFog(float w)
{
	half2 fogVals = w * SunFogRange.xy + SunFogRange.zw;
	half close = max(fogVals.y, SunFogColor.w);
	half far = pow(fogVals.x, 3.0);
	return close-far;
}

float calcSunFogAngle(float4 vPos)
{
	float3 vertVec = normalize(vPos.xyz - CameraPos);
	float3 sunVec = normalize(SunPos - CameraPos);
	float sunAngle = saturate(pow(dot(vertVec,sunVec), SunFogPower));
	return 1.0 - sunAngle;
}
