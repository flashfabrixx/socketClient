#import "MeteorAgent.h"
#import "LoginViewController.h"
#import "ListViewController.h"

@implementation LoginViewController
{
    UIAlertController *resumeSessionAlert;
    NSString *sessionToken;
    BOOL isUserCreatingAccount;
}

- (void)viewDidLoad
{
    [super viewDidLoad];    
    isUserCreatingAccount = YES;
    [self setLabelsForView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View Layout

- (void)setLabelsForView
{
    if (isUserCreatingAccount) {
        self.title = @"Register";
        self.sendActionButton.titleLabel.text = @"Create a new account";
        self.switchSignupButton.titleLabel.text = @"Already have an account?";
    } else {
        self.title = @"Login";
        self.sendActionButton.titleLabel.text = @"Login into account";
        self.switchSignupButton.titleLabel.text = @"Don't have an account?";
    }
}

- (void)showListView
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UINavigationController *vc = [storyboard instantiateViewControllerWithIdentifier:@"ListViewControllerNC"];
    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Textfields

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField isEqual:self.emailTextField]) {
        [textField resignFirstResponder];
        [self.passwordTextField becomeFirstResponder];
    } else if ([textField isEqual:self.passwordTextField]) {
        [textField resignFirstResponder];
    }
    return YES;
}

#pragma mark - Validation Helper

- (BOOL)validateTextFields
{
    NSMutableString *errorMessage = [NSMutableString new];
    BOOL inputHasErrors = NO;
    
    if (![self validateEmailAddress:self.emailTextField.text]) {
        [errorMessage appendString:@"Please enter a valid email address. "];
        inputHasErrors = YES;
    }
    if (self.passwordTextField.text.length < 5) {
        [errorMessage appendString:@"Please make sure that your password has at least five characters."];
        inputHasErrors = YES;
    }
    
    if (inputHasErrors) {
        [self showErrorWithMessage:errorMessage];
    }
    return inputHasErrors;
}

- (BOOL)validateEmailAddress:(NSString *)text
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [predicate evaluateWithObject:text];
}

- (void)showErrorWithMessage:(NSString *)errorMessage
{
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"Error"
                                        message:errorMessage
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sendButton = [UIAlertAction actionWithTitle:@"Okay, I understand." style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:sendButton];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Network Actions

- (void)createNewAccount
{
    [[[MeteorAgent sharedInstance] meteorClient] signupWithEmail:self.emailTextField.text
                                                        password:self.passwordTextField.text
                                                        fullname:self.emailTextField.text
                                                responseCallback:^(NSDictionary *response, NSError *error) {
                                                    if (error) {
                                                        [self showErrorWithMessage:[error localizedDescription]];
                                                        return;
                                                    }
                                                    [[MeteorAgent sharedInstance] saveConnectionCredentials:response];
                                                    [self showListView];
                                                }];
}

- (void)loginIntoAccount
{
    [[[MeteorAgent sharedInstance] meteorClient] logonWithUsernameOrEmail:self.emailTextField.text
                                                                 password:self.passwordTextField.text
                                                         responseCallback:^(NSDictionary *response, NSError *error) {
                                                             if (error) {
                                                                 [self showErrorWithMessage:[error localizedDescription]];
                                                                 return;
                                                             }
                                                             [[MeteorAgent sharedInstance] saveConnectionCredentials:response];
                                                             [self showListView];
    }];
}

#pragma mark - Button Actions

- (IBAction)sendActionButtonTapped:(id)sender
{
    if (![self validateTextFields]) {
        if (isUserCreatingAccount) {
            [self createNewAccount];
        } else {
            [self loginIntoAccount];
        }
    }
}

- (IBAction)switchSignupButtonTapped:(id)sender
{
    // Switch between register or login mode
    if (isUserCreatingAccount) {
        isUserCreatingAccount = NO;
    } else if (!isUserCreatingAccount) {
        isUserCreatingAccount = YES;
    }
    [self performSelector:@selector(setLabelsForView) withObject:nil afterDelay:.3];
}
@end
