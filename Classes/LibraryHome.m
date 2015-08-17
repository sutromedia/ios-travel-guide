//
//  LibraryHome.m
//  TheProject
//
//  Created by Tobin1 on 5/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LibraryHome.h"
#import "Entry.h"
#import "EntryCollection.h"
#import "LibraryCell.h"
#import "EntriesTableViewController.h"
#import "SlideController.h"
#import "TopLevelMapView.h"
#import "TopLevelMapView.h"
#import "CommentsViewController.h"
#import "MapViewController.h"
#import "FilterPicker.h"
#import "DataDownloader.h"
#import "GuideDownloader.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import	"MyStoreObserver.h"
#import <StoreKit/StoreKit.h>
#import "LoadingController.h"
#import "TutorView.h"
#import "ZipArchive.h"
#import "Reachability.h"
#import "ASIHTTPRequest.h"

#import "LocationViewController.h"

#define kBackgroundViewTag 13245
#define kLoadingViewTag 34564345
#define kTutorViewTag   90782345
#define kSyncAlertTag   32453426
#define kVersionAlertTag 22
#define kViewPartiallyDownloadedGuideAlert 2345445

@interface LibraryHome (Private)

- (void) runOpeningTutorial;
- (void) appJustOpened;
- (void) runOpeningSequence;
- (void) addGuideView;
- (void) addGoToGuidesButton;
- (Entry *)entryForIndexPath:(NSIndexPath *)indexPath;
- (void) checkForUpdates;
- (BOOL) isGuideBeingDownloaded: (int) guideId;
- (void) updateWaitStatuses;
- (void) goToGuide:(int) guideId withRect:(CGRect) guideRect;
- (void) addBackground;
- (void) updateLibraryListHeight;
- (void) checkIfAppUpdateIsAvailable;
- (void) updateContentDatabase;
- (void) checkForSoftwareUpdate;

@end

@implementation LibraryHome


@synthesize libraryList;


- (id) init {
    
    //NSLog(@"LIBRARYHOME.init");
    
    self = [super init];
    if (self) {
        
        //self.view.autoresizesSubviews = FALSE;
        
        displayedGuides = [NSMutableArray new];
        guideDownloaders = [NSMutableDictionary new];
        
        NSString *theFilePath = [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].cacheFolder];
        guidesDB = [[FMDatabase alloc] initWithPath:theFilePath];
        if (![guidesDB open]) NSLog(@"GUIDEDOWNLOADER - Error opening database");
        
        NSLog(@"Registering observer with payment queue");
		//[[SKPaymentQueue defaultQueue] addTransactionObserver:[MyStoreObserver sharedMyStoreObserver]];
        
        [Props global].isShellApp = TRUE;
        
        //Move purchased guides database from main bundle to documents folder so we can write to it later
        //CREATE table guides (guideid INT NOT NULL, status INT, purchase_date DATETIME, PRIMARY KEY (guideid))
        NSString *purchasedGuidesDBFilePath= [NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:purchasedGuidesDBFilePath]) {
            
            NSLog(@"LIBRARYHOME.init: Moving purchased guides database from resource bundle to docs directory");
            
            NSError *theError = nil;
            if (![[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"purchased_guides" ofType:@"sqlite3"] toPath: purchasedGuidesDBFilePath error:&theError]) NSLog(@"LIBRARYHOME.init: ERROR MOVING purchased guides DATABASE to %@ with error %@-  **************************************************", purchasedGuidesDBFilePath, [theError description]);
        }
		
		else {
			//Need to figure out if the database has the new samples column
			FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder]];
			if (![db open]) NSLog(@"ERROR: LIBRARYHOME.checkForUpdates: Can't open purchased guides database *************************************");
			
			@synchronized ([Props global].dbSync) {
				
				BOOL needToAddisSampleColumn = FALSE;
				
				@try {
					FMResultSet *rs = [db executeQuery:@"SELECT is_sample FROM guides"];
					
					if (![rs next]) {
						NSLog(@"Need to add isSample column");
						needToAddisSampleColumn = TRUE;
					}
					
					[rs close];
				}
				@catch (NSException *exception) {
					needToAddisSampleColumn = TRUE;
				}
				@finally {
					//Nothing to do here
				}
				
				if (needToAddisSampleColumn) {
					[db executeUpdate:@"BEGIN TRANSACTION"];
					[db executeUpdate:@"ALTER table guides ADD COLUMN is_sample int"];
					[db executeUpdate:@"END TRANSACTION"];
					
					[db executeUpdate:@"BEGIN TRANSACTION"];
					[db executeUpdate:@"ALTER table guides ADD COLUMN archived int"];
					[db executeUpdate:@"END TRANSACTION"];
				}
			}
			
			[db close];
		}
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateWaitStatuses:) name:kUpdateWaitStatuses object:nil];
        
        [self appJustOpened]; //We need to call this in addition to register for notifications, as by the time this object is getting inited it has already missed the notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appJustOpened) name:UIApplicationWillEnterForegroundNotification object:nil]; //Register for notification so we check for updates on restarts
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exploreGuides) name:kExploreGuidesNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGuides) name:kRefreshLibraryHome object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteGuide:) name:kDeleteGuide object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDownloadProblemsAlert) name:kDownloadProblems object:nil];
		
	}
    
    return self;
}


