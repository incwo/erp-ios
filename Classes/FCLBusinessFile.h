#import "FCLModel.h"
@interface FCLBusinessFile : FCLModel

@property(nonatomic, strong) NSString* identifier;
@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSString* kind;
@property(nonatomic, strong) NSMutableArray* categories;

@end
