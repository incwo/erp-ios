//
//  FCLAppearance.m
//  facile
//
//  Created by Renaud Pradenc on 26/03/2018.
//

#import "FCLAppearance.h"

@implementation FCLAppearance

+(void) setup {
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [self darkGrey]}];
    [[UINavigationBar appearance] setTintColor:[self blue]];
    
    [[UITabBar appearance] setTintColor:[self blue]];
}

// MARK: Colors

+(UIColor *) lightGrey {
    return [UIColor colorWithWhite:222.0/255.0 alpha:1.0];
}

+(UIColor *) darkGrey {
    return [UIColor colorWithWhite:65.0/255.0 alpha:1.0];
}

+(UIColor *) blue {
    return [UIColor colorWithRed:20.0/255.0 green:93.0/255.0 blue:151.0/255.0 alpha:1.0];
}

+(UIColor *) red {
    return [UIColor colorWithRed:218.0/255.0 green:79.0/255.0 blue:73.0/255.0 alpha:1.0];
}


@end
