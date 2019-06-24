@import UIKit;

#import "FCLModel.h"

typedef enum : NSUInteger {
    FCLFieldTypeUnknown,
    FCLFieldTypeString,
    FCLFieldTypeText,
    FCLFieldTypeNumeric,
    FCLFieldTypeEnum,
    FCLFieldTypeSignature,
} FCLFieldType;

@interface FCLField : FCLModel<UITextFieldDelegate, UITextViewDelegate>

@property(nonatomic, strong) NSString* key;
@property(nonatomic, strong) NSString* name;
@property (readonly) FCLFieldType type;
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

- (void) reset;

- (void) saveDefaults;
- (void) loadDefaults;

@end
