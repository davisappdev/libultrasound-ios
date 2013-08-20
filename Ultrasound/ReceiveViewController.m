//
//  ReceiveViewController.m
//  Ultrasound
//
//  Created by AppDev on 7/26/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import "ReceiveViewController.h"
#import "AudioManager.h"
#import "UIView+Donald.h"
#import "Processor.h"
#import "NSArray+Levenshtein.h"

@interface ReceiveViewController ()
@property (nonatomic, strong) AudioPlayer *player;
@property (weak, nonatomic) IBOutlet UILabel *receivedStringLabel;
@property (weak, nonatomic) IBOutlet GraphView *graphView;
@property (nonatomic) float *copiedFFTData;
@property (nonatomic) float copiedCutoff;
@property (nonatomic) NSString *testString;
@end

@implementation ReceiveViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.player = [AudioPlayer sharedAudioPlayer];
    self.player.receiveDelegate = self;

//    [self.containerView applyStandardSinkStyle];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.player.isReceiving = YES;
    [self.player start];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.player stop];
    self.player.isReceiving = NO;
}

- (void) audioReceivedDataUpdate:(int)data
{
    
}

- (void) audioReceivedText:(NSString *)text
{
    if (text == nil)
    {
        self.receivedStringLabel.text = @"nil";
    }
    else
    {
        self.receivedStringLabel.text = text;
        // Nibbles we received
//        NSLog(@"Received: %@\n\nShould have received: %@", nibbles, correctNibbles);
        
    }
}

- (void) audioReceivedFFTData:(float *)data arraySize:(int)size cutoff:(float)cutoff
{
    /*if(self.copiedFFTData != NULL)
    {
        free(self.copiedFFTData);
    }
    
    self.copiedFFTData = malloc(sizeof(float) * size);
    memcpy(self.copiedFFTData, data, sizeof(float) * size);
    
    self.copiedCutoff = cutoff;
    
    [self.graphView generateBitmapAndRedraw];*/
}



#pragma mark - Graph Stuff

- (void) setGraphView:(GraphView *)graphView
{
    _graphView = graphView;
    //_graphView.dataSource = self;
    
    [_graphView setupInitialTransforms];
    
    [_graphView applyStandardSinkStyleNoRounding];
}

- (double) valueForXCoord:(double)x withIndex:(int)graphIndex graphView:(GraphView *)view
{
    if(graphIndex == 0)
    {
        if(self.copiedFFTData == NULL || x >= 22000)
        {
            return 0;
        }
        
        int index = round(x / kRatio);
        return self.copiedFFTData[index];
    }
    else
    {
        return self.copiedCutoff;
    }
}


@end
