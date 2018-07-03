#import "OAHTTPProtocols.h"

@class FCLUploader;
@protocol UploaderDelegate
- (void) uploaderDidUpdateStatus:(FCLUploader*)anUploader;
@end

@class FCLUpload;
@class OAHTTPQueue;
@interface FCLUploader : NSObject<OAHTTPDownloadDelegate>
{
  id<UploaderDelegate> __weak delegate;
  BOOL uploading;
  OAHTTPQueue* queue;
}

@property(nonatomic,weak) id<UploaderDelegate> delegate;
@property(nonatomic,strong) OAHTTPQueue* queue;

- (BOOL) isUploading;

- (void) start;
- (void) stop;

- (void) addUpload:(FCLUpload*)upload;

+ (FCLUploader*) sharedUploader;
+ (void) releaseSharedUploader;

@end