- (void) appJustOpened {
    
    NSLog(@"LIBRARYHOME.appJustOpened");
    needToRunOpeningSequence = TRUE;
    if([guideDownloaders count] > 0) [self runOpeningSequence];
}




- (void)loadView {
    
    //NSLog(@"LIBRARYHOME.loadView");

    NSLog(@"Content folder = %@", [Props global].contentFolder);
    
    //[[UIApplication sharedApplication] setStatusBarHidden:FALSE withAnimation: UIStatusBarAnimationNone];
    
    UIView *contentView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
	self.view = contentView;
    self.view.backgroundColor = [UIColor blackColor];
    
    [self addGoToGuidesButton];
    
    [self addSyncButton];
    
    [self addGuideView];
    
	
    //NSLog(@"************* WARNING: SET TO ALWAYS SHOW TUTOR VIEW ***********************");
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HomeViewTutorialShown"] && ![[Props global] inLandscapeMode]) {
		//NSLog(@"LIBARYHOME.loadView:about to add tutorial");
        
		TutorView *tutorView = [[TutorView alloc] init];
		tutorView.tag = kTutorViewTag;
		[self.view addSubview:tutorView];
        [tutorView startAnimation];
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"HomeViewTutorialShown"];
	}
}


- (void)viewWillAppear:(BOOL)animated {
    
    NSLog(@"LIBRARYHOME.viewWillAppear idle timer is %@", [UIApplication sharedApplication].idleTimerDisabled ? @"disabled" : @"not disabled");
    [[UIApplication sharedApplication] setStatusBarHidden:FALSE withAnimation: UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:FALSE animated:FALSE];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.alpha = 0.75;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:(42.0/255.0) green:(42.0/255.0) blue:(50.0/255.0) alpha:1.0];// [UIColor colorWithWhite:0.5 alpha:0.5];
    //self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:(220.0/255.0) green:(218.0/255.0) blue:(213.0/255.0) alpha:1.0];

    [Props global].killDataDownloader = TRUE;
    NSLog(@"LIBRARYHOME.viewWillAppear: kill dd = %@",  [Props global].killDataDownloader ? @"TRUE" : @"FALSE");
    
	if ([Props global].appID != 1) {
		[EntryCollection resetContent];
		[Props global].appID = 1;
		[[Props global] setContentFolder];
		[[Props global] setupPropsDictionary];
	}
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:kResumeGuideDownload object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSetGuideDownloadToFast object:nil];
    [self checkForUpdates];
           
    [self addBackground]; // re-add the background in case the view was rotated elsewhere
    //libraryList.frame = CGRectMake(0, [Props global].titleBarHeight, libraryList.frame.size.width, libraryList.frame.size.height);
    //self.libraryList.frame = CGRectMake(0, [Props global].titleBarHeight, [Props global].screenWidth, libraryList.frame.size.height);
    
    BOOL paused = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, guideID]];
    
    if (!paused) {
        NSNumber *guide = [NSNumber numberWithInt:guideID];
        [[NSNotificationCenter defaultCenter] postNotificationName:kResumeGuideDownload object:guide];
    }
	
	/*for (UIView *view in [self.view subviews]) {
		if (view.tag == kLoadingViewTag) [view removeFromSuperview];
	}*/
	
    [super viewWillAppear:animated];
}


