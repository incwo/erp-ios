
// November 30, 2010: Initial version.
// December 6,  2011: Added parseData:withBlock: API which is simpler and more useful.

/*
 This decoder builds a nice block-based API for the stream-based NSXMLParser.
 Basically, XPath ease of use meets performance of the stream-oriented parser.
 
 Quick start: 
 
	[OAXMLDecoder parseData:yourXMLData withBlock:^(OAXMLDecoder* decoder){
		[decoder startElement:@"root" withBlock:^{
			[decoder startElement:@"child" withBlock:^{
				[decoder endElement:@"name" withBlock:^{
					self.name = aDecoder.currentString;
				}];
				[decoder endElement:@"age" withBlock:^{
					self.age = aDecoder.currentString;
				}];
			}];
			[decoder startElement:@"another_object" withBlock:^{
				AnotherObject* anObject = [[AnotherObject new] autorelease];
				[anObject decodeWithDecoder:aDecoder]; // similar to the current method
			}];
		}];
	}];

 [OAXMLDecoder parseData:withBlock:] returns an instance of OAXMLDecoder containing error and options used for parsing.
 You may configure OAXMLDecoder inside that block, before sending startElement: and endElement: messages.
 
 The block passed with startElement:withBlock: is called when the tag is first time found.
 
 Q: How do I get a value from <name>Christophe</name>?
 A: [decoder endElement:@"name" withBlock:^{ self.name = decoder.currentString }];
 
 Q: This block-based xpath-like stream-friendly API was never done before?
 A: Pretty cool, huh :-)
 
*/


@interface OAXMLDecoder : NSObject<NSXMLParserDelegate>

@property(nonatomic) NSData *xmlData;
@property(nonatomic) NSXMLParser *xmlParser;
@property(nonatomic) NSDictionary *currentAttributes;
@property(nonatomic) NSString *currentQualifiedName;
@property(nonatomic) NSString *currentNamespaceURI;
@property(nonatomic) NSString *currentElementName;
@property(nonatomic) NSError *error;

@property(nonatomic, readonly) NSString *currentString;
@property(nonatomic, readonly) NSString *currentStringStripped;
@property(nonatomic, readonly) NSString *currentStringStrippedNilIfEmpty;

@property(nonatomic) NSString *(^qualifiedNameTransformer)(NSString *);

@property(nonatomic) BOOL caseInsensitive;
@property(nonatomic) BOOL succeed;
@property(nonatomic) BOOL traceParsing;

+ (OAXMLDecoder *) parseData:(NSData *)data withBlock:(void(^)(OAXMLDecoder *))block;

- (void) decodeWithBlock:(void(^)(OAXMLDecoder *))block;
- (void) decodeWithBlock:(void(^)(OAXMLDecoder *))block endBlock:(void(^)(void))endBlock;

- (void) decodeWithObject:(id<NSObject>)rootObject startSelector:(SEL)selector; // obsolete API
- (void) decodeWithObject:(id<NSObject>)rootObject startSelector:(SEL)startSelector endSelector:(SEL)endSelector; // obsolete API
- (void) decodeWithObject:(id<NSObject>)rootObject startSelector:(SEL)startSelector endBlock:(void(^)(void))endBlock; // obsolete API

- (void) parseElement:(NSString *)elementName startBlock:(void(^)(void))startBlock endBlock:(void(^)(void))endBlock;
- (void) parseElements:(id<NSFastEnumeration>)elements startBlock:(void(^)(void))startBlock endBlock:(void(^)(void))endBlock;
- (void) startElement:(NSString *)elementName withBlock:(void(^)(void))block;
- (void) startOptionalElement:(NSString *)elementName withBlock:(void(^)(void))block;
- (void) startElements:(id<NSFastEnumeration>)elements withBlock:(void(^)(void))block;
- (void) startOptionalElements:(id<NSFastEnumeration>)elements withBlock:(void(^)(void))block;
- (void) endElement:(NSString *)elementName withBlock:(void(^)(void))block;
- (void) endElements:(id<NSFastEnumeration>)elements withBlock:(void(^)(void))block;

- (NSString *) attributeForName:(NSString *)attrName;

@end
