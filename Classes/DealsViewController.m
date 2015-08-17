#import "DealsViewController.h"
#import "Entry.h"
#import "EntryTableViewCell.h"
#import "LocationViewController.h"
#import "EntriesAppDelegate.h"
#import "ActivityLogger.h"
#import "FilterPicker.h"
#import "FilterButton.h"
#import "EntryCollection.h"
#import	"Props.h"
#import "SMLog.h"
#import "SMRichTextViewer.h"
#import "SearchCell.h"
#import "DownloadStatus.h"
#import "ImageManipulator.h"
#import "Deal.h"


#define kShowTitle @"Show all deals"
#define kHideTitle @"Only show deals for this entry"

@interface DealsViewController (Private)

- (void) showGoLeaveGuideAlert;
- (NSString*) generateHTML;
- (void) goToEntry: (NSNumber*) theEntryIdObject;

@end

@implementation DealsViewController 

@synthesize entry, dealURL;
    
- (id)init {
    
    self = [super init];
	if (self) {
		
		self.title = @"Deals!";
		self.tabBarItem.image = [UIImage imageNamed: @"deals_icon.png"];
		self.navigationItem.title= @"Deals!"; //@"Best of SF";
        self.navigationItem.titleView = nil;
		// Set sort criteria for initial view
        self.hidesBottomBarWhenPushed = FALSE; 
				
		//Set the custom back image for getting back here from LocationViewController
		//UIImage *backImage =[[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"backToList" ofType:@"png"]];
        UIImage *backImage = [UIImage imageNamed:@"backToList.png"];
		UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backImage style: UIBarButtonItemStylePlain target:nil action:nil];
		
		//[backImage release];
		
		self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
		
        
        showAllDeals = TRUE;
		
		}

	return self;
}


- (id) initWithEntry:(Entry*) theEntry {
    
    self = [super init];
	if (self) {
        
        self.entry = theEntry;
        showAllDeals = FALSE;
		
    }
    
	return self;
}


- (void)dealloc {
	
	NSLog(@"DVC.dealloc**********************************************");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    dealView.delegate = nil;
     
}


- (void)loadView {
    
	UIView *contentView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - kTabBarHeight - kTitleBarHeight)];
    contentView.backgroundColor = [UIColor darkGrayColor];
    contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	self.view = contentView;
    
    dealView = [[UIWebView alloc] initWithFrame: CGRectMake(0, 0, [Props global].screenWidth + 1, [Props global].screenHeight - kTabBarHeight - kTitleBarHeight)];
    dealView.backgroundColor = [UIColor darkGrayColor];
    dealView.dataDetectorTypes = UIDataDetectorTypePhoneNumber;
    
    dealView.scalesPageToFit = NO;
    dealView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    dealView.delegate = self;	
    
    /*NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    [sharedCache release];*/
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    baseURL = [NSURL fileURLWithPath:path];
    
    [self.view addSubview:dealView];
    
    if (entry != nil) {
        UIBarButtonItem *showOthersButton = [[UIBarButtonItem alloc] initWithTitle: kShowTitle style:UIBarButtonItemStylePlain target:self action:@selector(showOrHideAllDeals:)];
        self.navigationItem.rightBarButtonItem = showOthersButton;
    }
    
	
	self.navigationController.navigationBar.translucent = FALSE;
}


-(void)viewWillAppear:(BOOL)animated {
	
	//used to make tab bar show completely if we hid it a bit in the slideshow view previously
	self.navigationController.navigationBar.translucent = FALSE;
	[self.navigationController setNavigationBarHidden:FALSE animated:FALSE];
		
	self.navigationController.navigationBar.alpha = .9;
	self.navigationController.navigationBar.tintColor = [Props global].navigationBarTint;
	self.navigationController.navigationBar.hidden = FALSE;
	//if ([Props global].sortable)[[FilterPicker sharedFilterPicker] showSorterPicker];
	
	if ([Props global].deviceType != kiPad) {
        if ([[Props global] inLandscapeMode] && [Props global].osVersion > 3.1){
            
            //original version for regular app
            float xPos =  [[UIDevice currentDevice] orientation]==UIDeviceOrientationLandscapeLeft ? -kPartialHideTabBarHeight : 0;
            if(![Props global].isShellApp) self.tabBarController.view.frame = CGRectMake( xPos,0, [Props global].screenHeight + kPartialHideTabBarHeight, [Props global].screenWidth);
            
            //update for SW - WHY????
            else self.tabBarController.view.frame = CGRectMake( 0,0, [Props global].screenWidth, [Props global].screenHeight + kPartialHideTabBarHeight);
        }
        
        else self.tabBarController.view.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
	}

    
    [dealView loadHTMLString:[self generateHTML] baseURL:baseURL];
    
    [super viewWillAppear:animated];
}


