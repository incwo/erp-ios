//
//  FCLFormsBusinessFilesFetch.m
//  facile
//
//  Created by Renaud Pradenc on 12/10/2018.
//

#import "FCLFormsBusinessFilesFetch.h"
#import "OAHTTPDownload.h"
#import "FCLBusinessFilesParser.h"

@interface FCLFormsBusinessFilesFetch () <OAHTTPDownloadDelegate>

@property FCLSession *session;
@property FCLFormsBusinessFilesFetchSuccess successHandler;
@property FCLFormsBusinessFilesFetchFailure failureHandler;

@property(nonatomic) OAHTTPDownload *download;

@end

@implementation FCLFormsBusinessFilesFetch

-(nonnull instancetype) initWithSession:(nonnull FCLSession *)session {
    self = [super init];
    if (self) {
        NSParameterAssert(session);
        _session = session;
    }
    return self;
}

- (void)dealloc
{
    [self.download cancel];
}

-(void) fetchAllSuccess:(FCLFormsBusinessFilesFetchSuccess)successHandler failure:(FCLFormsBusinessFilesFetchFailure)failureHandler {
    NSParameterAssert(successHandler);
    _successHandler = successHandler;
    NSParameterAssert(failureHandler);
    _failureHandler = failureHandler;
    
    [self.download cancel]; // The method might be called while still fetching
    [self loadBusinessFilesAtURL:[[self class] URLForSession:self.session]];
}

-(void) fetchOneWithId:(nonnull NSString *)identifier success:(nonnull FCLFormsBusinessFilesSingleFetchSuccess)successHandler failure:(nonnull FCLFormsBusinessFilesFetchFailure)failureHandler {
    NSParameterAssert(successHandler);
    _successHandler = ^(NSArray *businessFiles) {
        successHandler(businessFiles.count > 0 ? businessFiles[0] : nil);
    };
    NSParameterAssert(failureHandler);
    _failureHandler = failureHandler;
    
    [self.download cancel]; // The method might be called while still fetching
    [self loadBusinessFilesAtURL:[[self class] URLForSession:self.session businessFileId:identifier]];
}

- (void) loadBusinessFilesAtURL:(NSURL *)url {
    NSLog(@"Loading URL: %@", url);
    
    // Note: I avoid using iPhone NSURLConnection credentials API here to avoid unnecessary request
    //       This makes things 2 times faster on slow networks.
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    [request setFCLSession:self.session];
    
    self.download = [OAHTTPDownload downloadWithRequest:request];
    self.download.username = self.session.username;
    self.download.password = self.session.password;
    self.download.delegate = self;
    self.download.shouldAllowSelfSignedCert = YES;
    [self.download start];
}

+(NSURL *) URLForSession:(FCLSession *)session {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/account/get_files_and_image_enabled_objects/0.xml?r=%d", session.facileBaseURL, rand()]];
}

+(NSURL *) URLForSession:(FCLSession *)session businessFileId:(NSString *)businessFileId {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/account/get_files_and_image_enabled_objects/0.xml?r=%d&file_id=%@", session.facileBaseURL, rand(), businessFileId]];
}

// MARK: OAHTTPDownloadDelegate
- (void) oadownloadDidFinishLoading:(id<OAHTTPDownloadProtocol>)download {
    NSData *xmlData = download.receivedData;
    NSArray *businessFiles = [FCLBusinessFilesParser businessFilesFromXMLData:xmlData];
    if(businessFiles) {
        self.successHandler(businessFiles);
    } else {
        self.failureHandler([NSError errorWithDomain:@"Business Files" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Could not parse the Business Files XML data."}]);
    }
}
- (void) oadownload:(id<OAHTTPDownloadProtocol>)download didFailWithError:(NSError *)error {
    self.failureHandler(error);
}

@end
