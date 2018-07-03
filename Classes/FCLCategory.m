#import "FCLCategory.h"
#import "FCLField.h"

@implementation FCLCategory {
    NSString* key;
    NSString* name;
    NSMutableArray* fields;
}

@synthesize key;
@synthesize name;

@synthesize fields;
- (NSMutableArray*) fields
{
    if (!fields)
    {
        self.fields = [NSMutableArray array];
    }
    return fields;
}

- (BOOL) hasSignatureField
{
    for (FCLField* f in self.fields)
    {
        if ([f isSignature]) return YES;
    }
    return NO;
}

- (BOOL) wantsUploadPicture
{
    return YES;
// old debug:    return ![self hasSignatureField];
}

- (void) reset
{
    for (FCLField* field in self.fields)
    {
        [field reset];
    }
}

- (void) saveDefaults
{
    for (FCLField* field in self.fields)
    {
        [field saveDefaults];
    }
}

- (void) loadDefaults
{
    for (FCLField* field in self.fields)
    {
        [field loadDefaults];
    }
}


- (BOOL)isEqual:(id)anObject
{
    if (![anObject isKindOfClass:[FCLCategory class]]) return NO;
    FCLCategory* other = (FCLCategory*)anObject;
    return [self.key isEqualToString:other.key] && [self.fields isEqualToArray:other.fields];
}


#pragma mark NSXMLParser delegate


- (void)       parser:(NSXMLParser*) parser
      didStartElement:(NSString*) elementName
         namespaceURI:(NSString*) namespaceURI
        qualifiedName:(NSString*) qualifiedName
           attributes:(NSDictionary*) attributeDict
{
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qualifiedName attributes:attributeDict];
    if ([elementName isEqualToString:@"les_champs"]) // despite the plural name, it is a block for a single field
    {
        FCLField* field = [[FCLField alloc] init];
        field.parentNode = self;
        [self.fields addObject:field];
        [parser setDelegate:field];
    }
}

- (void)     parser:(NSXMLParser*) parser
      didEndElement:(NSString*) elementName
       namespaceURI:(NSString*) namespaceURI
      qualifiedName:(NSString*) qName
{
    if ([elementName isEqualToString:@"lobjet"])
    {
        self.name = self.currentStringDuringParsing;
    }
    else if ([elementName isEqualToString:@"la_classe"])
    {
        self.key = self.currentStringDuringParsing;
    }
    
    [super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
}


@end
