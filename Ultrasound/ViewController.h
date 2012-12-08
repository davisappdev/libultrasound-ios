//
//  ViewController.h
//  Ultrasound
//
//  Created by AppDev on 9/28/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioPlayer.h"

@interface ViewController : UIViewController <AudioPlayerDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *receivedData;
@property (weak, nonatomic) IBOutlet UITextField *numberToSend;

@end