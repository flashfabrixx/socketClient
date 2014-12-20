#import <UIKit/UIKit.h>
@interface LoginViewController : UIViewController
<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendActionButton;
@property (weak, nonatomic) IBOutlet UIButton *switchSignupButton;

- (IBAction)sendActionButtonTapped:(id)sender;
- (IBAction)switchSignupButtonTapped:(id)sender;

@end
