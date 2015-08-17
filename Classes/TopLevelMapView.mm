    //
//  TopLevelMapView.m
//  TheProject
//
//  Created by Tobin1 on 10/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TopLevelMapView.h"
#import "MapViewController.h"
#import "Props.h"
#import "FilterPicker.h"
#import "EntryCollection.h"
#import "Entry.h"
#import "RMMarker.h"
#import "SMLog.h"
#import "ActivityLogger.h"
#import "RMMarker.h"
#import "LocationViewController.h"
#import "RMMarkerManager.h"
#import "SMMapAnnotation.h"
#import "DataDownloader.h"
#import "Reachability.h"
#import "FilterButton.h"
#import "UpgradePitch.h"
//#import "GlobeViewController.h"
#import "ImageManipulator.h"
#import <QuartzCore/QuartzCore.h>

#define kOverlayTag 1
#define kSetMapButtonsTag 23452345
#define kLoadingViewTag 98732145
#define kMapAnnotationTag 234534



@interface TopLevelMapView (PrivateMethods)

- (void) createSetMapButtons;
- (void) refreshViewAndData:(BOOL) shouldRefreshData;
- (void) hideFilterPicker: (id) sender;
- (void) addOfflineUpgradePitch;

@end

@implementation TopLevelMapView


#pragma mark
#pragma mark Initilization Methods

- (id) init {
	
	NSLog(@"TLMV.init");
	self = [super init];
    if (self) {
		self.tabBarItem.image = [UIImage imageNamed: @"signpost.png"];
		self.title = @"Map";
		self.navigationItem.title = nil;
		filterPickerShowing = NO;
		filterCriteria = @"Everything";
		self.hidesBottomBarWhenPushed = FALSE;
		
		//Create a custom back button image
		UIImage *backImage =[UIImage imageNamed:@"backToMap.png"];
		UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backImage style: UIBarButtonItemStylePlain target:nil action:nil];
		
		self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
        
        mvc = [MapViewController sharedMVC]; //start the map loading as early as possible
        //[mvc performSelectorInBackground:@selector(loadEntries) withObject:nil];
		
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLocation:) name:kShowLocation object:nil];
        
		if([Props global].filters != nil) {
			filterPicker =  [FilterPicker sharedFilterPicker];
			pickerSelectButton = [[FilterButton alloc] initWithController:self];
            //**[pickerSelectButton resize];
			self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
			filterCriteria = [[FilterPicker sharedFilterPicker] getPickerTitle];
		}
        
        //set initial map zoom and center
        lastMapCenter.latitude = [Props global].mapRegion.center.latitude + [Props global].mapRegion.span.latitudeDelta * .06;
        lastMapCenter.longitude = [Props global].mapRegion.center.longitude; 
        
        lastZoomLevel = [Props global].startingZoomLevel;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMapAnnotation:) name: kShowMapAnnotation object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeMapAnnotations) name: kRemoveMapAnnotations object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showView) name: kGoToMapsNotification object:nil];
	}
	
	return self;
}


- (void) showView {
    
    self.tabBarController.selectedIndex = 2;
}


- (void) showLocation:(NSNotification*) notification {
    
    NSLog(@"Top level map view - show location");
    //self.tabBarController.selectedViewController = self;
    self.tabBarController.selectedIndex = 2;
    
    Entry *_entry = (Entry*) notification.object;
    
    /*lastMapCenter.latitude = [_entry getLatitude] - .02;
    lastMapCenter.longitude = [_entry getLongitude];
    lastZoomLevel = 17;*/
    
    [mvc performSelectorInBackground:@selector(showAnnotationForEntry:) withObject:_entry];
}


- (void)dealloc {
    
    NSLog(@"TLMV.dealloc*******************************************");
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //[globe release];
	mvc.mapView.delegate = nil;
}


