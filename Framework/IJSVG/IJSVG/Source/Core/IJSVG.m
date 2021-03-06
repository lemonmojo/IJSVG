//
//  IJSVGImage.m
//  IconJar
//
//  Created by Curtis Hard on 30/08/2014.
//  Copyright (c) 2014 Curtis Hard. All rights reserved.
//

#import "IJSVG.h"
#import "IJSVGExporter.h"
#import "IJSVGTransaction.h"

@implementation IJSVG

@synthesize title = _title;
@synthesize desc = _desc;
@synthesize renderingBackingScaleHelper;
@synthesize clipToViewport;
@synthesize renderQuality;
@synthesize renderingStyle = _renderingStyle;
@synthesize intrinsicSize = _intrinsicSize;

- (void)dealloc
{
    // this can all be called on the background thread to be released
    BOOL hasTransaction = IJSVGBeginTransaction();
    (void)([renderingBackingScaleHelper release]),
        renderingBackingScaleHelper = nil;
    (void)([_replacementColors release]), _replacementColors = nil;
    (void)([_renderingStyle release]), _renderingStyle = nil;
    (void)([_group release]), _group = nil;
    (void)([_intrinsicSize release]), _intrinsicSize = nil;
    (void)([_desc release]), _desc = nil;
    (void)([_title release]), _title = nil;

    // kill any memory that has been around
    (void)([_layerTree release]), _layerTree = nil;
    [super dealloc];
    if (hasTransaction == YES) {
        IJSVGEndTransaction();
    }
}

+ (id)svgNamed:(NSString*)string
         error:(NSError**)error
{
    return [self.class svgNamed:string
                          error:error
                       delegate:nil];
}

+ (id)svgNamed:(NSString*)string
{
    return [self.class svgNamed:string
                          error:nil];
}

+ (id)svgNamed:(NSString*)string
      delegate:(id<IJSVGDelegate>)delegate
{
    return [self.class svgNamed:string
                          error:nil
                       delegate:delegate];
}

+ (id)svgNamed:(NSString*)string
         error:(NSError**)error
      delegate:(id<IJSVGDelegate>)delegate
{
    NSBundle* bundle = NSBundle.mainBundle;
    NSString* str = nil;
    NSString* ext = [string pathExtension];
    if (ext == nil || ext.length == 0) {
        ext = @"svg";
    }
    if ((str = [bundle pathForResource:[string stringByDeletingPathExtension]
                                ofType:ext])
        != nil) {
        return [[[self alloc] initWithFile:str
                                     error:error
                                  delegate:delegate] autorelease];
    }
    return nil;
}

- (id)initWithImage:(NSImage*)image
{
    __block IJSVGGroupLayer* layer = nil;
    __block IJSVGImageLayer* imageLayer = nil;

    // create the layers we require
    BOOL hasTransaction = IJSVGBeginTransaction();
    layer = [[[IJSVGGroupLayer alloc] init] autorelease];
    imageLayer =
        [[[IJSVGImageLayer alloc] initWithImage:image] autorelease];
    [layer addSublayer:imageLayer];
    if (hasTransaction == YES) {
        IJSVGEndTransaction();
    }

    // return the initialized SVG
    return [self initWithSVGLayer:layer
                          viewBox:imageLayer.frame];
}

- (id)initWithSVGLayer:(IJSVGGroupLayer*)group
               viewBox:(NSRect)viewBox
{
    // this completely bypasses passing of files
    if ((self = [super init]) != nil) {
        // keep the layer tree
        _layerTree = [group retain];
        _viewBox = viewBox;

        // any setups
        [self _setupBasicsFromAnyInitializer];
    }
    return self;
}

- (id)initWithFile:(NSString*)file
{
    return [self initWithFile:file
                        error:nil
                     delegate:nil];
}

- (id)initWithFile:(NSString*)file
             error:(NSError**)error
          delegate:(id<IJSVGDelegate>)delegate
{
    return [self initWithFilePathURL:[NSURL fileURLWithPath:file isDirectory:NO]
                               error:error
                            delegate:delegate];
}

