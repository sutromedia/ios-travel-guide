/*

File: TheElementsAppDelegate.m
Abstract: Application delegate that sets up the application.

Version: 1.7


Copyright (C) Sutro Media. All Rights Reserved.

*/

#import "EntriesAppDelegate.h"
#import "Entry.h"
#import "EntryCollection.h"
#import "EntriesTableViewController.h"
#import "ActivityLogger.h"
#import "Constants.h"
#import "MapViewController.h"
#import "Props.h"
#import	"DataDownloader.h"
#import "Reachability.h"
#import "TestAppView.h"
#import "FMDatabase.h"
#import	"FMResultSet.h"
#import <StoreKit/StoreKit.h>
#import "SlideController.h"
#import "SMLog.h"
#import "SMRichTextViewer.h"
#import "CommentsViewController.h"
#import "FlipViewController.h"
#include <sys/sysctl.h>  
#include <mach/mach.h>
#include "TopLevelMapView.h"
#include "ImageManipulator.h"
#import <QuartzCore/QuartzCore.h> 
//#import "CrashReportSender.h" //replaced with Crittercism
#import "LibraryHome.h"
#import "MyStoreObserver.h"
#import "ASIHTTPRequest.h"
#import "DealsViewController.h"
#import "ZipArchive.h"
#import "FilterPicker.h"
#import "OpeningView.h"
#include <sys/xattr.h> //Used for marking files as "do not back up" for iCloud
//#include "Crittercism.h"
//#import "SW_IntroTutorial.h"

//#import "Apsalar.h"
//#import "FlurryAnalytics.h"
//#import "TestFlight.h"

#define kUpgradeAlertTag 23
#define kWelcomeAlertTag 24
#define kContentUpdateDownloadedAlertTag 26
#define kUpdateViewTag 27
#define kReviewAlertTag 28
#define kDontShowReviewPrompt @"Don't show review prompt"

@implementation EntriesAppDelegate

@synthesize tabBarController;
@synthesize portraitWindow;


- init {
    
    self = [super init];
	if (self) {

		portraitWindow = nil;
		tabBarController = nil;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showTestApp:) name:kShowTestApp object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flipToOrFromSutroWorld:) name:kFlipWorlds object:nil];
	}
	return self;
}




- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	//NSLog(@"Application did finish launching");

	if(getenv("NSZombieEnabled") || getenv("NSAutoreleaseFreedObjectCheckEnabled")) NSLog(@"****** WARNING: NSZombieEnabled/NSAutoreleaseFreedObjectCheckEnabled enabled! **********");
    
    //NSURL *CRASH_REPORTER_URL = [NSURL URLWithString:@"http://www.crashreport.sutromedia.com/crash_v200.php"];
	//[[CrashReportSender sharedCrashReportSender] sendCrashReportToURL:CRASH_REPORTER_URL delegate:self activateFeedback:NO];
    
    //[Apsalar startSession:@"tobinfisher" withKey:@"sEY0yo8F" andLaunchOptions:launchOptions];
    //[FlurryAnalytics startSession:@"SUUKFD81Z5LHKFXEL5IF"];
/*#define TESTING 1
#ifdef TESTING
	[TestFlight setDeviceIdentifier:[Props global].deviceID];
#endif
	
    [TestFlight takeOff:@"5e66807ee31affacce9ae91a8374f427_NDQ0MDMyMDExLTEyLTAzIDE2OjUyOjI3LjMwMDI3Mg"];*/
    
    //SF EXplorer [Crittercism initWithAppID: @"4ffc9787067e7c44d9000004" andKey:@"yhw5slacm3ojhuwvdcsxrqp4ikqn" andSecret:@"p5phxviu7fqna2ilzcswg1j3bqgdndlj"];
    //[Crittercism initWithAppID:@"4ffe25bf067e7c259b000002" andKey:@"vktkeu2vqr0j67bhgp1iowrjftny" andSecret:@"djpvmkqyxsc9b6zrurwz1q8agcbtd0wg"]; //New York On The Cheap
    
	[self runStartupTasks];
	
    [[Props global] setupPropsDictionary];
    
    if ([Props global].freemiumType != kFreemiumType_Paid)[[MyStoreObserver sharedMyStoreObserver] requestProductData];
    
	if ([Props global].appID != 1) {
        
        [[EntryCollection sharedEntryCollection] initialize];
        [self setupSingleGuide];
    }
    
    else [self setupLibraryHome];
	
	//if([self shouldShowWiFiAlert])[self performSelector:@selector(showWiFiAlert2:) withObject:nil afterDelay: 20];
    if ([Props global].osVersion >= 4) [self applicationWillEnterForeground:application];
    
    return TRUE;
}


- (void) applicationDidBecomeActive:(UIApplication *)application {
	
	 //[Apsalar startSession:@"tobinfisher" withKey:@"sEY0yo8F"];
    
    if ([Props global].osVersion < 4) [self applicationWillEnterForeground:application];
}


