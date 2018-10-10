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

@property(nonatomic, strong) IBOutlet UITextField* loginTextField;
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
    self.title = NSLocalizedString(@"incwo", @"");
    
    self.loginTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                             target:self
                                             action:@selector(cancel:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                              target:self
                                              action:@selector(done:)];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Connexion", @"") style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.loginTextField.text = self.email ?: [self loginField];
    self.passwordTextField.text = [self passwordField];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.loginTextField becomeFirstResponder];
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

- (void) cancel:(id)sender
{
    [self.connection cancel];
    self.connection = nil;
    
    self.successHandler(nil);
}

- (void) done:(id)sender
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
    return (self.loginTextField.text && ![self.loginTextField.text isEqualToString:@""]) ? self.loginTextField.text : nil;
}

- (NSString *) passwordField
{
    return (self.passwordTextField.text && ![self.passwordTextField.text isEqualToString:@""]) ? self.passwordTextField.text : nil;
}


#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.loginTextField)
    {
        [textField resignFirstResponder];
        [self.passwordTextField becomeFirstResponder];
    }
    
    if (textField == self.passwordTextField)
    {
        [textField resignFirstResponder];
        [self done: self];
    }
    return YES;
}

@end

