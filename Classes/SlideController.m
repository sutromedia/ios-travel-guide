

#import "SlideController.h"
#import "ImageView.h"
#import "Constants.h"
#import "Entry.h"
#import "ActivityLogger.h"
#include <stdlib.h>
#import "FilterPicker.h"
#import	"LocationViewController.h"
#import "EntryCollection.h"
#import "Props.h"
#import "SMLog.h"
#import	"SMRichTextViewer.h"
#import "WebViewController.h"
#import "EntriesAppDelegate.h"
//#import "DownloadStatus.h"
#import "FilterButton.h"
#import "UpgradePitch.h"


#define kSlideshowInterval				2.5 //interval between slide changes
#define kThumbnailBarButtonWidth		90


@interface SlideController (PrivateMethods)

- (void) initVariables;
- (void) showSingleImageView: (id) sender;
- (void) showThumbnailView;
- (void) refreshData;
- (void) createFilterPicker;
- (void) startSlideshow;
- (void) fadeInControls:(id)theTimer;
- (void) fadeOutControls:(id)theTimer;
- (void) addTitleLabel;
- (void)scrollViewDidScroll:(UIScrollView *)sender;
//- (void) createDownloadStatusDisplay;
- (void) hideTopAndBottomBarsWithAnimation:(BOOL) animated;
- (void) showTopAndBottomBars;
- (void) reset;
- (void) showLoopIndicator;
- (int) getPageNumberForIndex:(int) theIndex;
- (void) hideFilterPicker: (id) sender;
- (void) updateImageArray: (id) sender;
- (void) setUpThumbnails:(id)sender;
- (void) addUpgradePitch;
- (void) sharePic: (id) sender;
- (void) removeUpgradePitch;
- (NSString*) createPhotoQuery;


@end

@implementation SlideController

@synthesize /*dataSource,*/ pickerSelectButton, imageArray, filterCriteria, lastFilterChoice, playing, touchTimer, firstImageIndex, showingThumbnails, roughNumberOfThumbnailsPerPage, showSlideshowUpgradePitch;


@synthesize entry;

# pragma mark Initializaztion code

- (id) init  {
    self = [super init];
	if (self) {
		
		[self initVariables];
		
		self.tabBarItem.image = [UIImage imageNamed: @"slideshow.png"];;
		self.title = @"Photos";
		self.hidesBottomBarWhenPushed = FALSE;
		self.navigationItem.title = nil;
		
		self.entry			= nil;
	
		thumbnailRowWidth	= 2;
		thumbnailRowHeight	= 1.57;
		
		filterPickerShowing = FALSE;
		resetingContentSize = FALSE;
		NSLog(@"SLIDECONTROLLER.initWithDataSource: device %@ show thumbnails", deviceCanShowThumbnails ? @"can" : @"can not");
		showingThumbnails	= ([Props global].deviceType == kiPad && deviceCanShowThumbnails) ? TRUE : FALSE;
        thumbnailViewEnabled = deviceCanShowThumbnails;
		settingUpSlideshow	= FALSE;
        self.roughNumberOfThumbnailsPerPage = 0;
		
		//create a custom back button image
		UIImage *backImage = [UIImage imageNamed:@"backToSlideshow.png"];
		UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backImage style: UIBarButtonItemStylePlain target:nil action:nil];
		
		self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
				
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name: kOrientationChange object:nil];
         
         if([Props global].filters != nil) {
             pickerSelectButton = [[FilterButton alloc] initWithController:self];
             
             self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
         }
        
		NSLog(@"SLIDECONTROLLER.initWithDataSource: done");
    }
	
	return self;
}


- (id) initWithEntry:(Entry *)theEntry  {
	
	NSLog(@"SLIDECONTROLLER.initWithEntry");
	
    self = [super init];
	if (self) {
		//set the variables not being used for entry level slideshow to nil to make sure they don't get released later.
		
		[self initVariables];
		
		self.entry = theEntry;
		self.showingThumbnails = FALSE;
		self.imageArray = [entry createImageArray];
        self.showSlideshowUpgradePitch = [Props global].freemiumType == kFreemiumType_V1 && [Props global].firstVersion > 27317 && [self.imageArray count] > 2;        thumbnailViewEnabled = !self.showSlideshowUpgradePitch && deviceCanShowThumbnails;
        
        NSLog(@"SLIDECONTROLLER.initWithEntry: %i photos in image array", [imageArray count]);
		
		[self addTitleLabel];
		//if (![[NSUserDefaults standardUserDefaults] boolForKey:kDownloadStatusHidden] && [Props global].appID > 1)[self createDownloadStatusDisplay];
		[self showSingleImageView:nil];
	}
	
	return self;
}


- (void) initVariables {

	pickerSelectButton	= nil;
	cancelButton		= nil;
    rotationOverlay     = nil;
	
	//downloadStatus		= nil;
	self.imageArray		= nil;
	scrollView			= nil;
	
	previousSlide		= nil;
	currentSlide		= nil;
	nextSlide			= nil;
	
	hideBarsTimer		= nil;
	fadeControlsTimer	= nil;
	//hideControlsTimer	= nil;
	slideShowTimer		= nil;
	touchTimer			= nil;
	
	currentPage			= 0;
	thumbnailRowWidth	= 0;
	thumbnailRowHeight	= 0;
	maxImageIndex		= 0;
	tmpCounter			= 0;
	
	userControllingMotion	= TRUE;
	viewDidJustAppear		= TRUE;
	filterPickerShowing		= FALSE;
	self.playing			= TRUE;
	visible					= FALSE;
	
	NSMutableArray *tempImageIndex = [NSMutableArray new];
	self.firstImageIndex = tempImageIndex;
	[firstImageIndex addObject:[NSNumber numberWithInt:0]];
	
	self.view.backgroundColor = [UIColor blackColor];
    
    deviceCanShowThumbnails = ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported && [Props global].osVersion > 3.9);
}


- (void)dealloc {
	NSLog(@"SLIDECONTROLLER.dealloc *************************************");
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	//Release all global variables
	if (scrollView != nil)			{			scrollView = nil;}
	if (previousSlide != nil)		{		previousSlide = nil;}
	if (currentSlide != nil)		{		currentSlide = nil;}
	if (nextSlide != nil)			{			nextSlide = nil;}
	if (updateArray != nil)			{			updateArray = nil;}
	//if (downloadStatus != nil)		{[downloadStatus release];		downloadStatus = nil; NSLog(@"SLIDECONTROLLER.dealloc: just released download status. retain count = %i", [downloadStatus retainCount]);}
    //else NSLog(@"DownloadStatus is nil!");
	if (slideModeControl != nil)	{	slideModeControl = nil;}
    if (rotationOverlay != nil)     {     rotationOverlay = nil;}
	
	//Invalidate all current timers
	if (slideShowTimer != nil && [slideShowTimer isValid])		{[slideShowTimer invalidate]; slideShowTimer = nil;}
	if (fadeControlsTimer !=nil && [fadeControlsTimer isValid])	{[fadeControlsTimer invalidate]; fadeControlsTimer = nil;}
	if (hideBarsTimer != nil && [hideBarsTimer isValid])		{[hideBarsTimer invalidate]; hideBarsTimer = nil;}
	if (updateTimer != nil && [updateTimer isValid])			{[updateTimer invalidate]; updateTimer = nil;}
	if (touchTimer != nil && [touchTimer isValid])				{[touchTimer invalidate]; }
	
	// set all values defined as properties to nil. May be redundant, but can't hurt.
	//self.dataSource = nil;
}


- (void)loadView {
	
	//NSLog(@"SLIDECONTROLLER.loadView: RC = %i", [self retainCount]);

	UIView *contentView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	contentView.backgroundColor = [UIColor blackColor];
	self.view = contentView;
	
	self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	self.view.autoresizesSubviews = YES;
	
	//Set up slide mode button
	NSString *rightButton = (showingThumbnails) ? @"singleImageButton.png" : @"thumbnailButton.png";
	
	//this variable is also defined in it, but needs to also be defined here, as loadView sometimes gets called before init
	deviceCanShowThumbnails = ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported && [Props global].osVersion > 3.9);

    NSArray *segmentTextContent = deviceCanShowThumbnails ? [NSArray arrayWithObjects: [UIImage imageNamed:@"playButton.png"], [UIImage imageNamed:@"share_active.png"], [UIImage imageNamed:rightButton],nil] : [NSArray arrayWithObjects:[UIImage imageNamed:@"playButton.png"], [UIImage imageNamed:@"share_active.png"], nil];
	
	slideModeControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	slideModeControl.momentary = TRUE;
	slideModeControl.segmentedControlStyle = UISegmentedControlStyleBar;
	
    float width = [Props global].osVersion >= 7 && [Props global].deviceType != kiPad ? 40 : 60;
	int i;
    for (i = 0; i <= slideModeControl.numberOfSegments - 1; i++) [slideModeControl setWidth:width forSegmentAtIndex:i];
    
	[slideModeControl addTarget: self action:@selector(toggleSlideControls:) forControlEvents:UIControlEventValueChanged];
	slideModeControl.tintColor = [UIColor blackColor];
	
	UIBarButtonItem *tmpBarButton = [[UIBarButtonItem alloc] initWithCustomView:slideModeControl];
    self.navigationItem.rightBarButtonItem = tmpBarButton;
    
    updateArray = [NSMutableArray new];
}


