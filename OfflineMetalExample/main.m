//
//  main.m
//  MetalCommand
//
//  Created by Toshiyuki Terashita on 2018/09/12.
//  Copyright © 2018年 Toshiyuki Terashita. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import "ShaderTypes.h"
#import "Renderer.h"


void Exec()
{
    Renderer* renderer = [[Renderer alloc] initWithSize:CGSizeMake(8, 8)];
    if (!renderer)
    {
        NSLog(@"Failed to created renderer.");
        return;
    }
    renderer.uniforms->flipVertical = true;
    renderer.uniforms->color = (vector_uint4){10, 11, 12, 13};
    [renderer draw];
    NSData* pixels = [renderer readPixels];

    uint8_t* p = (uint8_t*)pixels.bytes;
    for (int y = 0; y < renderer.height; ++y)
    {
        NSMutableString* s = [NSMutableString string];
        for (int x = 0; x < renderer.width; ++x)
        {
            [s appendString:@"("];
            for (int k = 0; k < 4; ++k)
            {
                [s appendFormat:@" %3d", *(p++)];
            }
            [s appendString:@" )"];
        }
        NSLog(@"%@", s);
    }
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Exec();
    }
    return 0;
}
