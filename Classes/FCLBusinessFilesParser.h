@class FCLBusinessFile;

@interface FCLBusinessFilesParser : NSObject

+ (NSArray <FCLBusinessFile *> *) businessFilesFromXMLData:(NSData*)data;

@end
