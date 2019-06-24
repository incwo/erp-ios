@import Foundation;

@class FCLFormsBusinessFile;

@interface FCLBusinessFilesParser : NSObject

+ (NSArray <FCLFormsBusinessFile *> *) businessFilesFromXMLData:(NSData*)data;

@end