- (void) runOpeningSequence {
    
    if ([Props global].connectedToInternet) {
        //[self performSelectorInBackground:@selector(checkForContentUpdate) withObject:nil];
        [self checkForSoftwareUpdate];
        
        for (GuideDownloader *loader in [guideDownloaders allValues]) {
            [loader performSelectorInBackground:@selector(checkForContentUpdate) withObject:nil];
        }
    }
        
    needToRunOpeningSequence = FALSE;
}


- (void) viewDidAppear:(BOOL)animated {
	
	[self updateGuideDownloaders];
}

   
- (void) addGuideView {
    
    if (libraryList != nil) [libraryList removeFromSuperview];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame: CGRectZero style:UITableViewStylePlain];
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.separatorColor = [UIColor grayColor];
    tableView.delegate = self;
	tableView.dataSource = self;
	tableView.sectionIndexMinimumDisplayRowCount = 10;
    tableView.backgroundColor = [UIColor clearColor];
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	tableView.autoresizesSubviews = YES;
    tableView.scrollEnabled = FALSE;
	self.libraryList = tableView;
	[self.view insertSubview:libraryList atIndex:1];
}


- (void) addGoToGuidesButton {
    
    UIBarButtonItem *appBarButton = [[UIBarButtonItem alloc] initWithTitle:@"  Explore Guides  " style:UIBarButtonItemStylePlain target:self action:@selector(exploreGuides)];

	self.navigationItem.rightBarButtonItem = appBarButton;
}


- (void) addSyncButton {
    
    UIBarButtonItem *appBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Restore purchases" style:UIBarButtonItemStylePlain target:self action:@selector(syncGuides)];
    
	self.navigationItem.leftBarButtonItem = appBarButton;
    
}

/*- (void) addBottomToolbar {
    
    //UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 150, [Props global].titleBarHeight * .4)];
    //UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 100, 45)];
    //[toolbar setBarStyle:UIBarStyleBlackTranslucent];
    //toolbar.alpha = 0.1;
    
    NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:2];
    
    NSArray *sortOptions = [NSArray arrayWithObjects:@"By date", @"By name", nil];
    UISegmentedControl *sortController = [[UISegmentedControl alloc] initWithItems:sortOptions];
    //sortController.

    UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithCustomView:sortController];
    //sortButton.style = UI
    [buttons addObject:sortButton];
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editGuides)];
    [buttons addObject:editButton];
    
    //[toolbar setItems:buttons animated:NO];
    
	//self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
    
    [self setToolbarItems:buttons];
    
    self.navigationController.toolbar.tintColor = [UIColor blackColor];
    self.navigationController.toolbar.translucent = YES;   
    
    [self.navigationController setToolbarHidden:NO animated:NO];
}*/


/*- (void) addLeftToolbar {
    
    //UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 150, [Props global].titleBarHeight * .4)];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 100, 45)];
    [toolbar setBarStyle:UIBarStyleBlackTranslucent];
    toolbar.alpha = 0.1;
    
    NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:2];
    
    UIBarButtonItem *restoreButton = [[UIBarButtonItem alloc] initWithTitle:@"Sync" style:UIBarButtonItemStyleBordered target:self action:@selector(syncGuides)];
    [buttons addObject:restoreButton];
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editGuides)];
    [buttons addObject:editButton];
    
    [toolbar setItems:buttons animated:NO];
    
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
    
}*/

