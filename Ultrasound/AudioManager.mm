//
//  AudioManager.m
//  Ultrasound
//
//  Created by AppDev on 9/28/12.
//  Copyright (c) 2012 AppDev. All rights reserved.
//

#import "AudioManager.h"
#import <AudioToolbox/AudioToolbox.h>
#include "CAStreamBasicDescription.h"
#include "audio_helper.h"
#include "FFTBufferManager.h"

@implementation AudioManager
{
    AudioUnit toneUnit;
    AURenderCallbackStruct inputProc;
    CAStreamBasicDescription thruFormat;
    FFTBufferManager *fft;
    int32_t *fftData;

}

const double kSampleRate = 44100;

static AudioManager *globalSelf;


void SilenceData(AudioBufferList *inData)
{
	for (UInt32 i=0; i < inData->mNumberBuffers; i++)
		memset(inData->mBuffers[i].mData, 0, inData->mBuffers[i].mDataByteSize);
}



OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags 	*ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData)

{
    if(globalSelf.isReceiving)
    {
        AudioUnitRender(globalSelf->toneUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    
        SInt8 *data_ptr = (SInt8 *)(ioData->mBuffers[0].mData);        
        if (globalSelf->fft == NULL)
        {
            return noErr;
        }
        if (globalSelf->fft->NeedsNewAudioData())
        {
            globalSelf->fft->GrabAudioData(ioData);
        }
    }
    else
    {
        Float32 *ptr = (Float32 *)(ioData->mBuffers[0].mData);

        [globalSelf.delegate renderAudioIntoData:ptr withSampleRate:kSampleRate numberOfFrames:inNumberFrames];
    }
    //SilenceData(ioData);
    return noErr;
}


void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
	[globalSelf stopAudio];
}


int SetupRemoteIO (AudioUnit& inRemoteIOUnit, AURenderCallbackStruct inRenderProc, CAStreamBasicDescription& outFormat)
{
		// Open the output unit
		AudioComponentDescription desc;
		desc.componentType = kAudioUnitType_Output;
		desc.componentSubType = kAudioUnitSubType_RemoteIO;
		desc.componentManufacturer = kAudioUnitManufacturer_Apple;
		desc.componentFlags = 0;
		desc.componentFlagsMask = 0;
		
		AudioComponent comp = AudioComponentFindNext(NULL, &desc);
		
		AudioComponentInstanceNew(comp, &inRemoteIOUnit);
        
		UInt32 one = 1;
		AudioUnitSetProperty(inRemoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
		AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &inRenderProc, sizeof(inRenderProc));
		
        //set our required format - Canonical AU format: LPCM non-interleaved 8.24 fixed point
        outFormat.SetAUCanonical(2, false);
        outFormat.mSampleRate = kSampleRate;
        //AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outFormat, sizeof(outFormat));
        AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &outFormat, sizeof(outFormat));

    
		AudioUnitInitialize(inRemoteIOUnit);
	
	return 0;
}



- (void) toggleAudio
{
	if (toneUnit)
	{
		[self stopAudio];
	}
	else
	{
		[self startAudio];
	}
}


- (void) stopAudio
{
    AudioOutputUnitStop(toneUnit);
    AudioUnitUninitialize(toneUnit);
    AudioComponentInstanceDispose(toneUnit);
    toneUnit = nil;
}


- (void) startAudio
{
    Float32 preferredBufferSize = .005;
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
    
    
	inputProc.inputProc = RenderTone;
	inputProc.inputProcRefCon = (__bridge void *)(self);
    
    SetupRemoteIO(toneUnit, inputProc, thruFormat);
    
    
    
    UInt32 maxFPS;
    UInt32 size = sizeof(maxFPS);
    AudioUnitGetProperty(toneUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size);
    fft = new FFTBufferManager(maxFPS);
    
    fftData = new int32_t[maxFPS / 2];
    fourierSize = maxFPS / 2;
    
    // Start playback
    AudioOutputUnitStart(toneUnit);
}

int fourierSize;
- (id) initWithDelegate:(id<AudioManagerDelegate>)delegate
{
    self = [super init];
    
    if(self)
    {
        self.delegate = delegate;
        
        globalSelf = self;
        
        OSStatus result = AudioSessionInitialize(NULL, NULL, ToneInterruptionListener, (__bridge void *)(self));
        if (result == kAudioSessionNoError)
        {
            UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
        }
        AudioSessionSetActive(true);
        
    }
    return self;
}


- (id) init
{
    return [self initWithDelegate:nil];
}


#define CLAMP(min,x,max) (x < min ? min : (x > max ? max : x))
//#define kRatio 21.5542521994135      //21.533203125
#define kRatio (21.533203125)       //21.533203125
//#define kRatio 21.5437276622068

void printFFT(int *fftData, int len)
{
    for(int i = 0; i < len; i++)
    {
        printf("%d, ", fftData[i]);
    }
    printf("\n");
}


