#import "UIImage+OAImageResize.h"

@implementation UIImage (OAImageResize)

- (UIImage*) OAImageScaledAndCroppedToSize:(CGSize) targetSize
{
    CGSize currentSize = self.size;
    if (CGSizeEqualToSize(currentSize, targetSize)) return self;
    
    CGRect targetRect = CGRectMake(0, 0, targetSize.width, targetSize.height);
    
    UIGraphicsBeginImageContext(targetSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    CGContextClipToRect(context, targetRect);
    
    CGFloat maxSide = (currentSize.height > currentSize.width ? currentSize.height : currentSize.width);
    
    CGFloat dx = targetSize.height * (currentSize.height - maxSide) / 2.0 / currentSize.height;
    CGFloat dy = targetSize.width  * (currentSize.width  - maxSide) / 2.0 / currentSize.width;
    
    [self drawInRect:CGRectInset(targetRect, dx, dy)];
    
    CGContextRestoreGState(context);
    UIImage* targetImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return targetImage;
}

- (UIImage*) OAImageScaledAndCroppedToRect:(CGRect) targetRect
{
    return [self OAImageScaledAndCroppedToSize:targetRect.size];
}

- (UIImage*) OAImageScaledToFitWidth:(CGFloat) targetWidth
{
    CGSize currentSize = self.size;
    if (currentSize.width <= targetWidth) return self;
    
    CGRect targetRect = CGRectMake(0, 0, targetWidth, currentSize.height * targetWidth/currentSize.width);
    CGSize targetSize = targetRect.size;
    
    UIGraphicsBeginImageContext(targetSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    
    [self drawInRect:targetRect];
    
    UIImage* targetImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return targetImage;
}

@end
