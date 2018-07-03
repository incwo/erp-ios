#import "CG+OAHelpers.h"

CGFloat OACGSquareDistanceFromPoint(CGPoint point1, CGPoint point2)
{
  return (point1.x - point2.x)*(point1.x - point2.x) + (point1.y - point2.y)*(point1.y - point2.y);
}


CGPoint OACGPointShift(CGPoint point, CGFloat dx, CGFloat dy)
{
  point.x += dx;
  point.y += dy;
  return point;
}

CGPoint OACGPointBetweenPoints(CGPoint point1, CGPoint point2)
{
  return CGPointMake(0.5*(point1.x + point2.x), 0.5*(point1.y + point2.y));
}

CGPoint OACGPointBetweenPointsWithRatio(CGPoint point1, CGPoint point2, CGFloat ratio1)
{
  CGFloat ratio2 = 1.0 - ratio1;
  return CGPointMake(ratio1*point1.x + ratio2*point2.x, ratio1*point1.y + ratio2*point2.y);
}

CGPoint OADifferenceBetweenPoints(CGPoint point1, CGPoint point2)
{
  return CGPointMake(point2.x - point1.x, point2.y - point1.y);
}

CGPoint OACGPointMultipliedBy(CGPoint point, CGFloat ratio)
{
  return CGPointMake(point.x*ratio, point.y*ratio);
}

CGRect OACGRectAroundPoint(CGPoint point, CGFloat width, CGFloat height)
{
  return CGRectInset((CGRect){.origin = point}, -width*0.5, -height*0.5);
}

CGRect OACGSquareAroundPoint(CGPoint point, CGFloat width)
{
  return OACGRectAroundPoint(point, width, width);
}

CGRect OACGRectContainingPoints(CGPoint point1, CGPoint point2)
{
  return CGRectUnion((CGRect){.origin = point1}, (CGRect){.origin = point2});
}
