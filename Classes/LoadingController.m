//
//  LoadingController.m
//  TheProject
//
//  Created by Tobin1 on 7/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LoadingController.h"
#import "Props.h"

#import "EntryCollection.h"
#import "EntriesTableViewController.h"
#import "SlideController.h"
#import "TopLevelMapView.h"
#import "CommentsViewController.h"
#import "MapViewController.h"
#import "FilterPicker.h"
#import "DataDownloader.h"
#import "LocationManager.h"
#import "DealsViewController.h"
#import "MyStoreObserver.h"
#import "Constants.h"


#define kLoadingViewTag 23454
#define kBackgroundViewTag 2397458

@implementation LoadingController

@synthesize homeController; //, tabBarController;


- (id) initWithGuideId:(int)theGuideId  {
    
    NSLog(@"LOADINGCONTROLLER.initWithGuideId: Loading guide %i", theGuideId);
    self = [super init];
	if (self) {

        [EntryCollection resetContent];
        
        [Props global].appID = theGuideId;
        [[Props global] setContentFolder];
        [[Props global] setupPropsDictionary];
        [[EntryCollection sharedEntryCollection] initialize];
        [[FilterPicker sharedFilterPicker] initialize];
        //[[Props global] setupPropsDictionary];
        
        //[self loadGuide];

    }
    return self;
}


- (void)dealloc
{
    NSLog(@"LOADINGCONTROLLER.dealloc***************");
    //[tabBarController release];
}

- (void)didReceiveMemoryWarning
{
  
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)loadView {
	
	NSLog(@"LOADINGCONTROLLER.loadView");
    
	//UIView *contentView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - kTabBarHeight)];
    UIView *contentView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
    contentView.backgroundColor = [UIColor clearColor]; //[UIColor colorWithWhite:0.9 alpha:1.0];
	self.view = contentView;
    
    self.navigationController.navigationBar.alpha = .9;
	self.navigationController.navigationBar.tintColor = [Props global].navigationBarTint;
    self.navigationController.navigationBar.translucent = TRUE;
    
    [self addBackground];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame: self.view.bounds style:UITableViewStylePlain];
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.separatorColor = [UIColor colorWithWhite:0.8 alpha:1.00];
	tableView.delegate = self;
	tableView.dataSource = self;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.alpha = .5;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	tableView.autoresizesSubviews = YES;
    tableView.userInteractionEnabled = FALSE;
    
	[self.view addSubview:tableView];
	
	//NSLog(@"************** CHANGE ME NOT CHECKING FOR IF SAMPLE MESSAGE WAS ALREADY SHOW ********************");
	[Props global].isFreeSample = [[MyStoreObserver sharedMyStoreObserver] isGuideFreeSample:[Props global].appID];
	if ([Props global].isFreeSample && ![[NSUserDefaults standardUserDefaults] boolForKey:@"sample message shown"]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"You can view any five entries from the sample content.\nEnjoy!" delegate: self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
		
		[alert show];
		
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"sample message shown"];
	}
    
    [LocationManager sharedLocationManager]; //init location manager if it hasn't been already
	
	[self loadGuide];
}


- (void) viewDidAppear:(BOOL)animated {
    
    //**[self performSelectorInBackground:@selector(loadGuide) withObject:nil];
    [super viewDidAppear:animated];
    
}

- (void) addBackground {
    
    for (UIView *view in [self.view subviews]) 
        if (view.tag == kBackgroundViewTag) [view removeFromSuperview];
	
	NSString *theFilePath= [NSString stringWithFormat:@"%@/Splash.jpg", [Props global].contentFolder];
    
	UIImage *image;
    float yPos; 
	
	if ([Props global].appID == 1 || ![[NSFileManager defaultManager] fileExistsAtPath:theFilePath]) {
		image = [Props global].deviceType == kiPad ? [UIImage imageNamed:@"Default-Portrait.png"] : [UIImage imageNamed:@"SutroWorld.png"];
        [self createLoadingAnimation];
        
        yPos = [[Props global] inLandscapeMode] ? -120 : [Props global].titleBarHeight; 
	}
	
	else {
       image = [UIImage imageWithContentsOfFile:theFilePath];
        self.navigationController.navigationBarHidden = TRUE;
        
        yPos = 0;
    }
	
    UIImageView *background = [[UIImageView alloc] initWithImage:image];
    float height = [[Props global] inLandscapeMode] ? [Props global].screenWidth * image.size.height/image.size.width : [Props global].screenHeight;
    background.frame = CGRectMake(0,  yPos, [Props global].screenWidth, height);
    background.tag = kBackgroundViewTag;
    
    [self.view insertSubview:background atIndex:0];
}