- (void) applicationWillEnterForeground:(UIApplication *)application {
	
	NSLog(@"\n****************\nEAP.applicationWillEnterForeground\n*********************");
	
	//NSLog(@"************ CHANGE ME - Setting BOOL to always show tutor view");
	//[[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"ListViewTutorialShown"];
    
    [Props global].sessionID	= [[NSDate date] timeIntervalSince1970];
    [Props global].commentsDatabaseNeedsUpdate = TRUE;
	[[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:kShouldQuit];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectOrientation) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    
    int sessionCounter = [[[NSUserDefaults standardUserDefaults] objectForKey:@"sessionCounter"] intValue];
    sessionCounter ++;
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:sessionCounter] forKey:@"sessionCounter"];
	
    //NSSet *updateTestGuides = [NSSet setWithObjects:[NSNumber numberWithInt:37], [NSNumber numberWithInt:3], [NSNumber numberWithInt:1], nil];
    
    if ([[Reachability sharedReachability] internetConnectionStatus] != NotReachable) 
        [self performSelectorInBackground:@selector(checkForContentUpdate) withObject:nil];
    
    
	if ([ActivityLogger sharedActivityLogger].sequence_id == 0 && [Props global].appID != 1 && ![DataDownloader sharedDataDownloader].initialized){
		NSLog(@"EAD.applicationDidBecomeActive: About to start downloader for first time");
		[self performSelectorInBackground:@selector(downloadData) withObject:nil];
	}
	
	else {
		
		NSLog(@"Reseting activity logger and data downloader");
		//[ActivityLogger sharedActivityLogger].sequence_id = 0;
		//if ([Props global].hasLocations)[[LocationManager sharedLocationManager] reset];
		[Props global].dataDownloaderShouldCheckForUpdates = TRUE;
	}
    
    [[ActivityLogger sharedActivityLogger] startSession];
    
    NSLog(@"Session counter = %i, mod 2 = %i", sessionCounter, sessionCounter%2);
    
    //Startup stuff for Sutro World
    if ([Props global].isShellApp) [[MyStoreObserver sharedMyStoreObserver] requestProductData];
    
    //Startup stuff for non-upgraded free apps
    else if ([Props global].freemiumType != kFreemiumType_Paid){
        
        [[MyStoreObserver sharedMyStoreObserver] requestProductData];
        
        //NSLog(@"*************** REMOVE ME - OFFLINE ACCESS NEEDS DISABLING **************************");
        
        if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable && [Props global].firstVersion >= 31141) {
            UIAlertView *upgradePopup = [[UIAlertView alloc] initWithTitle:nil message:@"Looks like you don't have an internet connection.\n Offline use requires upgrading to Pro." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            upgradePopup.tag = kUpgradeAlertTag;
            [upgradePopup show];
        }
        
        else if ([Props global].freemiumType == kFreemiumType_V1 && sessionCounter > 1 && !doNotShowUpgradeOrReviewPopup) {
            
            NSString *message = [NSString stringWithFormat:@"For the best experience, consider upgrading to get:\n~ Offline maps and photos\n~ Full content search\n~ Ability to save favorites\n~ No ads\n~ More pictures\n~ A well fed author!\n"];
            
            UIAlertView *welcomePopup = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Thanks for using %@!", [Props global].appName] message:message delegate:self cancelButtonTitle:@"No thanks" otherButtonTitles: @"Upgrade", nil];
            welcomePopup.tag = kWelcomeAlertTag;
            
            //This next line causes a crash in iOS 7, because alertview popups can't be accessed
            if ([Props global].osVersion < 7) ((UILabel*)[[welcomePopup subviews] objectAtIndex:1]).textAlignment = UITextAlignmentLeft;
            
            [welcomePopup show];
        }
    }
    
    else if (sessionCounter > 2 && sessionCounter % 2 == 1 && !doNotShowUpgradeOrReviewPopup && ![[NSUserDefaults standardUserDefaults] boolForKey:kDontShowReviewPrompt] && [Props global].freemiumType == kFreemiumType_Paid  && ![[Reachability sharedReachability] internetConnectionStatus] == NotReachable){
        
        NSString *message = [NSString stringWithFormat:@"Thanks for using %@. If you've enjoyed it, we'd be grateful if you would take a minute to  review it for others. Thanks for your support!", [Props global].appName];
        
        UIAlertView *reviewPopup = [[UIAlertView alloc] initWithTitle:@"Review?" message:message delegate:self cancelButtonTitle:@"No thanks" otherButtonTitles: @"Review on iTunes", @"Remind me later", nil];
        reviewPopup.tag = kReviewAlertTag;
        //((UILabel*)[[welcomePopup subviews] objectAtIndex:1]).textAlignment = UITextAlignmentLeft;
        [reviewPopup show];
        
        if ([Props global].appID == 17) [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kDontShowReviewPrompt]; //Per Jeffrey's request
    }
    
    FMDatabase *db = [EntryCollection sharedContentDatabase];
    
    @synchronized ([Props global].dbSync) {
        FMResultSet *rs = [db executeQuery: @"SELECT COUNT(*) AS theCount FROM entries"];
        
        if ([db hadError]) NSLog(@"\n **** WARNING: SQLITE ERROR: SINGLESETTINGVIEW.setKey, %d: %@\n", [db lastErrorCode], [db lastErrorMessage]);
        
        int totalNumberOfEntries = 7;
        if ([rs next]) totalNumberOfEntries = [rs intForColumn:@"theCount"];
        else NSLog(@"GUIDEDOWNLOADER.updateTotalContentSize: Error with query");
        
        [rs close];
        
        NSLog(@"EAD Entry count = %i", totalNumberOfEntries);
    }
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    
	[[NSUserDefaults standardUserDefaults] synchronize];
    [[ActivityLogger sharedActivityLogger] endSession];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShouldQuit]) {
		NSLog(@"Exiting app");
		exit(0);
	}
	
	else NSLog(@"Application entering background");
}


- (void) applicationWillTerminate:(UIApplication *)application {
	
	[[ActivityLogger sharedActivityLogger] endSession];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setupSingleGuide {
 
    [[UIApplication sharedApplication] setStatusBarHidden:TRUE withAnimation: UIStatusBarAnimationNone];
    
	@autoreleasepool {
    // Set up the portraitWindow and content view
		UIWindow *localPortraitWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		self.portraitWindow = localPortraitWindow;
		
    [portraitWindow setBackgroundColor:[UIColor blackColor]];
		[portraitWindow makeKeyAndVisible]; 
		[portraitWindow setAutoresizesSubviews:YES];
		
		NSMutableArray *localViewControllersArray = [[NSMutableArray alloc] initWithCapacity:4];
		
		if (TRUE) {
			
        EntriesTableViewController *theTableViewController = [[EntriesTableViewController alloc] init];
			
			UINavigationController *theNavigationController = [[UINavigationController alloc] initWithRootViewController:theTableViewController];
			[localViewControllersArray addObject:theNavigationController];
			
		}
		
		if (TRUE) {
        
        SlideController *theSlideController = [[SlideController alloc] init];
        
			UINavigationController *theNavigationController = [[UINavigationController alloc] initWithRootViewController:theSlideController];
			[localViewControllersArray addObject:theNavigationController];
			
		}
    
		// repeat the process for Maps
		if ([Props global].hasLocations) {
			
			TopLevelMapView * mapView = [[TopLevelMapView alloc] init];
			
			UINavigationController *theNavigationController = [[UINavigationController alloc] initWithRootViewController:mapView];
			[localViewControllersArray addObject:theNavigationController];
        
		}	
		
		
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
		
		// set the tab bar controller view controller array to the localViewControllersArray'
    
    /*if (tabBarController != nil) {
     NSLog(@"Retain count for tabBarController = %i", [tabBarController retainCount]);
     //[tabBarController release];
     self.tabBarController = nil;
     }*/
    
    // Create a tabbar controller and an array to contain the view controllers
    /*UITabBarController *tempTabBarController = [[UITabBarController alloc] init];
     self.tabBarController = tempTabBarController;
     [tempTabBarController release];*/
    
    if (tabBarController != nil) {
        tabBarController = nil;
    }
    
    tabBarController = [[UITabBarController alloc] init];
    
		tabBarController.viewControllers = localViewControllersArray;
    
		// Set RootViewController to window
		if ( [[UIDevice currentDevice].systemVersion floatValue] < 6.0)
			{
				    // warning: addSubView doesn't work on iOS6
				    [portraitWindow addSubview: tabBarController.view];
				}
		else
			{
				    // use this mehod on ios6
				    [portraitWindow setRootViewController:tabBarController];
				}
    
		//[portraitWindow addSubview:tabBarController.view];
    
    //[FlurryAnalytics logAllPageViews:tabBarController];
    
    // NSLog(@"Retain count for tab bar controller = %i", [tabBarController retainCount]);
	
	}
	
	if ([Props global].inTestAppMode) [self addScreenshotButton];
}


- (void) setupLibraryHome {
    
	self.portraitWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
    [portraitWindow setBackgroundColor:[UIColor blackColor]];
	[portraitWindow setAutoresizesSubviews:YES];
    
    LibraryHome *homeScreen = [[LibraryHome alloc] init];
    
    UINavigationController *theNavigationController = [[UINavigationController alloc] init];
    theNavigationController.navigationBar.tintColor = [Props global].navigationBarTint;
    theNavigationController.view.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - [UIApplication sharedApplication].statusBarFrame.size.height);
    //theNavigationController.wantsFullScreenLayout = YES;
    [theNavigationController pushViewController:homeScreen animated:NO];
     
    
    self.portraitWindow.rootViewController = theNavigationController;
    [portraitWindow makeKeyAndVisible]; 
}


