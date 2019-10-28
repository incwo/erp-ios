//
//  UIViewController+Alert.m
//  facile
//
//  Created by Renaud Pradenc on 14/08/2018.
//

#import "UIViewController+Alert.h"

@implementation UIViewController (Alert)

-(void) FCL_presentAlertForError:(NSError *)error {
    NSString *title;
    NSString *message;
    NSString *reason = [error localizedFailureReason];
    if(reason) {
        title = [error localizedDescription];
        message = reason;
    } else {
        title = @"Erreur";
        message = [error localizedDescription];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) FCL_presentAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
