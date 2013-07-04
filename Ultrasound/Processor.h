//
//  Processor.h
//  Ultrasound
//
//  Created by AppDev on 7/3/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Processor : NSObject

+ (NSArray *) processPacketData:(NSArray *)packetData;


// Fun debug encoding
+ (NSArray *) encodeString:(NSString *)string;
+ (NSString *) decodeData:(NSArray *)data;

@end