- (id)initWithFile:(NSString*)file
             error:(NSError**)error
{
    return [self initWithFile:file
                        error:error
                     delegate:nil];
}

- (id)initWithFile:(NSString*)file
          delegate:(id<IJSVGDelegate>)delegate
{
    return [self initWithFile:file
                        error:nil
                     delegate:delegate];
}

- (id)initWithFilePathURL:(NSURL*)aURL
{
    return [self initWithFilePathURL:aURL
                               error:nil
                            delegate:nil];
}

- (id)initWithFilePathURL:(NSURL*)aURL
                    error:(NSError**)error
{
    return [self initWithFilePathURL:aURL
                               error:error
                            delegate:nil];
}

- (id)initWithFilePathURL:(NSURL*)aURL
                 delegate:(id<IJSVGDelegate>)delegate
{
    return [self initWithFilePathURL:aURL
                               error:nil
                            delegate:delegate];
}

- (id)initWithFilePathURL:(NSURL*)aURL
                    error:(NSError**)error
                 delegate:(id<IJSVGDelegate>)delegate
{
    // create the object
    if ((self = [super init]) != nil) {
        NSError* anError = nil;
        _delegate = delegate;

        // this is a really quick check against the delegate
        // for methods that exist
        [self _checkDelegate];

        // create the group
        _group = [[IJSVGParser groupForFileURL:aURL
                                         error:&anError
                                      delegate:self] retain];

        [self _setupBasicInfoFromGroup];
        [self _setupBasicsFromAnyInitializer];

        // something went wrong...
        if (_group == nil) {
            if (error != NULL) {
                *error = anError;
            }
            (void)([self release]), self = nil;
            return nil;
        }
    }
    return self;
}

- (id)initWithSVGData:(NSData*)data
{
    return [self initWithSVGData:data
                           error:nil];
}

- (id)initWithSVGData:(NSData*)data
                error:(NSError**)error
{
    NSString* svgString = [[NSString alloc] initWithData:data
                                                encoding:NSUTF8StringEncoding];
    return [self initWithSVGString:svgString.autorelease
                             error:error];
}

- (id)initWithSVGString:(NSString*)string
{
    return [self initWithSVGString:string
                             error:nil
                          delegate:nil];
}

- (id)initWithSVGString:(NSString*)string
                  error:(NSError**)error
{
    return [self initWithSVGString:string
                             error:error
                          delegate:nil];
}

- (id)initWithSVGString:(NSString*)string
                  error:(NSError**)error
               delegate:(id<IJSVGDelegate>)delegate
{
    if ((self = [super init]) != nil) {
        // this is basically the same as init with URL just
        // bypasses the loading of a file
        NSError* anError = nil;
        _delegate = delegate;
        [self _checkDelegate];

        // setup the parser
        _group = [[IJSVGParser alloc] initWithSVGString:string
                                                  error:&anError
                                               delegate:self];

        [self _setupBasicInfoFromGroup];
        [self _setupBasicsFromAnyInitializer];

        // something went wrong :(
        if (_group == nil) {
            if (error != NULL) {
                *error = anError;
            }
            (void)([self release]), self = nil;
            return nil;
        }
    }
    return self;
}

- (void)performBlock:(dispatch_block_t)block
{
    BOOL hasTransaction = IJSVGBeginTransaction();
    block();
    if (hasTransaction == YES) {
        IJSVGEndTransaction();
    }
}

- (void)discardDOM
{
    // if we discard, we can no longer create a tree, so lets create tree
    // upfront before we kill anything
    [self layer];

    // now clear memory
    (void)([_group release]), _group = nil;
}

- (void)_setupBasicInfoFromGroup
{
    _viewBox = _group.viewBox;
    _intrinsicSize = _group.intrinsicSize.retain;
}

