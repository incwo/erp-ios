#import "FCLSession.h"
#import "facilescan-Swift.h"
#import "FCLBusinessFilesViewController.h"
#import "FCLBusinessFilesFetch.h"
#import "FCLBusinessFile.h"
#import "UIViewController+Alert.h"

@interface FCLBusinessFilesViewController ()

@property id <FCLBusinessFilesViewControllerDelegate> delegate;
@property NSDate *lastCheckDate;

@end

@implementation FCLBusinessFilesViewController

-(nonnull instancetype) initWithDelegate:(nonnull id <FCLBusinessFilesViewControllerDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        NSParameterAssert(delegate);
        _delegate = delegate;
    }
    return self;
}

#pragma mark Lifecycle

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Dossiers d'entreprise";
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Tirer pour rafraichir"];
    
    self.navigationItem.hidesBackButton = true;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"FCLNavSignOut"] style:UIBarButtonItemStylePlain target:self action:@selector(signOut:)];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!self.lastCheckDate || [[NSDate date] timeIntervalSinceDate:self.lastCheckDate] > 300.0)
    {
        self.lastCheckDate = [NSDate date];
        [self.delegate businessFilesViewControllerRefresh:self];
    }
}

// MARK: Contents

@synthesize businessFiles = _businessFiles;
-(void)setBusinessFiles:(NSArray<FCLBusinessFile *> *)businessFiles {
    __typeof(self) __weak weakSelf = self;
    
    @synchronized (self) {
        if(businessFiles != _businessFiles) {
            _businessFiles = businessFiles;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.tableView reloadData];
        [weakSelf.refreshControl endRefreshing];
    });
}

-(NSArray<FCLBusinessFile *> *)businessFiles {
    @synchronized (self) {
        return _businessFiles;
    }
}

// MARK: Actions

- (void) signOut:(id)sender {
    [self.delegate businessFilesViewControllerLogOut:self];
}

- (IBAction)refresh:(id)sender {
    [self.delegate businessFilesViewControllerRefresh:self];
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

#pragma mark UITableViewDataSource


- (NSInteger)tableView:(UITableView*)aTableView numberOfRowsInSection:(NSInteger)section
{
    return self.businessFiles ? [self.businessFiles count] : 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"BusinessFileCell";
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    FCLBusinessFile *businessFile = [self.businessFiles objectAtIndex:indexPath.row];
    cell.textLabel.text = businessFile.name;
    cell.detailTextLabel.text = businessFile.kind ? businessFile.kind : @"";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [self.delegate businessFilesViewController:self didSelectBusinessFile:[self.businessFiles objectAtIndex:indexPath.row]];
}

@end
