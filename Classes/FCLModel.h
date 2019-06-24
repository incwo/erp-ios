@import Foundation;

@interface FCLModel : NSObject <NSXMLParserDelegate>

@property(nonatomic, strong) NSMutableString* currentStringDuringParsing;
@property(nonatomic, weak) id parentNode;

@end
