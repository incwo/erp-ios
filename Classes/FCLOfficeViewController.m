#import "FCLOfficeViewController.h"
#import "FCLLoginController.h"
#import "FCLSession.h"
#import "PFWebViewController.h"
#import "OANetworkActivityIndicator.h"
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+Alert.h"

@interface FCLOfficeViewController () <UIWebViewDelegate>

@property(nonatomic) IBOutlet UIWebView* webView;
@property(nonatomic) IBOutlet UIView* webViewControls;
@property(nonatomic) IBOutlet UIView* authView;

@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIButton *forwardButton;
@property (strong, nonatomic) IBOutlet UIButton *reloadButton;
@property (strong, nonatomic) IBOutlet UIButton *stopButton;

@property (nonatomic) BOOL didLoadSomethingAlready;
@property(nonatomic) BOOL loading;

@end

@implementation FCLOfficeViewController

// MARK: Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    FCLSession* session = [FCLSession savedSession];
    if ([session isValid]) {
        self.session = session;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSignOut:) name:FCLSessionDidSignOutNotification object:nil];
    
    [self updateView];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.loading = NO;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![self.session isValid]) {
        FCLSession* session = [FCLSession savedSession];
        if ([session isValid]) {
            self.session = session;
        }
    }
    
    if ([self.session isValid] && !self.didLoadSomethingAlready) {
        self.didLoadSomethingAlready = YES;
        [self loadHomepage];
    }
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


#pragma - Actions


- (void) didSignOut:(id)_
{
    self.session = nil;
    [self.webView stopLoading];
    [self.webView loadHTMLString:@"" baseURL:[NSURL URLWithString:@"http://example.com"]]; // clear the webview for securing
    self.didLoadSomethingAlready = NO;
    [self updateView];
}

- (IBAction)signOut:(id)sender
{
    [FCLSession removeSavedSession];
}

- (void) sessionNeedsSignIn:(NSNotification *)notification
{
    [self signInWithEmail:notification.userInfo[FCLSessionEmailKey]];
}

- (IBAction)signIn:(id)sender
{
    [self signInWithEmail:nil];
}

- (void)signInWithEmail:(NSString *)email
{
    FCLLoginController* loginViewController = [[FCLLoginController alloc] initWithNibName:nil bundle:nil];
    loginViewController.email = email;
    __weak FCLLoginController* wc = loginViewController;
    loginViewController.completionHandler = ^(FCLSession* session, NSError* error) {
        self.session = session;
        
        if (session)
            [self loadHomepage];
        [self dismissViewControllerAnimated:wc completion:^{}];
    };
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:loginViewController] animated:YES completion:nil];
    [self updateView];
}

- (IBAction)signUp:(id)sender
{
    NSString* storyBoardName = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? @"Main-iPad" : @"Main";
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:storyBoardName bundle:nil];
    UINavigationController *webViewNavigationController = [storyBoard instantiateViewControllerWithIdentifier:@"webViewNavigationController"];

    // webViewController may eventually emit FCLSessionNeedsSignInNotification
    PFWebViewController* webViewController = webViewNavigationController.viewControllers[0];
    webViewController.request = [FCLSession signupRequest];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionNeedsSignIn:) name:FCLSessionNeedsSignInNotification object:webViewController];
    
    [self presentViewController:webViewNavigationController animated:YES completion:nil];
}

- (IBAction)reloadPage:(id)sender
{
    [self.webView reload];
    [self updateControls];
}

- (IBAction)stopLoadingPage:(id)sender
{
    [self.webView stopLoading];
    [self updateControls];
}

- (IBAction)goBack:(id)sender
{
    [self.webView goBack];
    [self updateControls];
}

- (IBAction)goForward:(id)sender
{
    [self.webView goForward];
    [self updateControls];
}


#pragma - Configuration

- (void) loadHomepage
{
    // According to email from Guillaume 21/01/2013:
    // Would that be acceptable to login by going to "account/login" with params[:email] / params[:password] as credentials ? It would save us time.
    
    NSString* authQueryString = [NSString stringWithFormat:@"email=%@&password=%@",
                                 [self.session.username stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                                 [self.session.password stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
    // Note: this url somehow redirects to the home page.
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/account/login?mobile=1&remember_me=1&%@", self.session.facileBaseURL, authQueryString]];
    
    // This redirects sucessfully where needed (but only after signed in from the webview)
    //NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/account/login_mobile?r=%d", self.session.facileBaseURL, rand()]];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setFCLSession:self.session];
    [self.webView loadRequest:request];
    [self updateControls];
}

@synthesize session = _session;
- (void) setSession:(FCLSession *)session {
    if (_session == session) {
        return;
    }
    _session = session;
    
    [self updateView];
}

- (void) updateView {
    [self updateControls];
    
    if(self.session) {
        self.webView.hidden = NO;
        self.authView.hidden = YES;
        self.navigationItem.titleView = self.webViewControls;
    } else {
        self.navigationItem.titleView = nil;
        self.navigationItem.title = @"Bureau";
        self.navigationItem.prompt = nil;
        self.webView.hidden = YES;
        self.authView.hidden = NO;
    }
}

- (void) updateControls {
    if (self.session) {
        self.backButton.enabled = self.webView.canGoBack;
        self.forwardButton.enabled = self.webView.canGoForward;
        self.stopButton.hidden = !self.webView.isLoading;
        self.reloadButton.hidden = !self.stopButton.hidden;
    }
}

@synthesize loading = _loading;
- (void) setLoading:(BOOL)loading {
    if(loading == _loading) {
        return;
    }
    _loading = loading;
    
    if (_loading) {
        [OANetworkActivityIndicator push];
    } else {
        [OANetworkActivityIndicator pop];
    }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"Web view URL: %@", request.URL);
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.loading = YES;
    [self updateControls];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.loading = NO;
    [self updateControls];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.loading = NO;
    [self updateControls];
    NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
    
    if(![self _isURLCancellationError:error]) {
        [self FCL_presentAlertForError:error];
    }
}

-(BOOL) _isURLCancellationError:(NSError *)error {
    return error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled;
}

@end
