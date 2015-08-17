#import "EntriesTableViewController.h"
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
#import "TutorView.h"
#import "Region.h"
#import "MyStoreObserver.h"
#import "OfflineContentDownloadStatus.h"
#import "SettingsView.h"
#import "HeaderViewCell.h"
#import "SMPopUp.h"
#import "IntroTutorial.h"


#define kTutorViewTag 49872345
#define kIntroAdTag 2345098
#define kUpgradeAdTag 90872345  
#define kSutroAdTag 2345234
#define kBackgroundCancelButtonTag 23456524
#define kSutroHideAdButtonTag 98072345
#define kHeaderHeight [Props global].deviceType == kiPad ? 56.3 : 40
#define kBannerEntryHeight [Props global].deviceType == kiPad ? 70 : 60
#define kSutroWorldURL @"http://sutromedia.com/world"
#define kUpgradeButtonTitleKey @"upgrade button title"
#define kSettingsViewTag 842483038
#define kSettingsViewButtonTag 857494789
#define kGearIconTag 7892435
#define kUpgradePopupTag 30094449
#define kWaitingForAppStoreMessageTag 234655 
#define kThankYouTag 4320987
#define kCoverViewTag 89762345
#define kBackgroundViewTag 98762435
#define kUpgradeAlertTag 2453543
#define kUpgradeViews 4839373

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface EntriesTableViewController (Private)

- (void) setViewMovedUp:(BOOL)movedUp;
- (void) refreshData;
- (void) hideSutroAd;
- (void) addUpgradeButtonWithSelector:(NSString*) selectorString;
- (void) hideUpgradeView;
- (void) getOfflineUpgrade;
- (void) addReturnToAppButton;
//- (void) hideSearchRow;
- (void) showTopRow;
- (void) hideFilterPicker: (id) sender;
//- (void) addGoHomeButton;
- (void) createSortButtons;
- (void) addSettingsButtonWithSelector:(NSString*) selectorString;
- (NSMutableArray*) createEntryFirstLetterIndex;
- (void) addRightSideToolbar;
- (void) showSettings;
- (void) hideSettings;

- (void) showUpgradePopup;
- (void)fixupAdViewWithAnimation:(BOOL) shouldAnimate;
- (void)createAdBannerView;
- (void) hideAdBannerWithAnimation:(BOOL) shouldAnimate;
- (void) showThankYou;

@end

@implementation EntriesTableViewController

@synthesize theTableView, /*dataSource,*/ currentEntry, rowToGoBackTo, /*searchCell,*/ homeController, entryFirstLetterIndex, sortCriteria;
 
//iAd Synthesizes
@synthesize adView, adBannerIsVisible;
    
- (id)init {
    
    self = [super init];
	if (self) {
		
		self.theTableView = nil;
		self.title = @"Browse";
		self.tabBarItem.image = [UIImage imageNamed: @"By_Name.png"];
		self.navigationItem.title= nil; //@"Best of SF";
        self.navigationItem.titleView = nil;
		searchController = nil;
		searchText = nil;
        sutroButton = nil;
		filterCriteria = [[FilterPicker sharedFilterPicker] getPickerTitle];
		sortCriteria = [Props global].sortable ? [FilterPicker sharedFilterPicker].sortType : nil;
		showingDistanceRow = [FilterPicker sharedFilterPicker].showingDistanceSort;
		filterPickerShowing = FALSE;
        settingsShowing = FALSE;
		firstTime = TRUE;
		searchKeyboardShowing = FALSE;
		self.hidesBottomBarWhenPushed = FALSE; 
        
        NSMutableArray *tmpIndex = [self createEntryFirstLetterIndex];
        self.entryFirstLetterIndex = tmpIndex;
		
		[self refreshData];
		
		//register to get notification when purchase transaction is complete so we can refresh data as necessary
		
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPremiumContent:) name:kTransactionComplete object:nil];
        
        NSString *samplePurchasedNotification = [NSString stringWithFormat:@"%@_%i", kSampleGuidePurchased, [Props global].appID];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goHome:) name:samplePurchasedNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goHome:) name:kGoHome object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freemiumUpgradePurchased) name:kFreemiumUpgradePurchased object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUpgrade) name:kShowUpgrade object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFilterPicker:) name:kShowFilter object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSettings) name:kShowSettings object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData) name:kContentUpdated object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(animateGear) name:kContentDownloaded object:nil];
        
		//Set the custom back image for getting back here from LocationViewController
		UIImage *backImage =[UIImage imageNamed:@"backToList.png"];
		UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backImage style: UIBarButtonItemStylePlain target:nil action:nil];
		
		self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
		
		}

	return self;
}


- (void)dealloc {
	
	NSLog(@"ETVC.dealloc *****************************************************");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.adView.delegate = nil;
    if (searchController != nil) {searchController.delegate = nil;  searchController = nil;}
    if (searchBar != nil) {searchBar.delegate = nil;  searchBar = nil;}
    if (sutroButton != nil) { sutroButton = nil;}
    
    if (pickerSelectButton != nil) { pickerSelectButton = nil;}
}


- (void)loadView {
    
	UIView *contentView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - kTabBarHeight - kTitleBarHeight)];
	self.view = contentView;
	
	
	UITableView *tableView = [[UITableView alloc] initWithFrame: self.view.bounds style:UITableViewStylePlain];
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.sectionIndexMinimumDisplayRowCount = 10;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	tableView.autoresizesSubviews = YES;
    tableView.sectionHeaderHeight = sortCriteria == [Props global].spatialCategoryName ? kHeaderHeight : 0;
	self.theTableView = tableView;
	[self.view addSubview:theTableView];
	
	if ([Props global].isShellApp) [self addLoadingOverlay];
    
    if (([Props global].deviceType == kiPad || [[Props global] inLandscapeMode]) && [Props global].sortable) [self createSortButtons];
	
	
	if([Props global].filters != nil || [Props global].sortable) {
        
		pickerSelectButton = [[FilterButton alloc] initWithController:self];
		self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
	}
	
	else self.navigationItem.title = [Props global].appShortName;
	
	
	self.navigationController.navigationBar.translucent = FALSE;
    
    searchBar = [[UISearchBar alloc]initWithFrame:CGRectZero];
    searchBar.center = CGPointMake([Props global].screenWidth*.75, [Props global].titleBarHeight/2);
    searchBar.barStyle = UIBarStyleDefault;
    searchBar.tintColor = [UIColor colorWithWhite:0.7 alpha:1];
    searchBar.alpha = 1.0;
    searchBar.showsCancelButton = YES;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    searchBar.delegate = self;
    searchBar.hidden = TRUE;
    [self.view addSubview:searchBar];
    
	
	searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
	searchController.delegate = self;
	searchController.searchResultsDataSource = self;
	searchController.searchResultsDelegate = self;
	searchController.active = FALSE;
    
    //NSString *tutorialShownKey = [NSString stringWithFormat:@"ListViewTutorialShown_%i", [Props global].appID];
    
    NSString *tutorialShownKey = @"ListViewTutorialShown";
	//NSLog(@"************** WARNING: SET TO ALWAYS SHOW TUTORIAL *********************");
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:tutorialShownKey]) {
		
		if ([Props global].freemiumType == kFreemiumType_V2 || [Props global].isFreeSample) [self performSelector:@selector(showSampleAlertAsNecessary) withObject:nil afterDelay:5];
		
		else if ([Props global].appID > 1) {
			
			NSLog(@"ETVC.viewWillAppear:about to show tutorial");
			
			IntroTutorial *intro = [[IntroTutorial alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - kTabBarHeight - kTitleBarHeight)];
			intro.tag = kIntroAdTag;
			[self.view addSubview:intro];
			[intro startAnimation];
			
			[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:tutorialShownKey];
		}
	}
    
    /*else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"SutroWorldTutorialShown"] && [Props global].appID == 0){
        
        NSString *imageName = [[Props global] inLandscapeMode] ? @"SutroWorldIntro_landscape" : @"SutroWorldIntro";
		float frameHeight = [[Props global] inLandscapeMode] ? [Props global].screenHeight - (kTabBarHeight - kPartialHideTabBarHeight) - [Props global].titleBarHeight : [Props global].screenHeight - kTabBarHeight - [Props global].titleBarHeight;
        TutorView *tutorView = [[TutorView alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, frameHeight) andView:imageName];
		tutorView.tag = kTutorViewTag;
		[self.view addSubview:tutorView];
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"SutroWorldTutorialShown"];
    }*/
	
	if ([Props global].isShellApp) [self hideLoadingOverlay];

	NSLog(@"ETVC.loadView: picker button = %@", pickerSelectButton);
}


-(void)viewWillAppear:(BOOL)animated {
	
    //NSLog(@"ETVC.viewWillAppear:Tableview frame height = %f, width = %f", self.theTableView.frame.size.height, self.theTableView.frame.size.width);
	//goingToEntry = FALSE;
    [self addRightSideToolbar];
    	
	//used to make tab bar show completely if we hid it a bit in the slideshow view previously
	self.navigationController.navigationBar.translucent = FALSE;
	[self.navigationController setNavigationBarHidden:FALSE animated:FALSE];
		
	self.navigationController.navigationBar.alpha = .9;
	
    if ([Props global].osVersion < 7.0) self.navigationController.navigationBar.tintColor = [Props global].navigationBarTint;
    else self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
	self.navigationController.navigationBar.hidden = FALSE;
    self.navigationController.toolbarHidden = TRUE;
	//if ([Props global].sortable)[[FilterPicker sharedFilterPicker] showSorterPicker];
	
	if ([Props global].deviceType != kiPad) {
        if ([[Props global] inLandscapeMode] && [Props global].osVersion > 3.1){
            
            //update for SW - WHY????
            if ([Props global].isShellApp) self.tabBarController.view.frame = CGRectMake( 0,0, [Props global].screenWidth, [Props global].screenHeight + kPartialHideTabBarHeight);
            
            else {
                //original version for regular app
                float xPos =  [[UIDevice currentDevice] orientation]==UIDeviceOrientationLandscapeLeft ? -kPartialHideTabBarHeight : 0;
                self.tabBarController.view.frame = CGRectMake( xPos,0, [Props global].screenHeight + kPartialHideTabBarHeight, [Props global].screenWidth);
            }
        }
        
        else self.tabBarController.view.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
    }
    
	if(!firstTime){
		
		SMLog *log = [[SMLog alloc] initWithPageID: kTLLV actionID: kLVViewSelected];
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}

	firstTime = FALSE;
	
	//Set view to show all if the filter is set to favorites and the last favorite was removed
	if(([[EntryCollection sharedEntryCollection] favoritesExist] == FALSE) && [filterCriteria  isEqual: kFavorites]){
		filterCriteria = nil;
		[self refreshData];
		[[FilterPicker sharedFilterPicker].theFilterPicker selectRow:0 inComponent:0 animated: NO];
	}
	
	if ([[EntryCollection sharedEntryCollection] favoritesExist] && [[[FilterPicker sharedFilterPicker] getPickerTitle]  isEqual: kFavorites]) {
		NSMutableArray *theFavorites = [[NSMutableArray alloc] initWithArray: [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]]];
		
		if ([theFavorites count] != [[EntryCollection sharedEntryCollection].sortedEntries count] ) {
			NSLog(@"ETVC.viewWillAppear: updating entry collection after entry was removed from favorites");
			[self refreshData];
		}
	}
    
	//update view if the filter was changed in another view
	if([Props global].filters != nil) {

		if(([filterCriteria isEqualToString:[[FilterPicker sharedFilterPicker] getPickerTitle]] == FALSE)){
			filterCriteria = [[FilterPicker sharedFilterPicker] getPickerTitle];
			sortCriteria = [FilterPicker sharedFilterPicker].sortType;
			
			if (searchController.active) [self searchBarCancelButtonClicked:searchController.searchBar];
			
			else [self refreshData];
		}
		
		[pickerSelectButton update];
        self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
	}
	
	// force the tableview to load
    else [theTableView reloadData];

	
	[FilterPicker sharedFilterPicker].delegate = self;
    //pickerSelectButton.controller = self;
    
    if (([Props global].deviceType == kiPad || [[Props global] inLandscapeMode]) && [Props global].sortable) [self createSortButtons];
    
    else if (![[Props global] inLandscapeMode] && [Props global].deviceType != kiPad) self.navigationItem.titleView = nil;
    
	//NSLog(@"Current device orientation = %i and view orientation = %i", [UIDevice currentDevice].orientation, self.interfaceOrientation);
	//NSLog(@"ETVC.viewWillAppear:done");
    
    [super viewWillAppear:animated];
}


