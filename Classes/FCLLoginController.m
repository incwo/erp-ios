#import "FCLLoginController.h"
#import "FCLSession.h"
#import "PHTTPConnection.h"
#import "MBProgressHUD.h"

@interface FCLLoginController () <UITextFieldDelegate>

@property NSString *email;
@property FCLLoginControllerSuccessHandler successHandler;
@property FCLLoginControllerFailureHandler failureHandler;
@property PHTTPConnection *connection;
@property MBProgressHUD *loadingHUD;

@property(nonatomic, strong) IBOutlet UITextField* emailTextField;
@property(nonatomic, strong) IBOutlet UITextField* passwordTextField;

@end

@implementation FCLLoginController

-(nonnull instancetype) initWithEMail:(nullable NSString *)email success:(nonnull FCLLoginControllerSuccessHandler)successHandler failure:(nonnull FCLLoginControllerFailureHandler)failureHandler {
    self = [[UIStoryboard storyboardWithName:@"Login" bundle:nil] instantiateInitialViewController];
    NSAssert(self, @"Could not load the Login view controller from its Storyboard.");
    if (self) {
        _email = email;
        NSParameterAssert(successHandler);
        _successHandler = successHandler;
        NSParameterAssert(failureHandler);
        _failureHandler = failureHandler;
    }
    return self;
}

#pragma mark - UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Connexion";
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Connexion", @"") style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.emailTextField.text = self.email ?: [self loginField];
    self.passwordTextField.text = [self passwordField];
}

// MARK: Rotation

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAllButUpsideDown;
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (BOOL) shouldAutorotate
{
    return YES;
}

// MARK: Actions

- (IBAction) logIn:(id)sender
{
    if (_connection) return; // ignore repeated taps
    
    FCLSession* session = [[FCLSession alloc] init];
    session.username = [self loginField];
    session.password = [self passwordField];
  
//#warning Need a more efficient way to sign in.
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/account/get_files_and_image_enabled_objects/0.xml?r=%d", session.facileBaseURL, rand()]];
//    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/account/get_my_email?r=%d", session.facileBaseURL, rand()]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    [request setFCLSession:session];
    
    self.connection = [PHTTPConnection connectionWithRequest:request];
    self.connection.username = session.username;
    self.connection.password = session.password;
    
    self.loadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.loadingHUD.mode = MBProgressHUDModeIndeterminate;
    self.loadingHUD.labelText = NSLocalizedString(@"Connexion...", @"");
    
    __weak FCLLoginController *weakSelf = self;
    [self.connection startWithCompletionBlock:^{
        [weakSelf.loadingHUD hide:YES];
        weakSelf.loadingHUD = nil;
        
        if (weakSelf.connection.data) {
            [session saveSession];
            weakSelf.successHandler(session);
        } else {
            NSLog(@"COULD NOT LOG IN: %@", weakSelf.connection.error);
            weakSelf.failureHandler(weakSelf.connection.error);
        }
        weakSelf.connection = nil;
    }];
}

- (NSString *) loginField
{
    return (self.emailTextField.text && ![self.emailTextField.text isEqualToString:@""]) ? self.emailTextField.text : nil;
}

- (NSString *) passwordField
{
    return (self.passwordTextField.text && ![self.passwordTextField.text isEqualToString:@""]) ? self.passwordTextField.text : nil;
}


#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.emailTextField)
    {
        [textField resignFirstResponder];
        [self.passwordTextField becomeFirstResponder];
    }
    
    if (textField == self.passwordTextField)
    {
        [textField resignFirstResponder];
        [self logIn: self];
    }
    return YES;
}

@end