- (void)loadView {
	
	NSLog(@"TLMV.loadView");
	
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	contentView.backgroundColor = [UIColor blackColor];
	self.view = contentView;
	self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	self.view.autoresizesSubviews = YES;
    
    if ([Props global].appID != 1) {
        mvc.mapView.delegate = self;
        [self.view addSubview: mvc.view];
        NSLog(@"TLMV.loadView: center = %f, %f, last center = %f, %f",mvc.mapView.contents.mapCenter.latitude, mvc.mapView.contents.mapCenter.longitude, lastMapCenter.latitude, lastMapCenter.longitude);

    }
    
    else {
        
       // GlobeViewController *globe = [[GlobeViewController alloc] init];
       // [self.view addSubview:globe.view];
       // [globe release];
    }
}


- (void) viewWillAppear:(BOOL)animated {

	NSLog(@"TLMV.viewWillAppear");
    
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
	
	mvc.view.frame = self.view.bounds;
    mvc.mapView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	
	self.navigationController.navigationBar.alpha = 1.0;
	self.navigationController.navigationBar.translucent = TRUE;
    if ([Props global].osVersion < 7.0) self.navigationController.navigationBar.tintColor = [Props global].navigationBarTint;
    else self.navigationController.navigationBar.barStyle = UIBarStyleDefault;

	[self.navigationController setNavigationBarHidden:FALSE animated:FALSE];
	[[DataDownloader sharedDataDownloader] pauseDownload];
	
	//Set map parameters that might have gotten changed in another view
    mvc.userLocationMarker.hidden = FALSE;
	mvc.userLocationBackground.hidden = FALSE;
    
    //Reset the map center after going to the test app
    if (!mvc.entriesLoaded && !mvc.entriesLoading) {
        lastMapCenter.latitude = [Props global].mapRegion.center.latitude + [Props global].mapRegion.span.latitudeDelta * .06;
        lastMapCenter.longitude = [Props global].mapRegion.center.longitude; 
        
        lastZoomLevel = [Props global].startingZoomLevel;
    }
    
   
    if (mvc.mapView.contents.zoom != lastZoomLevel) {
        NSLog(@"TLMV.viewWillAppear: reseting map zoom");
        mvc.mapView.contents.zoom = lastZoomLevel;
        [mvc afterMapZoom:mvc.mapView byFactor:0 near:CGPointZero];
    }
    
    //mvc.mapView.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - kTabBarHeight);
    NSLog(@"TLMV.viewWillAppear: center = %f, %f, last center = %f, %f",mvc.mapView.contents.mapCenter.latitude, mvc.mapView.contents.mapCenter.longitude, lastMapCenter.latitude, lastMapCenter.longitude);
    
    if (mvc.mapView.contents.mapCenter.latitude != lastMapCenter.latitude || mvc.mapView.contents.mapCenter.longitude != lastMapCenter.longitude){
        NSLog(@"TLMV.viewWillAppear: reseting map center");
        [mvc.mapView moveToLatLong:lastMapCenter];
    }
	
	[mvc.mapView.contents.markerManager removeMarker: mvc.destinationMarker];
	
	for (UIView *subview in [self.navigationController.navigationBar subviews]) {
		if (subview.tag > 0) {
			[subview removeFromSuperview];
			NSLog(@"Removing old views from nav controller");
		}
	}
    
    filterPicker.delegate = self;
	
	if (![[self.view subviews] containsObject:mvc.view]) {
		[self.view addSubview:mvc.view];
		[self.view sendSubviewToBack:mvc.view];
	}
	
	[[FilterPicker sharedFilterPicker] hideSorterPicker];

	
	if ([Props global].inTestAppMode && ![[Props global] inLandscapeMode]) [self createSetMapButtons];
	
    
    //*** UPDATE THE DATA AS NECESSARY ***
    
    BOOL refreshData = FALSE;
	
	if([Props global].filters != nil){
		
		[pickerSelectButton update];
        self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
		
		//Set view to show all if the filter is set to favorites and the last favorite was removed
		if(([[EntryCollection sharedEntryCollection] favoritesExist] == FALSE) && [filterCriteria  isEqual: kFavorites]){
			filterCriteria = nil; //kFilterAll;
			[[FilterPicker sharedFilterPicker].theFilterPicker selectRow:0 inComponent:0 animated: NO];
            refreshData = TRUE;
		}
		
		//remove favorites as necessary if they are showing and one was removed in another view
		else if ([[EntryCollection sharedEntryCollection] favoritesExist] && [[[FilterPicker sharedFilterPicker] getPickerTitle]  isEqual: kFavorites]) {
			NSMutableArray *theFavorites = [[NSMutableArray alloc] initWithArray: [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]]];
			
			if ([theFavorites count] != [[EntryCollection sharedEntryCollection].sortedEntries count] ) {
				NSLog(@"TLMV.viewWillAppear: updating entry collection after entry was removed from favorites");
				refreshData = TRUE;
			}
			
		}
		
		else if (filterCriteria != [[FilterPicker sharedFilterPicker] getPickerTitle]) refreshData = TRUE;
        
        filterCriteria = [[FilterPicker sharedFilterPicker] getPickerTitle];
        
		NSLog(@"Filter criteria = %@ and last filter criteria = %@", filterCriteria, lastFilterChoice);
        
        if (filterCriteria != lastFilterChoice || refreshData)[self refreshViewAndData:refreshData];
	}
    
    
    //[globe activateView];
	
    [super viewWillAppear:animated];
	
	NSLog(@"TLMV.viewWillAppear: done!");
}


