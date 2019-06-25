//
//  FCLFormFolder.m
//  facile
//
//  Created by Renaud Pradenc on 24/06/2019.
//

#import "FCLForm.h"
#import "FCLFormFolder.h"

@interface FCLFormFolder ()

@property (readwrite, nonnull) NSArray <FCLForm *> *forms;

@end

@implementation FCLFormFolder

-(nonnull instancetype)initWithTitle:(nonnull NSString *)title
{
    NSParameterAssert(title);
    
    self = [super init];
    if (self) {
        _title = title;
        _forms = [NSArray array];
    }
    return self;
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
        self.forms = [self.forms arrayByAddingObject: form];
        [parser setDelegate:form];
    }
}

@end
