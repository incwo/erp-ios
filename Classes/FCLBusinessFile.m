#import "FCLBusinessFile.h"
#import "FCLCategory.h"

@interface FCLBusinessFile ()

@property (nonnull, readwrite) NSString *identifier;
@property (nonnull, readwrite) NSString *name;
@property (nonnull, readwrite) NSString *kind;
@property (nonnull, readwrite) NSArray <FCLCategory *> *categories;

@end


@implementation FCLBusinessFile

- (BOOL)isEqual:(id)anObject {
    FCLBusinessFile *other = (FCLBusinessFile *)anObject;
    if(other == self) {
        return YES;
    }
    
    if (![anObject isKindOfClass:[FCLBusinessFile class]]) return NO;
    
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
        if(self.categories) {
            self.categories = [self.categories arrayByAddingObject:category];
        } else {
            self.categories = [NSArray arrayWithObject:category];
        }
        
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
