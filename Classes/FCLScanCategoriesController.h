#import "FCLUploader.h"
@class FCLBusinessFile;
@class FCLFormController;

/// Presents the list of Scan forms
@interface FCLScanCategoriesController : UITableViewController

@property(nonatomic, strong) FCLBusinessFile* file;
@property(nonatomic, strong) FCLFormController* formController;

@property(nonatomic,strong) NSString* username;
@property(nonatomic,strong) NSString* password;

@end
