//
//  ProcessAlgoMain.h
//  Ultrasound
//
//  Created by AppDev on 7/5/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProcessAlgoMain : NSObject

+ (float) getDistanceSpacingFallback:(NSArray *) packetData andDistancesIntoArray:(NSArray **)distances;

@end