- (void) viewDidAppear:(BOOL)animated {
    
    float tabBarHeight = [[Props global] inLandscapeMode] && [Props global].deviceType != kiPad ? kTabBarHeight - kPartialHideTabBarHeight : kTabBarHeight; 
    
    if(!searchController.active) self.theTableView.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - tabBarHeight - [Props global].titleBarHeight);
    
    NSLog(@"ETVC.viewDidAppear:Tableview frame height = %f, width = %f and resizing mask %@", self.theTableView.frame.size.height, self.theTableView.frame.size.width, self.theTableView.autoresizingMask == UIViewAutoresizingNone ? @"none" : @"some");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kHideLoadingView object:nil];
    
    
    if ([Props global].showAds && [self.view viewWithTag:kTutorViewTag] == nil && [self.view viewWithTag:kIntroAdTag] == nil && searchText == nil && !searchKeyboardShowing) {
        
        NSLog(@"ETVC.viewDidAppear: creating AdBannerView");
        [self createAdBannerView];
    }
    
    NSLog(@"ETVC.viewDidAppear done:Tableview frame height = %f, width = %f", self.theTableView.frame.size.height, self.theTableView.frame.size.width);
	
    [super viewDidAppear:animated];
}


-(void)viewWillDisappear:(BOOL)animated {

    NSLog(@"ETVC - viewWillDisappear");
    
	if (filterPickerShowing) [self hideFilterPicker:nil];
    if (settingsShowing) [self hideSettings];
	
	if([Props global].appID !=0 && [[self.navigationController.navigationBar subviews] containsObject:sutroButton]) [sutroButton removeFromSuperview];
	
	//Do this to hide popover and reset the search controller on iPad - not the best solution, but prevents worse issues at the moment
	if ([Props global].screenWidth == 768 && searchController.active) {
		[searchController setActive:NO animated:YES];
		searchController.searchBar.text = nil;
		searchText = nil;
	}
    
    UIView *tutorView = [self.view viewWithTag:kTutorViewTag];
    if (tutorView == nil) tutorView = [self.view viewWithTag:kIntroAdTag];
    if ([[self.view subviews] containsObject:tutorView]) [tutorView removeFromSuperview];
    
    //pickerSelectButton.controller = nil;
}


- (void) viewDidDisappear:(BOOL)animated {
    
    [self hideAdBannerWithAnimation:NO];
    
    //Hide search if we're going to another tab
    if (self.tabBarController.selectedIndex != 0 && searchController.active) {
        NSLog(@"ETVC.viewDidDisappear: hiding search bar when going to another view");
        [self searchBarCancelButtonClicked:searchBar];
    }
}


- (BOOL)prefersStatusBarHidden {
    
    return YES;
}



#pragma mark CREATE VIEWS AND BUTTONS


- (void) addLoadingOverlay {
	
	UIView *background = [[UIView alloc] initWithFrame:CGRectMake(0, -[Props global].titleBarHeight, [Props global].screenWidth, [Props global].screenHeight)];
	background.autoresizesSubviews = TRUE;
	background.tag = kBackgroundViewTag;
	background.backgroundColor = [UIColor blackColor];
	
	NSString *theFilePath= [NSString stringWithFormat:@"%@/Splash.jpg", [Props global].contentFolder];
	
	UIImage *image;
	
	if ([Props global].appID == 1 || ![[NSFileManager defaultManager] fileExistsAtPath:theFilePath])
		image = [Props global].deviceType == kiPad ? [UIImage imageNamed:@"Default-Portrait.png"] : [UIImage imageNamed:@"SutroWorld.png"];
		
	
	else 
		image = [UIImage imageWithContentsOfFile:theFilePath];
		
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	
	
	float width = [[Props global] inLandscapeMode] ? [Props global].screenHeight/image.size.height * image.size.width : [Props global].screenWidth;
	imageView.frame = CGRectMake(([Props global].screenWidth - width)/2, 0, width, [Props global].screenHeight);
	background.frame = CGRectMake(0, -[Props global].titleBarHeight, [Props global].screenWidth, [Props global].screenHeight);
	[background addSubview:imageView];
	[self.view addSubview:background];
}


- (void) hideLoadingOverlay {
	
	NSLog(@"ETVC.hideLoadingOverlay");
	
	UIView *overlay = [self.view viewWithTag:kBackgroundViewTag];
	
	
	[ UIView beginAnimations: nil context: nil ];
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
	[ UIView setAnimationDuration: 0.4 ];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(removeOverlay)];
	
	overlay.frame = CGRectMake([Props global].screenWidth/2, [Props global].screenHeight/2 - [Props global].titleBarHeight, 0, 0);
	overlay.alpha = 0.0;
	for (UIView *subview in [overlay subviews]) {
		subview.frame = CGRectMake(overlay.frame.size.width/2, overlay.frame.size.height/2, 0 ,0);
	}
	
	[UIView commitAnimations];
}


- (void) removeOverlay {[[self.view viewWithTag:kBackgroundViewTag] removeFromSuperview];}


- (void) doNothing: (id) sender {
	NSLog(@"Doing nothing (other than preventing tableview from getting accidentially hit)");
}


- (void) addReturnToAppButton {
	
	float viewTag = 90782345;
	
	[[self.view viewWithTag:viewTag] removeFromSuperview]; //remove old view in case method is being called after view rotation
	
	UIImage *theIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"Icon"] ofType:@"png"]];
	
	UIImage *roundedIcon = [ImageManipulator makeRoundCornerImage:theIcon :12 :12];
	
	float height = [Props global].titleBarHeight * 0.8;
	CGRect buttonFrame = CGRectMake(0, 3, height, height);
	UIButton *appButton = [UIButton buttonWithType: 0]; 
	appButton.frame = buttonFrame;
	
	[appButton setBackgroundColor: [UIColor clearColor]];
	[appButton setBackgroundImage:roundedIcon forState:normal];
	
	
	[appButton addTarget:self action:@selector(flipWorlds:) forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem *appBarButton = [[UIBarButtonItem alloc] initWithCustomView:appButton];
	
	self.navigationItem.rightBarButtonItem = appBarButton;
	
}


- (void) createSortButtons {
	
    NSLog(@"ETVC.createSortButtons");
	NSMutableArray *segmentTextContent = [NSMutableArray new];
	
    int i;
    
    for (i = 0; i < [FilterPicker sharedFilterPicker].sorterControl.numberOfSegments; i++) {
        [segmentTextContent addObject:[[FilterPicker sharedFilterPicker].sorterControl titleForSegmentAtIndex:i]];
    }
    
	if ([segmentTextContent count] > 1) {
		
        UISegmentedControl *sorterControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
        sorterControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        sorterControl.segmentedControlStyle = UISegmentedControlStyleBar;
        //sorterControl.frame = CGRectMake([Props global].leftMargin, 0, 280, [Props global].titleBarHeight * .7);
        [sorterControl addTarget:self action:@selector(toggleSortType:) forControlEvents:UIControlEventValueChanged];
        
		sorterControl.selectedSegmentIndex = [FilterPicker sharedFilterPicker].sorterControl.selectedSegmentIndex;
        if ([Props global].appID > 1) sorterControl.tintColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            
        sortCriteria = [sorterControl titleForSegmentAtIndex:sorterControl.selectedSegmentIndex];
        //NSLog(@"ETVC.createSortButtons: sortCriteria = %@, selected index = %i", sortCriteria, [FilterPicker sharedFilterPicker].sorterControl.selectedSegmentIndex);
        
        int i;
        int totalTitleLengths = 0;
        int longestTitle = 0;
        
        for (i = 0;i < sorterControl.numberOfSegments; i++) {
            NSString *title = [sorterControl titleForSegmentAtIndex:i];
            totalTitleLengths += [title length];
            if ([title length] > longestTitle) longestTitle = [title length];
            //NSLog(@"ETVC.createSortButtons: total title length = %i", totalTitleLengths);
        }
        
        //Balance sorter segment widths
        float sorterWidth = [Props global].deviceType == kiPad ? [Props global].screenWidth * .45 : 248;
       
        //float minSegmentWidth = [Props global].deviceType == kiPad ? 80 : 42;
        float minSegmentWidth = 20; //actual segment length of shortest one is longer than this
        
        if (totalTitleLengths != 0 && longestTitle > sorterWidth/35 /*number selected from trial and error - only want to balance when necessary*/ ) {
            
            for (i = 0;i <= sorterControl.numberOfSegments - 1; i++) {
                NSString *title = [sorterControl titleForSegmentAtIndex:i];
                float segmentWidth =  ((float)[title length]/totalTitleLengths) * (sorterWidth - minSegmentWidth * sorterControl.numberOfSegments) + minSegmentWidth;
                //float segmentWidth =  ((float)[title length]/totalTitleLengths) * sorterWidth;
                 //NSLog(@"ETVC.createSortButtons: Title = %@, width = %f", title, segmentWidth);
                [sorterControl setWidth:segmentWidth forSegmentAtIndex:i];
            }
        }
        
        sorterControl.selectedSegmentIndex = [FilterPicker sharedFilterPicker].sorterControl.selectedSegmentIndex;
        
		self.navigationItem.titleView = sorterControl;
        
       // NSLog(@"ETVC.createSortButtons: Sorter width = %f", self.navigationItem.titleView.frame.size.width);
        
        if ([Props global].hasLocations && ![FilterPicker sharedFilterPicker].showingDistanceSort) {
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createSortButtons) name:kDistanceSortAdded object:nil];
        }
        
	}	
    
    else NSLog(@"ERROR - ETVC.createSortButtons: sorter has no buttons***********************");
	
}


