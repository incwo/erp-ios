//
//  FCLBusinessFilesFetch.m
//  facile
//
//  Created by Renaud Pradenc on 12/10/2018.
//

#import "FCLBusinessFilesFetch.h"
#import "OAHTTPDownload.h"
#import "FCLBusinessFilesParser.h"

@interface FCLBusinessFilesFetch () <OAHTTPDownloadDelegate>

@property FCLSession *session;
@property FCLBusinessFilesFetchSuccess successHandler;
@property FCLBusinessFilesFetchFailure failureHandler;

@property(nonatomic) OAHTTPDownload *download;

@end

@implementation FCLBusinessFilesFetch

-(nonnull instancetype) initWithSession:(nonnull FCLSession *)session {
    self = [super init];
    if (self) {
        NSParameterAssert(session);
        _session = session;
    }
    return self;
}

-(void) fetchSuccess:(FCLBusinessFilesFetchSuccess)successHandler failure:(FCLBusinessFilesFetchFailure)failureHandler {
    NSParameterAssert(successHandler);
    _successHandler = successHandler;
    NSParameterAssert(failureHandler);
    _failureHandler = failureHandler;
    
    [self.download cancel]; // The method might be called while still fetching
    [self loadBusinessFiles];
}

- (void) loadBusinessFiles {
    NSURL* url = [[self class] URLForSession:self.session];
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

// MARK: OAHTTPDownloadDelegate
- (void) oadownloadDidFinishLoading:(id<OAHTTPDownload>)download {
    NSData *xmlData = download.receivedData;
    NSArray *businessFiles = [FCLBusinessFilesParser businessFilesFromXMLData:xmlData];
    if(businessFiles) {
        self.successHandler(businessFiles);
    } else {
        self.failureHandler([NSError errorWithDomain:@"Business Files" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Could not parse the Business Files XML data."}]);
    }
}
- (void) oadownload:(id<OAHTTPDownload>)download didFailWithError:(NSError *)error {
    self.failureHandler(error);
}

@end
