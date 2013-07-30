//
//  TransmitGraphView.m
//  Ultrasound
//
//  Created by AppDev on 7/29/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import "TransmitGraphView.h"

@implementation TransmitGraphView

- (Transforms) initialTransforms
{
    Transforms trans = [super initialTransforms];
    
    trans.translation.x = 0;
    trans.translation.y = 0;
    
    trans.scale.x = self.frame.size.width / (1.0 / 690);
    trans.scale.y = self.frame.size.height / 8;
    
    return trans;
}

- (CGPoint) tickMarkSpacing
{
    return CGPointMake(10.0, 1.0);
}

@end
