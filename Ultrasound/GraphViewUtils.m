
#import "GraphViewUtils.h"

@implementation GraphViewUtils

//TODO: Divide by (2*M_PI)
+ (CGPoint) convertCartesianToPixel:(CGPoint)p withTransforms:(Transforms)transforms
{
    CGPoint cart = [self addPoint:p with:[self multiplyPoint:transforms.translation withScalar:-1]];
    
    CGPoint point = transforms.center;
    point.x += cart.x * transforms.scale.x;
    point.y += -cart.y * transforms.scale.y;
    
    return point;
}

+ (CGPoint) convertPixelToCartesian:(CGPoint)p withTransforms:(Transforms)transforms
{
    double xDiff = (p.x-transforms.center.x) / transforms.scale.x; // Find difference between center of screen and pixel, then scale
    double yDiff = -(p.y-transforms.center.y) / transforms.scale.y;
    CGPoint point = CGPointMake(xDiff, yDiff);
    
    
    point = [self addPoint:point with:transforms.translation]; // Apply translation
    
    return point;
}

+ (CGPoint) addPoint:(CGPoint)p0 with:(CGPoint) p1
{
    return CGPointMake(p0.x + p1.x, p0.y + p1.y);
}

+ (CGPoint) multiplyPoint:(CGPoint)p0 withScalar:(CGFloat)s
{
    return CGPointMake(p0.x * s, p0.y * s);
}

+ (Transforms) loadSavedTransforms
{
    NSUserDefaults *savedData = [NSUserDefaults standardUserDefaults];
    
    CGPoint scale = CGPointMake([savedData doubleForKey:@"scale_x"], [savedData doubleForKey:@"scale_y"]);
    CGPoint translation = CGPointMake([savedData doubleForKey:@"trans_x"], [savedData doubleForKey:@"trans_y"]);
    
    Transforms transform;
    transform.scale = scale;
    transform.translation = translation;
    
    return transform;
}

+ (void) saveTransforms:(Transforms)transforms
{
    NSUserDefaults *savedData = [NSUserDefaults standardUserDefaults];
    [savedData setDouble:transforms.scale.x forKey:@"scale_x"];
    [savedData setDouble:transforms.scale.y forKey:@"scale_y"];

    [savedData setDouble:transforms.translation.x forKey:@"trans_x"];
    [savedData setDouble:transforms.translation.y forKey:@"trans_y"];
}
@end
