@class FCLSession;
@class OAHTTPDownload;
@class FCLCategoriesController;

@interface FCLScanViewController : UIViewController

@property(nonatomic) FCLSession *session; // input

- (NSURL*) listURL;
- (void) loadList;
- (void) resetData;

@end