/*
- (void) addLeftToolbar {
    
    UIView *buttonHolder = [[UIView alloc] init];
    float buttonHeight = [Props global].titleBarHeight * .7;
    UIFont *buttonFont = [UIFont boldSystemFontOfSize:13];
    
    UIButton *syncButton = [UIButton buttonWithType:0];
    [syncButton setTitle:@"Sync" forState:UIControlStateNormal];
    [syncButton.titleLabel setFont:buttonFont];
    syncButton.frame = CGRectMake(0,([Props global].titleBarHeight - buttonHeight)/2,50,buttonHeight);
    [buttonHolder addSubview:syncButton];
    
    UIButton *editButton = [UIButton buttonWithType:0];
    [editButton setTitle:@"Edit" forState:UIControlStateNormal];
    [editButton addTarget:self action:@selector(editGuides) forControlEvents:UIControlEventTouchUpInside];
    [editButton.titleLabel setFont:buttonFont];
    editButton.frame = CGRectMake(CGRectGetMaxX(syncButton.frame) + 5,([Props global].titleBarHeight - buttonHeight)/2,50,buttonHeight);
    [buttonHolder addSubview:editButton];
    
    buttonHolder.frame = CGRectMake(0,0,CGRectGetMaxX(editButton.frame),[Props global].titleBarHeight);
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:buttonHolder];
}
*/

- (void) editGuides {
    
    NSLog(@"Time to edit guides");
}


- (void) exploreGuides {
    
    TutorView *tutorview = (TutorView*) [self.view viewWithTag:kTutorViewTag];
	
	if (tutorview != nil) {[tutorview hide]; [tutorview removeFromSuperview];} 
    
    if (sw_downloader == nil) sw_downloader = [[GuideDownloader alloc] initWithGuideId:1];
    
	guideID = 1;
    [self goToGuide:1 withRect:CGRectMake([Props global].screenWidth - 100, 0, 100, [Props global].titleBarHeight)];
}


