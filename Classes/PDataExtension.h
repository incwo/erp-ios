//
//  PDataExtension.h

//
//

#import <Foundation/Foundation.h>

@protocol PAsynchronousDataDelegate
@optional
// implement one of the two. Only the most complete is called if you implement both 
- (void) data:(NSData*)data didDownloadFromURL:(NSURL*)url withError:(NSError*)error;
- (void) data:(NSData*)data didDownloadFromURL:(NSURL*)url withError:(NSError*)error httpStatusCode:(NSInteger)statusCode;
// you may also implement this if you need auth
- (void) connectionForURL:(NSURL*)url didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
@end

@interface NSData(PDataExtension)
+ (void) downloadFromURL:(NSURL*)url delegate:(NSObject<PAsynchronousDataDelegate>*)delegate;
+ (void) downloadWithURLRequest:(NSURLRequest*)request delegate:(NSObject<PAsynchronousDataDelegate>*)delegate;
- (NSString*) hexString;
@end
