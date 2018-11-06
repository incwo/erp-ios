
#import "OAHTTPProtocols.h"

@interface OAHTTPQueue : NSObject <OAHTTPQueue>

@property(nonatomic,strong) NSMutableArray*    queue;
@property(nonatomic,strong) NSOperationQueue*  decodingQueue;
@property(nonatomic,strong) id<OAHTTPDownloadProtocol> currentDownload;
@property(nonatomic,weak) id<OAHTTPDownloadDelegate> delegate;
@property(nonatomic,weak) id<OAHTTPDownloadDelegate> downloadDelegate;

@end
