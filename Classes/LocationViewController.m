// Manages root entry level view

 
#import "LocationViewController.h"
#import "DetailView.h"
#import "Entry.h"
#import "Constants.h"
#import "SlideController.h"
#import "WebViewController.h"
#import "LocationManager.h"
#import "ActivityLogger.h"
#import "DataDownloader.h"
#import "Props.h"
#import	"EntriesTableViewController.h"
#import	"CommentPageView.h"
#import	"FilterPicker.h"
#import "SMLog.h"
#import "SMPitch.h"
#import "SMRichTextViewer.h"
#import "EntryCollection.h"
#import "YouTubePlayer.h"
#import "CommentsViewController.h"
#import "SutroView.h"
#import "MapViewController.h"
#import "EntryMapView.h"
#import <QuartzCore/QuartzCore.h> //used for generating map icon 
#import "MyStoreObserver.h"
#import "Region.h"
#import "DownloadOperation.h"
#import "DealsViewController.h"


#define kQuarterTurnCCW     -kPI/2
#define kQuarterTurnCW      kPI/2
#define kITunesButtonTag    2
#define kTitleLabelTag      3
#define kFavoritesAlertTag  4
#define kUpgradeAlertTag    5
#define kAppStoreAlertTag   6
#define kiTunesAlertTag     7
#define kCallAlertTag       8
#define kSampleContentTag   9
#define kSampleContentWarningTag 10
#define kDownloadObserverKeyPath @"operations"
#define kFirstFavoriteSaved @"First_favorite_saved"

#define kUpgradeViews 4839373
#define kWaitingForAppStoreMessageTag 4239867
#define kThankYouTag 9349873


@interface LocationViewController (PrivateMethods)

- (BOOL) isYouTubeURL:(NSString*) urlString;
- (BOOL) isiTunesURL: (NSString*) urlString;
- (void) showMap:(id)sender;
- (void) showPics:(id)sender;
- (void) createDetailView;
- (void) showDetailView:(id)sender;
- (void) showWebPageViewWithURL:(NSURL*) theURL;
- (void) goToExternalWebPageWithURL:(NSURL*) webPageURL;
- (void) showGoToAppStoreAlert: (id) sender; 
- (void) showGoToiTunesAlert;
- (void) addTitleLabel;
- (void) launchMailAppOnDevice;
- (void) displayComposerSheet;
- (void) loadEntry:(Entry*) theEntry;
- (void) loadNextEntry;
- (void) showCommentsViewOrUpdateFavorites:(id)sender;
- (void) showShareView;
- (NSString*) getYouTubeVideoIdWithURLString:(NSString*)urlString;
- (NSString *)flattenHTML:(NSString *)html;
- (void) addGetOniTunesBarButton;
- (void) updateFavorites:(id)sender;
- (void) createMapIcon;
- (BOOL) isOfflineContentURL:(NSString*) urlString;
- (UIImage*) rotateImage:(UIImage*) src rotationAngle:(float) radians;
- (UIImage*) captureScreen;
- (void) addDownloadButton;
- (void) goToEntryWithId:(NSNumber*) theEntryIdObject;
- (void) launchMailAppOnDeviceForRecipient:(NSString *) recipient;
- (void) displayComposerSheetForRecipient:(NSString*) recipient;
- (void) updateFrameForOffset:(float) offset;
- (void) createAdBannerView;
- (void) fixupAdView;
- (void) createToolbar;

@end

@implementation LocationViewController

@synthesize entry, pitch, moving, detailScrollView, richTextViewer, showGoToTopButton, canScrollToPrevious, canScrollToNext, goToNextOrPreviousEntry, operationQueue; 

//iAd Synthesizes
@synthesize adView, adBannerIsVisible;

- (id)initWithController: (EntriesTableViewController*) theTableViewController {
	
    self = [super init];
	if (self) {
		
        loadTimer = [NSDate date];
        self.entry = nil;
		detailView = nil;
        self.detailScrollView = nil;
		videoPlayer = nil;
		self.pitch = nil;
		iTunesURL = nil;
		counter = 0;
        entryLoadingCounter = 0;
		refreshTimer = nil;
		self.richTextViewer = nil;
		entryLoaded = NO;
		controller = theTableViewController;
		self.moving = FALSE;
		self.showGoToTopButton = FALSE;
		titleBarImage_portrait = nil;
		titleBarImage_landscape = nil;
		lastScrollPosition = 0;
		scrollPastTime = nil;
		goToNextOrPreviousEntry = FALSE;
		
		//Remove any subviews from other views
		for (UIView *subview in [self.navigationController.navigationBar subviews]) {
			[subview removeFromSuperview];
		}
		
		self.hidesBottomBarWhenPushed = YES;  //***** deleted this to get fix bug with buttons. No idea why it worked.
		
		self.navigationItem.leftBarButtonItem = nil;
		self.navigationItem.rightBarButtonItem = nil;
		
		//Set back image for returning to this view
		//UIImage *backImage =[UIImage imageNamed:@"back.png"];
		//UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backImage style: UIBarButtonItemStylePlain target:nil action:nil];
		//self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
		
		entryHistory = [NSMutableArray new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freemiumUpgradePurchased) name:kFreemiumUpgradePurchased object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionFailed) name:kTransactionFailed object:nil];
    
		}
	
	return self;
}

- (void)dealloc {

    controller = nil;
	
	self.detailScrollView.delegate = nil;
    
    self.adView.delegate = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.operationQueue removeObserver:self forKeyPath:kDownloadObserverKeyPath];
    [operationQueue cancelAllOperations];
	
	if (self.richTextViewer != nil) richTextViewer.delegate = nil;
	
	if (entryHistory != nil) { entryHistory = nil;}
	
	
	
	if (videoPlayer != nil) { videoPlayer = nil;}
	
	if ([Props global].appID <= 1) {
		
		for (UIView *subview in [self.navigationController.navigationBar subviews]) {
			if (subview.tag == kTitleLabelTag || subview.tag == kITunesButtonTag) {
				[subview removeFromSuperview];
			}
		}
	}
	
    NSLog(@"LocationViewController dealloc called");
}


- (void)loadView {	
	
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	
	UIView *contentView = [[UIView alloc] initWithFrame:screenRect];
	
	self.view = contentView;
	
	self.view.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0]; //[Props global].entryViewBGColor;
    
    //if ([[[self navigationController] viewControllers] count] == 2) entry.lastScrollPosition = 0;
    entry.lastScrollPosition = 0;
}


- (void) viewWillAppear:(BOOL) animated {
	
    NSLog(@"LVC.viewWillAppear: start time = %0.2f", -[loadTimer timeIntervalSinceNow]);
    
	shouldScrollTableView = NO;
	self.navigationController.navigationBar.translucent = TRUE;
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	self.navigationController.navigationBar.tintColor = [Props global].navigationBarTint_entryView;
	[self.navigationController setNavigationBarHidden:FALSE animated:FALSE];
	
	[self loadEntry:entry];
	
    [self addTitleLabel];
    
    NSLog(@"Content offset = %f", detailScrollView.contentOffset.y);
    detailScrollView.contentOffset = CGPointMake(0, 0);
    
    [super viewWillAppear:animated];
    
    NSLog(@"LVC.viewWillAppear: finish time = %0.2f", -[loadTimer timeIntervalSinceNow]);
}


- (void) viewDidAppear:(BOOL) animated {
	
    NSLog(@"LVC.viewDidAppear: start time = %0.2f", -[loadTimer timeIntervalSinceNow]);
    
    NSLog(@"LVC.viewDidAppear: finish time = %0.2f", -[loadTimer timeIntervalSinceNow]);
    
    [super viewDidAppear:animated];
}


