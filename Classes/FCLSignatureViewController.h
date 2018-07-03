
@interface FCLSignatureViewController : UIViewController

@property(nonatomic, readonly) UILabel* descriptionLabel;
@property(nonatomic, strong) void(^completionBlock)(UIImage*); // screenshot image (or nil if cancelled)

@end
