
#import "GraphView.h"
#import <complex.h>
#import <QuartzCore/QuartzCore.h>

@interface GraphView()
@property  (nonatomic) Transforms transforms;
@property (nonatomic) BOOL doesNotNeedToLoadUserDefaults;
@property (nonatomic) CGPoint topLeftCartesianCoordinateOfFunctionBitmap;
@property (nonatomic) CGPoint scaleAtTimeOfBitmapRender;
@property (nonatomic) NSTimeInterval lastBitmapGenerationTime;
@end

@implementation GraphView
{
    CGImageRef offscreenImage;
}
@synthesize dataSource = _dataSource, transforms = _transforms, doesNotNeedToLoadUserDefaults = _doesNotNeedToLoadUserDefaults;

- (CGPoint) center
{
    return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

- (Transforms) transforms
{
    if(!self.doesNotNeedToLoadUserDefaults)
    {
        //_transforms = [GraphViewUtils loadSavedTransforms];
        _transforms = [self initialTransforms];
        self.doesNotNeedToLoadUserDefaults = YES;
    }
    
    Transforms output = _transforms;
    if(output.scale.x == 0)
    {
        output.scale.x = 40;
    }
    if(output.scale.y == 0)
    {
        output.scale.y = 40;
    }
    
    output.center = [self center];
    
    return output;
}

- (Transforms) initialTransforms
{
    Transforms output;
    
    output.scale.x = self.frame.size.width / 2;
    output.scale.y = self.frame.size.height / 2;
    
    output.translation.y = 0;
    output.translation.x = 0;
    
    output.center = [self center];
    
    return output;
    
}

- (CGPoint) tickMarkSpacing
{
    return CGPointMake(1, 1);
}


- (void) setTransforms:(Transforms)transforms
{
    _transforms.scale = transforms.scale;
    _transforms.translation = transforms.translation;
    
    [self setNeedsDisplay];
}



- (void) setupInitialTransforms
{
    self.transforms = [self initialTransforms];
}


- (void) drawGrid:(CGContextRef) ref withXIncrement:(double)xIncrement withYIncrement:(double)yIncrement
{
    UIGraphicsPushContext(ref);
    
    
#define kTickHeightX 2.0

    // X Axis
    CGPoint leftScreen = CGPointMake(0, 0);
    double leftCart = [GraphViewUtils convertPixelToCartesian:leftScreen withTransforms:self.transforms].x - ((int)self.transforms.translation.x % (int)xIncrement);
    
    
    CGPoint rightScreen = CGPointMake(self.frame.size.width, 0);
    double rightCart = [GraphViewUtils convertPixelToCartesian:rightScreen withTransforms:self.transforms].x - ((int)self.transforms.translation.x % (int)xIncrement);
    
    leftCart = floor(leftCart);
    rightCart = ceil(rightCart);
    
    
    
    // Start the path!
    CGContextBeginPath(ref);
    
    for(double i = leftCart; i <= rightCart; i += xIncrement)
    {
        
        CGPoint topCartesian = CGPointMake(i, kTickHeightX/2.0);
        CGPoint bottomCartesian = CGPointMake(i, -kTickHeightX/2.0);
    
        CGPoint topPixelCoord = [GraphViewUtils convertCartesianToPixel:topCartesian withTransforms:self.transforms];
        CGPoint bottomPixelCoord = [GraphViewUtils convertCartesianToPixel:bottomCartesian withTransforms:self.transforms];
        topPixelCoord.y = self.frame.size.height - 12.5;
        bottomPixelCoord.y = topPixelCoord.y + 25;
    
        CGPoint labelPosition = CGPointMake(topPixelCoord.x - 10, topPixelCoord.y - 15);
        if ((ABS(i) > 0.0001))
        {
            NSString *xValueLabel = [NSString stringWithFormat:@"%g", i];
            [xValueLabel drawAtPoint:labelPosition withFont:[UIFont systemFontOfSize:12.0f]];
        }
        else
        {
            NSString *xValueLabel = [NSString stringWithFormat:@"%i", 0];
            [xValueLabel drawAtPoint:labelPosition withFont:[UIFont systemFontOfSize:12.0f]];
        }
        
        CGContextMoveToPoint(ref, topPixelCoord.x, topPixelCoord.y);
        CGContextAddLineToPoint(ref, bottomPixelCoord.x, bottomPixelCoord.y - 7.5);
    }
    
    
#define kTickHeightY 0.01
    // Y Axis
    CGPoint topScreen = CGPointMake(0, 0);
    double topCart = [GraphViewUtils convertPixelToCartesian:topScreen withTransforms:self.transforms].y;
    
    
    CGPoint bottomScreen = CGPointMake(0, self.frame.size.height);
    double bottomCart = [GraphViewUtils convertPixelToCartesian:bottomScreen withTransforms:self.transforms].y;
    
    bottomCart = floor(bottomCart / yIncrement) * yIncrement;
    topCart = ceil(topCart / yIncrement) * yIncrement;
    
    for(double i = bottomCart; i <= topCart; i += yIncrement)
    {
        CGPoint leftCartesian = CGPointMake(-kTickHeightY/2.0, i);
        CGPoint rightCartesian = CGPointMake(kTickHeightY/2.0, i);
        
        CGPoint leftPixelCoord = [GraphViewUtils convertCartesianToPixel:leftCartesian withTransforms:self.transforms];
        CGPoint rightPixelCoord = [GraphViewUtils convertCartesianToPixel:rightCartesian withTransforms:self.transforms];
        float width = 20;
        leftPixelCoord.x = 0;
        rightPixelCoord.x = leftPixelCoord.x + width;
        if ((ABS(i) > 0.0001))
        {
            CGPoint labelPosition = CGPointMake(rightPixelCoord.x + width / 2, leftPixelCoord.y - 8);
            NSString *yValueLabel = [NSString stringWithFormat:@"%g", i];
            [yValueLabel drawAtPoint:labelPosition withFont:[UIFont systemFontOfSize:12.0f]];
        }
        else
        {
            CGPoint labelPosition = CGPointMake(rightPixelCoord.x + width / 2, leftPixelCoord.y - 8);
            NSString *yValueLabel = [NSString stringWithFormat:@"%i", 0];
            [yValueLabel drawAtPoint:labelPosition withFont:[UIFont systemFontOfSize:12.0f]];
        }

        CGContextMoveToPoint(ref, leftPixelCoord.x, leftPixelCoord.y);
        CGContextAddLineToPoint(ref, rightPixelCoord.x, rightPixelCoord.y);
    }
    
    CGContextDrawPath(ref, kCGPathStroke); // Done drawing each grid line

    UIGraphicsPopContext();
}

- (void) drawBorder: (CGContextRef) ref
{
    UIGraphicsPushContext(ref);
    
    CGContextBeginPath(ref);
    
    CGContextMoveToPoint(ref, 0, 0);
    CGContextAddLineToPoint(ref, self.frame.size.width, 0);
    CGContextAddLineToPoint(ref, self.frame.size.width, self.frame.size.height);
    CGContextAddLineToPoint(ref, 0, self.frame.size.height);
    CGContextAddLineToPoint(ref, 0, 0);

    CGContextSetLineWidth(ref, 2.0f);
    
    CGContextDrawPath(ref, kCGPathStroke); // Done drawing each grid line
    
    UIGraphicsPopContext();

}

bool hadRecentNan;
- (void) drawGraph:(CGContextRef) c withIndex:(int)index
{
    UIGraphicsPushContext(c);
    CGContextBeginPath(c);
    
    for(int i = 0 ; i <= self.frame.size.width; i+=4)
    {
        CGPoint convertedToCart = [GraphViewUtils convertPixelToCartesian:CGPointMake(i, 0) withTransforms:self.transforms];
        convertedToCart.y = [self.dataSource valueForXCoord:convertedToCart.x withIndex:index graphView:self];
        //convertedToCart.x *= 2.0*M_PI;
        
        if(isnan(convertedToCart.y) || isinf(convertedToCart.y))
        {
            hadRecentNan = YES;
            continue;
        }
        
        CGPoint finalPixelPosition = [GraphViewUtils convertCartesianToPixel:convertedToCart withTransforms:self.transforms];
        
        if(i == 0)
        {
            CGContextMoveToPoint(c, finalPixelPosition.x, finalPixelPosition.y);
        }
        else
        {
            if(hadRecentNan)
            {
                CGContextMoveToPoint(c, finalPixelPosition.x, finalPixelPosition.y);
                hadRecentNan = NO;
            }
            else
            {
                CGContextAddLineToPoint(c, finalPixelPosition.x, finalPixelPosition.y);
            }
        }
    }
    
    // S11 = 0
    // S21 = 1
    // S11 (Changed load) = 2
    // S21 (Changed load) = 3
    
    CGContextSetLineWidth(c, 1.5);
    

    
    switch (index)
    {
        case 0:
            CGContextSetRGBStrokeColor(c, 0.0, 1.0, 0.0, 0.8);
            
            break;
        case 1:
            CGContextSetRGBStrokeColor(c, 0.0, 1.0, 1.0, 1.0);

            break;
        case 2:
            CGContextSetRGBStrokeColor(c, 0.0, 1.0, 0.0, 0.8);

            CGFloat dash1[2] = {8, 2};
            CGContextSetLineDash(c, 0, dash1, 2);
            break;
        case 3:
            CGContextSetRGBStrokeColor(c, 0.0, 1.0, 1.0, 1.0);

            CGFloat dash2[2] = {8, 2};
            CGContextSetLineDash(c, 0, dash2, 2);
            break;
        default:
            CGContextSetRGBStrokeColor(c, 0.0, 0, 0, 0.0);
            break;
    }
    
    CGContextDrawPath(c, kCGPathStroke);
    UIGraphicsPopContext();
}

- (void) drawAllFunctions:(CGContextRef)c
{
    [self drawGraph:c withIndex:0];
    [self drawGraph:c withIndex:1];
    [self drawGraph:c withIndex:2];
    [self drawGraph:c withIndex:3];
}

- (void) drawCachedFunctionImage:(CGContextRef)c
{
    if(offscreenImage == NULL)
    {
        [self generateBitmap];
    }
    
    
    CGPoint topLeftPixelCoordinateOfBitmap = [GraphViewUtils convertCartesianToPixel:self.topLeftCartesianCoordinateOfFunctionBitmap withTransforms:self.transforms];
    CGRect imageRect;
    imageRect.origin = topLeftPixelCoordinateOfBitmap;
    imageRect.size = self.bounds.size;
    
    CGPoint scaleRatio;
    scaleRatio.x = self.transforms.scale.x / self.scaleAtTimeOfBitmapRender.x;
    scaleRatio.y = self.transforms.scale.y / self.scaleAtTimeOfBitmapRender.y;
    
    
    
    imageRect.size.width *= scaleRatio.x;
    imageRect.size.height *= scaleRatio.y;
    
    
    
    
    CGContextDrawImage(c, imageRect, offscreenImage);
}

- (void)drawRect:(CGRect)rect
{
    //self.translations.y = -(self.frame.size.height / 2.0) / output.scale.y;
    Transforms transforms = self.transforms;
    transforms.translation.y = (self.frame.size.height / 2.0) / self.transforms.scale.y;
    self.transforms = transforms;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    const CGFloat colors[] = {0.8, 0.8, 0.8, 1.0};
    CGContextSetStrokeColor(c, colors);
    CGContextSetFillColor(c, colors);

    
    CGPoint spacing = [self tickMarkSpacing];
    [self drawGrid:c withXIncrement:spacing.x withYIncrement:spacing.y];
    [self drawBorder:c];
    
    
    [self drawCachedFunctionImage:c];
}


- (void) generateBitmapAndRedraw
{
    [self generateBitmap];
    [self setNeedsDisplay];
}


- (void) generateBitmap
{
    NSTimeInterval currentTime = CACurrentMediaTime();
    
    if(currentTime - self.lastBitmapGenerationTime >= 1.0)
    {
        CGImageRelease(offscreenImage);
        void *data;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef bitmapContext = createBitmapContext((int)self.frame.size.width, (int)self.frame.size.height, &data);
        [self drawAllFunctions:bitmapContext];
        offscreenImage = CGBitmapContextCreateImage(bitmapContext);
        CGColorSpaceRelease(colorSpace);
        CFRelease(bitmapContext);
        free(data);
        CGPoint topLeft = CGPointMake(0, 0);
        self.topLeftCartesianCoordinateOfFunctionBitmap = [GraphViewUtils convertPixelToCartesian:topLeft withTransforms:self.transforms];
        self.scaleAtTimeOfBitmapRender = self.transforms.scale;
        
        self.lastBitmapGenerationTime = currentTime;
    }
    else
    {
        [self performSelector:@selector(generateBitmapAndRedraw) withObject:nil afterDelay:1.0];
    }
}




CGContextRef createBitmapContext (int pixelsWide, int pixelsHigh, void **bitmapData)
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    
    bitmapBytesPerRow = (pixelsWide * 4); // 1
    bitmapByteCount = (bitmapBytesPerRow * pixelsHigh);
    
    colorSpace = CGColorSpaceCreateDeviceRGB(); // 2
    *bitmapData = malloc(bitmapByteCount); // 3
    if (*bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        return NULL;
    }
    // 4
    context = CGBitmapContextCreate(*bitmapData,
                                    pixelsWide,
                                    pixelsHigh,
                                    8, // Bits per component
                                    bitmapBytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast);
    if (context== NULL)
    {
        free (*bitmapData); // 5
        fprintf (stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease(colorSpace); // 6
    
    return context; // 7
}




// Touch event handlers
#define kHorizontalThreshold 10.0
#define kVerticalThreshold 80.0
- (void)handlePinch:(UIPinchGestureRecognizer *) pinch
{
    if (pinch.state == UIGestureRecognizerStateChanged)
    {
        CGFloat pinchSize = pinch.scale;
        Transforms newTransforms = self.transforms;
        
        if(pinch.numberOfTouches < 2)
        {
            pinch.scale = 1;
            return;
        }
        
        CGPoint touch1 = [pinch locationOfTouch:0 inView:self];
        CGPoint touch2 = [pinch locationOfTouch:1 inView:self];
        
        float dx = ABS(touch2.x - touch1.x);
        float dy = ABS(touch2.y - touch1.y);
        
        float angle = atan(dy / dx);
        
        if(angle <= kHorizontalThreshold * (M_PI / 180.0))
        {
            newTransforms.scale.x *= pinchSize;
        }
        else if(angle >= kVerticalThreshold * (M_PI / 180.0))
        {
            newTransforms.scale.y *= pinchSize;
        }
        else
        {
            newTransforms.scale.x *= pinchSize;
            newTransforms.scale.y *= pinchSize;
        }
        
        
        
        
        self.transforms = newTransforms;
        
        pinch.scale = 1;
        
        return;
    }
    
    if(pinch.state == UIGestureRecognizerStateEnded)
    {
        CGFloat pinchSize = pinch.scale;
        Transforms newTransforms = self.transforms;
        newTransforms.scale.x *= pinchSize;
        newTransforms.scale.y *= pinchSize;
        
        [self generateBitmap];
        
        self.transforms = newTransforms;
        
        pinch.scale = 1;
        
        [GraphViewUtils saveTransforms:self.transforms];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *) pan
{
    if (pan.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [GraphViewUtils multiplyPoint:[pan translationInView:self] withScalar:-1];
        //tran
        CGPoint currentTranslationAsPixels = [GraphViewUtils convertCartesianToPixel:self.transforms.translation withTransforms:self.transforms];
        
        Transforms newTransforms = self.transforms;
        newTransforms.translation = [GraphViewUtils addPoint:currentTranslationAsPixels with:translation];
        newTransforms.translation = [GraphViewUtils convertPixelToCartesian:newTransforms.translation withTransforms:self.transforms];
        
        self.transforms = newTransforms;
        
        [pan setTranslation:CGPointZero inView:self];
        
        return;
    }
    
    if(pan.state == UIGestureRecognizerStateEnded)
    {
        CGPoint translation = [GraphViewUtils multiplyPoint:[pan translationInView:self] withScalar:-1];
        //tran
        CGPoint currentTranslationAsPixels = [GraphViewUtils convertCartesianToPixel:self.transforms.translation withTransforms:self.transforms];
        
        Transforms newTransforms = self.transforms;
        newTransforms.translation = [GraphViewUtils addPoint:currentTranslationAsPixels with:translation];
        newTransforms.translation = [GraphViewUtils convertPixelToCartesian:newTransforms.translation withTransforms:self.transforms];
        
        [self generateBitmap];
        
        self.transforms = newTransforms;
        
        [pan setTranslation:CGPointZero inView:self];
        
        [GraphViewUtils saveTransforms:self.transforms];
    }
}



- (void) layoutSubviews
{
    [super layoutSubviews];
    
    [self generateBitmapAndRedraw];
}

@end