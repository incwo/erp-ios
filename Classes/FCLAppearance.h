//
//  FCLAppearance.h
//  facile
//
//  Created by Renaud Pradenc on 26/03/2018.
//

#import <Foundation/Foundation.h>

@interface FCLAppearance : NSObject

/// Apply the color scheme to various user interface elements
+(void) setup;

// MARK: Colors

/// A Light grey used for headers, etc.
+(UIColor *) lightGrey;

/// A Dark grey used for titles
+(UIColor *) darkGrey;

/// A blue used for highlighting.
+(UIColor *) blue;

/// A red used to attract the user's attention.
+(UIColor *) red;

@end
