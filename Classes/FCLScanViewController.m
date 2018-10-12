#import "FCLSession.h"
#import "facilescan-Swift.h"
#import "FCLScanViewController.h"
#import "FCLBusinessFilesList.h"
#import "FCLBusinessFile.h"
#import "FCLCategoriesController.h"
#import "FCLLoginController.h"
#import "PFWebViewController.h"
#import "UIViewController+Alert.h"

#import "OAHTTPDownload.h"

@interface FCLScanViewController ()

@property (nonatomic, readonly) FCLSession *session;
@property(nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic) OAHTTPDownload* download;
@property(nonatomic) NSArray* files;
@property(nonatomic) NSData* xmlData;
@property(nonatomic) FCLCategoriesController* categoriesController;
@end

@implementation FCLScanViewController {
    BOOL performingGoToFile;
    NSDate* _lastCheckDate;
}


@synthesize download;
@synthesize xmlData;
@synthesize categoriesController;
@synthesize files;

-(nonnull instancetype) initWithSession:(nonnull FCLSession *)session {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        NSParameterAssert(session);
        _session = session;
    }
    return self;
}

#pragma mark Lifecycle

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Scan";
    
    UIRefreshControl* rc = [[UIRefreshControl alloc] init];
    [rc addTarget:self action:@selector(reload:) forControlEvents:UIControlEventValueChanged];
    self.tableView.tableHeaderView = rc;
    
    self.navigationItem.hidesBackButton = true;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"FCLNavSignOut"] style:UIBarButtonItemStylePlain target:self action:@selector(signOut:)];
}

- (void) dealloc
{
    self.download.target = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!_lastCheckDate || [[NSDate date] timeIntervalSinceDate:_lastCheckDate] > 300.0)
    {
        _lastCheckDate = [NSDate date];
        [self loadList];
    }
}

// MARK: Contents

- (NSArray*) files
{
    if (!files && self.xmlData)
    {
        self.files = [FCLBusinessFilesList arrayOfBusinessFilesForXMLData:self.xmlData];
    }
    return files;
}


- (NSURL*) listURL
{
    return [NSURL URLWithString:
            [NSString stringWithFormat:@"%@/account/get_files_and_image_enabled_objects/0.xml?r=%d", self.session.facileBaseURL, rand()]];
}

- (void) resetData
{
    self.xmlData = nil;
    self.files = nil;
    [self.tableView reloadData];
}


- (void) loadList
{
    NSURL* url = [self listURL];
    NSLog(@"Loading URL: %@", url);
    
    // Note: I avoid using iPhone NSURLConnection credentials API here to avoid unnecessary request
    //       This makes things 2 times faster on slow networks.
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    [request setFCLSession:self.session];
    
    self.download = [OAHTTPDownload downloadWithRequest:request];
    download.username = self.session.username;
    download.password = self.session.password;
    download.target = self;
    download.successAction = @selector(listDidFinishLoading:);
    download.failureActionWithError = @selector(listDownload:didFailWithError:);
    download.shouldAllowSelfSignedCert = YES;
    [download start];
}

- (void) goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) goToFile:(FCLBusinessFile*)file
{
    performingGoToFile = NO;
    self.categoriesController = [[FCLCategoriesController alloc] initWithNibName:nil bundle:nil];
    self.categoriesController.file = file;
    self.categoriesController.username = self.session.username;
    self.categoriesController.password = self.session.password;
    
    [self.navigationController pushViewController:self.categoriesController animated:YES];
}

- (void) signOut:(id)sender
{
    [FCLSession removeSavedSession]; // Emits FCLSessionDidSignOutNotification
}

- (IBAction)reload:(id)sender
{
    [self loadList];
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


#pragma mark OAHTTPDownload target/actions


- (void) listDidFinishLoading:(OAHTTPDownload*)aDownload
{
    //NSLog(@"did load XML: %@", [[[NSString alloc] initWithData:aDownload.receivedData encoding:NSUTF8StringEncoding] autorelease]);
    self.files = nil;
    self.xmlData = aDownload.receivedData;
    
    [((UIRefreshControl*) self.tableView.tableHeaderView) endRefreshing];
    
    [self.tableView reloadData];
}

- (void) listDownload:(OAHTTPDownload*)aDownload didFailWithError:(NSError*)error
{
    [self _showAlertForError:error];
    [self performSelector:@selector(goBack) withObject:nil afterDelay:0.6];

    [((UIRefreshControl*) self.tableView.tableHeaderView) endRefreshing];
}

-(void) _showAlertForError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:error.localizedDescription message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark UITableViewDataSource


- (NSInteger)tableView:(UITableView*)aTableView numberOfRowsInSection:(NSInteger)section
{
    return self.files ? [self.files count] : 0;
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
    
    FCLBusinessFile* aFile = [self.files objectAtIndex:indexPath.row];
    cell.textLabel.text = aFile.name;
    cell.detailTextLabel.text = aFile.kind ? aFile.kind : @"";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    if (!performingGoToFile)
    {
        [self goToFile:[self.files objectAtIndex:indexPath.row]];
    }
}

@end
