#import <Foundation/Foundation.h>

@interface PMultipartData : NSObject

// Optional boundary. If not specified, a good default value is used.
@property(nonatomic) NSString *boundary;

// Returns @"multipart/form-data; boundary=..."
@property(nonatomic, readonly) NSString *contentType;

// Appends text/plain values.
- (void) addString:(NSString *)string forKey:(NSString *)key;

// Appends string values and keys using addString:forKey:
- (void) addDictionary:(NSDictionary *)dict;

// Appends arbitrary file data. Filename is optional.
- (void) addData:(NSData *)data mimeType:(NSString *)mimeType filename:(NSString *)filename forKey:(NSString *)key;

// Returns fully formatted data. If nothing was added, the data is empty.
// You cannot add more data after sending this message.
- (NSData *) data;

@end
