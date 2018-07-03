#import "FCLVideoViewController.h"

@interface FCLVideoViewController ()

@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation FCLVideoViewController

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


// MARK: Videos

-(void) playVideoAtURL:(NSURL *)url {
    NSParameterAssert(url);
    NSAssert(self.webView, @"we should have loaded the view already");
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

// MARK: WebView

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
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
