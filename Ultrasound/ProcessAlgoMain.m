//
//  ProcessAlgoMain.m
//  Ultrasound
//
//  Created by AppDev on 7/5/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import "ProcessAlgoMain.h"
#import "ProcessingFunctions.h"
#import "Clump.h"
#import "AudioPlayer.h"


#define NSLog(x)
#define printArray(x)
#define printArrayWithIndices(x)

@implementation ProcessAlgoMain
+ (float) getDistanceSpacingFallback:(NSArray *) packetData andDistancesIntoArray:(NSArray **)distances
{
    NSArray *firstDerivative = differentiate(packetData, 2);
    
    NSArray *cutoffFirstDeriv = cutoffData(multiplyArrayByConstant(firstDerivative, 10), 0.5);
    printArrayWithIndices(cutoffFirstDeriv);
    

    NSArray *mergedDeriv = mergeGaps(cutoffFirstDeriv, 4);
//    printArray(mergedLowPassedSecondDeriv);

    NSArray *clumpIndices = findMidpointsOfClumps(mergedDeriv);
    NSLog(@"-------Clump indices-----");
//    printArray(clumpIndices);
    *distances = findDistances(clumpIndices);
    

    NSArray *distanceClumps = clumpData(*distances, 12);
    distanceClumps = [distanceClumps sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        double val1 = [obj1 average];
        double val2 = [obj2 average];
        
        if (val2 > val1)
        {
            return NSOrderedAscending;
        }
        else if(val2 < val1)
        {
            return NSOrderedDescending;
        }
        else
        {
            return NSOrderedSame;
        }
    }];


    printArray(distanceClumps);
    
    double defaultClumpLength = 30.0 * (kTransmitInterval / 0.6);
    if(distanceClumps.count == 0)
    {
        return defaultClumpLength;
    }
    
    // Find the clump whose average is closest to the experimentally determined splitting value of 30
    int closestClump;
    double minDiff = DBL_MAX;
    for (int i = 0; i < distanceClumps.count; i++)
    {
        double average = [distanceClumps[i] average];
        double diff = abs(average - defaultClumpLength);
        if (diff < minDiff)
        {
            minDiff = diff;
            closestClump = i;
        }
    }

    float fallbackDistance = [distanceClumps[closestClump] average];
    
    // Add on the last distance value
    int lastClumpIndex = [[clumpIndices lastObject] intValue];
    int lastDataIndex = packetData.count - 1;
    int lastDistance = lastDataIndex - lastClumpIndex;
    if(lastDistance >= fallbackDistance * 0.5)
    {
        *distances = [*distances arrayByAddingObject:@(lastDistance)];
    }
    NSLog(@"-------Distances-----");
//    printArray(*distances);
    
    //printf("%f", distance);
    return fallbackDistance;
}
@end
