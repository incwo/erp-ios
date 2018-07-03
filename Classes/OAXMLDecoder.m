#import "OAXMLDecoder.h"

@interface OAXMLDecoder()

@property(nonatomic) NSMutableString *currentStringBuffer;
@property(nonatomic) NSMutableArray *startMapStack;
@property(nonatomic) NSMutableArray *endMapStack;
@property(nonatomic) NSMutableDictionary *currentStartMap; // elementName -> block
@property(nonatomic) NSMutableDictionary *currentEndMap; // elementName -> block

- (void) debugElementWithMessage:(NSString *)msg;

@end

@implementation OAXMLDecoder

+ (OAXMLDecoder *) parseData:(NSData *)data withBlock:(void(^)(OAXMLDecoder *))block
{
	OAXMLDecoder *decoder = [[self alloc] init];
	decoder.xmlData = data;
	[decoder decodeWithBlock:block];
	return decoder;
}

- (void) decodeWithBlock:(void(^)(OAXMLDecoder*))block
{
	[self decodeWithBlock:block endBlock:nil];
}

- (void) decodeWithBlock:(void(^)(OAXMLDecoder*))block endBlock:(void(^)(void))endBlock
{
	self.startMapStack = [NSMutableArray arrayWithCapacity:8];
	self.endMapStack   = [NSMutableArray arrayWithCapacity:8];
	
	self.xmlParser = [[NSXMLParser alloc] initWithData:self.xmlData];
	[self.xmlParser setShouldProcessNamespaces:YES];
	[self.xmlParser setShouldReportNamespacePrefixes:YES];
	[self.xmlParser setDelegate:self];
	
	self.currentStartMap = [NSMutableDictionary dictionary];
	self.currentEndMap   = [NSMutableDictionary dictionary];
	
	if (block) block(self);
	
	self.succeed = [self.xmlParser parse];
	
	if (!self.succeed)
	{
		self.error = [self.xmlParser parserError];
		NSLog(@"OAXMLDecoder failed to parse XML list");
	}
	
	if (endBlock) endBlock();
	
	// Cleanup possible referential cycles within blocks
	self.startMapStack = nil;
	self.endMapStack = nil;
	self.currentStartMap = nil;
	self.currentEndMap = nil;
	self.xmlParser = nil;
}

- (void) decodeWithObject:(id<NSObject>)rootObject startSelector:(SEL)startSelector // obsolete API
{
	[self decodeWithObject:rootObject startSelector:startSelector endSelector:NULL];
}

- (void) decodeWithObject:(id<NSObject>)rootObject startSelector:(SEL)startSelector endSelector:(SEL)endSelector // obsolete API
{
	[self decodeWithObject:rootObject startSelector:startSelector endBlock:^{
		if (endSelector)
		{
            // The compiler warns "PerformSelector may cause a leak because its selector is unknown".
            // I don't see any problem here since the return value is not used.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [rootObject performSelector:endSelector withObject:self];
#pragma clang diagnostic pop

		}
	}];
}

- (void) decodeWithObject:(id<NSObject>)rootObject startSelector:(SEL)startSelector endBlock:(void(^)(void))endBlock // obsolete API
{
	[self decodeWithBlock:^(OAXMLDecoder *decoder){
		if (startSelector)
		{
            // The compiler warns "PerformSelector may cause a leak because its selector is unknown".
            // I don't see any problem here since the return value is not used.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[rootObject performSelector:startSelector withObject:decoder];
#pragma clang diagnostic pop
		}
	} endBlock:endBlock];
}









#pragma mark Callbacks



- (void) parseElement:(NSString*)elementName startBlock:(void(^)(void))startBlock endBlock:(void(^)(void))endBlock
{
	startBlock = [startBlock copy];
	endBlock = [endBlock copy];
	[self startElement:elementName withBlock:startBlock];
	[self endElement:elementName withBlock:endBlock];
}

- (void) parseElements:(id<NSFastEnumeration>)elements startBlock:(void(^)(void))startBlock endBlock:(void(^)(void))endBlock
{
	startBlock = [startBlock copy];
	endBlock = [endBlock copy];
	[self startElements:elements withBlock:startBlock];
	[self endElements:elements withBlock:endBlock];
}



- (void) startElement:(NSString*)elementName withBlock:(void(^)(void))block
{
	if (!block) return;
	//NSLog(@"OAXMLDecoder: register block for start element: %@", elementName);
	if (self.caseInsensitive) elementName = [elementName lowercaseString];
	void(^existingBlock)(void) = [self.currentStartMap objectForKey:elementName];
	if (existingBlock)
	{
		block = [block copy];
		block = ^{
			existingBlock();
			block();
		};
	}
	[self.currentStartMap setObject:[block copy] forKey:elementName];
}

- (void) startOptionalElement:(NSString*)elementName withBlock:(void(^)(void))block
{
	[self startElement:elementName withBlock:block];
	block();
}

- (void) startElements:(id<NSFastEnumeration>)elements withBlock:(void(^)(void))block
{
	block = [block copy];
	for (NSString* element in elements)
	{
		[self startElement:element withBlock:block];
	}
}

