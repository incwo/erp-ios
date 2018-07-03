#import "FCLLoginController.h"
#import "FCLSession.h"
#import "PHTTPConnection.h"
#import "MBProgressHUD.h"

@interface FCLLoginController () <UITextFieldDelegate>

@property PHTTPConnection *connection;
@property MBProgressHUD *loadingHUD;

@property(nonatomic, strong) IBOutlet UITextField* loginTextField;
@property(nonatomic, strong) IBOutlet UITextField* passwordTextField;

- (NSString*) login;
- (NSString*) password;
@end

@implementation FCLLoginController



- (void) cancel:(id)_
{
    [self.connection cancel];
    self.connection = nil;
    
    if (self.completionHandler)
    {
        self.completionHandler(nil, nil);
        self.completionHandler = nil;
    }
}

- (void) done:(id)_
{
    if (_connection) return; // ignore repeated taps
    
    FCLSession* session = [[FCLSession alloc] init];
    session.username = self.login;
    session.password = self.password;
  
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
        
        if (weakSelf.connection.data)
        {
            if (weakSelf.completionHandler)
            {
                [session saveSession];
                weakSelf.completionHandler(session, nil);
                weakSelf.completionHandler = nil;
            }
        }
        else
        {
            NSLog(@"CANNOT LOG IN: %@", weakSelf.connection.error);
            NSString *message = [weakSelf.connection.error localizedDescription] ?: @"Merci d'indiquer un email valide pour vous connecter.";
            [weakSelf _showAlertWithTitle:@"Erreur" message:message];
        }
        weakSelf.connection = nil;
    }];
}

-(void) _showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString*) login
{
    return (self.loginTextField.text && ![self.loginTextField.text isEqualToString:@""]) ? self.loginTextField.text : nil;
}

- (NSString*) password
{
    return (self.passwordTextField.text && ![self.passwordTextField.text isEqualToString:@""]) ? self.passwordTextField.text : nil;
}




#pragma mark - UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"incwo", @"");
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                             target:self
                                             action:@selector(cancel:)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                              target:self
                                              action:@selector(done:)];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Connexion", @"") style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.loginTextField.text = self.email ?: [self login];
    self.passwordTextField.text = [self password];
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
        [self done:nil];
    }
    return YES;
}



#pragma mark - UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) return NSLocalizedString(@"E-mail", @"");
    if (section == 1) return NSLocalizedString(@"Mot de passe", @"");
    return nil;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell*)tableView:(UITableView*)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    UITextField* field = nil;
    
    if (indexPath.section == 0) field = self.loginTextField;
    if (indexPath.section == 1) field = self.passwordTextField;
    
    field.delegate = self;
    
    [field setFrame:CGRectInset(CGRectMake(0, 0, cell.contentView.bounds.size.width, 40.0), 10.0, 0.0)];
    [cell.contentView addSubview:field];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

@end

