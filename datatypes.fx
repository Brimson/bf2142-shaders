#ifndef DATA_TYPES
#define DATA_TYPES

#if 1  //USEPARTIALPRECISIONTYPES

typedef half scalar;
typedef vector<half, 1> vec1;
typedef vector<half, 2> vec2;
typedef vector<half, 3> vec3;
typedef vector<half, 4> vec4;
typedef matrix<half, 3, 3> mat3x3;
typedef matrix<half, 3, 4> mat3x4;
typedef matrix<half, 4, 3> mat4x3;
typedef matrix<half, 4, 4> mat4x4;

#else

typedef float scalar;
typedef vector<float, 1> vec1;
typedef vector<float, 2> vec2;
typedef vector<float, 3> vec3;
typedef vector<float, 4> vec4;
typedef matrix<float, 3, 3> mat3x3;
typedef matrix<float, 3, 4> mat3x4;
typedef matrix<float, 4, 3> mat4x3;
typedef matrix<float, 4, 4> mat4x4;

#endif

#endif