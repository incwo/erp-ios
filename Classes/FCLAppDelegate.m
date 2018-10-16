#import "FCLAppDelegate.h"
#import "facilescan-Swift.h"
#import "FCLAppearance.h"
#import "FCLVideosViewController.h"
#import "FCLNewsViewController.h"

#import "FCLUploader.h"

#import "PHTTPConnection.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>


@interface FCLAppDelegate ()

@property (nonatomic) UITabBarController *tabBarController;
@property (nonatomic) AppRouter *appRouter;
@property (nonatomic) OfficeRouter *officeRouter;
@property (nonatomic) ScanRouter *scanRouter;
@property (nonatomic) FCLVideosViewController *videosController;
@property (nonatomic) FCLNewsViewController *newsController;

@end

@implementation FCLAppDelegate

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
    self.officeRouter = [[OfficeRouter alloc] init];
    self.officeRouter.navigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Bureau" image:[UIImage imageNamed:@"FCLTabBarOffice"] selectedImage:[UIImage imageNamed:@"FCLTabBarOfficeSelected"]];
    
    self.scanRouter = [[ScanRouter alloc] init];
    self.scanRouter.navigationController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Scan" image:[UIImage imageNamed:@"FCLTabBarScan"] selectedImage:[UIImage imageNamed:@"FCLTabBarScanSelected"]];
    
    self.videosController = [FCLVideosViewController catalogController];
    self.videosController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Vidéos" image:[UIImage imageNamed:@"FCLTabBarVideos"] selectedImage:[UIImage imageNamed:@"FCLTabBarVideosSelected"]];
    
    self.newsController   = [[FCLNewsViewController alloc] initWithNibName:nil bundle:nil];
    self.newsController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Actualités" image:[UIImage imageNamed:@"FCLTabBarNews"] selectedImage:[UIImage imageNamed:@"FCLTabBarNewsSelected"]];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[
        self.officeRouter.navigationController,
        self.scanRouter.navigationController,
        [[UINavigationController alloc] initWithRootViewController:self.videosController],
        [[UINavigationController alloc] initWithRootViewController:self.newsController]
    ];
    
    self.appRouter = [[AppRouter alloc] initWithOfficeRouter:self.officeRouter scanRouter:self.scanRouter];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[self.window setRootViewController:self.tabBarController];
    [self.window makeKeyAndVisible];
    
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



