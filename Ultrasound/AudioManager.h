//
//  AudioManager.h
//  Ultrasound
//
//  Created by AppDev on 9/28/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kLowerFrequencyBound 1000
#define kUpperFrequencyBound 3000
#define kNumberOfTransmitFrequencies 8


@protocol AudioManagerDelegate <NSObject>

- (void) renderAudioIntoData:(Float32 *)data withSampleRate:(double)sampleRate numberOfFrames:(int)numberOfFrames;

@end

@interface AudioManager : NSObject


- (void) startAudio;
- (void) stopAudio;
- (void) toggleAudio;

- (id) initWithDelegate:(id<AudioManagerDelegate>)delegate;

- (NSArray *) fourier:(NSArray *) requestedFrequencies;


@property (nonatomic, strong) id<AudioManagerDelegate> delegate;
@property (nonatomic) BOOL isReceiving;

@end
