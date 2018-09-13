//
//  Shaders.metal
//  MetalCommand
//
//  Created by Toshiyuki Terashita on 2018/09/12.
//  Copyright © 2018年 Toshiyuki Terashita. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "ShaderTypes.h"

using namespace metal;


typedef struct
{
    float4 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;


vertex ColorInOut vertexShader(Vertex in [[stage_in]],
                               constant Uniforms & uniforms [[buffer(BufferIndexUniforms)]])
{
    ColorInOut out;
    out.position = in.position;
    out.texCoord = in.texCoord;
    if (uniforms.flipVertical)
    {
        out.position.y = -out.position.y;
    }
    return out;
}

fragment uint4 fragmentShader(ColorInOut in [[stage_in]],
                              constant Uniforms & uniforms [[buffer(BufferIndexUniforms)]],
                              texture2d<uint> colorMap     [[texture(TextureIndexColor)]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    return uniforms.color + colorMap.sample(colorSampler, in.texCoord.xy);
}