- (void) viewDidAppear:(BOOL)animated {
	
	mvc.mapView.delegate = self;
	
	[mvc startPulsingUser];
	
	if (!mvc.entriesLoaded && !mvc.entriesLoading) {
        [[MapViewController sharedMVC] performSelectorInBackground:@selector(loadEntries) withObject:nil];
        [self performSelectorInBackground:@selector(showLoadingAnimation) withObject:nil];
        [self performSelectorInBackground:@selector(hideLoadingAnimationWhenLoaded) withObject:nil];
    }
    
    if ([Props global].freemiumType == kFreemiumType_V1 && !upgradePitchHidden && ![Props global].inTestAppMode) [self addOfflineUpgradePitch];
}


- (void) viewWillDisappear:(BOOL)animated {
    
    lastMapCenter = mvc.mapView.contents.mapCenter;
	lastZoomLevel = mvc.mapView.contents.zoom;
	NSLog(@"Last map center.y = %f and zoom level = %f", lastMapCenter.latitude, lastZoomLevel);
    
}


- (void) viewDidDisappear:(BOOL)animated {
	
    if (filterPickerShowing) [self hideFilterPicker:nil];
	[[DataDownloader sharedDataDownloader] resumeDownload];
	[mvc stopPulsingUser];
	
    
    UIView *offlineUpgradeView = [self.view viewWithTag:kOfflineUpgradePitchTag];
    if (offlineUpgradeView != nil && offlineUpgradeView.frame.size.height == 0) upgradePitchHidden = TRUE;
    [offlineUpgradeView removeFromSuperview];
}


- (BOOL)prefersStatusBarHidden {return YES;}


- (void) addOfflineUpgradePitch {
    
    [[self.view viewWithTag:kOfflineUpgradePitchTag] removeFromSuperview];
    
    UpgradePitch *pitch = [[UpgradePitch alloc] initWithYPos:[Props global].titleBarHeight andMessage: @"<a class='SMUpgradeLink' href='SMUpgradeLink://1'>Upgrade</a>&nbsp;for&nbsp;fast&nbsp;offline&nbsp;access"];
    pitch.tag = kOfflineUpgradePitchTag;
    [self.view addSubview:pitch];
}


#pragma mark
#pragma mark Delegate Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
    lastMapCenter = mvc.mapView.contents.mapCenter;
    
    if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) return YES;
    
    else return NO;
}


- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	 lastMapCenter = mvc.mapView.contents.mapCenter;
}


- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
	[mvc.mapView moveToLatLong:lastMapCenter];
	
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
        
        CGRect frame = self.tabBarController.view.frame;
        NSLog(@"TLMV.didRotateFromInterfaceOrientation: frame coordinates = %f, %f, %f, %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
	}
	
    if (filterPickerShowing) [filterPicker viewWillRotate];
    
    if ([Props global].inTestAppMode){
        
        if ([[Props global] inLandscapeMode]) [self.view viewWithTag:kSetMapButtonsTag].hidden = TRUE;
        
        else {
            
            if ([self.view viewWithTag:kSetMapButtonsTag] == nil) [self createSetMapButtons];
            
            [self.view viewWithTag:kSetMapButtonsTag].hidden = FALSE;
        }
    }
    
     if ([Props global].freemiumType == kFreemiumType_V1 && !upgradePitchHidden) [self addOfflineUpgradePitch];
    
     //**[pickerSelectButton resize];
}


- (void) afterMapZoom: (RMMapView*) map byFactor: (float) zoomFactor near:(CGPoint) center {
	
	//NSLog(@"TLMV.afterMapZom: zoom = %f, center.lat = %f, long = %f", mvc.mapView.contents.zoom, mvc.mapView.contents.mapCenter.latitude, mvc.mapView.contents.mapCenter.longitude);
	
	lastZoomLevel = mvc.mapView.contents.zoom;
	lastMapCenter = mvc.mapView.contents.mapCenter;
	
	[mvc afterMapZoom:map byFactor:zoomFactor near:center];
}

/*
- (void) afterMapMove:(RMMapView *)map {

	lastMapCenter = mvc.mapView.contents.mapCenter;
	
	//if ([mvc respondsToSelector:@selector(afterMapMove:)]) [mvc afterMapMove:map];
}*/

- (void) tapOnMarker: (RMMarker*) marker onMap: (RMMapView*) map {
	
	NSLog(@"Marker tapped");
	[mvc tapOnMarker:marker onMap:map withViewRect:CGRectMake(0, kTitleBarHeight, [Props global].screenWidth, [Props global].screenHeight - kTitleBarHeight - kTabBarHeight) fromSender:self];
}


- (void) singleTapOnMap: (RMMapView*) map At: (CGPoint) point {

	[mvc singleTapOnMap:map At:point];
}


- (void) tapOnLabelForMarker: (RMMarker*) marker onMap: (RMMapView*) map onLayer: (CALayer *)layer {
	
	[mvc tapOnLabelForMarker:marker onMap:map onLayer:layer fromSender:self];
}


- (BOOL) shouldMove:(CGSize) delta {

	//NSLog(@"TLMV.shouldMove");
	
	return [mvc shouldMove:delta];
}


- (void) refreshViewAndData:(BOOL) shouldRefreshData {
	
	NSLog(@"TLMV.refreshData: filter = %@", filterCriteria);
	
	if (shouldRefreshData) [[EntryCollection sharedEntryCollection] filterDataTo:filterCriteria];
	
	/*while (!mvc.entriesLoaded) {
		NSLog(@"TLMV.refreshViewAndData: Waiting for entries to finish loading");
		[NSThread sleepForTimeInterval:0.1];
	}*/
    
    if (mvc.entriesLoaded){
	
         @synchronized([Props global].mapDbSync) { //Not actually using the map DB here, but makes more sense than using the entries DB
             for (RMMarker *marker in [mvc.mapView.contents.markerManager markers]){
                 
                 NSNumber *markerIdNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
                 int markerId = [markerIdNumber intValue];
                 Entry *theEntry = [EntryCollection entryById:markerId];
                 
                 if (theEntry != nil){
                     marker.hidden = ![[EntryCollection sharedEntryCollection].sortedEntries containsObject:theEntry];
                 }
             }
         }
    }
	
	else [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshViewAndData:) name:kMapMarkersLoaded object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kEntriesRefreshed object:nil];
	
	NSLog(@"refresh data completes");
}

- (void) goToEntryFromButton:(id) sender {
    
    UIButton *button = (UIButton*) sender;
    
    [self goToEntry:[NSNumber numberWithInt:button.tag]];
}


