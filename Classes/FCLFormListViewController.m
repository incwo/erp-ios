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

@synthesize sidePanelButtonShown = _sidePanelButtonShown;
- (void)setSidePanelButtonShown:(BOOL)sidePanelButtonShown {
    if(sidePanelButtonShown == _sidePanelButtonShown) {
        return;
    }
    _sidePanelButtonShown = sidePanelButtonShown;
    
    if(_sidePanelButtonShown) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Menu"] style:UIBarButtonItemStylePlain target:self action:@selector(showSidePanel:)];
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}
- (BOOL)sidePanelButtonShown {
    return _sidePanelButtonShown;
}

@synthesize listTitle = _listTitle;
- (void)setListTitle:(NSString *)listTitle {
    @synchronized (self) {
        if(listTitle == _listTitle) {
            return;
        }
        _listTitle = listTitle;
        self.navigationItem.title = listTitle;
    }
}

- (NSString *)listTitle {
    @synchronized (self) {
        return _listTitle;
    }
}

@synthesize formsAndFolders = _formsAndFolders;
- (void)setFormsAndFolders:(NSArray *)formsAndFolders {
    @synchronized (self) {
        if(formsAndFolders != _formsAndFolders) {
            _formsAndFolders = formsAndFolders;
        }
    }
    
    __typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.refreshControl endRefreshing];
        [weakSelf.tableView reloadData];
    });
}

- (NSArray *)formsAndFolders {
    @synchronized (self) {
        return _formsAndFolders;
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
    return self.formsAndFolders ? self.formsAndFolders.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id child = [self.formsAndFolders objectAtIndex:indexPath.row];
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
    id child = [self.formsAndFolders objectAtIndex:indexPath.row];
    if([child isKindOfClass:[FCLForm class]]) {
        [self.delegate formListViewController:self didSelectForm:(FCLForm *)child];
    } else if([child isKindOfClass:[FCLFormFolder class]]){
        [self.delegate formListViewController:self didSelectFormFolder:(FCLFormFolder *)child];
    }
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

@end
