
#import <UIKit/UIKit.h>

@interface UIView (Donald)

- (UIImage *) imageSnapshot;

- (void) applySinkStyleWithInnerColor:(UIColor *)innerColor borderColor:(UIColor *)borderColor borderWidth:(float)width andCornerRadius:(float)radius;
- (void) applyStandardSinkStyle;
- (void) applyStandardSinkStyleNoRounding;

@end