- (void) viewWillDisappear:(BOOL)animated {
	
	//if (detailView.createMapIcon) [self createMapIcon];
	if ([Props global].appID <= 1) {
		
		for (UIView *subview in [self.navigationController.navigationBar subviews]) {
			if (subview.tag == kTitleLabelTag || subview.tag == kITunesButtonTag) {
				[subview removeFromSuperview];
			}
		}
	}
	
	if (refreshTimer != nil) {
		[refreshTimer invalidate];
		refreshTimer = nil;
	}
	
	if([controller isMemberOfClass:[EntriesTableViewController class]] && shouldScrollTableView) {
		NSLog(@"About to scroll table view to row %i", controller.rowToGoBackTo.row);
		NSIndexPath *thePath = controller.rowToGoBackTo;
		
		if (controller.rowToGoBackTo.row < 5 && [[EntryCollection sharedEntryCollection].sortedEntries count] > 5){
			unsigned indexes[2] = {0,5};
			thePath = [NSIndexPath indexPathWithIndexes:indexes length:2];
		}
		
		[controller.theTableView scrollToRowAtIndexPath: thePath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
	}
    
    self.navigationController.toolbarHidden = TRUE;
    
    [super viewWillDisappear:animated];
}


- (BOOL)prefersStatusBarHidden {
    
    return YES;
}


- (void) loadEntry:(Entry*) theEntry {
    	
    NSLog(@"LVC.loadEntry with id = %i", entry.entryid);

    self.entry = theEntry;
	[entry hydrateEntry];
    
    //if ([Props global].isShellApp && [Props global].isFreeSample) {
	if ([Props global].isFreeSample || [Props global].freemiumType == kFreemiumType_V2) {
        
        NSString *sampleListKey = [NSString stringWithFormat:@"%@-%i", kSampleEntryList, [Props global].appID];
        NSMutableArray *sampleList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:sampleListKey]];
        
        if (sampleList == nil) sampleList = [NSMutableArray new];
        
        if ([sampleList containsObject:[NSNumber numberWithInt:entry.entryid]]) {
            NSLog(@"Can show entry");
        }
        
        else if ([sampleList count] < [Props global].freemiumNumberofSampleEntriesAllowed) {
            [sampleList addObject:[NSNumber numberWithInt:entry.entryid]];
            [[NSUserDefaults standardUserDefaults] setObject:sampleList forKey:sampleListKey];
			
			NSString *freeSampleMessage = [NSString stringWithFormat:@"You've viewed %i of %i sample entries.", [sampleList count], [Props global].freemiumNumberofSampleEntriesAllowed];
			
			NSString *upgradePrice = [[MyStoreObserver sharedMyStoreObserver] getUpgradePrice];
			
			NSString *upgradeButtonTitle = upgradePrice == nil ? @"Upgrade" : [NSString stringWithFormat:@"Upgrade - %@", upgradePrice];
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message: freeSampleMessage delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:upgradeButtonTitle, @"Restore Purchase", nil];
			alert.tag = kSampleContentWarningTag;
			
			[alert show];
        }
        
        else {
            NSLog(@"Time to show purchase popup");
            /*//UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"You've viewed all your sample content. Want to buy the guide to see the rest?" delegate: self cancelButtonTitle:nil otherButtonTitles:@"Not now", @"Buy", nil];
            alert.tag = kSampleContentTag;
            
            [alert show];*/
			
			if ([Props global].isFreeSample) {
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message: @"You've viewed all your sample content. Want to buy the guide to see the rest?" delegate: self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
				alert.tag = kSampleContentTag;
				
				[alert show];
			}
			
			else {
				
				NSString *freeSampleMessage = @"You've viewed all your sample content. Want to upgrade to see the rest?";
				
				NSString *upgradePrice = [[MyStoreObserver sharedMyStoreObserver] getUpgradePrice];
				
				NSString *upgradeButtonTitle = upgradePrice == nil ? @"Upgrade" : [NSString stringWithFormat:@"Upgrade - %@", upgradePrice];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message: freeSampleMessage delegate: self cancelButtonTitle:@"Not now" otherButtonTitles:upgradeButtonTitle, nil];
				alert.tag = kSampleContentTag;
				
				[alert show];
			}
        }
    }

    
    NSString *entryPhotoDownloadNotificationName = [NSString stringWithFormat:@"%@_%i", kDownloadEntryPhotos, [Props global].appID];
    [[NSNotificationCenter defaultCenter] postNotificationName:entryPhotoDownloadNotificationName object:entry];
	
	scrollCounter = 0;
	counter = 0;
	scrollOffsetHasReset = FALSE;
	titleBarImage_portrait = nil;
	titleBarImage_landscape = nil;
	goToNextEntry = FALSE;
	goToPreviousEntry = FALSE;
	self.navigationItem.titleView = nil;
	self.navigationController.navigationBar.translucent = TRUE;
	[self.navigationController setNavigationBarHidden:FALSE animated:FALSE];
	self.canScrollToPrevious = FALSE;
	self.canScrollToNext = FALSE;
	if (videoPlayer != nil) videoPlayer = nil;
	
	if([controller isMemberOfClass:[EntriesTableViewController class]] && [self.navigationController.viewControllers count] <= 2){
        
        //NSLog(@"LVC.loadEntry: Index of object = %i", [controller.dataSource.sortedEntries indexOfObject:entry]);

        EntriesTableViewController *theController = (EntriesTableViewController*) controller;
        if (theController.sortCriteria == [Props global].spatialCategoryName) {
            int regionIndex = 0;
            int entryIndex = 0;
            for (Region *region in [EntryCollection sharedEntryCollection].sortedRegions) {
                
                if ([region.entries containsObject:entry]) {
                    entryIndex = [region.entries indexOfObject:entry];
                    break;
                }
                
                regionIndex ++;
            }
            NSLog(@"ETVC.loadEntry: entry index = %i and regionIndex = %i", entryIndex, regionIndex);
            
            if (entryIndex > 0 || regionIndex > 0) self.canScrollToPrevious = TRUE;
            
            else self.canScrollToPrevious = FALSE;
        }
		
        else self.canScrollToPrevious = ([[EntryCollection sharedEntryCollection].sortedEntries indexOfObject:entry] == 0)?FALSE:TRUE;
		self.canScrollToNext = (entry.entryid == -1) ? FALSE : TRUE;
	}
	
	if ([Props global].appID <= 1) {
		
		for (UIView *subview in [self.navigationController.navigationBar subviews]) {
			if (subview.tag == kTitleLabelTag || subview.tag == kITunesButtonTag) [subview removeFromSuperview];
		}
		
		if (entry.entryid != -1){
            if ([Props global].appID == 0) [self addGetOniTunesBarButton];
            else if ([Props global].appID == 1) [self addDownloadButton];
        }
	}
	
	if (entry.entryid != -1) [self addTitleLabel];
	
	if (self.richTextViewer != nil) self.richTextViewer = nil;
    
	SMRichTextViewer *tmpRichTextViewer = [[SMRichTextViewer alloc] init];
	self.richTextViewer = tmpRichTextViewer;
	richTextViewer.delegate = self;
	
	NSString *webstring = [entry createHTMLFormatedString];
	
	[richTextViewer loadHTMLString:webstring baseURL:nil];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.delegate = self;
    [richTextViewer addGestureRecognizer:swipeRight];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHideBars)];
    singleTap.delegate = self;
    [richTextViewer addGestureRecognizer:singleTap];
    
    if (!([Props global].appID == 1 && !entry.isDemoEntry)) {
        UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showPics:)];
        swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        swipeLeft.delegate = self;
        [richTextViewer addGestureRecognizer:swipeLeft];
    }

	self.pitch = [[SMPitch alloc] initWithEntryID:entry.entryid];
    
	[self createDetailView];

    [self createToolbar];
    
    //Uncomment out to show iAds
    if ([Props global].showAds && entry.entryid != -1) {
       
        NSLog(@"LVC.loadEntry: creating AdBannerView and attaching to detailView");
        if (self.adView != nil)
            [self fixupAdView];
        else
            [self createAdBannerView];
    }
    
	if (!entry.isDemoEntry && (showGoToTopButton || [self.navigationController.viewControllers count] > 2)) {

		UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
		
		temporaryBarButtonItem.target = self;
		temporaryBarButtonItem.action = @selector(showTopView:);
		
		UIImage *goToTopImage = [UIImage imageNamed:@"goToTop.png"];
		temporaryBarButtonItem.image = goToTopImage;
		self.navigationItem.rightBarButtonItem = temporaryBarButtonItem;
    }
	
	else if (self.navigationItem.rightBarButtonItem != nil && [entryHistory count] == 0 && [Props global].appID > 1) {
				
		self.navigationItem.rightBarButtonItem = nil;
		
		UIBarButtonItem *temporaryLeftBarButtonItem = [[UIBarButtonItem alloc] init];
		
		temporaryLeftBarButtonItem.target = self;
		temporaryLeftBarButtonItem.action = @selector(showTopView:);
		
		UIImage *goBackImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"back" ofType:@"png"]];
		temporaryLeftBarButtonItem.image = goBackImage;
		self.navigationItem.leftBarButtonItem = temporaryLeftBarButtonItem;
	}	
	 
	/*[Apsalar eventWithArgs:@"entry view",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
	
    SMLog *log = [[SMLog alloc] initPopularityLog];
	log.entry_id = entry.entryid;
	[[ActivityLogger sharedActivityLogger] sendPopularityLog: [log createPopularityLog]];
}


- (void) showLastView: (id) sender {
	
    NSLog(@"LVC.showLastView:");
	Entry *theEntry = [entryHistory objectAtIndex:0];
	
	[entryHistory removeObjectAtIndex:0];
	
	[self loadEntry:theEntry];
}


//Used to pop to the top view after doing some entry to entry browsing
- (void) showTopView: (id) sender {
    
    entry.lastScrollPosition = 0;
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

- (void) goBack: (id) sender { 
    
    NSLog(@"LVC.goBack: Setting scroll position to 0 for %@", entry.name);
    entry.lastScrollPosition = 0;
    //if ([[[self navigationController] viewControllers] count] == 1) {
        
    //}
    [[self navigationController] popViewControllerAnimated:YES];
}


#pragma mark Create content

- (void) createDetailView {
	
	//NSLog(@"LVC.createDetailView:called");
    @autoreleasepool {
    
    //NSLog(@"DetailScrollView = %@", detailScrollView);
    //NSLog(@"DetailView = %@ with retain count = %i", detailView, [detailView retainCount]);
	//NSLog(@"DetailScroll view contains detailview = %@", [[self.detailScrollView subviews] containsObject:detailView] ? @"YES" : @"NO");
    
		if (self.detailScrollView != nil && [[self.detailScrollView subviews] containsObject:detailView]) [detailView removeFromSuperview];
    
    //if (self.detailScrollView != nil && [[self.detailScrollView subviews] containsObject:detailView]) NSLog(@"I can do this");
		
		
		CGRect viewRect = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight); 	//adjust this height later in detailViewSetContentSize
		
		if ([Props global].appID > 1 || entry.entryid == -1 || entry.isDemoEntry) {
			detailView = [[DetailView alloc] initWithFrame:viewRect andEntry:entry andLocationViewController:self];
		}
		
		else detailView = [[SutroView alloc] initWithFrame:viewRect andEntry:entry andLocationViewController:self];
		
		
		//Set up the scroll view within the front page
        self.detailScrollView.delegate = nil;
        self.detailScrollView = nil;
        self.detailScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
        //self.detailScrollView.contentOffset = CGPointMake(0, 0);
		self.detailScrollView.delegate = self;
		self.detailScrollView.bounces = TRUE;
		self.detailScrollView.alwaysBounceVertical = TRUE;
        //self.detailScrollView.pagingEnabled = YES;
		//self.detailScrollView.autoresizesSubviews = YES;
		//self.detailScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		
		if (canScrollToNext && canScrollToPrevious) self.detailScrollView.contentInset = UIEdgeInsetsMake(0, 0, -kTopScrollGraphicHeight * 2, 0);
		else if (canScrollToNext) self.detailScrollView.contentInset = UIEdgeInsetsMake(0, 0, -kTopScrollGraphicHeight, 0);
		else if (canScrollToPrevious) self.detailScrollView.contentInset = UIEdgeInsetsMake(0, 0, - kTopScrollGraphicHeight, 0); 
		
		self.view.clearsContextBeforeDrawing = NO;
		//detailView.backgroundColor = [Props global].entryViewBGColor;
		
		[self.detailScrollView setContentSize: CGSizeMake([Props global].screenWidth, [Props global].screenHeight)]; //placeholder value, gets set in detailViewSetContentSize 
		
		if (![[self.view subviews] containsObject:self.detailScrollView])[self.view addSubview:self.detailScrollView];
		[self.detailScrollView addSubview:detailView];
	
	}
}


- (void) detailViewSetContentHeight: (float) height {
	
	NSLog(@"LVC.detailViewSetContentHeight: height = %f", height);
    
	if (height < [Props global].screenHeight + kTopScrollGraphicHeight) height = [Props global].screenHeight + kTopScrollGraphicHeight;
	
	float frameY = (canScrollToPrevious) ? -kTopScrollGraphicHeight : 0;
	
	detailView.frame =  CGRectMake(0, frameY, [Props global].screenWidth, height);
	
	[self.detailScrollView setContentSize:CGSizeMake([Props global].screenWidth, height) ];
    
    if (entry.lastScrollPosition > 0 && entry.lastScrollPosition < height) {
        
        self.detailScrollView.contentOffset = CGPointMake(0,entry.lastScrollPosition);
        
        [self updateFrameForOffset:entry.lastScrollPosition];
        
        [self.navigationController setToolbarHidden:TRUE];
        
        if ([Props global].appID != 1) [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
    }

	//detail view will get reloaded from webViewDidFinishLoading, but only if there is some webview loading on the page
	//if (![SMRichTextViewer sharedCopy].loading) [detailView setNeedsDisplay];
}


- (void) addGetOniTunesBarButton {
	
	UIImage *getOniTunesImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"itunes_badge"] ofType:@"png"]];
	
	float buttonHeight = [Props global].titleBarHeight * .72; // 35;
	
	CGRect buttonFrame = CGRectMake([Props global].screenWidth - 5 - (getOniTunesImage.size.width * (buttonHeight/getOniTunesImage.size.height)), 5, getOniTunesImage.size.width * (buttonHeight/getOniTunesImage.size.height), buttonHeight);
	
	UIButton *iTunesButton = [UIButton buttonWithType: 0]; 
	iTunesButton.frame = buttonFrame;
	iTunesButton.alpha = .9;
	iTunesButton.tag = kITunesButtonTag;
	
	[iTunesButton setBackgroundColor: [UIColor clearColor]];
	[iTunesButton setBackgroundImage:getOniTunesImage forState:normal];
	
	
	[iTunesButton addTarget:self action:@selector(showGoToAppStoreAlert:) forControlEvents:UIControlEventTouchUpInside];
	
	[self.navigationController.navigationBar addSubview:iTunesButton];	
}


- (void) addDownloadButton {
    
    int entryid;
    
    if (entry.isDemoEntry) {
        
        LocationViewController *parentController = [[[self navigationController] viewControllers] objectAtIndex:1];
        entryid = parentController.entry.entryid;
    }
    
    else entryid = entry.entryid;
    
    NSDictionary *downloadStatus = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, entryid]];
    
    int download_status_key = [[downloadStatus objectForKey:@"summary"] intValue];
	

	NSDictionary *guidePurchaseStatus = [[MyStoreObserver sharedMyStoreObserver] getGuideStatus:entryid];
	
	BOOL archived = FALSE;
	BOOL freeSample = FALSE;

	if (guidePurchaseStatus != nil) {
		archived = [[guidePurchaseStatus objectForKey:@"archived"] intValue] == 1 ? TRUE : FALSE;
		freeSample = [[guidePurchaseStatus objectForKey:@"is_sample"] intValue] == 1 ? TRUE : FALSE;
	}
	
	NSLog(@"Guide is %@a free sample", freeSample ? @"" : @"not ");
	
    
    NSString *title = nil;
    NSString *selector = nil;
    
    if ((download_status_key > 0 || archived) && !freeSample) {
                                
        if (archived) {
            title = @"unarchive";
            selector = @"unarchive";
        }
        
        else if (download_status_key == kDownloadComplete){
			
            title = @"re-download";
            selector = @"redownload";
        }
        
        else if (download_status_key > 0) {
            title = @"downloading";
            selector = nil;
        }
		
		else {
			
			title = @"Free!";
			selector = @"testBuy";
		}

		UIBarButtonItem *appBarButton = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:NSSelectorFromString(selector)];
		
		self.navigationItem.rightBarButtonItem = appBarButton;
    }
      
    else {
        
        if ([[MyStoreObserver sharedMyStoreObserver] getPriceForGuideId: entryid] != nil)
            title = [Props global].deviceType == kiPad || [[Props global] inLandscapeMode] ? [NSString stringWithFormat:@"Buy: %@",[[MyStoreObserver sharedMyStoreObserver] getPriceForGuideId: entryid]] : [NSString stringWithFormat:@"%@",[[MyStoreObserver sharedMyStoreObserver] getPriceForGuideId: entryid]];
        
        else {
			title = @"Buy";
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDownloadButton) name:kUpdateBuyButton object:nil];
		}
	
		NSArray *purchaseBarItems = freeSample ? [NSArray arrayWithObjects: title, nil] : [NSArray arrayWithObjects:@"Sample",title, nil];
		//NSArray *purchaseBarItems = [NSArray arrayWithObjects:@"Sample",title, nil];
		
		UISegmentedControl *purchaseBar = [[UISegmentedControl alloc] initWithItems:purchaseBarItems];
		purchaseBar.momentary = YES;
		purchaseBar.segmentedControlStyle = UISegmentedControlStyleBar;
		//purchaseBar.tintColor = upgradeButtonColor;
		[purchaseBar addTarget:self action:@selector(purchaseOrSample:) forControlEvents:UIControlEventValueChanged];
		
		if ([purchaseBarItems count] > 1) {
            
            if ([Props global].deviceType == kiPad) {
                [purchaseBar setWidth:75 forSegmentAtIndex:0];
                [purchaseBar setWidth:75 forSegmentAtIndex:1];
            }
            
            else if ([[Props global] inLandscapeMode]){
                [purchaseBar setWidth:58 forSegmentAtIndex:0];
                [purchaseBar setWidth:68 forSegmentAtIndex:1];
            }

            
            else {
                [purchaseBar setWidth:53 forSegmentAtIndex:0];
                [purchaseBar setWidth:48 forSegmentAtIndex:1];
            }
		}
		
		UIBarButtonItem *purchaseButton = [[UIBarButtonItem alloc] initWithCustomView:purchaseBar];
		
		self.navigationItem.rightBarButtonItem = purchaseButton;
    }
}


- (void) createMapIcon {
	
	//create a image of the mapView for faster page loading next time
	NSLog(@"LVC.createMapIcon: creating map icon for %@", entry.name);
	NSString *mapImageName = [[NSString alloc] initWithFormat:@"%i_map", entry.entryid];
	NSString *theFolderPath = [NSString stringWithFormat:@"%@/maps",[Props global].contentFolder];
	NSString *theFilePath = [NSString stringWithFormat:@"%@/%@.png",theFolderPath , mapImageName];
	
	if([[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath] || [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ]){
		CGRect mapFrame = detailView.mapFrame;
		UIGraphicsBeginImageContext(self.view.frame.size);
		[self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
		UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		CGSize contextSize = detailView.mapFrame.size;
		
		UIGraphicsBeginImageContext(contextSize);
		[viewImage drawInRect:CGRectMake(-mapFrame.origin.x, -mapFrame.origin.y, viewImage.size.width, viewImage.size.height)];
		UIImage* mapImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		NSData *theData = UIImagePNGRepresentation(mapImage);
		
		//Write the data to disk
		NSError * theError = nil;
		
		if([theData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) NSLog(@"LVC.viewWillDisappear.createMapIconForMap: Error writing image");
	}
}


- (void) createToolbar {
    
    float spaceBetweenButtons = 12; //The UI does this automatically, but we still need to account for it
    float buttonWidth = ([Props global].screenWidth - spaceBetweenButtons * 4)/3;
    float imageWidth = 30;
    
    UIButton *shareButton = [UIButton buttonWithType:0];
    [shareButton addTarget:self action:@selector(showShareView:) forControlEvents:UIControlEventTouchUpInside];
    [shareButton setImage:[UIImage imageNamed:@"share.png"] forState:UIControlStateNormal];
    //shareButton.backgroundColor = [UIColor redColor];
    shareButton.imageEdgeInsets = UIEdgeInsetsMake(0, buttonWidth/2  - imageWidth/2, 0, buttonWidth/2 - imageWidth/2);
    shareButton.frame = CGRectMake(0, 0, buttonWidth, imageWidth);
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
    
    UIButton *saveButton = [UIButton buttonWithType:0];
    //saveButton.backgroundColor = [UIColor greenColor];
    [saveButton addTarget:self action:@selector(updateFavorites:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *saveImage = [[EntryCollection sharedEntryCollection] entryIsInFavorites: entry] ? [UIImage imageNamed:@"favorited.png"] : [UIImage imageNamed:@"save.png"];
    [saveButton setImage:saveImage forState:UIControlStateNormal];
    saveButton.frame = CGRectMake(0, 0, buttonWidth, imageWidth);
    saveButton.imageEdgeInsets = UIEdgeInsetsMake(0, buttonWidth/2  - imageWidth/2, 0, buttonWidth/2 - imageWidth/2);
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithCustomView:saveButton];
    
    UIButton *commentButton = [UIButton buttonWithType:0];
    //commentButton.backgroundColor = [UIColor blueColor];
    [commentButton addTarget:self action:@selector(showCommentMaker:) forControlEvents:UIControlEventTouchUpInside];
    [commentButton setImage:[UIImage imageNamed:@"comment.png"] forState:UIControlStateNormal];
    commentButton.frame = CGRectMake(0, 0, buttonWidth, imageWidth);
    commentButton.imageEdgeInsets = UIEdgeInsetsMake(0, buttonWidth/2  - imageWidth/2, 0, buttonWidth/2 - imageWidth/2);
    UIBarButtonItem *comment = [[UIBarButtonItem alloc] initWithCustomView:commentButton];
    
    NSArray *toolbarItems = [NSArray arrayWithObjects:comment, save, share, nil];
    
    
    //[self.navigationController.toolbar setItems:toolbarItems];
    [self setToolbarItems:toolbarItems];
    
    self.navigationController.toolbar.tintColor = [Props global].navigationBarTint_entryView;
    self.navigationController.toolbar.translucent = YES;   
    
    [self.navigationController setToolbarHidden:NO animated:NO];
}


#pragma mark -
#pragma mark iAd Private Helpers

//get banner height based on device orientation
- (int)getBannerHeight:(UIDeviceOrientation)orientation {
    
    if (UIInterfaceOrientationIsPortrait(orientation))
        return 50;
    else
        return 32;
}

//get banner height
- (int)getBannerHeight {
    
    return [self getBannerHeight:[UIDevice currentDevice].orientation];
}

/* Idea:
 1. Set the current size of the expected ad based on orientation
 2. Animate the hiding or displaying of the ADBannerView if ad has arrived
 */
