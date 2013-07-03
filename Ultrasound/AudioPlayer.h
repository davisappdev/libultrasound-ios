
#import <Foundation/Foundation.h>
#import "AudioManager.h"

@protocol AudioPlayerDelegate <NSObject>

- (void) audioReceivedDataUpdate:(int)data;

@end

@interface AudioPlayer : NSObject <AudioManagerDelegate>

- (void) start;
- (void) stop;
- (void) setDataToTransmit: (int) numberToSend;
- (void) transmitSequence:(NSArray *)sequence;
- (void) transmitPacketDelimiterWithCallback:(void (^)(void))callback;

@property (nonatomic) BOOL isReceiving;
@property (nonatomic, weak) id<AudioPlayerDelegate> delegate;

@end
