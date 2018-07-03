#import "FCLWebViewController.h"
#import "OANetworkActivityIndicator.h"

@interface FCLWebViewController () <UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *webViewControls;
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIButton *forwardButton;
@property (strong, nonatomic) IBOutlet UIButton *reloadButton;
@property (strong, nonatomic) IBOutlet UIButton *stopButton;

@property(nonatomic) BOOL loadingInProgress;

@end

@implementation FCLWebViewController {
    NSString* _HTML;
    NSURL* _baseURL;
    NSURL* _URL;
}

- (id) initWithHTML:(NSString*)html baseURL:(NSURL *)baseURL
{
    if (self = [super initWithNibName:nil bundle:nil])
    {
        _HTML = html;
        _baseURL = baseURL;
    }
    return self;
}

- (id) initWithURL:(NSURL*)url
{
    if (self = [super initWithNibName:nil bundle:nil])
    {
        _URL = url;
    }
    return self;
}

// MARK: Lifecycle

- (void) dealloc
{
    self.loadingInProgress = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for(UIView *wview in [[[self.webView subviews] objectAtIndex:0] subviews]) {
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; }
    }
    
    self.navigationItem.titleView = self.webViewControls;
    
    [self updateControls];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:(BOOL)animated];
    
    if (_HTML)
    {
        [self.webView loadHTMLString:_HTML baseURL:_baseURL];
    }
    else
    {
        [self.webView loadRequest:[NSURLRequest requestWithURL:_URL]];
    }
    [self updateControls];
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

// MARK: Navigation

- (void) updateControls
{
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
    self.stopButton.hidden = !self.webView.isLoading;
    self.reloadButton.hidden = !self.stopButton.hidden;
}



- (void) setLoadingInProgress:(BOOL)loadingInProgress
{
    if (loadingInProgress == _loadingInProgress) return;
    _loadingInProgress = loadingInProgress;
    if (_loadingInProgress)
    {
        [OANetworkActivityIndicator push];
    }
    else
    {
        [OANetworkActivityIndicator pop];
    }
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




#pragma mark - UIWebViewDelegate




- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"Web view URL: %@", request.URL);
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.loadingInProgress = YES;
    [self updateControls];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.loadingInProgress = NO;
    [self updateControls];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    self.loadingInProgress = NO;
    [self updateControls];
    
    if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled)
    {
        // skip
    }
    else
    {
        // Do not show any error if we stopped loading after signing out.
        [self showAlertForError:error];
    }
}

-(void) showAlertForError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erreur" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}



@end