-  (void) goToEntry:(NSNumber*) theEntryIdObject {
    
    int theEntryId = [theEntryIdObject intValue];
    
	if (theEntryId != kUserLocation && theEntryId != kDestination && theEntryId != kUserLocationBackground) {
        
        //self.tabBarController.view.frame = [[UIScreen mainScreen] bounds];
        self.tabBarController.view.frame = [Props global].isShellApp ? CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight) : [[UIScreen mainScreen] bounds];
        
        LocationViewController *entryController = [[LocationViewController alloc] initWithController: nil];
        Entry *theEntry = [EntryCollection entryById:theEntryId];
        
        entryController.entry = theEntry; 
        [[self navigationController] pushViewController:entryController animated:YES];
        
        //Log event
        SMLog *log = [[SMLog alloc] initWithPageID: kTLMV actionID: kMVGoToEntry];
         log.entry_id = theEntry.entryid;
         [[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
    }
}


- (void) showLoadingAnimation {
	
	//Line below and last line of method are needed to wrap separate thread and create memory pool
	@autoreleasepool {
	
	
		NSString *loadingTagMessage = [Props global].appID == 1 ? @"Loading destinations..." : @"Loading markers...";
		float loadingAnimationSize = 20; //This variable is weird - only sort of determines size at best.
		
		UIFont *errorFont = [UIFont fontWithName: kFontName size: 19];
		CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].rightMargin - [Props global].leftMargin, 19);
    
		CGSize textBoxSize = [loadingTagMessage sizeWithFont: errorFont constrainedToSize: textBoxSizeMax lineBreakMode: UILineBreakModeWordWrap];
		
		float borderWidth = 5; //side of border between background and stuff on inside
		float messageWidth = (loadingAnimationSize + 30 + textBoxSize.width);
		float progressInd_x = ([Props global].screenWidth - messageWidth)/2;
		float progressInd_y = ([Props global].screenHeight - 30 - [Props global].titleBarHeight)/2;
		
		
		UIImage *waitingForAppStoreBackground = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"waitingForAppStoreBackground" ofType:@"png"]];
		
		UIImageView *backgroundHolder = [[UIImageView alloc] initWithImage:waitingForAppStoreBackground];
		
		
    backgroundHolder.alpha = .7;
    backgroundHolder.tag = kLoadingViewTag;
		backgroundHolder.frame = CGRectMake(progressInd_x - borderWidth, progressInd_y - borderWidth, messageWidth + borderWidth*2, loadingAnimationSize + borderWidth*2);
    
		[self.view addSubview: backgroundHolder];
		
		CGRect frame = CGRectMake(progressInd_x, progressInd_y, loadingAnimationSize, loadingAnimationSize);
		UIActivityIndicatorView *progressInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
		
		progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    progressInd.tag = kLoadingViewTag;
    progressInd.alpha = 0.8;
		[progressInd sizeToFit];
		[progressInd startAnimating];
		[self.view addSubview: progressInd];
		
		CGRect labelRect = CGRectMake (progressInd_x + 30, progressInd_y + (loadingAnimationSize - textBoxSize.height)/2, textBoxSize.width, textBoxSize.height);
		
		UILabel *loadingTag = [[UILabel alloc] initWithFrame:labelRect];
		loadingTag.text = loadingTagMessage;
		loadingTag.font = errorFont;
		loadingTag.textColor = [UIColor whiteColor];
		loadingTag.backgroundColor = [UIColor clearColor];
    loadingTag.alpha = 0.7;
    loadingTag.tag = kLoadingViewTag;
		
		[self.view addSubview:loadingTag];
    
	
	}
}


