#ifndef DATA_TYPES
    #define DATA_TYPES
    #if 1  //USEPARTIALPRECISIONTYPES
        typedef half float;
        typedef vector<half, 1> vec1;
        typedef vector<half, 2> float2;
        typedef vector<half, 3> float3;
        typedef vector<half, 4> float4;
        typedef matrix<half, 3, 3> float3x3;
        typedef matrix<half, 3, 4> float3x4;
        typedef matrix<half, 4, 3> float4x3;
        typedef matrix<half, 4, 4> float4x4;
    #else
        typedef float float;
        typedef vector<float, 1> vec1;
        typedef vector<float, 2> float2;
        typedef vector<float, 3> float3;
        typedef vector<float, 4> float4;
        typedef matrix<float, 3, 3> float3x3;
        typedef matrix<float, 3, 4> float3x4;
        typedef matrix<float, 4, 3> float4x3;
        typedef matrix<float, 4, 4> float4x4;
    #endif
#endif