- (void) addGoHomeButton {
	
    //NSLog(@"ETVC.addGoHomeButton");
    
    UIBarButtonItem *appBarButton = [[UIBarButtonItem alloc] initWithTitle:@" My Guides " style:UIBarButtonItemStylePlain target:self action:@selector(goHome:)];
    
	self.navigationItem.rightBarButtonItem = appBarButton;
    
}


- (void) addRightSideToolbar {
    
    //Create view that holds the search and settings button
    float x_spacing = 15;
    
    UIView *buttonHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, [Props global].titleBarHeight)];
    buttonHolder.backgroundColor = [UIColor clearColor];
    
    NSString *selectorString = nil;
    
    if ([Props global].inTestAppMode) selectorString = @"flipWorlds:";
    else if (settingsShowing) selectorString = @"hideSettings";
    else selectorString = @"showSettings";
    
    //NSLog(@"ETVC.addRightSideToolbar: selector = %@", selectorString);
    
    if (settingsShowing) {
        UIBarButtonItem *hideButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:NSSelectorFromString(selectorString)];
        self.navigationItem.rightBarButtonItem = hideButton;
    }
    
    else if ([Props global].freemiumType != kFreemiumType_V1) {
        
        //***** Create search button *******
        UIImage *searchIcon = [UIImage imageNamed:@"search.png"];
        
        float height = [[Props global] inLandscapeMode] ? [Props global].titleBarHeight * .75 : [Props global].titleBarHeight * .55;
        CGRect buttonFrame = CGRectMake(0, 0, height, height); //set center later
        UIButton *searchButton = [UIButton buttonWithType: 0]; 
        searchButton.frame = buttonFrame;
        //searchButton.center = CGPointMake(buttonHolder.frame.size.width/4, buttonHolder.frame.size.height/2 + 1);
        searchButton.center = CGPointMake(searchButton.center.x, buttonHolder.frame.size.height/2 + 1);
        searchButton.alpha = 0.6;
        //[appButton setContentEdgeInsets:UIEdgeInsetsMake([Props global].titleBarHeight * .2, width - height, [Props global].titleBarHeight * .2, 0)];
        [searchButton setBackgroundColor: [UIColor clearColor]];
        [searchButton setBackgroundImage:searchIcon forState:normal];
        [searchButton addTarget:self action:@selector(search) forControlEvents:UIControlEventTouchUpInside];
        
        [buttonHolder addSubview:searchButton];
        buttonHolder.frame = CGRectMake(0, 0, CGRectGetMaxX(searchButton.frame), buttonHolder.frame.size.height);
        
        if ([Props global].appID > 1) {
            //**** Add the settings button ******
            UIImage *theIcon = [UIImage imageNamed:@"gear.png"];
            
            height = [[Props global] inLandscapeMode] ? [Props global].titleBarHeight * .75 : [Props global].titleBarHeight * .6;
            buttonFrame = CGRectMake(0, 0, height, height);
            UIButton *settingsButton = [UIButton buttonWithType: 0]; 
            settingsButton.frame = buttonFrame;
            //appButton.center = CGPointMake(buttonHolder.frame.size.width * .75, buttonHolder.frame.size.height/2);
            settingsButton.center = CGPointMake(settingsButton.center.x + CGRectGetMaxX(searchButton.frame) + x_spacing, buttonHolder.frame.size.height/2);
            settingsButton.alpha = 0.8;
            settingsButton.tag = kGearIconTag;
            [settingsButton setBackgroundColor: [UIColor clearColor]];
            [settingsButton setBackgroundImage:theIcon forState:normal];
            
            [settingsButton addTarget:self action:NSSelectorFromString(selectorString) forControlEvents:UIControlEventTouchUpInside];
            
            [buttonHolder addSubview:settingsButton];
            buttonHolder.frame = CGRectMake(0, 0, CGRectGetMaxX(settingsButton.frame), buttonHolder.frame.size.height);
        }
        
        //**** Add the go home button if we're in Sutro World *****
        if ([Props global].isShellApp) {
            UIImage *theIcon = [UIImage imageNamed:@"home.png"];
            
            float height = height = [[Props global] inLandscapeMode] ? [Props global].titleBarHeight * .75 : [Props global].titleBarHeight * .6;
            CGRect buttonFrame = CGRectMake(0, 0, theIcon.size.width * (height/theIcon.size.height), height);
            UIButton *homeButton = [UIButton buttonWithType: 0]; 
            homeButton.frame = buttonFrame;
            //homeButton.center = CGPointMake(buttonHolder.frame.size.width * .75, buttonHolder.frame.size.height/2);
            homeButton.center = CGPointMake(homeButton.center.x + CGRectGetMaxX(buttonHolder.frame) + x_spacing, buttonHolder.frame.size.height/2);
            homeButton.alpha = .8;
            [homeButton setBackgroundColor: [UIColor clearColor]];
            [homeButton setBackgroundImage:theIcon forState:normal];
            
            [homeButton addTarget:self action:@selector(goHome:) forControlEvents:UIControlEventTouchUpInside];
            
            [buttonHolder addSubview:homeButton];
            buttonHolder.frame = CGRectMake(0, 0, CGRectGetMaxX(homeButton.frame), buttonHolder.frame.size.height);
        }
        
        UIBarButtonItem *appBarButton = [[UIBarButtonItem alloc] initWithCustomView:buttonHolder];
        
        self.navigationItem.rightBarButtonItem = appBarButton;
    }
    
    else {
        
        if (upgradeButtonColor == nil) {
            
            upgradeButtonColorRef = [[NSUserDefaults standardUserDefaults] objectForKey:@"Upgrade button color"];
            
            NSArray *possibleColors = [NSArray arrayWithObjects:[UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:0.0], [UIColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:0.0], [UIColor colorWithRed:0.0 green:0.0 blue:0.6 alpha:0.0], [Props global].linkColor, [UIColor blackColor], nil];
            
            if ([upgradeButtonColorRef intValue] == 0) {
                NSArray *possibleTitles = [NSArray arrayWithObjects:[UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor grayColor], nil];
                
                int index = arc4random() % [possibleTitles count];
                
                upgradeButtonColorRef = [NSNumber numberWithInt:index];
                
                upgradeButtonColor = [possibleTitles objectAtIndex:index];
                
                NSLog(@"Upgrade button color = %@", upgradeButtonColor);
                
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:index] forKey:@"Upgrade button color"];
            }
            
            upgradeButtonColor = [possibleColors objectAtIndex:[upgradeButtonColorRef intValue]];
            
            NSLog(@"Upgrade button color = %@", upgradeButtonColor);
        }
        
        upgradeButtonView = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"✦ Upgrade ✦", nil]];
        upgradeButtonView.momentary = YES;
        upgradeButtonView.segmentedControlStyle = UISegmentedControlStyleBar;  //Doesn't work in iOS 7
        
        if ([Props global].osVersion >= 7.0) {
            
            UIColor *textColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.0 alpha:1.0];
            
            NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIFont boldSystemFontOfSize:17], UITextAttributeFont,
                                        textColor, UITextAttributeTextColor,
                                        nil];
            [upgradeButtonView setTitleTextAttributes:attributes forState:UIControlStateNormal];
            NSDictionary *highlightedAttributes = [NSDictionary dictionaryWithObject:[UIColor grayColor] forKey:UITextAttributeTextColor];
            [upgradeButtonView setTitleTextAttributes:highlightedAttributes forState:UIControlStateHighlighted];
        }
        
        
        //upgradeButtonView.backgroundColor = [UIColor redColor];
        upgradeButtonView.tintColor = upgradeButtonColor;
        [upgradeButtonView addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventValueChanged];
        
        //UIBarButtonItem *upgradeButton = [[UIBarButtonItem alloc] initWithTitle:@"✦ Upgrade ✦" style:UIBarButtonItemStylePlain target:self action:NSSelectorFromString(selectorString)];
        
        UIBarButtonItem *upgradeButton = [[UIBarButtonItem alloc] initWithCustomView:upgradeButtonView];
        upgradeButton.tintColor = [UIColor redColor];
        //upgradeButton.target = self;
        //upgradeButton.action = NSSelectorFromString(selectorString);
        self.navigationItem.rightBarButtonItem = upgradeButton;
        //[button release];
    }
}


- (void) animateGear {
    
    //NSLog(@"Getting message to animate gear");
    
    //if its not moving, start it moving
    if (!movingGear) {
        //NSLog(@"Gear isn't moving, so we'll start it");
        [self performSelectorOnMainThread:@selector(animateGearInMain) withObject:nil waitUntilDone:FALSE];
    }
    
    //if its moving, have it more again when it's done
    else shouldMoveGear = TRUE;

}

- (void) animateGearInMain {
    
    //NSLog(@"About to start gear animation");
    NSNumber *theFromValue = [NSNumber numberWithFloat:0];
	NSNumber *theToValue = [NSNumber numberWithFloat: 6.28318];
    
    UIView *gearView = [self.navigationController.navigationBar viewWithTag:kGearIconTag];
    
    if (gearView != nil) {
        movingGear = TRUE;
    }
    
	CABasicAnimation  *rotate;
	rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	rotate.fromValue = theFromValue; //[[dialView.layer presentationLayer] valueForKeyPath:@"transform.rotation.z"];
	rotate.toValue = theToValue;
	rotate.fillMode = kCAFillModeForwards;
	rotate.duration = 4;
	rotate.removedOnCompletion = YES;
	rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	rotate.delegate = self;
	
	[gearView.layer addAnimation: rotate forKey: @"someKey"];
}

- (void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    
    //NSLog(@"Animation did stop called");
    
    movingGear = FALSE;
    
    if (shouldMoveGear) {
	
        [self performSelectorOnMainThread:@selector(animateGearInMain) withObject:nil waitUntilDone:FALSE];
    }
    
    shouldMoveGear = FALSE;
}

