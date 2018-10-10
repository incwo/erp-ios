#import "FCLOfficeContentViewController.h"
#import "facilescan-Swift.h"
#import "FCLLoginController.h"
#import "FCLSession.h"
#import "PFWebViewController.h"
#import "OANetworkActivityIndicator.h"
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+Alert.h"

@interface FCLOfficeContentViewController () <UIWebViewDelegate>

@property(nonatomic) IBOutlet UIWebView* webView;
@property(nonatomic) IBOutlet UIView* webViewControls;

@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIButton *forwardButton;
@property (strong, nonatomic) IBOutlet UIButton *reloadButton;
@property (strong, nonatomic) IBOutlet UIButton *stopButton;

@property (nonatomic) BOOL didLoadSomethingAlready;
@property (nonatomic) BOOL loading;

@end

@implementation FCLOfficeContentViewController

// MARK: Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = true;
    self.navigationItem.titleView = self.webViewControls;
    [self updateControls];
}

- (void) dealloc {
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

- (IBAction)signOut:(id)sender {
    [FCLSession removeSavedSession]; // Emits a FCLSessionDidSignOutNotification
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
