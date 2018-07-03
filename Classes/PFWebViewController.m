//
//  PFWebViewController.m
//
//

#import "PFWebViewController.h"
#import "FCLSession.h"
#import "PXWWWFormSerialization.h"

@interface PFWebViewController ()<UIWebViewDelegate>
@property (nonatomic, weak) IBOutlet UIBarButtonItem *dismissBarButtonItem;
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic) BOOL needsUpdateWebView;
@end

@implementation PFWebViewController

- (NSURL *)URL
{
    return self.request.URL;
}

- (void)setURL:(NSURL *)URL
{
    self.request = [NSURLRequest requestWithURL:URL];
}

- (void)setRequest:(NSURLRequest *)request
{
    if (request != _request) {
        _request = [request copy];
        self.needsUpdateWebView = YES;
    }
}

- (void)setDismissBarButtonItemTitle:(NSString *)dismissBarButtonItemTitle
{
    if (_dismissBarButtonItemTitle != dismissBarButtonItemTitle) {
        _dismissBarButtonItemTitle = [dismissBarButtonItemTitle copy];
        [self updateDismissBarButtonItem];
    }
}


#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateDismissBarButtonItem];
    [self updateWebViewIfNeeded];
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *URL = request.URL;
    
    if ([[URL host] isEqualToString:@"facilepos.app"]) {
        NSArray *pathComponents = [URL pathComponents];
        
        if (pathComponents.count == 2 && [pathComponents[1] isEqualToString:@"signin"]) {
            //    http://facilepos.app/signin?email=<email>
            NSDictionary *parameters = [PXWWWFormSerialization dictionaryWithURL:URL options:0];
            NSString *email = parameters[@"email"];
            NSDictionary *userInfo = nil;
            if (email) {
                userInfo = @{ FCLSessionEmailKey: email };
            }
            [self dismissWithCompletionBlock:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:FCLSessionNeedsSignInNotification object:self userInfo:userInfo];
            }];
        }
        
        return NO;
    }
    
    return YES;
}


#pragma mark - Private

- (IBAction)dismiss:(id)sender
{
    [self dismissWithCompletionBlock:nil];
}

- (void)dismissWithCompletionBlock:(void(^)(void))completionBlock
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:completionBlock];
}

- (void)setNeedsUpdateWebView:(BOOL)needsUpdateWebView
{
    if (_needsUpdateWebView != needsUpdateWebView) {
        _needsUpdateWebView = needsUpdateWebView;
        if (_needsUpdateWebView) {
            if (self.isViewLoaded) {
                [self updateWebView];
            }
        }
    }
}

- (void)updateWebViewIfNeeded
{
    if (self.needsUpdateWebView) {
        [self updateWebView];
    }
}

- (void)updateWebView
{
    self.needsUpdateWebView = NO;
    
    if (self.request) {
        [self.webView loadRequest:self.request];
    }
}

- (void)updateDismissBarButtonItem
{
    if (self.dismissBarButtonItemTitle.length > 0) {
        self.dismissBarButtonItem.title = self.dismissBarButtonItemTitle;
    } else {
        self.dismissBarButtonItem.title = @"OK";
    }
}

@end
