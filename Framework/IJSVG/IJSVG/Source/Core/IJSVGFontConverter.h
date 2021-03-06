//
//  IJSVGFontConverter.h
//  IJSVGExample
//
//  Created by Curtis Hard on 21/05/2015.
//  Copyright (c) 2015 Curtis Hard. All rights reserved.
//

#import "IJSVG.h"
#import <Foundation/Foundation.h>

typedef void (^IJSVGFontConverterEnumerateBlock)(NSString* unicode, IJSVG* svg);

@interface IJSVGFontConverter : NSObject {

@private
    NSURL* _url;
    NSFont* _font;
    NSMutableDictionary<NSString*, id>* _transformedPaths;
}

- (id)initWithFontAtFileURL:(NSURL*)url;
- (NSFont*)font;
- (void)enumerateUsingBlock:(IJSVGFontConverterEnumerateBlock)block;

+ (IJSVG*)convertIJSVGPathToSVG:(IJSVGPath*)path;
+ (IJSVG*)convertPathToSVG:(CGPathRef)path;

@end
