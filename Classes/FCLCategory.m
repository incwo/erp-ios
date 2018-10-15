#import "FCLCategory.h"
#import "FCLField.h"

@interface FCLCategory ()

@property (readwrite) NSString *key;
@property (readwrite) NSString *name;
@property (readwrite) NSArray *fields;

@end

@implementation FCLCategory

- (BOOL) hasSignatureField
{
    for (FCLField* f in self.fields)
    {
        if ([f isSignature]) return YES;
    }
    return NO;
}

- (BOOL) wantsUploadPicture {
    return YES;
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
        if(self.fields == nil) {
            self.fields = [NSArray arrayWithObject:field];
        } else {
            self.fields = [self.fields arrayByAddingObject:field];
        }
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