- (void) removeBackground {
    
    for (UIView *view in [self.view subviews])
        if (view.tag == kBackgroundViewTag) [view removeFromSuperview];
}


- (void) loadGuide {
    
    @autoreleasepool {
    
        NSDate *time = [NSDate date];
        
        NSLog(@"LC.loadGuide.start time = %f", -[time timeIntervalSinceNow]);
        
        [[MapViewController sharedMVC] reset]; //This needs to be after setting up props dictionary, as calling this for the first time before setting the app id causes problems
        [Props global].commentsDatabaseNeedsUpdate = TRUE;
        [Props global].killDataDownloader = FALSE; // might need to throw some sort of wait in here to give this time to do it's thing
        [Props global].dataDownloaderShouldCheckForUpdates = TRUE;
        //[[FilterPicker sharedFilterPicker] resetContent];
        
        //**[[MapViewController sharedMVC] loadEntries]; //This takes a while, but gets messy when done as a background processs
        
        NSLog(@"LC.loadGuide: map icons loaded time = %f", -[time timeIntervalSinceNow]);
        
        NSMutableArray *localViewControllersArray = [[NSMutableArray alloc] initWithCapacity:4];
        
        if (TRUE) {
		
            EntriesTableViewController *theTableViewController = [[EntriesTableViewController alloc] init];
            
		theTableViewController.homeController = self.homeController;
            
		UINavigationController *theNavigationController = [[UINavigationController alloc] initWithRootViewController:theTableViewController];
		[localViewControllersArray addObject:theNavigationController];
		
            
        }
	
        NSLog(@"LC.loadGuide: browse view loaded time = %f", -[time timeIntervalSinceNow]);
        
	if (TRUE) {
            
        SlideController *theSlideController = [[SlideController alloc] init];
            
		UINavigationController *theNavigationController = [[UINavigationController alloc] initWithRootViewController:theSlideController];
		[localViewControllersArray addObject:theNavigationController];
		
	}
        
        NSLog(@"LC.loadGuide: slide show loaded time = %f", -[time timeIntervalSinceNow]);
        
	// repeat the process for Maps
	if ([Props global].hasLocations) {
		
		TopLevelMapView * mapView = [[TopLevelMapView alloc] init];
		
		UINavigationController *theNavigationController = [[UINavigationController alloc] initWithRootViewController:mapView];
		[localViewControllersArray addObject:theNavigationController];
            
	}	
	
        NSLog(@"LC.loadGuide: map loaded time = %f", -[time timeIntervalSinceNow]);
	// repeat the process for Comments
	if ([Props global].showComments) {
		
		CommentsViewController *theCommentsViewController = [[CommentsViewController alloc] init];
		UINavigationController *theNavigationController = [[UINavigationController alloc] initWithRootViewController:theCommentsViewController];
		[localViewControllersArray addObject:theNavigationController];
		
	}	
        
        //Deals
        if ([Props global].hasDeals) {
		
		DealsViewController *theDealsViewController = [[DealsViewController alloc] init];
		UINavigationController *theNavigationController = [[UINavigationController alloc] initWithRootViewController:theDealsViewController];
		[localViewControllersArray addObject:theNavigationController];
		
	}	
        
        
        self.tabBarController.viewControllers = localViewControllersArray;
        
        
        [self performSelectorInBackground:@selector(downloadData) withObject:nil];
 
        //NSLog(@"LOADINGCONTROLLER.loadGuide: retain count for ETVC = %i", [[self.tabBarController.viewControllers objectAtIndex:0] retainCount]);
        //NSLog(@"LOADINGCONTROLLER.loadGuide: retain count for TLSC = %i", [[self.tabBarController.viewControllers objectAtIndex:1] retainCount]);
        
        NSLog(@"LC.loadGuide: done time = %f", -[time timeIntervalSinceNow]);
        
        //[[NSNotificationCenter defaultCenter] postNotificationName:kCatalogLoadedNotification object:nil];
        
        //[self removeBackground];
    }
}


