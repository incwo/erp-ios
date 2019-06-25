#import "FCLFormListViewController.h"
#import "FCLFormsBusinessFile.h"
#import "FCLForm.h"
#import "FCLFormFolder.h"
#import "FCLFormViewController.h"
#import "FCLUploader.h"
#import "FCLUpload.h"
#import "UIViewController+Alert.h"

@interface FCLFormListViewController ()

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
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Tirer pour rafraichir"];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Menu"] style:UIBarButtonItemStylePlain target:self action:@selector(showSidePanel:)];
    
    self.helpHeaderView.text = NSLocalizedString(@"Insérez des photos et signatures sur votre application", @"");
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
        [self.delegate formListViewController:self didSelectForm:(FCLForm *)child];
    }
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

@end
