#include "FFTBufferManager.h"

#define min(x,y) (x < y) ? x : y

FFTBufferManager::FFTBufferManager(UInt32 inNumberFrames) :
	mNeedsAudioData(0),
	mHasAudioData(0),
	mNumberFrames(inNumberFrames),
	mAudioBufferSize(inNumberFrames * sizeof(int32_t)),
    mAudioBufferCurrentIndex(0)
    
{
	mAudioBuffer = (int32_t*)malloc(mAudioBufferSize);	
	mSpectrumAnalysis = SpectrumAnalysisCreate(mNumberFrames);
	OSAtomicIncrement32Barrier(&mNeedsAudioData);
}

FFTBufferManager::~FFTBufferManager()
{
	free(mAudioBuffer);
	SpectrumAnalysisDestroy(mSpectrumAnalysis);
}

void FFTBufferManager::GrabAudioData(AudioBufferList *inBL)
{
	if (mAudioBufferSize < inBL->mBuffers[0].mDataByteSize)	return;
	
	UInt32 bytesToCopy = min(inBL->mBuffers[0].mDataByteSize, mAudioBufferSize - mAudioBufferCurrentIndex);
	memcpy(mAudioBuffer+mAudioBufferCurrentIndex, inBL->mBuffers[0].mData, bytesToCopy);
    
    
    /*printf("Microphone Values:\n");
    for(int i = 0; i < inBL->mBuffers[0].mDataByteSize * sizeof(int32_t); i += sizeof(int32_t))
    {
        printf("%f\n", ((float *)inBL->mBuffers[0].mData)[i]);
    }
	printf("\n\n");*/
    
    
	mAudioBufferCurrentIndex += bytesToCopy / sizeof(int32_t);
	if (mAudioBufferCurrentIndex >= mAudioBufferSize / sizeof(int32_t))
	{
		OSAtomicIncrement32Barrier(&mHasAudioData);
		OSAtomicDecrement32Barrier(&mNeedsAudioData);
	}
}

Boolean	FFTBufferManager::ComputeFFT(int32_t *outFFTData)
{
	if (HasNewAudioData())
	{
		SpectrumAnalysisProcess(mSpectrumAnalysis, mAudioBuffer, outFFTData, true);
//        SpectrumAnalysisProcess(mSpectrumAnalysis, mAudioBuffer, outFFTData, false);
		OSAtomicDecrement32Barrier(&mHasAudioData);
		OSAtomicIncrement32Barrier(&mNeedsAudioData);
		mAudioBufferCurrentIndex = 0;
		return true;
	}
	else if (mNeedsAudioData == 0)
		OSAtomicIncrement32Barrier(&mNeedsAudioData);
	
	return false;
}