- (void)fixupAdView {
    
    if (self.adView != nil) {
        
        if ([[Props global] inLandscapeMode]) {
            self.adView.currentContentSizeIdentifier =ADBannerContentSizeIdentifierLandscape;
        } else {
            self.adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        }
        
        [UIView beginAnimations:@"fixupAdView" context:nil];        
        if (adBannerIsVisible) {
            CGRect adViewFrame = [self.adView frame];
            adViewFrame.origin.x = 0;
            adViewFrame.origin.y = [Props global].screenHeight - adViewFrame.size.height;
            NSLog(@"frame height = %f", detailView.frame.size.height);
            self.detailScrollView.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - adView.frame.size.height);
             NSLog(@"frame height 2 = %f", detailView.frame.size.height);
            
            detailView.frame = CGRectMake(detailView.frame.origin.x, detailView.frame.origin.y, detailView.frame.size.width, detailView.frame.size.height + adView.frame.size.height);
            
            [self.adView setFrame:adViewFrame];
            
        } else {
            CGRect adViewFrame = [self.adView frame];
            adViewFrame.origin.x = 0;
            adViewFrame.origin.y = [Props global].screenHeight; //set offscreen as there is no ad
            [self.adView setFrame:adViewFrame];
            
            self.detailScrollView.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
        }
        [UIView commitAnimations];
    }
}

/* Steps:
 1. Alloc and init ADBannerView object with CGRectZero
 2. Set the possible sizes of expected ads
 3. Set the current size of expected ads (based on device orientation)
 4. Set the current frame of the ad banner offscreen initially, since we
 don't know if ad is available, and thus don't want to display the
 view until we know an ad is ready
 5. Set the location view controller to be the ADBannerView's delegate
 6. Add ADBannerView as subView to DetailView
 */

- (void)createAdBannerView
{
    self.adView = nil;
    
    ADBannerView *anAdView = [[ADBannerView alloc] initWithFrame:CGRectZero];
    
    self.adView = anAdView;
    self.adBannerIsVisible = FALSE;
    
    //set the possible sizes of expected ads
    self.adView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil];
    
    //set the current size of expected ads
    if (UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        self.adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
    } else {
        self.adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    }
    
    //set offscreen as there is no ad
    //[self.adView setFrame:CGRectOffset([adView frame], 0, -[self getBannerHeight])];
    
    self.adView.frame = CGRectMake(0, [Props global].screenHeight, [Props global].screenWidth, [self getBannerHeight]);
    
    self.adView.delegate = self;
    
    //is this the best place to put the ad banner?
    
    [self.view addSubview:self.adView];
    NSLog(@"SS:LVC<-createAdBannerView: created ad banner view and added as subview to detailView");
}




#pragma mark Action methods for button presses

- (void) showOrHideBars {
    
    
    NSLog(@"LVC.showOrHideBar:content offset = %f", detailScrollView.contentOffset.y);
    
    changingTopBar = TRUE;
    
    if (detailScrollView.contentOffset.y > [Props global].titleBarHeight) {
        
        if ([Props global].deviceType != kiPad) {
            [self.navigationController setToolbarHidden:!self.navigationController.navigationBarHidden animated:YES];
            [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];
        }
        
        else [self.navigationController setToolbarHidden:!self.navigationController.toolbarHidden animated:YES];
    }
    
    else {
        [self.navigationController setToolbarHidden:!self.navigationController.toolbarHidden animated:YES];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    
    [self performSelector:@selector(setChangingTopBarToFalse) withObject:nil afterDelay:0.1];
}


- (void) showCommentMaker: (id) sender {
	
	NSLog(@"LVC.showCommentMaker");
	
	if([[Reachability sharedReachability] internetConnectionStatus] != NotReachable) {
		
		CommentPageView *commentPage = [[CommentPageView alloc] initWithEntry:self.entry];
		
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:commentPage];
		
		
		[self presentModalViewController:navigationController animated:YES];
		
		
		SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVComment ];
		log.entry_id = entry.entryid;
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}
	
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Looks like you don't have an internet connection. You'll need one to post comments." delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:nil];   
		
		[alert show];  
	}
	
}

- (void) goToImageEntry:(id) sender {
    
    UIButton *button = (UIButton*) sender;
    
    //Need to find demo entry from database with this image
    
    int entryid = kValueNotSet;
    
    @synchronized([Props global].dbSync) {
        
        FMDatabase *db = [EntryCollection sharedContentDatabase];
        
        NSString *query = [NSString stringWithFormat:@"SELECT rowid from demo_entries WHERE icon_photo_id = %i", button.tag];
        FMResultSet *rs = [db executeQuery:query];
        
        while ([rs next]) {
            entryid = [rs intForColumn:@"rowid"]; 
        }
    }
    
    if (entryid != kValueNotSet) [self goToEntryWithId:[NSNumber numberWithInt:entryid]];
    
    NSLog(@"Got touched for button with tag %i", button.tag);
}


- (void) showComments: (id) sender {
	
	CommentsViewController *commentController = [[CommentsViewController alloc] initWithEntry: entry ];
	[self.navigationController pushViewController:commentController animated:YES];
	
	/*[Apsalar eventWithArgs:@"view entry comments",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
	
	SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVGoToComments];
	log.entry_id = entry.entryid;
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	
}


- (void) showDeals {
	
	DealsViewController *dealsController = [[DealsViewController alloc] initWithEntry: entry];
	[self.navigationController pushViewController:dealsController animated:YES];
	
	/*[Apsalar eventWithArgs:@"view entry deals",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
	
	SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVGoToComments];
     log.entry_id = entry.entryid;
     [[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	
}


- (void) showCommentsViewOrUpdateFavorites:(id)sender
{
	UISegmentedControl* segCtl = sender;
	// the segmented control was clicked, handle it here 
	
	switch (segCtl.selectedSegmentIndex)
	{
		case 0:	{ //show comments view
			
			[self showCommentMaker:nil];
			
			/*[Apsalar eventWithArgs:@"make entry comment",
			 @"entry id", [NSNumber numberWithInt:entry.entryid],
			 @"entry name", entry.name,
			 nil];*/
			
			break;
		}
			
		case 1: { //show share view
			
			[self showShareView];
			
			/*[Apsalar eventWithArgs:@"share entry",
			 @"entry id", [NSNumber numberWithInt:entry.entryid],
			 @"entry name", entry.name,
			 nil];*/
			
			break;
		}
			
		case 2: { //update favorites
			
			[self updateFavorites:nil];
			break;
		}
	}
}


- (void)showPics:(id)sender {
	
	[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kPlayButtonPressed];
	
	@autoreleasepool {
			
			SlideController *slideController = [[SlideController alloc] initWithEntry: entry ];
			[self.navigationController pushViewController:slideController animated:YES];

	}
	
	/*[Apsalar eventWithArgs:@"view entry slideshow",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
}


- (void) showWebPageViewWithURL:(NSURL*) theURL {
	
	if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Looks like you don't have an internet connection. You'll need one to view external websites." delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:nil];   
		
		[alert show];  
		
		return;
	}
	
	
	@autoreleasepool {
	
	//[[NSURLCache sharedURLCache] setMemoryCapacity:(1024*1024)]; //should be 1 MB
	//[[NSURLCache sharedURLCache] setDiskCapacity:(1024*1024)];
	
		[[NSURLCache sharedURLCache] setMemoryCapacity:0]; //should be 1 MB
		[[NSURLCache sharedURLCache] setDiskCapacity:0];
		
		/*if ([self isYouTubeURL:[theURL absoluteString]] && [Props global].deviceType != kiPad) {
				
			NSLog(@"LOCATIONVIEWCONTROLLER - Launching youtube video with url = %@", [theURL absoluteString]);
			//[self embedYouTube:[url absoluteString] frame:CGRectMake(20, 20, 100, 100)];
			videoPlayer= [[YouTubePlayer alloc] initWithDelegate:self];
			[videoPlayer playbackVideo:[self getYouTubeVideoIdWithURLString:[theURL absoluteString]]  InView:self.view];
			
			///Missing release?????
			
		}
		
		else */if ([self isiTunesURL:[theURL absoluteString]]){
			iTunesURL = theURL;
			[self showGoToiTunesAlert];
		}
		
		else {
			
			WebViewController *webPageView = [[WebViewController alloc] initWithEntry:self.entry andURLToLoad:theURL];
			[self.navigationController pushViewController:webPageView animated:YES];
			
			SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVGoToWebPage ];
			log.entry_id = entry.entryid;
			[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
		}
	
	}
}