/*
- (void) addUpgradeButtonWithSelector:(NSString*) selectorString {
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOfflineUpgradePurchased]) {
        [self addSettingsButtonWithSelector:@"showSettings"];
        return;
    }
    
    if ([Props global].inTestAppMode) selectorString = @"flipWorlds:";
    
    
    if (upgradeButtonTitle == nil) {
        
        upgradeButtonTitle = [[NSUserDefaults standardUserDefaults] objectForKey:kUpgradeButtonTitleKey];
        
        if ([upgradeButtonTitle length] == 0) {
            NSArray *possibleTitles = [NSArray arrayWithObjects:@"✦ Go Pro! ✦", @"✦ Upgrade ✦", @"✦ Go offline ✦", @"✦ Get it to go ✦", nil];
            
            int index = arc4random() % [possibleTitles count];
            
            NSLog(@"Index = %i", index);
            
            upgradeButtonTitle = [possibleTitles objectAtIndex:index];
            
            NSLog(@"Upgrade button title = %@", upgradeButtonTitle);
            
            [[NSUserDefaults standardUserDefaults] setObject:upgradeButtonTitle forKey:kUpgradeButtonTitleKey];
        }
    }
    
    
    UIBarButtonItem *upgradeButton = [[UIBarButtonItem alloc] initWithTitle:upgradeButtonTitle style:UIBarButtonItemStylePlain target:self action:NSSelectorFromString(selectorString)];
    self.navigationItem.rightBarButtonItem = upgradeButton;
    [upgradeButton release];
}


- (void) addSettingsButtonWithSelector:(NSString*) selectorString {
    
    NSLog(@"ETVC.addSettingsButtonWithSelector: %@", selectorString);
    
    if ([Props global].inTestAppMode) selectorString = @"flipWorlds:";
    
    UIImage *theIcon = [UIImage imageNamed:@"gear.png"];
	
	float height = [Props global].titleBarHeight * 0.8;
	CGRect buttonFrame = CGRectMake(0, 3, height, height);
	UIButton *appButton = [UIButton buttonWithType: 0]; 
	appButton.frame = buttonFrame;
	
	[appButton setBackgroundColor: [UIColor clearColor]];
	[appButton setBackgroundImage:theIcon forState:normal];
	
	[appButton addTarget:self action:NSSelectorFromString(selectorString) forControlEvents:UIControlEventTouchUpInside];
	
	//UIBarButtonItem *appBarButton = [[UIBarButtonItem alloc] initWithCustomView:appButton];
    UIBarButtonItem *appBarButton = [[UIBarButtonItem alloc] initWithImage:theIcon style:UIBarButtonItemStylePlain target:self action:NSSelectorFromString(selectorString)];
	
	self.navigationItem.rightBarButtonItem = appBarButton;
	
	[appBarButton release];	
}

*/
- (void) addEnterSutroButtonWithSelector:(NSString*) selectorString {
    
    NSLog(@"ETVC.addEnterSutroButtonWithSelector: %@", selectorString);
    
    if ([Props global].inTestAppMode) selectorString = @"flipWorlds:";
    
    UIImage *theIcon = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"sutroAd"] ofType:@"png"]];
	
	float height = [Props global].titleBarHeight * 0.8;
	CGRect buttonFrame = CGRectMake(0, 3, height, height);
	UIButton *appButton = [UIButton buttonWithType: 0]; 
	appButton.frame = buttonFrame;
	
	[appButton setBackgroundColor: [UIColor clearColor]];
	[appButton setBackgroundImage:theIcon forState:normal];
	
	
	[appButton addTarget:self action:NSSelectorFromString(selectorString) forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem *appBarButton = [[UIBarButtonItem alloc] initWithCustomView:appButton];
	
	self.navigationItem.rightBarButtonItem = appBarButton;
	
}


- (void) showUpgradePopup {
    
    float width = 280;
    float height = 350;
    
    UIView *upgradeView = [[UIView alloc] initWithFrame:CGRectMake(([Props global].screenWidth - width)/2, ([Props global].screenHeight - [Props global].titleBarHeight - kTabBarHeight - height)/2, width, height)];
    upgradeView.backgroundColor = [UIColor blackColor];
    upgradeView.alpha = .8;
    upgradeView.tag = kUpgradePopupTag;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, height/10, width, 20)];
    title.text = @"Welcome";
    title.textColor = [UIColor whiteColor];
    title.backgroundColor = [UIColor clearColor];
    title.font = [UIFont fontWithName:kFontName size:30];
    title.backgroundColor = [UIColor clearColor];
    title.textAlignment = UITextAlignmentCenter;
    [upgradeView addSubview:title];
    
    UIButton *upgradeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    float buttonWidth = width/3;
    float buttonHeight = 30;
    upgradeButton.frame = CGRectMake((width/2 - buttonWidth)/2, height - buttonHeight - 10, buttonWidth, buttonHeight);
    [upgradeButton setTitle:@"Upgrade" forState:UIControlEventAllEvents];
    [upgradeButton addTarget:self action:@selector(getOfflineUpgrade) forControlEvents:UIControlEventTouchUpInside];
    [upgradeView addSubview:upgradeButton];
    [self.view addSubview:upgradeView];
    
    
    UIButton *hideButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    //float buttonWidth = width/3;
    //float buttonHeight = 30;
    hideButton.frame = CGRectMake(width/2 + (width/2 - buttonWidth)/2, height - buttonHeight - 10, buttonWidth, buttonHeight);
    [hideButton setTitle:@"No thanks" forState:UIControlEventAllEvents];
    [hideButton addTarget:self action:@selector(hidePopup) forControlEvents:UIControlEventTouchUpInside];
    [upgradeView addSubview: hideButton];
    
    [self.view addSubview:upgradeView];
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


- (void) hideAdBannerWithAnimation:(BOOL) shouldAnimate {
    
    //self.theTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    
    if (self.adView != nil) {
                
        float animationDuration = shouldAnimate ? 0.2 : 0.001;
        
        [UIView beginAnimations:@"fixupAdView" context:nil]; 
        [ UIView setAnimationDuration: animationDuration ];
    
        CGRect adViewFrame = [self.adView frame];
        adViewFrame.origin.x = 0;
        adViewFrame.origin.y = [Props global].screenHeight; //set offscreen as there is no ad
        [self.adView setFrame:adViewFrame];
        
        float tabBarHeight = [[Props global] inLandscapeMode] && [Props global].deviceType != kiPad ? kTabBarHeight - kPartialHideTabBarHeight : kTabBarHeight; 
        
        self.theTableView.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - tabBarHeight - [Props global].titleBarHeight);
        
        NSLog(@"ETVC.hideAdBannerWithAnimation height = %f, width = %f", self.theTableView.frame.size.height, self.theTableView.frame.size.width);
       
        [UIView commitAnimations];
    }  
}

/* Idea:
 1. Set the current size of the expected ad based on orientation
 2. Animate the hiding or displaying of the ADBannerView if ad has arrived
 */
