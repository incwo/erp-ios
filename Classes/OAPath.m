#import "OAPath.h"
#import "CG+OAHelpers.h"

@implementation OAPath

@synthesize erasing;
@synthesize CGPath;
@synthesize smooth;
@synthesize curves;
@synthesize touch;
@dynamic currentPoint;



#pragma mark Init


- (CGMutablePathRef) CGPath
{
    if (!CGPath)
    {
        CGPath = CGPathCreateMutable();
    }
    return CGPath;
}

- (void) setCGPath:(CGMutablePathRef)newPath
{
    if (newPath != CGPath)
    {
        CGPathRelease(CGPath);
        CGPath = newPath ? CGPathCreateMutableCopy(newPath) : nil;
    }
}

- (NSMutableArray*) curves
{
    if (!curves)
    {
        self.curves = [NSMutableArray array];
    }
    return curves;
}

- (CGPoint) currentPoint
{
    return CGPathGetCurrentPoint(self.CGPath);
}

- (void) dealloc
{
}





#pragma mark Actions


- (void) moveToPoint:(CGPoint) point
{
    CGPathMoveToPoint(self.CGPath, nil, point.x, point.y);
    if (smooth)
    {
        [self.curves addObject:[NSMutableArray arrayWithObject:[NSValue valueWithCGPoint:point]]];
    }
}

- (void) addLineToPoint:(CGPoint) point
{
    CGPathAddLineToPoint(self.CGPath, nil, point.x, point.y);
    if (smooth)
    {
        if (![self.curves lastObject])
        {
            [self.curves addObject:[NSMutableArray array]];
        }
        [[self.curves lastObject] addObject:[NSValue valueWithCGPoint:point]];
    }
}

- (void) addLineToPoint:(CGPoint) point skipDistance:(CGFloat)distance
{
    CGPoint lastPoint = CGPathGetCurrentPoint(self.CGPath);
    if (OACGSquareDistanceFromPoint(lastPoint, point) > distance*distance)
    {
        [self addLineToPoint:point];
    }
}

- (void) stroke
{
    [self strokeInContext:UIGraphicsGetCurrentContext()];
}

- (void) strokeInContext:(CGContextRef)context
{
    if (smooth)
    {
        for (NSMutableArray* points in self.curves)
        {
            CGContextBeginPath(context);
            NSUInteger pointsCount = [points count];
            if (pointsCount > 0)
            {
                if (pointsCount <= 1)
                {
                    CGPoint point = [[points objectAtIndex:0] CGPointValue];
                    CGContextMoveToPoint(context, point.x, point.y);
                    CGContextAddLineToPoint(context, point.x, point.y);
                }
                else // smooth the line
                {
                    CGPoint point1;
                    CGPoint pointA; // the point in between
                    CGPoint point2;
                    
                    // 1. Draw a straight line to the middle of the first segment
                    point1 = [[points objectAtIndex:0] CGPointValue];
                    point2 = [[points objectAtIndex:1] CGPointValue];
                    pointA = OACGPointBetweenPoints(point1, point2);
                    CGContextMoveToPoint(context, point1.x, point2.y);
                    CGContextAddLineToPoint(context, pointA.x, pointA.y);
                    
                    // 2. Draw quadratic bezier arcs around each inner point
                    point1 = point2;
                    for (NSUInteger index = 1; index < (pointsCount-1); index++)
                    {
                        point2 = [[points objectAtIndex:index+1] CGPointValue];
                        pointA = OACGPointBetweenPoints(point1, point2);
                        
                        CGContextAddQuadCurveToPoint(context, point1.x, point1.y, pointA.x, pointA.y);
                        
                        point1 = point2;
                    }
                    
                    // 3. Draw a straight line from the middle of the last segment to the end
                    point2 = [[points objectAtIndex:pointsCount - 1] CGPointValue];
                    CGContextAddLineToPoint(context, point2.x, point2.y);
                } // pointsCount <= 1
            } // any points
            
            CGContextDrawPath(context, kCGPathStroke);
        } // for each line
    }
    else // not smooth
    {
        CGContextBeginPath(context);
        CGContextAddPath(context, self.CGPath);
        CGContextDrawPath(context, kCGPathStroke);    
    }
}

@end
