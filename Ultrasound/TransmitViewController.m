//
//  TransmitViewController.m
//  Ultrasound
//
//  Created by AppDev on 7/26/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import "TransmitViewController.h"
#import "Processor.h"

@interface TransmitViewController ()
@property (nonatomic, strong) AudioPlayer *player;
@end

@implementation TransmitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.player = [AudioPlayer sharedAudioPlayer];
    self.player.isReceiving = NO;
    self.player.transmitDelegate = self;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.player.isReceiving = NO;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.player stop];
    self.player.isReceiving = YES;
}

- (void) audioStartedTransmittingSequence
{
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    self.tabBarController.tabBar.tintColor = [UIColor grayColor];
}

- (void) audioFinishedTransmittingSequence
{
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    self.tabBarController.tabBar.tintColor = self.view.tintColor;
}

#pragma mark - Text Field Methods
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
    [self.player start];
    [self.player transmitString:textField.text];
}


#pragma mark - Card.io Methods
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
    [scanViewController dismissViewControllerAnimated:YES completion:^{
        [self.player transmitString:info.cardNumber];
    }];
}


@end