- (void) loadURL:(NSURL*) theURL {
	
	WebViewController *webPageView = [[WebViewController alloc] initWithEntry:self.entry andURLToLoad:theURL];
	[self.navigationController pushViewController:webPageView animated:YES];
	
	/*[Apsalar eventWithArgs:@"view web page",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
	
	SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVGoToWebPage ];
	log.entry_id = entry.entryid;
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
}


- (void) loadVideoWithoutYouTubePlayer {
	
	WebViewController *webPageView = [[WebViewController alloc] initWithEntry:self.entry andURLToLoad:[NSURL URLWithString: [self consistifyURLStringForUse:entry.videoLink]]];
	[self.navigationController pushViewController:webPageView animated:YES];
	
	SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVGoToWebPage ];
	log.entry_id = entry.entryid;
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
}


- (void) showReservationPage {
    
    [self showWebPageViewWithURL: [NSURL URLWithString: [self consistifyURLStringForUse:entry.reservationLink]]];
	
	/*[Apsalar eventWithArgs:@"view reservation page",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
}


- (void) showVideo {
    
    [self showWebPageViewWithURL: [NSURL URLWithString: [self consistifyURLStringForUse:entry.videoLink]]];
	
	/*[Apsalar eventWithArgs:@"view video tile link",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
}


- (void) showFacebookPage {
    
    [self showWebPageViewWithURL: [NSURL URLWithString: [self consistifyURLStringForUse:entry.facebookLink]]];
	
	/*[Apsalar eventWithArgs:@"view facebook page",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
}


- (void) showTwitterPage {
 
	[self showWebPageViewWithURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://twitter.com/%@", entry.twitterUsername]]];
    
	/*[Apsalar eventWithArgs:@"view twitter page",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
}


- (void) showEntryWebView: (id) sender {
	
	[self showWebPageViewWithURL: [NSURL URLWithString: entry.mobilewebsite]];
	
	/*[Apsalar eventWithArgs:@"view entry web view",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
	
}


-(void) showEntireDescription: (id) sender {
	
	SutroView *sutroView = (SutroView*) detailView;
	sutroView.showEntireDescription = TRUE;
	
	[detailView setNeedsDisplay];	
}


-(void) showMap: (id) sender {
	
	EntryMapView *mapView = [[EntryMapView alloc] initWithEntry:self.entry];
	[self.navigationController pushViewController:mapView animated:YES];
	
	/*[Apsalar eventWithArgs:@"view entry map",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
	
	//SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVGoToMapView];
	//log.entry_id = entry.entryid;
	//[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
}


- (void)callThem {
	
	SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVPhoneCall ];
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	
	/*[Apsalar eventWithArgs:@"phone call",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
	
	NSString * phoneNumberString = [NSString stringWithFormat:@"tel://%@", entry.phoneNumber];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumberString]];
}


- (NSString*) processURLStringForDisplay:(NSString*) retVal {
	
	if(retVal != nil) {
		if([retVal hasPrefix:@"http://"]){
			if([retVal hasPrefix:@"http://www."]) retVal = [retVal substringFromIndex:11];
			else if([retVal hasPrefix:@"http://en.m."]) retVal = [retVal substringFromIndex:12];
			else retVal = [retVal substringFromIndex:7];
		}
		
		int maxLength = ([Props global].screenWidth > 320) ? 70 : 33;
		if([retVal length] > maxLength) retVal = [NSString stringWithFormat:@"%@...",[retVal substringToIndex: maxLength - 1]];
		
		else if([retVal hasSuffix:@"/"]) retVal = [retVal substringToIndex:([retVal length] - 1)];
	}
	
	return retVal;
}


- (NSString*) consistifyURLStringForUse: (NSString*) inconsistentURL {
    
    inconsistentURL = [inconsistentURL stringByReplacingOccurrencesOfString:@"www." withString:@""];
    inconsistentURL = [inconsistentURL stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    inconsistentURL = [inconsistentURL stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    
    NSString *cleanURLString = [NSString stringWithFormat:@"http://www.%@", inconsistentURL];
    
    return cleanURLString;
}


- (void) updateFavorites: (id) sender {
    
    BOOL showPopupTutorial = FALSE;
	
	if([[EntryCollection sharedEntryCollection] entryIsInFavorites: entry]) {
		
		[[EntryCollection sharedEntryCollection] removeFromFavorites: entry];
				
		SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVRemoveFromFavorites];
		log.entry_id = entry.entryid;
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}
	
	else {
		
		[[EntryCollection sharedEntryCollection] addToFavorites: entry];
		
		SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVMakeFavorite];
		log.entry_id = entry.entryid;
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
		
		/*[Apsalar eventWithArgs:@"favorite added",
		 @"entry id", [NSNumber numberWithInt:entry.entryid],
		 @"entry name", entry.name,
		 nil];*/
        
        //NSString *key = [NSString stringWithFormat:@"First_favorite_saved_%i", [Props global].appID];
        
        if ([Props global].freemiumType != kFreemiumType_V1 && [[NSUserDefaults standardUserDefaults] boolForKey:kFirstFavoriteSaved] != TRUE) {
            showPopupTutorial = TRUE;
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kFirstFavoriteSaved];
        }
	}
    
    [self createToolbar];
    
    NSLog(@"First version = %i", [Props global].firstVersion);
    
    if ([Props global].freemiumType == kFreemiumType_V1 && [Props global].firstVersion >= 31141) {
        UIAlertView *upgradePopup = [[UIAlertView alloc] initWithTitle:nil message:@"Saving favorites requires upgrading to the Pro version" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: @"Upgrade", nil];
        upgradePopup.tag = kUpgradeAlertTag;
        upgradePopup.delegate = self;
        [upgradePopup show];
        
        [[EntryCollection sharedEntryCollection] removeFromFavorites:entry];
        
        [self performSelector:@selector(createToolbar) withObject:nil afterDelay:0.4];
    }
    
    else if (showPopupTutorial) {
        UIAlertView *favoritesTutorial = [[UIAlertView alloc] initWithTitle:@"Favorite saved" message:@"You can see your favorites by pressing the filter button on the top left of the browse, photos, maps, and comments pages" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: @"Show me", nil];
        favoritesTutorial.tag = kFavoritesAlertTag;
        favoritesTutorial.delegate = self;
        [favoritesTutorial show];
    }
}


-(UIImage*)resizedImage1:(UIImage*)inImage  inRect:(CGRect)thumbRect {
	// Creates a bitmap-based graphics context and makes it the current context.
	UIGraphicsBeginImageContext(thumbRect.size);
	[inImage drawInRect:thumbRect];
	
	return UIGraphicsGetImageFromCurrentImageContext();
}


- (UIImage*) captureTitlebar {
	
	NSLog(@"LVC.captureTitlebar");
	
	UIImage *screenImage = [self captureScreen];
	
	UIImage *titleBarImage = nil;
	CGSize contextSize =  CGSizeMake([Props global].screenWidth, [Props global].titleBarHeight);
	
	UIDeviceOrientation orientation = [Props global].lastOrientation; // [[UIDevice currentDevice] orientation];
	
	if (orientation == UIDeviceOrientationLandscapeRight) {
		
		NSLog(@"In landscape right");
		UIImage *rotatedImage = [self rotateImage:screenImage rotationAngle:kQuarterTurnCW];
		
		UIGraphicsBeginImageContext(contextSize);
		[rotatedImage drawInRect:CGRectMake(0, 0, rotatedImage.size.width, rotatedImage.size.height)];
		titleBarImage = UIGraphicsGetImageFromCurrentImageContext();
		titleBarImage_landscape = titleBarImage;
		UIGraphicsEndImageContext();
	}
	
	else if (orientation == UIDeviceOrientationLandscapeLeft) {
		
		NSLog(@"In landscape left");
		UIImage *rotatedImage = [self rotateImage:screenImage rotationAngle:kQuarterTurnCCW];
		
		UIGraphicsBeginImageContext(contextSize);
		[rotatedImage drawInRect:CGRectMake(0, 0, rotatedImage.size.width, rotatedImage.size.height)];
		titleBarImage = UIGraphicsGetImageFromCurrentImageContext();
		titleBarImage_landscape = titleBarImage;
		UIGraphicsEndImageContext();
	}
	
	else if (orientation == UIDeviceOrientationPortrait || (orientation == UIDeviceOrientationFaceUp && [Props global].lastOrientation == UIDeviceOrientationPortrait)) {
		
		//NSLog(@"In portrait right side up");
		
		UIGraphicsBeginImageContext(contextSize);
		[screenImage drawInRect:CGRectMake(0, 0, screenImage.size.width, screenImage.size.height)];
		titleBarImage = UIGraphicsGetImageFromCurrentImageContext();
		titleBarImage_portrait = titleBarImage;
		UIGraphicsEndImageContext();
	}
	
	else if (orientation == UIDeviceOrientationPortraitUpsideDown || (orientation == UIDeviceOrientationFaceUp && [Props global].lastOrientation == UIDeviceOrientationPortraitUpsideDown)) {
		
		NSLog(@"In portrait upside down");
				
		UIImage *rotatedImage = [self rotateImage:screenImage rotationAngle:kPI];
		
		UIGraphicsBeginImageContext(contextSize);
		[rotatedImage drawInRect:CGRectMake(0, 0, rotatedImage.size.width, rotatedImage.size.height)];
		titleBarImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		titleBarImage_portrait = titleBarImage;
	}
	
    return titleBarImage;
}


- (UIImage*) captureScreen {
	
	// Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
	
	UIImage* screenCapture = nil;
	
	CGSize imageSize = [UIScreen mainScreen].bounds.size;
	
	if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
	
    CGContextRef context = UIGraphicsGetCurrentContext();
	
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
			
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
			
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
	
    // Retrieve the screenshot image
    screenCapture = UIGraphicsGetImageFromCurrentImageContext();
	
    UIGraphicsEndImageContext();
	
	//UIImageWriteToSavedPhotosAlbum(screenCapture,nil, nil, nil);
	
	return screenCapture;
}


- (UIImage*) rotateImage:(UIImage*) src rotationAngle:(float) radians {
	
	UIImage *rotatedImage = nil;
	
	BOOL quarterTurn = fabs(radians - kQuarterTurnCCW) < .1 || fabs(radians - kQuarterTurnCW) < .1;
	
	CGSize contextSize = quarterTurn ? CGSizeMake(src.size.height, src.size.height) : src.size;
    
	UIGraphicsBeginImageContext(contextSize);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextRotateCTM (context, radians);
	
	NSLog(@"Radians = %f, quarter turn = %f", radians, kQuarterTurnCCW);
	
	if (fabs(radians -kPI) < .1) {
		NSLog(@"Translating for flip");
		CGContextTranslateCTM(context, -[Props global].screenWidth, -[Props global].screenHeight);
	}
	
	else if (fabs (radians - kQuarterTurnCCW) < .1){ //radians == -kPI/2 should work, but it isn't
		CGContextTranslateCTM(context, -[Props global].screenHeight, 0);
		NSLog(@"Translating for CCW");
	}
	
	else if (fabs (radians - kQuarterTurnCW) < .1) { //radians == -kPI/2 should work, but it isn't
		CGContextTranslateCTM(context, 0, -[Props global].screenWidth);
		NSLog(@"Translating CW");
	}
		
    [src drawAtPoint:CGPointMake(0, 0)];
	
	rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
    return rotatedImage;
}


/*
- (UIImage*)rotateImage:(UIImage *)image rotationAngle:(float) angle {
	
	CGImageRef imgRef = image.CGImage;
	
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGRect bounds = CGRectMake(0, 0, width, height);
	
	CGAffineTransform transform = CGAffineTransformRotate(transform, angle);
		
	UIGraphicsBeginImageContext(bounds.size);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGContextConcatCTM(context, transform);
	
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return imageCopy;
}
*/

- (void)embedYouTube:(NSString *)urlString frame:(CGRect)frame {
	NSString *embedHTML = @"\
	<html><head>\
	<style type=\"text/css\">\
	body {\
	background-color: transparent;\
	color: white;\
	}\
	</style>\
	</head><body style=\"margin:0\">\
	<embed id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" \
	width=\"%0.0f\" height=\"%0.0f\"></embed>\
	</body></html>";
	NSString *html = [NSString stringWithFormat:embedHTML, urlString,
						frame.size.width, frame.size.height];
	UIWebView *videoView = [[UIWebView alloc] initWithFrame:frame];
	[videoView loadHTMLString:html baseURL:nil];
	[self.view addSubview:videoView];
}


//Checks if a URL is a youTube URL
- (BOOL) isYouTubeURL:(NSString*) urlString {
	
	if ([urlString length] < 32) return NO;
	
	//http://www.youtube.com...
	else if([[urlString substringWithRange:NSMakeRange(11,7)] isEqualToString:@"youtube"]) return YES;	
	
	//https://www.youtube.com...
	else if([[urlString substringWithRange:NSMakeRange(12,7)] isEqualToString:@"youtube"]) return YES;	
	
	else return NO;
}

//Checks if a URL is an offline content URL
- (BOOL) isOfflineContentURL:(NSString*) urlString {
	
	//http://www.sutromedia.com/published/offline/
	if ([urlString length] > 44)NSLog(@"Offline candiate = %@, substring = %@", urlString, [urlString substringWithRange:NSMakeRange(7,32)]);
	
	if ([urlString length] < 44) return NO;
	
	else if([[urlString substringWithRange:NSMakeRange(7,32)] isEqualToString:@"sutromedia.com/published/offline"]) return YES;	
	
	else if([[urlString substringWithRange:NSMakeRange(11,32)] isEqualToString:@"sutromedia.com/published/offline"]) return YES;	
	
	else return NO;
}


- (BOOL) isiTunesURL: (NSString*) urlString {
	
	//http://itunes.apple.com/us/podcast/chicago-blues-enhanced-version/id358733197
	
	if ([urlString length] < 24) return NO;
	
	else if([[urlString substringWithRange:NSMakeRange(7,16)] isEqualToString:@"itunes.apple.com"]) return YES;	
	
	else return NO;
}


- (NSString*) getYouTubeVideoIdWithURLString:(NSString*)urlString {
	
	NSArray *youTubeArray = [urlString componentsSeparatedByString:@"watch?v="];
	
	if ([youTubeArray count] == 2) {
		
		NSArray *innerYouTubeArray = [[youTubeArray objectAtIndex:1] componentsSeparatedByString:@"&feature="];
		if ([innerYouTubeArray count] == 2) return [innerYouTubeArray objectAtIndex:0];

		else return [youTubeArray objectAtIndex:1];
	}
	
	else return nil;
}