- (void) viewWillAppear:(BOOL)animated {
	
	NSLog(@"SLIDECONTROLLER.viewWillAppear: called");
	
	visible = TRUE;
	
	for (UIView *subview in [self.navigationController.navigationBar subviews]) {
		if (subview.tag > 0) {
			[subview removeFromSuperview];
			NSLog(@"Removing old views from nav controller");
		}
	}
	
    if ([Props global].deviceType != kiPad && self.entry == nil) {
        if ([[Props global] inLandscapeMode] && [Props global].osVersion > 3.1){
            
            //original version for regular app
            float xPos =  [[UIDevice currentDevice] orientation]==UIDeviceOrientationLandscapeLeft ? -kPartialHideTabBarHeight : 0;
            if(![Props global].isShellApp) self.tabBarController.view.frame = CGRectMake( xPos,0, [Props global].screenHeight + kPartialHideTabBarHeight, [Props global].screenWidth);
            
            //update for SW - WHY????
            else self.tabBarController.view.frame = CGRectMake( 0,0, [Props global].screenWidth, [Props global].screenHeight + kPartialHideTabBarHeight);
        }
        
        else self.tabBarController.view.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
	}
	
	self.navigationController.navigationBar.tintColor = [Props global].osVersion >= 7.0 ? [UIColor grayColor] : [UIColor blackColor];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	self.navigationController.navigationBar.translucent = TRUE;
    self.navigationController.toolbarHidden = TRUE;
    
	slideModeControl.tintColor = [Props global].osVersion >= 7.0 ? [UIColor grayColor] : [UIColor blackColor]; //necessary to fix weird bug in SutroWorld where this button turns blue after going to entry
	
	//if (downloadStatus != nil) [downloadStatus setActive];
	
	viewDidJustAppear = TRUE;
	viewDidJustAppear2 = TRUE;
	
	//If it's a top level slideshow...
	if(entry == nil){
		
		//[[SMRichTextViewer sharedCopy] reset];
		[[FilterPicker sharedFilterPicker] hideSorterPicker];
		

		if([Props global].filters != nil) {
			//Set view to show all if the filter is set to favorites and the last favorite was removed
			if(([[EntryCollection sharedEntryCollection] favoritesExist] == FALSE) && [filterCriteria  isEqual: kFavorites]){
				filterCriteria =  nil; //kFilterAll;
				[self refreshData];
				[[FilterPicker sharedFilterPicker].theFilterPicker selectRow:0 inComponent:0 animated: NO];
			}
			
            NSLog(@"SC: Filter criteria = %@ and button title = %@, other button title = %@", filterCriteria, pickerSelectButton.selectBarButton.title, self.navigationItem.leftBarButtonItem.title);
            [pickerSelectButton update];
            self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
            
            NSLog(@"SC: Filter criteria = %@ and button title = %@, other button title = %@", filterCriteria, pickerSelectButton.selectBarButton.title, self.navigationItem.leftBarButtonItem.title);
			//update view if the filter was changed in another view
			if(![filterCriteria isEqualToString:[[FilterPicker sharedFilterPicker] getPickerTitle]]){
				filterCriteria = [[FilterPicker sharedFilterPicker] getPickerTitle];
				[self refreshData];
			}
			
			//remove favorites as necessary if they are showing and one was removed in another view
			if ([[EntryCollection sharedEntryCollection] favoritesExist] && [[[FilterPicker sharedFilterPicker] getPickerTitle]  isEqual: kFavorites]) {
				NSMutableArray *theFavorites = [[NSMutableArray alloc] initWithArray: [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]]];
				
				if ([theFavorites count] != [[EntryCollection sharedEntryCollection].sortedEntries count] ) {
					NSLog(@"SLIDECONTROLLER.viewWillAppear: updating entry collection after entry was removed from favorites");
					[self refreshData];
				}
				
			}
			
			[pickerSelectButton update];
		}
        
        if (imageArray == nil) [self refreshData];
			
		SMLog *log = [[SMLog alloc] initWithPageID: kTLSS actionID: kSSViewSelected];
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}	
		
	// Workaround to deal with imageviews getting purged from memory sometimes
	if ([[self.view subviews] containsObject:scrollView] != TRUE) [self.view addSubview:scrollView];
	
    //**[pickerSelectButton resize];
    
	[FilterPicker sharedFilterPicker].delegate = self;
    
    [super viewWillAppear:animated];
}


- (void) viewDidAppear:(BOOL)animated {
	
	//[thumbnails.theTableView beginUpdates];
	//[thumbnails.theTableView endUpdates];
	
	[self fadeInControls:nil];
	if(currentSlide != nil && !showingThumbnails){
		if (hideBarsTimer != nil && [hideBarsTimer isValid]){
			[hideBarsTimer invalidate];
			hideBarsTimer = nil;
		}
			 
		hideBarsTimer = [NSTimer scheduledTimerWithTimeInterval: 0.8 target:self selector:@selector(hideTopAndBottomBarsWithAnimation:) userInfo:nil repeats:NO];
	}
			 
	else if (currentSlide != nil && showingThumbnails) [self hideTopAndBottomBarsWithAnimation:YES];
	
	if(!showingThumbnails && playing && [imageArray count] > 1 && currentSlide != nil && nextSlide != nil) [self startSlideshow];
    
    if (nextSlide != nil) nextSlide.hidden = FALSE;
    if (previousSlide != nil)  previousSlide.hidden = FALSE;
}


- (void) viewDidDisappear:(BOOL) animated {
    
    visible = FALSE;
    
	[self pauseSlideshow];
	
	//if (downloadStatus != nil) [downloadStatus setInactive];
	
	if (fadeControlsTimer != nil && [fadeControlsTimer isValid]) {
		[fadeControlsTimer invalidate];
		fadeControlsTimer = nil;
	}
	
	if (hideBarsTimer != nil && [hideBarsTimer isValid]){
		[hideBarsTimer invalidate];
		hideBarsTimer = nil;
	}
    
    if (filterPickerShowing)[self hideFilterPicker:nil];
    
    UIView *offlineUpgradeView = [self.view viewWithTag:kOfflineUpgradePitchTag];
    if (offlineUpgradeView != nil && offlineUpgradeView.frame.size.height == 0) upgradePitchHidden = TRUE;
    [offlineUpgradeView removeFromSuperview];
}


- (void) toggleSlideControls: (id) sender {

	UISegmentedControl *segControl = sender;
	
	switch (segControl.selectedSegmentIndex) {
			
		case 0:	{ 
		
			NSLog(@"Time to show slideshow");
			if (playing) [self pauseSlideshow];
							
			else if ([imageArray count] > 1)[self startSlideshow];
				
			break;
		}
			
		case 1 : {
            
            NSLog(@"Time to switch between slideshow and thumbnail view");
			if (showingThumbnails)[self showSingleImageView:nil];
			
			else if (thumbnailViewEnabled) [self showThumbnailView];
            
			break;
		}
        
        case 2 : {
            
            if (!showingThumbnails) [self sharePic:nil];
            
            break;
        }
	}		
}


- (BOOL)prefersStatusBarHidden {
    
    return YES;
}


- (void) reset {

    NSLog(@"Slide mode control number of segments - %i", slideModeControl.numberOfSegments);
	
    if (slideModeControl.numberOfSegments > 2) {
		
		if (showingThumbnails) {
            [slideModeControl setImage:[UIImage imageNamed:@"singleImageButton.png"] forSegmentAtIndex:1];
            [slideModeControl setImage:[UIImage imageNamed:@"share_inactive.png"] forSegmentAtIndex:2];
        }
		
		else {
			if (thumbnailViewEnabled) [slideModeControl setImage:[UIImage imageNamed:@"thumbnailButton.png"] forSegmentAtIndex:1];
			else [slideModeControl setImage:[UIImage imageNamed:@"thumbnailButton_deactivated.png"] forSegmentAtIndex:1];
            
            [slideModeControl setImage:[UIImage imageNamed:@"share_active.png"] forSegmentAtIndex:2];
		}
	}
	
	if (slideShowTimer != nil)		[slideShowTimer invalidate];
	slideShowTimer = nil;
	
	if (fadeControlsTimer !=nil) [fadeControlsTimer invalidate];
	fadeControlsTimer = nil;
	
	if(scrollView != nil){
		[scrollView removeFromSuperview];
		scrollView.delegate = nil;
		scrollView = nil;
	}
	
	
	previousSlide	= nil;
	currentSlide	= nil;
	nextSlide		= nil;
	
	scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];

	scrollView.pagingEnabled = YES;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.showsVerticalScrollIndicator = NO;
	//scrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	scrollView.scrollsToTop = NO;
	scrollView.decelerationRate = 20.0; //a higher number results in a slower deceleration.
	scrollView.delegate = self;
	scrollView.backgroundColor = [UIColor blackColor];
    
    if ([Props global].osVersion < 3.2) {
        scrollView.bounces = YES;
        scrollView.directionalLockEnabled = YES;
        scrollView.alwaysBounceVertical = NO;
        scrollView.alwaysBounceHorizontal = NO;
    }
	
    else scrollView.bounces = NO;
    
    //For some strange reason, the lines below cause the app to not do paging on 3.1.3
    //scrollView.bounces = NO;
	//scrollView.alwaysBounceHorizontal = YES;
	scrollView.scrollEnabled = FALSE;
	
	if (self.entry == nil && [FilterPicker sharedFilterPicker] != nil) [self.view insertSubview:scrollView belowSubview:[FilterPicker sharedFilterPicker]];
	else [self.view addSubview:scrollView];
}


