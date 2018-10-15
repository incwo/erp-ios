#import "FCLField.h"

@interface FCLField ()

@property (readwrite) FCLFieldType type;

@end

@implementation FCLField

- (id) init
{
    if (self = [super init])
    {
        [self reset];
    }
    return self;
}

- (NSArray*) values
{
    if (!_values)
    {
        self.values = [NSMutableArray array];
    }
    return _values;
}

- (NSArray*) valueTitles
{
    if (!_valueTitles)
    {
        self.valueTitles = [NSMutableArray array];
    }
    return _valueTitles;
}


#pragma mark - Remembering defaults


- (NSString*) defaultsKey
{
    return [NSString stringWithFormat:@"Field:%@", [self key]];
}

- (void) saveDefaults
{
    if(self.type == FCLFieldTypeEnum)
    {
        [[NSUserDefaults standardUserDefaults] setInteger:_enumSelectionIndex forKey:[self defaultsKey]];
    }
}

- (void) loadDefaults
{
    if ((self.type == FCLFieldTypeEnum) && [[NSUserDefaults standardUserDefaults] objectForKey:[self defaultsKey]])
    {
        self.enumSelectionIndex = [[NSUserDefaults standardUserDefaults] integerForKey:[self defaultsKey]];
    }
}




#pragma mark - Value UI elements


- (UITextField*) textField
{
    if (!_textField)
    {
        self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100.0, 20.0)];
        _textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _textField.delegate = self;
        _textField.returnKeyType = UIReturnKeyDone;
        if(self.type == FCLFieldTypeNumeric)
        {
            _textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        }
    }
    return _textField;
}

- (UITextView*) textView
{
    if (!_textView)
    {
        self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 100.0, 20.0)];
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _textView.font = self.textField.font;
        _textView.delegate = self;
        _textView.returnKeyType = UIReturnKeyDone;
    }
    return _textView;
}

- (void) reset
{
    self.textField = nil;
    self.textView = nil;
    self.enumSelectionIndex = -1;
}

- (BOOL)isEqual:(id)anObject
{
    if (![anObject isKindOfClass:[FCLField class]]) return NO;
    FCLField* other = (FCLField*)anObject;
    return [self.key isEqualToString:other.key] &&
    self.type == other.type &&
    [self.values isEqualToArray:other.values];
}



#pragma mark Value accessors

- (NSString*) stringValue
{
    return self.textField.text;
}

- (NSString*) textValue
{
    return self.textView.text;
}

- (NSString*) enumValue
{
    if (self.enumSelectionIndex >= 0 && self.values && [self.values count] > self.enumSelectionIndex)
    {
        return [self.values objectAtIndex:self.enumSelectionIndex];
    }
    return nil;
}

-(NSString *)value {
    switch (self.type) {
        case FCLFieldTypeString:
        case FCLFieldTypeNumeric:
            return [self stringValue];
            break;
        case FCLFieldTypeText:
            return [self textValue];
            break;
        case FCLFieldTypeEnum:
            return [self enumValue];
            break;
        default:
            return nil;
            break;
    }
}


#pragma mark - NSXMLParser delegate


- (void)       parser:(NSXMLParser*) parser
      didStartElement:(NSString*) elementName
         namespaceURI:(NSString*) namespaceURI
        qualifiedName:(NSString*) qualifiedName
           attributes:(NSDictionary*) attributeDict
{
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qualifiedName attributes:attributeDict];
    
    if ([elementName isEqualToString:@"la_valeur"])
    {
        [self.values addObject:[attributeDict objectForKey:@"key"]];
    }
}

- (void)     parser:(NSXMLParser*) parser
      didEndElement:(NSString*) elementName
       namespaceURI:(NSString*) namespaceURI
      qualifiedName:(NSString*) qName
{
    if ([elementName isEqualToString:@"le_nom"])
    {
        self.name = self.currentStringDuringParsing;
    }
    else if ([elementName isEqualToString:@"le_champ"])
    {
        self.key = self.currentStringDuringParsing;
    }
    else if ([elementName isEqualToString:@"le_type"])
    {
        self.type = [[self class] typeFromTypeString:self.currentStringDuringParsing];
    }
    else if ([elementName isEqualToString:@"la_valeur"])
    {
        [self.valueTitles addObject:self.currentStringDuringParsing];
    }
    else if ([elementName isEqualToString:@"description"])
    {
        self.fieldDescription = self.currentStringDuringParsing;
    }
    
    [super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
}

+(FCLFieldType) typeFromTypeString:(NSString *)typeString {
    if([typeString isEqualToString:@"string"]) {
        return FCLFieldTypeString;
    } else if([typeString isEqualToString:@"text"]) {
        return FCLFieldTypeText;
    } else if([typeString isEqualToString:@"numeric"]) {
        return FCLFieldTypeNumeric;
    } else if([typeString isEqualToString:@"enum"]) {
        return FCLFieldTypeEnum;
    } else if([typeString isEqualToString:@"signature"]) {
        return FCLFieldTypeSignature;
    } else if([typeString isEqualToString:@"my_signature"]) {
        return FCLFieldTypeSignature;
    } else {
        NSLog(@" %s: Unknown type: %@", __PRETTY_FUNCTION__, typeString);
        return FCLFieldTypeUnknown;
    }
}
       
#pragma mark UITextFieldDelegate


- (BOOL) textFieldShouldReturn:(UITextField *)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
}


#pragma mark UITextViewDelegate


- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (range.length == 0 && [text isEqualToString:@"\n"]) // user entered "Return" key
    {
        [aTextView resignFirstResponder];
        return NO;
    }
    return YES;
}


@end