- (void) viewDidAppear:(BOOL)animated {
    
    NSLog(@"DVC - viewDidAppear called");
    
    [super viewDidAppear:animated];
}


-(void)viewWillDisappear:(BOOL)animated {
	
	NSLog(@"DVC - viewWillDisappear");
}


- (BOOL)prefersStatusBarHidden {
    
    return YES;
}


- (NSString*) generateHTML {
    
    NSString *header = @"<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>\
    <html lang='en-US' xmlns='http://www.w3.org/1999/xhtml' dir='ltr'>\
    <head>\
	<title>Deals</title>\
	<meta http-equiv='Content-type' content='text/html; charset=utf-8' />\
	<meta name='viewport' content='width=device-width, initial-scale=0.5, maximum-scale=0.5, minimum-scale=0.5'/>\
    \
	<link rel='shortcut icon' href='favicon.ico' />\
	<link rel='stylesheet' href='deals_style.css' type='text/css' media='all' />\
    </head>\
    <body>\
    <div class='list'>\
	<ul>";
    
    
    NSMutableString *htmlDescription = [NSMutableString stringWithString:@""]; 
    
    NSArray *deals;
    
    if (showAllDeals) {
        NSMutableArray * mutableDealsArray = [[NSMutableArray alloc] init];
        
        @synchronized([Props global].dbSync) {
    
            FMDatabase * db = [EntryCollection sharedContentDatabase];
                        
            FMResultSet * rs = [db executeQuery:@"SELECT *, rowid FROM deals"];
            
            while ([rs next]) {
                
                Deal *deal = [[Deal alloc] initWithRow:rs];
                [mutableDealsArray addObject:deal];
            }
            
            [rs close];
        }
        
        deals = [NSArray arrayWithArray:mutableDealsArray];
        
    }
    
    else deals = [entry createDealsArray];
        
    for (Deal *deal in deals) {
        
        NSString *dealHeader = [NSString stringWithFormat:@"\
                              <li>\
                              <div class='inner'>\
                              <div class='item-head'>\
                              <a href='%@' class='btn'>get deal</a>\
                              <h2>%@</h2>\
                              </div>",deal.url, deal.title];
        
        NSString *dealBody = [NSString stringWithFormat:@"\
                              <div class='item-body'>\
                              <div class='img'>\
                              <img src='%@' alt='' height = '104 px' width = '150 px'/>\
                              <span class='price'>%@</span>\
                              </div>\
                              \
                              <div class='cnt'>\
                              <h3>%@ <span>$%0.0f value</span></h3>\
                              <p>%@</p>\
                              </div>", deal.imageFileLocation, deal.priceString, deal.discountString, deal.value, deal.description];
        
        NSString *dealFooter;
        
        if (entry == nil || showAllDeals) {
            /*dealFooter = [NSString stringWithFormat:@"\
                          </div>\
                          \
                          <div class='item-footer'>\
                          <p class='exp-date'>Exp %@</p>\
                          <p class='right'>\
                          <a class='SMEntryLink' href='SMEntryLink://%i'>%@</a>\
                          <span>%@</span>\
                          </p>\
                          </div>\
                          </div>\
                          </li>", deal.expiration, deal.entry.entryid, deal.entryName, @" "];*/
            dealFooter = [NSString stringWithFormat:@"\
                            </div>\
                            \
                            <div class='item-footer'>\
                            <p class='exp-date'>Exp %@</p>\
                            <p class='right'>\
                            <a class='SMEntryLink' href='SMEntryLink://%i'>%@</a>\
                            <span>%@</span>\
                            </p>\
                            </div>\
                            </div>\
                            </li>", deal.expiration, deal.entry.entryid, deal.entryName, deal.distanceString];
        }
        
        else 
            dealFooter = [NSString stringWithFormat:@"\
                          </div>\
                          \
                          <div class='item-footer'>\
                          <p class='exp-date'>Exp %@</p>\
                          <p class='right'>\
                          %@\
                          <span>%@</span>\
                          </p>\
                          </div>\
                          </div>\
                          </li>", deal.expiration, deal.entryName, deal.distanceString];
    
        
        NSString *dealHTML = [NSString stringWithFormat:@"%@%@%@", dealHeader, dealBody, dealFooter];
        [htmlDescription appendString:dealHTML];
    }
    
    
    NSString *footer = @"</ul></div></body></html>";
    
    NSString *formattedString = [NSString stringWithFormat:@"%@%@%@",header,htmlDescription,footer];
    
    //[deals release];
    //NSLog(@"Formatted string = %@", formattedString);
    
    return formattedString;
}

