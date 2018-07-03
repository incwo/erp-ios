//
//  PFWebViewController.h
//
//

#import <UIKit/UIKit.h>

@interface PFWebViewController : UIViewController
@property (nonatomic, copy) NSString *dismissBarButtonItemTitle;
@property (nonatomic) NSURL *URL;
@property (nonatomic, copy) NSURLRequest *request;
@end
