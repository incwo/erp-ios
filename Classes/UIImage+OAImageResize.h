@interface UIImage (OAImageResize)

- (UIImage*) OAImageScaledAndCroppedToSize:(CGSize) targetSize;
- (UIImage*) OAImageScaledAndCroppedToRect:(CGRect) targetRect;

- (UIImage*) OAImageScaledToFitWidth:(CGFloat) targetWidth;

@end
