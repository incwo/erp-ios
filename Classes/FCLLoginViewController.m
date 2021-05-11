#import "FCLLoginViewController.h"
#import "FCLSession.h"
#import "MBProgressHUD.h"
#import "UIViewController+Alert.h"

@interface FCLLoginViewController () <UITextFieldDelegate>

@property (weak) id <FCLLoginViewControllerDelegate> delegate;
@property NSURLSessionDataTask *credentialsCheckTask;
@property MBProgressHUD *loadingHUD;

@property (weak, nonatomic) IBOutlet UITextField* emailTextField;
@property (weak, nonatomic) IBOutlet UITextField* passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *shardTextField;
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

- (IBAction)showShardingHelp:(id)sender {
    [self FCL_presentAlertWithTitle:@"Espace privé ?" message:@"Certains clients disposent d'une instance de serveur privée, avec son propre stockage et sa propre puissance de calcul.\n\nSi vous ne disposez pas d'un tel espace, laissez le champ vide."];
}

- (IBAction) logIn:(id)sender
{
    if (self.credentialsCheckTask) return; // ignore repeated taps
    
    if([self loginField] == nil || [self passwordField] == nil) { // Can happen if validating with the Keyboard
        return;
    }
    
    self.loadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.loadingHUD.mode = MBProgressHUDModeIndeterminate;
    self.loadingHUD.labelText = NSLocalizedString(@"Connexion...", @"");
    
    
    FCLSession *session = [[FCLSession alloc] initWithUsername:[self loginField] password:[self passwordField]];
    __typeof(self) __weak weakSelf = self;
    [self checkSessionCredentials:session onAuthorized:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.loadingHUD hide:YES];
            weakSelf.loadingHUD = nil;
            [session saveSession]; // Emits FCLSessionDidSignInNotification
            
            // This is a little trick to leave the view controller in a consistent state between the Office and Scan tabs.
            weakSelf.emailTextField.text = nil;
            weakSelf.passwordTextField.text = nil;
        });
    } onUnauthorized:^(NSInteger httpStatusCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.loadingHUD hide:YES];
            weakSelf.loadingHUD = nil;
            
            if(httpStatusCode == 401) {
                [weakSelf FCL_presentAlertWithTitle:@"Compte invalide" message:@"Veuillez vérifier votre adresse e-mail et votre mot de passe, puis réessayez."];
            } else {
                [weakSelf FCL_presentAlertWithTitle:@"Échec de la connexion" message:[NSString stringWithFormat:@"Le serveur a répondu avec le status HTTP %li", httpStatusCode]];
            }
        });
    } onError:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.loadingHUD hide:YES];
            weakSelf.loadingHUD = nil;
            [weakSelf FCL_presentAlertForError:error];
        });
    }];
}

-(void) checkSessionCredentials:(FCLSession *)session onAuthorized:(void (^)(void))onAuthorized onUnauthorized:(void (^)(NSInteger))onUnauthorized onError:(void (^)(NSError *))onError {
    // The 'r' parameter was useful because Orange would cache the URL. Is it still useful?
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/account/get_files_and_image_enabled_objects/0.xml?r=%d", session.facileBaseURL, rand()]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    [request setFCLSession:session];
    
    __typeof(self) __weak weakSelf = self;
    self.credentialsCheckTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        weakSelf.credentialsCheckTask = nil;
        
        if(error) {
            onError(error);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(httpResponse.statusCode < 200 || httpResponse.statusCode > 299) {
            onUnauthorized(httpResponse.statusCode);
            return;
        }
        
        if(data == nil) {
            onError([NSError errorWithDomain:@"Login credentials" code:0 userInfo:@{NSLocalizedDescriptionKey: @"No data returned by the server."}]);
            return;
        }
        
        onAuthorized();
    }];
    [self.credentialsCheckTask resume];
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

