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




OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags 	*ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData)

{
    AudioUnitRender(globalSelf->toneUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    
    SInt8 *data_ptr = (SInt8 *)(ioData->mBuffers[0].mData);
    for (int i=0; i<inNumberFrames; i++)
    {
        //printf("%i\n", data_ptr[2]);
        data_ptr += 4;
    }
    
    if (globalSelf->fft == NULL)
    {
        return noErr;
    }
    
    if (globalSelf->fft->NeedsNewAudioData())
    {
        globalSelf->fft->GrabAudioData(ioData);
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
        outFormat.mSampleRate = 44100;
        AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outFormat, sizeof(outFormat));
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
    
    
    [self performSelector:@selector(fourier) withObject:nil afterDelay:2.0];

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
#define kRatio 21.4634
- (void) fourier
{
    fft->ComputeFFT(fftData);
    
    int y, maxY;
    maxY = 1024;
    float maxValue = 0.0f;
    int maxIndex = 0;
    for (y=0; y<maxY; y++)
    {
        CGFloat yFract = (CGFloat)y / (CGFloat)(maxY - 1);
        CGFloat fftIdx = yFract * ((CGFloat)fourierSize);
        
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
        
        if (interpVal > maxValue && y != maxY - 1) {
            maxValue = interpVal;
            maxIndex = y;
        }
        //drawBuffers[0][y] = (interpVal * 120);
        //printf("(%f, %f)  ", , interpVal * 120);
   //     printf("(%i, %g)  ", y, interpVal);
        
        
    }
    float frequency = maxIndex * kRatio;
    printf("%g", frequency);
    printf("\n\n");
    
    
    
    
    [self performSelector:@selector(fourier) withObject:nil afterDelay:2.0];
}

@end
