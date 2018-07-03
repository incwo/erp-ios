#import "FCLModel.h"
@interface FCLField : FCLModel<UITextFieldDelegate, UITextViewDelegate>

@property(nonatomic, strong) NSString* key;
@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSString* type;
@property(nonatomic, strong) NSString* fieldDescription;
@property(nonatomic, strong) UIImage* image;
@property(nonatomic, strong) NSMutableArray* values;
@property(nonatomic, strong) NSMutableArray* valueTitles;

@property(nonatomic, strong) UITextField* textField;
@property(nonatomic, strong) UITextView* textView;
@property(nonatomic, strong) UIImageView* imageView;
@property(nonatomic, assign) NSInteger enumSelectionIndex;

- (NSString*) stringValue;
- (NSString*) textValue;
- (NSString*) enumValue;
- (NSString*) value;

- (BOOL) isString;
- (BOOL) isText;
- (BOOL) isNumeric;
- (BOOL) isEnum;
- (BOOL) isSignature;

- (void) reset;

- (void) saveDefaults;
- (void) loadDefaults;

@end
