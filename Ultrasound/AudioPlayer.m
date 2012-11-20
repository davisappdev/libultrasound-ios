//
//  AudioPlayer.m
//  Ultrasound
//
//  Created by AppDev on 10/21/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import "AudioPlayer.h"

@interface AudioPlayer ()
@property (nonatomic, strong) AudioManager *audio;
@property (nonatomic) double theta;
@property (nonatomic) double frequency;
@end

@implementation AudioPlayer

- (id) init
{
    self = [super init];
    if(self)
    {
        self.audio = [[AudioManager alloc] initWithDelegate:self];
    }
    
    return self;
}

- (void) play
{
    
    [self.audio startAudio];
}

- (void) playFrequency:(double)freq
{
    self.frequency = freq;
    [self.audio startAudio];
}

- (void) playFrequency:(double)freq forTime:(NSTimeInterval)time
{
    [self playFrequency:freq];
    
    [self performSelector:@selector(stop) withObject:nil afterDelay:time];
}

- (void) stop
{
    [self.audio stopAudio];
}


- (void) renderAudioIntoData:(Float32 *)data withSampleRate:(double)sampleRate numberOfFrames:(int)numberOfFrames
{
    // Fixed amplitude is good enough for our purposes
	const double amplitude = 0.25;
	// Get the tone parameters out of the view controller
    
    
	double theta_increment = 2.0 * M_PI * self.frequency / sampleRate;
	
	// Generate the samples
	for (UInt32 frame = 0; frame < numberOfFrames; frame++)
	{
		data[frame] = sin(self.theta) * amplitude;
		
		self.theta += theta_increment;
		if (self.theta > 2.0 * M_PI)
		{
			self.theta -= 2.0 * M_PI;
		}
	}
}
@end
