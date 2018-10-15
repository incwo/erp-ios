#import "FCLOptionsViewController.h"
#import "FCLField.h"

@implementation FCLOptionsViewController {
    FCLField* field;
}

@synthesize field;

// MARK: Lifecycle

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:(BOOL)animated];
    self.title = self.field.name;
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

// MARK: UITableViewDataSource

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    return self.field ? [self.field.values count] : 0;
}

- (UITableViewCell*) tableView:(UITableView*)aTableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    NSString* cellIdentifier = @"Cell";
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    if (self.field) {
        cell.textLabel.text = [field.valueTitles objectAtIndex:indexPath.row];
        if ([[field value] isEqualToString:[field.values objectAtIndex:indexPath.row]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (field.enumSelectionIndex == indexPath.row)
    {
        field.enumSelectionIndex = -1;
    }
    else
    {
        field.enumSelectionIndex = indexPath.row;
    }
    
    [self.delegate optionsViewControllerDidPick:self];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

@end