- (void) showGoToAppStoreAlert: (id) sender {
	
	NSLog(@"Got message to show go to app store alert");
	UIAlertView *appStoreAlert = [[UIAlertView alloc] initWithTitle: nil message:@"This will leave the guide and open the App Store" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Go for it!", nil];
    appStoreAlert.tag = kAppStoreAlertTag;
	[appStoreAlert show];
}


- (void) showGoToiTunesAlert {
	
	NSLog(@"Got message to show go to iTunes alert");
	UIAlertView *iTunesAlert = [[UIAlertView alloc] initWithTitle: nil message:@"This will leave the guide and open iTunes" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Go for it!", nil];
    iTunesAlert.tag = kiTunesAlertTag;
	[iTunesAlert show];
}


- (void) showCallThemAlert: (id) sender {
	
	if([Props global].deviceType == kiPhone) {
		
		UIAlertView *callAlert = [[UIAlertView alloc] initWithTitle: nil message:[NSString stringWithFormat:@"Call %@?", entry.formattedPhoneNumber]
											  delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Okay", nil];
        callAlert.tag = kCallAlertTag;
		[callAlert show];
	}
}


- (void)goToExternalWebPageWithURL:(NSURL*) webPageURL  {
	
	NSLog(@"About to open external url = %@", webPageURL);
	
	if (![[UIApplication sharedApplication] openURL:webPageURL])
	{
		SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVErrorGoingToAppStore];
		log.entry_id = entry.entryid;
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}
}


- (void) addTitleLabel {
	
	UILabel *label = [[UILabel alloc] init];
	[label setBackgroundColor:[UIColor clearColor]];
	label.adjustsFontSizeToFitWidth = TRUE;
	
	label.shadowOffset = CGSizeMake(1, 1);
	
	
	if ([Props global].appID > 1) {
		label.shadowColor = [UIColor blackColor];
		[label setFont:[UIFont boldSystemFontOfSize:16.0]];
		[label setTextColor:[UIColor colorWithWhite:0.8 alpha:0.9]];
		label.textAlignment = UITextAlignmentCenter;
		label.frame = CGRectMake(0, 0, 260, 30);
		label.minimumFontSize = 13;
		
		if ([entry.name length] < 20) [label setText: [NSString stringWithFormat:@"%@                ", entry.name]];
		
		else if ([entry.name length] < 26) [label setText: [NSString stringWithFormat:@"%@           ", entry.name]];
		
		else [label setText:entry.name];
		
		self.navigationItem.titleView = label;
	}
	
	else {
		
        UIView *oldView = [self.navigationController.navigationBar viewWithTag:kTitleLabelTag];
        [oldView removeFromSuperview];
        
		label.shadowColor = [UIColor darkGrayColor];
		[label setFont:[UIFont boldSystemFontOfSize:15.0]];
		label.minimumFontSize = 12;
		label.textAlignment = UITextAlignmentCenter;
		label.tag = kTitleLabelTag;
		[label setTextColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
        
        if ([Props global].deviceType == kiPad) label.frame = CGRectMake(62, 0, [Props global].screenWidth - 214, [Props global].titleBarHeight);
            
        else if ([[Props global] inLandscapeMode]) label.frame = CGRectMake(62, 0, [Props global].screenWidth - 188, [Props global].titleBarHeight);
        
        else label.frame = CGRectMake(62, 0, [Props global].screenWidth - 175, [Props global].titleBarHeight);
        
		label.numberOfLines = 2;
		label.text = entry.name;
		
		[self.navigationController.navigationBar addSubview:label];
	}
	
}


- (void) goToEntryWithId:(NSNumber*) theEntryIdObject {
    
    int theEntryId = [theEntryIdObject intValue];
    Entry *newEntry = [Props global].appID > 1 ? [EntryCollection entryById:theEntryId] : [EntryCollection demoEntryById:theEntryId];
    
    if (newEntry != nil){
        
        LocationViewController *entryController = [[LocationViewController alloc] initWithController: nil];
        
        // set the entry for the controller
        entryController.entry = newEntry;
        
        // push the entry view controller onto the navigation stack to display it
        [[self navigationController] pushViewController:entryController animated:YES];
        //[entryController.view setNeedsDisplay];
    }
}


#pragma mark
#pragma mark Button action methods for Sutro World purchases

- (void) purchaseOrSample:(id) sender {
    
    UISegmentedControl *segControl = (UISegmentedControl*) sender;
    int selectedSegment = segControl.selectedSegmentIndex;
	NSString *segmentTitle = [segControl titleForSegmentAtIndex:selectedSegment];
    
    if ([segmentTitle isEqualToString:@"Sample"]) [self getSample];
	
	else if ([segmentTitle isEqualToString:@"Buy"]) [self noPrice];
    
    else [self buyGuide];
}

- (void) testBuy {
    
    SMLog *log = [[SMLog alloc] initWithPageID: kInAppPurchase actionID: kTestPurchaseStart];
    log.entry_id = entry.entryid;
	[[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
    
    [[MyStoreObserver sharedMyStoreObserver] provideContent:[self getRootEntryId]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kGoHome object:nil];
}


- (void) getSample {
	
	[[MyStoreObserver sharedMyStoreObserver] provideSampleContent:[self getRootEntryId]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kGoHome object:nil];
}


- (void) buyGuide {
    
    SMLog *log = [[SMLog alloc] initWithPageID: kInAppPurchase actionID: kPurchaseStart];
    log.entry_id = entry.entryid;
	[[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
    
    [[MyStoreObserver sharedMyStoreObserver] purchaseGuide:[self getRootEntryId]];
    
    [detailView createLoadingAnimation];
}


- (void) redownload {
    
    int entryid = [self getRootEntryId];
    
    NSString *redownloadNotification = [NSString stringWithFormat:@"%@_%i", kRedownloadGuide, entryid];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:redownloadNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kGoHome object:nil];
}


- (void) unarchive {
    
    int entryid = [self getRootEntryId];
    
    [[MyStoreObserver sharedMyStoreObserver] unarchiveGuide: entryid];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kGoHome object:nil];
}


- (int) getRootEntryId {
	
	int entryid;
	
    if (entry.isDemoEntry) {
        
        LocationViewController *parentController = [[[self navigationController] viewControllers] objectAtIndex:([[[self navigationController] viewControllers] count] - 2)];
        
        entryid = parentController.entry.entryid;
    }
    
    else entryid = entry.entryid;
	
	return entryid;
}



- (void) noPrice {
    
    if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
		
        SMLog *log = [[SMLog alloc] initWithPageID: kInAppPurchase actionID: kNoPriceNoInternet];
        log.entry_id = entry.entryid;
        [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
        
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Looks like you don't have an internet connection. You'll need one to make purchases." delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
		
		[alert show];
		
		return;
	}
    
    else {
        
        SMLog *log = [[SMLog alloc] initWithPageID: kInAppPurchase actionID: kNoPrice];
        log.entry_id = entry.entryid;
        [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDownloadButton) name:kUpdateBuyButton object:nil];
        
        
        if ([Props global].deviceType == kSimulator) {
            [self testBuy];
        }
        
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"App Store Error" message:@"Give it another shot later. Sorry!" delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            
            [alert show];
        }
    }
}


#pragma mark
#pragma mark Button Action Methods for hotel booking links

- (void) openOtelsPage {
    
    SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kHotelAdClicked];
    log.entry_id = entry.entryid;
    log.note = @"otels click";
    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
	
	/*[Apsalar eventWithArgs:@"otels add click",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
    
    NSLog(@"Dict = %@",entry.hotelBookingLinks);
    
    NSLog(@"Otel = %@", [entry.hotelBookingLinks objectForKey:@"otel"]);
    
    NSURL *url = [NSURL URLWithString:[entry.hotelBookingLinks objectForKey:@"otel"]];  
    
    //NSURL *url = [NSURL URLWithString: @"http://www.kqzyfj.com/click-5266468-10619013?sid=SUTROSUBID&url=http%3A%2F%2Fwww.otel.com%2Frdcj.php%3Ffn%3Domni_hotel_parker_house_boston&cjsku=US90H0"];
    
    NSLog(@"URL = %@", [url absoluteString]);
    
    [self showWebPageViewWithURL:url];
}


- (void) openHotelscomPage {
    
    SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kHotelAdClicked];
    log.entry_id = entry.entryid;
    log.note = @"hotelscom click";
    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
	
	/*[Apsalar eventWithArgs:@"hotels.com ad click",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
    
    NSURL *url = [NSURL URLWithString:[entry.hotelBookingLinks objectForKey:@"hotelscom"]];
    [self showWebPageViewWithURL:url];
}


- (void) openExpediaPage {
    SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kHotelAdClicked];
    log.entry_id = entry.entryid;
    log.note = @"expedia click";
    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
	
	/*[Apsalar eventWithArgs:@"expedia ad click",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
    
    NSURL *url = [NSURL URLWithString:[entry.hotelBookingLinks objectForKey:@"expedia"]];
    [self showWebPageViewWithURL:url];
}


#pragma mark
#pragma mark Background Image Downloading
- (void) downloadIcon {      
    // Setup the operation queue.
    // Cancel any previous operations that might be running
    [operationQueue cancelAllOperations];  
    self.operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setMaxConcurrentOperationCount:1];
    [self.operationQueue addObserver:self forKeyPath:kDownloadObserverKeyPath options:0 context:NULL];
    
    // Create the image download operations, and add them to the queue
    NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i%@.jpg", [Props global].contentFolder, entry.icon, [Props global].deviceType == kiPad ? @"_768" : @""];
    
    NSString *tempString = [[NSString alloc] initWithFormat: @"http://%@/published/%@-sized-photos/%i.jpg", [Props global].serverContentSource, [Props global].deviceType == kiPad ? @"ipad":@"480", entry.icon];
    
    NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *dataURL = [[NSURL alloc] initWithString: urlString];

    DownloadOperation *operation = [[DownloadOperation alloc] initWithURL:dataURL downloadPath:theFilePath];
    [operationQueue addOperation:operation];
    
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == self.operationQueue && [keyPath isEqualToString:kDownloadObserverKeyPath]) {
        
        if ([self.operationQueue.operations count] == 0) {
            // Do something here when your queue has completed
            NSLog(@"LVC.observeValueForKeyPath: queue has completed");
            
            NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i%@.jpg", [Props global].contentFolder, entry.icon, [Props global].deviceType == kiPad ? @"_768" : @""];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath: theFilePath]) {
                //Update database
                NSString *query = [[NSString alloc] initWithFormat:@"UPDATE photos SET downloaded_%ipx_photo = 1 WHERE rowid = %i", [Props global].deviceType == kiPad ? 768:320, self.entry.icon];
                
                FMDatabase *db = [EntryCollection sharedContentDatabase];
                
                @synchronized([Props global].dbSync) {
                    [db executeUpdate:@"BEGIN TRANSACTION"];
                    [db executeUpdate:query];
                    [db executeUpdate:@"END TRANSACTION"];
                }
                
                //Update image in detailView 
                [detailView performSelectorOnMainThread:@selector(updateIcon) withObject:nil waitUntilDone:NO];
            }
            
            else NSLog(@"*** WARNING - LVC.observeValueForKeyPath: high quality icon image still missing for %@ after attempting download", entry.name);
        }
    }
    
    else {
     
        @try {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
        @catch (NSException *exception) {
            NSLog(@"*********** ERROR: LVC.observeValueForKeyPath:ofObject:change:content");
        }
        @finally {
            NSLog(@"And finally");
        }
    }
}


#pragma mark
#pragma mark Delegate Methods

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
	NSURL *url = [request URL];
	
	//Web action happens inside rich text viewer
	if (aWebView == richTextViewer /*[SMRichTextViewer sharedCopy]*/) {
		
		NSString *scheme = [url scheme];
		
		//Happens when blank page is pre-loaded to clear page
		if ([scheme isEqualToString:@"about"])return YES;
		
		//if tag is clicked
		else if([scheme caseInsensitiveCompare:@"SMTag"] == NSOrderedSame){
			
			NSLog(@"URL path  = %@ ", [url path]);
			
			NSString *filterID = [[url resourceSpecifier] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			NSString *filter = nil;
            
            @synchronized([Props global].dbSync) {
			
                FMDatabase *db = [EntryCollection sharedContentDatabase];
                
                NSString *query = [NSString stringWithFormat:@"SELECT name FROM groups WHERE rowid = %@", filterID];
                
                FMResultSet * rs = [db executeQuery:query];
                
                if ([db hadError]) NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                
                while ([rs next]){ filter = [rs stringForColumn:@"name"]; }
                
                [rs close];
			}
			
			if(filter != nil) {
				
				[[FilterPicker sharedFilterPicker] setPickerToFilter:filter];
				
				self.tabBarController.selectedIndex = 0;
				[[self navigationController] popToRootViewControllerAnimated:YES];
				
				SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVTagClicked];
				log.entry_id = entry.entryid;
				[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
				
				return NO;
			}
		}
		
		//if mail link is clicked
		else if([scheme isEqualToString:@"mailto"]){
			
            NSLog(@"Absolute string = %@", [url absoluteString]);
            NSString *urlString = [url absoluteString];
            if ([urlString length] > 8) {
            
                NSString * recipient = [urlString substringWithRange:NSMakeRange(7,[urlString length] - 7)];	
                
                NSLog(@"Recipient = %@", recipient);
                
                Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
                if (mailClass != nil)
                {
                    // We must always check whether the current device is configured for sending emails
                    if ([mailClass canSendMail]) [self displayComposerSheetForRecipient:recipient];
                    
                    else [self launchMailAppOnDeviceForRecipient:recipient];
                }
                
                else [self launchMailAppOnDeviceForRecipient:recipient];
            }
			
			
			return NO;
		}
		
		//if a entry link is clicked
		else if ([scheme caseInsensitiveCompare:@"SMEntryLink"] == NSOrderedSame) {
			
			NSString *idString = [[[url resourceSpecifier] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"//" withString:@""];
			
			[self goToEntryWithId:[NSNumber numberWithInt:[idString intValue]]];
            
			return NO;
		}
		
		//if a regular webpage is clicked
		else if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
			
			if ([self isOfflineContentURL:[url absoluteString]] && ![Props global].inTestAppMode && [Props global].appID > 1) {
				
				NSArray *urlArray = [[url absoluteString] componentsSeparatedByString:@"?o="];
				
				NSArray *filenameArray = [[urlArray lastObject] componentsSeparatedByString:@"."];
				
				if ([filenameArray count] >= 2) {
					
					NSString *filename = [filenameArray objectAtIndex:0];
					NSString *fileType = [filenameArray objectAtIndex:1];
					
					NSString *offlinePath = [[NSBundle mainBundle] pathForResource:filename ofType:fileType];
					
					NSLog(@"Offline file path = %@", offlinePath);
					
					if ([[NSFileManager defaultManager] fileExistsAtPath:offlinePath]){
						
						url = [NSURL fileURLWithPath:offlinePath];
					}
                    
                    else {
                        offlinePath = [NSString stringWithFormat:@"%@/OfflineLinkFiles/%@.%@", [Props global].contentFolder, filename, fileType];
                        NSLog(@"Offline path = %@", offlinePath);
                        if ([[NSFileManager defaultManager] fileExistsAtPath:offlinePath])url = [NSURL fileURLWithPath:offlinePath];
                    }
                    
                    /*else if ([Props global].appID <= 1) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"This link is for offline content, which is only available in the purchased guide." delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:nil];   
                        
                        [alert show];  
                        [alert release];
                        url = 
                    }*/
				}
				
				WebViewController *webPageView = [[WebViewController alloc] initWithEntry:self.entry andURLToLoad:url];
				[self.navigationController pushViewController:webPageView animated:YES];
				
				SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVGoToOfflineContent];
				log.entry_id = entry.entryid;
				[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
				
				return NO;
			}
			
			else if (entry.entryid != -1) { 
				
				[self showWebPageViewWithURL: url];
				
				return NO;
			}
			
			//Code for handling links on the Sutro Page...
			else {
				
				//** Code for handling links on Sutro Entry **//
				//Need to add target app id on the the signature of the linkshare URL
				//Take advantage of the fact that sutro website gets called before linkshare referral
				//first strip app id from the sutro URL
				//then use it in the linkshare URL signature
				
				//get the target app id from the sutro page on the first run through
				
				NSLog(@"Absolute URL string = %@", [url absoluteString]);
				
				NSArray *sutroURLArray = [[url resourceSpecifier] componentsSeparatedByString:@"target_app_id="];
				NSArray *linkshareURLArray = [[url absoluteString] componentsSeparatedByString:@"&u1="];
				
				if ([sutroURLArray count] > 1) {
					
					targetAppID = [[sutroURLArray objectAtIndex:1] intValue];
					NSLog(@"Target App ID = %i", targetAppID);
					
					return YES;
				}
				
				//then use the target app id the next time this method gets called to construct the linkshare URL
				else if ([linkshareURLArray count] > 1) {
					
					NSLog(@"Linkshare base URL = %@", [linkshareURLArray objectAtIndex:0]);
					
					
					NSString *linkShareURLWithSignature = [[linkshareURLArray objectAtIndex:0] stringByAppendingString:[NSString stringWithFormat:@"&u1=a%i_e0_t%i_u%@", [Props global].appID, targetAppID, [Props global].deviceID]];
					
					linkShareURLWithSignature = [linkShareURLWithSignature stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					
					NSLog(@"Link share URL = %@", linkShareURLWithSignature);
					
					appURL = [NSURL URLWithString:linkShareURLWithSignature];
					NSLog(@"Final URL = %@", appURL);
					NSLog(@"App store URL before clicking alert view button = %@", [appURL absoluteString]);
					
					[self showGoToAppStoreAlert: (nil)];
					
					return NO;
				}
				
				//In the event that we want to show a webpage from the sutro page
				else if ([scheme isEqualToString:@"http"]) {
					
					if ([[url absoluteString] isEqualToString:@"http://www.sutromedia.com/iphone/apps/"]) return YES;
					
					else {
						
						[self showWebPageViewWithURL:url];
						return NO;
					}
				}
				
				else return YES;
			}
		}
		
		else [self goToExternalWebPageWithURL:url];
	}
	
	//Loading guides list on non-richtext guide
	else if (self.entry.entryid == -1 && aWebView == detailView.theGuidesList){
		
		//** Code for handling links on Sutro Entry **//
		//Need to add target app id on the the signature of the linkshare URL
		//Take advantage of the fact that sutro website gets called before linkshare referral
		//first strip app id from the sutro URL
		//then use it in the linkshare URL signature
		
		//get the target app id from the sutro page on the first run through
		
		NSArray *sutroURLArray = [[url resourceSpecifier] componentsSeparatedByString:@"target_app_id="];
		NSArray *linkshareURLArray = [[url absoluteString] componentsSeparatedByString:@"&u1="];
		
		NSLog(@"Sutro URL Array count = %i", [sutroURLArray count]);
		
		if ([sutroURLArray count] > 1) {
			
			targetAppID = [[sutroURLArray objectAtIndex:1] intValue];
			NSLog(@"Target App ID = %i", targetAppID);
			
			return YES;
		}
		
		//then use the target app id the next time this method gets called to construct the linkshare URL
		else if ([linkshareURLArray count] > 1) {
			
			NSLog(@"Linkshare base URL = %@", [linkshareURLArray objectAtIndex:0]);
			
			
			NSString *linkShareURLWithSignature = [[linkshareURLArray objectAtIndex:0] stringByAppendingString:[NSString stringWithFormat:@"&u1=%i", targetAppID]];
			
			appURL = [NSURL URLWithString:linkShareURLWithSignature];
			NSLog(@"Final URL = %@", appURL);
			NSLog(@"App store URL before clicking alert view button = %@", [appURL absoluteString]);
			
			[self showGoToAppStoreAlert: (nil)];
			
			return NO;
		}
	}
	
	return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	
	NSString *scheme = [webView.request.URL scheme];
	
	if (webView == richTextViewer /*[SMRichTextViewer sharedCopy]*/ && ![scheme isEqualToString:@"http"]) {
		
		richTextViewer.frame = CGRectZero;
		
		NSString *descrptionHeightString = [richTextViewer /*[SMRichTextViewer sharedCopy]*/  stringByEvaluatingJavaScriptFromString:@"document.getElementById('pageContent').offsetHeight"];
		
		CGRect frame = richTextViewer.frame;

		richTextViewer.contentSize = [descrptionHeightString floatValue];
		
		if (richTextViewer.contentSize > [Props global].screenHeight) richTextViewer.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, [Props global].screenHeight);
		
		else richTextViewer.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, richTextViewer.contentSize);
		
		
		if(detailView.drawCount < 2) {
			[detailView setNeedsDisplay];
			
			//CONTENT TEST CODE
			//[detailScrollView setContentOffset:CGPointMake(0,detailScrollView.contentSize.height - 60) animated:YES];
			//[self performSelector:@selector(loadNextEntry) withObject:nil afterDelay:1.00];
		}
	}
}


-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
	
    if (theAlert.tag == kSampleContentTag) {
        if (buttonIndex == 0) [self goBack:nil];
        
        else [self upgrade];
    }
	
	else if (theAlert.tag == kSampleContentWarningTag){
		if (buttonIndex != 0) [self upgrade];
	}
    
    else if (buttonIndex == 0) return;
    	
    else if(theAlert.tag == kAppStoreAlertTag) { 
        
        if (entry.entryid != -1) {
            
            NSString *linkShareLink = [NSString stringWithFormat:@"%@_u%@_o%i", pitch.linkshareURL, [Props global].deviceID,[[Props global] getOriginalAppId]];
            
            appURL = [NSURL  URLWithString:linkShareLink];
            
            NSLog(@"App store URL after clicking some alert view button = %@", [appURL absoluteString]);
            
            SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVGoToAppStore];
            log.entry_id = entry.entryid;
            log.target_app_id = pitch.appID;
            [[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
        }
        
        else {
            
            SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVGoToAppStore];
            log.entry_id = entry.entryid;
            log.target_app_id = targetAppID;
            [[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
        }
        
        NSLog(@"App store URL after clicking go for it = %@", [appURL absoluteString]);
        [self goToExternalWebPageWithURL: appURL];
    }
    
    else if (theAlert.tag == kiTunesAlertTag) [self goToExternalWebPageWithURL: iTunesURL];
    
    else if (theAlert.tag == kCallAlertTag) [self callThem];
    
    else if (theAlert.tag == kFavoritesAlertTag) {
        
        [[FilterPicker sharedFilterPicker] setPickerToFilter:kFavorites];
        self.tabBarController.selectedIndex = 0;
        [self showTopView:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kShowFilter object:nil];
    }
    
    else if (theAlert.tag == kUpgradeAlertTag)[self showPurchaseOption];
    
    else NSLog(@"******* ERROR: LocationViewController, Alert not found.");
}


- (void) showPurchaseOption {
	
	self.tabBarController.selectedIndex = 0;
	[self showTopView:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowSettings object:nil];
}


- (void) loadNextEntry {
	
	EntriesTableViewController *theTableViewController = controller;
	Entry *e = [[EntryCollection sharedEntryCollection] getNextEntry:self.entry];
	
	if (e.entryid != self.entry.entryid) {
		shouldScrollTableView = TRUE;
		
		[self loadEntry:e];
		
		unsigned indexes[2] = {0,theTableViewController.rowToGoBackTo.row + 1};
		NSIndexPath *thePath = [NSIndexPath indexPathWithIndexes:indexes length:2];
		theTableViewController.rowToGoBackTo = thePath;
		
		SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVScrollToNextEntry];
		log.entry_id = entry.entryid;
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}
	
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	
	NSLog(@"LOCATIONVIEWCONTROLLER - WebviewDidFailLoadWithError = %@", error);
}


- (void) setChangingTopBarToFalse {
    
    changingTopBar = false;
}


//Desired behavior ->
//Hide bars at start of dragging
//Show bars when scrolling to top
//Hide or show bars with tap
//Move top bar down when scrolling to previous
//Move bottom bar down when scrolling to next
//Don't hide the top bar on an iPad

/*- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

    //if (scrollView.contentOffset.y >lastOffset.y) {
    if (scrollView.contentOffset.y > kTitleBarHeight) {
        
        NSLog(@"LVC.scrollViewWillBeginDragging: Hiding bars at start of dragging");
        if ([Props global].deviceType != kiPad)  [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
        
        [self.navigationController setToolbarHidden:TRUE animated:TRUE];
    }
 }*/



- (void)scrollViewDidScroll:(UIScrollView *)sender {
    
    NSLog(@"ScrollViewDidScroll offset = %f", sender.contentOffset.y);
    
    if (changingTopBar) {
        NSLog(@"Returing because top bar is changing");
        return;
    }
    
    
    if (sender.contentOffset.y > lastOffset.y + 1000) {
        NSLog(@"Ignoring weird content offset values after scrolling between entries");
        return;
    }
    
    //weired bug scrolling between entries, where there are a bunch of bogus scrollViewDidScroll values initially
	if (!scrollOffsetHasReset && sender.contentOffset.y < 40 && sender.contentOffset.y > 5) {
        NSLog(@"\n\nReseting scroll offset with content offset = %f\n\n", sender.contentOffset.y);
        scrollOffsetHasReset = TRUE;
    }
    
    
    //NSLog(@"Delta scroll = %0.2f", ABS(sender.contentOffset.y - entry.lastScrollPosition));
    //NSLog(@"Sender.contentOffset.y = %0.2f", sender.contentOffset.y);
    
    //if (lastOffset.y - sender.contentOffset.y < 50) return; //Fixes an endless loop it gets stuck in hiding and showing top bar
    
    lastOffset = sender.contentOffset;
    /*if (ABS(sender.contentOffset.y - entry.lastScrollPosition) < 50) {
        NSLog(@"Not a big scroll");
        return;
    }*/
	
	//**** Adjust frame size on rich text viewer to force update on content (and avoid disappearing text) ****
    [self updateFrameForOffset:sender.contentOffset.y];
    
    float adHeight = adBannerIsVisible ? adView.frame.size.height : 0;
	
	// **** Navigate up and down between entries if we're coming from the list view ******
	if(canScrollToPrevious || canScrollToNext) {
		
        float bottomOffset = (canScrollToNext) ? kTopScrollGraphicHeight : 0;
        float topOffset = (canScrollToPrevious) ? kTopScrollGraphicHeight : 0; //This needs to be the same as variable in next method - maybe should have larger scope
        
		float distanceBelowBottom = sender.contentOffset.y - ((detailScrollView.contentSize.height - topOffset - bottomOffset) - [Props global].screenHeight) -adHeight;
    
		//NSLog(@"Distance below bottom = %f", distanceBelowBottom);
		
		//NSLog(@"Offset = %f", sender.contentOffset.y);
		
		if(distanceBelowBottom > kTopScrollGraphicHeight + 10  && entry.entryid != -1 && detailView.drawCount > 1){
			
			if (!goToNextOrPreviousEntry && !detailView.animating) [detailView flipScrollIcon:kBottomScrollIcon direction:kFlipUpsidedown];

			goToNextEntry = TRUE;
		}
		
		else if(canScrollToPrevious && sender.contentOffset.y < - kTopScrollGraphicHeight && detailView.drawCount > 1) {
			
			if (!goToPreviousEntry) [detailView flipScrollIcon:kTopScrollIcon direction:kFlipUpsidedown];
			goToPreviousEntry = TRUE;
		}
		
		else if (canScrollToPrevious && sender.contentOffset.y < 0 && detailView.drawCount > 1) {
			
			UIImage *titlebarImage = [[Props global] inLandscapeMode] ? titleBarImage_landscape : titleBarImage_portrait;
			
			if (titlebarImage == nil) titlebarImage = [self captureTitlebar];
			
			int fakeTopBarTag = 9827345;
			
			detailView.fakeTopBar = [[UIImageView alloc] initWithImage:titlebarImage];
			detailView.fakeTopBar.frame = CGRectMake(0, kTopScrollGraphicHeight, titlebarImage.size.width, titlebarImage.size.height);
			detailView.fakeTopBar.tag = fakeTopBarTag;
			
			for (UIView *view in [detailView subviews]) {if (view.tag == fakeTopBarTag) [view removeFromSuperview];}
			
			[detailView addSubview:detailView.fakeTopBar];
			
			detailView.fakeTopBar.hidden = FALSE;
            //changingTopBar = TRUE;
			[self.navigationController setNavigationBarHidden:TRUE animated:FALSE];
            //[self performSelector:@selector(setChangingTopBarToFalse) withObject:nil afterDelay:1.0];
			
			if (goToPreviousEntry) [detailView flipScrollIcon:kTopScrollIcon direction:kFlipUpright];

			goToPreviousEntry = FALSE;
		}
		
		else {
			//if(scrollPastTime != nil) [scrollPastTime release]; scrollPastTime = nil;
			goToNextOrPreviousEntry = FALSE;
			if (goToNextEntry) [detailView flipScrollIcon:kBottomScrollIcon direction:kFlipUpright];
			if (goToPreviousEntry) [detailView flipScrollIcon:kTopScrollIcon direction:kFlipUpright];
			if (detailView.fakeTopBar != nil && !detailView.fakeTopBar.hidden) {
				detailView.fakeTopBar.hidden = TRUE;
                //changingTopBar = TRUE;
				//**[self.navigationController setNavigationBarHidden:FALSE animated:FALSE];
                //[self performSelector:@selector(setChangingTopBarToFalse) withObject:nil afterDelay:1.0];
                [self.navigationController setToolbarHidden:FALSE animated:TRUE];
			}
			
			goToNextEntry = FALSE;
			goToPreviousEntry = FALSE;
		}
	}
	
	// ***** Hide and show navigation bar as appropriate *******
	// hide navigation and tool bars as they scroll down
    
    
    
    if(sender.contentOffset.y > [Props global].titleBarHeight + 5 && (!self.navigationController.navigationBar.hidden || !self.navigationController.toolbar.hidden) && ABS(sender.contentOffset.y - entry.lastScrollPosition) > 50 && scrollOffsetHasReset)  {
        //NSLog(@"Counter = %i", counter);
        //NSLog(@"Hiding navigation bar - scroll offset = %f", sender.contentOffset.y);
        if ([Props global].deviceType != kiPad && [Props global].appID > 1 && sender.contentOffset.y > [Props global].titleBarHeight){

            [self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
         
            NSLog(@"Hiding navingation bar for %@ with content offset = %f", entry.name, sender.contentOffset.y);
        }
        
        [self.navigationController setToolbarHidden:TRUE animated:TRUE];
    }
    
    // show navigation bar when user scrolls to top
    if(sender.contentOffset.y <= [Props global].titleBarHeight && sender.contentOffset.y >= 0 && self.navigationController.navigationBar.hidden) {
        NSLog(@"LVC.scrollViewDidScroll: Showing navigation bar");
        
        [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
        [self.navigationController setToolbarHidden:FALSE animated:TRUE];
    }
}


- (void) updateFrameForOffset:(float) offset {
    
    float chunkSize = 10;
	CGRect frame = richTextViewer.frame;
	
	float topOffset = (canScrollToPrevious) ? kTopScrollGraphicHeight : 0;
	
	float richTextViewerHeight = [Props global].screenHeight + (offset + topOffset) - frame.origin.y + chunkSize;
	
	if (richTextViewerHeight < 0) richTextViewerHeight = 0;
	
	
	if (richTextViewerHeight > richTextViewer.contentSize || richTextViewer.contentSize - richTextViewerHeight < chunkSize) {
		//NSLog(@"LVC.scrollViewDidScroll: updating frame size to contentsize (%f)", richTextViewer.contentSize);
		float additionalSize = (entry.descriptionHTMLVersion > 0) ? 80 : 0; //I'm thoroughly confused why this is necessary, but it is, otherwise end of tags get cut off
		richTextViewer.frame = CGRectMake(frame.origin.x, frame.origin.y, [Props global].screenWidth, richTextViewer.contentSize + additionalSize);
	}
	
	else if (richTextViewerHeight - frame.size.height > chunkSize){
		//NSLog(@"LVC.scrollViewDidScroll: increasing richtextviewer frame size to %f", richTextViewerHeight);
		richTextViewer.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, richTextViewerHeight);
	}
	
	else if (frame.size.height - richTextViewerHeight > chunkSize) {
		richTextViewer.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, richTextViewerHeight);
		//NSLog(@"LVC.scrollViewDidScroll: decreasing richtextviewframe size to %f", richTextViewerHeight );
	}

}


- (void)scrollViewDidEndDragging:(UIScrollView *)sender willDecelerate:(BOOL)decelerate {
	
    entry.lastScrollPosition = sender.contentOffset.y;
    
	if (goToNextOrPreviousEntry) {
		
		float topOffset = (canScrollToPrevious) ? kTopScrollGraphicHeight : 0;
		float bottomOffset = (canScrollToNext) ? kTopScrollGraphicHeight : 0;
        
        float adHeight = adBannerIsVisible ? adView.frame.size.height : 0;
		
		float distanceBelowBottom = sender.contentOffset.y - ((detailScrollView.contentSize.height - topOffset - bottomOffset) - [Props global].screenHeight - adHeight);
		
		if(distanceBelowBottom > kTopScrollGraphicHeight + 10  && entry.entryid != -1 && detailView.drawCount > 1){ 
			
			EntriesTableViewController *theTableViewController = controller;
			Entry *e = [[EntryCollection sharedEntryCollection] getNextEntry:self.entry];
			
			if (e.entryid != self.entry.entryid) {
				shouldScrollTableView = [EntryCollection sharedEntryCollection].currentSort == [Props global].spatialCategoryName ? FALSE : TRUE;
				
                entry.lastScrollPosition = 0;
				[self loadEntry:e];
				
				unsigned indexes[2] = {0,theTableViewController.rowToGoBackTo.row + 1};
				NSIndexPath *thePath = [NSIndexPath indexPathWithIndexes:indexes length:2];
				theTableViewController.rowToGoBackTo = thePath;
				
				SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVScrollToNextEntry];
				log.entry_id = entry.entryid;
				[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
			}
		}
		
		else if(canScrollToPrevious && sender.contentOffset.y < - kTopScrollGraphicHeight && detailView.drawCount > 1) {
			
			EntriesTableViewController *theTableViewController = controller;
			Entry *e = [[EntryCollection sharedEntryCollection] getPreviousEntry:self.entry];
			if (e.entryid != kSearchCellID && e.entryid != self.entry.entryid) {
				shouldScrollTableView = [EntryCollection sharedEntryCollection].currentSort == [Props global].spatialCategoryName ? FALSE : TRUE;
				entry.lastScrollPosition = 0;
                [self loadEntry:e];
				
				unsigned indexes[2] = {0,theTableViewController.rowToGoBackTo.row - 1};
				NSIndexPath *thePath = [NSIndexPath indexPathWithIndexes:indexes length:2];
				theTableViewController.rowToGoBackTo = thePath;
                
                //theTableViewController.rowToGoBackTo = [EntryCollection sharedEntryCollection].currentIndex;
				
				SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVScrollToPreviousEntry];
				log.entry_id = entry.entryid;
				[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
			}
			
		}
	}
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
    if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        
        return YES;
    }
    
    else return NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
    if (toInterfaceOrientation != UIDeviceOrientationFaceUp && toInterfaceOrientation != UIDeviceOrientationFaceDown && toInterfaceOrientation != UIDeviceOrientationUnknown) {
        [[Props global] updateScreenDimensions: toInterfaceOrientation];
        NSLog(@"LVC.willRotateToInterfaceOrientation");
        [self loadEntry:entry];
	
        if ([[Props global] appID] == 0) [self addGetOniTunesBarButton];
    }
	
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {return YES;}


- (void)swipeRightAction:(id)ignored {
    
    NSLog(@"Swipe Right");
    //add Function
}


#pragma mark -
#pragma mark Freemium Upgrade V2 Methods

- (void) upgrade {
    
    NSLog(@"LVC.upgrade");
	
	if ([Props global].isShellApp) [[MyStoreObserver sharedMyStoreObserver] upgradeSamplePurchaseForGuideId:[Props global].appID];
	
	else {
		[self showMessage:@"Waiting for App Store..."];
		
		[[MyStoreObserver sharedMyStoreObserver] getOfflineContentUpgrade];
	}
}


- (void) showThankYou {
    
	@autoreleasepool {
		
        [[self.view viewWithTag:kWaitingForAppStoreMessageTag] removeFromSuperview];
		
		NSString *loadingTagMessage = @"Thanks!"; //@"Waiting for the App Store...";
		
		UIFont *errorFont = [UIFont boldSystemFontOfSize: 20];
		CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].rightMargin - [Props global].leftMargin, 19);
        
		CGSize textBoxSize = [loadingTagMessage sizeWithFont: errorFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
		
		float borderWidth = 12; //side of border between background and stuff on inside
        float height = textBoxSize.height + borderWidth * 2;
		float messageWidth = textBoxSize.width + borderWidth * 2;
		
        UIView *waitingBackground = [[UIView alloc] initWithFrame:CGRectMake(([Props global].screenWidth - messageWidth)/2, [Props global].screenHeight/2.5, messageWidth, height)];
        waitingBackground.opaque = NO;
        waitingBackground.backgroundColor = [UIColor clearColor];
        waitingBackground.tag = kThankYouTag;
        
		CALayer *backgroundLayer = [[CALayer alloc] init];
        backgroundLayer.borderColor = [UIColor blackColor].CGColor;
        backgroundLayer.borderWidth = 2;
        backgroundLayer.cornerRadius = 12;
        backgroundLayer.backgroundColor = [UIColor blackColor].CGColor;
        backgroundLayer.opacity = 0.4;
        backgroundLayer.shadowOpacity = 0.8;
        backgroundLayer.shadowColor = [UIColor blackColor].CGColor;
        backgroundLayer.shadowOffset = CGSizeMake(2, 2);
        backgroundLayer.bounds = waitingBackground.bounds;
        backgroundLayer.position = CGPointMake([waitingBackground bounds].size.width/2, [waitingBackground bounds].size.height/2);
        [waitingBackground.layer addSublayer:backgroundLayer];
		
		CGRect labelRect = CGRectMake (borderWidth, (waitingBackground.frame.size.height - textBoxSize.height)/2, textBoxSize.width, textBoxSize.height);
		UILabel *loadingTag = [[UILabel alloc] initWithFrame:labelRect];
		loadingTag.text = loadingTagMessage;
		loadingTag.font = errorFont;
		loadingTag.textColor = [UIColor lightGrayColor];
		loadingTag.lineBreakMode = 0;
		loadingTag.numberOfLines = 2;
		loadingTag.backgroundColor = [UIColor clearColor];
		[waitingBackground addSubview:loadingTag];
        
        [self.view addSubview: waitingBackground];
	}
}


