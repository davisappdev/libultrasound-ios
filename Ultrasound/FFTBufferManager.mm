//
//  FFTBufferManager.m
//  Ultrasound
//
//  Created by AppDev on 7/25/13.
//  Copyright (c) 2013 AppDev. All rights reserved.
//

#import "FFTBufferManager.h"
#import "FFTAccelerate.h"

@implementation FFTBufferManager
{
    int index;
    int size;
    int *buffer;
    
    FFTAccelerate *accel;
}

- (instancetype) initWithSize:(int)s
{
    if(self = [super init])
    {
        size = s;
        buffer = (int *)malloc(size * sizeof(int));
        accel = new FFTAccelerate(s);
    }
    return self;
}

- (void) addFrames:(AudioBufferList *)bl
{
	UInt32 bytesToCopy = MIN(bl->mBuffers[0].mDataByteSize, (size - index) * sizeof(int));
	memcpy(buffer+index, bl->mBuffers[0].mData, bytesToCopy);
	
	index += bytesToCopy / sizeof(int);
	if (index >= size)
	{
		// Audio data is full, can now process data...
        printf("Processing data!!!");
        float *normalized = (float *)malloc(size * sizeof(float));
        for (int i = 0; i < size; i++)
        {
            normalized[i] = buffer[i] / INT32_MAX;
        }
        
        float *tmp = (float *)malloc(size * sizeof(float));
        accel->doFFTReal(normalized, tmp, size);

        for (int i = 0; i < size; i++)
        {
            printf("%d,%f\n", i, tmp[i]);
        }
        
        printf("Done processing data!!!");
        
	}
}

- (void) doFFT:(int **)result
{

}

@end
