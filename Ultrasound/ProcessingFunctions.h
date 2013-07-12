//
//  ProcessingFunctions.h
//  ProcessAlgo
//
//  Created by AppDev on 7/4/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kProcessingLowPassFilterConstant 0.5
#define kProcessingSecondDerivCutoff 4.0


NSArray *multiplyArrayByConstant(NSArray *data, double k);
int getMinGap(NSArray *data);
NSArray *differentiate(NSArray *data, int accuracy);
NSArray *doLowPass(NSArray *data, double k);
void printArrayWithIndices(NSArray *array);
void printArray(NSArray *array);
NSArray *cutoffData(NSArray *data, double cutoff);
NSArray *mergeGaps(NSArray *data, int maxWidth);
NSArray *findMidpointsOfClumps(NSArray *data);
NSArray *findDistances(NSArray *data);
NSArray *clumpData(NSArray *data, int tolerance);