- (void) showSingleImageView: (id) sender {
	
	showingThumbnails = FALSE;
	
	UIButton *button = (UIButton*) sender;
	
	//Page numbers start at zero
	int pageNumber = (button.tag == 0) ? currentSlide.firstImageIndex: [imageArray indexOfObject:[NSNumber numberWithInt:button.tag]];
	
	/*UIGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didZoom:)];
	 [scrollView addGestureRecognizer:pinchRecognizer];
	 pinchRecognizer.delegate = self;*/
	[self reset];
    
    if ([Props global].freemiumType == kFreemiumType_V1 && self.entry != nil && [self.imageArray count] > 2) scrollView.contentSize = CGSizeMake([Props global].screenWidth * 3, [Props global].screenHeight);
	
    else scrollView.contentSize = CGSizeMake([Props global].screenWidth * 10000, [Props global].screenHeight);
	scrollView.contentOffset = CGPointMake([Props global].screenWidth * pageNumber, 0);
	
	
	if (pageNumber > 0) {
		previousSlide = [[ImageView alloc] initWithPageNumber:pageNumber - 1 andController:self];
		[scrollView insertSubview:previousSlide atIndex:0];	
	}
	
	currentSlide = [[ImageView alloc] initWithPageNumber:pageNumber andController:self];
	[scrollView insertSubview:currentSlide atIndex:0];	
	//[currentSlide release];
	
	nextSlide = [[ImageView alloc] initWithPageNumber:pageNumber + 1 andController:self];
	[scrollView insertSubview:nextSlide atIndex:0];	
	//[nextSlide release];
	
	if (nextSlide == nil && previousSlide == nil) {
		scrollView.contentSize = CGSizeMake([Props global].screenWidth, [Props global].screenHeight);
		[slideModeControl setImage:[UIImage imageNamed:@"playButton_inactive.png"] forSegmentAtIndex:0];
	}	
	
	else [slideModeControl setImage:[UIImage imageNamed:@"playButton.png"] forSegmentAtIndex:0];

	if (currentSlide != nil && visible && !self.navigationController.navigationBarHidden) {
		NSLog(@"About to set hide bars timer");
		if (hideBarsTimer != nil && [hideBarsTimer isValid]){
			[hideBarsTimer invalidate];
			hideBarsTimer = nil;
		}
		
		if(!filterPickerShowing)hideBarsTimer = [NSTimer scheduledTimerWithTimeInterval: 0.8 target:self selector:@selector(hideTopAndBottomBarsWithAnimation:) userInfo:nil repeats:NO];
	}

	//if (downloadStatus != nil && downloadStatus.hidden) [downloadStatus show];
	
	scrollView.scrollEnabled = TRUE;
    scrollView.pagingEnabled = TRUE;
    
    if ([Props global].freemiumType == kFreemiumType_V1 && !upgradePitchHidden)[self addUpgradePitch];
}


- (void) showThumbnailView {
	
	NSLog(@"SLIDECONTROLLER.showThumbnailView");
	
	settingUpSlideshow = TRUE;
    
    if (!showingThumbnails) currentPage = 0; //This resets the page to zero when transitioning from single images to thumbnails. Need to fix this to keep the page number during the transition at some point.
    
	showingThumbnails = TRUE;
	scrollView.scrollEnabled = FALSE;
	
	if (hideBarsTimer != nil && [hideBarsTimer isValid]){
		[hideBarsTimer invalidate];
		hideBarsTimer = nil;
	}
	
	//[scrollView removeGestureRecognizer:[[scrollView gestureRecognizers] objectAtIndex:0]];
	
	if (currentSlide != nil && self.navigationController.visibleViewController == self && [Props global].deviceType != kiPad)[self showTopAndBottomBars];
	
	UIView *coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
	coverView.alpha = 0.9;
	coverView.backgroundColor = [UIColor blackColor];
	
	UIActivityIndicatorView *progressInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	progressInd.frame = CGRectMake(([Props global].screenWidth - 40)/2, self.view.bounds.size.height/2.2, 40, 40);
	progressInd.alpha = .7;
	[progressInd startAnimating];
	//[progressInd sizeToFit];
	[coverView addSubview: progressInd];
	[self.view addSubview:coverView];
	
//	[self.view setNeedsDisplay];
	
	if (visible) [self performSelector:@selector(setUpThumbnails:) withObject:coverView afterDelay:.01];
    else [self setUpThumbnails:nil];
}

- (void) setUpThumbnails:(id)sender {
	
	UIView *coverView = (UIView*) sender;
    
    //currentPage = [self getPageNumberForIndex:currentSlide.firstImageIndex];
	
    NSLog(@"Current page = %i", currentPage);
    
    int pageNumber = currentPage;
    
    [self reset];
    
	scrollView.contentSize = CGSizeMake([Props global].screenWidth * 10000, [Props global].screenHeight - kTabBarHeight);
	
	[self.view bringSubviewToFront:coverView]; 
	
	scrollView.contentOffset = CGPointMake(self.view.bounds.size.width * pageNumber, 0);
	
	currentPage = pageNumber;
	
	if (pageNumber > 0) {
		NSLog(@"SLIDECONTROLLER.showThumbnailView: About to load previous slide");
		previousSlide = [[ImageView alloc] initWithPageNumber:pageNumber - 1 andController:self];
		[scrollView insertSubview:previousSlide atIndex:0];	
		//[previousSlide release];
	}
	
	NSLog(@"SLIDECONTROLLER.showThumbnailView: About to load current slide");
	currentSlide = [[ImageView alloc] initWithPageNumber:pageNumber andController:self];
	[scrollView insertSubview:currentSlide atIndex:0];
	
	[self.view bringSubviewToFront:coverView]; 
	
	NSLog(@"SLIDECONTROLLER.showThumbnailView: About to load next slide");
	nextSlide = [[ImageView alloc] initWithPageNumber:pageNumber + 1 andController:self];
	[scrollView insertSubview:nextSlide atIndex:0];	
	
	if (nextSlide == nil && previousSlide == nil) {
		scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, scrollView.frame.size.height);
		[slideModeControl setImage:[UIImage imageNamed:@"playButton_inactive.png"] forSegmentAtIndex:0];
	}	
	
	else [slideModeControl setImage:[UIImage imageNamed:@"playButton.png"] forSegmentAtIndex:0];
	
	//if (downloadStatus != nil && !downloadStatus.hidden) [downloadStatus hide];
	
	settingUpSlideshow = FALSE;
	scrollView.scrollEnabled = TRUE; //Necessary to avoid a potential bug with scrollViewDidScroll getting called mid-setup
	
	[UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[UIView setAnimationDuration: 0.2f ]; 
	
	coverView.alpha = 0;
	
	[UIView commitAnimations];
	
	[self performSelector:@selector(removeCoverView:) withObject:coverView afterDelay:.2];
	
	NSLog(@"SLIDECONTROLLER.showThumbnailView: done setting up thumbnails");
}


- (void) removeCoverView:(UIView*)coverView {
	
	[coverView removeFromSuperview];
}


- (void) addSlideToIndex:(ImageView*) slide {
	
	if (showingThumbnails && slide.lastImageIndex > maxImageIndex) {
		//if index contains first image on slide, do nothing
		//if index does not contrain first image, add it to end (slide page number and index value should be the same)
		if (![firstImageIndex containsObject:[NSNumber numberWithInt:slide.firstImageIndex]]) {
			NSLog(@"Adding image with index %i to firstImageIndex", slide.pageNumber);
			[firstImageIndex addObject:[NSNumber numberWithInt:slide.firstImageIndex]];
		}
	}
	
	else {		
		
		if (slide.pageNumber %[imageArray count] > maxImageIndex) {
			maxImageIndex = slide.pageNumber %[imageArray count];
			float thumbNailHeight = 77.5;
			float thumbNailWidth = slide.imageFrame.size.width * (thumbNailHeight/slide.imageFrame.size.height) + 2;
			thumbnailRowWidth += thumbNailWidth;	//if slide page number is bigger than max index 
			
			if (thumbnailRowWidth > self.view.bounds.size.width) {
				
				thumbnailRowWidth = thumbNailWidth + 2;
				thumbnailRowHeight += thumbNailHeight + 1.57;
				
				//NSLog(@"ThumbnailRowHeight = %f", thumbnailRowHeight);
				float contentHeight = self.view.bounds.size.height;
				if (self.entry == nil) contentHeight -= kTabBarHeight;
				
				if (thumbnailRowHeight > contentHeight) {
					thumbnailRowHeight = thumbNailHeight;
					if (![firstImageIndex containsObject:[NSNumber numberWithInt:slide.firstImageIndex]]) {
						NSLog(@"Adding image with index %i to firstImageIndex", slide.pageNumber);
						[firstImageIndex addObject:[NSNumber numberWithInt:slide.firstImageIndex]];
					}
				}
			}
		}
	}
}


- (int) getPageNumberForIndex:(int) theIndex {
	
	if (theIndex == 0) return 0;
	
	int i;
	for (i=0; i < [firstImageIndex count] - 1; i++) {
		if (theIndex > [[firstImageIndex objectAtIndex:i] intValue] && theIndex < [[firstImageIndex objectAtIndex:i+1] intValue]) {
			return i;
		}
	}
	
	return [[firstImageIndex lastObject] intValue];
}


- (int) getFirstImageIndexForPageNumber:(int) thePageNumber {
	
	int imageIndex = 0;
	
	NSLog(@"SLIDECONTROLLER.getFirstImageForPageNumber: page number = %i, firstImageIndex count = %i", thePageNumber, [firstImageIndex count]);
	
	if (thePageNumber >= [firstImageIndex count]) {
		
		if (currentSlide != nil) imageIndex = currentSlide.lastImageIndex + 1;
		
		else imageIndex = 0;
	}
	
	else imageIndex = [[firstImageIndex objectAtIndex:thePageNumber] intValue];
	
	NSLog(@"SLIDECONTROLLER.getFirstImageForPageNumber:imageIndex = %i", imageIndex);
	
	return imageIndex;
}


/*- (void) createDownloadStatusDisplay {
	
	NSLog(@"SLIDECONTROLLER.createDownloadStatusDisplay: called");

	float indicatorHeight = 44;
	float yPosition = (entry == nil) ? ([Props global].screenHeight - indicatorHeight - [Props global].tabBarHeight) : ([Props global].screenHeight - indicatorHeight);
	yPosition += indicatorHeight; //bar starts hidden and gets animated in
	//NSLog(@"yPosition = %f", yPosition);
	
	downloadStatus = [[DownloadStatus alloc] initWithFrame:CGRectMake(0, yPosition, [Props global].screenWidth, indicatorHeight) andController:self];
	downloadStatus.tag = 77;
	[self.view addSubview:downloadStatus];
    
    totalNumberOfImages = downloadStatus.totalNumber;
	
	if (showingThumbnails) {
		[downloadStatus setInactive];
		downloadStatus.hidden = TRUE;
		downloadStatus.frame = CGRectOffset(downloadStatus.frame, 0, downloadStatus.frame.size.height);
	}
}*/


