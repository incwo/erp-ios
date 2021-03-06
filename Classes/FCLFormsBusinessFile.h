#import "FCLModel.h"

@interface FCLFormsBusinessFile : FCLModel

// Initialized through XML parsing

@property (nonnull, readonly) NSString *identifier;
@property (nonnull, readonly) NSString *name;
@property (nonnull, readonly) NSString *kind; // Like a subtitle. Shown to the user.
@property (nonnull, readonly) NSArray *children; // FCLForm or FCLFormFolder

@end