- (void) downloadData {
	
	@autoreleasepool {
    
        while ([Props global].contentUpdateInProgress) {
            [NSThread sleepForTimeInterval:1];
            //NSLog(@"EAD.downloadData: Waiting to start until content update completes");
        }
	
	[[DataDownloader sharedDataDownloader] initializeDownloader]; 
	
	}
}


- (void) runStartupTasks {
    
    NSLog(@"EAD.runStartupTasks");
	
	//Update to new freemium purchase key as necessary
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kOfflineUpgradePurchased] && [[NSUserDefaults standardUserDefaults] integerForKey:kFreemiumType] == kFreemiumType_NotSet)[[NSUserDefaults standardUserDefaults] setInteger:kFreemiumType_Paid forKey:kFreemiumType];
   
    // **************** Move content database from the app bundle to the cache folder as necessary **********************
    // DB needs to be moved if either:
    // - The app is being started for the first time and there isn't one there
    // - The app was just upgraded and the one in the cache folder is out of date
    
    NSString *appBundlePath = [[NSBundle mainBundle] pathForResource:@"content" ofType:@"sqlite3"];
    NSString *cacheFolderPath = [NSString stringWithFormat:@"%@/%@.sqlite3",[Props global].cacheFolder, @"content"];
    
    int documentsDbBundleVersion = 0;
    int appBundleDbBundleVersion = 0;
    
    
    FMDatabase *tempDatabase = [[FMDatabase alloc] initWithPath:appBundlePath];
    
    if (![tempDatabase open]) NSLog(@"EAP.runStartupTasks - Could not open sqlite database from file = %@", appBundlePath);
    
    FMResultSet *rs = [tempDatabase executeQuery:@"SELECT key,Value FROM app_properties WHERE key = 'bundle_version'"];
    
    if ([rs next]) appBundleDbBundleVersion = [rs intForColumn:@"Value"];
    
    [rs close];
    [tempDatabase close];
    
    
    FMDatabase *db = [[FMDatabase alloc] initWithPath:cacheFolderPath];
    
    if (![db open]) NSLog(@"Could not open sqlite database from file = %@", cacheFolderPath);
    
    else {
        
        FMResultSet *rs1 = [db executeQuery:@"SELECT key,Value FROM app_properties WHERE key = 'bundle_version'"];
        
        if ([rs1 next]) documentsDbBundleVersion = [rs1 intForColumn:@"Value"];
        
        [rs1 close];
        [db close];
    }
	
	[Props global].previousBundleVersion = documentsDbBundleVersion; //Used for figuring out if app was previously purchased in the event that it is now free
    
    
    
    //Check to see if the binary version of the db is the most recent one, which can happen after an app update through iTunes
    if (![[NSFileManager defaultManager] fileExistsAtPath: cacheFolderPath] || appBundleDbBundleVersion > documentsDbBundleVersion) {
        
        if ([[NSFileManager defaultManager] fileExistsAtPath: cacheFolderPath]){ 
            [[NSFileManager defaultManager] removeItemAtPath:cacheFolderPath error:nil];
        }
        
        NSLog(@"EAD.runStartupTasks: Reinitiallizing defaults");
        NSString *thumbnailKeyString = [NSString stringWithFormat:@"%@_%i", kThumbnailsDownloaded, [Props global].appID];
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:thumbnailKeyString];
        
        //Remove old map cache while we're at it
        NSString *mapCachePath = [NSString stringWithFormat:@"%@/Map(null).sqlite",[Props global].cacheFolder];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath: mapCachePath]){ 
            [[NSFileManager defaultManager] removeItemAtPath:mapCachePath error:nil];
            NSLog(@"EAD.runStartupTasks: Removing old map cache");
        }
        
        if(![[NSFileManager defaultManager] copyItemAtPath: appBundlePath toPath:cacheFolderPath error:nil])
            NSLog(@"Error copying file");
        
        else NSLog(@"EAD.runStartupTasks: Successfully copied database to content folder");
    }
    
    
    //************************** Update and move maps database as necessary ***************************

    NSString *oldMapsDBFilePath= [NSString stringWithFormat:@"%@/offline-map-tiles.sqlite3", [Props global].cacheFolder];
    NSString *mapsDBAppBundlePath = [[NSBundle mainBundle] pathForResource:@"offline-map-tiles" ofType:@"sqlite3"];
    
    //Move maps DB to documents folder if it's in the cache folder
    //Making this change because things in the cache folder can get deleted without warning
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldMapsDBFilePath]) {
        
        //We need to use the maps DB at this old location for this session, as moving the maps folder potentially takes longer than can be done on startup
        //[Props global].mapDatabaseLocation = oldMapsDBFilePath;
        
        //Add new properties row to map tile DB if it's in the cache folder and is still the old version
        if (![Props global].isShellApp && documentsDbBundleVersion < 26108 && documentsDbBundleVersion > 0) {
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:oldMapsDBFilePath]) {
                
                NSLog(@"ENTRYCOLLECTION.sharedContentDatabase: Updating map db with tile count row");
                
                FMDatabase *newMapDB = [[FMDatabase alloc] initWithPath:mapsDBAppBundlePath];
                
                [newMapDB open];
                
                FMDatabase *oldMapsDB = [[FMDatabase alloc] initWithPath:oldMapsDBFilePath];
                
                [oldMapsDB open];
                
                @synchronized([Props global].mapDbSync) {
                    
                    FMResultSet *rs = [newMapDB executeQuery:@"SELECT * FROM preferences WHERE name = 'initial_tile_row_count'"];
                    
                    if ([rs next]) {
                        
                        [oldMapsDB executeUpdate:@"BEGIN TRANSACTION"];
                        [oldMapsDB executeUpdate:@"INSERT INTO preferences (name, value) VALUES (?, ?)", [rs stringForColumn:@"name"], [NSNumber numberWithInt:[rs intForColumn:@"value"]]];
                        [oldMapsDB executeUpdate:@"END TRANSACTION"];
                    }
                    
                    [rs close];
                }
                
                [oldMapsDB close];
                
                [newMapDB close];
            }
        }

        NSLog(@"EAP.runStartupTasks: Moving maps database from cache folder to documents folder");
        NSError *error = nil;
        
        [[NSFileManager defaultManager] moveItemAtPath: oldMapsDBFilePath toPath:[Props global].mapDatabaseLocation error:&error];
        
        if (error != nil) NSLog(@"******* ERROR: EC.sharedContentDatabase: Moving maps database from cache folder to documents folder - Error = %@", [error description]);
        
        NSLog(@"EC.sharedContentDatabase: Finished moving maps database from cache folder to documents folder");

    }
    
    
    //Move maps database from main bundle to documents folder (so we can write to it later) if this hasn't been done already
    else if (![[NSFileManager defaultManager] fileExistsAtPath:[Props global].mapDatabaseLocation]) {
        
        NSLog(@"EAD.runStartupTasks: Moving map database from resource bundle to docs directory");
        
        NSError *theError = nil;
        if (![[NSFileManager defaultManager] copyItemAtPath:mapsDBAppBundlePath toPath: [Props global].mapDatabaseLocation error:&theError]) NSLog(@"EAD.runStartupTasks:: ERROR MOVING MAIN MAP DATABASE from %@ to %@ with error %@-  **************************************************", mapsDBAppBundlePath, [Props global].mapDatabaseLocation, [theError description]);
    }
    
    //Mark maps database as "do not back up" for iCloud
    const char* filePath = [[Props global].mapDatabaseLocation fileSystemRepresentation];
    
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);

    NSLog(@"ENTRIESAPPDELEGATE.runStartupTasks: result of setting do not back up attribute is %i", result);
    
    /*
    ********************  Set defaults as necessary depending on when the user first bought the app
    
    NSString *firstVersionFilename = [NSString stringWithFormat:@"%@/first_version.txt", [Props global].documentsFolder];
    
    int firstVersion = [[NSString stringWithContentsOfFile:firstVersionFilename encoding:NSUTF8StringEncoding error:nil] intValue];
    
    if (firstVersion == 0) {
        firstVersion = appBundleDbBundleVersion;
        [[NSString stringWithFormat:@"%i", firstVersion] writeToFile:firstVersionFilename atomically:YES encoding: NSUTF8StringEncoding error: NULL];
    }
    
    [Props global].firstVersion = firstVersion;
    
    
    //Set this app as upgraded, as the user has already purchased it prior to the free with paid upgrade version
    if ((documentsDbBundleVersion <= 24849 && documentsDbBundleVersion > 0) || firstVersion <= 24849) {
        
        NSLog(@"This user shouldn't pay for an upgrade. Setting the upgrade automatically");
        
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kOfflineUpgradePurchased];
        
        
        [[NSString stringWithFormat:@"%i", documentsDbBundleVersion] writeToFile:firstVersionFilename atomically:YES encoding: NSUTF8StringEncoding error: NULL];
    }
     */
}