- (void) goToGuide:(int) guideId withRect:(CGRect)guideRect {
    
	//**[[UIApplication sharedApplication] setStatusBarHidden:TRUE withAnimation:UIStatusBarAnimationNone];
    //[[NSNotificationCenter defaultCenter] postNotificationName:kPauseGuideDownload object:nil];
    
    @autoreleasepool {
    
        
        //self.navigationController.view.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
		
		UIView *fullBackground = [[UIView alloc] initWithFrame:CGRectMake(0,  0, [Props global].screenWidth, [Props global].screenHeight)];
		fullBackground.backgroundColor = [UIColor blackColor];
		fullBackground.alpha = 0.0;
		fullBackground.tag = kLoadingViewTag;
		[self.view addSubview:fullBackground];
		
        NSString *theFilePath= [NSString stringWithFormat:@"%@/%i/Splash.jpg", [Props global].cacheFolder, guideId];
        
        UIImage *image;
        
        if (guideId == 1 || ![[NSFileManager defaultManager] fileExistsAtPath:theFilePath]) {
            image = [Props global].deviceType == kiPad ? [UIImage imageNamed:@"Default-Portrait.png"] : [UIImage imageNamed:@"SutroWorld.png"];
            //[self createLoadingAnimation];
        }
        
        else {
            image = [UIImage imageWithContentsOfFile:theFilePath];
        }
			
		CGRect startRect = guideID == 1 ? guideRect : CGRectMake(0,libraryList.frame.origin.y + guideRect.origin.y, guideRect.size.height, guideRect.size.height);
		
		UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
		imageView.frame = CGRectMake(0,0, startRect.size.width, startRect.size.height);
		
		UIView *background = [[UIView alloc] initWithFrame:startRect];
		background.tag = kLoadingViewTag;
		[background setBackgroundColor:[UIColor blackColor]];
		[background addSubview:imageView];
		
		background.frame = startRect;
		background.alpha = 0;
		
		float ind_height = 42;
		UIActivityIndicatorView *progressInd = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, ind_height, ind_height)];
		progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
		[progressInd sizeToFit];
		progressInd.center = CGPointMake(background.frame.size.width/2, background.frame.size.height/2);
		[progressInd startAnimating];
		[background addSubview:progressInd];
		
		[self.view addSubview:background];
		
		[[UIApplication sharedApplication] setStatusBarHidden:TRUE withAnimation:UIStatusBarAnimationNone];
		self.navigationController.navigationBarHidden = TRUE;
		
		[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
		[ UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
		[ UIView setAnimationDuration: 0.5 ]; // Set the duration
		[UIView setAnimationDelegate:self];
		//[UIView setAnimationDidStopSelector:@selector(actuallyLoadGuide)];
		
		float width = [[Props global] inLandscapeMode] ? [Props global].screenHeight/image.size.height * image.size.width : [Props global].screenWidth;
		background.frame = CGRectMake(0,  0, [Props global].screenWidth, [Props global].screenHeight);
		imageView.frame = CGRectMake(([Props global].screenWidth - width)/2, 0, width, [Props global].screenHeight);
		background.alpha = 1.0;
		fullBackground.alpha = 1.0;
		progressInd.center = CGPointMake(background.frame.size.width/2, background.frame.size.height/2);
		
		[UIView commitAnimations];
		
		[self performSelectorInBackground:@selector(actuallyLoadGuide) withObject:nil];
		
		

        /*
        NSMutableArray *localViewControllersArray = [[NSMutableArray alloc] initWithCapacity:1];
        
        UITabBarController *tabBarController = [[UITabBarController alloc] init];
        //tabBarController.view.frame = CGRectMake(0,0, [Props global].screenWidth, [Props global].screenHeight + kTabBarHeight);
        
        LoadingController *loadingController = [[LoadingController alloc] initWithGuideId:guideId];
        loadingController.homeController = self.navigationController;
        UINavigationController *theNavigationController = [[UINavigationController alloc] initWithRootViewController:loadingController];
        [localViewControllersArray addObject:theNavigationController];
        
        tabBarController.viewControllers = localViewControllersArray;
        
        [self.navigationController setNavigationBarHidden:TRUE animated:FALSE];
        //self.navigationController.view.frame = CGRectMake(0,0, [Props global].screenWidth, [Props global].screenHeight + kTabBarHeight);
        NSLog(@"About to push view 2 through %@", self.navigationController);
		
		[self.navigationController pushViewController:tabBarController animated:YES];
        //[loadingView.navigationController pushViewController:tabBarController animated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kSetGuideDownloadToSlow object:nil];
        
        GuideDownloader *downloader = [guideDownloaders objectForKey:[NSNumber numberWithInt:guideId]];
        [downloader getMaxThumbnailPhotos];
		[downloader updateContent];*/
		 
    }
}


- (void) actuallyLoadGuide {
	
	NSMutableArray *localViewControllersArray = [[NSMutableArray alloc] initWithCapacity:1];
	
	UITabBarController *tabBarController = [[UITabBarController alloc] init];
	
	LoadingController *loadingController = [[LoadingController alloc] initWithGuideId:guideID];
	loadingController.homeController = self.navigationController;
	UINavigationController *theNavigationController = [[UINavigationController alloc] initWithRootViewController:loadingController];
	[localViewControllersArray addObject:theNavigationController];
	
	tabBarController.viewControllers = localViewControllersArray;
	
	[self.navigationController setNavigationBarHidden:TRUE animated:FALSE];
	
	for (UIView *view in [self.view subviews]) {
		if (view.tag == kLoadingViewTag) [view removeFromSuperview];
	}
	
	[self.navigationController pushViewController:tabBarController animated:NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kSetGuideDownloadToSlow object:nil];
	
	GuideDownloader *downloader = [guideDownloaders objectForKey:[NSNumber numberWithInt:guideID]];
	[downloader getMaxThumbnailPhotos];
	[downloader updateContent];
}


- (void) updateGuides {
	
	[self checkForUpdates];
	[self updateGuideDownloaders];
}


