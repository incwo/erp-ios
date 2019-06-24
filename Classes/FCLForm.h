#import "FCLModel.h"

@class FCLField;

@interface FCLForm : FCLModel

// Properties set by parsing XML
@property (readonly) NSString *key;
@property (readonly) NSString *name;
@property (readonly) NSArray <FCLField *> *fields;

/// Calls -[reset] on all fields.
- (void) reset;

/// Calls -[saveDefaults] on all fields.
- (void) saveDefaults;

/// Calls -[loadDefaults] on all fields.
- (void) loadDefaults;

/// Returns true if any field returns true for -[isSignature].
- (BOOL) hasSignatureField;

/// Always returns YES.
- (BOOL) wantsUploadPicture;

@end
