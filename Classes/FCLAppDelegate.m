#import "FCLAppDelegate.h"
#import "FCLAppearance.h"
#import "FCLScanViewController.h"
#import "FCLOfficeContentViewController.h"
#import "FCLVideosViewController.h"
#import "FCLNewsViewController.h"

#import "FCLUploader.h"

#import "PHTTPConnection.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>


@interface FCLAppDelegate ()
@end

@implementation FCLAppDelegate {
    UITabBarController*      _tabBarController;
    FCLOfficeContentViewController* _officeController;
    FCLScanViewController*      _scanController;
    FCLVideosViewController* _videosController;
    FCLNewsViewController*   _newsController;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    [PHTTPConnection setSSLTrustedHosts:@[ FACILE_HOSTNAME, FACILE_HOSTNAME_DEV ]];
    
    // WebView causes memory leaks without this configuration.
    // See http://discussions.apple.com/thread.jspa?threadID=1785052
    // Also without this NSURLConnection caches everything
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    
    [[FCLUploader sharedUploader] start];
    
    [FCLAppearance setup];
    
    // Fabric insists that its framework must be the last one initalized, since it catches exceptions.
    NSDictionary *fabricDic = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Fabric"];
    NSString *fabricAPIKey = fabricDic[@"APIKey"];
    if(fabricAPIKey.length > 0) {
        // Only init if the key is set in info.plist.
        // The key is set at build time using a script.
        // We did not open-source our key, for good reasons!
        [Fabric with:@[[Crashlytics class]]];
    }
    
    // Init 4 tabs: Work, Scan, Videos, News.
    _officeController = [[FCLOfficeContentViewController alloc] initWithNibName:nil bundle:nil];
    _officeController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Bureau" image:[UIImage imageNamed:@"FCLTabBarOffice"] selectedImage:[UIImage imageNamed:@"FCLTabBarOfficeSelected"]];
    
    _scanController   = [[FCLScanViewController alloc] initWithNibName:nil bundle:nil];
    _scanController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Scan" image:[UIImage imageNamed:@"FCLTabBarScan"] selectedImage:[UIImage imageNamed:@"FCLTabBarScanSelected"]];
    
    _videosController = [FCLVideosViewController catalogController];
    _videosController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Vidéos" image:[UIImage imageNamed:@"FCLTabBarVideos"] selectedImage:[UIImage imageNamed:@"FCLTabBarVideosSelected"]];
    
    _newsController   = [[FCLNewsViewController alloc] initWithNibName:nil bundle:nil];
    _newsController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Actualités" image:[UIImage imageNamed:@"FCLTabBarNews"] selectedImage:[UIImage imageNamed:@"FCLTabBarNewsSelected"]];
    
    _tabBarController = [[UITabBarController alloc] init];
    _tabBarController.viewControllers = @[
        [[UINavigationController alloc] initWithRootViewController:_officeController],
        [[UINavigationController alloc] initWithRootViewController:_scanController],
        [[UINavigationController alloc] initWithRootViewController:_videosController],
        [[UINavigationController alloc] initWithRootViewController:_newsController]
    ];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[_window setRootViewController:_tabBarController];
    [_window makeKeyAndVisible];
    
	return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[FCLUploader sharedUploader] stop];
    
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
    NSLog(@"applicationWillEnterForeground:");
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
    NSLog(@"applicationDidEnterBackground:");
}

- (void)dealloc
{
    [FCLUploader releaseSharedUploader];
}


@end





@implementation UITabBarController(FCLOrientation)

- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger mask = UIInterfaceOrientationPortrait;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        mask = UIInterfaceOrientationMaskAllButUpsideDown;
    
    for (UIViewController* vc in self.viewControllers)
    {
        mask = mask & [vc supportedInterfaceOrientations];
    }
    return mask | UIInterfaceOrientationMaskPortrait;
}

@end


@implementation UINavigationController(FLCOrientation)
/*
- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger mask = UIInterfaceOrientationPortrait;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        mask = UIInterfaceOrientationMaskAllButUpsideDown;

    return mask;
//    return [[self.viewControllers lastObject] supportedInterfaceOrientations] | UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return self.interfaceOrientation;
//    return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}

*/
@end


// http://stackoverflow.com/questions/12522491/crash-on-presenting-uiimagepickercontroller-under-ios-6-0
@implementation UIImagePickerController(FLCOrientation)

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end



