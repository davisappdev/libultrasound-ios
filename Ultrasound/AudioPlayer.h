
#import <Foundation/Foundation.h>
#import "AudioManager.h"


#define kFFTInterval 0.02
#define kTransmitInterval 0.4

@protocol AudioPlayerReceiveDelegate <NSObject>

- (void) audioReceivedDataUpdate:(int)data;
- (void) audioReceivedText:(NSString *) text;
- (void) audioReceivedFFTData:(float *)data arraySize:(int)size cutoff:(float)cutoff;

@end

@protocol AudioPlayerTransmitDelegate <NSObject>

- (void) audioStartedTransmittingSequence: (float *) freqs withSize: (int) size;
- (void) audioStartedTransmittingFrequencies:(float *) freqs withSize:(int) size;
- (void) audioFinishedTransmittingSequence;

@end

@interface AudioPlayer : NSObject <AudioManagerDelegate>

+ (AudioPlayer *) sharedAudioPlayer;

- (void) start;
- (void) stop;
- (void) setDataToTransmit: (int) numberToSend;
- (void) transmitSequence:(NSArray *)sequence;
- (void) transmitPacketDelimiterWithCallback:(void (^)(void))callback;
- (void) transmitString:(NSString *)string;

@property (nonatomic) BOOL isReceiving;
@property (nonatomic, weak) id<AudioPlayerTransmitDelegate> transmitDelegate;
@property (nonatomic, weak) id<AudioPlayerReceiveDelegate> receiveDelegate;

@end