- (void) checkForUpdates {
    
    NSLog(@"LIBRARYHOME.checkforUpdates");
    
    [displayedGuides removeAllObjects];
    
    FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder]];
    if (![db open]) NSLog(@"ERROR: LIBRARYHOME.checkForUpdates: Can't open purchased guides database *************************************");
    
    @synchronized ([Props global].dbSync) {
    
        FMResultSet *rs = [db executeQuery:@"SELECT guideid FROM guides WHERE purchase_date NOT NULL AND (archived < 1 OR archived IS NULL) ORDER BY purchase_date DESC"];
        
        while ([rs next]) {
            NSNumber *purchasedGuide = [NSNumber numberWithInt:[rs intForColumn:@"guideid"]];
            [displayedGuides addObject:purchasedGuide];
        }
        
        [rs close];
    }
    
    [db close];
    
    [self updateLibraryListHeight];
    
    [libraryList reloadData];
    
    if (needToRunOpeningSequence) [self runOpeningSequence];
}


- (void) updateGuideDownloaders {
	
	for (NSNumber *guide in displayedGuides) {
        
		int guideId = [guide intValue];
        
        if ([guideDownloaders objectForKey:[NSNumber numberWithInt:guideId]] == nil) {
			
            NSDictionary *theStatus = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, guideId]];
            
            int downloadStatus = [[theStatus objectForKey:@"summary"] intValue];
            
            //Have the SF Explorer download paused by default...
            if (guideId == 3 && downloadStatus == kDownloadNotStarted) {
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kPauseGuideDownload object:[NSNumber numberWithInt:3]];
                [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, 3]];
            }
            
            GuideDownloader *downloader = [[GuideDownloader alloc] initWithGuideId:guideId];
            if (downloadStatus < kReadyForViewing)[downloader performSelectorInBackground:@selector(downloadBaseContent) withObject:nil];
            [guideDownloaders setObject:downloader forKey:[NSNumber numberWithInt:guideId]];
        }
    }
}


- (void) syncGuides {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Would you like to sync previously purchased guides now?"  delegate: self cancelButtonTitle:@"No thanks" otherButtonTitles:@"Okay!", nil];
    alert.tag = kSyncAlertTag;
    [alert show];  
}


-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
    
    if (theAlert.tag == kSyncAlertTag && buttonIndex != 0) 
        [[NSNotificationCenter defaultCenter] postNotificationName:kLookForPreviouslyPurchasedGuides object:nil];
    
    else if (theAlert.tag == kVersionAlertTag && buttonIndex != 0) [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[Props global].appLink]];
}


- (void) updateLibraryListHeight {
    
    float height = [displayedGuides count] * [Props global].tableviewRowHeight_libraryView; //[libraryList.delegate heightForRowAtIndexPath:nil];
    
    float maxHeight = [Props global].screenHeight - [Props global].titleBarHeight - 20;
    
    if (height > maxHeight) {
        height = maxHeight;
        NSLog(@"Setting height to max height of %f", maxHeight);
        libraryList.scrollEnabled = TRUE;
    }
    
    else libraryList.scrollEnabled = FALSE;
    
    libraryList.frame = CGRectMake(libraryList.frame.origin.x, [Props global].titleBarHeight, [Props global].screenWidth, height);
}


- (BOOL) isGuideWaiting:(int) theGuideId {
    
    NSLog(@"LIBRARYHOME.isGuideWaiting: %i", theGuideId);
    
    for (GuideDownloader *downloader in [guideDownloaders allValues]) {
        if (downloader.guideId == theGuideId){
            NSLog(@"LIBRARYHOME.isGuideWaiting: %i is%@ waiting", theGuideId, downloader.waiting ? @"": @" not");
            return downloader.waiting;
        }
    }
    
    return FALSE;
}

