#import "OAPath.h"
#import "FCLHandDrawingView.h"
#import "CG+OAHelpers.h"

@implementation FCLHandDrawingView

@synthesize image;
@synthesize currentPaths;
@synthesize penColor;
@synthesize lineWidth;
@synthesize erasing;

#pragma mark Init

- (id) initWithFrame:(CGRect)aframe
{
	if ((self = [super initWithFrame:aframe]))
	{
#if NUMBERLAND_APPLE_DEMO
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
	}
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]))
	{
#if NUMBERLAND_APPLE_DEMO
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
	}
	return self;
}

- (void) appDidEnterBackground:(NSNotification*)notif
{
	self.image = nil;
	self.currentPaths = nil;
	[self setNeedsDisplay];
}

- (UIImage*) image
{
    if (!image)
    {
        UIImage* anImage;
        UIGraphicsBeginImageContext(self.bounds.size);
        anImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.image = anImage;
    }
    return image;
}

- (CGFloat) lineWidth
{
    if (lineWidth == 0.0)
    {
        lineWidth = 1.0;
    }
    return lineWidth;
}

- (UIColor*) penColor
{
    if (!penColor)
    {
        self.penColor = [UIColor blackColor];
    }
    return penColor;
}

- (void) setErasing:(BOOL)f
{
    erasing = f;
    [self setNeedsDisplay];
}

- (NSMutableArray*) currentPaths
{
    if (!currentPaths)
    {
        self.currentPaths = [NSMutableArray array];
    }
    return currentPaths;
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}





#pragma mark Actions


- (IBAction) choosePen
{
    self.erasing = NO;
}

- (IBAction) chooseBlackPen
{
    [self choosePen];
    self.penColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.92];
}

- (IBAction) chooseRedPen
{
    [self choosePen];
    self.penColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.92];
}

- (IBAction) chooseOrangePen
{
    [self choosePen];
    self.penColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.1 alpha:0.92];
}

- (IBAction) chooseYellowPen
{
    [self choosePen];
    self.penColor = [UIColor colorWithRed:1.0 green:0.9 blue:0.1 alpha:0.92];
}

- (IBAction) chooseGreenPen
{
    [self choosePen];
    self.penColor = [UIColor colorWithRed:0.4 green:0.8 blue:0.0 alpha:0.92];
}

- (IBAction) chooseBluePen
{
    [self choosePen];
    self.penColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:0.92];
}

- (IBAction) chooseRosePen
{
    [self choosePen];
    self.penColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.7 alpha:0.92];
}


- (IBAction) chooseEraser
{
    self.erasing = YES;
}

- (IBAction) erase
{
    self.currentPaths = nil;
    self.image = nil;
    self.dirty = NO;
    [self setNeedsDisplay];
    if ([self.delegate respondsToSelector:@selector(handDrawingViewDidClean:)])
    {
        [self.delegate handDrawingViewDidClean:self];
    }
}



#pragma mark Touch events



- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    for (UITouch* touch in touches)
    {
        CGPoint point = [touch locationInView:self];
        
        OAPath* path = [[OAPath alloc] init];
        
        path.touch = touch;
        path.erasing = self.erasing;
        path.smooth = YES;
        
        [path moveToPoint:point];
        [path addLineToPoint:point];
        
        [self.currentPaths addObject:path];
        
        [self setNeedsDisplayInRect:OACGSquareAroundPoint(point, self.lineWidth*4)];
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    for (UITouch* touch in touches)
    {
        OAPath* thePath = nil;
        for (OAPath* path in self.currentPaths)
        {
            if (path.touch == touch)
            {
                thePath = path;
                break;
            }
        }
        if (thePath)
        {
            CGPoint point = [touch locationInView:self];
            CGPoint prevPoint = thePath.currentPoint;
            //[self.currentPath addLineToPoint:point];
            [thePath addLineToPoint:point skipDistance:15.0];
            
            // Note: this is not 100% accurate invalidation algorithm since the curve may be smoothed and go out of the rectangle
            [self setNeedsDisplayInRect:CGRectInset(OACGRectContainingPoints(point, prevPoint), -self.lineWidth*5 - 20.0, -self.lineWidth*5 - 20.0)];
        }
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    for (UITouch* touch in touches)
    {
        OAPath* thePath = nil;
        for (OAPath* path in self.currentPaths)
        {
            if (path.touch == touch)
            {
                thePath = path;
                break;
            }
        }
        if (thePath)
        {
            self.dirty = YES;
            
            CGPoint point = [touch locationInView:self];
            CGPoint prevPoint = thePath.currentPoint;
            
            [thePath addLineToPoint:point skipDistance:2.0];
            
            // Replace current image with a composition of the image and a current path
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
            [self composeInContext:UIGraphicsGetCurrentContext() inRect:self.bounds];
            self.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [self.currentPaths removeObject:thePath];
            
            // Note: this is not 100% accurate invalidation algorithm since the curve may be smoothed and go out of the rectangle
            [self setNeedsDisplayInRect:CGRectInset(OACGRectContainingPoints(point, prevPoint), -self.lineWidth*2, -self.lineWidth*2)];
            
            if ([self.delegate respondsToSelector:@selector(handDrawingViewDidDraw:)])
            {
                [self.delegate handDrawingViewDidDraw:self];
            }
        }
    }
    
    
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Replace current image with a composition of the image and a current path
    UIGraphicsBeginImageContext(self.bounds.size);
    [self composeInContext:UIGraphicsGetCurrentContext() inRect:self.bounds];
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.currentPaths = nil;
    
    [self setNeedsDisplay];
}




#pragma mark Drawing


- (void) composeInContext:(CGContextRef) context inRect:(CGRect)rect
{
    CGContextClipToRect(context, rect);
    CGContextBeginTransparencyLayerWithRect(context, rect, NULL); // preserve background color
    [self.image drawInRect:self.bounds];
    
    for (OAPath* path in self.currentPaths)
    {
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetLineCap(context, kCGLineCapRound);
        
        CGColorRef penCGColor = [self.penColor CGColor];
        CGColorRef eraserCGColor = [[UIColor blackColor] CGColor];
        
        CGBlendMode aBlendMode;
        CGColorRef aColor;
        if (path.erasing)
        {
            aColor = eraserCGColor;
            aBlendMode = kCGBlendModeDestinationOut; // R = D*(1 - Sa)
            CGContextSetLineWidth(context, self.lineWidth*2);
        }
        else
        {
            aColor = penCGColor;
            aBlendMode = kCGBlendModeNormal;
            CGContextSetLineWidth(context, self.lineWidth);
        }
        
        CGContextSetBlendMode(context, aBlendMode);
        CGContextBeginTransparencyLayerWithRect(context, rect, NULL); // when ended, the layer is composed using a blend mode
        CGContextSetStrokeColorWithColor(context, aColor);
        [path stroke];
        CGContextEndTransparencyLayer(context); // at this point the eraser is correctly blended with self.image
    }
    CGContextEndTransparencyLayer(context); // here the composition is normally blended to the view
}

- (void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self composeInContext:UIGraphicsGetCurrentContext() inRect:rect];
}







@end