- (void)fixupAdViewWithAnimation:(BOOL) shouldAnimate {

    //self.theTableView.autoresizingMask = UIViewAutoresizingNone;
    
    if (self.adView != nil) {
        
        if ([[Props global] inLandscapeMode]) {
            self.adView.currentContentSizeIdentifier =ADBannerContentSizeIdentifierLandscape;
        } else {
            self.adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        }
        
        float animationDuration = shouldAnimate ? 0.2 : 0.001;
        float tabBarHeight = [[Props global] inLandscapeMode] && [Props global].deviceType != kiPad ? kTabBarHeight - kPartialHideTabBarHeight : kTabBarHeight; 
        
        [UIView beginAnimations:@"fixupAdView" context:nil]; 
        [ UIView setAnimationDuration: animationDuration ];
        if (adBannerIsVisible) {
            CGRect adViewFrame = [self.adView frame];
            adViewFrame.origin.x = 0;
            
            adViewFrame.origin.y = [Props global].screenHeight - tabBarHeight - [Props global].titleBarHeight - adViewFrame.size.height;
            
            self.theTableView.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - tabBarHeight - [Props global].titleBarHeight - adView.frame.size.height);
            
            NSLog(@"ETVC.fixupAdView height = %f, width = %f", self.theTableView.frame.size.height, self.theTableView.frame.size.width);
            
            [self.adView setFrame:adViewFrame];
            
        } else {
            
            self.theTableView.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - [Props global].titleBarHeight - tabBarHeight);
            NSLog(@"ETVC.fixupAdView2 height = %f, width = %f", self.theTableView.frame.size.height, self.theTableView.frame.size.width);
            CGRect adViewFrame = [self.adView frame];
            adViewFrame.origin.x = 0;
            adViewFrame.origin.y = [Props global].screenHeight; //set offscreen as there is no ad
            [self.adView setFrame:adViewFrame];
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

- (void)createAdBannerView {
    
    self.adView = nil;
    
    ADBannerView *anAdView = [[ADBannerView alloc] initWithFrame:CGRectZero];
    
    self.adView = anAdView;
    self.adView.tag = kAdViewTag;
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
    
    [[self.view viewWithTag:kAdViewTag] removeFromSuperview];
    [self.view addSubview:self.adView];
    NSLog(@"ETVC.createAdBannerView: created ad banner view and added as subview to ETVC");
}


#pragma mark BUTTON ACTION METHODS

- (void) search {
    
    NSLog(@"ETVC.search");
    
    if (filterPickerShowing) [self hideFilterPicker:nil];
    //
    //[self.navigationController.navi[self.view addSubview:searchBar];
    //[self.navigationController.navigationBar addSubview:searchBar];
    searchBar.hidden = FALSE;
    
    searchBar.center = CGPointMake([Props global].screenWidth/2, [Props global].titleBarHeight/2);
    
    //[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
    //[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
    //[ UIView setAnimationDuration: 0.8f ]; 
    
    searchBar.bounds = CGRectMake(0, 0, [Props global].screenWidth, [Props global].titleBarHeight);
    
    //[ UIView commitAnimations ];
    
    if ([Props global].showAds) adView.hidden = TRUE;
	
	/*coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
	coverView.alpha = .8;
	coverView.backgroundColor = [UIColor blackColor];
	[self.view addSubview:coverView];
	[coverView release];*/
    
    searchController.active = TRUE;
    searchKeyboardShowing = TRUE;
}


- (void) showFilterPicker: (id) sender {
    
    if (settingsShowing) [self hideSettings];
    
    UIView *coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
    coverView.backgroundColor = [UIColor blackColor];
    coverView.alpha = 0;
    coverView.tag = kCoverViewTag;
    coverView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:coverView];
    
    [ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
    [ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
    [ UIView setAnimationDuration: 0.8f ];
    [UIView setAnimationDelegate:self]; 
    [UIView setAnimationDidStopSelector:@selector(testCheck)];
    
    coverView.alpha = .8;
    NSLog(@"Coverview 1 = %@", coverView);
    
    [ UIView commitAnimations ];
	
	if(showingDistanceRow != TRUE && [Props global].hasLocations && [[LocationManager sharedLocationManager] getLatitude] !=kValueNotSet) {
		[[FilterPicker sharedFilterPicker] addDistanceButton];
    }
    
    if (self.navigationItem.titleView == nil)[[FilterPicker sharedFilterPicker] showSorterPicker];
    else [[FilterPicker sharedFilterPicker] hideSorterPicker];
	
	filterPickerShowing = TRUE;
	[self.view addSubview: [FilterPicker sharedFilterPicker]];
	[self.view bringSubviewToFront:[FilterPicker sharedFilterPicker]];
	[[FilterPicker sharedFilterPicker] showControls];
	
	lastFilterChoice = [[FilterPicker sharedFilterPicker] getPickerTitle];
	lastSortChoice = [FilterPicker sharedFilterPicker].sortType;
	
    NSLog(@"ETVC.showFilterPicker: picker select button = %@", pickerSelectButton);
    
	self.navigationItem.leftBarButtonItem = pickerSelectButton.cancelBarButton;
    
    NSLog(@"ETVC.showFilterPicker: picker select button 2 = %@", pickerSelectButton);
    
    UIView *tutorView = [self.view viewWithTag:kTutorViewTag];
    if (tutorView != nil) [tutorView removeFromSuperview];
    
    NSLog(@"ETVC.showFilterPicker: picker select button 3 = %@", pickerSelectButton);
}

- (void) testCheck {
     NSLog(@"ETVC.testCheck. Picker select button = %@ and self = %@", pickerSelectButton, self);
}


- (void) hideFilterPicker: (id) sender {
	
    NSLog(@"ETVC.hideFilterPicker. Picker select button = %@ and self = %@", pickerSelectButton, self);
	filterPickerShowing = FALSE;
	[[FilterPicker sharedFilterPicker] hideControls];
	
	filterCriteria = [[FilterPicker sharedFilterPicker] getPickerTitle];

	[pickerSelectButton update];
	self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
	
	if ([Props global].sortable && ![FilterPicker sharedFilterPicker].sorterHidden) sortCriteria = [FilterPicker sharedFilterPicker].sortType;
	
	if([filterCriteria isEqualToString:lastFilterChoice] == FALSE || sortCriteria != lastSortChoice) [self refreshData];
	
	//NSLog(@"Coverview = %@", coverView);
    for (UIView *view in [self.view subviews]) {
        if (view.tag == kCoverViewTag){
            [view removeFromSuperview];
        }
        
        else NSLog(@"Tag = %i", view.tag);
    }
    //[coverView removeFromSuperview];
    

	SMLog *log = [[SMLog alloc] initWithPageID: kTLLV actionID: kLVFilter];
	log.filter_id = [[FilterPicker sharedFilterPicker] getFilterID];
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
}


- (void)toggleSortType:(id)sender {
	
	UISegmentedControl *segControl = sender;
	
	sortCriteria = [segControl titleForSegmentAtIndex:segControl.selectedSegmentIndex];
    
    NSLog(@"ETVC.toggleSortType: sort criteria = %@", sortCriteria);
    
    [FilterPicker sharedFilterPicker].sorterControl.selectedSegmentIndex = segControl.selectedSegmentIndex;
	[FilterPicker sharedFilterPicker].sortType = sortCriteria;
    
    [self refreshData];
}


/*- (void) showUpgradeView {
    
    NSString *price = [[MyStoreObserver sharedMyStoreObserver] getUpgradePrice];
    
    [self addUpgradeButtonWithSelector:@"hideUpgradeView"];
    
    UIButton *cancelButton = [UIButton buttonWithType:0];
    cancelButton.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [cancelButton addTarget:self action:@selector(hideUpgradeView) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.frame = CGRectMake(0, 0,  [Props global].screenWidth, [Props global].screenHeight);
    cancelButton.backgroundColor = [UIColor blackColor];
    cancelButton.alpha = 0;
    cancelButton.tag = kBackgroundCancelButtonTag;
    [self.view addSubview:cancelButton];
    
    UIImage* background = [UIImage imageNamed:@"sutroPopUp_Background.png"];
    
    UIWebView *textView = [[UIWebView alloc] init];
    textView.opaque = NO;
    textView.delegate = self;
    textView.alpha = 0.0;
    textView.tag = kUpgradeAdTag;
    textView.frame = CGRectMake([Props global].screenWidth - 320, 0, 320, background.size.height * (320/background.size.width));  // CGRectMake([Props global].screenWidth * .8, 0, 0, 0);
    textView.backgroundColor = [UIColor clearColor];
    NSString *header = [NSString stringWithFormat:@"<html><head><title>Sutro Media</title>\
                        <style type=\"text/css\">\
                        a { color: %@; text-decoration: none; font-weight:1000; -webkit-tap-highlight-color:rgba(0,0,0,0);}\
                        body{\
                        padding:0;\
                        font-family:'Arial';\
                        font-size:%0.0fpx;\
                        padding:0;\
                        margin:34 20px 0px 20px;\
                        color:%@;\
                        background-image:url('sutroPopUp_Background.png');\
                        background-repeat:no-repeat;\
                        background-position: 0px 0px;\
                        }\
                        </style></head><body>\
                        <div id='pageContent'>\
                        ", [Props global].cssLinkColor, [Props global].bodyTextFontSize, [Props global].cssTextColor];
	
	NSString *body = [NSString stringWithFormat:@"You really really want to upgrade right?<br>\
    <br>\
    Do it now for <a href='http://placeholderURL'>%@</a>!", price];
	
	
	NSString *footer = @"</div></body></html>";
    
    NSString *htmlString = [NSString stringWithFormat:@"%@%@%@", header, body, footer];
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [[NSURL fileURLWithPath:path] retain];
    
    [textView loadHTMLString:htmlString baseURL:baseURL];
    [self.view addSubview:textView];
    
    
    //[self.view addSubview:sutroView];
    
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
    
	//sutroView.frame = CGRectMake(0, 0, [Props global].screenWidth, background.size.height * ([Props global].screenWidth/background.size.width));
    //textView.frame = CGRectMake(0, 0, 320, background.size.height * (320/background.size.width));    
    textView.alpha = 1.0;
    
    //sutroView.alpha = 1;
    cancelButton.alpha = 0.7;
    [UIView commitAnimations];
    
    [textView release];
    //[sutroView release];
}


- (void) hideUpgradeView {
    
    [self addUpgradeButtonWithSelector:nil];
    
    UIView *hideButton = [self.view viewWithTag:kBackgroundCancelButtonTag];
    [hideButton removeFromSuperview];
    
    
    UIView *upgradeView = [self.view viewWithTag:kUpgradeAdTag];
    
    float animationDuration = 0.3;
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:animationDuration];
    
	upgradeView.frame = CGRectMake([Props global].screenWidth * .8, 0, 0, 0);
    upgradeView.alpha = .1;
    
    [UIView commitAnimations];
    
    [self performSelector:@selector(removeUpgradeView:) withObject:upgradeView afterDelay:animationDuration];
}*/


- (void) showUpgrade {
    
    NSLog(@"ETVC.showUpgrade");
    //self.tabBarController.selectedViewController = self;
    [self.navigationController popToRootViewControllerAnimated:YES];
    self.tabBarController.selectedIndex = 0;
    [self showSettings];
}


- (void) showSettings {
    
    settingsShowing = TRUE;
    if (filterPickerShowing) [self hideFilterPicker:nil];
    
    [[self.view viewWithTag:kSettingsViewTag] removeFromSuperview];
    [[self.view viewWithTag:kSettingsViewButtonTag] removeFromSuperview];
    
    UIButton *cancelButton = [UIButton buttonWithType:0];
    cancelButton.backgroundColor = [UIColor blackColor];
    cancelButton.alpha = 0.0;
    cancelButton.frame = self.view.bounds;
    cancelButton.tag = kSettingsViewButtonTag;
    [cancelButton addTarget:self action:@selector(hideSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelButton];
    
    SettingsView *settings = [[SettingsView alloc] init];
    settings.tag = kSettingsViewTag;
    [self.view addSubview:settings];
    
    settings.frame = CGRectMake(settings.frame.origin.x, -settings.frame.size.height, settings.frame.size.width, settings.frame.size.height);
    settings.alpha = 0;
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.6];
    
    settings.frame = CGRectMake(settings.frame.origin.x, 0, settings.frame.size.width, settings.frame.size.height);
    settings.alpha = 1.0;
    cancelButton.alpha = 0.4;
    
    [UIView commitAnimations];
    
    
    [self addRightSideToolbar];
    
    if ([Props global].freemiumType == kFreemiumType_V1) {
        SMLog *log = [[SMLog alloc] initWithPageID: kTLLV actionID: kLVOfflineUpgradePressed ];
        //log.note = upgradeButtonTitle;
        [[ActivityLogger sharedActivityLogger] logPurchase:[log createLogString]];
    }
}


- (void) hideSettings {
    
    settingsShowing = FALSE;
    
    UIView *settings = [self.view viewWithTag:kSettingsViewTag];
    UIView *cancelButton = [self.view viewWithTag:kSettingsViewButtonTag];
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.6];
    
    settings.frame = CGRectMake(settings.frame.origin.x, -settings.frame.size.height, settings.frame.size.width, settings.frame.size.height);
    settings.alpha = 0.0;
    cancelButton.alpha = 0.0;
    
    [UIView commitAnimations];
    
    [self performSelector:@selector(removeSettings) withObject:nil afterDelay:0.6];
    //[self addSettingsButtonWithSelector:@"showSettings"];
    //self.navigationItem.rightBarButtonItem.enabled = FALSE;
    [self addRightSideToolbar];
}

- (void) removeSettings {
    
    [[self.view viewWithTag:kSettingsViewTag] removeFromSuperview];
    [[self.view viewWithTag:kSettingsViewButtonTag] removeFromSuperview];
}


/*- (void) showSutroAd {
    
    [self addEnterSutroButtonWithSelector:@"hideSutroAd"];
    
    UIButton *cancelButton = [UIButton buttonWithType:0];
    cancelButton.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [cancelButton addTarget:self action:@selector(hideSutroAd) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.frame = CGRectMake(0, 0,  [Props global].screenWidth, [Props global].screenHeight);
    cancelButton.backgroundColor = [UIColor blackColor];
    cancelButton.alpha = 0;
    cancelButton.tag = kSutroHideAdButtonTag;
    [self.view addSubview:cancelButton];
    
    UIImage* background = [UIImage imageNamed:@"sutroPopUp_Background.png"];
    //UIImageView *sutroView = [[UIImageView alloc] initWithImage:background];
     //sutroView.frame = CGRectMake([Props global].screenWidth * .8, 0, 0, 0);
     //sutroView.tag = kSutroAdTag;
     //sutroView.alpha = 0.1;
    
    UIWebView *textView = [[UIWebView alloc] init];
    //textView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    textView.opaque = NO;
    textView.delegate = self;
    textView.alpha = 0.0;
    textView.tag = kSutroAdTag;
    textView.frame = CGRectMake([Props global].screenWidth - 320, 0, 320, background.size.height * (320/background.size.width));  // CGRectMake([Props global].screenWidth * .8, 0, 0, 0);
    textView.backgroundColor = [UIColor clearColor];
    NSString *header = [NSString stringWithFormat:@"<html><head><title>Sutro Media</title>\
                        <style type=\"text/css\">\
                        a { color: %@; text-decoration: none; font-weight:1000; -webkit-tap-highlight-color:rgba(0,0,0,0);}\
                        body{\
                        padding:0;\
                        font-family:'Arial';\
                        font-size:%0.0fpx;\
                        padding:0;\
                        margin:34 20px 0px 20px;\
                        color:%@;\
                        background-image:url('sutroPopUp_Background.png');\
                        background-repeat:no-repeat;\
                        background-position: 0px 0px;\
                        }\
                        </style></head><body>\
                        <div id='pageContent'>\
                        ", [Props global].cssLinkColor, [Props global].bodyTextFontSize, [Props global].cssTextColor];
	
	NSString *body = @"Want to see all Sutro Media’s guides in one place?<br>\
    <br>\
    Get <a href='http://placeholderURL'>Sutro World</a> (it’s free!) and you can browse, sample, purchase, and use over 300 guides from one app!";
	
	
	NSString *footer = @"</div></body></html>";
    
    NSString *htmlString = [NSString stringWithFormat:@"%@%@%@", header, body, footer];
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [[NSURL fileURLWithPath:path] retain];
    
    [textView loadHTMLString:htmlString baseURL:baseURL];
    [self.view addSubview:textView];
    
    
    //[self.view addSubview:sutroView];
    
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
    
	//sutroView.frame = CGRectMake(0, 0, [Props global].screenWidth, background.size.height * ([Props global].screenWidth/background.size.width));
    //textView.frame = CGRectMake(0, 0, 320, background.size.height * (320/background.size.width));    
    textView.alpha = 1.0;
    
    //sutroView.alpha = 1;
    cancelButton.alpha = 0.7;
    [UIView commitAnimations];
    
    [textView release];
    //[sutroView release];
}*/


- (void) hideSutroAd {
    
    [self addEnterSutroButtonWithSelector:nil];
    
    UIView *hideButton = [self.view viewWithTag:kSutroHideAdButtonTag];
    [hideButton removeFromSuperview];
    
    
    UIView *sutroView = [self.view viewWithTag:kSutroAdTag];
    
    float animationDuration = 0.3;
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:animationDuration];
    
	sutroView.frame = CGRectMake([Props global].screenWidth * .8, 0, 0, 0);
    sutroView.alpha = .1;
    
    [UIView commitAnimations];
    
    [self performSelector:@selector(removeSutroView:) withObject:sutroView afterDelay:animationDuration];
}