- (void)_setupBasicsFromAnyInitializer
{
    self.renderingStyle = [[[IJSVGRenderingStyle alloc] init] autorelease];
    self.clipToViewport = YES;
    self.renderQuality = kIJSVGRenderQualityFullResolution;

    // setup low level backing scale
    _lastProposedBackingScale = 0.f;
    self.renderingBackingScaleHelper = ^CGFloat {
        return NSScreen.mainScreen.backingScaleFactor;
    };
}

- (void)setTitle:(NSString*)title
{
    _group.title = title;
}

- (NSString*)title
{
    return _group.title;
}

- (void)setDesc:(NSString*)description
{
    _group.desc = description;
}

- (NSString*)desc
{
    return _group.desc;
}

- (NSString*)identifier
{
    return _group.identifier;
}

- (void)_checkDelegate
{
    _respondsTo.shouldHandleForeignObject =
        [_delegate respondsToSelector:@selector(svg:shouldHandleForeignObject:)];
    _respondsTo.handleForeignObject = [_delegate
        respondsToSelector:@selector(svg:handleForeignObject:document:)];
    _respondsTo.shouldHandleSubSVG =
        [_delegate respondsToSelector:@selector(svg:foundSubSVG:withSVGString:)];
}

- (NSRect)viewBox
{
    return _viewBox;
}

- (IJSVGGroup*)rootNode
{
    return _group;
}

- (BOOL)isFont
{
    return [_group isFont];
}

- (NSArray<IJSVGPath*>*)glyphs
{
    return [_group glyphs];
}

- (NSArray<IJSVG*>*)subSVGs:(BOOL)recursive
{
    return [_group subSVGs:recursive];
}

- (NSString*)SVGStringWithOptions:(IJSVGExporterOptions)options
{
    IJSVGExporter* exporter = [[[IJSVGExporter alloc] initWithSVG:self
                                                             size:self.viewBox.size
                                                          options:options] autorelease];
    return [exporter SVGString];
}

- (NSString*)SVGStringWithOptions:(IJSVGExporterOptions)options
             floatingPointOptions:(IJSVGFloatingPointOptions)floatingPointOptions
{
    IJSVGExporter* exporter = [[[IJSVGExporter alloc] initWithSVG:self
                                                             size:self.viewBox.size
                                                          options:options
                                             floatingPointOptions:floatingPointOptions] autorelease];
    return [exporter SVGString];
}

- (NSImage*)imageWithSize:(NSSize)aSize
{
    return [self imageWithSize:aSize
                       flipped:NO
                         error:nil];
}

- (NSImage*)imageWithSize:(NSSize)aSize
                    error:(NSError**)error;
{
    return [self imageWithSize:aSize
                       flipped:NO
                         error:error];
}

- (NSImage*)imageWithSize:(NSSize)aSize
                  flipped:(BOOL)flipped
{
    return [self imageWithSize:aSize
                       flipped:flipped
                         error:nil];
}

- (NSSize)computeSVGSizeWithRenderSize:(NSSize)size
{
    IJSVGUnitSize* svgSize = _intrinsicSize;
    return NSMakeSize([svgSize.width computeValue:size.width],
        [svgSize.height computeValue:size.height]);
}

- (NSRect)computeOriginalDrawingFrameWithSize:(NSSize)aSize
{
    NSSize propSize = [self computeSVGSizeWithRenderSize:aSize];
    [self _beginDraw:(NSRect) { .origin = CGPointZero, .size = aSize }];
    return NSMakeRect(0.f, 0.f, propSize.width * _clipScale,
        propSize.height * _clipScale);
}

- (CGImageRef)newCGImageRefWithSize:(CGSize)size
                            flipped:(BOOL)flipped
                              error:(NSError**)error
{
    // setup the drawing rect, this is used for both the intial drawing
    // and the backing scale helper block
    NSRect rect = (CGRect) {
        .origin = CGPointZero,
        .size = (CGSize)size
    };

    // this is highly important this is setup
    [self _beginDraw:rect];

    // make sure we setup the scale based on the backing scale factor
    CGFloat scale = [self backingScaleFactor:NULL];

    // create the context and colorspace
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ref = CGBitmapContextCreate(NULL, (int)size.width * scale,
        (int)size.height * scale, 8, 0, colorSpace,
        kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);

    // scale the context
    CGContextScaleCTM(ref, scale, scale);

    if (flipped == YES) {
        CGContextTranslateCTM(ref, 0.f, size.height);
        CGContextScaleCTM(ref, 1.f, -1.f);
    }

    // draw the SVG into the context
    [self _drawInRect:rect
              context:ref
                error:error];

    // create the image from the context
    CGImageRef imageRef = CGBitmapContextCreateImage(ref);

    // release all things!
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(ref);
    return imageRef;
}

