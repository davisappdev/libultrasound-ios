//
//  Processor.m
//  Ultrasound
//
//  Created by AppDev on 7/3/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import "Processor.h"
#import "ProcessAlgoMain.h"
//#define kNumberLength 25.0

@implementation Processor

+ (void) incrementCountForKey:(id)key inDictionary:(NSMutableDictionary *)dict
{
    NSNumber *count = [dict objectForKey:key];
    if(count)
    {
        [dict setObject:@(count.intValue + 1) forKey:key];
    }
    else
    {
        [dict setObject:@(1) forKey:key];
    }
}


+ (NSArray *) processPacketData:(NSArray *)packetData
{
    NSMutableArray *result = [NSMutableArray array];
    double kNumberLength = [ProcessAlgoMain getDistanceSpacing:packetData];
    int numSections = ceil(packetData.count / kNumberLength);
    
    for(int n = 0; n < numSections; n++)
    {
        NSMutableDictionary *values = [NSMutableDictionary dictionary];
        for(int i = n*kNumberLength; i < n*kNumberLength+kNumberLength; i++)
        {
            if(i >= packetData.count)
            {
                // Use -1 to indicate accessing the array out of bounds.. use this to detect stray data at the end of the array
                [self incrementCountForKey:@(-1) inDictionary:values];
                continue;
            }
            
            NSNumber *value = packetData[i];
            [self incrementCountForKey:value inDictionary:values];
        }
        
        
        int maxCount = 0;
        int mode = 0;
        for(NSNumber *value in values.allKeys)
        {
            int count = [[values objectForKey:value] intValue];
            if(count > maxCount)
            {
                maxCount = count;
                mode = [value intValue];
            }
        }
        
        if(mode !=-1)
        {
            [result addObject:@(mode)];
        }
    }
    
    return [result copy];
}


// Fun debug encoding
+ (NSArray *) encodeString:(NSString *)string
{
    NSMutableArray *data = [NSMutableArray array];
    for(int i = 0; i < string.length; i++)
    {
        unichar c = [string characterAtIndex:i];
        [data addObject:@(c-'A')];
    }
    return [data copy];
}

+ (NSString *) decodeData:(NSArray *)data
{
    NSMutableString *string = [NSMutableString string];
    for(int i = 0; i < data.count; i++)
    {
        unichar c = 'A' + [data[i] intValue];
        [string appendFormat:@"%c", c];
    }
    
    return [string copy];
}

@end
