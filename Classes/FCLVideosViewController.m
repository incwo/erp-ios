#import "FCLVideosViewController.h"
#import "FCLVideoViewController.h"
#import "FCLSession.h"
#import "OAXMLDecoder.h"
#import "OANetworkActivityIndicator.h"
#import "UIViewController+Alert.h"

typedef NS_ENUM(NSUInteger, FCLVideoSearchMode) {
    FCLVideoSearchModeNone,
    FCLVideoSearchModeFocused,
    FCLVideoSearchModeSearching,
};

@interface FCLVideosViewController () <UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *blackOverlayView;

@property BOOL isCatalog;
@property NSDate *lastCheckDate;
@property UISearchBar *searchBar;
@property NSCache *hotImageCache;

@property(nonatomic) NSArray* allVideoItems;
@property(nonatomic) NSArray* videoItems;
@property(nonatomic) NSArray* videoCategories;
@property(nonatomic) NSDictionary* videoCategoriesCounts;
@property(nonatomic) FCLVideoSearchMode searchMode;
@end

@implementation FCLVideosViewController

+ (instancetype) catalogController
{
    FCLVideosViewController* videosViewController = [[self alloc] initWithNibName:nil bundle:nil];
    videosViewController.title = NSLocalizedString(@"Vidéos", nil);
    videosViewController.isCatalog = YES;
    return videosViewController;
}

+ (instancetype) videosControllerWithVideoItems:(NSArray*)videoItems title:(NSString*)title
{
    FCLVideosViewController* vc = [[self alloc] initWithNibName:nil bundle:nil];
    vc.title = title;
    vc.allVideoItems = videoItems;
    return vc;
}

// MARK: Lifecycle

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.isCatalog && !self.searchBar)
    {
        self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 200.0, 44.0)];
		self.searchBar.placeholder = NSLocalizedString(@"Recherche videos", @"");
		self.searchBar.delegate = self;
		self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.navigationItem.titleView = self.searchBar;
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.isCatalog)
    {
        [self updateVideos];
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

// MARK: Videos

- (void) updateVideos
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.incwo.com/videos/trainings.xml"]];
    
    NSCachedURLResponse* cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    
    if (cachedResponse.data)
    {
        [self displayVideosWithXMLData:cachedResponse.data];
    }
    
    // If we haven't checked the source since a long time, should do it.
    if (!self.lastCheckDate || [[NSDate date] timeIntervalSinceDate:self.lastCheckDate] > 300.0)
    {
        self.lastCheckDate = [NSDate date];
        [OANetworkActivityIndicator push];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            NSURLResponse* response = nil;
            NSError* error = nil;
            NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [OANetworkActivityIndicator pop];
                
                if (!data)
                {
                    [self FCL_presentAlertForError:error];
                    return;
                }
                
                NSCachedURLResponse* cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
                [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:request];
                
                [self displayVideosWithXMLData:data];
            });
        });
    }
}

- (void) displayVideosWithXMLData:(NSData *)data
{
    if (!data) return;
    
    __typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSError *xmlParsingError;
        NSArray *videoItems;
        NSDictionary *countByCategories;
        BOOL success = [self videoItems:&videoItems countByCategories:&countByCategories forXMLData:data error:&xmlParsingError];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(success) {
                if(videoItems.count > 0) {
                    self.videoItems = nil;
                    self.allVideoItems = videoItems;
                    self.videoCategories = [[countByCategories allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
                    self.videoCategoriesCounts = countByCategories;
                    [self.tableView reloadData];
                }
            } else {
                [weakSelf FCL_presentAlertForError:xmlParsingError];
            }
        });
    });
}


