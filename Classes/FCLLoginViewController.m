#import "FCLLoginViewController.h"
#import "FCLSession.h"
#import "PHTTPConnection.h"
#import "MBProgressHUD.h"
#import "UIViewController+Alert.h"

@interface FCLLoginViewController () <UITextFieldDelegate>

@property (weak) id <FCLLoginViewControllerDelegate> delegate;
@property PHTTPConnection *connection;
@property MBProgressHUD *loadingHUD;

@property (weak, nonatomic) IBOutlet UITextField* emailTextField;
@property (weak, nonatomic) IBOutlet UITextField* passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *logInButton;

@end

@implementation FCLLoginViewController

-(nonnull instancetype) initWithDelegate:(id <FCLLoginViewControllerDelegate>)delegate {
    self = [[UIStoryboard storyboardWithName:@"Login" bundle:nil] instantiateInitialViewController];
    NSAssert(self, @"Could not load the Login view controller from its Storyboard.");
    if (self) {
        NSParameterAssert(delegate);
        _delegate = delegate;
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
- (IBAction)emailEditingChanged:(id)sender {
    [self updateLogInButtonEnabled];
}

- (IBAction)passwordEditingChanged:(id)sender {
    [self updateLogInButtonEnabled];
}


- (IBAction) logIn:(id)sender
{
    if (_connection) return; // ignore repeated taps
    
    if([self loginField] == nil || [self passwordField] == nil) { // Can happen if validating with the Keyboard
        return;
    }
    
    FCLSession *session = [[FCLSession alloc] initWithUsername:[self loginField] password:[self passwordField]];
  
    // The 'r' parameter was useful because Orange would cache the URL. Is it still useful?
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/account/get_files_and_image_enabled_objects/0.xml?r=%d", session.facileBaseURL, rand()]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    [request setFCLSession:session];
    
    self.connection = [PHTTPConnection connectionWithRequest:request];
    self.connection.username = session.username;
    self.connection.password = session.password;
    
    self.loadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.loadingHUD.mode = MBProgressHUDModeIndeterminate;
    self.loadingHUD.labelText = NSLocalizedString(@"Connexion...", @"");
    
    __weak FCLLoginViewController *weakSelf = self;
    [self.connection startWithCompletionBlock:^{
        [weakSelf.loadingHUD hide:YES];
        weakSelf.loadingHUD = nil;
        
        if (weakSelf.connection.data) {
            [session saveSession]; // Emits FCLSessionDidSignInNotification
            
            // This is a little trick to leave the view controller in a consistent state between the Office and Scan tabs.
            weakSelf.emailTextField.text = nil;
            weakSelf.passwordTextField.text = nil;
        } else {
            NSLog(@"COULD NOT LOG IN: %@", weakSelf.connection.error);
            [weakSelf FCL_presentAlertWithTitle:@"Échec de la connexion" message:@"Veuillez vérifier votre adresse e-mail et votre mot de passe, puis réessayez."];
        }
        weakSelf.connection = nil;
    }];
}


- (IBAction)createAccount:(id)sender {
    [self.delegate loginViewControllerWantsAccountCreation:self];
}

-(void) updateLogInButtonEnabled {
    self.logInButton.enabled = [self loginField] && [self passwordField];
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

