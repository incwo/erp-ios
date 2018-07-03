@class OAPath;

@class FCLHandDrawingView;
@protocol FCLHandDrawingViewDelegate <NSObject>
@optional
- (void) handDrawingViewDidDraw:(FCLHandDrawingView*)drawingView;
- (void) handDrawingViewDidClean:(FCLHandDrawingView*)drawingView;
@end

@interface FCLHandDrawingView : UIView

@property(nonatomic,weak) id<FCLHandDrawingViewDelegate> delegate;
@property(nonatomic,strong) UIImage* image;
@property(nonatomic,strong) NSMutableArray* currentPaths;
@property(nonatomic,strong) UIColor* penColor;
@property(nonatomic,assign) CGFloat lineWidth;
@property(nonatomic,assign) BOOL erasing;
@property(nonatomic,assign) BOOL dirty;

#pragma mark Actions

- (IBAction) choosePen;

- (IBAction) chooseBlackPen;
- (IBAction) chooseRedPen;
- (IBAction) chooseOrangePen;
- (IBAction) chooseYellowPen;
- (IBAction) chooseGreenPen;
- (IBAction) chooseBluePen;
- (IBAction) chooseRosePen;

- (IBAction) chooseEraser;
- (IBAction) erase;


#pragma mark Drawing

- (void) composeInContext:(CGContextRef) context inRect:(CGRect)rect;

@end