- (void) deleteGuide:(NSNotification *) notification {

    int theGuideID = [notification.object intValue];
    
    [[MyStoreObserver sharedMyStoreObserver] deleteOrArchiveGuide:theGuideID];
    
	//Remove from the displayed guides list
	int objectIndex = [displayedGuides indexOfObject:[NSNumber numberWithInt:theGuideID]];
	[displayedGuides removeObjectAtIndex:objectIndex];
	
	NSArray *deleteIndexPaths = [[NSArray alloc] initWithObjects:
								 [NSIndexPath indexPathForRow:objectIndex inSection:0],
								 nil];
	
	[libraryList beginUpdates];
	[libraryList deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
	[libraryList endUpdates];
	
	[self updateLibraryListHeight];
    
    //Show pop-up explaining how to unarchive a guide
    
    if (![[MyStoreObserver sharedMyStoreObserver] isGuideFreeSample:theGuideID] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"shown archived guides explanation"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You can restore archived guides by going to \"Explore Guides\" and tapping \"Unarchive\" on the archived guide's page." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        alert.tag = kVersionAlertTag;
        [alert show];
        
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"shown archived guides explanation"];
    }
    
			
	//Delete content and get rid of the data downloader
	GuideDownloader *guideDownloaderToRemove = [guideDownloaders objectForKey:[NSNumber numberWithInt:theGuideID]];
	guideDownloaderToRemove.shouldStop = TRUE;
    [guideDownloaderToRemove removeAllContent];
	[guideDownloaders removeObjectForKey:[NSNumber numberWithInt:theGuideID]];
}


/*- (void) successfulDownload:(NSNotification*) theNotification {
    
    int theGuideId = [theNotification.object intValue];
    
    GuideDownloader *oneToRemove = nil;
    
    for (GuideDownloader *downloader in guideDownloaders) {
        if (downloader.guideId == theGuideId) {
            oneToRemove = downloader;
            NSLog(@"LIBRARYHOME.downloadSuccessful: removing %i", theGuideId);
        }
    }
    
    if (oneToRemove != nil) [guideDownloaders removeObject:oneToRemove];
}*/


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

//************ Checks server to see if more recent version of the software is available
#pragma mark
#pragma Software Updates

- (void) checkForSoftwareUpdate {
    
    NSLog(@"LIBRARYHOME.checkForSoftwareUpdate");
    
    //Get the data
    NSURL *dataURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/sutro-world-minimum-bundle-version.txt", [Props global].serverDatabaseUpdateSource]];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:dataURL];
    [request setDelegate:self];
    [request startAsynchronous];
}


- (void)requestFinished:(ASIHTTPRequest *)request {
    
    NSString *versionString = [[NSString alloc] initWithData:[request responseData] encoding:NSUTF8StringEncoding];
    NSArray *versionArray = [versionString componentsSeparatedByString:@"Version="];
    int latestVersionNumber = [[versionArray lastObject] intValue];
    
    NSLog(@"EAD.requestFinished: Check for software update - Latest version = %i and this version = %i", latestVersionNumber, [Props global].bundleVersion);
    
    if (latestVersionNumber > [Props global].bundleVersion) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Looks like your version of Sutro World is out of date" message:@"Click 'Update' below to go off to the App Store to get the latest and greatest." delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Update", nil];
        alert.tag = kVersionAlertTag;
        [alert show];
    }
}


- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"ENTRIESAPPDELEGATE.requestFailed: error = %@", [[request error] description]);
}


#pragma
#pragma View Rotation Methods

//Depricated
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
	//NSLog(@"ETVC.shouldAutorotateToInterfaceOrientation %i", interfaceOrientation);
    
    if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        
        return YES;
    }
    
    else return NO;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	if (toInterfaceOrientation != UIDeviceOrientationFaceUp && toInterfaceOrientation != UIDeviceOrientationFaceDown && toInterfaceOrientation != UIDeviceOrientationUnknown) {
        
        [[Props global] updateScreenDimensions: toInterfaceOrientation];
		
		TutorView *tutorview = (TutorView*) [self.view viewWithTag:kTutorViewTag];
		
		if (tutorview != nil) {[tutorview hide]; [tutorview removeFromSuperview];}
	}
}





- (BOOL) shouldAutorotate {
    
    return YES;
}


- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    [self addBackground];
    //[self addGuideView];
    [self updateLibraryListHeight];
    
    //libraryList.frame = CGRectMake(0, [Props global].titleBarHeight, libraryList.frame.size.width, libraryList.frame.size.height);
}