-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
    
	if (theAlert.tag == kUpgradeAlertTag) exit(0);
    
    else if (theAlert.tag == kWelcomeAlertTag && buttonIndex != 0){
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kShowUpgrade object:nil userInfo:nil];
        
        SMLog *log = [[SMLog alloc] initWithPageID: kUpgradePopup actionID: kUpgradeFromPopup];
        [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
    }
    
    else if (theAlert.tag == kReviewAlertTag){
        
        switch (buttonIndex)
        {
            case 0:
                {
                    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kDontShowReviewPrompt];
                }
                break;
            case 1:
                {
                    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kDontShowReviewPrompt];
                    
                    SMLog *log = [[SMLog alloc] initWithPageID: kReviewPopup actionID: kReviewFromPopup];
                    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[Props global].reviewURL]];
                }
                break;
                
            case 2:
                {
                    NSLog(@"Case 2");
                } 
                break;
        
            default:
                { 
                    NSLog(@"Default");
                } 
                break;
        };
    }
}


#pragma mark
#pragma mark Content Updates

- (void) checkForContentUpdate {
    
    @autoreleasepool {
        NSLog(@"EAD.checkForContentUpdate");
        
        NSString *urlString;
        if ([Props global].isShellApp) urlString = [NSString stringWithFormat:@"%@/1.v2-bundleversion.txt", [Props global].serverDatabaseUpdateSource];
        
        else urlString = [NSString stringWithFormat:@"%@/%i-bundleversion.txt", [Props global].serverDatabaseUpdateSource, [Props global].appID];
        
        NSURL *url = [NSURL URLWithString:urlString];
       
        NSError* error;
        int latestBundleVersion = [[NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error] intValue];
        
        NSLog(@"EAD.checkForContentUpdate: Latest bundle version = %i and current bundle version = %i", latestBundleVersion, [Props global].bundleVersion);
        
        //NSLog(@"\n\n************** WARNING: SET TO ALWAYS UPDATE DATABASE - CHANGE ME!!! **************************\n\n");
        
        if (latestBundleVersion > [Props global].bundleVersion){
            
            doNotShowUpgradeOrReviewPopup = TRUE;
            
            if ([Props global].isShellApp) [self performSelectorInBackground:@selector(updateContent) withObject:nil];
            
            else {
                
                OpeningView *openingView = [[OpeningView alloc] init];
                openingView.tag = kUpdateViewTag;
                [self.portraitWindow addSubview:openingView];
            }
        }
        
        else doNotShowUpgradeOrReviewPopup = FALSE;
    }
}


