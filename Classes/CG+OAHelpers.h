
CGFloat OACGSquareDistanceFromPoint(CGPoint point1, CGPoint point2);

CGPoint OACGPointShift(CGPoint point, CGFloat dx, CGFloat dy);
CGPoint OACGPointBetweenPoints(CGPoint point1, CGPoint point2);
CGPoint OACGPointBetweenPointsWithRatio(CGPoint point1, CGPoint point2, CGFloat ratio);
CGPoint OADifferenceBetweenPoints(CGPoint point1, CGPoint point2);
CGPoint OACGPointMultipliedBy(CGPoint point, CGFloat ratio);

CGRect OACGRectAroundPoint(CGPoint point, CGFloat width, CGFloat height);
CGRect OACGSquareAroundPoint(CGPoint point, CGFloat width);
CGRect OACGRectContainingPoints(CGPoint point1, CGPoint point2);