- (NSImage*)imageWithSize:(NSSize)aSize
                  flipped:(BOOL)flipped
                    error:(NSError**)error
{
    CGImageRef ref = [self newCGImageRefWithSize:aSize
                                         flipped:flipped
                                           error:error];

    NSImage* image = [[NSImage alloc] initWithCGImage:ref
                                                 size:aSize];
    CGImageRelease(ref);
    return image.autorelease;
}

- (NSImage*)imageByMaintainingAspectRatioWithSize:(NSSize)aSize
                                          flipped:(BOOL)flipped
                                            error:(NSError**)error
{
    NSRect rect = [self computeOriginalDrawingFrameWithSize:aSize];
    return [self imageWithSize:rect.size flipped:flipped error:error];
}

- (NSData*)PDFData
{
    return [self PDFData:nil];
}

- (NSData*)PDFData:(NSError**)error
{
    return [self
        PDFDataWithRect:(NSRect) { .origin = NSZeroPoint, .size = _viewBox.size }
                  error:error];
}

- (NSData*)PDFDataWithRect:(NSRect)rect
{
    return [self PDFDataWithRect:rect error:nil];
}

- (NSData*)PDFDataWithRect:(NSRect)rect
                     error:(NSError**)error
{
    // create the data for the PDF
    NSMutableData* data = [[[NSMutableData alloc] init] autorelease];

    // assign the data to the consumer
    CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)data);
    const CGRect box = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width,
        rect.size.height);

    // create the context
    CGContextRef context = CGPDFContextCreate(dataConsumer, &box, NULL);

    CGContextBeginPage(context, &box);

    // the context is currently upside down, doh! flip it...
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -box.size.height);

    // make sure we set the masks to path bits n bobs
    [self _beginVectorDraw];
    // draw the icon
    [self _drawInRect:(NSRect)box context:context error:error];
    [self _endVectorDraw];

    CGContextEndPage(context);

    // clean up
    CGPDFContextClose(context);
    CGContextRelease(context);
    CGDataConsumerRelease(dataConsumer);
    return data;
}

- (void)endVectorDraw
{
    [self _endVectorDraw];
}

- (void)beginVectorDraw
{
    [self _beginVectorDraw];
}

- (void)_beginVectorDraw
{
    // turn on converts masks to PDF's
    // as PDF context and layer masks dont work
    void (^block)(CALayer* layer, BOOL isMask) = ^void(CALayer* layer, BOOL isMask) {
        ((IJSVGLayer*)layer).convertMasksToPaths = YES;
    };
    [IJSVGLayer recursivelyWalkLayer:self.layer withBlock:block];
}

- (void)_endVectorDraw
{
    // turn of convert masks to paths as not
    // needed for generic rendering
    void (^block)(CALayer* layer, BOOL isMask) = ^void(CALayer* layer, BOOL isMask) {
        ((IJSVGLayer*)layer).convertMasksToPaths = NO;
    };
    [IJSVGLayer recursivelyWalkLayer:self.layer withBlock:block];
}

- (void)prepForDrawingInView:(NSView*)view
{
    // kill the render
    if (view == nil) {
        self.renderingBackingScaleHelper = nil;
        return;
    }

    // construct the layer before drawing
    [self layer];

    // set the scale
    __block NSView* weakView = view;
    self.renderingBackingScaleHelper = ^CGFloat {
        return weakView.window.screen.backingScaleFactor;
    };
}

