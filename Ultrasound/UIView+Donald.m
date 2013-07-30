
#import "UIView+Donald.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (Donald)

- (UIImage *) imageSnapshot
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (void) applySinkStyleWithInnerColor:(UIColor *)innerColor borderColor:(UIColor *)borderColor borderWidth:(float)width andCornerRadius:(float)radius
{
    if(innerColor) self.backgroundColor = innerColor;
    if(borderColor) self.layer.borderColor = [borderColor CGColor];
    
    self.layer.borderWidth = width;
    self.layer.cornerRadius = 10.0;
}

- (void) applyStandardSinkStyle
{
    [self applySinkStyleWithInnerColor:nil borderColor:[UIColor colorWithWhite:227/255.0 alpha:1.0] borderWidth:1.0 andCornerRadius:10.0];
}

- (void) applyStandardSinkStyleNoRounding
{
    self.layer.borderColor = [[UIColor colorWithWhite:227/255.0 alpha:1.0] CGColor];
    
    self.layer.borderWidth = 1.0;
}

@end