-(void) removePickerFromView:(id) sender {[[FilterPicker sharedFilterPicker] removeFromSuperview];}


- (void) flipWorlds: (id) selector {
	
	NSLog(@"Time to flip worlds");
	
	self.view.userInteractionEnabled = NO;
	self.navigationController.view.userInteractionEnabled = NO;
    
	@autoreleasepool {
		if ([Props global].appID != 0 && ![Props global].inTestAppMode) {
			
			SMLog *log = [[SMLog alloc] initWithPageID: kTLLV actionID: kLVEnterSutroWorld ];
			[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
		}
		
		if ([Props global].appID != 0 && [Props global].inTestAppMode) {
			
			SMLog *log = [[SMLog alloc] initWithPageID: kTLLV actionID: kLVLeaveTestApp ];
			[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
		}
		
		/*else {
     
     SMLog *log = [[SMLog alloc] initWithPageID: kTLLV actionID: kLVLeaveSutroWorld ];
     [[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
     [log release];
     }*/
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kFlipWorlds object:nil];
	}
}


- (void) hidePopup {
    
    [[self.view viewWithTag:kUpgradePopupTag] removeFromSuperview];
}


- (void) goHome:(id) sender {
    
    if (theTableView != nil) { theTableView = nil;}
    //self.dataSource = nil;
    //self.searchCell = nil;
    self.currentEntry = nil;
    
    if (searchController != nil) {searchController.delegate = nil;  searchController = nil;}
    
    if (pickerSelectButton != nil) { pickerSelectButton = nil;}
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [Props global].killDataDownloader = TRUE;
    [self.homeController popToRootViewControllerAnimated:YES];
    self.homeController = nil;
}


#pragma mark
#pragma mark Helper Methods


- (void) goToEntry:(Entry*) theEntry {
    
    //goingToEntry = TRUE; //This is used to prevent the search controller from getting dismissed when going to an entry
    //self.tabBarController.view.frame = [[UIScreen mainScreen] bounds];
    self.tabBarController.view.frame = [Props global].isShellApp ? CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight) : [[UIScreen mainScreen] bounds];
    // create an LocationViewController
	LocationViewController *entryController = [[LocationViewController alloc] initWithController: self];
	
	// set the entry for the controller
	entryController.entry = theEntry;
	
	// push the entry view controller onto the navigation stack to display it
	[[self navigationController] pushViewController:entryController animated:YES];
	[entryController.view setNeedsDisplay];
	
	
	SMLog *log = [[SMLog alloc] initWithPageID: kTLLV actionID: kLVGoToEntry];
	log.entry_id = theEntry.entryid;
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
    

}


- (void) refreshData {
	
	NSLog(@"ETVC - Refresh data with filter criteria = %@, sort criteria = %@, search text = %@", filterCriteria, sortCriteria, searchText);
	
    [[EntryCollection sharedEntryCollection] filterDataTo:filterCriteria withSortCriteria: sortCriteria];
	//dataSource.controller = self;
	//self.theTableView.dataSource = dataSource;
    //self.theTableView.dataSource = self;
    
    if ([sortCriteria  isEqual: kSortByName]) {
        NSMutableArray *tmpIndex = [self createEntryFirstLetterIndex];
        self.entryFirstLetterIndex = tmpIndex;
    }
    
    openSectionIndex = NSNotFound;
    
    if (sortCriteria == [Props global].spatialCategoryName && !searchController.active){
        self.theTableView.sectionHeaderHeight = kHeaderHeight;
        //self.theTableView.separatorColor = [UIColor blackColor];
        //self.theTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    else self.theTableView.sectionHeaderHeight = 0;
    
	[self.theTableView reloadData];
    
    self.theTableView.contentOffset = CGPointMake(0, 0);
}


- (NSMutableArray*) createEntryFirstLetterIndex {
	
	//NSLog(@"Number of entries = %i, filter = %@, and total number of entries = %i", [self.sortedEntries count], filter, [self totalNumberOfEntries]);
	
	//This should get released through the assignment to the property variable
	NSMutableArray *tmpIndex = [NSMutableArray new];
	
	/*if (filterCriteria == nil || [filterCriteria isEqualToString:@"Everything"])*/ //[tmpIndex addObject:@"{search}"];
	
    FMDatabase * db = [EntryCollection sharedContentDatabase];
    
	@synchronized([Props global].dbSync) {
    
		FMResultSet * rs;
		
		if ([[Props global].defaultSort isEqualToString:@"month, day_of_month"])
			rs = [db executeQuery:@"SELECT SUBSTR(entries.name,0,3) AS first_letter from entries GROUP BY SUBSTR(entries.name,0,3) ORDER BY entries.month"];
		
		else if(filterCriteria == nil || [filterCriteria isEqualToString:@"Everything"]) rs = [db executeQuery:@"SELECT UPPER(SUBSTR(entries.name,0,1)) AS first_letter from entries GROUP BY UPPER(SUBSTR(entries.name,0,1))"];
		
		else rs = [db executeQuery:@"SELECT UPPER(SUBSTR(entries.name,0,1)) AS first_letter from entries,groups, entry_groups WHERE entries.rowid = entry_groups.entryid AND entry_groups.groupid = groups.rowid AND groups.name = ? group by UPPER(SUBSTR(entries.name,0,1))", filterCriteria];		
		if ([db hadError]) NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		
		while ([rs next]) [tmpIndex addObject:[rs stringForColumn:@"first_letter"]];
	}
	
	return tmpIndex;
}


- (void) removeUpgradeView: (UIView*) upgradeView {
    
    [self addUpgradeButtonWithSelector:@"showUpgradeView"];
    
    [upgradeView removeFromSuperview];
}


- (void) removeSutroView: (UIView*) sutroView {
    
    [self addEnterSutroButtonWithSelector:@"showSutroAd"];
    
    [sutroView removeFromSuperview];
}


/*- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        
        NSString *scheme = [request.URL scheme];
        
        if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
           
            [self getOfflineUpgrade];
            
            return FALSE;
        }
    }
    
    return TRUE;
}*/


- (void) getOfflineUpgrade {
    
    /*SMLog *log = [[SMLog alloc] initWithPageID: kInAppPurchase actionID: kPurchaseStart];
	[[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
	[log release];*/
    
    [[MyStoreObserver sharedMyStoreObserver] getOfflineContentUpgrade];
}



- (void) freemiumUpgradePurchased {
    
    NSLog(@"ETVC.freemiumUpgradePurchased");
    /*OfflineContentDownloadStatus *downloadStatus = [[OfflineContentDownloadStatus alloc] init];
    [self.view addSubview:downloadStatus];
    [downloadStatus release];*/
	
	[self removeMessage];
	
    if ([self.view viewWithTag:kUpgradePopupTag] != nil) {
        [self hidePopup];
    }
	
	[self showThankYou];
    
    [self addRightSideToolbar];
    
    [self hideAdBannerWithAnimation:YES];
    [self.adView removeFromSuperview];
    
    SMLog *log = [[SMLog alloc] initWithPageID: kTLLV actionID: kLVOfflineUpgradePurchased];
    //log.note = [NSString stringWithFormat:@"Upgrade color reference = %i", [upgradeButtonColorRef intValue]];
    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
}


- (void) showThankYou {
    
	@autoreleasepool {
    
    //[[self.view viewWithTag:kWaitingForAppStoreMessageTag] removeFromSuperview];
	
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
    
    [self performSelector:@selector(hideMessage) withObject:nil afterDelay:2.0];
    
	}
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
}



/*- (void) hideSearchRow {
	//NSLog(@"ETVC.hideSearchRow() called with %i entries in datasource", [dataSource numberOfEntries]);
	unsigned indexes[2] = {0,1};
	NSIndexPath *thePath = [[NSIndexPath alloc] initWithIndexes:indexes length:2];
	
	[self.theTableView reloadData];
	[self.theTableView scrollToRowAtIndexPath:thePath atScrollPosition:UITableViewScrollPositionTop animated:NO];
	[thePath release];
}*/


- (void) showTopRow {
	NSLog(@"ETVC.showTopRow() called");
	
	//[self.theTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    self.theTableView.contentOffset = CGPointMake(0, 0);
}


#pragma mark DELEGATE METHODS
-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
	
	if (buttonIndex != 0) {
		
		if (theAlert.tag == kUpgradeAlertTag) [self upgrade];
        
		else {
			
			SMLog *log = [[SMLog alloc] initWithPageID: kTLLV actionID: kLVSWDownload];
			[[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
			
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kSutroWorldURL]];
		}
    }
}


//For IOS 5 and below
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	//NSLog(@"ETVC.shouldAutorotateToInterfaceOrientation");
    
    if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        
        return YES;
    }
    
    else return NO;
}

