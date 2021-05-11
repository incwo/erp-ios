#import "FCLOfficeContentViewController.h"
#import "facilescan-Swift.h"
#import "FCLLoginViewController.h"
#import "FCLSession.h"
#import "OANetworkActivityIndicator.h"
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+Alert.h"
#import "MBProgressHUD.h"

@interface FCLOfficeContentViewController () <UIWebViewDelegate>

@property(nonatomic) IBOutlet UIView* webViewControls;

@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIButton *forwardButton;
@property (strong, nonatomic) IBOutlet UIButton *reloadButton;
@property (strong, nonatomic) IBOutlet UIButton *stopButton;

@property(strong, nonatomic) UIWebView *webView;
@property BOOL visible;
@property (nonatomic) BOOL loading;
@property BOOL showingCurrentBusinessFile;

@end

@implementation FCLOfficeContentViewController

// MARK: Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Menu"] style:(UIBarButtonItemStylePlain) target:self action:@selector(showSidePanel:)];
    
    [self addWebView];
    self.navigationItem.titleView = self.webViewControls;
    [self updateControls];
    
    // This restricts the content to the area between the navbar and the tabbar.
    // Otherwise, the top of the webview is shown below the navbar.
    // This is not the recommanded way on iOS 11+ (Safe Area should be used instead), but
    // at least it works seemlessly on iOS 9 and 10.
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void) dealloc {
    self.loading = NO;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSParameterAssert(self.session);
    self.visible = YES;
    
    if(!self.showingCurrentBusinessFile && self.businessFileId) {
        [self loadBusinessFileWithId:self.businessFileId];
    }
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    self.visible = NO;
}

// MARK: WebView

-(void) addWebView {
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.webView];
    
    [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
}

-(void) removeWebView {
    [self.webView removeFromSuperview];
    self.webView = nil;
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

-(void) showSidePanel:(id)sender {
    [self.delegate officeContentViewControllerPresentSidePanel:self];
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


// MARK: HTML page

@synthesize businessFileId = _businessFileId;
-(NSString *)businessFileId {
    @synchronized (self) {
        return _businessFileId;
    }
}

- (void)setBusinessFileId:(NSString *)businessFileId {
    @synchronized (self) {
        if(businessFileId == _businessFileId) {
            return;
        }
        _businessFileId = businessFileId;
    }
    
    if(self.visible && businessFileId) {
        [self loadBusinessFileWithId:businessFileId];
    } else {
        // There is no need to load the page for the new business file if the view is not shown.
        // It will loaded be when the view becomes visible.
        self.showingCurrentBusinessFile = NO;
    }
}

-(void) loadBusinessFileWithId:(NSString *)businessFileId {
    NSString *urlString = [@"https://www.incwo.com/navigation_mobile/home/" stringByAppendingString:businessFileId];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setBasicAuthHeadersForSession:self.session];
    
    // The History of the web view must be cleared or the user can go to a different business file using the Back or Forward commands.
    // Since Apple does not provide any method to clear the history of UIWebView (!), the less terrible way is to instantiate a new WebView.
    [self removeWebView];
    [self addWebView];
    
    [self.webView loadRequest:request];
    self.showingCurrentBusinessFile = YES;
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
        [MBProgressHUD showHUDAddedTo:self.webView animated:YES];
    } else {
        [OANetworkActivityIndicator pop];
        [MBProgressHUD hideHUDForView:self.webView animated:YES];
    }
    
    [self updateControls];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"Web view URL: %@", request.URL);
    [self.delegate officeContentViewController:self didPresentURL:request.URL];
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.loading = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.loading = NO;
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
