#import "FCLModel.h"
@interface FCLCategory : FCLModel

@property(nonatomic, strong) NSString* key;
@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSMutableArray* fields;

- (void) reset;

- (void) saveDefaults;
- (void) loadDefaults;

- (BOOL) hasSignatureField;
- (BOOL) wantsUploadPicture;

@end
