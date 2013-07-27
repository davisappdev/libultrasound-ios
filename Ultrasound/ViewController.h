
#import <UIKit/UIKit.h>
#import "AudioPlayer.h"
#import "CardIO.h"

@interface ViewController : UIViewController <AudioPlayerReceiveDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CardIOPaymentViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *receivedData;
@property (weak, nonatomic) IBOutlet UILabel *receivedText;
@property (weak, nonatomic) IBOutlet UITextField *numberToSend;
@property (weak, nonatomic) IBOutlet UITextField *textToSendField;

@end