- (void) addTitleLabel {
	
	//NSLog(@"SLIDECONTROLLER.addTitleLabel: called");
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 260, 30)];
	
	[label setFont:[UIFont boldSystemFontOfSize:16.0]];
	label.adjustsFontSizeToFitWidth = TRUE;
	label.minimumFontSize = 13;
	[label setBackgroundColor:[UIColor clearColor]];
	[label setTextColor:[UIColor colorWithWhite:0.8 alpha:0.8]];
	label.textAlignment = UITextAlignmentCenter;
	
	if ([entry.name length] < 20) [label setText: [NSString stringWithFormat:@"%@   ", entry.name]];
	
	else if ([entry.name length] < 26) [label setText: [NSString stringWithFormat:@"%@", entry.name]];
	
	else [label setText:entry.name];
	
	self.navigationItem.titleView = label;
}


- (void) addUpgradePitch {
    
    [[self.view viewWithTag:kOfflineUpgradePitchTag] removeFromSuperview];
    //UpgradePitch *pitch = [[UpgradePitch alloc] initWithYPos:[Props global].screenHeight - 30  andMessage: @"This slideshow requires an internet connection.<br> <a class='SMUpgradeLink' href='SMUpgradeLink://1'>Upgrade</a> for offline access"];
    UpgradePitch *pitch = [[UpgradePitch alloc] initWithYPos:0  andMessage: @"<a class='SMUpgradeLink' href='SMUpgradeLink://1'>Upgrade</a>&nbsp;for&nbsp;full&nbsp;offline&nbsp;access"];
    pitch.tag = kOfflineUpgradePitchTag;
    [self.view addSubview:pitch];
}


- (void) removeUpgradePitch { [[self.view viewWithTag:kOfflineUpgradePitchTag] removeFromSuperview];}


#pragma mark Delegate Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
   // NSLog(@"Current orientation = %u and to orientation = %u", interfaceOrientation, [UIDevice currentDevice].orientation);
    
    if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        
        return YES;
    }
    
    else return NO;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    
    NSLog(@"SLIDECONTROLLOER.willAnimateRotation");
	
	if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        [[Props global] updateScreenDimensions: interfaceOrientation];
	}
    
    if (visible) {
        NSLog(@"SLIDECONTROLLER.shouldAutorotate: hiding next and previous slides");
        
        if (!showingThumbnails) {
            rotationOverlay = [[ImageView alloc] initWithPageNumber:currentPage andController:self];
            rotationOverlay.frame = CGRectMake(0, 0, [Props global].screenHeight, [Props global].screenWidth);
            [self.view addSubview:rotationOverlay];
            scrollView.hidden = TRUE;
        }
    }

}


- (void) orientationChange: (NSNotification *)notification {
    
    NSLog(@"SLIDECONTROLLER.orientationChange");
     
    if (!visible) {
         NSLog(@"SLIDECONTROLLER.orientationChange: updating views"); 
        if (showingThumbnails) [self showThumbnailView];
         else [self showSingleImageView:nil];
     }
    
     tmpCounter ++;
}


- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
    
	NSLog(@"SLIDECONTROLLER.didRotateFromInterfaceOrientation");
	
    if (visible) {
		NSLog(@"SLIDECONTROLLER.willAutorotateToInterfaceOrientation:Updating views");
		if (showingThumbnails) [self showThumbnailView];
		else [self showSingleImageView:nil];
	}
    
    /*if ([Props global].osVersion >= 7.0 && [Props global].deviceType != kiPad) {
        [pickerSelectButton update];
        self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
    }*/
	
	if (self.navigationController.navigationBarHidden) [self hideTopAndBottomBarsWithAnimation:NO];
	
	else if ([Props global].deviceType != kiPad && [Props global].osVersion >= 4.0 && [[Props global] inLandscapeMode] && !self.navigationController.navigationBarHidden && self.entry == nil){
		
		NSLog(@"SLIDECONTROLLER.willAutorotateToInterfaceOrientation:Hiding title on tabBar controller");
		
		float xPos =  [[UIDevice currentDevice] orientation]==UIDeviceOrientationLandscapeLeft ? -kPartialHideTabBarHeight : 0;
		
		[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
		[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
		[ UIView setAnimationDuration: 0.1f ]; 
		
		//original version for regular app
		if(![Props global].isShellApp) self.tabBarController.view.frame = CGRectMake( xPos,0, ([Props global].screenHeight + kPartialHideTabBarHeight), [Props global].screenWidth);
        
        //update for SW - WHY????
        else self.tabBarController.view.frame = CGRectMake( 0,0, [Props global].screenWidth, [Props global].screenHeight + kPartialHideTabBarHeight);
		
		[ UIView commitAnimations ];
	}
    
    scrollView.hidden = FALSE;
    
    if ([[self.view subviews] containsObject:scrollView] != TRUE) [self.view addSubview:scrollView];
    scrollView.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
    
    if ([[self.view subviews] containsObject:rotationOverlay]){
        [rotationOverlay removeFromSuperview];
        if (rotationOverlay != nil)     {     rotationOverlay = nil;}
    }	
    
    if (playing && visible && !showingThumbnails) [self startSlideshow];
    
    if (filterPickerShowing) [[FilterPicker sharedFilterPicker] viewWillRotate];
    
    //**[pickerSelectButton resize];
    
    CGRect frame = self.tabBarController.view.frame;
    NSLog(@"TLSV.didRotateFromInterfaceOrientation: tabBarController coordinates = %f, %f, %f, %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    
    frame = self.view.frame;
    NSLog(@"TLSV.didRotateFromInterfaceOrientation: self.view coordinates = %f, %f, %f, %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    
    frame = [UIScreen mainScreen].bounds;
    NSLog(@"TLSV.didRotateFromInterfaceOrientation: mainscreen coordinates = %f, %f, %f, %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
}


#pragma mark code for advancing Slideshow

- (void)scrollViewDidScroll:(UIScrollView *)sender {
	
	//Used to differentiate between touches and scrolls
	if (touchTimer != nil) {
		[touchTimer invalidate];
		touchTimer = nil;
	}
	
    [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0)];
    
	// Switch the page when more than 50% of the previous/next page is visible
    CGFloat pageWidth = scrollView.frame.size.width;
	int pageNumber = floor((scrollView.contentOffset.x - pageWidth / 5) / pageWidth) + 1;
	
	if ((pageNumber != currentPage && [imageArray count] > 1) && !resetingContentSize) {
		
        @autoreleasepool {
            
            if (nextSlide != nil) nextSlide.hidden = FALSE;
            if (previousSlide != nil)  previousSlide.hidden = FALSE;
            
            //add any new images to the image array if we are approaching the end of the slideshow
            
            int pagesUntilEnd = (showingThumbnails) ? [imageArray count]/self.roughNumberOfThumbnailsPerPage - pageNumber : [imageArray count] - pageNumber % [imageArray count];
            NSLog(@"SLIDECONTROLLER.scrollViewDidScroll: pages to end = %i, current image count = %i", pagesUntilEnd, [imageArray count]);
            
            if (pagesUntilEnd < 2) {
                [self updateImageArray:nil];
                
                @synchronized(self) {
                    if ([updateArray count] > 0) {
                        [imageArray addObjectsFromArray:updateArray];
                        [updateArray removeAllObjects];
                        NSLog(@"SLIDECONTROLLER.scrollViewDidScroll: Updating image array, now has %i images", [imageArray count]);
                    }
                }
            }
            
            // going forwards
            if (pageNumber >= currentPage) {
                
                if(previousSlide != nil) {
                    //NSLog(@"SLIDECONTROLLER.scrollViewDidScroll:removing previous slide from superview");
                    [previousSlide removeFromSuperview];
                    previousSlide = nil;
                }
                
                previousSlide = currentSlide;
                currentSlide = nextSlide;
                
                nextSlide = [[ImageView alloc] initWithPageNumber:pageNumber + 1 andController:self];
                
                if (nextSlide == nil && showingThumbnails) {
                    scrollView.contentSize = CGSizeMake(self.view.bounds.size.width * (pageNumber + 1), scrollView.contentSize.height);
                    if (playing)[self pauseSlideshow];
                }
                
                if (!showingThumbnails && pageNumber >= [imageArray count] &&  pageNumber % [imageArray count] == 0) [self showLoopIndicator];
            }
            
            // going backwards
            else {
                
                if(nextSlide != nil){
                    [nextSlide removeFromSuperview];
                    nextSlide = nil;
                }
                
                nextSlide = currentSlide;
                
                currentSlide = previousSlide;
                
                if (pageNumber != 0) previousSlide = [[ImageView alloc] initWithPageNumber:pageNumber - 1 andController:self];
                
                else previousSlide = nil;
                
                NSLog(@"Page number = %i, image array count = %i, modulo count = %i", pageNumber, [imageArray count], pageNumber % [imageArray count]);
                
                if (!showingThumbnails && pageNumber % [imageArray count] == [imageArray count] - 1) [self showLoopIndicator];
            }
            
            //Bug with slideshow where app crashes when going backwards in slideshow happens somewhere in here. We might have fixed it, but don't quite know.
            
            
            if(previousSlide != nil)
                //NSLog(@"SLIDECONTROLLER.scrollViewDidScroll:About to insert previous slide = %@", previousSlide);
                [scrollView insertSubview:previousSlide atIndex:0];
            
            
            if (currentSlide != nil) {
                //NSLog(@"SLIDECONTROLLER.scrollViewDidScroll:About to insert current slide = %@", currentSlide);
                [scrollView insertSubview:currentSlide atIndex:1];
            }
            
            if (nextSlide != nil){
                //NSLog(@"SLIDECONTROLLER.scrollViewDidScroll:About to insert next slide = %@", nextSlide);
                [scrollView insertSubview:nextSlide atIndex:2];
            }
            
            
            //remove unused views
            //NSLog(@"Scrollview has %i subviews", [[scrollView subviews] count]);
            while ([[scrollView subviews] count] > 3) {
                
                [[[scrollView subviews] lastObject] removeFromSuperview];
            }
            
            /*int i;
             for (i= 0; i < [[scrollView subviews] count]; i++) {
             ImageView *theImageView = [[scrollView subviews] objectAtIndex:i];
             NSLog(@"%@:%@",theImageView.image.entry.name, theImageView.image.imageName);
             }*/
            
            currentPage = pageNumber;
            
            //NSLog(@"SLIDECONTROLLER.scrollViewDidScroll: Page number = %i", currentPage);
			
            //bring status view to the front
            for (UIView *view in [self.view subviews]) {
                if (view.tag == 77) 
                    [self.view bringSubviewToFront:view];
            }
            
            //Remove the top upgrade pitch in the event that we're showing an upgrade slide
            if (currentSlide.tag == kSlideshowUpgradeViewTag) [self removeUpgradePitch];
            
        }
	}
}


- (void) showNextImage:(id) sender {
	
	float xOffSet = self.view.bounds.size.width * (currentPage + 1);
	
	[scrollView setContentOffset:CGPointMake(xOffSet, 0)];
	
}


- (void) startSlideshow {
	
	NSLog(@"SLIDECONTROLLER.startSlideshow: called");
	
	if (nextSlide != nil) {
		playing = TRUE;
		
		if (viewDidJustAppear != TRUE) [NSTimer scheduledTimerWithTimeInterval: 0.35 target:self selector:@selector(showNextImage:) userInfo:nil repeats:NO];
		
		viewDidJustAppear = FALSE;
		
		if (slideShowTimer != nil) [slideShowTimer invalidate];
			
		slideShowTimer = [NSTimer scheduledTimerWithTimeInterval: kSlideshowInterval target:self selector:@selector(showNextImage:) userInfo:nil repeats:YES];
		
		[slideModeControl setImage:[UIImage imageNamed:@"pauseButton.png"] forSegmentAtIndex:0];
		
		//hide controls if they are showing
		if (!self.navigationController.navigationBarHidden && self.isViewLoaded && !showingThumbnails){
			if (hideBarsTimer != nil && [hideBarsTimer isValid]) [hideBarsTimer invalidate];
			hideBarsTimer = [NSTimer scheduledTimerWithTimeInterval: 0.8 target:self selector:@selector(hideTopAndBottomBarsWithAnimation:) userInfo:nil repeats:NO];
			
			if (fadeControlsTimer != nil && [fadeControlsTimer isValid]) [fadeControlsTimer invalidate];
			
			fadeControlsTimer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target:self selector:@selector(fadeOutControls:) userInfo:nil repeats:NO];
		}
	}	
}


- (void) pauseSlideshow {
	
	//NSLog(@"SLIDECONTROLLER.pauseSlideshow: called");
	
	if (playing) {
		
		if(slideShowTimer != nil) {
			[slideShowTimer invalidate];
			slideShowTimer = nil;
		}
		
		playing = FALSE;
		
		if ([imageArray count]>1) [slideModeControl setImage:[UIImage imageNamed:@"playButton.png"] forSegmentAtIndex:0];
		else [slideModeControl setImage:[UIImage imageNamed:@"playButton_inactive.png"] forSegmentAtIndex:0];
		
		fadeControlsTimer = [NSTimer scheduledTimerWithTimeInterval: 3.5 target:self selector:@selector(fadeOutControls:) userInfo:nil repeats:NO];
		
		
		[currentSlide updateLabels];
		if (nextSlide != nil) [nextSlide updateLabels];
		if (previousSlide != nil) [previousSlide updateLabels];
	}
}


- (void) fadeOutControls:(NSTimer*)theTimer {
	
	//NSLog(@"SLIDECONTROLLER.fadeOutControls: called");
	
	if (fadeControlsTimer != nil) {
		[fadeControlsTimer invalidate];
		fadeControlsTimer = nil;
	}
	
	[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
	[ UIView setAnimationDuration: 1.0f ]; // Set the duration
	
	[currentSlide hideLabels];
	
	[ UIView commitAnimations ];
	
	if (previousSlide != nil) [previousSlide hideLabels];
	if (nextSlide != nil) [nextSlide hideLabels];
}


- (void) fadeInControls:(NSTimer*)theTimer {
	
	//NSLog(@"SLIDECONTROLLER.fadeInControls: called");
	
	[UIView beginAnimations: nil context: nil]; // Tell UIView we're ready to start animations.
	[UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration: 0.5f]; // Set the duration
	
	if (currentSlide !=nil) [currentSlide showLabels];
	
	[UIView commitAnimations];
	
	if (previousSlide != nil) [previousSlide showLabels];
	if (nextSlide != nil) [nextSlide showLabels];

		
	if (fadeControlsTimer != nil && [fadeControlsTimer isValid]) {
		[fadeControlsTimer invalidate];
		fadeControlsTimer = nil;
	}
	
	fadeControlsTimer = [NSTimer scheduledTimerWithTimeInterval: 6.0 target:self selector:@selector(fadeOutControls:) userInfo:nil repeats:NO];
}


- (void) showTopAndBottomBars {
	
	NSLog(@"SLIDECONTROLLER.showTopAndBottomBars");
	
    scrollView.backgroundColor = [UIColor blackColor];
    
	[self fadeInControls:nil];
	
	[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[ UIView setAnimationDuration: 0.4f ];
    
    [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
	
	if (entry == nil) {
		
		if ([Props global].deviceType != kiPad && [[Props global] inLandscapeMode] && [Props global].osVersion >= 4.0){
			
            NSLog(@"Device orientation = %@", [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ? @"Landscape left" : @"Landscape right");
            
			float xPos =  [[UIDevice currentDevice] orientation]==UIDeviceOrientationLandscapeLeft ? -kPartialHideTabBarHeight : 0;
            //float xPos =  [[UIDevice currentDevice] orientation]==UIDeviceOrientationLandscapeLeft ? -10 : 0;
			if(![Props global].isShellApp) self.tabBarController.view.frame = CGRectMake( xPos,0, [Props global].screenHeight + kPartialHideTabBarHeight, [Props global].screenWidth);
            else self.tabBarController.view.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight + kPartialHideTabBarHeight);
		}
		
		else self.tabBarController.view.frame = [Props global].isShellApp ? CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight) : [[UIScreen mainScreen] bounds];
		
        
		if (!showingThumbnails) {
			[currentSlide updateTitleLabelPosition];
			if(nextSlide != nil)[nextSlide updateTitleLabelPosition];
			if (previousSlide != nil) [previousSlide updateTitleLabelPosition];
		}
	}
	
	/*if (downloadStatus != nil && !showingThumbnails) {
		float yPosition = (entry == nil) ? [Props global].screenHeight - downloadStatus.frame.size.height - [Props global].tabBarHeight: [Props global].screenHeight - downloadStatus.frame.size.height;
        
		NSLog(@"SLIDECONTROLLER.showTopAndBottomBars: About to show download status at yPos = %f, xPos = %f, with downloadStatus frame height = %f, width = %f", yPosition, downloadStatus.frame.origin.x, downloadStatus.frame.size.height, downloadStatus.frame.size.width);
		downloadStatus.frame = CGRectMake(downloadStatus.frame.origin.x, yPosition, downloadStatus.frame.size.width, downloadStatus.frame.size.height);
		downloadStatus.alpha = .8;
        [self.view bringSubviewToFront:downloadStatus];
	}*/
    
     [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0)];
	
	[ UIView commitAnimations ];
	
	if (currentSlide != nil && self.navigationController.visibleViewController == self && !showingThumbnails) hideBarsTimer = [NSTimer scheduledTimerWithTimeInterval: 5.0 target:self selector:@selector(hideTopAndBottomBarsWithAnimation:) userInfo:nil repeats:NO];
}


- (void) hideTopAndBottomBarsWithAnimation: (BOOL) animated {
	
	NSLog(@"SLIDECONTROLLER.hideTopAndBottomBars:self.view.bounds.size.width = %f", self.view.bounds.size.width);

    if (hideBarsTimer !=nil && [hideBarsTimer isValid]) {
        [hideBarsTimer invalidate];
        hideBarsTimer = nil;
    }
    
    scrollView.backgroundColor = [UIColor blackColor];
    
	if (!showingThumbnails && !filterPickerShowing) {
		[self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
		
        //[self hideTabBar:self.tabBarController];
		//float hideTabBarHeight, hideTabBarWidth;
		CGRect newScreenRect = CGRectZero;
		
		UIDeviceOrientation orientation = [Props global].lastOrientation; //This "last orientation" approach is necessary to get around complications with not changing the screen layout in faceup or facedown modes
		
        if ([Props global].isShellApp) newScreenRect = CGRectMake( 0,0, [Props global].screenWidth, [Props global].screenHeight + kTabBarHeight);
                    
        else {
            if (orientation == UIDeviceOrientationLandscapeRight) {
                
                NSLog(@"In landscape right");
                if([Props global].osVersion >= 4.0) newScreenRect = CGRectMake(0, 0, [Props global].screenHeight + kTabBarHeight, [Props global].screenWidth);
            }
            
            else if (orientation == UIDeviceOrientationLandscapeLeft) {
                
                NSLog(@"In landscape left");
                //if([Props global].osVersion >= 4.0) newScreenRect = CGRectMake(-kTabBarHeight, 0, [Props global].screenHeight + kTabBarHeight, [Props global].screenWidth);
                if([Props global].osVersion >= 4.0) newScreenRect = CGRectMake(-kTabBarHeight, 0, [Props global].screenHeight + kTabBarHeight, [Props global].screenWidth);
            }
            
            else if (orientation == UIDeviceOrientationPortrait || orientation == 0) {
                
                newScreenRect = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight + kTabBarHeight);
                NSLog(@"In portrait right side up");
            }
            
            else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
                
                newScreenRect = CGRectMake(0, -kTabBarHeight, [Props global].screenWidth, [Props global].screenHeight + kTabBarHeight);
                NSLog(@"In portrait upside down");
            }
            
            else {
                NSLog(@"******************ERROR*********************** SLIDECONTROLLER.hideTopAndBottomBars: orientation not found");
                newScreenRect = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
            } 
        }
		
        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0)];
		
		float duration = animated ? .3 : .00001;
		
		[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
		[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
		[ UIView setAnimationDuration: duration ]; 
		
		if (entry == nil && newScreenRect.size.width > 0) self.tabBarController.view.frame = newScreenRect; // CGRectMake(0, 0, hideTabBarWidth, hideTabBarHeight);
		
		NSLog(@"SC.hideTopAndBottomBars: tabBarController width = %f, height = %f, x = %f", self.tabBarController.view.frame.size.width, self.tabBarController.view.frame.size.height, self.tabBarController.view.frame.origin.x);
		
		/*if (downloadStatus != nil) {
			
			//float yPosition = (entry == nil) ? [Props global].screenHeight - downloadStatus.frame.size.height - kTabBarHeight: [Props global].screenHeight;
            float yPosition = [Props global].screenHeight;
			
			downloadStatus.frame = CGRectMake(downloadStatus.frame.origin.x, yPosition, downloadStatus.frame.size.width, downloadStatus.frame.size.height);
			downloadStatus.alpha = 0;
		}*/
		
		[currentSlide updateTitleLabelPosition];
		if(nextSlide != nil)[nextSlide updateTitleLabelPosition];
		if (previousSlide != nil) [previousSlide updateTitleLabelPosition];
		
		[ UIView commitAnimations ];
	}
}


- (void) hideOrShowTopAndBottomBars:(id) sender {
	
	NSLog(@"SLIDECONTROLLER.hideOrShowTopAndBottomBars");
        
    if (self.navigationController.navigationBarHidden) [self showTopAndBottomBars];
        
    else [self hideTopAndBottomBarsWithAnimation:YES];
}


- (void) removeTopBar: (id) sender {
	
	[self.navigationController setNavigationBarHidden:TRUE animated:FALSE];
}


- (void) showLoopIndicator {
	
	UIImage *roundTripImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"wrapAround" ofType:@"png"]];
	
	UIImageView *statusIndicator = [[UIImageView alloc] initWithImage:roundTripImage];
	statusIndicator.frame = CGRectMake((self.view.bounds.size.width - roundTripImage.size.width)/2,(self.view.bounds.size.width - roundTripImage.size.height)/2,roundTripImage.size.width, roundTripImage.size.height);
	
	statusIndicator.alpha = .85;
	[self.view addSubview:statusIndicator];

	[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[ UIView setAnimationDuration: 0.6f ]; // Set the duration to 1 second.
	
	statusIndicator.alpha = 0;
	
	[ UIView commitAnimations ];
	
}


- (void) didZoom: (id) sender {
	
	NSLog(@"Did zoom");
	if (!settingUpSlideshow) [self showThumbnailView];
}


// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	
	userControllingMotion = TRUE;
	
	// This method only seems to get called when the page is advanced with a finger swipe.
	[self pauseSlideshow];
	playing = FALSE;
	[self fadeInControls:nil];
}