- (void) startOptionalElements:(id<NSFastEnumeration>)elements withBlock:(void(^)(void))block
{
	[self startElements:elements withBlock:block];
	block();
}

- (void) endElement:(NSString*)elementName withBlock:(void(^)(void))block
{
	if (!block) return;
	//NSLog(@"OAXMLDecoder: register block for end element: %@", elementName);
	if (self.caseInsensitive) elementName = [elementName lowercaseString];
	void(^existingBlock)(void) = [self.currentEndMap objectForKey:elementName];
	if (existingBlock)
	{
		block = [block copy];
		block = ^{
			existingBlock();
			block();
		};
	}
	[self.currentEndMap setObject:[block copy] forKey:elementName];
}

- (void) endElements:(id<NSFastEnumeration>)elements withBlock:(void(^)(void))block
{
	block = [block copy];
	for (NSString* element in elements)
	{
		[self endElement:element withBlock:block];
	}
}





#pragma mark Accessors



- (NSString*) attributeForName:(NSString*)attrName
{
	return [self.currentAttributes objectForKey:attrName];
}

- (NSString*) currentString
{
	return [NSString stringWithString:self.currentStringBuffer];
}

- (NSString*) currentStringStripped
{
	return [self.currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString*) currentStringStrippedNilIfEmpty
{
	NSString* s = self.currentStringStripped;
	if (s.length == 0) return nil;
	return s;
}








#pragma mark NSXMLParserDelegate




- (void)       parser:(NSXMLParser*) parser 
      didStartElement:(NSString*) elementName
         namespaceURI:(NSString*) namespaceURI 
        qualifiedName:(NSString*) qualifiedName
           attributes:(NSDictionary*) attributesDict
{
	if (self.caseInsensitive) qualifiedName = [qualifiedName lowercaseString];
	
	if (self.qualifiedNameTransformer)
	{
		qualifiedName = self.qualifiedNameTransformer(qualifiedName);
	}

	//NSLog(@"OAXMLDecoder: start element %@", qualifiedName);
	
	if (self.traceParsing) [self debugElementWithMessage:[NSString stringWithFormat:@"<%@>", qualifiedName]];
	
	self.currentStringBuffer = [NSMutableString string];
	self.currentNamespaceURI = namespaceURI;
	self.currentQualifiedName = qualifiedName;
	self.currentAttributes = attributesDict;
	self.currentElementName = elementName;
	
	void(^startBlock)(void) = [self.currentStartMap objectForKey:qualifiedName];
	
	[self.startMapStack addObject:self.currentStartMap];
	[self.endMapStack addObject:self.currentEndMap];
	
	self.currentStartMap = [NSMutableDictionary dictionary];
	self.currentEndMap = [NSMutableDictionary dictionary];
	
	if (startBlock) startBlock(); // block fills in currentStartMap and currentEndMap
}



- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string 
{
	// TODO: provide a way for client to gather the whole content with a block here
	[self.currentStringBuffer appendString:string];
}



- (void)     parser:(NSXMLParser*) parser 
      didEndElement:(NSString*) elementName
       namespaceURI:(NSString*) namespaceURI
      qualifiedName:(NSString*) qualifiedName
{
	//NSLog(@"OAXMLDecoder: end element %@", qualifiedName);
	
	if (self.caseInsensitive) qualifiedName = [qualifiedName lowercaseString];
	
	if (self.qualifiedNameTransformer)
	{
		qualifiedName = self.qualifiedNameTransformer(qualifiedName);
	}

	NSMutableDictionary* startMap = [self.startMapStack lastObject];
	NSMutableDictionary* endMap = [self.endMapStack lastObject];
	
	// We do not keep a stack of the attributes, so they will be overwritten by nested tags.
	// Here we explicitly reject it to make sure client does not try to use it.
	// TODO: keep a stack of the attributes so we don't have this issue
	self.currentAttributes = nil;
	
	self.currentNamespaceURI = namespaceURI;
	self.currentQualifiedName = qualifiedName;
	self.currentElementName = elementName;
	
	void(^endBlock)(void) = [endMap objectForKey:qualifiedName];
	if (endBlock) endBlock();
	
	self.currentStartMap = startMap;
	self.currentEndMap = endMap;
	
	[self.startMapStack removeLastObject];
	[self.endMapStack removeLastObject];
	
	if (self.traceParsing) [self debugElementWithMessage:[NSString stringWithFormat:@"</%@>", qualifiedName]];
	
	self.currentStringBuffer = [NSMutableString string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	NSLog(@"OAXMLParser: NSXMLParser failed parsing. Error: %@; line: %ld:%ld", parseError, (long)[parser lineNumber], (long)[parser columnNumber]);
}

// Not invoked yet.
- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError
{
	
}




- (void) debugElementWithMessage:(NSString*)msg
{
	NSUInteger offset = [self.startMapStack count];
	NSMutableString* indentation = [NSMutableString string];
	
	while (offset--)
	{
		[indentation appendString:@"    "];
	}
	
	NSLog(@"%@: %@%@", [self class], indentation, msg);
}


@end
