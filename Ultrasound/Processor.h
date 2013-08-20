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

+ (NSArray *) splitByteArrayIntoNibbleArray:(NSArray *)bytes;
+ (NSArray *) combineNibbleArrayToByteArray:(NSArray *)nibbles;


// String encoding
+ (NSArray *) encodeString:(NSString *)string;
+ (NSArray *) encodeStringAndEncrypt:(NSString *)string withKey:(NSString *) key;
+ (NSString *) decodeDataAndDecrypt:(NSArray *)data withKey:(NSString *) key;
+ (NSString *) decodeData:(NSArray *)data;

@end