//This is currrently used for SW only. Need to figure out how to merge this method with the one in OpeningView
- (void) updateContent {
    
    NSLog(@"EAD.updateContent. In main thread - %@", [NSThread isMainThread] ? @"YES" : @"NO");
    
   
	@autoreleasepool {
    
        NSDate *date = [NSDate date];
        
        NSString *unzippedFilePath;   
        
        NSString *urlString =[NSString stringWithFormat:@"%@/1.v2.sqlite3.zip", [Props global].serverDatabaseUpdateSource];
        unzippedFilePath= [NSString stringWithFormat:@"%@/1.v2.sqlite3", [Props global].cacheFolder];
        
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
        
        NSString *zippedFilePath= [NSString stringWithFormat:@"%@.zip", unzippedFilePath];
        
        NSURL *dataURL = [NSURL URLWithString: urlString];
        NSLog(@"EAD.updateContent: About to try and download database at %@", urlString);
        
        //Get the data
        NSData *databaseData = [[NSData alloc] initWithContentsOfURL:dataURL options:NSDataReadingUncached error:nil];
        
        //Write the data to disk
        [databaseData writeToFile: zippedFilePath atomically:YES];
        
        //Unzip file
        ZipArchive *za = [[ZipArchive alloc] init];
        if ([za UnzipOpenFile: zippedFilePath]) {
            BOOL ret = [za UnzipFileTo: [Props global].cacheFolder overWrite: YES];
            if (NO == ret){} [za UnzipCloseFile];
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:zippedFilePath error:nil];
        
        NSLog(@"EAD.updateContent: File saved to disk, %0.2f", -[date timeIntervalSinceNow]);
        
        //*************** Get any missing app icons *********************
        
        FMDatabase *db = [[FMDatabase alloc] initWithPath:unzippedFilePath];
        [db open];
        
        NSMutableArray *missingImages = [NSMutableArray new];
        
        @synchronized ([Props global].dbSync){
            FMResultSet *rs = [db executeQuery:@"SELECT icon_photo_id FROM entries"];
            while ([rs next]){
                
                int iconId = [rs intForColumn:@"icon_photo_id"];
                
                NSString *imageName = [NSString stringWithFormat:@"%i_x100", iconId];
                NSString *filePath = [NSString stringWithFormat:@"%@/images/%@.jpg", [Props global].contentFolder, imageName];
                
                //NSLog(@"Checking for %@", imageName);
                
                //Look to see if the 100px icon image is present
                if (!([[NSFileManager defaultManager] fileExistsAtPath:[[NSBundle mainBundle] pathForResource:imageName ofType:@"jpg"]] || [[NSFileManager defaultManager] fileExistsAtPath:filePath])) {
                    [missingImages addObject:[NSNumber numberWithInt:iconId]];
                }
            }
            
            [rs close];
        }
        
        NSLog(@"EAD.updateContent: %i images missing", [missingImages count]);
        
        NSString *theFolderPath = [NSString stringWithFormat:@"%@/images", [Props global].contentFolder];
        NSError *theError = nil;
        
        //Create folder for content as necessary
        if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath]) 
            [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:&theError];
        
        for (NSNumber *missingImage in missingImages) {
            NSLog(@"EAD.updateContent: Missing image %i", [missingImage intValue]);
            
            NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i_x100.jpg", [Props global].contentFolder, [missingImage intValue]];
            
            NSString *urlString = [[NSString stringWithFormat: @"http://pub1.sutromedia.com/published/dynamic-photos/height/100/%i.jpg", [missingImage intValue]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
            
            //Get the data
            NSData *imageData = [[NSData alloc] initWithContentsOfURL:dataURL];
            
            //Write the data to disk
            theError = nil;
            
            if([imageData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) 
                NSLog(@"EAD.updateContent: failed to write local file to %@, error = %@, userInfo = %@", theFilePath, theError, [theError userInfo]);
            
            else NSLog(@"EAD.updateContent: Wrote image to %@", theFilePath);
            
            //Clean up
        }
        
        NSLog(@"EAD.updateContent: Missing icons downloaded in %0.2f seconds", -[date timeIntervalSinceNow]);
        
        //******************* Update the Photos table to correctly show what images are present ***********************
        //This is used for correctly setting up the slideshow
        
        NSMutableString *downloadedPhotoList = [[NSMutableString alloc] init];
		NSString *query = @"SELECT rowid from photos WHERE downloaded_x100px_photo IS NULL LIMIT 5000";
		
		FMResultSet * rs = [db executeQuery:query];
		
		if ([db hadError]) NSLog(@"sqlite error in EAD.updateContent, query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
		
		while ([rs next]) {
			
			int imageId = [rs intForColumn:@"rowid"];
			NSString *fileName = [NSString stringWithFormat:@"%i_x100", imageId];
			NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/images/%@.jpg", [Props global].contentFolder, fileName];
			
			//NSLog(@"About to look for file at %@", theFilePath);
			
			if([[NSFileManager defaultManager] fileExistsAtPath: theFilePath] || [[NSFileManager defaultManager] fileExistsAtPath: [[NSBundle mainBundle] pathForResource:fileName ofType:@"jpg"]]){
				[downloadedPhotoList appendString:[NSString stringWithFormat:@"%i,", imageId]];
			}
			
			[NSThread sleepForTimeInterval:0.0005];
		}
		
		[rs close];
		
		
		if ([downloadedPhotoList length] > 0) {
			
			[downloadedPhotoList deleteCharactersInRange:NSMakeRange([downloadedPhotoList length] - 1, 1)];
			
			NSString *query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_x100px_photo = 1 WHERE rowid IN (%@)", downloadedPhotoList];
			
			[db executeUpdate:@"BEGIN TRANSACTION"];
			[db executeUpdate:query];
			[db executeUpdate:@"END TRANSACTION"];
		}
		
        
        [db close];
		
        
        NSString *theFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].cacheFolder];
        
        @synchronized ([Props global].dbSync) {
            
            [[NSFileManager defaultManager] removeItemAtPath:theFilePath error:nil];
            [[NSFileManager defaultManager] moveItemAtPath:unzippedFilePath toPath: theFilePath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:unzippedFilePath error:nil];
            
			/*if ([Props global].appID == 1) {
				[EntryCollection resetContent];
				[[FilterPicker sharedFilterPicker] resetContent];
				[[MapViewController sharedMVC] reset]; //This needs to be after setting up props dictionary, as calling this for the first time before setting the app id causes problems
				[FilterPicker resetContent];
				[[Props global] setupPropsDictionary];
				[Props global].dataDownloaderShouldCheckForUpdates = TRUE;
				
				//[[NSNotificationCenter defaultCenter] postNotificationName:kContentUpdated object:nil];
			}*/
        }
        
        NSLog(@"EAD.updateContent: Database updated with latest images, %0.2f", -[date timeIntervalSinceNow]);
    }
}


