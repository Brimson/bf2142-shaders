vec3	CameraPos : cameraPos;

vec4	SunFogRange : sunFogRange;
vec4	SunFogColor : sunFogColor;
scalar	SunFogPower : sunFogPower = 1;
vec3	SunPos : sunPos;

scalar calcSunFog(scalar w)
{
	half2 fogVals = w * SunFogRange.xy + SunFogRange.zw;
	half close = max(fogVals.y, SunFogColor.w);
	half far = pow(fogVals.x, 3.0);
	return close-far;
}

scalar calcSunFogAngle(vec4 vPos)
{
	vec3 vertVec = normalize(vPos.xyz - CameraPos);
	vec3 sunVec = normalize(SunPos - CameraPos);
	scalar sunAngle = saturate(pow(dot(vertVec, sunVec), SunFogPower));
	return 1.0 - sunAngle;
}
