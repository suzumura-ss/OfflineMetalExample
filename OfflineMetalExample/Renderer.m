//
//  Renderer.m
//  MetalCommand
//
//  Created by Toshiyuki Terashita on 2018/09/12.
//  Copyright © 2018年 Toshiyuki Terashita. All rights reserved.
//

#import "Renderer.h"
#import <simd/simd.h>
#import <ModelIO/ModelIO.h>


@implementation Renderer
{
    MTLPixelFormat _outputPixelFormat;
    dispatch_semaphore_t _inFlightSemaphore;

    id <MTLTexture> _outputTexture;
    MTLVertexDescriptor *_mtlVertexDescriptor;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLCommandQueue> _commandQueue;

    // Uniforms
    id <MTLBuffer> _uniformBuffer;

    // Mesh
    id <MTLBuffer> _positionsBuffer;
    id <MTLBuffer> _texCoordsBuffer;
    NSUInteger _vertexCount;
    
    // Texture
    id <MTLTexture> _colorMap;
}


- (instancetype)initWithSize:(CGSize)size
{
    id <MTLDevice> device = MTLCreateSystemDefaultDevice();
    return [self initWithDevice:device size:size];
}


- (instancetype)initWithDevice:(id <MTLDevice>)device size:(CGSize)size
{
    self = [super init];
    if (self)
    {
        _device = device;
        _outputPixelFormat = MTLPixelFormatRGBA8Uint;
        _width = (NSUInteger)size.width;
        _height = (NSUInteger)size.height;
        [self loadMetal];
        [self loadMesh];
        [self loadTexture];
    }
    return self;
}


- (void)loadMetal
{
    _inFlightSemaphore = dispatch_semaphore_create(0);
    
    // output texture.
    {
        MTLTextureDescriptor* outputDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_outputPixelFormat
                                                                                              width:_width
                                                                                             height:_height
                                                                                          mipmapped:NO];
        outputDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        _outputTexture = [_device newTextureWithDescriptor:outputDesc];
    }
    
    // vertex desc.
    {
        _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];
        _mtlVertexDescriptor.attributes[VertexAttributePosition].format = MTLVertexFormatFloat4;
        _mtlVertexDescriptor.attributes[VertexAttributePosition].offset = 0;
        _mtlVertexDescriptor.attributes[VertexAttributePosition].bufferIndex = BufferIndexMeshPositions;
        
        _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].format = MTLVertexFormatFloat2;
        _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].offset = 0;
        _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].bufferIndex = BufferIndexMeshTexCoords;
        
        _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stride = sizeof(vector_float4);
        _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepRate = 1;
        _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;
        
        _mtlVertexDescriptor.layouts[BufferIndexMeshTexCoords].stride = sizeof(vector_float2);
        _mtlVertexDescriptor.layouts[BufferIndexMeshTexCoords].stepRate = 1;
        _mtlVertexDescriptor.layouts[BufferIndexMeshTexCoords].stepFunction = MTLVertexStepFunctionPerVertex;
    }
    
    // pipeline state.
    {
        
        MTLRenderPipelineDescriptor* pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        {
            id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
            pipelineStateDescriptor.sampleCount = 1;
            pipelineStateDescriptor.vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
            pipelineStateDescriptor.fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];;
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = _outputPixelFormat;
            pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
        }
        
        NSError *error = NULL;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        if (!_pipelineState || error)
        {
            NSLog(@"Failed to created pipeline state, error %@", error);
            abort();
            return;
        }
    }
    
    // command queue.
    _commandQueue = [_device newCommandQueue];

    // uniform buffer.
    _uniformBuffer = [_device newBufferWithLength:sizeof(Uniforms) options:MTLResourceStorageModeShared];
    _uniforms = (Uniforms*)_uniformBuffer.contents;
}


- (void)loadMesh
{
    vector_float4 positions[] = {
        {-1,  -1, 0, 1},
        { 1,  -1, 0, 1},
        { 0,   1, 0, 1}
    };
    vector_float2 texCoords[] = {
        {0, 0},
        {1, 0},
        {0, 1}
    };
    _positionsBuffer = [_device newBufferWithBytes:positions length:sizeof(positions) options:MTLResourceCPUCacheModeDefaultCache];
    _texCoordsBuffer = [_device newBufferWithBytes:texCoords length:sizeof(texCoords) options:MTLResourceCPUCacheModeDefaultCache];
    _vertexCount = sizeof(positions) / sizeof(vector_float4);
}


- (void)loadTexture
{
    MTLTextureDescriptor* colorMapDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Uint
                                                                                            width:2
                                                                                           height:2
                                                                                        mipmapped:NO];
    _colorMap = [_device newTextureWithDescriptor:colorMapDesc];
    uint8 pixels[2 * 2 * 4] = {
        1,  3,  5,  7,      10, 13, 15, 17,
        21, 23, 25, 27,     30, 33, 35, 37,
    };
    [_colorMap replaceRegion:MTLRegionMake2D(0, 0, colorMapDesc.width, colorMapDesc.height)
                 mipmapLevel:0
                   withBytes:pixels
                 bytesPerRow:colorMapDesc.width * 4];
}


- (void)draw
{
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_sema);
    }];
    
    MTLRenderPassDescriptor* renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = _outputTexture;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 2, 3, 4);
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    if (!renderEncoder)
    {
        NSLog(@"No renderEncoder");
        abort();
        return;
    }
    [renderEncoder pushDebugGroup:@"DrawBox"];
    [renderEncoder setRenderPipelineState:_pipelineState];
    [renderEncoder setVertexBuffer:_positionsBuffer offset:0 atIndex:BufferIndexMeshPositions];
    [renderEncoder setVertexBuffer:_texCoordsBuffer offset:0 atIndex:BufferIndexMeshTexCoords];
    [renderEncoder setVertexBuffer:_uniformBuffer offset:0 atIndex:BufferIndexUniforms];
    [renderEncoder setFragmentBuffer:_uniformBuffer offset:0 atIndex:BufferIndexUniforms];
    [renderEncoder setFragmentTexture:_colorMap atIndex:TextureIndexColor];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_vertexCount];
    
    [renderEncoder popDebugGroup];
    [renderEncoder endEncoding];
    [commandBuffer commit];
    
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
}


- (nonnull NSData*)readPixels
{
    NSMutableData* pixels = [NSMutableData dataWithLength:_width * _height * 4 /* <= MTLPixelFormatRGBA8Uint */];
    [_outputTexture getBytes:pixels.mutableBytes
                 bytesPerRow:_width * 4
                  fromRegion:MTLRegionMake2D(0, 0, _width, _height)
                 mipmapLevel:0];
    
    return pixels;
}


@end
