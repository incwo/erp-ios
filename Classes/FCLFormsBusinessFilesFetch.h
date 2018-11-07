//
//  FCLFormsBusinessFilesFetch.h
//  facile
//
//  Created by Renaud Pradenc on 12/10/2018.
//

#import <Foundation/Foundation.h>
#import "FCLSession.h"
@class FCLFormsBusinessFile;

@interface FCLFormsBusinessFilesFetch : NSObject

typedef void (^FCLFormsBusinessFilesFetchSuccess)( NSArray <FCLFormsBusinessFile *> * _Nonnull businessFiles);
typedef void (^FCLFormsBusinessFilesSingleFetchSuccess)(FCLFormsBusinessFile * _Nonnull businessFile);
typedef void (^FCLFormsBusinessFilesFetchFailure)( NSError * _Nonnull error);

-(nonnull instancetype) initWithSession:(nonnull FCLSession *)session;
-(nonnull instancetype) init NS_UNAVAILABLE;

-(void) fetchAllSuccess:(nonnull FCLFormsBusinessFilesFetchSuccess)success failure:(nonnull FCLFormsBusinessFilesFetchFailure)failure;
-(void) fetchOneWithId:(nonnull NSString *)identifier success:(nonnull FCLFormsBusinessFilesSingleFetchSuccess)successHandler failure:(nonnull FCLFormsBusinessFilesFetchFailure)failureHandler;

@end