/*
- (void) updateContent {
    
    NSLog(@"EAD.updateContent");
    
    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
    
    NSDate *date = [NSDate date];
    
    NSString *unzippedFilePath;   
    
    NSString *urlString;
    if ([Props global].appID != 1 && ![Props global].isShellApp){
        urlString = [NSString stringWithFormat:@"http://www.sutromedia.com/published/content/%i.sqlite3.zip", [Props global].appID];
        unzippedFilePath= [NSString stringWithFormat:@"%@/%i.sqlite3", [Props global].cacheFolder, [Props global].appID];
    }
    
    else{
        urlString = @"http://www.sutromedia.com/published/content/1.v2.sqlite3.zip";
        unzippedFilePath= [NSString stringWithFormat:@"%@/1.v2.sqlite3", [Props global].cacheFolder];
    }
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
    
    NSString *zippedFilePath= [NSString stringWithFormat:@"%@.zip", unzippedFilePath];
    
    NSURL *dataURL = [NSURL URLWithString: urlString];
    NSLog(@"EAD.updateContent: About to try and download database at %@", urlString);
    
    //Get the data
    NSData *databaseData = [[NSData alloc] initWithContentsOfURL:dataURL options:NSDataReadingUncached error:nil];
    
    //Write the data to disk
    [databaseData writeToFile: zippedFilePath atomically:YES];
    [databaseData release];
    
    //Unzip file
    ZipArchive *za = [[ZipArchive alloc] init];
    if ([za UnzipOpenFile: zippedFilePath]) {
        BOOL ret = [za UnzipFileTo: [Props global].cacheFolder overWrite: YES];
        if (NO == ret){} [za UnzipCloseFile];
    }
    [za release];
    
    [[NSFileManager defaultManager] removeItemAtPath:zippedFilePath error:nil];
    
    NSLog(@"EAD.updateContent: File saved to disk, %0.2f", -[date timeIntervalSinceNow]);
    
    // *************** Get any missing app icons *********************
    
    FMDatabase *db = [[FMDatabase alloc] initWithPath:unzippedFilePath];
    [db open];
    
    NSMutableArray *missingImages = [NSMutableArray new];
    
    @synchronized ([Props global].dbSync){
        FMResultSet *rs = [db executeQuery:@"SELECT icon_photo_id FROM entries"];
        while ([rs next]){
            
            int iconId = [rs intForColumn:@"icon_photo_id"];
            
            NSString *imageName = [NSString stringWithFormat:@"%i_x100", iconId];
            NSString *filePath = [NSString stringWithFormat:@"%@/images/%@.jpg", [Props global].contentFolder, imageName];
            
            NSLog(@"Checking for %@", imageName);
            
            //Look to see if the 100px icon image is present
            if (!([[NSFileManager defaultManager] fileExistsAtPath:[[NSBundle mainBundle] pathForResource:imageName ofType:@"jpg"]] || [[NSFileManager defaultManager] fileExistsAtPath:filePath])) {
                [missingImages addObject:[NSNumber numberWithInt:iconId]];
            }
        }
        
        [rs close];
    }
    
    NSLog(@"EAD.updateContent: %i images missing", [missingImages count]);
    
    NSString *theFolderPath = [NSString stringWithFormat:@"%@/images", [Props global].contentFolder];
    NSError *theError = nil;
    
    //Create folder for content as necessary
    if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath]) 
        [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:&theError];
    
    for (NSNumber *missingImage in missingImages) {
        NSLog(@"EAD.updateContent: Missing image %i", [missingImage intValue]);
        
        NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i_x100.jpg", [Props global].contentFolder, [missingImage intValue]];
        
        NSString *urlString = [[NSString stringWithFormat: @"http://pub1.sutromedia.com/published/dynamic-photos/height/100/%i.jpg", [missingImage intValue]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
        
        //Get the data
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:dataURL];
        
        //Write the data to disk
        theError = nil;
        
        if([imageData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) 
            NSLog(@"EAD.updateContent: failed to write local file to %@, error = %@, userInfo = %@", theFilePath, theError, [theError userInfo]);
        
        else NSLog(@"EAD.updateContent: Wrote image to %@", theFilePath);
        
        //Clean up
        [dataURL release];
        [imageData release];
    }
    
    NSLog(@"EAD.updateContent: Missing icons downloaded in %0.2f seconds", -[date timeIntervalSinceNow]);
    
    // ******************* Update the Photos table to correctly show what images are present ***********************
    //This is used for correctly setting up the slideshow
    
    NSMutableString *downloadedPhotoList = [[NSMutableString alloc] initWithCapacity:10000];
    
    @synchronized([Props global].dbSync) {
		
		NSString *query = @"SELECT rowid from photos WHERE downloaded_x100px_photo is null LIMIT 2000";
		
		FMResultSet * rs = [db executeQuery:query];
		
		if ([db hadError]) NSLog(@"sqlite error in EAD.updateContent, query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
		
		if (![rs next]) NSLog(@"EAD.updateContent - no rows in result set");
		
		while ([rs next]) {
			
            int imageId = [rs intForColumn:@"rowid"];
			NSString *fileName = [NSString stringWithFormat:@"%i_x100", imageId];
			NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/images/%@.jpg", [Props global].contentFolder, fileName];
			
			//NSLog(@"About to look for file at %@", theFilePath);
			
			if([[NSFileManager defaultManager] fileExistsAtPath: theFilePath] || [[NSFileManager defaultManager] fileExistsAtPath: [[NSBundle mainBundle] pathForResource:fileName ofType:@"jpg"]]) 
				[downloadedPhotoList appendString:[NSString stringWithFormat:@"%i,", imageId]];
            
            [theFilePath release];
		}
		
		[rs close];
    }
    
    @synchronized([Props global].dbSync) {
		
		//NSLog(@"DATADOWNLOADER.updatePhotoStatuses: Downloaded photos ids has about %i objects", [downloadedPhotoList length]/7);
		
		if ([downloadedPhotoList length] > 0) {
			
			//NSLog(@"DOWNLOADER.updatePhotoStuatuses: updating datebase for %i new photos", [downloadedPhotoList length]/7);
			
			[downloadedPhotoList deleteCharactersInRange:NSMakeRange([downloadedPhotoList length] - 1, 1)];
			
			//NSLog(@"Downloaded photo list = %@", downloadedPhotoList);
			
			NSString *query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_x100px_photo = 1 WHERE rowid IN (%@)", downloadedPhotoList];
			
			NSLog(@"Query = %@", query);
			[db executeUpdate:@"BEGIN TRANSACTION"];
			[db executeUpdate:query];
			[db executeUpdate:@"END TRANSACTION"];
		}
        
		[downloadedPhotoList release];
	}
    
    [db close];
    [db release];
    
    
    //if ([Props global].appID == 1) //[self finalizeUpdate];
    
    if ([Props global].appID != 1 && ![Props global].isShellApp) {
        UIAlertView *updateAlert = [[UIAlertView alloc] initWithTitle:@"Content update downloaded" message:@"Would you like to download the content updates now? (you can keep using the guide during the update)" delegate:self cancelButtonTitle:@"Not now" otherButtonTitles:@"Yup!", nil];
        
        updateAlert.tag = kContentUpdateDownloadedAlertTag;
        [updateAlert show];
        [updateAlert release];
    }
    
    NSString *theFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].cacheFolder];
    
    @synchronized ([Props global].dbSync) {
        
        [[NSFileManager defaultManager] removeItemAtPath:theFilePath error:nil];
        [[NSFileManager defaultManager] moveItemAtPath:unzippedFilePath toPath: theFilePath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:unzippedFilePath error:nil];
        
        [EntryCollection resetContent];
        [EntryCollection sharedEntryCollection];
        //[[FilterPicker sharedFilterPicker] resetContent];
        //[[MapViewController sharedMVC] reset]; //This needs to be after setting up props dictionary, as calling this for the first time before setting the app id causes problems
        //[FilterPicker resetContent];
        //[Props global].dataDownloaderShouldCheckForUpdates = TRUE;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kContentUpdated object:nil];
    }
    
    NSLog(@"EAD.updateContent: Database updated with latest images, %0.2f", -[date timeIntervalSinceNow]);
    
    [autoreleasepool release];
}


- (void) finalizeUpdate {
    
    //Replace old database with new one once everything is good to go
    
    NSString *theFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].cacheFolder];
    
    NSString *unzippedFilePath;   
    
    if ([Props global].appID != 1 && ![Props global].isShellApp)
        unzippedFilePath= [NSString stringWithFormat:@"%@/%i.sqlite3", [Props global].cacheFolder, [Props global].appID];
    
    else
        unzippedFilePath= [NSString stringWithFormat:@"%@/1.v2.sqlite3", [Props global].cacheFolder];
    
    @synchronized ([Props global].dbSync) {
        
        [[NSFileManager defaultManager] removeItemAtPath:theFilePath error:nil];
        [[NSFileManager defaultManager] moveItemAtPath:unzippedFilePath toPath: theFilePath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:unzippedFilePath error:nil];
    }
}
*/

