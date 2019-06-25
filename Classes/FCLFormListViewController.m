#import "FCLFormListViewController.h"
#import "FCLFormsBusinessFile.h"
#import "FCLForm.h"
#import "FCLFormFolder.h"
#import "FCLFormViewController.h"
#import "FCLUploader.h"
#import "FCLUpload.h"
#import "UIViewController+Alert.h"

@interface FCLFormListViewController () <UploaderDelegate, FCLFormViewControllerDelegate>

@property(nonatomic, strong) FCLFormViewController *formController;
@property(nonatomic,strong) IBOutlet UILabel *helpHeaderView;

@end

@implementation FCLFormListViewController

@synthesize formsBusinessFile = _formsBusinessFile;
-(void)setFormsBusinessFile:(FCLFormsBusinessFile *)businessFile {
    @synchronized (self) {
        if(businessFile != _formsBusinessFile) {
            _formsBusinessFile = businessFile;
        }
    }
    
    __typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.refreshControl endRefreshing];
        weakSelf.navigationItem.title = businessFile.name;
        [weakSelf.tableView reloadData];
    });
}

-(FCLFormsBusinessFile *)formsBusinessFile {
    @synchronized (self) {
        return _formsBusinessFile;
    }
}

#pragma mark Lifecycle

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    NSParameterAssert(self.delegate);
    NSParameterAssert(self.username);
    NSParameterAssert(self.password);
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Tirer pour rafraichir"];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Menu"] style:UIBarButtonItemStylePlain target:self action:@selector(showSidePanel:)];
    
    self.helpHeaderView.text = NSLocalizedString(@"Insérez des photos et signatures sur votre application", @"");
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [FCLUploader sharedUploader].delegate = self;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [FCLUploader sharedUploader].delegate = nil;
}

// MARK: Actions

-(void)refresh:(id)sender {
    [self.delegate formListViewControllerRefresh:self];
}

-(void) showSidePanel:(id)sender {
    [self.delegate formListViewControllerSidePanel:self];
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



#pragma mark UploaderDelegate


- (void) uploaderDidUpdateStatus:(FCLUploader *)anUploader
{
    NSLog(@"uploaderDidUpdateStatus: isUploading: %d", (int)[anUploader isUploading]);
    [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.0];
}

- (void)uploader:(FCLUploader *)uploader didFailWithError:(NSError *)error {
    [self FCL_presentAlertForError:error];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)aTableView numberOfRowsInSection:(NSInteger)section
{
    return self.formsBusinessFile ? [self.formsBusinessFile.children count] : 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id child = [self.formsBusinessFile.children objectAtIndex:indexPath.row];
    if([child isKindOfClass:[FCLForm class]]) {
        return [self createTitleCellForForm:(FCLForm *)child inTableView:aTableView];
    } else if([child isKindOfClass:[FCLFormFolder class]]) {
        return [self createTitleCellForFolder:(FCLFormFolder *)child inTableView:aTableView];
    } else {
        NSLog(@"%s Unknown class in formsBusinessFile.children", __PRETTY_FUNCTION__);
        return [UITableViewCell new];
    }
}

-(UITableViewCell *)createTitleCellForForm:(FCLForm *)form inTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FormTitle"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FormTitle"];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = [form name];
    
    return cell;
}

-(UITableViewCell *)createTitleCellForFolder:(FCLFormFolder *)folder inTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FolderTitle"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FolderTitle"];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = folder.title;
    
    return cell;
}

#pragma mark UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id child = [self.formsBusinessFile.children objectAtIndex:indexPath.row];
    if([child isKindOfClass:[FCLForm class]]) {
        FCLForm *form = child;
        self.formController = [[FCLFormViewController alloc] initWithNibName:nil bundle:nil];
        self.formController.delegate = self;
        self.formController.form = form;
        [form reset];
        [form loadDefaults];
        [self.navigationController pushViewController:self.formController animated:YES];
    }
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

// MARK: FCLFormViewControllerDelegate

-(void) formViewControllerSend:(FCLFormViewController *)formController {
    [self.navigationController popViewControllerAnimated:YES];
    
    FCLUpload* upload = [[FCLUpload alloc] init];
    
    [formController.form saveDefaults];
    
    NSLog(@"Sending form %@ (%@) to business_file %@ (%@)", formController.form.name, formController.form.key, self.formsBusinessFile.name, self.formsBusinessFile.identifier);
    
    upload.fileId = self.formsBusinessFile.identifier;
    upload.categoryKey = formController.form.key;
    upload.fields = [formController fields];
    upload.image = formController.image;
    upload.username = self.username;
    upload.password = self.password;
    
    [[FCLUploader sharedUploader] addUpload:upload];
}

@end
