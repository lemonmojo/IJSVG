//
//  IJSVGStyleSheetRule.h
//  IJSVGExample
//
//  Created by Curtis Hard on 16/01/2016.
//  Copyright © 2016 Curtis Hard. All rights reserved.
//

#import "IJSVGStyle.h"
#import "IJSVGStyleSheetSelector.h"
#import <Foundation/Foundation.h>

@class IJSVGNode;

@interface IJSVGStyleSheetRule : NSObject {

    NSArray* selectors;
    IJSVGStyle* style;
}

@property (nonatomic, retain) NSArray* selectors;
@property (nonatomic, retain) IJSVGStyle* style;

- (BOOL)matchesNode:(IJSVGNode*)node
           selector:(IJSVGStyleSheetSelector**)matchedSelector;

@end
