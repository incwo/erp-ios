#import <QuartzCore/QuartzCore.h>

@interface OAPath : NSObject

@property(nonatomic,assign) CGMutablePathRef CGPath;
@property(nonatomic,assign) BOOL erasing;
@property(nonatomic,assign) BOOL smooth;
@property(nonatomic,strong) NSMutableArray* curves;
@property(nonatomic,strong) UITouch* touch;

@property(readonly) CGPoint currentPoint;

- (void) moveToPoint:(CGPoint) point;
- (void) addLineToPoint:(CGPoint) point;
- (void) addLineToPoint:(CGPoint) point skipDistance:(CGFloat)distance;

- (void) stroke;
- (void) strokeInContext:(CGContextRef)context;

@end
