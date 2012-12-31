//
//  ViewController.m
//  Ultrasound
//
//  Created by AppDev on 9/28/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (nonatomic, strong) AudioPlayer *audioPlayer;
@property (nonatomic, weak) UIButton *button;
@property (nonatomic) Byte byteToTransmit;
@property (nonatomic, strong) NSTimer *transmitTimer;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.audioPlayer = [[AudioPlayer alloc] init];
    self.audioPlayer.delegate = self;
    self.audioPlayer.isReceiving = YES;
    
    self.numberToSend.delegate = self;
    self.byteToTransmit = 230;
    //[self.audioPlayer playFrequency:880 forTime:10.0];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startPressed:(id)sender
{
    [self.audioPlayer start];
    
    [sender setEnabled:NO];
    [sender setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [sender setAlpha:0.4];
    
    self.button = sender;
    
    
    if(!self.audioPlayer.isReceiving)
    {
        self.transmitTimer = [NSTimer timerWithTimeInterval:0.6 target:self selector:@selector(updateTransmission) userInfo:nil repeats:YES];
        //[[NSRunLoop mainRunLoop] addTimer:self.transmitTimer forMode:NSRunLoopCommonModes];
    }
    
}

- (void) updateTransmission
{
    [self.audioPlayer setDataToTransmit:self.byteToTransmit];
    self.numberToSend.text = [NSString stringWithFormat:@"%i", (int)self.byteToTransmit];
    self.byteToTransmit++;
}

- (IBAction)stepperValueChanged:(UIStepper *)sender
{
    self.numberToSend.text = [NSString stringWithFormat:@"%i", (int)sender.value];
    [self textFieldDidEndEditing:self.numberToSend];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField endEditing:YES];
    return YES;
}

- (BOOL) textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    NSString *dataToSend = textField.text;
    [self.audioPlayer setDataToTransmit:dataToSend.intValue];
    self.stepper.value = dataToSend.doubleValue;
}

- (IBAction)modeChanged:(id)sender
{
    [self.audioPlayer stop];
    
    [self.transmitTimer invalidate];
    self.byteToTransmit = 230;
    
    if([sender selectedSegmentIndex] == 0)
    {
        self.audioPlayer.isReceiving = YES;
    }
    else
    {
        self.audioPlayer.isReceiving = NO;
    }
    
    if(self.button)
    {
        self.button.enabled = YES;
        self.button.alpha = 1.0;
    }
}


- (void) audioReceivedDataUpdate:(int)data
{
    self.receivedData.text = [NSString stringWithFormat:@"%i", data];
}

@end