#pragma mark
#pragma mark DataSource Methods
- (void) initImageArray{
	
    //** This method is only used for creating the image array for the top level slideshow
    
    NSDate *date = [NSDate date]; //Just used for performance testing
    
	//NSLog(@"SLIDECONTROLLER.initImageArray: starting");
    
	self.imageArray = [NSMutableArray new];
	FMDatabase *db = [EntryCollection sharedContentDatabase];
        
    if(![filterCriteria  isEqual: kFavorites]) {
        
        // **** Get some big pics first if we're on an iPad ****
        if ([Props global].deviceType == kiPad) {
            
            NSString * query1;
            
            if((filterCriteria == nil || [filterCriteria isEqualToString:@"Everything"]))
                query1 = @"SELECT DISTINCT photos.rowid AS photoid, entries.rowid AS entryid FROM photos, entries, entry_photos\
                WHERE photos.rowid = entry_photos.photoid AND entry_photos.entryid = entries.rowid";
            
            else query1 = [NSString stringWithFormat: @"\
                           SELECT DISTINCT photos.rowid AS photoid, entries.rowid as entryid FROM entries, photos, entry_photos\
                           WHERE photos.rowid = entry_photos.photoid AND entry_photos.entryid = entries.rowid\
                           AND entries.rowid IN\
                           (SELECT entries.rowid FROM entries, groups, entry_groups WHERE entries.rowid = entry_groups.entryid AND entry_groups.groupid = groups.rowid AND groups.name = '%@')", filterCriteria];
            
            query1 = [query1 stringByAppendingString:@" AND photos.downloaded_768px_photo > 0 ORDER BY RANDOM() LIMIT 500"];
            
            NSMutableArray *entryList = [NSMutableArray new];
            
            @synchronized([Props global].dbSync) {
                
                FMResultSet * rs = [db executeQuery:query1];
                
                if ([db hadError]) NSLog(@"sqlite error in [SlideshowViewController initImageArray], query = %@, %d: %@", query1, [db lastErrorCode], [db lastErrorMessage]);
                
                //NSLog(@"SLIDECONTROLLER.initImageArray - starting to create image array");
                
                while ([rs next]) {
                    
                    NSNumber *imageID = [[NSNumber alloc] initWithInt:[rs intForColumn:@"photoid"]];
                    NSNumber *entryID = [[NSNumber alloc] initWithInt:[rs intForColumn:@"entryid"]];
                    if (![entryList containsObject:entryID]) [self.imageArray addObject:imageID];
                    else 
                        NSLog(@"Not adding a second image for an entry already present");
                    
                    [entryList addObject:entryID];
                }
                
                [rs close];
            }
        }
        
        NSLog(@"SLIDECONTROLLER.initImageAray: %i iPad sized photos added", [imageArray count]);
        
        // **** Add the full resolution icon photos next ****
        NSString * query1;
        if((filterCriteria == nil || [filterCriteria isEqualToString:@"Everything"])){
            
            if ([Props global].appID != 1) query1 = @"SELECT icon_photo_id FROM entries, photos\
                WHERE icon_photo_id = photos.rowid\
                AND (photos.downloaded_320px_photo OR photos.downloaded_768px_photo) > 0";
            
            else query1 = @"SELECT icon_photo_id FROM entries, photos\
                WHERE icon_photo_id = photos.rowid\
                AND photos.downloaded_x100px_photo > 0";
        }
        
        else {
            
            if ([Props global].appID != 1) 
                query1 = [NSString stringWithFormat: @"\
                          SELECT icon_photo_id FROM entries, photos\
                          WHERE icon_photo_id = photos.rowid\
                          AND (photos.downloaded_320px_photo OR photos.downloaded_768px_photo) > 0\
                          AND entries.rowid IN (SELECT entries.rowid FROM entries, groups, entry_groups WHERE entries.rowid = entry_groups.entryid AND entry_groups.groupid = groups.rowid AND groups.name = '%@')", filterCriteria];
            
            else query1 = [NSString stringWithFormat:@"\
                           SELECT icon_photo_id FROM entries, photos\
                           WHERE icon_photo_id = photos.rowid\
                           AND photos.downloaded_x100px_photo > 0\
                           AND entries.rowid IN (SELECT entries.rowid FROM entries, groups, entry_groups WHERE entries.rowid = entry_groups.entryid AND entry_groups.groupid = groups.rowid AND groups.name = '%@')\
                           ", filterCriteria];    
        }
        
        query1 = [query1 stringByAppendingString:@" ORDER BY RANDOM() LIMIT 500"];
        
        @synchronized([Props global].dbSync) {
            
            FMResultSet * rs = [db executeQuery:query1];
            
            if ([db hadError]) NSLog(@"sqlite error in [SlideshowViewController initImageArray], query = %@, %d: %@", query1, [db lastErrorCode], [db lastErrorMessage]);
            
            //NSLog(@"SLIDECONTROLLER.initImageArray - starting to create image array");
            
            while ([rs next]) {
                
                NSNumber *imageID = [[NSNumber alloc] initWithInt:[rs intForColumn:@"icon_photo_id"]];
                [self.imageArray addObject:imageID];
            }
            
            [rs close];
        }   
    }

            
    
    NSLog(@"SLIDECONTROLLER.initImageArray: time to 1 = %0.2f", -[date timeIntervalSinceNow]);
    
    //***** Next add the rest of the photos on at the end as needed *********
    
    if([self.imageArray count] < 200){
        NSString *query2 = [self createPhotoQuery];
        
        NSLog(@"SLIDECONTROLLER.initImageArray: time to 2 = %0.2f", -[date timeIntervalSinceNow]);
        
        @synchronized([Props global].dbSync) {
            
            FMResultSet *rs = [db executeQuery:query2];
            
            if ([db hadError]) NSLog(@"sqlite error in [SlideshowViewController initImageArray], query = %@, %d: %@", query2, [db lastErrorCode], [db lastErrorMessage]);
            
            //NSLog(@"SLIDECONTROLLER.initImageArray - starting to create image array");
            NSLog(@"SLIDECONTROLLER.initImageArray: time to 3 = %0.2f", -[date timeIntervalSinceNow]);
            
            while ([rs next]) {
                
                NSNumber *imageID = [[NSNumber alloc] initWithInt:[rs intForColumn:@"rowid"]];
                [self.imageArray addObject:imageID];
            }
            
            [rs close];	
        }
    }
	
	NSLog(@"SLIDECONTROLLER.initImageArray: image array set up with %i images", [imageArray count]);
    NSLog(@"SLIDECONTROLLER.initImageArray: took %0.5f seconds", -[date timeIntervalSinceNow]);
}