#pragma mark CREATE VIEWS AND BUTTONS




#pragma mark BUTTON ACTION METHODS
- (void) showOrHideAllDeals: (id) sender {
    
	NSLog(@"Time to show or hide others");
	UIBarButtonItem *showHideOthers = (UIBarButtonItem*) sender;
	
	if ([showHideOthers.title isEqualToString:kShowTitle]){
		showHideOthers.title = kHideTitle;
        showAllDeals = TRUE;
        [dealView loadHTMLString:[self generateHTML] baseURL:baseURL];
	}
	
	else {
		showHideOthers.title = kShowTitle;
        showAllDeals = FALSE;
        [dealView loadHTMLString:[self generateHTML] baseURL:baseURL];
	}
}


- (void) showGoLeaveGuideAlert {
	
	NSLog(@"Got message to show go to leave guide alert");
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: nil message:@"Want to leave the guide and go get this deal?" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Go for it!", nil];
	[alert show];
}


- (void)goToExternalWebPageWithURL:(NSURL*) webPageURL  {
	
	NSLog(@"About to open external url = %@", [webPageURL absoluteString]);
	
	if (![[UIApplication sharedApplication] openURL:webPageURL])
	{
		SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVErrorGoingToAppStore];
		log.entry_id = entry.entryid;
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}
}


#pragma mark DELEGATE METHODS

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        
        NSString *scheme = [request.URL scheme];
        
        if ([scheme caseInsensitiveCompare:@"SMEntryLink"] == NSOrderedSame) {
            
            NSString *idString = [[[request.URL resourceSpecifier] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"//" withString:@""];
            
            int entryID = [idString intValue]; 
            NSLog(@"abs string = %@, id string = %@ and id = %i", [request.URL absoluteString], idString, entryID);
            [self goToEntry:[NSNumber numberWithInt:entryID]];
            return NO;
        }
        
        else if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
            self.dealURL = request.URL;
            [self showGoLeaveGuideAlert];
            
            return FALSE;
        }
    }
    
    return TRUE;
}


-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
	
		if (buttonIndex != 0) {
			
			/*[Apsalar eventWithArgs:@"get deal",
			 @"entry id", [NSNumber numberWithInt:entry.entryid],
			 @"entry name", entry.name,
			 nil];*/
            
            SMLog *log = [[SMLog alloc] initWithPageID: kTLDV actionID: kGetDeal];
            [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
            
            [self goToExternalWebPageWithURL: dealURL];
        }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	//NSLog(@"ETVC.shouldAutorotateToInterfaceOrientation");
    
    if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        
        return YES;
    }
    
    else return NO;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	if (toInterfaceOrientation != UIDeviceOrientationFaceUp && toInterfaceOrientation != UIDeviceOrientationFaceDown && toInterfaceOrientation != UIDeviceOrientationUnknown) {
        
        [[Props global] updateScreenDimensions: toInterfaceOrientation];
	}
}



- (void) goToEntry: (NSNumber*) theEntryIdObject {
    
    int theEntryId = [theEntryIdObject intValue];
    //self.tabBarController.view.frame = [[UIScreen mainScreen] bounds];
    self.tabBarController.view.frame = [Props global].isShellApp ? CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight) : [[UIScreen mainScreen] bounds];
    
	LocationViewController *entryController = [[LocationViewController alloc] initWithController: nil];
	
	// set the entry for the controller
	entryController.entry = [EntryCollection entryById:theEntryId];
	
	// push the entry view controller onto the navigation stack to display it
	[[self navigationController] pushViewController:entryController animated:YES];
	[entryController.view setNeedsDisplay];
	
	//log event
	SMLog *log = [[SMLog alloc] initWithPageID: kTLCV actionID: kCVGoToEntry];
	log.entry_id = entryController.entry.entryid;
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	
}


- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

	if ([Props global].deviceType != kiPad && [Props global].osVersion >= 4.0 && [[Props global] inLandscapeMode]){
		
		float xPos =  [[UIDevice currentDevice] orientation]==UIDeviceOrientationLandscapeLeft ? -kPartialHideTabBarHeight : 0;
		
		[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
		[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
		[ UIView setAnimationDuration: 0.2f ]; 
		
        //original version for regular app
		if(![Props global].isShellApp) self.tabBarController.view.frame = CGRectMake( xPos,0, ([Props global].screenHeight + kPartialHideTabBarHeight), [Props global].screenWidth);
        
        //update for SW - WHY????
        else self.tabBarController.view.frame = CGRectMake( 0,0, [Props global].screenWidth, [Props global].screenHeight + kPartialHideTabBarHeight);
		
		[ UIView commitAnimations ];
	}
}


@end
