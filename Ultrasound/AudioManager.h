//
//  AudioManager.h
//  Ultrasound
//
//  Created by AppDev on 9/28/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTransmitFrequencies @[@16990, @17420, @17851, @18282, @18712, @19143, @19574, @20004]
#define kNumberOfTransmitFrequencies 8
#define kPacketDelimiterFrequency 19003
#define kRatio (21.533203125)


@protocol AudioManagerDelegate <NSObject>

- (void) renderAudioIntoData:(Float32 *)data withSampleRate:(double)sampleRate numberOfFrames:(int)numberOfFrames;
- (void) fftData:(float *)data arraySize:(int)size cutoff:(float)cutoff;

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
