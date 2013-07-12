//
//  ViewController.m
//  Ultrasound
//
//  Created by AppDev on 9/28/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import "ViewController.h"
#import "Processor.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (nonatomic, strong) AudioPlayer *audioPlayer;
@property (nonatomic, weak) UIButton *button;

@property (nonatomic, strong) UIPopoverController *pop;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.audioPlayer = [[AudioPlayer alloc] init];
    self.audioPlayer.delegate = self;
    self.audioPlayer.isReceiving = YES;
    
    self.numberToSend.delegate = self;
    self.textToSendField.delegate = self;
    //[self.audioPlayer playFrequency:880 forTime:10.0];
    

}


- (IBAction)cameraPressed:(id)sender
{
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
    scanViewController.appToken = @"0a3e3723bfde4ff683d03cd1520aabcc"; // get your app token from the card.io website
    [self presentViewController:scanViewController animated:YES completion:nil];
}

- (void) userDidCancelPaymentViewController:(CardIOPaymentViewController *)scanViewController
{
    NSLog(@"User canceled payment info");
    // Handle user cancellation here...
    [scanViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)info inPaymentViewController:(CardIOPaymentViewController *)scanViewController
{
    // The full card number is available as info.cardNumber, but don't log that!
    NSLog(@"Received card info. Number: %@, type:%i", info.cardNumber, info.cardType);
    // Use the card info...
    [scanViewController dismissViewControllerAnimated:YES completion:nil];
    self.textToSendField.text = [NSString stringWithFormat:@"%@", info.cardNumber];
}



- (IBAction)startPressed:(id)sender
{
    [self.audioPlayer start];
    
    [sender setEnabled:NO];
    [sender setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [sender setAlpha:0.4];
    
    if(!self.audioPlayer.isReceiving)
    {
        //                 FOGBADJIGGIJDABGOFFOGBADJIGGIJDABGOF
        NSArray *nibbleSequence = [Processor encodeString:self.textToSendField.text];
        NSLog(@"Transmitted nibble sequence: %@", nibbleSequence);
        [self.audioPlayer transmitSequence:nibbleSequence];
    }
    
    self.button = sender;
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
    if(textField == self.numberToSend)
    {
        [self.audioPlayer setDataToTransmit:dataToSend.intValue];
        self.stepper.value = dataToSend.doubleValue;
    }
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

- (void) audioReceivedText:(NSString *)text
{
    self.receivedText.text = text;
}

- (void) audioFinishedTransmittingSequence
{
    self.button.enabled = YES;
    self.button.alpha = 1.0;
}

@end