#pragma mark
#pragma mark Transition to test app or Sutro World

- (void) showTestApp: (NSNotification*) aNotification {

	NSLog(@"Got message to show test app");
	
	flipView = [[FlipViewController alloc] initWithAppDelegate: self startingImage:[self takeScreenshot] andDestination:kTestAppLogin];
	flipWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
	
	[flipWindow addSubview:flipView.view];
	[flipWindow makeKeyAndVisible];
	
	self.portraitWindow = nil;
	
	[self performSelector:@selector(flipViews:) withObject:nil afterDelay:.1];
}


- (void) flipToOrFromSutroWorld: (NSNotification*) aNotification {
	
	NSLog(@"Got message to show Sutro World");
	
	NSString *destination;
	
	if ([Props global].appID != 0 && ![Props global].inTestAppMode) destination = kSutroWorld;
	
	else if ([Props global].appID == 0 || [Props global].inTestAppMode) destination = kOriginalApp;
	
	else {NSLog(@"WARNING, EntriesAppDelegate - In situation we didn't think of"); destination = nil;}
	
	
	flipView = [[FlipViewController alloc] initWithAppDelegate: self startingImage:[self takeScreenshot] andDestination:destination];
	flipWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
	[flipWindow addSubview:flipView.view];
	[flipWindow makeKeyAndVisible];
	
	self.portraitWindow = nil;
	
	[self performSelector:@selector(flipViews:) withObject:nil afterDelay:.1];
}


- (void) flipViews: (id) sender {
	
	[flipView flipViews];
}


- (void)transitionDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {

	[flipView.view removeFromSuperview];
	NSLog(@"EAD.transitionDidStop:");
}


- (void)finishedHidingLogin:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	
	[flipView.view removeFromSuperview];
	
}


- (void) showLoginScreen {
	
	testAppView = [[TestAppView alloc] initWithAppDelegate: self];
	loginWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
	
	[loginWindow addSubview:testAppView.view];
	[loginWindow makeKeyAndVisible];
	
	[flipView.view removeFromSuperview];
	
}


- (void) hideTestAppLogin {

	flipView = [[FlipViewController alloc] initWithAppDelegate: self startingImage:[self takeScreenshot] andDestination:kTestApp];
	//flipWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenHeight, [Props global].screenHeight)];
	
	[self.portraitWindow addSubview:flipView.view];
	//[flipView hideLoginScreen];	 
}


#pragma mark
#pragma mark Taking Screenshots
- (void) addScreenshotButton {
	
	float screenshotButtonTag = 2439087;
	
	for (UIView *view in [portraitWindow subviews]){
		if (view.tag == screenshotButtonTag) [view removeFromSuperview];
	}
	
	CGRect frame;
	UIImage *camera; 
	//UIImage *rotatedCamera = camera;
	
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	
	if (orientation == UIDeviceOrientationLandscapeRight) {
		
		//NSLog(@"In landscape right");
		camera = [UIImage imageNamed:@"screenshot_lr.png"];
		//rotatedCamera = [self rotateImage:camera rotationAngle:.5];
		frame = CGRectMake([Props global].screenWidth * .35, [Props global].screenHeight + 100, camera.size.width, camera.size.height);
	}
	
	else if (orientation == UIDeviceOrientationLandscapeLeft) {
		
		//NSLog(@"In landscape left");
		camera = [UIImage imageNamed:@"screenshot_ll.png"];
		frame = CGRectMake( [Props global].screenWidth * .1, 0, camera.size.width, camera.size.height);
	}
	
	else if (orientation == UIDeviceOrientationPortrait || orientation == 0 || orientation == UIDeviceOrientationFaceUp) {
		
		camera = [UIImage imageNamed:@"screenshot.png"];
		frame = CGRectMake(0, [Props global].screenHeight * .6, camera.size.width, camera.size.height);
		//NSLog(@"In portrait right side up");
	}
	
	else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
		
		camera = [UIImage imageNamed:@"screenshot_upsidedown.png"];
		frame = CGRectMake([Props global].screenWidth - camera.size.width, [Props global].screenHeight * .4 - camera.size.height, camera.size.width, camera.size.height);
		//NSLog(@"In portrait upside down");
	}
	
		
	else {
		NSLog(@"******************ERROR*********************** EAP.addScreenshotButton: orientation not found");
		camera = [UIImage imageNamed:@"screenshot.png"];
		frame = CGRectMake(0, [Props global].screenHeight * .6, camera.size.width, camera.size.height);
	}
	
	UIButton *screenshotButton = [UIButton buttonWithType:0];
	[screenshotButton setImage:camera forState:UIControlStateNormal];
	[screenshotButton setTitle:@"Get screenshot" forState: UIControlStateNormal];
	[screenshotButton addTarget:self action:@selector(getScreenshot:) forControlEvents:UIControlEventTouchUpInside];
	screenshotButton.frame = frame;
	screenshotButton.tag = screenshotButtonTag;
    screenshotButton.alpha = .9;
	screenshotButton.backgroundColor = [UIColor clearColor];
	[portraitWindow addSubview:screenshotButton];
}


- (void) getScreenshot:(id) sender {
	
	[sender removeFromSuperview];
	
	UIImage *screenshot = [self takeScreenshot];
	
	UIView *loadingView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	loadingView.alpha = .5;
	loadingView.backgroundColor = [UIColor blackColor];
	
	CGRect frame = CGRectMake(([Props global].screenWidth - 30)/2, ([Props global].screenHeight - 30)/2, 30, 30);
	UIActivityIndicatorView *progressInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
	
	[progressInd startAnimating];
	progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
	[progressInd sizeToFit];
	[loadingView addSubview:progressInd];
	
	[portraitWindow addSubview:loadingView];
	
	[[ActivityLogger sharedActivityLogger] uploadImage:UIImageJPEGRepresentation(screenshot, 1.0)];
	
	[loadingView removeFromSuperview];
	[portraitWindow addSubview:sender];
}