//For iOS 6 and above
- (BOOL)shouldAutoRotate {
    
    return YES;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    if (toInterfaceOrientation != UIDeviceOrientationFaceUp && toInterfaceOrientation != UIDeviceOrientationFaceDown && toInterfaceOrientation != UIDeviceOrientationUnknown) {
        
        if ([Props global].showAds) [self hideAdBannerWithAnimation:NO];
        
        [[Props global] updateScreenDimensions: toInterfaceOrientation];
    }

    
    [self addRightSideToolbar];

	TutorView *tutorview = (TutorView*) [self.view viewWithTag:kTutorViewTag];
	
	if (tutorview != nil) {[tutorview hide]; [tutorview removeFromSuperview];} 
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
    
    if ([Props global].showAds && adBannerIsVisible) [self fixupAdViewWithAnimation:NO];
    
    //else self.theTableView.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
    
    
    if (([[Props global] inLandscapeMode] || [Props global].deviceType == kiPad) && [Props global].sortable) [self createSortButtons];
    
    else if (![[Props global] inLandscapeMode] && [Props global].deviceType != kiPad) self.navigationItem.titleView = nil;
    
    //else self.tabBarController.view.frame = CGRectMake( 0, 0, [Props global].screenWidth, [Props global].screenHeight);
    
    if (filterPickerShowing) [[FilterPicker sharedFilterPicker] viewWillRotate];
    
    [pickerSelectButton update];
    self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
    
    if (settingsShowing) [self showSettings]; // This is a rather ugly way to update the view size for settings appropriately
    
    CGRect frame = self.tabBarController.view.frame;
    NSLog(@"ETVC.didRotateFromInterfaceOrientation: frame coordinates = %f, %f, %f, %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
}


#pragma mark
#pragma mark SEARCH DELEGATE METHODS

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)theSearchText {
	
	//dataSource.controller = self;
	searchText = theSearchText;
	NSLog(@"ETVC.searchBar:textDidChange: searchText = %@", searchText);
}


- (void)searchBarTextDidBeginEditing:(UISearchBar *)_searchBar {
	
	//test code to fix the cancel button bug
	NSLog(@"ETVC - searchBarTextDidBeginEditing called");
	[_searchBar becomeFirstResponder];
	//[searchCell resignFirstResponder];
	//[_searchBar becomeFirstResponder];
	//[_searchBar setShowsCancelButton:YES animated:YES];
	//searchController.delegate = self;
	//_searchBar.delegate = self;
	NSLog(@"Search controller = %@", searchController);
	//**searchKeyboardShowing = TRUE;
    //**searchController.active = TRUE;
    //**[coverView removeFromSuperview];
    //[self performSelector:@selector(hideCoverView:) withObject:nil afterDelay:animationDuration];
	//dataSource.controller = self;
    
    /*if ([Props global].showAds) adView.hidden = TRUE;
	
	coverView = [[UIView alloc] initWithFrame:CGRectMake(0, kTitleBarHeight, [Props global].screenWidth, [Props global].screenHeight)];
	coverView.alpha = .8;
	coverView.backgroundColor = [UIColor blackColor];
	[self.view addSubview:coverView];
	[coverView release];*/
	
	//searchController.searchResultsDataSource = self;
	
}


- (BOOL)searchBarShouldEndEditing:(UISearchBar *)_searchBar {  
	
	if ([searchText length] == 0 && searchController.active) {
		NSLog(@"ETVC - searchBarShouldEndEditing: sending message to cancel search");
		[self searchBarCancelButtonClicked:_searchBar];
        return YES;
	}
    
    NSLog(@"ETVC.searchBarShouldEndEditing with search text length = %i", [searchText length]);
    
	return YES;  
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)_searchBar {
	
	NSLog(@"ETVC - Search button clicked with search Text = %@", searchText);
	searchKeyboardShowing = FALSE;
	//[searchCell resignFirstResponder];
	[_searchBar resignFirstResponder];
	
	SMLog *log = [[SMLog alloc] initWithPageID: kTLLV actionID: kLVSearch];
	log.note = searchText;
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)_searchBar {
	
	NSLog(@"ETVC - SearchBarCancelButtonClicked called");
	//[searchCell becomeFirstResponder];
    searchBar.hidden = TRUE;
	searchController.active = FALSE;
	searchText = nil;
    searchKeyboardShowing = FALSE;
	[self refreshData];
    
    if ([Props global].showAds) {
        adView.hidden = FALSE;
        [self fixupAdViewWithAnimation:NO];
    }
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	//dataSource.controller = self;
	[[EntryCollection sharedEntryCollection] updateDataWithSearchTerm:searchString withSortCriteria:sortCriteria];
	//dataSource.controller = self;
	NSLog(@"ETVC -  Should reload table for search string = %@ and sort = %@ called", searchString, sortCriteria);
	
    return YES;
}


- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {

	NSLog(@"ETVC.searchDisplayController:didLoadSearchResultsTableView:");
    NSLog(@"SDC - section header height = %f", tableView.sectionHeaderHeight);
    tableView.sectionHeaderHeight = 0;
}


- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
	
	NSLog(@"ETVC.searchDisplayController:willUnloadSearchResultsTableView:");
	//[tableView removeFromSuperview];
	//[tableView release];
	/*searchController.searchBar.showsCancelButton = YES;
	[searchController setActive:NO animated:YES];
	searchText = nil;
	searchController.searchBar.text = nil;
	[self refreshData];*/
	//[dataSource updateDataWithSearchTerm:@"" withSortCriteria:sortCriteria];
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	
	NSLog(@"ETVC - Should reload data for search scope getting called");
	return YES;
}


- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    
        NSLog(@"Will end");
        searchController.active = FALSE;
        searchBar.hidden = TRUE;
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
        NSLog(@"ETVC.bannerViewDidLoad: set adBannerVisible to TRUE and calling fixupAdView");
        if ([Props global].showAds) [self fixupAdViewWithAnimation:YES];
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
    NSLog(@"ETVC.bannerView:didFailToReceiveAdWithError: error: %@", [error localizedDescription]);
    if (adBannerIsVisible && [Props global].showAds) {
        adBannerIsVisible = FALSE;
        [self fixupAdViewWithAnimation:YES];
    }
}


- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    
    SMLog *log = [[SMLog alloc] initWithPageID: kTLLV actionID: kAdClicked];
    //log.entry_id = guideId;
    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
    
    return TRUE;
}

#pragma mark
#pragma mark Table view data source and delegate
// the user selected a row in the table.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//NSDate *time = [NSDate date];
	NSLog(@"ETVC - didSelectRowAtIndexPath called with row = %i", indexPath.row);
	
	rowToGoBackTo = indexPath;
	
	if(filterPickerShowing == TRUE)
		[self hideFilterPicker: nil];
	
	// get the entry that is represented by the selected row.
    
    //NSIndexPath *newPath;
    
    //if (sortCriteria == [Props global].spatialCategoryName || searchKeyboardShowing || searchText != nil || filterCriteria == kFavorites)newPath = indexPath; 
    
    //else newPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0];    
    
	self.currentEntry = [[EntryCollection sharedEntryCollection] entryForIndexPath:indexPath];
	
	if (searchKeyboardShowing) [self searchBarSearchButtonClicked:searchBar];
	
	if (currentEntry == nil){
		NSLog(@"ETVC - didSelectRowAtIndexPath - Returning");
		[tableView deselectRowAtIndexPath: indexPath animated:NO];
		return;
	}
	
	// deselect the new row using animation
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	[self goToEntry:currentEntry];	
	//NSLog(@"ETVC.didSelectRow: entry loaded in %0.3f seconds", -[time timeIntervalSinceNow]);
}


- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath*) indexPath {
	
	//NSLog(@"ENTRIESTABLEVIEWCONTROLLER.tableView:heightForRowAtIndexPAth: for %i, %i", indexPath.section, indexPath.row);
    
    //**if (indexPath.row == 0 && sortCriteria != [Props global].spatialCategoryName && !searchKeyboardShowing && filterCriteria != kFavorites) return kSearchBarHeight;
    
    //if (indexPath.row == 1 && sortCriteria != [Props global].spatialCategoryName && !searchKeyboardShowing && filterCriteria != kFavorites) return kSearchBarHeight;
    
    if (indexPath.row == 0 && sortCriteria != [Props global].spatialCategoryName && !searchController.active && ![filterCriteria  isEqual: kFavorites]){
        Entry *e = [[EntryCollection sharedEntryCollection].sortedEntries objectAtIndex:0];
        
        if (e.isBannerEntry) return self.theTableView.frame.size.height/3;
        
        else return [Props global].tableviewRowHeight;
    }
    
    else if (indexPath.row == [[EntryCollection sharedEntryCollection].sortedEntries count] && ![filterCriteria  isEqual: kFavorites] && filterCriteria != [Props global].spatialCategoryName) return 45;
    
    else return [Props global].tableviewRowHeight;
}


-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    
    //NSLog(@"Returning %i sections with sort criteria = %@", sortCriteria == [Props global].spatialCategoryName ? [[EntryCollection sharedEntryCollection].sortedEntries count] : 1, sortCriteria);
    
    return sortCriteria == [Props global].spatialCategoryName && !searchController.active ? [[EntryCollection sharedEntryCollection].sortedRegions count] : 1;
}