- (BOOL)drawAtPoint:(NSPoint)point
               size:(NSSize)aSize
{
    return [self drawAtPoint:point
                        size:aSize
                       error:nil];
}

- (BOOL)drawAtPoint:(NSPoint)point
               size:(NSSize)aSize
              error:(NSError**)error
{
    return
        [self drawInRect:NSMakeRect(point.x, point.y,
                             aSize.width, aSize.height)
                   error:error];
}

- (BOOL)drawInRect:(NSRect)rect
{
    return [self drawInRect:rect error:nil];
}

- (BOOL)drawInRect:(NSRect)rect
             error:(NSError**)error
{
    CGContextRef currentCGContext;
    if (@available(macOS 10.10, *)) {
        currentCGContext = NSGraphicsContext.currentContext.CGContext;
    } else {
        currentCGContext = NSGraphicsContext.currentContext.graphicsPort;
    }
    return [self _drawInRect:rect
                     context:currentCGContext
                       error:error];
}

- (CGFloat)computeBackingScale:(CGFloat)actualScale
{
    _backingScale = actualScale;
    return (CGFloat)(_scale + actualScale);
}

- (NSRect)computeRectDrawingInRect:(NSRect)rect
                           isValid:(BOOL*)valid
{
    // we also need to calculate the viewport so we can clip
    // the drawing if needed
    NSRect viewPort = NSZeroRect;
    NSSize propSize = [self computeSVGSizeWithRenderSize:rect.size];
    viewPort.origin.x = round((rect.size.width / 2 - (propSize.width / 2) * _clipScale) + rect.origin.x);
    viewPort.origin.y = round(
        (rect.size.height / 2 - (propSize.height / 2) * _clipScale) + rect.origin.y);
    viewPort.size.width = propSize.width * _clipScale;
    viewPort.size.height = propSize.height * _clipScale;

    // check the viewport
    if (NSEqualRects(_viewBox, NSZeroRect) || _viewBox.size.width <= 0 || _viewBox.size.height <= 0 || NSEqualRects(NSZeroRect, viewPort) || CGRectIsEmpty(viewPort) || CGRectIsNull(viewPort) || viewPort.size.width <= 0 || viewPort.size.height <= 0) {
        *valid = NO;
        return NSZeroRect;
    }

    *valid = YES;
    return viewPort;
}

- (void)drawInRect:(NSRect)rect
           context:(CGContextRef)context
{
    [self _drawInRect:rect context:context error:nil];
}

- (BOOL)_drawInRect:(NSRect)rect
            context:(CGContextRef)ref
              error:(NSError**)error
{
    // prep for draw...
    CGContextSaveGState(ref);
    @try {
        [self _beginDraw:rect];

        // we also need to calculate the viewport so we can clip
        // the drawing if needed
        BOOL canDraw = NO;
        NSRect viewPort = [self computeRectDrawingInRect:rect isValid:&canDraw];
        // check the viewport
        if (canDraw == NO) {
            if (error != NULL) {
                *error = [[[NSError alloc] initWithDomain:IJSVGErrorDomain
                                                     code:IJSVGErrorDrawing
                                                 userInfo:nil] autorelease];
            }
        } else {
            // clip to mask
            if (self.clipToViewport == YES) {
                CGContextClipToRect(ref, viewPort);
            }

            // add the origin back onto the viewport
            viewPort.origin.x -= (_viewBox.origin.x) * _scale;
            viewPort.origin.y -= (_viewBox.origin.y) * _scale;

            // transforms
            CGContextTranslateCTM(ref, viewPort.origin.x, viewPort.origin.y);
            CGContextScaleCTM(ref, _scale, _scale);

            // do we need to update the backing scales on the
            // layers?
            [self backingScaleFactor:nil];

            CGInterpolationQuality quality;
            switch (self.renderQuality) {
            case kIJSVGRenderQualityLow: {
                quality = kCGInterpolationLow;
                break;
            }
            case kIJSVGRenderQualityOptimized: {
                quality = kCGInterpolationMedium;
                break;
            }
            default: {
                quality = kCGInterpolationHigh;
            }
            }
            CGContextSetInterpolationQuality(ref, quality);
            BOOL hasTransaction = IJSVGBeginTransaction();
            [self.layer renderInContext:ref];
            if (hasTransaction == YES) {
                IJSVGEndTransaction();
            }
        }
    } @catch (NSException* exception) {
        // just catch and give back a drawing error to the caller
        if (error != NULL) {
            *error = [[[NSError alloc] initWithDomain:IJSVGErrorDomain
                                                 code:IJSVGErrorDrawing
                                             userInfo:nil] autorelease];
        }
    }
    CGContextRestoreGState(ref);
    return (error == nil);
}