- (void) addBackground {
    
    for (UIView *view in [self.view subviews]) 
       if (view.tag == kBackgroundViewTag) [view removeFromSuperview];
    
    UIImage *image = [Props global].deviceType == kiPad ? [UIImage imageNamed:@"Default-Portrait.png"] : [UIImage imageNamed:@"SutroWorld.png"];
    UIImageView *background = [[UIImageView alloc] initWithImage:image];
    float height = [[Props global] inLandscapeMode] ? [Props global].screenWidth * image.size.height/image.size.width : [Props global].screenHeight;
    float yPos = [[Props global] inLandscapeMode] ? -120 : -[UIApplication sharedApplication].statusBarFrame.size.height; 
    background.frame = CGRectMake(0,  yPos, [Props global].screenWidth, height);
    background.tag = kBackgroundViewTag;
    
    [self.view insertSubview:background atIndex:0];
}


#pragma
#pragma TABLEVIEW DELEGATE METHODS
// the user selected a row in the table.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	
	NSLog(@"LIBRARYDATASOURCE.tableView:didSelectRowAtIndexPath:");
    guideID = [[displayedGuides objectAtIndex: newIndexPath.row] intValue];
    
    NSDictionary *theStatus = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, guideID]];
    
    int downloadStatus = [[theStatus objectForKey:@"summary"] intValue];
    
    NSLog(@"LIBRARYDATASOURCE.tableView:didSelectRowAtIndexPath:Download status for %i = %i", guideID, downloadStatus);
    
    if (downloadStatus == kDownloadComplete) {
		//CGRect guideRect = [tableView rectForRowAtIndexPath:newIndexPath];
		CGRect guideRect = [tableView convertRect:[tableView rectForRowAtIndexPath:newIndexPath] toView:[tableView superview]];
		[self goToGuide:guideID withRect:guideRect];
	}
    
    else NSLog(@"LIBRARYDATASOURCE.tableView:didSelectRowAtIndexPath: download not yet complete");
    
    [tableView deselectRowAtIndexPath:newIndexPath animated:NO];
}


- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath*) indexPath {

    return [Props global].tableviewRowHeight_libraryView;
}


#pragma
#pragma TABLEVIEW DATASOURCE METHODS

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
   //NSLog(@"LIBRARYHOME.tableView:cellForRowAtIndexPath:");
	
    Entry *theEntry = [self entryForIndexPath:indexPath];

	LibraryCell *cell = [[LibraryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];  
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.entry = theEntry;
	
	return cell; //[cell autorelease]; //TF 102209}
}


- (Entry *)entryForIndexPath:(NSIndexPath *)indexPath {
	
    //NSLog(@"LIBRARYHOME.tableView:entryForIndexPath:");
    Entry *entry = nil;
	int index = indexPath.row;
    //NSDictionary *guideInfo = [displayedGuides objectAtIndex:index];
    //int _guideID = [[guideInfo objectForKey:@"guide"] intValue];

    int _guideID = [[displayedGuides objectAtIndex:index] intValue];
	
    //NSLog(@"LIBRARYHOME.entryForIndexPath: Guide ID = %i", guideID);
    
    NSString *query = [NSString stringWithFormat:@"SELECT rowid,* FROM entries WHERE rowid = %i", _guideID];
    
    @synchronized ([Props global].dbSync){
        FMResultSet *rs = [guidesDB executeQuery:query];
        if ([rs next]) entry = [[Entry alloc] initWithRow:rs]; 
        [rs close];
    }
    
	return entry;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView  {
    
	return 1;
}



- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section {
	// ask for, and return, the number of entries in the current selection
    
	return [displayedGuides count];
}

- (void) reloadLibrary {
    
    NSLog(@"LIBRARYHOME.reloadLibrary");
    
    [libraryList beginUpdates];
    [libraryList endUpdates];
    
}


- (void) showDownloadProblemsAlert {
    
    [self performSelectorOnMainThread:@selector(showDownloadProblemsAlertInMain) withObject:nil waitUntilDone:FALSE];
}


- (void) showDownloadProblemsAlertInMain {
    
    UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle :nil
                                                            message: @"Downloading your guide is taking longer than it should. Something is likely going wrong with your internet connection or our servers. We'll keep trying - sorry for the wait!"
                                                          delegate : self cancelButtonTitle:@"OK"otherButtonTitles:nil];
    [failureAlert show];
}


@end
