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
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.audioPlayer = [[AudioPlayer alloc] init];
    self.audioPlayer.delegate = self;
    self.audioPlayer.isReceiving = YES;
    
    self.numberToSend.delegate = self;
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
    
    if(!self.audioPlayer.isReceiving)
    {
        NSMutableArray *seq = [NSMutableArray array];
        NSString *text = @"FOGBADJIG"; // 5, 14, 
        for(int i = 0; i < text.length; i++)
        {
            unichar c = [text characterAtIndex:i];
            [seq addObject:@(c-'A')];
        }
        [self.audioPlayer transmitSequence:[seq copy]];
    }
    
    self.button = sender;
}

- (IBAction)outputDelimPressed:(UIButton *)button
{
    [self.audioPlayer transmitPacketDelimiterWithCallback:nil];
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
