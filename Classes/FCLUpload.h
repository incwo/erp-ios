@class OAHTTPDownload;
@interface FCLUpload : NSObject

@property(nonatomic,strong) NSString* fileId;
@property(nonatomic,strong) NSString* categoryKey;
@property(nonatomic,strong) UIImage* image;
@property(nonatomic,strong) NSArray* fields;

@property(nonatomic,strong) NSString* username;
@property(nonatomic,strong) NSString* password;

- (OAHTTPDownload *) OAHTTPDownload;

@end
