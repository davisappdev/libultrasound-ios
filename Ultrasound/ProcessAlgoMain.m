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
    printArrayWithIndices(cutoffFirstDeriv);
    
    

    NSArray *mergedDeriv = mergeGaps(cutoffFirstDeriv, 4);
    //        printArray(mergedLowPassedSecondDeriv);

    NSArray *clumpIndices = findMidpointsOfClumps(mergedDeriv);
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

    float fallbackDistance = [distanceClumps[0] average];
    
    // Add on the last distance value
    int lastClumpIndex = [[clumpIndices lastObject] intValue];
    int lastDataIndex = packetData.count - 1;
    int lastDistance = lastDataIndex - lastClumpIndex;
    if(lastDistance >= fallbackDistance * 0.5)
    {
        *distances = [*distances arrayByAddingObject:@(lastDistance)];
    }
    
    printArray(*distances);
    
    //printf("%f", distance);
    return fallbackDistance;
}
@end