- (NSArray *) fourier:(NSArray *) requestedFrequencies
{
    fft->ComputeFFT(fftData);
    
    int y, maxY;
    maxY = 1024;
    
    //printFFT(fftData, 1024);
   

    NSMutableArray *storedFFTData = [NSMutableArray array];
    for (y = 0; y < maxY; y++)
    {
        CGFloat yFract = (CGFloat) y / (CGFloat)(maxY - 1);
        CGFloat fftIdx = yFract * ((CGFloat) fourierSize);
        
        double fftIdx_i, fftIdx_f;
        fftIdx_f = modf(fftIdx, &fftIdx_i);
        
        SInt8 fft_l, fft_r;
        CGFloat fft_l_fl, fft_r_fl;
        CGFloat interpVal;
        
        fft_l = (fftData[(int)fftIdx_i] & 0xFF000000) >> 24;
        fft_r = (fftData[(int)fftIdx_i + 1] & 0xFF000000) >> 24;
        fft_l_fl = (CGFloat)(fft_l + 80) / 64.;
        fft_r_fl = (CGFloat)(fft_r + 80) / 64.;
        interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
        
        interpVal = CLAMP(0., interpVal, 1.);
        interpVal *= 120;
        
        //float frequency = y * kRatio;
        [storedFFTData addObject:@(interpVal)];
        
        
        
        //drawBuffers[0][y] = (interpVal * 120);
        //printf("(%f, %f)  ", , interpVal * 120);
        //printf("(%i, %g)  ", y, interpVal);
    }
    [storedFFTData removeLastObject];
    
    
    
    
    int minIndex = round([requestedFrequencies[0] intValue] / kRatio) - 20;
    int maxIndex = round([[requestedFrequencies lastObject] intValue] / kRatio) + 20;
    
    for(int i = minIndex; i <= maxIndex; i++)
    {
        printf("%d,%f\n", i - minIndex, [storedFFTData[i] floatValue]);
    }
    
    double mean = [self meanOfArray:storedFFTData startIndex:minIndex endIndex:maxIndex];
    double standardDeviation = [self standardDeviation:storedFFTData startIndex:minIndex endIndex:maxIndex mean:mean];
    double maxValue = [self maxValueForArray:storedFFTData startIndex:minIndex endIndex:maxIndex];
    double cutoffValue = maxValue - (standardDeviation * 2);
    
    printf("Mean: %f\n", mean);
    printf("STD: %f\n", standardDeviation);
    printf("Cutoff Value: %f\n", cutoffValue);
    
    
    NSMutableArray *outputFrequencies = [NSMutableArray array];
   
    
    for(int i = 0; i < requestedFrequencies.count; i++)
    {
        int index = round([requestedFrequencies[i] intValue] / kRatio);
        NSLog(@"Index: %i", index-minIndex);
        
        // Calculate the difference neighboring frequency indices.
        int dIndexUp = (i == requestedFrequencies.count-1) ? (index - round([requestedFrequencies[i-1] intValue] / kRatio)) : (round([requestedFrequencies[i+1] intValue] / kRatio) - index);
        int dIndexDown = (i == 0) ? (round([requestedFrequencies[i+1] intValue] / kRatio) - index) : (index - round([requestedFrequencies[i-1] intValue] / kRatio));
//        printf("%d\n----------\n", dIndex);
        
        int upAmt = ceilf(dIndexUp / 2.0f) - 1;
        int downAmt = ceilf(dIndexDown / 2.0f) - 1;
        
        double val = 0;
        for(int j = index; j <= index + upAmt; j++)
        {
            double a = [storedFFTData[j] floatValue];
            val = MAX(val, a);
        }
        for(int j = index; j >= index - downAmt; j--)
        {
            double a = [storedFFTData[j] floatValue];
            val = MAX(val, a);
        }
        
        
        //val += val * i * kAmplitudeAdjust;
        
        printf("%g  ", val);
        //printf("%g  ", ratio);
        
        if(standardDeviation < 0.5)
        {
            [outputFrequencies addObject:@(NO)];
        }
        //else if(val >= minimumValue)
        else if(val > cutoffValue)
        {
            //printf("Value: %f\n", MAX(MAX(val1, val2), MAX(val2, val3)));
            [outputFrequencies addObject:@(YES)];
        }
        else
        {
            [outputFrequencies addObject:@(NO)];
        }
    }
    
    printf("\n");

    return [outputFrequencies copy];
}


- (double) maxValueForArray:(NSArray *) array startIndex:(int)start endIndex:(int) end
{
    start = MAX(0, start);
    end = MIN(array.count-1, end);
    
    double maxValue = 0;
    for (int i = start; i <= end; i++)
    {
        maxValue = MAX(maxValue, [array[i] doubleValue]);
    }
    
    return maxValue;
}
- (double) meanOfArray:(NSArray *) array startIndex:(int)start endIndex:(int) end
{
    start = MAX(0, start);
    end = MIN(array.count-1, end);
    
    double sum = 0;
    for (int i = start; i <= end; i++) {
        sum += [array[i] doubleValue];
    }
    return sum / (end - start + 1);
}

- (double) standardDeviation:(NSArray *) array startIndex:(int) start endIndex:(int) end mean: (double) mean
{
    start = MAX(0, start);
    end = MIN(array.count-1, end);
    
    double totalDiff = 0.0;
    for (int i = start; i <= end; i++)
    {
        double diff = [array[i] doubleValue] - mean;
        diff *= diff;
        totalDiff += diff;
    }
    
    double standarDeviation = sqrt(totalDiff / (end - start + 1));
    return standarDeviation;
}
- (double) meanlessStandardDeviation:(NSArray *) array startIndex:(int) start endIndex:(int) end
{
    double mean;
    double sum = 0;
    
    for (int i = start; i <= end; i++) {
        sum += [array[i] doubleValue];
    }
   
    mean = sum / (end - start + 1);
   
    double totalDiff = 0.0;
    for (int i = start; i <= end; i++)
    {
        double diff = [array[i] doubleValue] - mean;
        diff *= diff;
        totalDiff += diff;
    }
    
    double standarDeviation = sqrt(totalDiff / (end - start + 1));
    return standarDeviation;

}

@end
