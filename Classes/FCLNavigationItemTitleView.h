//
//  FCLNavigationItemTitleView.h
//  facile
//
//  Created by Renaud Pradenc on 18/04/2018.
//

#import <UIKit/UIKit.h>

/// This subclass of UIView is used as the titleView of a UINavigationItem.
/// It overrides -intrinsicContentSize so the view takes the full width of the navigation bar.
/// This is needed from iOS 11 on.
@interface FCLNavigationItemTitleView : UIView

@end
