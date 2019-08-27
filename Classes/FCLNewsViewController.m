#import "FCLNewsViewController.h"
#import "FCLWebViewController.h"
#import "PStringExtensions.h"
#import "PDateExtension.h"
#import "OAXMLDecoder.h"
#import "OANetworkActivityIndicator.h"
#import "UIViewController+Alert.h"

@interface FCLNewsViewController ()

@property NSArray* newsItems;
@property NSDate *lastCheckDate;
@property UINib *cellNib;

@end

@implementation FCLNewsViewController

// MARK: Lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Actualités", @"");
    [self updateNews];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateNews];
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

// MARK: News

- (void) updateNews
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://blog.incwo.com/xml/rss20/feed.xml?show_extended=1"]];

    
    NSCachedURLResponse* cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    
    if (cachedResponse.data)
    {
        [self displayNewsWithXMLData:cachedResponse.data];
    }
    
    // If we haven't checked the source since a long time, should do it.
    if (!_lastCheckDate || [[NSDate date] timeIntervalSinceDate:_lastCheckDate] > 300.0)
    {
        _lastCheckDate = [NSDate date];
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
                
                [self displayNewsWithXMLData:data];
            });
        });
    }
}

- (void) displayNewsWithXMLData:(NSData*)data
{
    if (!data) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        NSMutableArray* newsItems = [NSMutableArray array];
        
        __block NSMutableDictionary* item = nil;
        
        OAXMLDecoder* xmlDecoder = [OAXMLDecoder parseData:data withBlock:^(OAXMLDecoder *decoder) {
            
            //<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:trackback="http://madskills.com/public/xml/rss/module/trackback/">
            //    <channel>
            //        <title>le blog incwo.com</title>
            //        <link>http://blog.incwo.com</link>
            //        <language>en-us</language>
            //        <ttl>40</ttl>
            //        <description></description>
            //        <item>
            //            <title>Recevez des documents dans vos emails de rappels de t&#226;che et de rendez-vous</title>
            //            <description>&lt;p&gt;&lt;strong&gt;Une nouvelle fonctionnalit&amp;eacute;&lt;/strong&gt; est disponible imm&amp;eacute;diatement sur les applications de gestion &lt;a href="http://www.incwo.com/" target="_blank"&gt;bureau virtuel&lt;/a&gt;, &lt;a href="http://www.gestion-de-chantier.com/" target="_blank"&gt;gestion-de-chantier&lt;/a&gt;, &lt;a href="http://www.ma-facturation.com" target="_blank"&gt;ma-facturation.com&lt;/a&gt; et &lt;a href="http://www.gestion-auto-entrepreneur.com" target="_blank"&gt;gestion-auto-entrepreneur.com&lt;/a&gt;. &lt;/p&gt;&lt;p&gt;&lt;strong&gt;&lt;img src="http://www.incwo.com/images/blog/email_attached_files.jpg" border="0" alt="" width="331" height="110" align="right" /&gt;&lt;/strong&gt;D&amp;eacute;sormais, les emails de rappel de t&amp;acirc;ches ou d&amp;#39;&amp;eacute;v&amp;eacute;nements que vous recevez contiennent un lien vers les fichiers qui leur sont attach&amp;eacute;s. Acc&amp;eacute;dez ainsi directement depuis votre email aux documents n&amp;eacute;cessaires pour r&amp;eacute;aliser une t&amp;acirc;che, pr&amp;eacute;parer &amp;agrave; un rendez-vous, etc.&amp;nbsp; &lt;/p&gt;&lt;p&gt;&lt;em&gt;Cette nouvelle fonctionnalit&amp;eacute; est &lt;strong&gt;disponible d&amp;egrave;s  maintenant&lt;/strong&gt;,  pour l&amp;#39;essayer, &lt;a href="https://www.incwo.com/site/compte" target="_blank"&gt;connectez-vous   sur votre application&lt;/a&gt;.&amp;nbsp; &lt;/em&gt;&lt;/p&gt;</description>
            //            <pubDate>Thu, 31 Jan 2013 14:40:00 +0100</pubDate>
            //            <guid isPermaLink="false">urn:uuid:839186df-9948-4c67-a548-f86b50832375</guid>
            //            <author>incwo</author>
            //            <link>http://blog.incwo.com/articles/2013/01/31/recevez-des-documents-dans-vos-emails-de-rappels-de-t%C3%A2che-et-de-rendez-vous</link>
            //            <category>Nos applications</category>
            //            <category>taches</category>
            //            <category>evenements</category>
            //            <category>documents</category>
            //        </item>
            
            [decoder startElement:@"rss" withBlock:^{
                [decoder startElement:@"channel" withBlock:^{
                    [decoder startElement:@"item" withBlock:^{
                    
                        item = [NSMutableDictionary dictionary];
                        
                        [decoder endElement:@"title" withBlock:^{
                            item[@"title"] = decoder.currentStringStripped ?: @"";
                        }];
                        [decoder endElement:@"description" withBlock:^{
                            item[@"HTML"] = decoder.currentStringStripped ?: @"";
                        }];
                        [decoder endElement:@"pubDate" withBlock:^{
                            NSDate* date = [NSDate dateWithHTTPDate:decoder.currentStringStripped ?: @""];
                            if (date) item[@"date"] = date;
                        }];
                        [decoder endElement:@"guid" withBlock:^{
                            item[@"UUID"] = decoder.currentStringStripped ?: @"";
                        }];
                        [decoder endElement:@"link" withBlock:^{
                            // TODO: parse the created_at into a NSDate object
                            NSURL* url = [NSURL URLWithString:decoder.currentStringStripped];
                            if (url) item[@"URL"] = url;
                        }];
                    }];
                    [decoder endElement:@"item" withBlock:^{
                        if (item.count > 0) [newsItems addObject:item];
                    }];
                }];
            }];
        }];
        
        if (xmlDecoder.error)
        {
            NSLog(@"News RSS parsing error: %@", xmlDecoder.error);
        }
        //NSLog(@"Parsed %d video items: %@", videoItems.count, videoItems);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (xmlDecoder.error) {
                [self FCL_presentAlertForError:xmlDecoder.error];
            }
            
            if (newsItems.count > 0)
            {
                self.newsItems = newsItems;
                [self markAllAsReadOnce];
                [self.tableView reloadData];
                [self updateUnreadCounts];
            }
        });
    });
}




