@interface FCLBusinessFilesList : NSObject<NSXMLParserDelegate>

@property(nonatomic, strong) NSMutableArray* businessFiles;

- (NSArray*) arrayOfBusinessFilesForXMLData:(NSData*)data;
+ (NSArray*) arrayOfBusinessFilesForXMLData:(NSData*)data;

@end
