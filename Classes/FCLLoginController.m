#import "FCLLoginController.h"
#import "FCLSession.h"
#import "PHTTPConnection.h"
#import "MBProgressHUD.h"

@interface FCLLoginController () <UITextFieldDelegate>

@property (weak) id <FCLLoginControllerDelegate> delegate;
@property PHTTPConnection *connection;
@property MBProgressHUD *loadingHUD;

@property(nonatomic, strong) IBOutlet UITextField* emailTextField;
@property(nonatomic, strong) IBOutlet UITextField* passwordTextField;

@end

@implementation FCLLoginController

-(nonnull instancetype) initWithDelegate:(id <FCLLoginControllerDelegate>)delegate email:(nullable NSString *)email {
    self = [[UIStoryboard storyboardWithName:@"Login" bundle:nil] instantiateInitialViewController];
    NSAssert(self, @"Could not load the Login view controller from its Storyboard.");
    if (self) {
        NSParameterAssert(delegate);
        _delegate = delegate;
        _email = email;
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

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.emailTextField.text = [FCLSession savedSession].username;
    self.passwordTextField.text = [FCLSession savedSession].password;
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

-(void)setEmail:(NSString *)email {
    if(email == _email) {
        return;
    }
    
    self.emailTextField.text = email;
}

// MARK: Actions

- (IBAction) logIn:(id)sender
{
    if (_connection) return; // ignore repeated taps
    
    FCLSession *session = [[FCLSession alloc] initWithUsername:[self loginField] password:[self passwordField]];
  
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
            [session saveSession]; // Emits FCLSessionDidSignInNotification
        } else {
            NSLog(@"COULD NOT LOG IN: %@", weakSelf.connection.error);
            [weakSelf.delegate loginControllerDidFail:self error:weakSelf.connection.error];
        }
        weakSelf.connection = nil;
    }];
}

- (IBAction)createAccount:(id)sender {
    [self.delegate loginControllerWantsAccountCreation:self];
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

