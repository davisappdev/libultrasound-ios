#ifndef __RAD2_FFT_H__
#define __RAD2_FFT_H__

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Struct for holding a 32 bit integer complex numbers
 */
struct Int32Cplx
{
	int real;
	int imag;
};
typedef struct Int32Cplx Int32Cplx;

/*
 * Packed complex type. The upper 16 bits correspond to the real part,
 * the lower 16 bit to imaginary part
 */
typedef int PackedInt16Cplx;


/*
 * Create a lookup table with "size" twiddle factors for the FFT.
 */
PackedInt16Cplx* CreatePackedTwiddleFactors(int size);

	
/* 
 * Dispose the twiddle factor table
 */
void DisposePackedTwiddleFactors(PackedInt16Cplx* cosSinTable);
	

/*
 * Inplace complex radix 2 FFT. The complex data vector must have the specified size and must be a power of 2.
 */
void Radix2IntCplxFFT(Int32Cplx* ioCplxData, int size, const PackedInt16Cplx* twiddleFactors, int twiddleFactorsStrides);


#ifdef __cplusplus
	}
#endif
		
#endif
