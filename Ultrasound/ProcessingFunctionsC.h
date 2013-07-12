//
//  ProcessingFunctionsC.h
//  Ultrasound
//
//  Created by AppDev on 7/10/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#ifndef Ultrasound_ProcessingFunctionsC_h
#define Ultrasound_ProcessingFunctionsC_h

// Basic statistics
double maxValueForArray(float *array, int start, int end);
double meanOfArray(float *array, int start, int end);
double standardDeviation(float *array, int start, int end, double mean);
double meanlessStandardDeviation(float *array, int start, int end);

#endif