#pragma mark - Read Count



#define kItemsMarkedAsRead @"FCLNewsItemsMarkedAsReadV2"

- (void) updateUnreadCounts
{
    int count = (int)[self unreadCount];
    self.title = NSLocalizedString(@"Actualités", @""); //[NSString stringWithFormat:@"%@ (%d)", NSLocalizedString(@"Actualités", @""), count];
    self.tabBarItem.title = NSLocalizedString(@"Actualités", @"");
    self.tabBarItem.badgeValue = count > 0 ? [NSString stringWithFormat:@"%d", count] : nil;
}

- (NSUInteger) unreadCount
{
    NSMutableSet* set = [NSMutableSet setWithArray:[self.newsItems valueForKey:@"UUID"]];
    [set minusSet:[NSSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kItemsMarkedAsRead] ?: @[]]];
    return set.count;
}

- (void) markAllAsReadOnce
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kItemsMarkedAsRead])
    {
        [self markAllAsRead];
    }
}

- (void) markAllAsRead
{
    [[NSUserDefaults standardUserDefaults] setObject:([self.newsItems valueForKey:@"UUID"] ?: @[]) forKey:kItemsMarkedAsRead];
}

- (void) markItemAsRead:(NSString*)uuid
{
    if (!uuid) return;
    
    NSMutableSet* set = [NSMutableSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kItemsMarkedAsRead] ?: @[]];
    if (!set)
    {
        set = [NSMutableSet set];
    }
    [set addObject:uuid];
    
    // Make sure we do not accumulate uuids for the news not accessible anymore.
    if (self.newsItems.count > 0)
    {
        [set intersectSet:[NSSet setWithArray:[self.newsItems valueForKey:@"UUID"]]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[set allObjects] forKey:kItemsMarkedAsRead];
    [self updateUnreadCounts];
}

