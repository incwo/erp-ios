//
//  PDictionaryExtensions.h
//
//

#import <Foundation/Foundation.h>


@interface NSDictionary(PDictionaryExtensions)
- (id) firstObjectForKeys:(id)firstKey, ...;
@end
