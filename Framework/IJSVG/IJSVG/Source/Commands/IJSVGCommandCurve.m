//
//  IJSVGCommandCurve.m
//  IconJar
//
//  Created by Curtis Hard on 30/08/2014.
//  Copyright (c) 2014 Curtis Hard. All rights reserved.
//

#import "IJSVGCommandCurve.h"

@implementation IJSVGCommandCurve

+ (NSInteger)requiredParameterCount
{
    return 6;
}

+ (void)runWithParams:(CGFloat*)params
           paramCount:(NSInteger)count
              command:(IJSVGCommand*)currentCommand
      previousCommand:(IJSVGCommand*)command
                 type:(IJSVGCommandType)type
                 path:(IJSVGPath*)path
{
    if (type == kIJSVGCommandTypeAbsolute) {
        [path.path curveToPoint:NSMakePoint(params[4], params[5])
                  controlPoint1:NSMakePoint(params[0], params[1])
                  controlPoint2:NSMakePoint(params[2], params[3])];
        return;
    }
    [path.path relativeCurveToPoint:NSMakePoint(params[4], params[5])
                      controlPoint1:NSMakePoint(params[0], params[1])
                      controlPoint2:NSMakePoint(params[2], params[3])];
}

@end
