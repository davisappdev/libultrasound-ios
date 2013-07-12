//
//  ProcessingFunctionsC.c
//  Ultrasound
//
//  Created by AppDev on 7/10/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#include <stdio.h>
#include <math.h>
#include "ProcessingFunctionsC.h"

// Basic statistics
double maxValueForArray(float *array, int start, int end)
{
//    start = MAX(0, start);
    
    double maxValue = 0;
    for (int i = start; i <= end; i++)
    {
        double val = array[i];
        if(val > maxValue)
        {
            maxValue = val;
        }
    }
    
    return maxValue;
}

double meanOfArray(float *array, int start, int end)
{
//    start = MAX(0, start);
    
    double sum = 0;
    for (int i = start; i <= end; i++) {
        sum += array[i];
    }
    return sum / (end - start + 1);
}

double standardDeviation(float *array, int start, int end, double mean)
{
//    start = MAX(0, start);
    
    double totalDiff = 0.0;
    for (int i = start; i <= end; i++)
    {
        double diff = array[i] - mean;
        diff *= diff;
        totalDiff += diff;
    }
    
    float standardDeviation = sqrt((float)(totalDiff / (end - start + 1)));
    return standardDeviation;
}

double meanlessStandardDeviation(float *array, int start, int end)
{
    return standardDeviation(array, start, end, meanOfArray(array, start, end));
}
