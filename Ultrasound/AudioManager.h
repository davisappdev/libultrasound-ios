//
//  AudioManager.h
//  Ultrasound
//
//  Created by AppDev on 9/28/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTransmitFrequencies @[@17980, @18174, @18605, @19509]
#define kNumberOfTransmitFrequencies 4
#define kPacketDelimiterFrequency 19003


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
