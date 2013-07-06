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
+ (double) getDistanceSpacing:(NSArray *) packetData
{
    
    NSArray *firstDerivative = differentiate(packetData, 4);
    NSArray *secondDerivative = differentiate(firstDerivative, 4);

    // printf("1st derivative:\n");
    //printArray(firstDerivative);

    NSArray *lowPassedSecondDeriv = doLowPass(multiplyArrayByConstant(secondDerivative, 60.0), kProcessingLowPassFilterConstant);
    lowPassedSecondDeriv = cutoffData(lowPassedSecondDeriv, 5);
    //printArray(lowPassedSecondDeriv);


    // Now we want to find clumps in lowPassedSecondDeriv, and mush them together (see graph)

    NSArray *mergedLowPassedSecondDeriv = mergeGaps(lowPassedSecondDeriv, 8);
    //        printArray(mergedLowPassedSecondDeriv);

    NSArray *clumpIndices = findMidpointsOfClumps(mergedLowPassedSecondDeriv);
    printArray(clumpIndices);
    NSArray *distances = findDistances(clumpIndices);
    distances = [distances sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        if ([obj2 intValue] > [obj1 intValue])
        {
            return NSOrderedAscending;
        }
        else if([obj2 intValue] < [obj1 intValue])
        {
            return NSOrderedDescending;
        }
        else
        {
            return NSOrderedSame;
        }
        
    }];

    printArray(distances);

    NSArray *distanceClumps = clumpData(distances, 8);

    printArray(distanceClumps);

    float distance = [distanceClumps[0] smallest];
    printf("%f", distance);
    return distance;
}
@end