- (CGFloat)backingScaleFactor:(CGFloat* _Nullable)proposedBackingScale
{
    __block CGFloat scale = 1.f;
    scale = (self.renderingBackingScaleHelper)();
    if (scale < 1.f) {
        scale = 1.f;
    }
    _backingScaleFactor = scale;

    // make sure we multiple the scale by the scale of the rendered clip
    // or it will be blurry for gradients and other bitmap drawing
    scale = (_scale * scale);

    // dont do anything, nothing has changed, no point of iterating over
    // every layer for no reason!
    if (scale == _lastProposedBackingScale && renderQuality == _lastProposedRenderQuality) {
        return _backingScaleFactor;
    }

    IJSVGRenderQuality quality = self.renderQuality;
    _lastProposedBackingScale = scale;
    _lastProposedRenderQuality = quality;
    if (proposedBackingScale != nil && proposedBackingScale != NULL) {
        *proposedBackingScale = scale;
    }

    // walk the tree
    void (^block)(CALayer* layer, BOOL isMask) = ^void(CALayer* layer, BOOL isMask) {
        IJSVGLayer* propLayer = ((IJSVGLayer*)layer);
        propLayer.renderQuality = quality;
        if (propLayer.requiresBackingScaleHelp == YES) {
            propLayer.backingScaleFactor = scale;
        }
    };

    // gogogo
    BOOL hasTransaction = IJSVGBeginTransaction();
    [IJSVGLayer recursivelyWalkLayer:self.layer withBlock:block];
    if (hasTransaction == YES) {
        IJSVGEndTransaction();
    }
    return _backingScaleFactor;
}

- (IJSVGLayer*)layerWithTree:(IJSVGLayerTree*)tree
{
    // clear memory
    BOOL hasTransaction = IJSVGBeginTransaction();
    if (_layerTree != nil) {
        (void)([_layerTree release]), _layerTree = nil;
    }

    // force rebuild of the tree
    _layerTree = [[tree layerForNode:_group] retain];
    if (hasTransaction == YES) {
        IJSVGEndTransaction();
    }
    return _layerTree;
}

- (IJSVGLayer*)layer
{
    if (_layerTree != nil) {
        return _layerTree;
    }

    // create the renderer and assign default values
    // from this SVG object
    IJSVGLayerTree* renderer = [[[IJSVGLayerTree alloc] init] autorelease];
    renderer.viewBox = self.viewBox;
    renderer.style = self.renderingStyle;

    // return the rendered layer
    return [self layerWithTree:renderer];
}

- (void)setRenderingStyle:(IJSVGRenderingStyle*)style
{
    (void)([_renderingStyle release]), _renderingStyle = nil;
    _renderingStyle = style.retain;
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id>*)change
                       context:(void*)context
{
    // invalidate the tree if a style is set
    if (object == _renderingStyle) {
        [self invalidateLayerTree];
    }
}

- (void)setNeedsDisplay
{
    [self invalidateLayerTree];
}

- (void)invalidateLayerTree
{
    (void)([_layerTree release]), _layerTree = nil;
}

