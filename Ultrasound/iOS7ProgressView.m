
#import "iOS7ProgressView.h"

@interface iOS7ProgressView ()
@property (nonatomic, strong) UIView *progressView;
@property (nonatomic, strong) NSLayoutConstraint *progressWidthConstraint;

@end

@implementation iOS7ProgressView

- (void) initLayout
{
    self.backgroundColor = self.trackColor;
    
    self.progressView = [[UIView alloc] init];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:self.progressView];
    
    // Setup the progress view to take up the whole view vertically
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[progressView]-(0)-|" options:0 metrics:nil views:@{@"progressView" : self.progressView}]];
    
    // Setup left constaint to always be 0, and the width to initially be 0, and later be resized
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    self.progressWidthConstraint = [NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    
    [self addConstraint:leftConstraint];
    [self addConstraint:self.progressWidthConstraint];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initLayout];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self initLayout];
    }
    return self;
}


- (void) setProgressColor:(UIColor *)progressColor
{
    self.progressView.backgroundColor = progressColor;
}

- (void) setTrackColor:(UIColor *)trackColor
{
    self.backgroundColor = trackColor;
}

- (void) setProgress:(float)progress
{
    [self setProgress:progress animated:NO];
}

#define kAnimSpeed 200.0 // In units of pts / sec
- (void) setProgress:(float)progress animated:(BOOL)animated
{
    float toWidth = self.frame.size.width * progress;
    
    if(animated)
    {
        float oldWidth = self.progressWidthConstraint.constant;
        
        self.progressWidthConstraint.constant = toWidth;
        
        float dw = ABS(toWidth - oldWidth);
        // dw / dt = kAnimSpeed (constant)
        float dt = dw / kAnimSpeed; // (multiply with those differentials!)
        
        [UIView animateWithDuration:dt animations:^{
            [self setNeedsLayout];
        }];
    }
    else
    {
        self.progressWidthConstraint.constant = toWidth;
        [self setNeedsLayout];
    }
}


@end