-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    
    /*if (sortCriteria == [Props global].spatialCategoryName) {
    
        SectionInfo *sectionInfo = [sectionInfoArray objectAtIndex:section];
        NSInteger numStoriesInSection = [[sectionInfo.region entries] count];
        
         NSLog(@"ETVC.numberOfRowsInSection. About to return %i", sectionInfo.open ? numStoriesInSection : 0);
        
        return sectionInfo.open ? numStoriesInSection : 0;
    }*/
    
    if (sortCriteria == [Props global].spatialCategoryName && !searchController.active) {
        
        Region *region = [[EntryCollection sharedEntryCollection].sortedRegions objectAtIndex:section];
        NSInteger numEntriesInSection = [[region entries] count];
        
        return region.open ? numEntriesInSection : 0;
    }
    
    else if ([filterCriteria  isEqual: kFavorites] || searchController.active) return [[EntryCollection sharedEntryCollection].sortedEntries count];
    
    else return [[EntryCollection sharedEntryCollection].sortedEntries count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //NSLog(@"Index path column = %i, row = %i", [indexPath indexAtPosition:0], indexPath.row);
    
    if (sortCriteria == [Props global].spatialCategoryName && !searchController.active) {
        
        EntryTableViewCell *cell = (EntryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:sortCriteria];
        if (cell == nil) cell = [[EntryTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sortCriteria]; //TF - 081610, addded autorelease - might create an issue
        
        int lastCell = 0;
        
        //Calling indexPathsForVisibleRows occassionally throws an exception, likely from the array being mutated as it's being called. Code below deals with this issue
        @try {
            
            NSIndexPath *lastVisibleCell = [[tableView indexPathsForVisibleRows] lastObject];
            lastCell = lastVisibleCell.row;
        }
        
        @catch (NSException *exception) {
            NSLog(@"We've got an exception");
        }
        //NSIndexPath *firstVisibleCell = [[tableView indexPathsForVisibleRows] objectAtIndex:0];
        //NSLog(@"Row for last visible cell = %i, current row = %i", lastVisibleCell.row, indexPath.row);
        int maxVisibleRows = tableView.frame.size.height/[Props global].tableviewRowHeight + 2;
        
        if (indexPath.row < lastCell + maxVisibleRows) {
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            //Adding the two background images adds .3 seconds to loading time for North America
            UIImageView *selectedImageView = [[UIImageView alloc] initWithImage:[Props global].LVBGView_selected];
            cell.selectedBackgroundView = selectedImageView;
            
            UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[Props global].LVBGView];
            //backgroundImageView.frame = CGRectMake(0,0, [Props global].screenWidth, 45);
            cell.backgroundView = backgroundImageView;
            
            Region *region = [[EntryCollection sharedEntryCollection].sortedRegions objectAtIndex:indexPath.section];
            
            Entry *theEntry = [region.entries objectAtIndex:indexPath.row];
            
            cell.entry = theEntry;
            
            return cell;
        }
        
        else return cell;
    }
    
    else {
        
        Entry *theEntry = [[EntryCollection sharedEntryCollection] entryForIndexPath:indexPath];
        //NSLog(@"Sort criteria = %@", sortCriteria);
        if (indexPath.row == 0 && !searchController.active && theEntry.isBannerEntry) {
                
            //Entry* theEntry = [EntryCollection entryById:71959];
            
            HeaderViewCell *cell = [[HeaderViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier: theEntry.name]; //TF - 081610, addded autorelease - might create an issue
            cell.entry = theEntry;
            
            return cell;
           
        }
        
        else {
            
            EntryTableViewCell *cell = (EntryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:sortCriteria];
            if (cell == nil) cell = [[EntryTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sortCriteria]; //TF - 081610, addded autorelease - might create an issue
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            UIImageView *selectedImageView = [[UIImageView alloc] initWithImage:[Props global].LVBGView_selected];
            cell.selectedBackgroundView = selectedImageView;
            
            UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[Props global].LVBGView];
            //backgroundImageView.frame = CGRectMake(0,0, [Props global].screenWidth, 45);
            cell.backgroundView = backgroundImageView;
                
            //theEntry = [[EntryCollection sharedEntryCollection] entryForIndexPath:indexPath];
            
            //NSLog(@"ETVC.cellForRow: Entry = %@", theEntry.name);
            //NSLog(@"Class of theEntry = %@", [theEntry class]);
            cell.entry = theEntry;
            
            return cell;
        }
    }
}


-(UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    
    //NSLog(@"ETVC.viewForHeaderInSection: sort = %@, section = %i", sortCriteria, section);
    
    if ([Props global].spatialCategoryName == sortCriteria) {
        Region *region = [[EntryCollection sharedEntryCollection].sortedRegions objectAtIndex:section];
       
        if (![region isKindOfClass:[Region class]]) {
            NSLog(@"ERROR: ENTRIESTABLEVIEWCONTROLLER.tableView:viewForHeaderInSection *******************");
            return nil;
        }
        
        //NSLog(@"Region title = %@ and class = %@", region.name, [Region class]);
        if (!region.headerView) {
            //NSString *title = [NSString stringWithFormat:@"%@ (%i)", region.name, [region.entries count]];
            region.headerView = [[SectionHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [Props global].screenWidth, kHeaderHeight) title:region.name number:[region.entries count] section:section delegate:self];
        }
        
        return region.headerView;
    }
	
    else return nil;
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	
	if (self.searchDisplayController.active || (![sortCriteria  isEqual: kSortByName] && sortCriteria != nil)) return nil;
	
	else return self.entryFirstLetterIndex;
}


- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	
	int i;
	
	if ([[Props global].defaultSort isEqualToString:@"month, day_of_month"]) {
		
		for (i = 0; i < [[EntryCollection sharedEntryCollection].sortedEntries count]; i++) {
			Entry *e = [[EntryCollection sharedEntryCollection].sortedEntries objectAtIndex:i];
			if ([[e.name substringToIndex:3] isEqualToString:title]) break;
		}
	}
	
	else {
		if ([title isEqualToString:@"{search}"]) i = 0;
		
		else {
			for (i = 0; i < [[EntryCollection sharedEntryCollection].sortedEntries count]; i++) {
				Entry *e = [[EntryCollection sharedEntryCollection].sortedEntries objectAtIndex:i];
				if ([[e.name substringToIndex:1] isEqualToString:title]) break;
			}
		}
	}
	
	// Just return to avoid a crash if the search index will be out of bounds
	if (i >= [[EntryCollection sharedEntryCollection].sortedEntries count] - 1) return 1;
	
	unsigned indexes[2] = {0,i};
	
	NSIndexPath *thePath = [[NSIndexPath alloc] initWithIndexes:indexes length:2];
	
	[tableView scrollToRowAtIndexPath:thePath atScrollPosition:UITableViewScrollPositionTop animated:YES];
	
	
	return 1;
}


#pragma mark Section header delegate

-(void)sectionHeaderView:(SectionHeaderView*)sectionHeaderView sectionOpened:(NSInteger)sectionOpened {
	
	NSLog(@"ETVC.sectionHeaderView:sectionOpened");
    
    NSDate *testTimer = [NSDate date];
        
    theTableView.userInteractionEnabled = NO;
    
    Region *region = [[EntryCollection sharedEntryCollection].sortedRegions objectAtIndex:sectionOpened];
	
    if ([region isMemberOfClass:[Region class]]) { //Sometimes, for reasons that I don't understand, and entry is return above. This causes a crash without this check
        
        region.headerView.userInteractionEnabled = NO;
        
        region.open = YES;
        
        SectionHeaderView *header = region.headerView;
        //[header.progressInd startAnimating];
        //header.progressInd.hidden = FALSE;
        //[header startWaitAnimation];
        [header.progressInd performSelectorInBackground:@selector(startAnimating) withObject:nil];
        //[header performSelectorInBackground:@selector(startWaitAnimation) withObject:nil];
        
        NSInteger countOfRowsToInsert = [region.entries count];
        NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
        //NSMutableArray *indexPathsToInsertLater = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToInsert; i++) {
            [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:sectionOpened]];
            //else [indexPathsToInsertLater addObject:[NSIndexPath indexPathForRow:i inSection:sectionOpened]];
        }
        
        
        NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
        
        NSInteger previousOpenSectionIndex = openSectionIndex;
        if (previousOpenSectionIndex != NSNotFound) {
            
            Region *previousOpenSection = [[EntryCollection sharedEntryCollection].sortedRegions objectAtIndex:previousOpenSectionIndex];
            previousOpenSection.open = NO;
            [previousOpenSection.headerView toggleOpenWithUserAction:NO];
            NSInteger countOfRowsToDelete = [previousOpenSection.entries count];
            for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
                [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:previousOpenSectionIndex]];
            }
        }
        
        // Style the animation so that there's a smooth flow in either direction.
        UITableViewRowAnimation insertAnimation;
        UITableViewRowAnimation deleteAnimation;
        if (previousOpenSectionIndex == NSNotFound || sectionOpened < previousOpenSectionIndex) {
            insertAnimation = UITableViewRowAnimationTop;
            deleteAnimation = UITableViewRowAnimationBottom;
        }
        else {
            insertAnimation = UITableViewRowAnimationBottom;
            deleteAnimation = UITableViewRowAnimationTop;
        }
        
        NSLog(@"Index paths to insert has %i objects and index paths to delete has %i paths", [indexPathsToInsert count], [indexPathsToDelete count]);
        
        // Apply the updates.
        [theTableView beginUpdates];
        [theTableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
        [theTableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:deleteAnimation];
        [theTableView endUpdates];
        openSectionIndex = sectionOpened;
        
        
        //[NSThread sleepForTimeInterval:2];
        //[header stopWaitAnimation];
        //header.progressInd.hidden = TRUE;
        [header.progressInd stopAnimating];
        region.headerView.userInteractionEnabled = YES;
        theTableView.userInteractionEnabled = YES;
        
         NSLog(@"ETVC.sectionHeaderView:sectionOpened: Done. Time = %0.2f", -[testTimer timeIntervalSinceNow]);
    }
}


-(void)sectionHeaderView:(SectionHeaderView*)sectionHeaderView sectionClosed:(NSInteger)sectionClosed {
    
     //Create an array of the index paths of the rows in the section that was closed, then delete those rows from the table view.
    /* 
	SectionInfo *sectionInfo = [sectionInfoArray objectAtIndex:sectionClosed];
	
    sectionInfo.open = NO;
     */
    
    Region *region = [[EntryCollection sharedEntryCollection].sortedRegions objectAtIndex:sectionClosed];
	
    region.open = NO;
    
    NSInteger countOfRowsToDelete = [theTableView numberOfRowsInSection:sectionClosed];
    
    if (countOfRowsToDelete > 0) {
        NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < countOfRowsToDelete; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:sectionClosed]];
        }
        [theTableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
    }
    openSectionIndex = NSNotFound;
}


#pragma mark -
#pragma mark Freemium Upgrade V2 Methods

- (void) showSampleAlertAsNecessary {
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"sample message shown"]) {
		
		if ([Props global].isFreeSample) {
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message: @"You can view any five entries from the sample content.\nEnjoy!" delegate: self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
			
			[alert show];
			
			NSLog(@"****************** NEED TO TURN ON RECORDING IF SAMPLE MESSAGE WAS SHOWN ******************************");
			//[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"sample message shown"];
		}
		
		else if ([Props global].freemiumType == kFreemiumType_V2) {
			
			NSString *freeSampleMessage = [NSString stringWithFormat:@"You can view any %i entries from this free sample version.\nEnjoy!", [Props global].freemiumNumberofSampleEntriesAllowed];
			
			NSString *upgradePrice = [[MyStoreObserver sharedMyStoreObserver] getUpgradePrice];
			
			NSString *upgradeButtonTitle = upgradePrice == nil ? @"Upgrade" : [NSString stringWithFormat:@"Upgrade - %@", upgradePrice];
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Welcome!" message: freeSampleMessage delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:upgradeButtonTitle, nil];
			alert.tag = kUpgradeAlertTag;
			
			[alert show];
			
			[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"ListViewTutorialShown"];
		}
	}
}


- (void) upgrade {
    
    NSLog(@"ETVC.upgrade");
	
	if ([Props global].isShellApp) [[MyStoreObserver sharedMyStoreObserver] upgradeSamplePurchaseForGuideId:[Props global].appID];
	
	else {
		[self showMessage:@"Waiting for App Store..."];
		
		[[MyStoreObserver sharedMyStoreObserver] getOfflineContentUpgrade];
	}
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
		
		[self.view setNeedsLayout];
	}
}


@end
