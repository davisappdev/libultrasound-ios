//
//  ReceiveViewController.h
//  Ultrasound
//
//  Created by AppDev on 7/26/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioPlayer.h"
#import "GraphView.h"

@interface ReceiveViewController : UIViewController <AudioPlayerReceiveDelegate, GraphViewDataSource>

@end
