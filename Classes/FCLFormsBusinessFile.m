#import "FCLFormsBusinessFile.h"
#import "FCLForm.h"
#import "FCLFormFolder.h"

@interface FCLFormsBusinessFile ()

@property (nonnull, readwrite) NSString *identifier;
@property (nonnull, readwrite) NSString *name;
@property (nonnull, readwrite) NSString *kind;
@property (nonnull, readwrite) NSArray *children;

@end


@implementation FCLFormsBusinessFile

- (BOOL)isEqual:(id)anObject {
    FCLFormsBusinessFile *other = (FCLFormsBusinessFile *)anObject;
    if(other == self) {
        return YES;
    }
    
    if (![anObject isKindOfClass:[FCLFormsBusinessFile class]]) return NO;
    
    return [self.identifier isEqualToString:other.identifier] && [self.children isEqualToArray:other.children];
}

#pragma mark NSXMLParser delegate


- (void)       parser:(NSXMLParser*) parser
      didStartElement:(NSString*) elementName
         namespaceURI:(NSString*) namespaceURI
        qualifiedName:(NSString*) qualifiedName
           attributes:(NSDictionary*) attributeDict
{
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qualifiedName attributes:attributeDict];
    if ([elementName isEqualToString:@"object"]) // Form
    {
        FCLForm *form = [[FCLForm alloc] init];
        form.parentNode = self;
        [self addChild:form];
        [parser setDelegate:form];
    } else if([elementName isEqualToString:@"folder"]) {
        NSString *title = attributeDict[@"title"];
        if(title == nil) {
            NSLog(@"%s The <folder> XML tag has not title. Adopting a default one.", __PRETTY_FUNCTION__);
            title = @"Dossier";
        }
        FCLFormFolder *folder = [[FCLFormFolder alloc] initWithTitle:title];
        folder.parentNode = self;
        [self addChild:folder];
        [parser setDelegate:folder];
    }
}

-(void) addChild:(id)child {
    if(self.children) {
        self.children = [self.children arrayByAddingObject:child];
    } else {
        self.children = [NSArray arrayWithObject:child];
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
