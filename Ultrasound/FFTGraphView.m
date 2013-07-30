//
//  FFTGraphView.m
//  Ultrasound
//
//  Created by AppDev on 7/26/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import "FFTGraphView.h"

@implementation FFTGraphView

- (Transforms) initialTransforms
{
    Transforms trans = [super initialTransforms];
    
    trans.translation.x = 20000;
    trans.translation.y = 0;
    
    trans.scale.x = self.frame.size.width / 6000.0;
    trans.scale.y = self.frame.size.height / 100.0;
    
    return trans;
}

- (CGPoint) tickMarkSpacing
{
    return CGPointMake(1000, 20);
}

@end
