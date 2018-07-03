#import "FCLBusinessFile.h"
#import "FCLCategory.h"

@implementation FCLBusinessFile {
    NSString* identifier;
    NSString* name;
    NSString* kind;
    NSMutableArray* categories;
}

@synthesize identifier;
@synthesize name;
@synthesize kind;

@synthesize categories;
- (NSMutableArray*) categories
{
    if (!categories)
    {
        self.categories = [NSMutableArray array];
    }
    return categories;
}


- (BOOL)isEqual:(id)anObject
{
    if (![anObject isKindOfClass:[FCLBusinessFile class]]) return NO;
    FCLBusinessFile* other = (FCLBusinessFile*)anObject;
    return [self.identifier isEqualToString:other.identifier] && [self.categories isEqualToArray:other.categories];
}



#pragma mark NSXMLParser delegate


- (void)       parser:(NSXMLParser*) parser
      didStartElement:(NSString*) elementName
         namespaceURI:(NSString*) namespaceURI
        qualifiedName:(NSString*) qualifiedName
           attributes:(NSDictionary*) attributeDict
{
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qualifiedName attributes:attributeDict];
    if ([elementName isEqualToString:@"object"])
    {
        FCLCategory* category = [[FCLCategory alloc] init];
        category.parentNode = self;
        [self.categories addObject:category];
        [parser setDelegate:category];
    }
}

- (void)     parser:(NSXMLParser*) parser
      didEndElement:(NSString*) elementName
       namespaceURI:(NSString*) namespaceURI
      qualifiedName:(NSString*) qName
{
    if ([elementName isEqualToString:@"id"])
    {
        self.identifier = self.currentStringDuringParsing;
    }
    else if ([elementName isEqualToString:@"name"])
    {
        self.name = self.currentStringDuringParsing;
    }
    else if ([elementName isEqualToString:@"kind"])
    {
        self.kind = self.currentStringDuringParsing;
    }
    
    [super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
}

@end
