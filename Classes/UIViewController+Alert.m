//
//  UIViewController+Alert.m
//  facile
//
//  Created by Renaud Pradenc on 14/08/2018.
//

#import "UIViewController+Alert.h"

@implementation UIViewController (Alert)

-(void) FCL_presentAlertForError:(NSError *)error {
    UIAlertController *alert = [[UIAlertController alloc] init];
    
    NSString *reason = [error localizedFailureReason];
    if(reason) {
        alert.title = [error localizedDescription];
        alert.message = reason;
        
    } else {
        alert.title = @"Erreur";
        alert.message = [error localizedDescription];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