-(BOOL) videoItems:(NSArray **)outVideoItems countByCategories:(NSDictionary **)outCountByCategories forXMLData:(NSData *)xmlData error:(NSError **)error {
    NSMutableArray *videoItems = [NSMutableArray array];
    NSMutableDictionary *categoryCounts = [NSMutableDictionary dictionary];
    
    __block NSMutableDictionary* item = nil;
    
    OAXMLDecoder* xmlDecoder = [OAXMLDecoder parseData:xmlData withBlock:^(OAXMLDecoder *decoder) {
        
        //  <medias type="array">
        //      <pagination>...</pagination>
        //      <media>
        //          <id>543169</id>
        //          <serie>app_training</serie>
        //          <kind>tutorial</kind>
        //          <reference>Supprimer une facture</reference>
        //          <title>Supprimer une facture</title>
        //          <permalink>supprimer-une-facture-543169</permalink>
        //          <subtitle>Supprimer une facture client</subtitle>
        //          <support>youtube</support>
        //          <video_reference>4enHEl7TNzA</video_reference>
        //          <publication_date>09-11-2012-00-00</publication_date>
        //          <view_count>102</view_count>
        //          <view_count_frozen>100</view_count_frozen>
        //          <view_count_frozen_at>31-01-2013-12-01</view_count_frozen_at>
        //          <is_running>1</is_running>
        //          <created_at>09-11-2012-17-31</created_at>
        //          <creator_id>43</creator_id>
        //          <modified_at>09-11-2012-18-11</modified_at>
        //          <modifier_id>43</modifier_id>
        //          <language>fr</language>
        //          <original_air_date>09-11-2012-00-00</original_air_date>
        //          <click_count>2</click_count>
        //          <positive_reviews>1</positive_reviews>
        //          <negative_reviews>0</negative_reviews>
        //          <average_review>1</average_review>
        //          <training_value>1000</training_value>
        //          <feature>factures</feature>
        //          <feature2>cashflow</feature2>
        //      </media>
        
        [decoder startElement:@"medias" withBlock:^{
            [decoder startElement:@"media" withBlock:^{
                
                item = [NSMutableDictionary dictionary];
                
                [decoder endElement:@"id" withBlock:^{
                    item[@"id"] = decoder.currentStringStripped ?: @"";
                }];
                [decoder endElement:@"video_reference" withBlock:^{
                    item[@"youtube_id"] = decoder.currentStringStripped ?: @"";
                }];
                [decoder endElement:@"permalink" withBlock:^{
                    item[@"permalink"] = decoder.currentStringStripped ?: @"";
                }];
                [decoder endElement:@"title" withBlock:^{
                    item[@"title"] = decoder.currentStringStripped ?: @"";
                }];
                [decoder endElement:@"created_at" withBlock:^{
                    // TODO: parse the created_at into a NSDate object
                    item[@"created_at"] = decoder.currentStringStripped ?: @"";
                }];
                [decoder endElement:@"feature" withBlock:^{
                    if (![item[@"categories"] isKindOfClass:[NSArray class]])
                    {
                        item[@"categories"] = [NSMutableArray array];
                    }
                    if (decoder.currentString.length > 0)
                    {
                        [item[@"categories"] addObject:decoder.currentStringStripped];
                        if (!categoryCounts[decoder.currentStringStripped])
                        {
                            categoryCounts[decoder.currentStringStripped] = @0;
                        }
                        categoryCounts[decoder.currentStringStripped] = @(1 + [categoryCounts[decoder.currentStringStripped] integerValue]);
                    }
                    [item[@"categories"] addObject:@""];
                    categoryCounts[@""] = @(1 + [categoryCounts[@""] integerValue]);
                }];
            }];
            [decoder endElement:@"media" withBlock:^{
                if (item.count > 0) [videoItems addObject:item];
            }];
        }];
    }];
    
    if (xmlDecoder.error) {
        *error = xmlDecoder.error;
        return nil;
    }
    
    *outVideoItems = videoItems;
    *outCountByCategories = categoryCounts;
    
    return videoItems;
}

- (NSURL*) URLForYoutubePageWithItem:(id)item
{
    if (item[@"permalink"])
    {
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@/iframe/training/%@", [FCLSession facileBaseURL], item[@"permalink"]]];
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", item[@"youtube_id"]]];
}

- (NSURL*) URLForYoutubeThumbnailWithID:(NSString*)youtubeID
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://img.youtube.com/vi/%@/0.jpg", youtubeID]];
}

- (NSURLRequest*) requestForYoutubeThumbnailWithID:(NSString*)youtubeID
{
    return [NSURLRequest requestWithURL:[self URLForYoutubeThumbnailWithID:youtubeID]];
}

- (IBAction)blackOverlayTap:(id)sender
{
    [self.searchBar resignFirstResponder];
    [self setSearchMode:FCLVideoSearchModeNone animated:YES];
    [self.tableView reloadData];
}






#pragma mark - Search