- (void) downloadData {
	
	@autoreleasepool {
    
		[[DataDownloader sharedDataDownloader] initializeDownloader]; 
	
	}
}


- (void) createLoadingAnimation {
	
	//Line below and last line of method are needed to wrap separate thread and create memory pool
	@autoreleasepool {
    
        for (UIView *view in [self.navigationController.view subviews]) {
            
            if (view.tag == kLoadingViewTag) [view removeFromSuperview];
        }
	
        UIView *loadingView = [[UIView alloc] init];
        loadingView.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].titleBarHeight);
        loadingView.tag = kLoadingViewTag;
        
	float loadingAnimationSize = 21; //This variable is weird - only sort of determines size at best.
	NSString *loadingTagMessage = [Props global].appID == 1 ? @"Loading Guide Catalog" : [NSString stringWithFormat:@"Loading %@...", [Props global].appName];
        
	UIFont *errorFont = [UIFont fontWithName: kFontName size: 16];
	CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin - loadingAnimationSize + [Props global].leftMargin, [Props global].titleBarHeight);
	CGSize textBoxSize = [loadingTagMessage sizeWithFont: errorFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
        
        CGRect labelRect = CGRectMake ([Props global].leftMargin + loadingAnimationSize + [Props global].rightMargin + ([Props global].screenWidth - textBoxSize.width - (loadingAnimationSize + [Props global].rightMargin) - [Props global].leftMargin - [Props global].rightMargin)/2, ([Props global].titleBarHeight - textBoxSize.height)/2, textBoxSize.width, textBoxSize.height);
        
	UILabel *loadingTag = [[UILabel alloc] initWithFrame:labelRect];
	loadingTag.text = loadingTagMessage;
	loadingTag.font = errorFont;
	loadingTag.textColor = [UIColor colorWithWhite:0.99 alpha:0.99];
	loadingTag.lineBreakMode = 0;
	loadingTag.numberOfLines = 2;
	loadingTag.shadowColor = [UIColor darkGrayColor];
	loadingTag.shadowOffset = CGSizeMake(1, 1);
	loadingTag.backgroundColor = [UIColor clearColor];
	
	[loadingView addSubview:loadingTag];
	
	float progressInd_x = labelRect.origin.x - [Props global].rightMargin - loadingAnimationSize;
	float progressInd_y = (loadingView.frame.size.height - loadingAnimationSize)/2;
	
	CGRect frame = CGRectMake(progressInd_x, progressInd_y, loadingAnimationSize, loadingAnimationSize);
	
	UIActivityIndicatorView *progressInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
        
	progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        progressInd.alpha = .90;
	[progressInd sizeToFit];
	[progressInd startAnimating];
	[loadingView addSubview: progressInd];
        
        [self.navigationController.view addSubview:loadingView];
        
	
	}
}

/*
- (void) removeLoadingAnimation {
	
	[loadingTag removeFromSuperview];
	[progressInd removeFromSuperview];
}
 */


#pragma
#pragma TABLEVIEW DATASOURCE METHODS

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"]; //TF - 081610, addded autorelease - might create an issue
        cell.accessoryType = UITableViewCellAccessoryNone;
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[Props global].LVBGView];
        backgroundImageView.frame = CGRectMake(0,0, [Props global].screenWidth, [Props global].tableviewRowHeight);
        backgroundImageView.alpha = .90;
        cell.opaque = NO;
        cell.backgroundView = backgroundImageView;
    }
	
	return cell; //[cell autorelease]; //TF 102209}
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView  {
    
	return 1;
}



- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section {
	// ask for, and return, the number of entries in the current selection
    
	return [Props global].deviceType == kiPad ? 24 : 10;
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
		[self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
	}
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    [self addBackground];
}

/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}*/

@end
