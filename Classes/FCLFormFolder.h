//
//  FCLFormFolder.h
//  facile
//
//  Created by Renaud Pradenc on 24/06/2019.
//

@import Foundation;
#import "FCLModel.h"

@class FCLForm;

@interface FCLFormFolder : FCLModel

-(nonnull instancetype)initWithTitle:(nonnull NSString *)title;
-(nonnull instancetype)init NS_UNAVAILABLE;

@property (readonly, nonnull) NSString *title;
@property (readonly, nonnull) NSArray <FCLForm *> *forms;

@end

