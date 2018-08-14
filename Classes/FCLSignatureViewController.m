#import "FCLSignatureViewController.h"
#import "FCLHandDrawingView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+Alert.h"

@interface FCLSignatureViewController () <FCLHandDrawingViewDelegate>
@property(nonatomic, readwrite) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel *yourSignatureSubtitle;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UIImageView *sampleImageView;
@property (strong, nonatomic) IBOutlet FCLHandDrawingView *drawingView;
@end

@implementation FCLSignatureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"Signer", @"");
        [self updateClearButton];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneSignature:)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.drawingView.delegate = self;
    // Do any additional setup after loading the view from its nib.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    df.timeStyle = NSDateFormatterShortStyle;
    df.dateStyle = NSDateFormatterLongStyle;
    
    self.dateLabel.text = [df stringFromDate:[NSDate date]];
    
    self.sampleImageView.hidden = YES;
    self.sampleImageView.alpha = 0.0;
    
    for (CGFloat fontSize = 14; fontSize > 10.0; fontSize--)
    {
        self.descriptionLabel.font = [UIFont systemFontOfSize:fontSize];
        CGFloat maxHeight = 300.0;
        CGRect rect = self.descriptionLabel.frame;
        CGSize size = [self.descriptionLabel sizeThatFits:CGSizeMake(rect.size.width, maxHeight)];
        if (size.height <= maxHeight)
        {
            rect.size.height = size.height;
            self.descriptionLabel.frame = rect;
            break;
        }
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id key = @"FCLSignatureSampleDidShowV2";
    if (![[NSUserDefaults standardUserDefaults] objectForKey:key])
    {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:key];
        self.sampleImageView.hidden = NO;
        self.sampleImageView.alpha = 0.0;
        [UIView animateWithDuration:0.3 animations:^{
            self.sampleImageView.alpha = 0.3;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 delay:0.5 options:0 animations:^{
                self.sampleImageView.alpha = 0.0;
            } completion:^(BOOL finished) {
                [self.sampleImageView removeFromSuperview];
            }];
        }];
    }
}

// MARK: Rotation

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAllButUpsideDown;
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (BOOL) shouldAutorotate
{
    return YES;
}


// MARK: Actions

- (void) undo:(id)_
{
    [self.drawingView erase];
    [self updateClearButton];
}

- (void) cancel:(id)_
{
    if (self.completionBlock)
    {
        self.completionBlock(nil);
        self.completionBlock = nil;
    }
}

- (void) doneSignature:(id)_
{
    if (self.completionBlock)
    {
        self.yourSignatureSubtitle.hidden = YES;
        
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 2.0); // always 2.0 to have hi-res image even on old devices.
        [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.yourSignatureSubtitle.hidden = NO;
        
        self.completionBlock(image);
        self.completionBlock = nil;
    }
}

- (void) image:(UIImage *) image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
	NSLog(@"Finished saving image. Error: %@", error);
	if (error) {
        [self FCL_presentAlertForError:error];
	}
}


- (void) handDrawingViewDidDraw:(FCLHandDrawingView*)drawingView
{
    [self updateClearButton];
}

- (void) handDrawingViewDidClean:(FCLHandDrawingView*)drawingView
{
    [self updateClearButton];
}

- (void) updateClearButton
{
    if (self.drawingView.dirty)
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Effacer", @"") style:UIBarButtonItemStyleDone target:self action:@selector(undo:)];
    }
    else
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    }
}

@end
