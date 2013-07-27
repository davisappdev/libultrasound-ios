
#import <Foundation/Foundation.h>
#import "Transforms.h"

@interface GraphViewUtils : NSObject

+ (CGPoint) convertCartesianToPixel:(CGPoint)cart withTransforms:(Transforms)transforms;

+ (CGPoint) convertPixelToCartesian:(CGPoint)pixel withTransforms:(Transforms)transforms;
    
+ (CGPoint) addPoint:(CGPoint)p0 with:(CGPoint) p1;
+ (CGPoint) multiplyPoint:(CGPoint)p0 withScalar:(CGFloat)s;

+ (Transforms) loadSavedTransforms;
+ (void) saveTransforms:(Transforms) transforms;
@end
