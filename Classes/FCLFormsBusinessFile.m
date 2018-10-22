#import "FCLFormsBusinessFile.h"
#import "FCLForm.h"

@interface FCLFormsBusinessFile ()

@property (nonnull, readwrite) NSString *identifier;
@property (nonnull, readwrite) NSString *name;
@property (nonnull, readwrite) NSString *kind;
@property (nonnull, readwrite) NSArray <FCLForm *> *forms;

@end


@implementation FCLFormsBusinessFile

- (BOOL)isEqual:(id)anObject {
    FCLFormsBusinessFile *other = (FCLFormsBusinessFile *)anObject;
    if(other == self) {
        return YES;
    }
    
    if (![anObject isKindOfClass:[FCLFormsBusinessFile class]]) return NO;
    
    return [self.identifier isEqualToString:other.identifier] && [self.forms isEqualToArray:other.forms];
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
        FCLForm *form = [[FCLForm alloc] init];
        form.parentNode = self;
        if(self.forms) {
            self.forms = [self.forms arrayByAddingObject:form];
        } else {
            self.forms = [NSArray arrayWithObject:form];
        }
        
        [parser setDelegate:form];
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
