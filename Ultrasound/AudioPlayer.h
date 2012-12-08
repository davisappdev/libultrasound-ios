
#import <Foundation/Foundation.h>
#import "AudioManager.h"

@protocol AudioPlayerDelegate <NSObject>

- (void) audioReceivedDataUpdate:(int)data;

@end

@interface AudioPlayer : NSObject <AudioManagerDelegate>

- (void) start;
- (void) stop;
- (void) setDataToTransmit: (int) numberToSend;

@property (nonatomic) BOOL isReceiving;
@property (nonatomic, weak) id<AudioPlayerDelegate> delegate;

@end