- (BOOL) isItemRead:(NSString*)uuid
{
    if (!uuid) return NO;
    return [[[NSUserDefaults standardUserDefaults] objectForKey:kItemsMarkedAsRead] containsObject:uuid];
}






#pragma mark - UITableView



- (NSInteger)tableView:(UITableView*)aTableView numberOfRowsInSection:(NSInteger)section
{
    return self.newsItems.count;
}

- (UITableViewCell *)tableView:(UITableView*)aTableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString* reuseIdentifier = @"Cell";
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    if (!_cellNib)
    {
        _cellNib = [UINib nibWithNibName:@"FCLNewsCellContentView" bundle:nil];
    }
    
    if (cell.contentView.subviews.count == 0)
    {
        UIView* v = [_cellNib instantiateWithOwner:nil options:nil][0];
        [cell.contentView addSubview:v];
        v.frame = cell.contentView.bounds;
    }
    
    UIView* contentView = cell.contentView.subviews[0];
    UILabel* dateLabel = (id)[contentView viewWithTag:1];
    UILabel* titleLabel = (id)[contentView viewWithTag:2];
    
    id item = self.newsItems[indexPath.row];
    
    dateLabel.text = item[@"date"] ? [self.dateFormatter stringFromDate:item[@"date"]] : @"";
    titleLabel.text = item[@"title"] ?: @"";
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

-(NSDateFormatter *) dateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    });
    
    return dateFormatter;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = self.newsItems[indexPath.row];
    UIView* contentView = cell.contentView.subviews[0];
    UILabel* titleLabel = (id)[contentView viewWithTag:2];
    
    {
        BOOL itemRead = [self isItemRead:item[@"UUID"]];
        
        titleLabel.font = itemRead ? [UIFont systemFontOfSize:16.0] : [UIFont boldSystemFontOfSize:16.0]; // standard font size
        titleLabel.textColor = itemRead ? [UIColor colorWithWhite:0.2 alpha:1.0] : [UIColor blackColor];
        CGRect rect = titleLabel.frame;
        CGSize boundedSize = CGSizeMake(rect.size.width, 10);
        CGSize size = [titleLabel sizeThatFits:boundedSize];
        //NSLog(@"size that fits: %@ => %@", NSStringFromCGSize(boundedSize), NSStringFromCGSize(size));
        rect.size.height = MIN(58.0, size.height);
        titleLabel.frame = rect;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    id item = self.newsItems[indexPath.row];
    NSUInteger viewPortWidth = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 600 : 800;
    
    NSString* stylePrefix =
    [NSString stringWithFormat:@"<html><head><meta name=\"viewport\" content=\"width=%lu\"></head><body>"
    "<style>\n"
        " *{ font-family: sans-serif}\n"
        " body{ padding:10px}\n"
        " h1{ margin: 0 0 10px 0; font-size:2em; }\n"
    "</style>\n", (unsigned long)viewPortWidth];
    
    NSString *content = item[@"HTML"];
    NSString *httpsContent = [content stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    NSString *html = [[stylePrefix stringByAppendingFormat:@"<h1>%@</h1>", item[@"title"]] stringByAppendingString:httpsContent];
    FCLWebViewController* vc = [[FCLWebViewController alloc] initWithHTML:html baseURL:item[@"URL"]];
    vc.title = NSLocalizedString(@"Article", @"");
    [self.navigationController pushViewController:vc animated:YES];
    
    [self markItemAsRead:item[@"UUID"]];
}



@end
