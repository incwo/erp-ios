#import "OAHTTPProtocols.h"

@class FCLUploader;
@protocol FCLUploaderDelegate

-(void) uploaderDidUpdateStatus:(FCLUploader *)uploader;
-(void) uploader:(FCLUploader *)uploader didFailWithError:(NSError *)error;

@end

@class FCLUpload;
@class OAHTTPQueue;
@interface FCLUploader : NSObject<OAHTTPDownloadDelegate>
{
  id<FCLUploaderDelegate> __weak delegate;
  BOOL uploading;
  OAHTTPQueue* queue;
}

@property(nonatomic,weak) id<FCLUploaderDelegate> delegate;
@property(nonatomic,strong) OAHTTPQueue* queue;

- (BOOL) isUploading;

- (void) start;
- (void) stop;

- (void) addUpload:(FCLUpload*)upload;

+ (FCLUploader*) sharedUploader;
+ (void) releaseSharedUploader;

@end