- (void) freemiumUpgradePurchased {
    
    NSLog(@"LVC.freemiumUpgradePurchased");
    
    for (UIView *view in [self.view subviews]) {
        if (view.tag == kUpgradeViews) [view removeFromSuperview];
    }
    
    [self showThankYou];
    [self performSelector:@selector(hideMessage) withObject:nil afterDelay:2.0];
    
    [self.view setNeedsLayout];
}


- (void) showMessage:(NSString *) message {
    
	@autoreleasepool {
		
        [[self.view viewWithTag:kWaitingForAppStoreMessageTag] removeFromSuperview];
		
		NSString *loadingTagMessage = message; //@"Waiting for the App Store...";
		float loadingAnimationSize = 20; //This variable is weird - only sort of determines size at best.
		
		UIFont *errorFont = [UIFont fontWithName: kFontName size: 16];
		CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].rightMargin - [Props global].leftMargin, 19);
        
		CGSize textBoxSize = [loadingTagMessage sizeWithFont: errorFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
		
		float borderWidth = 12; //side of border between background and stuff on inside
		float messageWidth = loadingAnimationSize + textBoxSize.width + borderWidth * 3;
		
        UIView *waitingBackground = [[UIView alloc] initWithFrame:CGRectMake(([Props global].screenWidth - messageWidth)/2, [Props global].screenHeight/2.5, messageWidth, loadingAnimationSize + borderWidth*2)];
        waitingBackground.opaque = NO;
        waitingBackground.backgroundColor = [UIColor clearColor];
        waitingBackground.tag = kWaitingForAppStoreMessageTag;
        
		CALayer *backgroundLayer = [[CALayer alloc] init];
        backgroundLayer.borderColor = [UIColor blackColor].CGColor;
        backgroundLayer.borderWidth = 2;
        backgroundLayer.cornerRadius = 12;
        backgroundLayer.backgroundColor = [UIColor blackColor].CGColor;
        backgroundLayer.opacity = 0.4;
        backgroundLayer.shadowOpacity = 0.8;
        backgroundLayer.shadowColor = [UIColor blackColor].CGColor;
        backgroundLayer.shadowOffset = CGSizeMake(2, 2);
        backgroundLayer.bounds = waitingBackground.bounds;
        backgroundLayer.position = CGPointMake([waitingBackground bounds].size.width/2, [waitingBackground bounds].size.height/2);
        [waitingBackground.layer addSublayer:backgroundLayer];
		
		CGRect frame = CGRectMake(borderWidth, (waitingBackground.frame.size.height - loadingAnimationSize)/2, loadingAnimationSize, loadingAnimationSize);
		UIActivityIndicatorView * progressInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
		progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
		[progressInd sizeToFit];
		[progressInd startAnimating];
		[waitingBackground addSubview: progressInd];
		
		CGRect labelRect = CGRectMake ( CGRectGetMaxX(progressInd.frame) + borderWidth, (waitingBackground.frame.size.height - textBoxSize.height)/2, textBoxSize.width, textBoxSize.height);
		UILabel *loadingTag = [[UILabel alloc] initWithFrame:labelRect];
		loadingTag.text = loadingTagMessage;
		loadingTag.font = errorFont;
		loadingTag.textColor = [UIColor lightGrayColor];
		loadingTag.lineBreakMode = 0;
		loadingTag.numberOfLines = 2;
		loadingTag.backgroundColor = [UIColor clearColor];
		[waitingBackground addSubview:loadingTag];
        
        [self.view addSubview: waitingBackground];
		
	}
}


