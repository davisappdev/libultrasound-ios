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


@implementation ProcessAlgoMain
+ (float) getDistanceSpacingFallback:(NSArray *) packetData andDistancesIntoArray:(NSArray **)distances
{
    NSArray *firstDerivative = differentiate(packetData, 4);
    
    NSArray *cutoffFirstDeriv = cutoffData(multiplyArrayByConstant(firstDerivative, 10), 0.5);
//    printArrayWithIndices(cutoffFirstDeriv);
    

    NSArray *mergedDeriv = mergeGaps(cutoffFirstDeriv, 4);
    //        printArray(mergedLowPassedSecondDeriv);

    NSArray *clumpIndices = findMidpointsOfClumps(mergedDeriv);
    NSLog(@"-------Clump indices-----");
    printArray(clumpIndices);
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
    
    if(distanceClumps.count == 0)
    {
        return 30;
    }
    
    // Find the clump whose average is closest to the experimentally determined splitting value of 30
    int closestClump;
    double minDiff = DBL_MAX;
    for (int i = 0; i < distanceClumps.count; i++)
    {
        double average = [distanceClumps[i] average];
        double diff = abs(average - 30.0);
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
    printArray(*distances);
    
    //printf("%f", distance);
    return fallbackDistance;
}
@end