- (void) updateImageArray: (id) sender {
	
    NSString *query = [self createPhotoQuery];
	
    @synchronized([Props global].dbSync) {
        
        FMDatabase * db = [EntryCollection sharedContentDatabase];
        FMResultSet *rs = [db executeQuery:query];
        
        //if ([db hadError]) (@"sqlite error in [SlideshowViewController initImageArray], query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
        
        while ([rs next]) {
            
            NSNumber *imageID = [[NSNumber alloc] initWithInt:[rs intForColumn:@"rowid"]];
            
            @synchronized(self) {[updateArray addObject:imageID];}
        }
        
        [rs close];	
    }
	
   	//NSLog(@"SLIDECONTROLLER.updateImageArray: update array count = %i and downloadCounter = %i", [updateArray count], downloadCounter);
}


- (NSString*) createPhotoQuery {
    
    NSString *query;
    
    if (self.entry != nil) {
        
        int sizeParameter = ([Props global].deviceType == kiPad) ? 768:320;
        
        query = [NSString stringWithFormat:@"SELECT DISTINCT photos.rowid FROM photos, entry_photos, entries WHERE entry_photos.entryid = %i AND entry_photos.photoid = photos.rowid AND entry_photos.entryid = entries.rowid AND (photos.downloaded_%ipx_photo NOT NULL OR photos.downloaded_x100px_photo NOT NULL)", entry.entryid, sizeParameter];
    }
    
    else if(filterCriteria == nil || [filterCriteria isEqualToString:@"Everything"]){
        //query = [NSString stringWithFormat:@"SELECT entries.name AS name, photos.rowid, photos.author, photos.license, photos.url, photos.caption FROM photos, entry_photos, entries WHERE entry_photos.awesome = 1 AND entry_photos.photoid = photos.rowid AND entries.rowid = entry_photos.entryid ORDER BY RANDOM()"];
        if ([Props global].appID != 1) query = @"SELECT DISTINCT photos.rowid FROM photos, entry_photos, entries WHERE entry_photos.awesome = 1  AND entry_photos.photoid = photos.rowid AND entries.rowid = entry_photos.entryid AND (photos.downloaded_320px_photo OR photos.downloaded_768px_photo or photos.downloaded_x100px_photo) > 0";
        
        else query = @"SELECT rowid FROM photos WHERE photos.downloaded_x100px_photo > 0";
    }
    
    else if([filterCriteria  isEqual: kFavorites]) {
		
		NSArray *theFavorites = [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]]; //get the array of names of favorite entries
		
		if([theFavorites count] > 0) {
            
            NSMutableString *entryList = [NSMutableString stringWithFormat:@""];
            
			for(NSString* entryName in theFavorites){
				
                Entry *e = [[EntryCollection sharedEntryCollection].entriesDictionary objectForKey:entryName];
                [entryList appendString:[NSString stringWithFormat:@"%i,", e.entryid]];
			}
            
            [entryList deleteCharactersInRange:NSMakeRange([entryList length] - 1, 1)]; //Delete the last comma on the end
            
            query = [NSString stringWithFormat:@"SELECT DISTINCT photos.rowid FROM photos, entry_photos, entries WHERE entry_photos.awesome = 1 AND entry_photos.photoid = photos.rowid AND entries.rowid = entry_photos.entryid AND entry_photos.entryid IN (%@) AND (photos.downloaded_320px_photo OR photos.downloaded_768px_photo or photos.downloaded_x100px_photo) > 0", entryList];
		}
	}
    
    
    else {
        
        query = [NSString stringWithFormat:@"SELECT DISTINCT photos.rowid FROM photos, entry_photos, entries WHERE entry_photos.awesome = 1 AND entry_photos.photoid = photos.rowid AND entries.rowid = entry_photos.entryid AND entries.rowid AND entry_photos.entryid AND (photos.downloaded_320px_photo OR photos.downloaded_768px_photo or photos.downloaded_x100px_photo) > 0 AND entries.rowid IN (SELECT entries.rowid FROM entries, groups, entry_groups WHERE entries.rowid = entry_groups.entryid AND entry_groups.groupid = groups.rowid AND groups.name = '%@')", filterCriteria];
    }
    
    //**** Create list of already included photos to exclude *****
    if ([self.imageArray count] > 0) {
        
        NSMutableString *excludeList = [NSMutableString stringWithFormat:@""];
        
        for (NSNumber *photoid in self.imageArray) {
            
            [excludeList appendFormat:@"%i,", [photoid intValue]];
        }
        
        [excludeList deleteCharactersInRange:NSMakeRange([excludeList length] - 1, 1)]; //delete the last comma
        
        query = [query stringByAppendingFormat:@" AND photos.rowid NOT IN (%@)", excludeList];
    }
        
    query = [query stringByAppendingString:[NSString stringWithFormat:@" ORDER BY RANDOM() LIMIT %i", [Props global].deviceType == kiPad ? 200 : 100]];
    
    NSLog(@"SLIDECONTROLLER.createQueryString: Query = %@", query);
    
    return query;
}


#define Button Actions

- (void) playPauseSlideshow: (id) sender {
	
	NSLog(@"SLIDECONTROLLER.playPauseSlideshow: called");
	
	if([imageArray count] > 1) {
		
		if(playing) {
			
			[self pauseSlideshow];
			//if (entry == nil) [self showTabBar];
			//[self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
			
			playing = FALSE;
			
			if (self.entry == nil) {
		
				SMLog *log = [[SMLog alloc] initWithPageID: kTLSS actionID: kSSPause];
				log.filter_id = [[FilterPicker sharedFilterPicker] getFilterID];
				[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
			}
		}
		
		else {
			
			[self startSlideshow];
			//[self.navigationController setNavigationBarHidden:TRUE animated:TRUE];
			//if (entry == nil) [self hideTabBar];
			
			if (self.entry == nil) {
				
				SMLog *log = [[SMLog alloc] initWithPageID: kTLSS actionID: kSSPlay];
				log.filter_id = [[FilterPicker sharedFilterPicker] getFilterID];
				[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
			}
			
			// remove title from top for entry level slideshows
			//else  //self.navigationItem.titleView = nil;			
		}
		
		[currentSlide updateLabels];
		if (previousSlide != nil) [previousSlide updateLabels];
		if (nextSlide != nil) [nextSlide updateLabels];
	}
}


- (void) goThere: (id) sender {
    
    //self.tabBarController.view.frame = [[UIScreen mainScreen] bounds];
    self.tabBarController.view.frame = [Props global].isShellApp ? CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight) : [[UIScreen mainScreen] bounds];
	
	LocationViewController *entryController = [[LocationViewController alloc] initWithController: nil];
	
	// set the entry for the controller
	entryController.entry = [EntryCollection entryByName:currentSlide.name]; 
	
	// push the entry view controller onto the navigation stack to display it
	[[self navigationController] pushViewController:entryController animated:YES];
	[entryController.view setNeedsDisplay];
	
	/*SMLog *log = [[SMLog alloc] initWithPageID: kTLSS actionID: kSSGoToEntry];
	log.entry_id = entryController.entry.entryid;
	log.photo_id = [currentSlide.imageName intValue];
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	[log release];*/
    
	SMLog *log = [[SMLog alloc] initPopularityLog];
	log.photo_id = [currentSlide.imageName intValue];
	[[ActivityLogger sharedActivityLogger] sendPopularityLog: [log createPopularityLog]];
}


- (void) refreshData {
	
    NSLog(@"SLIDECONTROLLER.refreshData = %@", filterCriteria);
	//[[EntryCollection sharedEntryCollection] filterDataTo:filterCriteria];
	
	[self initImageArray];
	
	if (showingThumbnails) [self showThumbnailView];
	else [self showSingleImageView:nil];
}


- (void) showFilterPicker: (id) sender {
	
	if (hideBarsTimer !=nil && [hideBarsTimer isValid]) {
		[hideBarsTimer invalidate];
		hideBarsTimer = nil;
	}
    
    [self showTopAndBottomBars];
	
	filterPickerShowing = TRUE;
	[self.view addSubview: [FilterPicker sharedFilterPicker]];
	[self.view bringSubviewToFront:[FilterPicker sharedFilterPicker]];
	[[FilterPicker sharedFilterPicker] showControls];
	
	lastFilterChoice = [[FilterPicker sharedFilterPicker] getPickerTitle];
	
	self.navigationItem.leftBarButtonItem = pickerSelectButton.cancelBarButton;
}


- (void) hideFilterPicker: (id) sender {
	
	filterPickerShowing = FALSE;
	[[FilterPicker sharedFilterPicker] hideControls];
	
	filterCriteria = [[FilterPicker sharedFilterPicker] getPickerTitle];
	
	[pickerSelectButton update];
	self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
	
	[cancelButton removeFromSuperview];
	
	if([filterCriteria isEqualToString:lastFilterChoice] == FALSE) {
		
		if(scrollView != nil)
			[scrollView removeFromSuperview];
		
		[self refreshData];
		
		viewDidJustAppear = TRUE; //BOOL is used to prevent slideshow from quickly advancing as it does after a tap
		
        NSLog(@"Image array count = %i", [imageArray count]);
        
		if([imageArray count] > 1 && !showingThumbnails)
			[self startSlideshow];
	}
	
	else if (!self.navigationController.navigationBarHidden && visible && !showingThumbnails){
		if (hideBarsTimer != nil && [hideBarsTimer isValid]) [hideBarsTimer invalidate];
		hideBarsTimer = [NSTimer scheduledTimerWithTimeInterval: 3.0 target:self selector:@selector(hideTopAndBottomBarsWithAnimation:) userInfo:nil repeats:NO];
	}
}


- (void) showWebPageView: (id) sender {
	
    
    //**self.tabBarController.view.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
    
    CGRect navFrame = self.navigationController.view.frame;
    NSLog(@"Navigation controller frame = %f, %f, %f, %f", navFrame.origin.x, navFrame.origin.y, navFrame.size.width, navFrame.size.height);
    
	NSURL *theURL = [NSURL URLWithString:currentSlide.hyperlink];
	
	if (entry != nil) {
		//Set back image for returning to this view
		UIImage *backImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"back" ofType:@"png"]];
		UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backImage style: UIBarButtonItemStylePlain target:nil action:nil];
		self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
	}
	
	WebViewController *webPageView = [[WebViewController alloc] initWithEntry:nil andURLToLoad:theURL];
	[self.navigationController pushViewController:webPageView animated:YES];
	
}


