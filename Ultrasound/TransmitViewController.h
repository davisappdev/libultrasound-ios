//
//  TransmitViewController.h
//  Ultrasound
//
//  Created by AppDev on 7/26/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardIO.h"
#import "AudioPlayer.h"

@interface TransmitViewController : UIViewController <UITextFieldDelegate, CardIOPaymentViewControllerDelegate, AudioPlayerTransmitDelegate>

@end