- (void) setSearchMode:(FCLVideoSearchMode)searchMode
{
    [self setSearchMode:searchMode animated:NO];
}

- (void) setSearchMode:(FCLVideoSearchMode)searchMode animated:(BOOL)animated
{
    if (searchMode == _searchMode) return;
    
    FCLVideoSearchMode oldMode = _searchMode;
    _searchMode = searchMode;
    
    __weak FCLVideosViewController *weakSelf = self;
    void(^block)(void) = ^{
        weakSelf.blackOverlayView.alpha = (weakSelf.searchMode == FCLVideoSearchModeFocused ? 0.5 : 0.0);
        weakSelf.blackOverlayView.userInteractionEnabled = (weakSelf.searchMode == FCLVideoSearchModeFocused ? YES : NO);
    };
    
    (animated && _searchMode == FCLVideoSearchModeFocused && oldMode == FCLVideoSearchModeNone)
        ? [UIView animateWithDuration:0.3 animations:block]
        : block();

    [_searchBar setShowsCancelButton:(_searchMode != FCLVideoSearchModeNone) animated:YES];
    [self.tableView reloadData];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if (searchBar.text.length > 0)
    {
        [self setSearchMode:FCLVideoSearchModeSearching animated:YES];
    }
    else
    {
        [self setSearchMode:FCLVideoSearchModeFocused animated:YES];
    }
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    self.videoItems = nil;
    [self setSearchMode:FCLVideoSearchModeNone animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.videoItems = nil;
    if (searchText.length > 0)
    {
        [self setSearchMode:FCLVideoSearchModeSearching animated:YES];
    }
    else
    {
        [self setSearchMode:FCLVideoSearchModeFocused animated:YES];
    }
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    if (searchBar.text.length > 0)
    {
        [self setSearchMode:FCLVideoSearchModeSearching animated:YES];
    }
    else
    {
        [self setSearchMode:FCLVideoSearchModeNone animated:YES];
    }
    [self.tableView reloadData];
}



#pragma mark - UITableView

// There are two modes: either categories of videos are shown, or the list of videos which titles match the search string
- (BOOL) tableViewShowsVideos
{
    if (self.isCatalog && (self.searchMode == FCLVideoSearchModeNone || self.searchMode == FCLVideoSearchModeFocused))
    {
        return NO; // displaying categories
    }
    return YES;
}


- (NSInteger)tableView:(UITableView*)aTableView numberOfRowsInSection:(NSInteger)section
{
    if (![self tableViewShowsVideos])
    {
        //NSLog(@"showing categories");
        return self.videoCategories.count;
    }
    else
    {
        //NSLog(@"showing videos");
        if (!self.videoItems)
        {
            self.videoItems = self.allVideoItems;
            
            if (self.searchMode == FCLVideoSearchModeSearching)
            {
                NSMutableArray* items = [NSMutableArray array];
                NSString* searchText = _searchBar.text;
                NSArray* searchTokens = [searchText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                // First, find exact matches
                for (id item in self.videoItems)
                {
                    NSString* str = [item[@"title"] stringByAppendingFormat:@" %@", [item[@"categories"] componentsJoinedByString:@" "]];
                    
                    if ([str rangeOfString:searchText options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch].length > 0)
                    {
                        [items addObject:item];
                    }
                }
                
                // Also add partial matches, to the end.
                if (searchTokens.count > 1)
                {
                    for (id item in self.videoItems)
                    {
                        if (![items containsObject:item])
                        {
                            NSString* str = [item[@"title"] stringByAppendingFormat:@" %@", [item[@"categories"] componentsJoinedByString:@" "]];
                            
                            for (id token in searchTokens)
                            {
                                if ([str rangeOfString:token options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch].length > 0)
                                {
                                    [items addObject:item];
                                }
                            }
                        }
                    }
                }
                
                self.videoItems = items;
            }
        }
        
        return self.videoItems.count;
    }
}

- (UITableViewCell *)tableView:(UITableView*)aTableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if([self tableViewShowsVideos]) {
        NSString *reuseIdentifier = @"TitleCell";
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        
        // Configure the cell.
        id item = self.videoItems[indexPath.row];
        cell.textLabel.text = item[@"title"];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
        cell.tag = indexPath.row;
        
        UIImage* cachedImage = [_hotImageCache objectForKey:item[@"youtube_id"]];
        cell.imageView.image =  cachedImage ?: [UIImage imageNamed:@"FCLNoVideo.png"];
        cell.imageView.bounds = CGRectMake(0, 0, 130.0, 100.0);
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        // Image loading
        if (!cachedImage)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                
                NSURLRequest* imageRequest = [self requestForYoutubeThumbnailWithID:item[@"youtube_id"]];
                NSCachedURLResponse* cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:imageRequest];
                
                BOOL cached = YES;
                NSData* imageData = cachedResponse.data;
                NSURLResponse* response = nil;
                
                if (!imageData)
                {
                    cached = NO;
                    NSError* error = nil;
                    imageData = [NSURLConnection sendSynchronousRequest:imageRequest returningResponse:&response error:&error];
                    if (!imageData)
                    {
                        NSLog(@"FCLVideosViewController: failed to load image: %@", error);
                    }
                }
                
                if (imageData)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!cached)
                        {
                            NSCachedURLResponse* cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:imageData userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
                            [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:imageRequest];
                        }
                        
                        if (!self.hotImageCache)
                        {
                            self.hotImageCache = [[NSCache alloc] init];
                            self.hotImageCache.name = @"FCLVideosThumbnailCache";
                            self.hotImageCache.totalCostLimit = 100*1024;
                            self.hotImageCache.countLimit = 20;
                        }
                        
                        UIImage* image = [UIImage imageWithData:imageData scale:1.0];
                        [self.hotImageCache setObject:image forKey:item[@"youtube_id"] cost:imageData.length];
                        
                        if ([self tableViewShowsVideos])
                        {
                            for (UITableViewCell* existingCell in self.tableView.visibleCells)
                            {
                                NSDictionary* existingItem = existingCell.tag < self.videoItems.count ? self.videoItems[existingCell.tag] : nil;
                                if ([existingItem[@"youtube_id"] isEqual:item[@"youtube_id"]])
                                {
                                    existingCell.imageView.image = image;
                                    [existingCell setNeedsLayout];
                                }
                            }
                        }
                    });
                }
            });
        }
        return cell;
    } else {
        NSString *reuseIdentifier = @"CategoryCellCell";
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        
        NSString* category = self.videoCategories[indexPath.row];
        
        cell.textLabel.text = [category capitalizedString];
        if ([category isEqualToString:@""])
        {
            cell.textLabel.text = NSLocalizedString(@"Toutes les vidéos", nil);
        }
        cell.textLabel.numberOfLines = 2;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        NSNumber* num = self.videoCategoriesCounts[category];
        if ([num integerValue] > 0)
        {
            cell.detailTextLabel.text = [num stringValue];
        }
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    if ([self tableViewShowsVideos])
    {
        // Open video
        [_searchBar resignFirstResponder];

        id item = self.videoItems[indexPath.row];
        FCLVideoViewController* vc = [[FCLVideoViewController alloc] initWithNibName:nil bundle:nil];
        vc.title = NSLocalizedString(@"Vidéo", @"");
        [self.navigationController pushViewController:vc animated:YES];
        [vc view]; // load view
        [vc playVideoAtURL:[self URLForYoutubePageWithItem:item]];
    }
    else
    {
        // Open videos controller with the videos for a given category

        id category = self.videoCategories[indexPath.row];
        NSMutableArray* videos = [NSMutableArray array];
        for (id item in self.allVideoItems)
        {
            if ([item[@"categories"] containsObject:category])
            {
                [videos addObject:item];
            }
        }
        
        NSString* title = [NSString stringWithFormat:@"%@ (%@)", [category capitalizedString], self.videoCategoriesCounts[category]];
        NSString* backTitle = [category capitalizedString];
        if ([category isEqualToString:@""])
        {
            title = NSLocalizedString(@"Toutes les vidéos", nil);
            backTitle = title;
        }
        
        FCLVideosViewController* vc = [FCLVideosViewController videosControllerWithVideoItems:videos title:title];
        vc.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:backTitle style:UIBarButtonItemStylePlain target:nil action:NULL];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (NSString*) reuseIdentifierForIndexPath:(NSIndexPath*)indexPath
{
    return [NSString stringWithFormat:@"Cell%lu", (unsigned long)self.searchMode];
}

@end
