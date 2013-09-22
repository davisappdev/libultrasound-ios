//
//  iOS7ProgressView.h
//  Protobowl
//
//  Created by Donald Pinckney on 6/17/13.
//  Copyright (c) 2013 Donald Pinckney. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iOS7ProgressView : UIView

@property (nonatomic) float progress;
@property (nonatomic, strong) UIColor *trackColor;
@property (nonatomic, strong) UIColor *progressColor;
- (void) setProgress:(float)progress animated:(BOOL)animated;
@end