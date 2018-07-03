#import "FCLBusinessFilesList.h"
#import "FCLBusinessFile.h"
@implementation FCLBusinessFilesList

+ (NSArray*) arrayOfBusinessFilesForXMLData:(NSData*)data
{
    return [[[self alloc] init] arrayOfBusinessFilesForXMLData:data];
}

- (NSArray*) arrayOfBusinessFilesForXMLData:(NSData*)data
{
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:data];
    
    [xmlParser setDelegate:self];
    
    self.businessFiles = [NSMutableArray array];
    
    BOOL success = [xmlParser parse];
    
    if (success)
    {
        return self.businessFiles;
    }
    else
    {
        NSLog(@"BusinessFilesList failed to parse XML list");
        return nil;
    }
}





#pragma mark NSXMLParser delegate

- (void)       parser:(NSXMLParser *)parser
      didStartElement:(NSString *)elementName
         namespaceURI:(NSString *)namespaceURI
        qualifiedName:(NSString *)qualifiedName
           attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"business_file"])
    {
        FCLBusinessFile* businessFile = [[FCLBusinessFile alloc] init];
        businessFile.parentNode = self;
        [self.businessFiles addObject:businessFile];
        [parser setDelegate:businessFile];
    }
}

- (void)     parser:(NSXMLParser*) parser
      didEndElement:(NSString*) elementName
       namespaceURI:(NSString*) namespaceURI
      qualifiedName:(NSString*) qName
{
}

@end
