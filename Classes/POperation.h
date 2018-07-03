// NSOperation-compatible API

#import <Foundation/Foundation.h>

@protocol POperation <NSObject>
@required

typedef void (^POperationCompletion)(void);

// Run once the operation is finished (see isFinished below)
@property (nonatomic, copy) POperationCompletion completionBlock;

// NO if the operation has not been started or is already finished; otherwise, YES.
- (BOOL)isExecuting;

// YES if the operation has been cancelled; otherwise, NO.
- (BOOL)isCancelled;

// YES if the operation has completed, or has been cancelled; otherwise, NO.
- (BOOL)isFinished;

// if the receiver is already finished, this method is a noop.
- (void)start;

// if the receiver is already finished, this method is a noop.
- (void)cancel;
@end
