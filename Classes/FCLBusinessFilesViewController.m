#import "FCLSession.h"
#import "facilescan-Swift.h"
#import "FCLBusinessFilesViewController.h"
#import "FCLBusinessFilesFetch.h"
#import "FCLBusinessFile.h"
#import "FCLCategoriesController.h"
#import "UIViewController+Alert.h"

@interface FCLBusinessFilesViewController ()

@property (nonatomic, readonly) FCLSession *session;
@property FCLBusinessFilesFetch *businessFilesFetch;
@property NSArray <FCLBusinessFile *> *businessFiles;
@property NSDate *lastCheckDate;

@end

@implementation FCLBusinessFilesViewController

-(nonnull instancetype) initWithSession:(nonnull FCLSession *)session {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        NSParameterAssert(session);
        _businessFilesFetch = [[FCLBusinessFilesFetch alloc] initWithSession:session];
    }
    return self;
}

#pragma mark Lifecycle

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Scan";
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reload:) forControlEvents:UIControlEventValueChanged];
    
    self.navigationItem.hidesBackButton = true;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"FCLNavSignOut"] style:UIBarButtonItemStylePlain target:self action:@selector(signOut:)];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!self.lastCheckDate || [[NSDate date] timeIntervalSinceDate:self.lastCheckDate] > 300.0)
    {
        self.lastCheckDate = [NSDate date];
        [self loadBusinessFiles];
    }
}

// MARK: Contents

-(void) loadBusinessFiles {
    __typeof(self) __weak weakSelf = self;
    [self.businessFilesFetch fetchSuccess:^(NSArray<FCLBusinessFile *> * _Nonnull businessFiles) {
        weakSelf.businessFiles = businessFiles;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
            [weakSelf.refreshControl endRefreshing];
        });
    } failure:^(NSError * _Nonnull error) {
        weakSelf.businessFiles = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf FCL_presentAlertForError:error];
            [weakSelf.refreshControl endRefreshing];
        });
    }];
}

- (void) presentBusinessFile:(FCLBusinessFile *)file
{
    FCLCategoriesController *categoriesController =  [[FCLCategoriesController alloc] initWithNibName:nil bundle:nil];
    categoriesController.file = file;
    categoriesController.username = self.session.username;
    categoriesController.password = self.session.password;
    
    [self.navigationController pushViewController:categoriesController animated:YES];
}

// MARK: Actions

- (void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) signOut:(id)sender
{
    [FCLSession removeSavedSession]; // Emits FCLSessionDidSignOutNotification
}

- (IBAction)reload:(id)sender
{
    [self loadBusinessFiles];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [self presentBusinessFile:[self.businessFiles objectAtIndex:indexPath.row]];
}

@end
