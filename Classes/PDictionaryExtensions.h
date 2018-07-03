//
//  PDictionaryExtensions.h
//
//

#import <Foundation/Foundation.h>


@interface NSDictionary(PDictionaryExtensions)
- (NSDictionary*) dictionaryByAddingObject:(id)object forKey:(id)key;
- (NSDictionary*) dictionaryByRemovingObjectForKey:(id)key;
- (id) firstObjectForKeys:(id)firstKey, ...;
@end
