#import "FCLUploader.h"
@class FCLBusinessFile;
@class FCLFormController;

@interface FCLCategoriesController : UITableViewController

@property(nonatomic, strong) FCLBusinessFile* file;
@property(nonatomic, strong) FCLFormController* formController;

@property(nonatomic,strong) NSString* username;
@property(nonatomic,strong) NSString* password;

@end
