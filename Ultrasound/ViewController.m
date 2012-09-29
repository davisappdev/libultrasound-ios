//
//  ViewController.m
//  Ultrasound
//
//  Created by AppDev on 9/28/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) AudioManager *audio;
@property (nonatomic) double theta;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.audio = [[AudioManager alloc] initWithDelegate:self];
    [self.audio startAudio];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) renderAudioIntoData:(Float32 *)data withSampleRate:(double)sampleRate numberOfFrames:(int)numberOfFrames
{
    // Fixed amplitude is good enough for our purposes
	const double amplitude = 0.25;
	// Get the tone parameters out of the view controller
    
    
	double theta_increment = 2.0 * M_PI * 440 / sampleRate;
	
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