- (void) transactionFailed {
	
	[self hideMessage];
	
	if ([Props global].freemiumType == kFreemiumType_V2) [self goBack:nil];
}


- (void) hideMessage {
	
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.1];
    
    for (UIView *view in [self.view subviews]) {
        if (view.tag == kWaitingForAppStoreMessageTag || view.tag == kThankYouTag) view.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    }
    
    [UIView commitAnimations];
    
    [self performSelector:@selector(removeMessage) withObject:nil afterDelay:0.1];
}


- (void) removeMessage {
    
    for (UIView *view in [self.view subviews]) {
        if (view.tag == kWaitingForAppStoreMessageTag || view.tag == kThankYouTag) [view removeFromSuperview];
    }
    
    [self.view setNeedsDisplay];
}


#pragma mark -
#pragma mark ADBannerViewDelegate Methods


//Detect when new ads are shown
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    /* Called when a new banner ad is loaded. Implement this to notify
     app that new ad is ready for display */
    NSLog(@"SS:LVC<-bannerViewDidLoad: AdBannerView loaded");
    if (!adBannerIsVisible) {
        adBannerIsVisible = TRUE;
        NSLog(@"SS:LVC<-bannerViewDidLoad: set adBannerVisible to TRUE and calling fixupAdView");
        [self fixupAdView];
    }
}

//Detect when user interacts with ad
- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    /* Called when banner view finishes executing an action that covers
     the app's UI. Any activities paused the delegate should be resumed */
    //Nothing to do right now
}


//Detect errors
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    /* Called when banner view fails to load a new ad */
    NSLog(@"SS:LVC<-bannerView:didFailToReceiveAdWithError: error: %@", [error localizedDescription]);
    if (adBannerIsVisible) {
        adBannerIsVisible = FALSE;
        [self fixupAdView];
    }
}


- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    
    SMLog *log = [[SMLog alloc] initWithPageID:kEntryIntroView actionID: kAdClicked];
    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
    
    return TRUE;
}

#pragma mark -
#pragma mark Compose Mail

