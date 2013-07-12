//
//  ProcessingFunctions.c
//  ProcessAlgo
//
//  Created by AppDev on 7/4/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#include <stdio.h>
#import <Foundation/Foundation.h>
#import "ProcessingFunctions.h"
#import "Clump.h"


void printArrayWithIndices(NSArray *array)
{
    for(int i = 0; i < array.count; i++)
    {
        printf("%d,%f\n", i, [array[i] doubleValue]);
    }
}

NSArray *doLowPass(NSArray *data, double k)
{
    NSMutableArray *lowPassData = [NSMutableArray arrayWithCapacity:data.count];
    double lastValue = [data[0] doubleValue];
    for(int i = 0; i < data.count; i++)
    {
        // val = lastVal * k + currVal * (1-k)
        double currentValue = [data[i] doubleValue];
        double filteredVal = (lastValue * k) + (currentValue * (1 - k));
        [lowPassData addObject:@(filteredVal)];
        lastValue = filteredVal;
    }
    return lowPassData;
}

NSArray *differentiate(NSArray *data, int accuracy)
{
    NSMutableArray *derivative = [NSMutableArray arrayWithCapacity:data.count];
    for(int i = 0; i < data.count; i++)
    {
        double leftVal = 0;
        double rightVal = 0;
        double dx = 0;
        if(i <= accuracy-1)
        {
            leftVal = [data[i] doubleValue];
            rightVal = [data[MIN(i + accuracy, data.count-1)] doubleValue];
            dx = accuracy;
        }
        else if(i >= data.count - accuracy)
        {
            leftVal = [data[i-accuracy] doubleValue];
            rightVal = [data[i] doubleValue];
            dx = accuracy;
        }
        else
        {
            leftVal = [data[i-accuracy] doubleValue];
            rightVal = [data[i+accuracy] doubleValue];
            dx = accuracy * 2;
        }
        
        double dy = rightVal - leftVal;
        [derivative addObject:@(dy/dx)];
    }
    
    return derivative;
}

NSArray *multiplyArrayByConstant(NSArray *data, double k)
{
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:data.count];
    for(int i = 0; i < data.count; i++)
    {
        double val = [data[i] doubleValue];
        [output addObject:@(val * k)];
    }
    return output;
}


int getMinGap(NSArray *data)
{
    int minGap = 1230123;
    int lastSigIndex = 0;

    for (int i = 0; i < data.count; i++)
    {
        if ([data[i] doubleValue] >= kProcessingSecondDerivCutoff)
        {
            if (lastSigIndex > 0)
            {
                int gap = i - lastSigIndex;
                if (gap < minGap) {
                    minGap = gap;
                }
            }
            
            lastSigIndex = i;
        }
    }
    return minGap;
}

NSArray *cutoffData(NSArray *data, double cutoff)
{
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:data.count];
    for(int i = 0; i < data.count; i++)
    {
        double value = [data[i] doubleValue];
        if(fabs(value) < cutoff)
        {
            [output addObject:@NO];
        }
        else
        {
            [output addObject:@YES];
        }
    }
    return output;
}

NSArray *mergeGaps(NSArray *data, int maxWidth)
{
    NSMutableArray *output = [data mutableCopy];
    int distance = 0;
    for (int i = 0; i < output.count; i++)
    {
        BOOL value = [output[i] boolValue];
        if(distance == 0 && value)
        {
            distance = maxWidth;
        }
        else if(distance > 0 && value)
        {
            int mergeAmount = maxWidth - distance;
            for(int j = i - mergeAmount; j < i; j++)
            {
                if(j < 0) continue;
                output[j] = @YES;
            }
            distance = maxWidth;
        }
        else if(!value)
        {
            distance--;
            distance = MAX(0, distance);
        }
    }
    
    return output;
}

NSArray *findMidpointsOfClumps(NSArray *data)
{
    NSMutableArray *midpointIndices = [NSMutableArray array];
    
    int clumpStart = -1;
    BOOL isInClump = NO;
    for (int i = 0; i < data.count; i++)
    {
        BOOL value = [data[i] boolValue];
        if(value && !isInClump)
        {
            clumpStart = i;
            isInClump = YES;
        }
        else if(!value && isInClump)
        {
            int midpoint = (i - 1 + clumpStart) / 2;
            [midpointIndices addObject:@(midpoint)];
            isInClump = NO;
        }
    }
    
    return midpointIndices;
}

NSArray *findDistances(NSArray *data)
{
    if(data.count == 0 || data == nil) return nil;
    
    NSMutableArray *diffArray = [NSMutableArray arrayWithCapacity:data.count];
    [diffArray addObject:data[0]];
    for (int i = 0; i < data.count; i++)
    {
        if (i < data.count - 1)
        {
            int diff = [data[i + 1] intValue] - [data[i] intValue];
            [diffArray addObject:@(diff)];
        }
    }
    return diffArray;
}

NSArray *clumpData(NSArray *data, int tolerance)
{
    NSMutableArray *clumps = [NSMutableArray array];
    for (int i = 0; i < data.count; i++)
    {
        int number = [data[i] intValue];
        double minDiff = DBL_MAX;
        Clump *minDiffClump = nil;
        for (int j = 0; j < clumps.count; j++)
        {
            double diff = fabs(number - [clumps[j] average]);
            if (diff < minDiff)
            {
                minDiff = diff;
                minDiffClump = clumps[j];
            }
        }
        
        if (minDiff <= tolerance)
        {
            [minDiffClump addNumber:number];
        }
        else
        {
            Clump *newClump = [[Clump alloc] init];
            [newClump addNumber:number];
            [clumps addObject:newClump];
        }
    }

    return clumps;
}
void printArray(NSArray *data)
{
    for (int i = 0; i < data.count; i++)
    {
        printf("%s,", [[data[i] description] UTF8String]);
    }
    printf("\n");
}

