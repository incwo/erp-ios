//
//  FCLBusinessFilesFetch.h
//  facile
//
//  Created by Renaud Pradenc on 12/10/2018.
//

#import <Foundation/Foundation.h>
#import "FCLSession.h"
@class FCLBusinessFile;

@interface FCLBusinessFilesFetch : NSObject

typedef void (^FCLBusinessFilesFetchSuccess)( NSArray <FCLBusinessFile *> * _Nonnull businessFiles);
typedef void (^FCLBusinessFilesFetchFailure)( NSError * _Nonnull error);

-(nonnull instancetype) initWithSession:(nonnull FCLSession *)session;
-(nonnull instancetype) init NS_UNAVAILABLE;

-(void) fetchSuccess:(nonnull FCLBusinessFilesFetchSuccess)success failure:(nonnull FCLBusinessFilesFetchFailure)failure;

@end
