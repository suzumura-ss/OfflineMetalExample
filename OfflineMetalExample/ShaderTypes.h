//
//  ShaderTypes.h
//  MetalExample
//
//  Created by Toshiyuki Terashita on 2018/09/12.
//  Copyright © 2018年 Toshiyuki Terashita. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#define SEMANTIC(s) [[s]]
#else
#import <Foundation/Foundation.h>
typedef vector_float4 float4;
typedef vector_float2 float2;
#define SEMANTIC(s)
#endif

#include <simd/simd.h>


typedef struct
{
    float4 position SEMANTIC(position);
    float2 texCoord;
} Vertex;


typedef NS_ENUM(NSInteger, BufferIndex)
{
    BufferIndexMesh          = 0,
    BufferIndexUniforms      = 2
};

typedef NS_ENUM(NSInteger, VertexAttribute)
{
    VertexAttributePosition  = 0,
    VertexAttributeTexcoord  = 1,
};

typedef NS_ENUM(NSInteger, TextureIndex)
{
    TextureIndexColor    = 0,
};

typedef struct
{
    bool flipVertical;
    vector_uint4 color;
} Uniforms;


#endif /* ShaderTypes_h */