- (void) showShareView: (id) sender {
	
	SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVShareEntry];
	log.entry_id = entry.entryid;
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	
	
	MFMailComposeViewController *emailer = [[MFMailComposeViewController alloc] init];
	emailer.mailComposeDelegate = self;
	
	[emailer setSubject:[NSString stringWithFormat:@"Check out %@",entry.name]];
	
    float width = [Props global].deviceType == kiPad ? 500 : 310;
	
	NSString* header =[NSString stringWithFormat:@"<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01//EN''http://www.w3.org/TR/html4/strict.dtd'><html><head><style type=\"text/css\"> A:link{text-decoration:none; font-weight:550; color:%@;} </style></head><body leftmargin=0 marginwidth=0 marginheight=0 offset=0 bgcolor=white >", [Props global].cssLinkColor];
	
	NSString *messageHeader = @"<p> Thought you'd like this...</p>";
	
	NSString *tableHeader = [NSString stringWithFormat:@"<table width=%f cellpadding=0 cellspacing=0 style='color:rgb(070,070,070); font-family:Arial, Helvetica, sans-serif;'>", width];
	
	NSString *emailLink;
	
	if ([Props global].appID > 1) emailLink = [NSString stringWithFormat:@"%@?id=entemail_a%i_e%i", [Props global].appLink, [Props global].appID, entry.entryid];
	
	else emailLink = [NSString stringWithFormat:@"%@?id=entemail_a%i_e%i", pitch.linkshareURL, [Props global].appID, entry.entryid];
	
	NSLog(@"Email link = %@ and pitch url = %@", emailLink, pitch.linkshareURL);
	
	NSString *guideLink = ([Props global].appID <= 1) ? @"": [NSString stringWithFormat:@"<tr><td COLSPAN=2 STYLE='PADDING-BOTTOM:10px; FONT-SIZE:14px'>From <a href='%@' style='text-decoration:none; color:%@'>%@</a>...</td></tr>", emailLink, [Props global].cssLinkColor, [Props global].appName];
	
	NSString *entryTitle = [NSString stringWithFormat:@"<tr><td COLSPAN=2 align='center' width='%0.0f' height='%f'  BACKGROUND='http://www.sutroproject.com/content/shared_content/Email_Top%@.gif' style='font-size:17px;font-weight:bold; PADDING-RIGHT: 0px; PADDING-LEFT: 0px; PADDING-BOTTOM: 6px;  PADDING-TOP:15px; background-repeat: no-repeat;'>%@</td></tr>",width, width * .11, [Props global].deviceType == kiPad ? @"_iPad" : @"", entry.name];
	
	NSString *tagline = [NSString stringWithFormat:@"<tr><td COLSPAN=2 align='center' style='font-size:14px; BORDER-LEFT: #808080 2px solid; BORDER-RIGHT: #808080 2px solid; PADDING-LEFT:6px; PADDING-RIGHT:6px; PADDING-BOTTOM:8px; PADDING-TOP: 12px; '><span style='font-weight:800;font-style:italic;'>%@</span></td></tr>",entry.tagline];
	
	
	//We only need to add line breaks for plain text
	//We need to remove Sutro Links for rich text - for now we'll just remove all links form description.
	
	NSString *descriptionWithLineBreaks;
	
	if (entry.descriptionHTMLVersion > 0) descriptionWithLineBreaks = [self flattenHTML:entry.description];
	
	else {
		
		NSString *string = entry.description;
		
		unsigned length = [string length];
		unsigned paraStart = 0, paraEnd = 0, contentsEnd = 0;
		NSMutableArray *array = [NSMutableArray array];
		NSRange currentRange;
		while (paraEnd < length) {
			[string getParagraphStart:&paraStart end:&paraEnd
						  contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
			currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
			[array addObject:[string substringWithRange:currentRange]];
		}
		
		descriptionWithLineBreaks = @"";
		NSString *paragraph = nil;
		
		for (paragraph in array) {
			
			if ([paragraph length] > 0) 
				
				descriptionWithLineBreaks = [descriptionWithLineBreaks stringByAppendingString:[NSString stringWithFormat:@"%@<br><br>", paragraph]];
		}
	}
	
	
	//NSString *description = [NSString stringWithFormat:@"<tr><td COLSPAN=2 WIDTH=310 bgcolor= white style='font-size:12px; BORDER-LEFT: #808080 2px solid; BORDER-RIGHT: #808080 2px solid; PADDING-LEFT:10px; PADDING-RIGHT:10px; PADDING-BOTTOM:16px; A:link{text-decoration:none; font-weight:550; color:%@;}'>%@</td></tr>", [Props global].cssLinkColor, descriptionWithLineBreaks];
	
	NSString *description = [NSString stringWithFormat:@"<tr><td COLSPAN=2 WIDTH=%0.0f bgcolor= white style='font-size:12px; BORDER-LEFT: #808080 2px solid; BORDER-RIGHT: #808080 2px solid; PADDING-LEFT:10px; PADDING-RIGHT:10px; PADDING-BOTTOM:16px;'>%@</td></tr>", width, descriptionWithLineBreaks];
	
	NSLog(@"LVC.showShareVew:description = %@", description);
	
	NSString *appLink;
	
	if ([Props global].appID > 1) {
		appLink = [NSString stringWithFormat:@"<tr><td COLSPAN=2 ALIGN='left' style='BORDER-LEFT: #808080 2px solid; BORDER-RIGHT: #808080 2px solid; PADDING-LEFT:6px; PADDING-RIGHT:6px'><table cellpadding='0' cellspacing='0' border='0'><tr><td><a href='%@' style='vertical-align:middle;'><img src='http://www.sutromedia.com/app-icons/%i_36x36.jpg' width='40' height='40' style='border-color:white; border-right:#FFFFFF 10px solid;'/></a></td><td><a href='%@' style='vertical-align:center; font-size:12px; text-decoration:none; color:%@'>Get <span style='font-weight:bold'>%@</span> for your iPhone</a></td></tr></table></td></tr>",emailLink, [Props global].appID, emailLink, [Props global].cssLinkColor, [Props global].appName];
	}
	
	else {
		appLink = [NSString stringWithFormat:@"<tr><td COLSPAN=2 ALIGN='left' style='BORDER-LEFT: #808080 2px solid; BORDER-RIGHT: #808080 2px solid; PADDING-LEFT:6px; PADDING-RIGHT:6px'><table cellpadding='0' cellspacing='0' border='0'><tr><td><a href='%@' style='vertical-align:middle;'><img src='http://www.sutromedia.com/app-icons/%i_36x36.jpg' width='40' height='40' style='border-color:white; border-right:#FFFFFF 10px solid;'/></a></td><td><a href='%@' style='vertical-align:center; font-size:12px; text-decoration:none; color:%@'>Get <span style='font-weight:bold'>%@</span> for your iPhone</a></td></tr></table></td></tr>",emailLink, entry.entryid, emailLink, [Props global].cssLinkColor, entry.name];
	}

	NSString *copyright = ([Props global].appID <= 1) ? @"":[NSString stringWithFormat:@"<tr><td COLSPAN=2 style='font-size:12px; BORDER-LEFT: #808080 2px solid; BORDER-RIGHT: #808080 2px solid; PADDING-LEFT:6px; PADDING-RIGHT: 6px; padding-top:10px; PADDING-BOTTOM:8px;'><span style='font-weight:200;font-style:italic;'>Copyright (C) %@. All rights reserved.</span></td></tr>", [Props global].authorName];
	
	NSString *sutroLink = [NSString stringWithFormat:@"<tr><td COLSPAN=2 align='left' width='%0.0f' height='%f'><a href='http://www.sutromedia.com'><img height='%f' alt='Published by Sutro Media' src='http://www.sutroproject.com/content/shared_content/Email_Bottom%@.gif' width='%0.0f' border='0'></a></td></tr>", width, width * .11, width * .11, [Props global].deviceType == kiPad ? @"_iPad" : @"", width];
    
	NSString *footer = @"</table></body></html>";
	
	NSString *rootSutroImageURL = @"http://www.sutromedia.com/published/iphone-sized-photos/";
	
	rootSutroImageURL = [rootSutroImageURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	UIImage *iconImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"%i",entry.icon] ofType:@"jpg"]];
	
	if (iconImage == nil) {
		
		//big image has not yet been downloaded, so we'll use a small one
		iconImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_151x", entry.icon] ofType:@"jpg"]];
	}
    
    if(iconImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
        
        NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/images/%i.jpg",[Props global].contentFolder , entry.icon];
        iconImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
    }
    
    if(iconImage == nil) { //look for a big version of the image (if we're on the iPad)
        
        NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/images/%i_768.jpg",[Props global].contentFolder , entry.icon];
        iconImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
    }

	/*														  
	UIImage *mapImage = nil;
	
	if ([Props global].appID != 0) mapImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_map",entry.entryid] ofType:@"jpg"]];
	
	if(mapImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
		
		NSString *theFilePath = [NSString stringWithFormat:@"%@/%i_map.jpg",[Props global].contentFolder , entry.entryid];
		
		mapImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
		
		NSLog(@"Looking for map at %@", theFilePath);
	}*/
	
	NSString *emailBody;
	NSString *mapImageHTML;
	NSString *iconImageHTML;
	
	if (FALSE && [Props global].appID > 1 && [entry getLatitude] != 0) { //maps are broken at the moment, so we're pulling this feature for now
		
		iconImageHTML = [NSString stringWithFormat:@"<tr><td style='PADDING-LEFT:4px; BORDER-LEFT: #808080 2px solid;'><IMG SRC='%@/%i.jpg' BORDER='0' align='left' width='%f' height='%f'></td>",rootSutroImageURL,entry.icon, width/2 - 10, (width/2 - 10) * iconImage.size.height/iconImage.size.width];
		
		NSString *mapLink = [[NSString stringWithFormat:@"http://sutroproject.com/content/%i/%i Content/images/%i_map.jpg", [Props global].appID, [Props global].appID, entry.entryid] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
        //Added an extra \ in the string below (see the '\\') to get rid of a compiler warning. Don't know if this creates a problem or not, as this is currently dead code. Look out if we use this code in the future
        mapImageHTML = [NSString stringWithFormat:@"<td style='PADDING-RIGHT:4px; BORDER-RIGHT: #808080 2px solid;'><a href='http://maps.google.com/maps?q=%@\\@%f,%f&g=%@&sll=%0.5f,%0.5f&t=m&z=17&iwloc=A'><img src='%@' BORDER='0' align='right' width='%fpx' height='%fpx'></a></td></tr>",entry.name,[entry getLatitude], [entry getLongitude], entry.address, [entry getLatitude], [entry getLongitude], mapLink, width/2 - 10, (width/2 - 10)* iconImage.size.height/iconImage.size.width];   
		
		emailBody = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@",header,messageHeader,tableHeader, guideLink, entryTitle,iconImageHTML, mapImageHTML, tagline, description, appLink,copyright,sutroLink,footer];
	}
	
	
	else {
		
		NSLog(@"No map, so we're just showing a big pic");
		
        float iconWidth = width - 8;
		iconImageHTML = [NSString stringWithFormat:@"<tr><td style='PADDING-LEFT:2px; BORDER-RIGHT: #808080 2px solid; BORDER-LEFT: #808080 2px solid;'><IMG SRC='%@/%i.jpg' BORDER='0' align='left' width='%f' height='%f'></td>",rootSutroImageURL,entry.icon,iconWidth, iconWidth * iconImage.size.height/iconImage.size.width];
		
		emailBody = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@",header,messageHeader,tableHeader, guideLink, entryTitle,iconImageHTML, tagline, description, appLink,copyright, sutroLink, footer];
	}

		
	NSLog(@"HTML for email = \n%@", emailBody);
	
	[emailer setMessageBody:emailBody isHTML:YES];
	
	if (iconImage != nil) {
		iconImage = nil;
	}
	
	/*if (mapImage != nil) {
		[mapImage release];
		iconImage = nil;
	}*/
	
    if ([Props global].osVersion >= 5.0) {
        [self presentViewController:emailer animated:YES completion:nil];
    }
    
    else [self presentModalViewController:emailer animated:YES];
	
}

//removes any links from text
- (NSString *)flattenHTML:(NSString *)html {
	
    NSScanner *theScanner;
    NSString *text = nil;

	html = [html stringByReplacingOccurrencesOfString:@"<br>" withString:@"xxxbrxxx"];
	
    theScanner = [NSScanner scannerWithString:html];
	
    while ([theScanner isAtEnd] == NO) {
		
        // find start of tag
        [theScanner scanUpToString:@"<" intoString:NULL] ; 
		
        // find end of tag
        [theScanner scanUpToString:@">" intoString:&text] ;
		
        // replace the found tag with a space
        //(you can filter multi-spaces out later if you wish)
        html = [html stringByReplacingOccurrencesOfString:
				[ NSString stringWithFormat:@"%@>", text]
											   withString:@" "];
		
    } // while //
	
	html = [html stringByReplacingOccurrencesOfString:@"xxxbrxxx" withString:@"<br>"];
    
    return [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];	
}


// Displays an email composition interface inside the application. Populates all the Mail fields. 
-(void)displayComposerSheetForRecipient:(NSString*) recipient {
    
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	picker.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	self.navigationController.navigationBar.translucent = FALSE;
	
	if ([recipient isEqualToString:@"letusknow@sutromedia.com"]) [picker setSubject:[NSString stringWithFormat:@"Comments on %@",[Props global].appName]];
	
	// Set up recipients
	NSArray *toRecipients = [NSArray arrayWithObject:recipient]; 
		
	[picker setToRecipients:toRecipients];
	
	[self presentModalViewController:picker animated:YES];
}


// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Workaround
// Launches the Mail application on the device.
-(void)launchMailAppOnDeviceForRecipient:(NSString *) recipient
{
	NSString *recipients = [recipient isEqualToString:@"letusknow@sutromedia.com"] ? [NSString stringWithFormat:@"mailto:letusknow@sutromedia.com&subject=Comments on %@",[Props global].appName] : [NSString stringWithFormat:@"mailto:%@",recipient];
	NSString *body = nil;
	
	NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
	email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

@end
