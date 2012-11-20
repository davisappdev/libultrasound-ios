//
//  AudioPlayer.h
//  Ultrasound
//
//  Created by AppDev on 10/21/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioManager.h"

@interface AudioPlayer : NSObject <AudioManagerDelegate>

- (void) play;
- (void) playFrequency:(double) freq;
- (void) stop;

- (void) playFrequency:(double) freq forTime: (NSTimeInterval)time;
@end
