#import "facilescan-Swift.h"
#import "FCLNewsViewController.h"
#import "FCLWebViewController.h"
#import "PStringExtensions.h"
#import "PDateExtension.h"
#import "OAXMLDecoder.h"
#import "OANetworkActivityIndicator.h"
#import "UIViewController+Alert.h"

@interface FCLNewsViewController ()

@property NSArray <NewsItem *> *newsItems;
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
        NSError *error;
        NSArray *newsItems = [self newItemsFromXMLData:data error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (!newsItems) {
                NSLog(@"News RSS parsing error: %@", error);
                [self FCL_presentAlertForError:error];
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

-(NSArray <NewsItem *> *)newItemsFromXMLData:(NSData *)data error:(NSError **)outError {
    NSMutableArray* newsItems = [NSMutableArray array];
    OAXMLDecoder* xmlDecoder = [OAXMLDecoder parseData:data withBlock:^(OAXMLDecoder *decoder) {
        
        [decoder startElement:@"rss" withBlock:^{
            [decoder startElement:@"channel" withBlock:^{
                __block NewsItem *item = nil;
                [decoder startElement:@"item" withBlock:^{
                    item = [[NewsItem alloc] init];
                    
                    [decoder endElement:@"title" withBlock:^{
                        item.title = decoder.currentStringStripped ?: @"";
                    }];
                    [decoder endElement:@"description" withBlock:^{
                        item.html = decoder.currentStringStripped ?: @"";
                    }];
                    [decoder endElement:@"pubDate" withBlock:^{
                        NSDate* date = [NSDate dateWithHTTPDate:decoder.currentStringStripped ?: @""];
                        if (date) item.date = date;
                    }];
                    [decoder endElement:@"guid" withBlock:^{
                        item.uuid = decoder.currentStringStripped ?: @"";
                    }];
                    [decoder endElement:@"link" withBlock:^{
                        // TODO: parse the created_at into a NSDate object
                        NSURL* url = [NSURL URLWithString:decoder.currentStringStripped];
                        if (url) item.url = url;
                    }];
                }];
                [decoder endElement:@"item" withBlock:^{
                    if ([item anyFieldSet]) [newsItems addObject:item];
                }];
            }];
        }];
    }];
    
    if (xmlDecoder.error) {
        *outError = xmlDecoder.error;
        return nil;
    }
    
    return newsItems;
}

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


#pragma mark - Read Count



#define kItemsMarkedAsRead @"FCLNewsItemsMarkedAsReadV2"

- (void) updateUnreadCounts
{
    int count = (int)[self unreadCount];
    self.title = NSLocalizedString(@"Actualités", @"");
    self.tabBarItem.title = NSLocalizedString(@"Actualités", @"");
    self.tabBarItem.badgeValue = count > 0 ? [NSString stringWithFormat:@"%d", count] : nil;
}

- (NSUInteger) unreadCount
{
    NSMutableSet* set = [NSMutableSet setWithArray:[self.newsItems valueForKey:@"uuid"]];
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
    [[NSUserDefaults standardUserDefaults] setObject:([self.newsItems valueForKey:@"uuid"] ?: @[]) forKey:kItemsMarkedAsRead];
}

- (void) markItemAsRead:(NewsItem *)newsItem
{
    if (!newsItem.uuid) return;
    
    NSMutableSet* set = [NSMutableSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kItemsMarkedAsRead] ?: @[]];
    if (!set)
    {
        set = [NSMutableSet set];
    }
    [set addObject:newsItem.uuid];
    
    // Make sure we do not accumulate uuids for the news not accessible anymore.
    if (self.newsItems.count > 0)
    {
        [set intersectSet:[NSSet setWithArray:[self.newsItems valueForKey:@"uuid"]]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[set allObjects] forKey:kItemsMarkedAsRead];
    [self updateUnreadCounts];
}

- (BOOL) isItemRead:(NewsItem *)newsItem
{
    if (!newsItem.uuid) return NO;
    return [[[NSUserDefaults standardUserDefaults] objectForKey:kItemsMarkedAsRead] containsObject:newsItem.uuid];
}


#pragma mark - UITableView

- (NSInteger)tableView:(UITableView*)aTableView numberOfRowsInSection:(NSInteger)section
{
    return self.newsItems.count;
}

- (UITableViewCell *)tableView:(UITableView*)aTableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NewsItem *item = self.newsItems[indexPath.row];
    NewsItemCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"NewsItemCell" forIndexPath:indexPath];
    cell.date = item.date;
    cell.title = item.title;
    cell.isRead = [self isItemRead:item];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    NewsItem *item = self.newsItems[indexPath.row];
    [self presentWebPageForItem:item];
    [self markItemAsRead:item];
}

-(void) presentWebPageForItem:(NewsItem *)item {
    NSUInteger viewPortWidth = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 600 : 800;
    
    NSString* stylePrefix =
    [NSString stringWithFormat:@"<html><head><meta name=\"viewport\" content=\"width=%lu\"></head><body>"
     "<style>\n"
     " *{ font-family: sans-serif}\n"
     " body{ padding:10px}\n"
     " h1{ margin: 0 0 10px 0; font-size:2em; }\n"
     "</style>\n", (unsigned long)viewPortWidth];
    
    NSString *httpsContent = [item.html stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    NSString *html = [[stylePrefix stringByAppendingFormat:@"<h1>%@</h1>", item.title] stringByAppendingString:httpsContent];
    FCLWebViewController* vc = [[FCLWebViewController alloc] initWithHTML:html baseURL:item.url];
    vc.title = NSLocalizedString(@"Article", @"");
    [self.navigationController pushViewController:vc animated:YES];
}



@end
