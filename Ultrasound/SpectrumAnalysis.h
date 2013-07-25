#if !defined __SPECTRUM_ANALYSIS_H__
#define __SPECTRUM_ANALYSIS_H__

#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Forward declarations
 */
struct SPECTRUM_ANALYSIS;
typedef struct SPECTRUM_ANALYSIS* H_SPECTRUM_ANALYSIS;

	
/* 
 * Create a SpectrumAnalysis object. The block size argument must be a power of 2
 */
H_SPECTRUM_ANALYSIS SpectrumAnalysisCreate(int32_t blockSize);

	
/*
 * Dispose SpectrumAnalysis object
 */
void SpectrumAnalysisDestroy(H_SPECTRUM_ANALYSIS p);

/*
 * 
 * Inputs:
 *		p:				an opaque SpectrumAnalysis object handle
 *		inTimeSig:		pointer to a time signal of the same length as specified in SpectrumAnalysisCreate()
 *		outMagSpectrum:	pointer to a magnitude spectrum. Its length must at least be size/2
 *		in_dB:			flag indicating wether the magnitude spectrum should be calculated in dB
 *
 * Discussion:
 * 
 * the real valued time signal is first weighted with a Hamming window of the same size and then transformed
 * in the frequency domain. The squared magnitudes of the resulting complex spectrum are copied into the 
 * outMagSpectrum vector and then converted to dB if so requested. Since the input signal is real, the magnitude
 * spectrum is only half the size (note that the Nyquist term is discarded) as the input signal.
 *
 * Value ranges:
 *
 * the input signal is expected to be in a Q7.24 format in the range [-1, 1) which means that the integer parts should be zero
 * the ouput magnitude spectrum is in Q7.24 format with a range of [-128, 0) when calculated in dB.
 */
void SpectrumAnalysisProcess(H_SPECTRUM_ANALYSIS p, const int32_t* inTimeSig, int32_t* outMagSpectrum, bool in_dB);

#ifdef __cplusplus
}
#endif
		
#endif
