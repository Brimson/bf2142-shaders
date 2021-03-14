//#include "shaders/datatypes.fx"

struct PointLightData
{
	vec3	pos;
	scalar	attSqrInv;
	vec3	col;
};

struct SpotLightData
{
	vec3	pos;
	scalar	attSqrInv;
	vec3	col;
	scalar	coneAngle;
	vec3	dir;
	scalar	oneminusconeAngle;
};

PointLightData pointLight : POINTLIGHT;
SpotLightData spotLight : SPOTLIGHT;


vec4 lightPosAndAttSqrInv : LightPositionAndAttSqrInv;
vec4 lightColor : LightColor;

vec3 calcPVPoint(PointLightData indata, vec3 wPos, vec3 normal)
{
	vec3 lvec = lightPosAndAttSqrInv.xyz - wPos;
	scalar radialAtt = saturate(1 - dot(lvec, lvec)*lightPosAndAttSqrInv.w);
	lvec = normalize(lvec);
	scalar intensity = dot(lvec, normal) * radialAtt;

	return intensity * lightColor.xyz;
}

vec3 calcPVPointTerrain(vec3 wPos, vec3 normal)
{
	vec3 lvec = pointLight.pos - wPos;
	scalar radialAtt = saturate(1 - (dot(lvec, lvec))*pointLight.attSqrInv);
//	return radialAtt * pointLight.col;
	lvec = normalize(lvec);
	scalar intensity = dot(lvec, normal) * radialAtt;

	return intensity * pointLight.col;
}

vec3 calcPVSpot(SpotLightData indata, vec3 wPos, vec3 normal)
{
	vec3 lvec = indata.pos - wPos;
	
	scalar radialAtt = saturate(1 - dot(lvec, lvec)*indata.attSqrInv);
	lvec = normalize(lvec);
	
	scalar conicalAtt =	saturate(dot(lvec, indata.dir)-indata.oneminusconeAngle) / indata.coneAngle;

	scalar intensity = dot(lvec, normal) * radialAtt * conicalAtt;

	return intensity * indata.col;
}
