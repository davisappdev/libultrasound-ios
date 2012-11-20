
#if !defined(__rio_helper_h__)
#define __rio_helper_h__

#include "CAStreamBasicDescription.h"

#define kNumDrawBuffers 12
#define kDefaultDrawSamples 1024
#define kMinDrawSamples 64
#define kMaxDrawSamples 4096

extern int drawBufferIdx;
extern int drawBufferLen;
extern int drawBufferLen_alloced;
extern SInt8 *drawBuffers[];

//int SetupRemoteIO (AudioUnit& inRemoteIOUnit, AURenderCallbackStruct inRenderProc);
void SilenceData(AudioBufferList *inData);

class DCRejectionFilter
{
public:
	DCRejectionFilter(Float32 poleDist = DCRejectionFilter::kDefaultPoleDist);

	void InplaceFilter(SInt32* ioData, UInt32 numFrames, UInt32 strides);
	void Reset();

protected:
	
	// Coefficients
	SInt16 mA1;
	SInt16 mGain;

	// State variables
	SInt32 mY1;
	SInt32 mX1;
	
	static const Float32 kDefaultPoleDist;
};

#endif