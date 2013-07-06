//
//  Clump.m
//  ProcessAlgo
//
//  Created by AppDev on 7/5/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import "Clump.h"

@interface Clump()
@property (nonatomic) NSMutableArray *data;
@end

@implementation Clump

- (NSMutableArray *) data
{
    if (!_data)
    {
        _data = [NSMutableArray array];
    }
    
    return _data;
}

- (double) average
{
    double sum = 0.0;
    for (int i = 0; i < self.data.count; i++)
    {
        sum += [self.data[i] intValue];
    }
    return sum / self.data.count;
}

- (int) smallest
{
    int min = INT_MAX;
    for (int i = 0; i < self.data.count; i++)
    {
        min = MIN([self.data[i] intValue], min);
    }
    return min;
}

- (void) addNumber:(int) dataToAdd
{
    [self.data addObject:@(dataToAdd)];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%f", self.average];
}

@end
