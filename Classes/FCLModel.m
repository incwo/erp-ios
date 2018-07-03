#import "FCLModel.h"

@implementation FCLModel
{
    NSMutableString* currentStringDuringParsing;
    id __weak parentNode;
    int depth;
}

@synthesize currentStringDuringParsing;
@synthesize parentNode;



#pragma mark NSXMLParser delegate


- (void)       parser:(NSXMLParser*) parser
      didStartElement:(NSString*) elementName
         namespaceURI:(NSString*) namespaceURI
        qualifiedName:(NSString*) qualifiedName
           attributes:(NSDictionary*) attributeDict
{
    self.currentStringDuringParsing = nil;
    depth++;
}

- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
    if (!currentStringDuringParsing)
    {
        self.currentStringDuringParsing = [[NSMutableString alloc] initWithString:string];
    }
    else
    {
        [self.currentStringDuringParsing appendString:string];
    }
}

- (void)     parser:(NSXMLParser*) parser
      didEndElement:(NSString*) elementName
       namespaceURI:(NSString*) namespaceURI
      qualifiedName:(NSString*) qName
{
    self.currentStringDuringParsing = nil;
    depth--;
    // parser went outside of the scope of current element
    if (depth < 0)
    {
        // reset depth, reset delegate, resend event to the parent node for symmetry
        depth = 0;
        [parser setDelegate:self.parentNode];
        [self.parentNode parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
    }
}


@end
