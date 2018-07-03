
@interface FCLAppDelegate : NSObject <UIApplicationDelegate>
@property(nonatomic,strong) IBOutlet UIWindow* window;
@end

@interface UITabBarController(FCLOrientation)
@end
@interface UINavigationController(FCLOrientation)
@end

// http://stackoverflow.com/questions/12522491/crash-on-presenting-uiimagepickercontroller-under-ios-6-0
@interface UIImagePickerController(FLCOrientation)
@end