- (void) hideLoadingAnimationWhenLoaded {
    @autoreleasepool {
    
        while (![MapViewController sharedMVC].entriesLoaded) {
            [NSThread sleepForTimeInterval:0.2];
            NSLog(@"TLMV.hideLoadingAnimationWhenLoaded: sleeping...");
        }
        
        [self refreshViewAndData:NO];
        
        [UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[UIView setAnimationDuration: 1.5f ]; 
        
        for (UIView *view in [self.view subviews]) {
           
            if (view.tag == kLoadingViewTag) view.alpha = 0;
        }
        
        [UIView commitAnimations];
        
        [self performSelector:@selector(removeLoadingAnimation) withObject:nil afterDelay:1.5];
    
    }
}


- (void) removeLoadingAnimation {
    @autoreleasepool {
    
        for (UIView *view in [self.view subviews]) {
            
            if (view.tag == kLoadingViewTag) [view removeFromSuperview];
        }
    
    }
}


- (void) showMapAnnotation: (NSNotification*) notification {
    
    //Remove any earlier annotations
    //[self removeMapAnnotations];
    [[NSNotificationCenter defaultCenter] postNotificationName:kRemoveMapAnnotations object:nil];
    
    NSDictionary *info = notification.object;
    int entryid = [[info objectForKey:@"entryid"] intValue];
    Entry *entry = [EntryCollection entryById:entryid];
    
    UIImage *markerImage = entry.iconImage;
    float markerHeight = 50;
    
    float cornerRadius = markerHeight/4;
    
    UIImage *roundedImage = [ImageManipulator makeRoundCornerImage:markerImage :cornerRadius :cornerRadius];
    
    //We hold the button in a view so we can use the map annotation tag to remove it later, but still also have the entry id in the button tag for identification of the entry
    UIView *buttonHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, markerHeight, markerHeight)];
    buttonHolder.center = CGPointMake([Props global].screenWidth/2, ([Props global].screenHeight - kTabBarHeight)/2 - 10);
    buttonHolder.tag = kMapAnnotationTag;
    
    UIButton *marker = [UIButton buttonWithType:UIButtonTypeCustom];
    [marker setImage:roundedImage forState:UIControlStateNormal];
    [marker addTarget:self action:@selector(goToEntryFromButton:) forControlEvents:UIControlEventTouchUpInside];
    marker.tag = entry.entryid;
    marker.frame = CGRectMake(0, 0, markerHeight, markerHeight);
    //marker.center = CGPointMake([Props global].screenWidth/2, ([Props global].screenHeight - kTabBarHeight)/2 - 10);
    marker.alpha = 0;
    marker.layer.shadowColor = [UIColor blackColor].CGColor;
    marker.layer.shadowOffset = CGSizeMake(0, 5);
    marker.layer.shadowOpacity = 0.9;
    marker.layer.shadowRadius = 4.0;
    marker.clipsToBounds = NO;
    marker.transform = CGAffineTransformMakeScale(0.001, 0.001);
    [buttonHolder addSubview:marker];
    [self.view addSubview:buttonHolder];
    
    
    SMMapAnnotation *note = [[SMMapAnnotation alloc] initWithEntry:entry andController:self];
    note.tag = kMapAnnotationTag;
    note.alpha = 0;
    [self.view addSubview:note];
    note.layer.anchorPoint = CGPointMake(0.5, 1);
    note.center = CGPointMake([Props global].screenWidth/2, buttonHolder.center.y - markerHeight/2);
    note.transform = CGAffineTransformMakeScale(0.001, 0.001);
            
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:0.5];
	[UIView setAnimationDuration:0.5];
    
    marker.transform = CGAffineTransformMakeScale(1.0, 1.0);
    marker.alpha = 1.0;
    note.transform = CGAffineTransformMakeScale(1.0, 1.0);
    note.alpha = 1.0;
    
    [UIView commitAnimations];

}


- (void) removeMapAnnotations {
    
    for (UIView *view in [self.view subviews]) {
        
        if (view.tag == kMapAnnotationTag) [view removeFromSuperview];
    }
}


#pragma mark TitleBar Interaction Elements

- (void) showFilterPicker: (id) sender {
	
	filterPickerShowing = TRUE;
	[self.view addSubview: filterPicker];
	[self.view bringSubviewToFront:filterPicker];
	[filterPicker showControls];
	
	lastFilterChoice = [filterPicker getPickerTitle];
	
	self.navigationItem.leftBarButtonItem = pickerSelectButton.cancelBarButton;
}


