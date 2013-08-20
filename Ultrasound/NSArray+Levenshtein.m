//
//  NSArray+Levenshtein.m
//  Ultrasound
//
//  Created by AppDev on 8/2/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import "NSArray+Levenshtein.h"
#import "NSString+Levenshtein.h"

@implementation NSArray (Levenshtein)
- (NSUInteger)levenshteinDistanceToArray:(NSArray *)array
{
    NSString *selfString = [self arrayToString:self];
    NSString *otherString = [self arrayToString:array];
    
    return [selfString levenshteinDistanceToString:otherString];
}

- (double)percentErrorToReceivedArray:(NSArray *)array
{
    int wc = 0;
    for(int i = 0; i < self.count; i++)
    {
        if(i >= array.count)
        {
            wc++;
        }
        else if([self[i] intValue] != [array[i] intValue])
        {
            wc++;
        }
    }
    wc += MAX((int)array.count - (int)self.count, 0);
    
    return (double)wc / self.count;
}

- (NSString *) arrayToString:(NSArray *)array
{
    NSMutableString *string = [NSMutableString stringWithCapacity:array.count];
    
    for (NSNumber *num in array)
    {
        [string appendFormat:@"%d", num.intValue];
    }
    return string;
}
@end
