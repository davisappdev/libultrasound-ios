//
//  ReceiveViewController.m
//  Ultrasound
//
//  Created by AppDev on 7/26/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import "ReceiveViewController.h"

@interface ReceiveViewController ()
@property (nonatomic, strong) AudioPlayer *player;
@property (weak, nonatomic) IBOutlet UILabel *receivedStringLabel;
@property (weak, nonatomic) IBOutlet GraphView *graphView;
@end

@implementation ReceiveViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.player = [AudioPlayer sharedAudioPlayer];
    self.player.receiveDelegate = self;
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
    self.receivedStringLabel.text = text;
}



#pragma mark - Graph Stuff

- (void) setGraphView:(GraphView *)graphView
{
    _graphView = graphView;
    _graphView.dataSource = self;
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:_graphView action:@selector(handlePinch:)];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:_graphView action:@selector(handlePan:)];
    pan.maximumNumberOfTouches = 1;
    pan.minimumNumberOfTouches = 1;
    
    
    [_graphView addGestureRecognizer:pinch];
    [_graphView addGestureRecognizer:pan];
    
    [_graphView setupInitialTransforms];
}

- (double) valueForXCoord:(double)x withIndex:(int)index graphView:(GraphView *)view
{
    return 2;
}


@end
