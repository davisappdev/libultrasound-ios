//
//  TransmitViewController.m
//  Ultrasound
//
//  Created by AppDev on 7/26/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import "TransmitViewController.h"
#import "Processor.h"
#import "UIView+Donald.h"
#import "ProcessAlgoMain.h"
#import "NSArray+Levenshtein.h"
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

@interface TransmitViewController ()
@property (nonatomic, strong) AudioPlayer *player;
@property (weak, nonatomic) IBOutlet GraphView *graphView;
@property (nonatomic) float *oldTransmittingFrequencies;
@property (nonatomic) float *currentlyTransmittingFrequencies;
@property (weak, nonatomic) IBOutlet UITextField *dataToTransmitField;
@property (nonatomic, strong) NSTimer *phaseShiftTimer;
@property (nonatomic) NSString *testString;
@property (nonatomic) int testTransmissionIndex;
@property (nonatomic) int repeatCount;
@end


#define kCarrierWaveAttenuation 0.2
@implementation TransmitViewController

BOOL programChangesVolume = NO;
- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.player = [AudioPlayer sharedAudioPlayer];
    self.player.isReceiving = NO;
    self.player.transmitDelegate = self;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Test Strings" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    self.testString = dict[@"transmitString"];
    self.repeatCount = [dict[@"repeatCount"] intValue];
    
    NSLog(@"Test repeat count: %d", self.repeatCount);
    NSLog(@"Test nibbles: %@", [Processor encodeString:self.testString]);
    self.dataToTransmitField.text = self.testString;
    
    MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(2000, 200, 400, 44)];
    //[self.view addSubview:myVolumeView];
    
    programChangesVolume = YES;
    [MPMusicPlayerController applicationMusicPlayer].volume = kCarrierWaveAttenuation;
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}


- (void)volumeChanged:(NSNotification *)notification
{
    if(programChangesVolume)
    {
        programChangesVolume = NO;
    }
    else
    {
        programChangesVolume = YES;
        [MPMusicPlayerController applicationMusicPlayer].volume = kCarrierWaveAttenuation;
    }
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

- (void) audioFinishedTransmittingSequence
{
    self.tabBarController.tabBar.userInteractionEnabled = YES;
//    self.tabBarController.tabBar.tintColor = self.view.tintColor;
    
    [self.phaseShiftTimer invalidate];
    

    if(self.testTransmissionIndex < self.repeatCount - 1)
    {
        self.testTransmissionIndex++;
        [self.player transmitString:self.testString];
        NSLog(@"Transmit count: %d", self.testTransmissionIndex);
    }
    else
    {
        self.testTransmissionIndex = 0;
        NSLog(@"Stopping transmission@");
        [self.player stop];
        
        NSString *soundPath =  [[NSBundle mainBundle] pathForResource:@"ding" ofType:@"wav"];
        SystemSoundID soundID;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
        AudioServicesPlaySystemSound (soundID);
    }
}
- (void) audioStartedTransmittingSequence: (float *) freqs withSize: (int) size
{
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    self.tabBarController.tabBar.tintColor = [UIColor grayColor];
    
    /*self.phaseShiftTimer = [NSTimer timerWithTimeInterval:0.0333 target:self selector:@selector(phaseShift:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.phaseShiftTimer forMode:NSRunLoopCommonModes];
    [self.phaseShiftTimer fire];*/
}
- (void) audioStartedTransmittingFrequencies:(float *)freqs withSize:(int)size
{
    /*if(self.currentlyTransmittingFrequencies != NULL)
    {
        if(self.oldTransmittingFrequencies != NULL)
        {
            free(self.oldTransmittingFrequencies);
        }
        self.oldTransmittingFrequencies = malloc(sizeof(float) * size);
        
        memcpy(self.oldTransmittingFrequencies, self.currentlyTransmittingFrequencies, sizeof(float) * size);
        free(self.currentlyTransmittingFrequencies);
    }
    
    self.currentlyTransmittingFrequencies = malloc(sizeof(float) * size);
    memcpy(self.currentlyTransmittingFrequencies, freqs, sizeof(float) * size);
    [self.graphView generateBitmapAndRedraw];
    
    justUpdated = YES;*/
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
        self.dataToTransmitField.text = info.cardNumber;
    }];
}

- (void) setGraphView:(GraphView *)graphView
{
    _graphView = graphView;
    //_graphView.dataSource = self;
    
    [_graphView setupInitialTransforms];
    _graphView.minRedrawInterval = 0.03;
    [_graphView applyStandardSinkStyleNoRounding];
}

/*float t = 0;
- (double) valueForXCoord:(double)x withIndex:(int)graphIndex graphView:(GraphView *)view
{
    if (!self.oldTransmittingFrequencies || !self.currentlyTransmittingFrequencies)
    {
        return 0;
    }
    
    float timeSinceUpdate = CACurrentMediaTime() - lastUpdateT;
    float progress = MIN(timeSinceUpdate / kTransmitInterval, 1.0);
    double time = 2.0 * M_PI * (x + t);
    float sum = 0;
    for (int i = 0; i < kNumberOfTransmitFrequencies; i++)
    {
        float oldFreq = self.oldTransmittingFrequencies != NULL ? self.oldTransmittingFrequencies[i] : self.currentlyTransmittingFrequencies[i];
        float newFreq = self.currentlyTransmittingFrequencies[i];
        float val = sin(time * oldFreq) * (1 - progress) + sin(time * newFreq) * progress;

        sum += val;
    }
    
    return sum;
}*/

/*float lastUpdateT = 0;
BOOL justUpdated = NO;
- (void) phaseShift:(NSTimer *)timer
{
    t += 0.00001;
    
    if(justUpdated)
    {
        justUpdated = NO;
        lastUpdateT = CACurrentMediaTime();
    }
    
    [self.graphView generateBitmapAndRedraw];
}*/

@end
