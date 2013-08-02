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
#include "ProcessingFunctionsC.h"

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
   
//    SilenceData(ioData);
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
float delimCutoff;
- (id) initWithDelegate:(id<AudioManagerDelegate>)delegate
{
    self = [super init];
    
    if(self)
    {
        self.delegate = delegate;
        
        globalSelf = self;
        delimCutoff = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ? 25 : 80;
        
        OSStatus result = AudioSessionInitialize(NULL, NULL, ToneInterruptionListener, (__bridge void *)(self));
        if (result == kAudioSessionNoError)
        {
            UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
            UInt32 one = 1;
            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
            AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(one), &one);
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

void printFFT(float *fftData)
{
    for(int i = 0; i < 1024; i++)
    {
        printf("%d,%f\n", i, fftData[i]);
    }
    printf("\n");
}


BOOL shouldPrintNormal = NO;
BOOL shouldPrintInterp = NO;
void printFFTStuff(int32_t *fftData)
{
    int maxY = 1024;
    for (int y = 0; y < maxY - 1; y++)
    {
        CGFloat yFract = (CGFloat) y / (CGFloat)(maxY - 1);
        CGFloat fftIdx = yFract * ((CGFloat) fourierSize);
        
        double fftIdx_i, fftIdx_f;
        fftIdx_f = modf(fftIdx, &fftIdx_i);
        
        SInt8 fft_l, fft_r;
        CGFloat fft_l_fl, fft_r_fl;
        CGFloat interpVal;
        fft_l = (fftData[(int)fftIdx_i] & 0xFF000000) >> 24;
        if(shouldPrintNormal)
        {
            printf("%d,%d\n", y, fft_l);
        }
        fft_r = (fftData[(int)fftIdx_i + 1] & 0xFF000000) >> 24;
        fft_l_fl = (CGFloat)(fft_l + 80) / 64.;
        fft_r_fl = (CGFloat)(fft_r + 80) / 64.;
        interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
        
        interpVal = CLAMP(0., interpVal, 1.);
        interpVal *= 120;
        
        if(shouldPrintInterp)
        {
            printf("%d,%f\n", y, interpVal);
        }
        
    }
}





- (NSArray *) fourier:(NSArray *) requestedFrequencies
{
    fft->ComputeFFT(fftData);
    
    int y, maxY;
    maxY = 1024;
    
    printFFTStuff(fftData);

    float *storedFFTData = (float *)malloc(sizeof(float) * (maxY-1));
    for (y = 0; y < maxY - 1; y++)
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
        
        storedFFTData[y] = interpVal;
    }
    
    
    
    int minIndex = round([requestedFrequencies[0] intValue] / kRatio) - 20;
    int maxIndex = round([[requestedFrequencies lastObject] intValue] / kRatio) + 20;
    int delimIndex = round(kPacketDelimiterFrequency / kRatio);
    
    for(int i = minIndex; i <= maxIndex; i++)
    {
//       printf("%d,%f\n", i - minIndex, storedFFTData[i]);
    }
    
    double delimValue = 0;
    int delimUp = 3;
    int delimDown = 3;
    for(int j = delimIndex; j <= delimIndex + delimUp; j++)
    {
        double a = storedFFTData[j];
        delimValue = MAX(delimValue, a);
    }
    for(int j = delimIndex; j >= delimIndex - delimDown; j--)
    {
        double a = storedFFTData[j];
        delimValue = MAX(delimValue, a);
    }
    
//    double averageValueInUltraSonicRange = meanOfArray(storedFFTData, 0, maxY - 1);
    
    minIndex = MAX(0, minIndex);
    maxIndex = MIN(maxIndex, maxY-2);
    double standardDeviation = meanlessStandardDeviation(storedFFTData, minIndex, maxIndex);
    double maxValue = maxValueForArray(storedFFTData, minIndex, maxIndex);
    double cutoffValue = maxValue - (standardDeviation * 3);
    cutoffValue = MIN(cutoffValue, 40);
    
    [self.delegate fftData:storedFFTData arraySize:maxY-1 cutoff:cutoffValue];
    
//    printf("AVG: %f\n", averageValueInUltraSonicRange);
//    printf("Cutoff Value: %f\n", cutoffValue);
    
    
    NSMutableArray *outputFrequencies = [NSMutableArray array];
    
    BOOL allBitsOff = YES;
    for(int i = 0; i < requestedFrequencies.count; i++)
    {
        int index = round([requestedFrequencies[i] intValue] / kRatio);
        //NSLog(@"Index: %i", index-minIndex);
        
        // Calculate the difference neighboring frequency indices.
        int dIndexUp = (i == requestedFrequencies.count - 1) ? (index - round([requestedFrequencies[i - 1] intValue] / kRatio)) : (round([requestedFrequencies[i + 1] intValue] / kRatio) - index);
        int dIndexDown = (i == 0) ? (round([requestedFrequencies[i+1] intValue] / kRatio) - index) : (index - round([requestedFrequencies[i-1] intValue] / kRatio));
        
        int upAmt = MAX(ceilf(dIndexUp / 4.0f) - 1, 2);
        int downAmt = MAX(ceilf(dIndexDown / 4.0f) - 1, 2);
        
        
        double val = 0;
        for(int j = index; j <= index + upAmt; j++)
        {
            double a = storedFFTData[j];
            val = MAX(val, a);
        }
        for(int j = index; j >= index - downAmt; j--)
        {
            double a = storedFFTData[j];
            val = MAX(val, a);
        }
        
//        printf("%f\n", val);
        
        if(standardDeviation < 0.5)
        {
            [outputFrequencies addObject:@(NO)];
        }
        else if(val > cutoffValue)
        {
            [outputFrequencies addObject:@(YES)];
            allBitsOff = NO;
        }
        else
        {
            [outputFrequencies addObject:@(NO)];
        }
    }
    
//    printf("%f\n", delimValue);
    if(delimValue > delimCutoff && fabs(delimValue - 120) > DBL_EPSILON)
    {
//        printf("DELIMITER DETECTED\n\n");
        return nil; // Returning nil indicates that the delimiter was detected
    }
    else
    {
//        printf("NO DELIMITER\n\n");
    }
    
    
    //printf("\n");
    free(storedFFTData);
    return [outputFrequencies copy];
}

@end