- (void) respondToTap:(NSTimer*) timer {

	NSLog(@"SLIDECONTORLLER.respondToTap: hide or show top or bottom bars");
	[self pauseSlideshow];
	if(!showingThumbnails)[self hideOrShowTopAndBottomBars:nil];
}


/*- (void) destroyDownloadStatus: (id) selector {

	NSLog(@"SLIDECONTROLLER.destroyDownloadStatus: called");
	
	//if (downloadStatus != nil) {
		
    NSLog(@"About to release dowloadstatus with retain count = %i", [downloadStatus retainCount]);
    //[downloadStatus setInactive];
    //[downloadStatus removeFromSuperview];
    NSLog(@"SLIDECONTROLLER.destroyDownloadStatus, 1 retain count = %i", [downloadStatus retainCount]);
    [downloadStatus release];
    //NSLog(@"SLIDECONTROLLER.destroyDownloadStatus, 2 retain count = %i", [downloadStatus retainCount]);
    downloadStatus = nil;
	//}
	
	//else NSLog(@"SLIDECONTROLLER.destroyDownloadStatus: download status already nil, no need to destroy")
}*/


- (void) sharePic: (id) sender {
		
	if (entry != nil) {
		
		SMLog *log = [[SMLog alloc] initWithPageID: kEntrySlideShow actionID: kESSShareImage];
		log.entry_id = entry.entryid;
		log.photo_id = [currentSlide.imageName intValue];
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}
	
	else {
		
		SMLog *log = [[SMLog alloc] initWithPageID: kTLSS  actionID: kSSShareImage];
		log.photo_id = [currentSlide.imageName intValue];
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}

	
	MFMailComposeViewController *emailer = [[MFMailComposeViewController alloc] init];
	emailer.mailComposeDelegate = self;
	
	[emailer setSubject:[NSString stringWithFormat:@"Check out %@",currentSlide.name]];
	
	
	// Fill out the email body text
	
	NSString* header =@"<html><body leftmargin='0' marginwidth='0' topmargin='0' marginheight='0' offset='0' bgcolor=white >";
	
	NSString *messageHeader = @"<p> Thought you'd like this...</p>";
	
	NSString *tableHeader = @"<table width='310px' cellpadding='0' cellspacing='0' style='color:rgb(070,070,070); font-family:Arial, Helvetica, sans-serif;'>";
	
	NSString *guideLink = [NSString stringWithFormat:@"<tr><td COLSPAN=2 STYLE='PADDING-BOTTOM:10px; FONT-SIZE:14px'>From <a href='%@?id=imgemail_a%i_e%i' style='text-decoration:none; color:rgb(%0.0f,%0.0f,%0.0f)'>%@</span></a> app:</td></tr>", [Props global].appLink, [Props global].appID, entry.entryid, kHyperlinkRed * 255, kHyperlinkGreen * 255, kHyperlinkBlue * 255, [Props global].appName];
	
	NSString *entryTitle;
    
    if ([Props global].appID > 1) {
        entryTitle =[NSString stringWithFormat:@"<tr><td COLSPAN=2 lign='left' width='310' height='35'  BACKGROUND='http://www.sutroproject.com/content/shared_content/Email_Top.gif'  style='font-size:15px;font-weight:700; PADDING-RIGHT: 0px; PADDING-LEFT: 0px; PADDING-BOTTOM: 0px;  PADDING-TOP:9px;' align='center'>%@</td></tr>",currentSlide.name];
    }	
    
    else entryTitle = [NSString stringWithFormat:@"<tr><td COLSPAN=2 lign='left' width='310' height='35'  BACKGROUND='http://www.sutroproject.com/content/shared_content/Email_Top.gif'  style='font-size:15px;font-weight:700; PADDING-RIGHT: 0px; PADDING-LEFT: 0px; PADDING-BOTTOM: 0px;  PADDING-TOP:9px;' align='center'>%@ from %@</td></tr>",currentSlide.caption, currentSlide.name];

	
	int licenseCode = [currentSlide.license intValue];
	
	NSString *attributionHTML;
	
	if([currentSlide.author length] == 0 || licenseCode == 7) attributionHTML = nil;
		
	else if(licenseCode == 0) attributionHTML = @"<img src='http://www.sutromedia.com/app-resources/copyright.png' width='15' height='14' style='border-color:white; border-right:#FFFFFF 2px solid;'/>";
			
	else if(licenseCode == 1 || licenseCode == 5)attributionHTML = @"<img src='http://www.sutromedia.com/app-resources/attribution.png' width='15' height='14' style='border-color:white; border-right:#FFFFFF 2px solid;'/><img src='http://www.sutromedia.com/app-resources/shareAlike.png' width='15' height='14' style='border-color:white; border-right:#FFFFFF 2px solid;'/>";
		
	
	else if(licenseCode == 2 || licenseCode == 4) attributionHTML = @"<img src='http://www.sutromedia.com/app-resources/attribution.png' width='15' height='14' style='border-color:white; border-right:#FFFFFF 2px solid;'/>";	
	
	else if(licenseCode == 3 || licenseCode == 6) attributionHTML = @"<img src='http://www.sutromedia.com/app-resources/attribution.png' width='15' height='14' style='border-color:white; border-right:#FFFFFF 2px solid;'/><img src='http://www.sutromedia.com/app-resources/noDerivative.png' width='15' height='14' style='border-color:white; border-right:#FFFFFF 2px solid;'/>";
	
	else attributionHTML = nil;
	
	
	NSString *copyright;
	
	if (attributionHTML != nil) copyright = [NSString stringWithFormat:@"<tr><td COLSPAN=2 ALIGN='center' style='font-size:8px; BORDER-LEFT: #808080 2px solid; BORDER-RIGHT: #808080 2px solid; PADDING-LEFT:6px; PADDING-RIGHT: 6px; PADDING-TOP:4px; PADDING-BOTTOM:5px;'>%@<span style='font-weight:100;font-style:italic; color:rgb(200,200,200)'>%@</span></td></tr>", attributionHTML, currentSlide.author];
	
	else copyright =[NSString stringWithFormat:@"<tr><td COLSPAN=2 ALIGN='center' style='font-size:5px; BORDER-LEFT: #808080 2px solid; BORDER-RIGHT: #808080 2px solid; PADDING-LEFT:6px; PADDING-RIGHT: 6px; PADDING-TOP:4px; PADDING-BOTTOM:8px;'><span style='font-weight:100;font-style:italic; color:rgb(150,150,150)'></span></td></tr>"];
	
	//NSString *appLink = [NSString stringWithFormat:@"<tr><td COLSPAN=2 ALIGN='left' style='BORDER-LEFT: #808080 2px solid; BORDER-RIGHT: #808080 2px solid; PADDING-LEFT:6px; PADDING-RIGHT:6px'><table cellpadding='0' cellspacing='0' border='0'><tr><td><a href='%@' style='vertical-align:middle;'><img src='http://www.sutromedia.com/app-icons/%i_36x36.jpg' width='40' height='40' style='border-color:white; border-right:#FFFFFF 10px solid;'/></a></td><td><a href='%@' style='vertical-align:center; font-size:11px; text-decoration:none; color:rgb(%0.0f,%0.0f,%0.0f)'>Get <span style='font-weight:bold'>%@</span> for your iPhone</a></td></tr></table></td></tr>",[Props global].appLink, [Props global].appID, [Props global].appLink,  kHyperlinkRed * 255, kHyperlinkGreen * 255, kHyperlinkBlue * 255, [Props global].appName];
	
	NSString *sutroLink = @"<tr><td COLSPAN=2 align='left' width='310' height='35'><a href='http://www.sutromedia.com'><img height='35' alt='Published by Sutro Media' src='http://www.sutroproject.com/content/shared_content/Email_Bottom.gif' width='310' border='0'></a></td></tr>";
	
	NSString *footer = @"</table></body></html>";
	
	
	NSString *rootSutroImageURL = @"http://www.sutromedia.com/published/iphone-sized-photos";
	
	rootSutroImageURL = [rootSutroImageURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	UIImage *iconImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource: currentSlide.imageName ofType:@"jpg"]];
	
	//if big image has not yet been downloaded, we'll need to use a small one
	if (iconImage == nil) iconImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@_151x", currentSlide.imageName] ofType:@"jpg"]];
	
	
	NSString *iconImageHTML = [NSString stringWithFormat:@"<tr><td style='PADDING-BOTTOM:2px; BORDER-RIGHT: #808080 2px solid; BORDER-LEFT: #808080 2px solid;'><IMG SRC='%@/%@.jpg' BORDER='0' align='left' width='306' height='%f'></td>",rootSutroImageURL,currentSlide.imageName, 302 * iconImage.size.height/iconImage.size.width];

		
	NSString *emailBody = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@",header,messageHeader,tableHeader, guideLink, entryTitle,iconImageHTML, copyright, sutroLink, footer];
	
	[emailer setMessageBody:emailBody isHTML:YES];
	
	if (iconImage != nil) {
		iconImage = nil;
	}
	
	if (emailer != nil) {
        [self presentModalViewController:emailer animated:YES];
    }
    
    NSLog(@"APPLINK = %@", guideLink);
}


// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	[self dismissModalViewControllerAnimated:YES];
}


@end

