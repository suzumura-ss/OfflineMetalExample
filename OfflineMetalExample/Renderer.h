//
//  Renderer.h
//  MetalCommand
//
//  Created by Toshiyuki Terashita on 2018/09/12.
//  Copyright © 2018年 Toshiyuki Terashita. All rights reserved.
//

#import <MetalKit/MetalKit.h>
#import "ShaderTypes.h"


@interface Renderer : NSObject

@property (readonly) id <MTLDevice> device;
@property (readonly) NSUInteger width;
@property (readonly) NSUInteger height;
@property (readonly) Uniforms* uniforms;

- (instancetype)initWithSize:(CGSize)size;
- (instancetype)initWithDevice:(id <MTLDevice>)device size:(CGSize)size;
- (void)draw;
- (nonnull NSData*)readPixels;

@end
