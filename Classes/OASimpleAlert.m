#import "OASimpleAlert.h"

@implementation OASimpleAlert

+ (void) title:(NSString*)title message:(NSString*)message delegate:(id)delegate
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles:nil];
	[alert show];
}

+ (void) error:(NSError*)error
{
    [self title:[error localizedDescription]
        message:[error localizedFailureReason]
       delegate:nil];
}


@end