- (void) hideFilterPicker: (id) sender {
	
	filterPickerShowing = FALSE;
	[filterPicker hideControls];
	
	filterCriteria = [filterPicker getPickerTitle];
	
	[pickerSelectButton update];
	self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
	
	//[self performSelector:@selector(removePickerFromView:) withObject:nil afterDelay:.8];
	
	if([filterCriteria isEqualToString:lastFilterChoice] == FALSE) 
		[self refreshViewAndData:TRUE];
}


- (void) createSetMapButtons {
	
    NSLog(@"TLMV.createSetMapButtons");
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"mapAlertShownFor%i", [Props global].appID]]){
		UIAlertView *setMapAlert = [[UIAlertView alloc] initWithTitle: nil message:@"Use the 'Update Map Area' button to set the default map to the current visible region.\n\nPress 'Hide buttons' to conceal this for a screenshot.\n\n(This alert and the 'Update Map Area' button will not appear to people using your guide.)" delegate:self cancelButtonTitle:@"Got it" otherButtonTitles:nil];
		[setMapAlert show];
		
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:[NSString stringWithFormat:@"mapAlertShownFor%i", [Props global].appID]];
	}
	
	NSArray *segmentTextContent = [NSArray arrayWithObjects:@"Update Map Area", @"Hide buttons",nil];
	
	UISegmentedControl* setMapControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	setMapControl.segmentedControlStyle = UISegmentedControlStyleBar;
	setMapControl.tintColor = [UIColor redColor];
	setMapControl.momentary = TRUE;
	float buttonWidth = 220;
    setMapControl.tag = kSetMapButtonsTag;
	setMapControl.frame = CGRectMake([Props global].screenWidth - buttonWidth - [Props global].tweenMargin, [Props global].titleBarHeight + kTopMargin, buttonWidth, 40);
	setMapControl.alpha = .7;
	[setMapControl addTarget: self action:@selector(toggleMapSettingsActions:) forControlEvents:UIControlEventValueChanged];
	[setMapControl setWidth:130 forSegmentAtIndex:0];
	
	[self.view addSubview:setMapControl];
	
}


- (void)toggleMapSettingsActions:(id)sender {
	
	UISegmentedControl *segControl = sender;
	switch (segControl.selectedSegmentIndex)
	{
		case 0:	{ // Set Map coordinates
			
			if([[Reachability sharedReachability] internetConnectionStatus] != NotReachable) {
				
				NSString *queryString = [NSString stringWithFormat:@"?updatemap=true&appid=%i&lat=%f&long=%f&zoom=%f", [Props global].appID, mvc.mapView.contents.mapCenter.latitude, mvc.mapView.contents.mapCenter.longitude, mvc.mapView.contents.zoom];
				NSString * urlString = [NSString stringWithFormat:@"http://sutroproject.com/admin%@%@", [Props global].adminSuffix, queryString];
				
				NSLog(@"URL string = %@", urlString);
				NSURL *webServiceURL = [NSURL URLWithString:urlString];
				NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:webServiceURL];
				(void) [[NSURLConnection alloc] initWithRequest:req delegate:nil startImmediately:YES];   
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle: nil message:@"Map area set!\nNote that the default map area shown won't exactly match the current area, but it should be close." delegate:self cancelButtonTitle:@"okay" otherButtonTitles:nil];
				[alert show];
			}
			
			else {
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle: nil message:@"Looks like your internet connection isn't working.\nGive it another shot when you've got internet." delegate:self cancelButtonTitle:@"okay" otherButtonTitles:nil];
				[alert show];
			}
			
			break;
		}
			
		case 1: { //hide button
			
			NSLog(@"Time to show message about hiding button");
			[segControl removeFromSuperview];
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle: nil message:@"If you still need to set the default map area, the 'Update Map Area' button will be back next time you return to this view." delegate:self cancelButtonTitle:@"Got it" otherButtonTitles:nil];
			[alert show];
			
			break;
		}	
	}
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


- (void)viewDidUnload {
    [super viewDidUnload];
}


@end
