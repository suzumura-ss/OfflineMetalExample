//
//  Shaders.metal
//  MetalCommand
//
//  Created by Toshiyuki Terashita on 2018/09/12.
//  Copyright © 2018年 Toshiyuki Terashita. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;
#include "ShaderTypes.h"



vertex Vertex vertexShader(constant Vertex* in [[buffer(BufferIndexMesh)]],
                           uint vid [[vertex_id]],
                           constant Uniforms & uniforms [[buffer(BufferIndexUniforms)]])
{
    Vertex out;
    out.position = in[vid].position;
    out.texCoord = in[vid].texCoord;
    if (uniforms.flipVertical)
    {
        out.position.y = -out.position.y;
    }
    return out;
}

fragment uint4 fragmentShader(Vertex in [[stage_in]],
                              constant Uniforms & uniforms [[buffer(BufferIndexUniforms)]],
                              texture2d<uint> colorMap     [[texture(TextureIndexColor)]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    return uniforms.color + colorMap.sample(colorSampler, in.texCoord.xy);
}