- (UIImage*) takeScreenshot {
	
	CGSize imageSize = [[UIScreen mainScreen] bounds].size;
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
			if (window == self.portraitWindow) {
				// -renderInContext: renders in the coordinate space of the layer,
				// so we must first apply the layer's geometry to the graphics context
				CGContextSaveGState(context);
				// Center the context around the window's anchor point
				CGContextTranslateCTM(context, [window center].x, [window center].y);
				// Apply the window's transform about the anchor point
				CGContextConcatCTM(context, [window transform]);
				// Offset by the portion of the bounds left of and above the anchor point
				CGContextTranslateCTM(context,-[window bounds].size.width * [[window layer] anchorPoint].x,-[window bounds].size.height * [[window layer] anchorPoint].y);
				
				// Render the layer hierarchy to the current context
				[[window layer] renderInContext:context];
				
				// Restore the context
				CGContextRestoreGState(context);
			}
        }
    }
	
    // Retrieve the screenshot image
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
	
    UIGraphicsEndImageContext();
	
	return screenshot;
}

/*
- (void) generateSquareIcons {
	
	NSLog(@"Starting to square icons");
	
	NSString *theFolderPath = [NSString stringWithFormat:@"%@/images",[Props global].contentFolder];
	
	if([[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath] || [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ])
		NSLog(@"Created folder");
	
	for (Entry *theEntry in [EntryCollection sharedEntryCollection].allEntries) {
		
		//UIImage *bigImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i",theEntry.icon] ofType:@"jpg"]];
		
		UIImage *bigImage = [UIImage imageNamed:[NSString stringWithFormat:@"%i.jpg",theEntry.icon]];
		
		if (bigImage == nil) bigImage = [[[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%0.0f.jpg", theFolderPath, theEntry.icon]] autorelease];
		
		CGRect imageRect;
		
		if (bigImage.size.width > bigImage.size.height) imageRect = CGRectMake((bigImage.size.width - bigImage.size.height)/2, 0, bigImage.size.height, bigImage.size.height);
		
		//UIImage *croppedImage = [self imageByCropping:bigImage toRect:imageRect];
		
		UIImage *thumbnail; // = [croppedImage imageByScalingProportionallyToSize:CGSizeMake(45, 45)];
		UIImage *background = [UIImage imageNamed:@"Marker_background.png"];
		
		UIGraphicsBeginImageContext(CGSizeMake(45, 45));
		
		//CGRect thumbnailRect = CGRectZero;
		//thumbnailRect.origin = thumbnailPoint;
		//thumbnailRect.size.width  = scaledWidth;
		//thumbnailRect.size.height = scaledHeight;
		
		
		[bigImage drawInRect:CGRectMake(0, 0, 45, 45)];
		
		thumbnail = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		UIGraphicsBeginImageContext(CGSizeMake(49, 49));
		[background drawInRect:CGRectMake(0, 0, 49, 49)];
		//[thumbnail drawInRect:CGRectMake(2, 2, 45, 45)];
		UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		NSData *theData = UIImagePNGRepresentation(newImage);
		
		//Write the data to disk
		NSError * theError = nil;
		
		NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i-icon.png",[Props global].contentFolder , theEntry.entryid];
		
		if([theData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) NSLog(@"DETAILVIEW.createMapIconForMap: Error writing image, %@", theError.userInfo);
		
		//if (bigImage != nil) [bigImage release];
	}
	
	NSLog(@"Finishing squaring icons");
}*/


- (UIImage *)imageByCropping:(UIImage *)imageToCrop toRect:(CGRect)rect
{
	CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], rect);
	
	UIImage *cropped = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	
	
	return cropped;	
}



- (void)application:(UIApplication *)application willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation duration:(NSTimeInterval)duration {
    
	NSLog(@"EAP.application:willChangeStatusBarOrientation...");
}


- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {

    return UIInterfaceOrientationMaskAll;
}


- (void) detectOrientation {
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    //NSLog(@"EAP.detectOrientation: orientation = %u and last orientation = %u", orientation, [Props global].lastOrientation);
    
    if (orientation != UIDeviceOrientationFaceDown && orientation != UIDeviceOrientationFaceUp && orientation != [Props global].lastOrientation && orientation != UIDeviceOrientationUnknown) {
        
       // NSLog(@"EAP.ORIENATIONDIDCHANGE");
        
        [Props global].lastLastOrientation = [Props global].lastOrientation;
        [Props global].lastOrientation = orientation;
        
        [[Props global] updateScreenDimensions: (UIInterfaceOrientation)[[UIDevice currentDevice] orientation]];
        
        if ([Props global].inTestAppMode) [self addScreenshotButton];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kOrientationChange object:nil];
    }
}


- (NSString*) crashReportUserID {

	return [Props global].deviceID;
}

- (BOOL) shouldShowWiFiAlert {
	
	// Warn iPod Touch users that are off the grid that they're missing out
	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"shownWiFiAlert"] && ([[[UIDevice currentDevice] model] isEqualToString: @"iPod touch"] || [[[UIDevice currentDevice] model] isEqualToString: @"iPhone Simulator"]) && ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) && ![Props global].inTestAppMode)
		return TRUE;
	
	else return FALSE;	
}


- (void) showWiFiAlert2: (id) sender {
	
	NSLog(@"Show alert2 called from app delegate");
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: nil message:@"You've got lots of additional pictures waiting for download. If you can, use the app when WiFi is available to get them."
												   delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
	[alert show];
	
	[[NSUserDefaults standardUserDefaults] setBool:TRUE  forKey:@"shownWiFiAlert"];
}


- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    
    NSLog(@"EAD.applicationDidReceiveMemoryWarning:****************************************************************************************");
    [self print_free_memory];
	
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
	
    for (Entry * e in [EntryCollection sharedEntryCollection].allEntries) {
        e.iconImage = nil;
    }
    
    [self print_free_memory];
    
	/*SMLog *log = [[SMLog alloc] initWithPageID: kError actionID: kLowMemory];
     [[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
     [log release];*/
}


- (void) print_free_memory {
    
	mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);        
	
    vm_statistics_data_t vm_stat;
	
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        NSLog(@"Failed to fetch vm statistics");
	
    /* Stats in bytes */ 
    natural_t mem_used = (vm_stat.active_count +
                          vm_stat.inactive_count +
                          vm_stat.wire_count) * pagesize;
    natural_t mem_free = vm_stat.free_count * pagesize;
    natural_t mem_total = mem_used + mem_free;
    NSLog(@"used: %u mb free: %u mb total: %u mb", mem_used/(1024*1024), mem_free/(1024*1024), mem_total/(1024*1024));
}


@end

