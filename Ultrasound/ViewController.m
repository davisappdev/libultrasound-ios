//
//  ViewController.m
//  Ultrasound
//
//  Created by AppDev on 9/28/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import "ViewController.h"
#import "AudioPlayer.h"

@interface ViewController ()
@property (nonatomic, strong) AudioPlayer *audioPlayer;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.audioPlayer = [[AudioPlayer alloc] init];
    //[self.audioPlayer playFrequency:880 forTime:10.0];
    [self.audioPlayer play];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
