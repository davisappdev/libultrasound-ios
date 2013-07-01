
#import <UIKit/UIKit.h>
#import "AudioPlayer.h"

@interface ViewController : UIViewController <AudioPlayerDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *receivedData;
@property (weak, nonatomic) IBOutlet UITextField *numberToSend;

@end