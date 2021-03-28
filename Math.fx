/*
    Common math library with optimized functions
*/

float4 mul1(float3 v, float4x4 m)
{
    return v.x * m[0] + (v.y * m[1] + (v.z * m[2] + m[3]));
}