- (IJSVGColorList*)computedColorList:(BOOL*)hasPatternFills
{
    IJSVGColorList* sheet = [[[IJSVGColorList alloc] init] autorelease];
    void (^block)(CALayer* layer, BOOL isMask) = ^void(CALayer* layer,
        BOOL isMask) {
        if ([layer isKindOfClass:[IJSVGShapeLayer class]] && isMask == NO && layer.isHidden == NO) {
            IJSVGShapeLayer* sLayer = (IJSVGShapeLayer*)layer;
            NSColor* color = nil;
            if (sLayer.fillColor != nil) {
                color = [NSColor colorWithCGColor:sLayer.fillColor];
                if (color.alphaComponent != 0.f) {
                    [sheet addColor:color];
                }
            }
            if (sLayer.strokeColor != nil) {
                color = [NSColor colorWithCGColor:sLayer.strokeColor];
                color = [IJSVGColor computeColorSpace:color];
                if (color.alphaComponent != 0.f) {
                    [sheet addColor:color];
                }
            }

            // check for any patterns
            if (sLayer.patternFillLayer != nil || sLayer.gradientFillLayer != nil || sLayer.gradientStrokeLayer != nil || sLayer.patternStrokeLayer != nil) {
                if (hasPatternFills != nil && *hasPatternFills != YES) {
                    *hasPatternFills = YES;
                }

                // add any colors from gradients
                IJSVGGradientLayer* gradLayer = nil;
                IJSVGGradientLayer* gradStrokeLayer = nil;
                if ((gradLayer = sLayer.gradientFillLayer) != nil) {
                    IJSVGColorList* gradSheet = gradLayer.gradient.computedColorList;
                    [sheet addColorsFromList:gradSheet];
                }
                if ((gradStrokeLayer = sLayer.gradientStrokeLayer) != nil) {
                    IJSVGColorList* gradSheet = gradStrokeLayer.gradient.computedColorList;
                    [sheet addColorsFromList:gradSheet];
                }
            }
        }
    };

    // walk
    [IJSVGLayer recursivelyWalkLayer:self.layer withBlock:block];

    // return the colours!
    return sheet;
}

- (void)_beginDraw:(NSRect)rect
{
    // in order to correctly fit the the SVG into the
    // rect, we need to work out the ratio scale in order
    // to transform the paths into our viewbox
    NSSize dest = rect.size;
    NSSize source = _viewBox.size;
    NSSize propSize = [self computeSVGSizeWithRenderSize:rect.size];
    _clipScale = MIN(dest.width / propSize.width,
        dest.height / propSize.height);

    // work out the actual scale based on the clip scale
    CGFloat w = propSize.width * _clipScale;
    CGFloat h = propSize.height * _clipScale;
    _scale = MIN(w / source.width, h / source.height);
}

#pragma mark NSPasteboard

- (NSArray*)writableTypesForPasteboard:(NSPasteboard*)pasteboard
{
    return @[ NSPasteboardTypePDF ];
}

- (id)pasteboardPropertyListForType:(NSString*)type
{
    if ([type isEqualToString:NSPasteboardTypePDF]) {
        return [self PDFData];
    }
    return nil;
}

#pragma mark IJSVGParserDelegate

- (void)svgParser:(IJSVGParser*)svg
      foundSubSVG:(IJSVG*)subSVG
    withSVGString:(NSString*)string
{
    if (_delegate != nil && _respondsTo.shouldHandleSubSVG == 1) {
        [_delegate svg:self
              foundSubSVG:subSVG
            withSVGString:string];
    }
}

- (BOOL)svgParser:(IJSVGParser*)parser
    shouldHandleForeignObject:(IJSVGForeignObject*)foreignObject
{
    if (_delegate != nil && _respondsTo.shouldHandleForeignObject == 1) {
        return [_delegate svg:self
            shouldHandleForeignObject:foreignObject];
    }
    return NO;
}

- (void)svgParser:(IJSVGParser*)parser
    handleForeignObject:(IJSVGForeignObject*)foreignObject
               document:(NSXMLDocument*)document
{
    if (_delegate != nil && _respondsTo.handleForeignObject == 1) {
        [_delegate svg:self
            handleForeignObject:foreignObject
                       document:document];
    }
}

@end
