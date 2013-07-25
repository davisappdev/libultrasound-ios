#include <AudioToolbox/AudioToolbox.h>
#include <libkern/OSAtomic.h>

#include "SpectrumAnalysis.h"

class FFTBufferManager
{
public:
	FFTBufferManager(UInt32 inNumberFrames);
	~FFTBufferManager();
	
	volatile int32_t	HasNewAudioData()	{ return mHasAudioData; }
	volatile int32_t	NeedsNewAudioData() { return mNeedsAudioData; }

	UInt32				GetNumberFrames() { return mNumberFrames; }

	void				GrabAudioData(AudioBufferList *inBL);
	Boolean				ComputeFFT(int32_t *outFFTData);
	
private:
	volatile int32_t	mNeedsAudioData;
	volatile int32_t	mHasAudioData;
	
	H_SPECTRUM_ANALYSIS mSpectrumAnalysis;
	
	int32_t*			mAudioBuffer;
	UInt32				mNumberFrames;
	UInt32				mAudioBufferSize;
	int32_t				mAudioBufferCurrentIndex;
};