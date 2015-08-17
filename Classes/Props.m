/*
 
 File: Props.m
 Abstract: Class for importing and accessing application wide properites.
 
 Version: 1.0
 
 */

#import "Props.h"
#import "FilterPicker.h"
#import	"Constants.h"
#import	"ActivityLogger.h"
#import "EntryCollection.h"
#import "Reachability.h"
#include <stdlib.h>
#import "UIDevice+IdentifierAddition.h"

#define UIColorFromRGB(rgbValue) [UIColor \
	colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
	green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
	blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define kPaid @"Paid first download"
#define kFree @"Free first download"

@implementation Props


@synthesize appName, free, filters, currentFilter, subtitleFont, inTestAppMode, isTestAppDevice, contentFolder, cacheFolder, documentsFolder, mapRegion, appID, showPremiumContent, deviceType, hasSpatialCategories, hasPrices, hasLocations, freeImageArray, defaultSort, appShortName, unitsInMiles, spatialCategoryName, mapsNeedUpdating, entryCollectionNeedsUpdate, sessionID, deviceID, defaultMapType, hasRichText, appLink, authorName, bundleVersion, commentsDatabaseNeedsUpdate, showComments, aboutSutroHTML, aboutSutroHTML_NoInternet, pitchesDatabaseNeedsUpdate, svnRevision, reviewURL, hasAbstractPrices, abstractPriceSymbol, dbSync,mapDbSync, dataDownloaderShouldCheckForUpdates, osVersion, sortable, taxiServicePhoneNumber, taxiServiceMinimumCharge, taxiServiceChargePerDistance, currencyString, currentFilterPickerRow, currentFilterPickerTitle, lastOrientation, lastLastOrientation, isShellApp, killDataDownloader, deviceShowsHighResIcons, hasDeals, downloadTestAppContent, showAds, mapDatabaseLocation, firstVersion, contentUpdateInProgress, serverContentSource, offlineLinkURLs, connectedToInternet, concurrentDownloads, serverDatabaseUpdateSource, latitudeSpan, isFreeSample, previousBundleVersion, freemiumType, freemiumNumberofSampleEntriesAllowed;


@synthesize startingZoomLevel, innermostZoomLevel;


//formatting properties
@synthesize navigationBarTint, navigationBarTint_entryView, descriptionTextColor, LVEntryTitleTextColor, LVEntrySubtitleTextColor, LVBGView, LVBGView_selected, entryViewBGColor, linkColor, fontName, cssTextColor, cssLinkColor, cssNonactiveLinkColor, cssExternalLinkColor, tableviewRowHeight, tableviewRowHeight_libraryView, screenWidth, screenHeight, tweenMargin, leftMargin, rightMargin, tinyTweenMargin, bodyTextFontSize, adminSuffix, titleBarHeight, bodyFont, tabBarHeight, browseViewVariation, landscapeSideMargin, portraitSideMargin;


- (id)init {
    
    self = [super init];
	if (self) {
		
        idleRefCount = 0;
		[self setBasicProps];
		dbSync = [[NSObject alloc] init];
        mapDbSync = [[NSObject alloc] init];
		
		//hostReach = [[Reachability reachabilityWithHostName: NSLocalizedString(@"SERVICE_HOST_URL", nil)] retain];
		//[hostReach startNotifier];
		//[self updateReachabilityStatus:hostReach];
		
		//Internet reachability
		[self updateInternetStatus];
		
		//This wasn't working reliably
		//[Reachability sharedReachability].networkStatusNotificationsEnabled = YES;
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:@"kNetworkReachabilityChangedNotification" object:nil];
		
		[NSTimer  scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateInternetStatus) userInfo:nil repeats:YES];
	}
    
	return self;
}


//Set props that do not require calling EntryCollection
- (void) setBasicProps {
    
	//Device info
	self.osVersion				= [[[[UIDevice currentDevice] systemVersion] substringToIndex:3] floatValue];
	self.screenWidth			= [UIScreen mainScreen].bounds.size.width;
	self.screenHeight			= [UIScreen mainScreen].bounds.size.height;
	self.inTestAppMode          = FALSE;
    self.isTestAppDevice        = FALSE;
	self.commentsDatabaseNeedsUpdate = FALSE;
	self.dataDownloaderShouldCheckForUpdates = TRUE;
	self.pitchesDatabaseNeedsUpdate = FALSE;
	originalAppId				= kValueNotSet;
	self.appID =				[self getOriginalAppId];
    self.isShellApp = self.appID == 1 ? TRUE : FALSE;
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)])
        self.deviceID	= [[[[UIDevice currentDevice] identifierForVendor] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    else self.deviceID = [[UIDevice currentDevice] uniqueGlobalDeviceIdentifier];
    
    
    self.serverContentSource = nil;
    availableSources = nil;
    self.concurrentDownloads = 0;
    //NSLog(@"\n\n\n********** WARNING: CONTENT SERVER SET TO TEST SERVER *************\n\n\n");
    //self.serverDatabaseUpdateSource = @"http://www.sutromedia.com/published/content-test";
    self.serverDatabaseUpdateSource = @"http://www.sutromedia.com/published/content";
    
    [self performSelectorInBackground:@selector(updateServerContentSource) withObject:nil];
    
    self.browseViewVariation = kTaglineOnlyWithCost;
    
    /*if (self.isShellApp || self.appID != 3) self.browseViewVariation = kTaglineOnlyWithCost;
    
    else { //A-B test on browse variation for SF Explorer
        
        NSString *_browseVariation = [[NSUserDefaults standardUserDefaults] stringForKey:@"browse variation"];
        
        if (_browseVariation == nil) {
            
            int randomNumber = arc4random() % 2;
            
            NSLog(@"Random number = %i", randomNumber);
            if (randomNumber == 1) self.browseViewVariation = kTaglineOnlyWithCost;
            else self.browseViewVariation = kTaglineAndDescription;
            
            [[NSUserDefaults standardUserDefaults] setObject:self.browseViewVariation forKey:@"browse variation"];
        }
    }*/

    
    self.startingZoomLevel      = 14;
    
    if ([[[UIDevice currentDevice] model] isEqualToString: @"iPhone"]) self.deviceType = kiPhone;
	
	else if ([[[UIDevice currentDevice] model] isEqualToString:@"iPhone Simulator"]) self.deviceType = kSimulator;
    
	else if ([[[UIDevice currentDevice] model] isEqualToString:@"iPod touch"]) self.deviceType = kiPodTouch;
	
	else if ([[[UIDevice currentDevice] model] isEqualToString:@"iPad"]) self.deviceType = kiPad;
	
	else if ([[[UIDevice currentDevice] model] isEqualToString:@"iPad Simulator"]) self.deviceType = kiPad;
    
	else {self.deviceType = 0; NSLog(@"ERROR: Props, something weird with device type ***************************");}

    self.deviceShowsHighResIcons = [[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && [UIDevice currentDevice].multitaskingSupported; //Multitasking support is a good proxy for having a fast enough processor to deal with high res icons
    
    //Set file location shortcuts
    self.documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //self.cacheFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    self.cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    self.mapDatabaseLocation    = [NSString stringWithFormat:@"%@/offline-map-tiles.sqlite3", self.documentsFolder];
    
    self.filters = nil;
    self.lastOrientation = UIDeviceOrientationPortrait;
    self.downloadTestAppContent = FALSE;
    
	
    //Props not used 
    self.free = FALSE;
	self.showPremiumContent = TRUE;
    self.hasRichText			= FALSE;
	self.entryCollectionNeedsUpdate = FALSE;
	
    //unchanging formatting props (other conditional formatting props set in "setupPropsDictionary"
    self.cssTextColor           = @"#424242";
    self.cssLinkColor           = @"#3678BF";
    self.cssNonactiveLinkColor  = @"6B839C"; //Not used
    self.cssExternalLinkColor   = @"#5183D5"; //just a bit darker than the test links
    self.tinyTweenMargin		= self.deviceType == kiPad ? 9 : 6; //self.screenHeight/84;
	self.tweenMargin			= self.deviceType == kiPad ? 20 : 12; // self.screenHeight/40;
	self.bodyTextFontSize		= self.deviceType == kiPad ? 19 : 15;
    self.landscapeSideMargin    = self.deviceType == kiPad ? 40 : 20;
    self.portraitSideMargin     = self.deviceType == kiPad ? 25 : 12;
	self.rightMargin			= [self inLandscapeMode] ? self.landscapeSideMargin : self.portraitSideMargin;
	self.leftMargin				= self.rightMargin;
    self.fontName               = @"Arial";
    self.bodyFont               = [UIFont fontWithName:self.fontName size:self.bodyTextFontSize];
    self.subtitleFont           = (deviceType == kiPad) ? [UIFont fontWithName:@"Arial-BoldMT" size: 21] : [UIFont fontWithName:@"Arial-BoldMT" size: 16];
    self.tabBarHeight           = kTabBarHeight;
    self.titleBarHeight         = 44;
    
    if ([self.browseViewVariation  isEqual: kTaglineOnlyWithCost]) 
        self.tableviewRowHeight		= self.deviceType == kiPad ? 67 : 57; //Three line variation
    
    else self.tableviewRowHeight	= self.deviceType == kiPad ? 82 : 69;
    
    self.tableviewRowHeight_libraryView = self.deviceType == kiPad ? 65 : 55;
}


//Props set from app data from database or conditional properties that need to be changed on switchover to sutroworld or test app
- (void)setupPropsDictionary {
	
    NSLog(@"PROPS.setupPropsDictionary");
	
    FMDatabase * db;
    
	@synchronized([Props global].dbSync) {
		db = [EntryCollection sharedContentDatabase];
        
		FMResultSet * rs = [db executeQuery:@"SELECT name FROM groups ORDER BY name"];
		//NSLog(@"Props.setupPropsDictionary:lock");
		
		if ([db hadError]) NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		
		// set up filters array
		//if (self.filters != nil) [self.filters release];
		//filters = nil;
        NSMutableArray *tmpFiltersArray = [NSMutableArray new];
        self.filters = tmpFiltersArray; // only happens once, throw memory into the wind :)
        
		while ([rs next]) [self.filters addObject:[rs stringForColumn:@"name"]];
		
		if([filters count] == 0)
			filters = nil;
		
		[rs close];
	}
	
	NSMutableDictionary *propertiesDict = [NSMutableDictionary new];
	
	@synchronized([Props global].dbSync) {
		
		FMResultSet *rs = [db executeQuery:@"SELECT key,value FROM app_properties"];
		
		
		while ([rs next]) {
			[propertiesDict setObject:[rs stringForColumn:@"value"] forKey:[rs stringForColumn:@"key"] ];
		}
		[rs close];
	}
	
	//Set the map coordinate properties
	MKCoordinateSpan span;
	// adjustment necessary after changing height of map view (to show google logo) after fitting the views
	span.latitudeDelta = [[propertiesDict valueForKey:@"map_latitude_delta"] floatValue]; // 0.107;
	span.longitudeDelta = [[propertiesDict valueForKey:@"map_longitude_delta"] floatValue]; //0.11;
	
	CLLocationCoordinate2D location2; 
	
	location2.latitude = [[propertiesDict valueForKey:@"map_center_latitude"] floatValue]; //kSanFranLatitude; 
	location2.longitude= [[propertiesDict valueForKey:@"map_center_longitude"] floatValue]; //kSanFranLongitude;
	
	mapRegion.span= span;
	mapRegion.center=location2;
    self.latitudeSpan = span.latitudeDelta; //this value is used for error checking when centering the map on 
    self.startingZoomLevel      = fmax(9.24561688214405 - 3.3203169287079 * log10(mapRegion.span.latitudeDelta * 2), 1.5);
    if (self.deviceType == kiPad) self.startingZoomLevel ++; //Add a bit to the zoom for the ipad

	self.innermostZoomLevel     = [[propertiesDict valueForKey:@"map_innermost_zoom_level"] floatValue];
    
    self.sessionID				= [[NSDate date] timeIntervalSince1970];
	self.appName				= [propertiesDict objectForKey:@"app_name"];
	self.appShortName			= [propertiesDict objectForKey:@"app_short_name"];
	self.adminSuffix			= [propertiesDict valueForKey:@"admin_suffix"];
	self.aboutSutroHTML			= [propertiesDict objectForKey:@"sutro_entry_html"];
	self.aboutSutroHTML_NoInternet	= [propertiesDict objectForKey:@"sutro_entry_html_no_internet"];
	self.appLink				= [propertiesDict objectForKey:@"app_url"];
	self.abstractPriceSymbol	= [propertiesDict objectForKey:@"abstract_price_symbol"];
	self.authorName				= [propertiesDict objectForKey:@"authors"];
	self.contentFolder			= [NSString stringWithFormat:@"%@/%i", self.cacheFolder, self.appID];
	self.currencyString			= [propertiesDict valueForKey:@"currency_string"];
	self.defaultMapType			= [[propertiesDict valueForKey:@"default_map_type"] intValue];
	self.hasSpatialCategories	= ([[propertiesDict valueForKey:@"has_spatial_groups"] intValue] == 1) ? TRUE : FALSE;
	self.hasPrices				= ([[propertiesDict valueForKey:@"has_prices"] intValue] == 1) ? TRUE : FALSE;
	self.hasLocations			= ([[propertiesDict valueForKey:@"has_locations"] intValue] == 1) ? TRUE : FALSE;
    self.defaultSort            = [propertiesDict valueForKey:@"default_sort_option"];
	self.mapsNeedUpdating		= ([[propertiesDict valueForKey:@"maps_need_updating"] intValue] == 1) ? TRUE : FALSE;
	self.unitsInMiles			= [[propertiesDict valueForKey:@"distance_units"] isEqualToString:@"mi"] ? TRUE : FALSE;
	self.reviewURL				= [propertiesDict objectForKey:@"review_url"];
	self.hasAbstractPrices		= ([[propertiesDict valueForKey:@"has_abstract_prices"] intValue] == 1) ? TRUE : FALSE;
	self.showComments			= ([[propertiesDict valueForKey:@"has_comments"] intValue] == 1) ? TRUE : FALSE;
	self.svnRevision			= [[propertiesDict objectForKey:@"svn_revision"] intValue];
    
    //Need to save the SVN revision value in the event that a database is downloaded dynamically
    if (self.svnRevision > 0) [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:svnRevision] forKey:@"svn_revision"];
    else self.svnRevision = [[[NSUserDefaults standardUserDefaults] valueForKey:@"svn_revision"] intValue];
    
    self.bundleVersion			= [[propertiesDict objectForKey:@"bundle_version"] intValue];
	self.spatialCategoryName	= [propertiesDict valueForKey:@"spatial_groups_name_singular"];
	self.taxiServiceMinimumCharge = [[propertiesDict objectForKey:@"taxi_service_minimum_charge"] floatValue];
	self.taxiServiceChargePerDistance = [[propertiesDict objectForKey:@"taxi_service_charge_per_distance"] floatValue];
	self.taxiServicePhoneNumber = [propertiesDict objectForKey:@"taxi_service_phone"];
	if([taxiServicePhoneNumber length] == 0) self.taxiServicePhoneNumber = nil;
    //self.killDataDownloader     = TRUE;
    self.hasDeals               = FALSE; // [[propertiesDict valueForKey:@"has_deals"] intValue] == 1 ? TRUE : FALSE;
    
    int suggestedPriceTier = [[propertiesDict objectForKey:@"suggested_price_tier"] intValue];
	
    
	//********************  Determine type of freemium upgrade depending on when the user first bought the app and set defaults as necessary *****************
	
	//If it's been downloaded for the first time, then do whatever it says to do in the DB
	//If it's been downloaded before, then keep the free state as it was
	
	//Possible states and how to handle them
	// 1. Previously upgraded -> mark it as offline upgrade purchased
	// 2. Downloaded as paid previously -> mark it as offline upgrade purchased
	// 3. Downloaded as free type x previously -> keep the free type the same as it was before
	// 4. first time download -> do whatever the db (or hardcoded info) says to do
	
	/*
	//Don't need to do any of this for a shell app
	if (!self.isShellApp) {
		
		//Case 1 - Already upgraded
		if ([[NSUserDefaults standardUserDefaults] boolForKey:kOfflineUpgradePurchased])[[NSUserDefaults standardUserDefaults] setObject:kPaid forKey:kInitialDownloadPrice]; //Free type doesn't matter if it's already been upgraded
		
		//Case 2 - Downloaded as paid previously
		//Old install that should be automatically upgraded
		//check both first version and documents folder in case the cache folder was deleted
		else if ((self.previousBundleVersion > 0 || firstVersion > 0) && (firstVersion <= 24849 || self.previousBundleVersion <= 24849)) [[NSUserDefaults standardUserDefaults] setObject:@"paid" forKey:kInitialDownloadPrice];
		
		//Old install that was previously free and shouldn't be upgraded
		else if ((self.previousBundleVersion > 24849 || firstVersion > 24849) && ![[NSUserDefaults standardUserDefaults] boolForKey:kOfflineUpgradePurchased])[[NSUserDefaults standardUserDefaults] setObject:kFree forKey:kFree];
		
		//First figure out if it has been previously downloaded or if this is a fresh install
		NSString *firstVersionFilename = [NSString stringWithFormat:@"%@/first_version.txt", self.documentsFolder];
		self.firstVersion = [[NSString stringWithContentsOfFile:firstVersionFilename encoding:NSUTF8StringEncoding error:nil] intValue];
		
		//If firstVersion has not been set (and thus equals zero) and previousBundleVersion = 0, we can be pretty confident that this is a fresh install
		if (self.firstVersion == 0 && self.previousBundleVersion == 0){ //previousBundleVersion is set in EntryAppDelegate based on the DB left in the docs folder
		}
	}
	*/
	

	
	// Need to initiate this process before moving the db to the docs folder, which would overwrite the old db. More code on this after opening the DB
	//NSString *initialDownloadPrice = [[NSUserDefaults standardUserDefaults] stringForKey:kInitialDownloadPrice];
	
	//We keep track of first version as a placeholder in case we need to know this for something in the future
	NSString *firstVersionFilename = [NSString stringWithFormat:@"%@/first_version.txt", self.documentsFolder];
	self.firstVersion = [[NSString stringWithContentsOfFile:firstVersionFilename encoding:NSUTF8StringEncoding error:nil] intValue];
	
	self.freemiumType = [[NSUserDefaults standardUserDefaults] integerForKey:kFreemiumType];
	
	//We don't use freemiumType for the shell app and we automatically upgrade all test app users
	if (self.inTestAppMode || self.isShellApp) self.freemiumType = kFreemiumType_Paid;
	
	//Nothing needs to be done if the value is already set
	else if (self.freemiumType > kFreemiumType_NotSet) NSLog(@"PROPS.setupPropsDictionary: Freemium type previously set to %i", self.freemiumType); //Most previously installed apps should have this value set by this point from the runStartupTasks method in EntriesAppDelegate
	
	//Freemium type not yet set
	else { 
		
		//Either a first install or an upgrade of a really old app (where the db is in the docs folder) - set price to whatever it is in the db
		if (firstVersion == 0 && self.previousBundleVersion == 0) {
			
			if(suggestedPriceTier == -1) {
				
				NSSet *freeSampleSet = [NSSet setWithObjects:
                                        [NSNumber numberWithInt:9999] // i just put this in as a holder to prevent errors JS 10/29/13
//                                        [NSNumber numberWithInt:572], [NSNumber numberWithInt:317], [NSNumber numberWithInt:349], [NSNumber numberWithInt:460], [NSNumber numberWithInt:90], [NSNumber numberWithInt:703], [NSNumber numberWithInt:461], [NSNumber numberWithInt:747], [NSNumber numberWithInt:559], [NSNumber numberWithInt:505], [NSNumber numberWithInt:263]
                                        , nil];
				
				if ([freeSampleSet containsObject:[NSNumber numberWithInt:self.appID]]) self.freemiumType = kFreemiumType_V2;
				
				else self.freemiumType = kFreemiumType_V1;
			}
			
			else self.freemiumType = kFreemiumType_Paid;
		}
			
		//Old install that should be automatically upgraded
		//check both first version and documents folder in case the cache folder was deleted
		else if (firstVersion <= 24849 || self.previousBundleVersion <= 24849) self.freemiumType = kFreemiumType_Paid;
		
		//Old install that was previously free and should be kept as a freemium V1 type
		else if (self.previousBundleVersion > 24849 || firstVersion > 24849) self.freemiumType = kFreemiumType_V1;
		
		//This case should never happen, but I am including it to play it safe in case I'm missing something.
		else {
			NSLog(@"\n\n\n****** ERROR: PROPS.setupPropsDictionary: Price setting logic is not working! **********\n\n\n");
			self.freemiumType = kFreemiumType_Paid;
		}
		
		[[NSUserDefaults standardUserDefaults] setInteger:self.freemiumType forKey:kFreemiumType]; //Update user defaults now that this has been set
	}
	
	
	//Record or update the first version as necessary
	if (self.firstVersion == 0) {
		
		if (self.previousBundleVersion > 0) self.firstVersion = self.previousBundleVersion;
		
		else self.firstVersion = self.bundleVersion;
		
		[[NSString stringWithFormat:@"%i", self.firstVersion] writeToFile:firstVersionFilename atomically:YES encoding: NSUTF8StringEncoding error: NULL];
	}
	
    	
	if (self.freemiumType != kFreemiumType_V1) {
		
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kOfflinePhotos]; //starts downloading offline maps ---- might not be using this anymore, need to check
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kOfflineMaps]; //starts downloading offline photos ---- might not be using this anymore, need to check
    }
	
	if (self.freemiumType == kFreemiumType_V2) {
		self.freemiumNumberofSampleEntriesAllowed = [[NSUserDefaults standardUserDefaults] integerForKey:@"Number of sample entries allowed"];
		
		if (self.freemiumNumberofSampleEntriesAllowed == 0) {
			self.freemiumNumberofSampleEntriesAllowed = 10;
			[[NSUserDefaults standardUserDefaults] setInteger:self.freemiumNumberofSampleEntriesAllowed forKey:@"Number of sample entries allowed"];
		}
	}
    
	
	// ***** End of freemium upgrade code
	
    self.hasSpatialCategories	= ([[propertiesDict valueForKey:@"has_spatial_groups"] intValue] == 1) ? TRUE : FALSE;
    
    @synchronized([Props global].dbSync) {
		
		FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) AS count FROM entries WHERE spatial_group_name <> \"\""];
		if ([rs next] && ([rs intForColumn:@"count"] == 0)) self.hasSpatialCategories = NO;
		[rs close];
	}
    
    self.sortable	= (hasPrices || hasLocations || hasSpatialCategories);
    
   // if (self.inTestAppMode) {
    //    self.browseViewVariation =    kTaglineOnlyWithCost;
    //    self.tableviewRowHeight		= self.deviceType == kiPad ? 67 : 57; //Three line variation
   // }
    
    self.showAds = self.freemiumType == kFreemiumType_V1 && self.osVersion >= 4.3;
	
    [[NSUserDefaults standardUserDefaults] setInteger:self.bundleVersion forKey:kBundleVersionKey];
	
	@synchronized([Props global].dbSync) {
		
		FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) AS count FROM entries WHERE spatial_group_name <> \"\""];
		if ([rs next] && ([rs intForColumn:@"count"] == 0)) self.hasSpatialCategories = NO;
		[rs close];
	}
    
    if ([Props global].appID != 1)[self buildOfflineLinkURLArray];
	
	//Formatting Props
	
	int navigationBarColorInt;
	int LVEntryTitleTextColorInt;
	int LVEntrySubtitleTextColorInt;
	int entryViewBGColorInt;
	int descriptionTextColorInt = 4342338;
	int linkColorInt  = 3569855;
	
	
	if (self.appID > 1) {
		
		navigationBarColorInt = 3552822;
		LVEntryTitleTextColorInt = 4342338;
		LVEntrySubtitleTextColorInt = 5855577;
		entryViewBGColorInt = 16777215;
		
        UIImage *tmpBackground = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LVBackground" ofType:@"png"]];
		self.LVBGView = tmpBackground;
        
        UIImage *selectedBackground = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LVBackground_selected" ofType:@"png"]];
		self.LVBGView_selected = selectedBackground;
		
		self.navigationBarTint_entryView = [UIColor blackColor];
        self.navigationBarTint = UIColorFromRGB(navigationBarColorInt);
	}
	
	else {
	
		//sutro dark grey #464646 or 70,70,70
		//navigationBarColorInt = 4605510;
		
		//sutro dark blue #0084B3 or 0,132,179
		navigationBarColorInt = 33971;
		
		LVEntryTitleTextColorInt = 4605510;
		LVEntrySubtitleTextColorInt = 4605510;
		
		//sutro light blue #E2F2FE or 226,242,254
		//entryViewBGColorInt = 14873342;
		
		//sutro light gray #999999 or 153,153,153
		//entryViewBGColorInt = 10066329;
		
		//light gray #EBEBEB or 235,235,235 or 8% gray
		entryViewBGColorInt = 15461355;
		
        UIImage *tmpImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LVBackground_sutro" ofType:@"png"]];
		self.LVBGView = tmpImage;
        
        UIImage *tmpImage2 = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LVBackground_selected" ofType:@"png"]];
		self.LVBGView_selected = tmpImage2;
    
		self.navigationBarTint_entryView = [UIColor colorWithRed:(0/255.0) green:(70.0/255.0) blue:(125.0/255.0) alpha:1.0];
        self.navigationBarTint = [UIColor colorWithRed:(0.0/255.0) green:(90.0/255.0) blue:(135.0/255.0) alpha:1.0];
	}
	
	self.LVEntryTitleTextColor = UIColorFromRGB(LVEntryTitleTextColorInt);
	self.LVEntrySubtitleTextColor = UIColorFromRGB(LVEntrySubtitleTextColorInt);
	self.entryViewBGColor = UIColorFromRGB(entryViewBGColorInt);
	self.descriptionTextColor = UIColorFromRGB(descriptionTextColorInt);
	self.linkColor = UIColorFromRGB(linkColorInt);
}


- (void) setTheAppID: (NSString*) theAppName {
	
	self.appName = theAppName; 

	NSString *theFilePath= [NSString stringWithFormat:@"%@/%@.plist", [Props global].cacheFolder, @"theAppList"];
	NSDictionary *appInfoDictionary = [[NSDictionary alloc] initWithContentsOfFile:theFilePath];
	
	NSDictionary *dictionaryOfApps = [[NSDictionary alloc] initWithDictionary:[appInfoDictionary objectForKey: @"applicationiddict"]];
	
	
	self.appID = [[dictionaryOfApps objectForKey:theAppName] intValue];
	
	
	self.contentFolder = [NSString stringWithFormat:@"%@/%i", cacheFolder, appID];
	
    self.free = FALSE;
}


- (BOOL) supportsAudioFiles {
	
	if(
	// Check to see if the device is one of the supported devices
	([[[UIDevice currentDevice] model] isEqualToString: @"iPhone"] || [[[UIDevice currentDevice] model] isEqualToString: @"iPhone Simulator"] /*|| [[[UIDevice currentDevice] model] isEqualToString: @"iPod touch"]*/) 
	
	&& // Then check to see if the operating system is one of the supported operating systems
	([[[[UIDevice currentDevice] systemVersion] substringToIndex:3] floatValue] >= 2.2)
		)
		
		return TRUE;
		
	else
		return FALSE;
}

- (int) getOriginalAppId {
	
	//NSLog(@"Get original app id called with original app id = %i", originalAppId);
	int theAppID = kValueNotSet;
	
	if (originalAppId == kValueNotSet) {
		
		NSString *binaryPackagePath = [[NSBundle mainBundle] pathForResource:@"content" ofType:@"sqlite3"];
		
		@synchronized(self.dbSync) {
			
			FMDatabase *tempDatabase = [[FMDatabase alloc] initWithPath:binaryPackagePath];
			
			if (![tempDatabase open]) {
				NSLog(@"Could not open sqlite database from file = %@", binaryPackagePath);
			}
			
			FMResultSet *rs = [tempDatabase executeQuery:@"SELECT key,Value FROM app_properties WHERE key = 'app_id'"];
			
			if ([rs next]) theAppID = [rs intForColumn:@"Value"];
			
			[rs close];
			[tempDatabase close];
		}
		
		originalAppId = theAppID;
	}
    
    //NSLog(@"PROPS.getOriginalAppId: Original App Id = %i", originalAppId);
	
	return originalAppId;
}


- (void) setContentFolder {
	
	self.contentFolder = [NSString stringWithFormat:@"%@/%i", cacheFolder, self.appID];

	//NSLog(@"Just set content folder to %@", self.contentFolder);		
}


- (void) updateScreenDimensions:(UIInterfaceOrientation)toInterfaceOrientation {
	
	//NSLog(@"PROPS.updateScreenDimensions for toInfaceOrientation = %u", toInterfaceOrientation);
    //self.screenWidth	= [UIScreen mainScreen].bounds.size.width;
	//self.screenHeight	= [UIScreen mainScreen].bounds.size.height;
	
    if ([self inLandscapeMode]) {
		self.screenWidth	= [UIScreen mainScreen].bounds.size.height;
		self.screenHeight	= [UIScreen mainScreen].bounds.size.width;
		self.titleBarHeight	= self.deviceType == kiPad ? 44 : 31;
        self.tabBarHeight   = kTabBarHeight - kPartialHideTabBarHeight;
        self.leftMargin     = self.deviceType == kiPad ? 30 : 15;
        self.rightMargin    = self.landscapeSideMargin;
        self.leftMargin     = self.landscapeSideMargin;
	}
	
	else if (toInterfaceOrientation != UIDeviceOrientationUnknown) {
		//NSLog(@"PROPS.updateScreenDimensions: setting orientation to portrait");
        self.screenWidth	= [UIScreen mainScreen].bounds.size.width;
		self.screenHeight	= [UIScreen mainScreen].bounds.size.height;
		self.titleBarHeight = 44;
        self.tabBarHeight   = kTabBarHeight;
        self.leftMargin     = self.portraitSideMargin;
        self.rightMargin    = self.portraitSideMargin;
	}
}

/*
- (float) titleBarHeight {

	if ([self inLandscapeMode]) return 31;
	else return 44;
}
*/

- (BOOL) inLandscapeMode {
	
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    
	if (UIDeviceOrientationIsLandscape(orientation)) return TRUE;
    
    else if (UIDeviceOrientationIsPortrait(orientation)) return FALSE;
    
    //This weirdness is necessary to work around situations where the orientation = UIDeviceOrientationUnKnown
    else if (deviceType == kiPad && screenWidth > 768) return TRUE;
    
    else if ((deviceType == kiPhone || deviceType == kiPodTouch) && screenWidth > 320) return  TRUE;
    
    else return FALSE;
}


- (void) incrementIdleTimerRefCount {
 
    if (idleRefCount < 0) {
        
        idleRefCount = 0;
        NSLog(@"*********ERROR Props.incrementRefCount: Ref count = %i, shound never be less than 0", idleRefCount);
    }
    
    idleRefCount ++;
    
    NSLog(@"PROPS.incrementIdleTimerRefCount: count = %i", idleRefCount);
    
    if (idleRefCount > 0 && ![UIApplication sharedApplication].idleTimerDisabled) {
        
        NSLog(@"PROPS.incrementRefCount: About to disable idle timer");
        [UIApplication sharedApplication].idleTimerDisabled = TRUE;
    }
    
    NSLog(@"PROPS.incrementRefCount: Idle timer %@ disabled", [UIApplication sharedApplication].idleTimerDisabled ? @"is" : @"is not");
}


- (void) decrementIdleTimerRefCount {
    
    idleRefCount --;
    
    NSLog(@"PROPS.decrementIdleTimerRefCount: count = %i", idleRefCount);
    
    if (idleRefCount < 0){
        
        idleRefCount = 0;
        NSLog(@"*********ERROR Props.decrementRefCount: Ref count = %i, should never be less than 0", idleRefCount);
    }
    
    if (idleRefCount == 0 && [UIApplication sharedApplication].idleTimerDisabled) {
       
        [UIApplication sharedApplication].idleTimerDisabled = FALSE;
        NSLog(@"PROPS.decrementRefCount: enabling idle timer");
    }
    
    NSLog(@"PROPS.decrementRefCount: Idle timer %@ disabled", [UIApplication sharedApplication].idleTimerDisabled ? @"is" : @"is not");
}

- (void) updateServerContentSource {
	
	@autoreleasepool {
		while (!self.connectedToInternet) {
			[NSThread sleepForTimeInterval:1];
			//NSLog(@"PROPS.updateServerContentSource: We %@ in the main thread", [NSThread isMainThread] ? @"are" : @"are not");
		}
		
		
		if (self.serverContentSource == nil || availableSources == nil) {
			
			NSDate *date = [NSDate date];
			
			//Detect available sources
			if (availableSources != nil) {
				availableSources = nil;
			}
			
			availableSources = [NSMutableArray new];
			
			while (self.serverContentSource == nil) {
				
				int counter = 1;
				int failureCounter = 0;
				
				while (TRUE) { //willing to take fewer content sources after a few failures
					
					//test if site is working by trying to download test image
					NSString *urlString = [NSString stringWithFormat:@"http://pub%i.sutromedia.com/published/connection_test.txt", counter];
					NSURL *dataURL = [NSURL URLWithString: urlString];
					
					NSError *error = nil;
					
					NSString *connectionTestResult = [NSString stringWithContentsOfURL:dataURL encoding:NSASCIIStringEncoding error:&error];
					
					NSString *hostname = [NSString stringWithFormat:@"pub%i.sutromedia.com", counter];
					
					if ([connectionTestResult isEqualToString:@"alive"]) {
						
						[availableSources addObject:hostname];
						counter ++;
					}
					
					else {
						//NSLog(@"GUIDEDOWNLOADER.setContentSource: %@ is Not resolved. Failure counter = %i", hostname, failureCounter);
						failureCounter ++;
						counter ++;
					}
	
			
					if (failureCounter > 0 && ([availableSources count] > 0 || failureCounter > 20) && failureCounter + [availableSources count] > 8) break;
				}
				
				if ([availableSources count] > 0) {
					int r = arc4random() % ([availableSources count]);
					
					self.serverContentSource = [availableSources objectAtIndex:r];
				}
				
				if (self.serverContentSource == nil){
					NSLog(@"ERROR *********** PROPS.updateContentSource: Content source is null");
					[NSThread sleepForTimeInterval:5.0];
				}
			}
			
			NSLog(@"PROPS.updateContentSource: Content source = %@ in %0.2f seconds", self.serverContentSource, -[date timeIntervalSinceNow]);
		}
		
		else {
			
			NSLog(@"Available sources has %i objects and current source is %@", [availableSources count], self.serverContentSource);
			
			int index = [availableSources indexOfObject:self.serverContentSource];
			
			index ++;
			
			if (index > [availableSources count] - 1) index = 0;
			
			self.serverContentSource = [availableSources objectAtIndex:index];
		}
	}
}


- (void) buildOfflineLinkURLArray {
	
	NSLog(@"PROPS.buildOfflineLinkURLArray: start");
	NSDate *date = [NSDate date];
    
    if ([Props global].osVersion >= 4) {
        NSMutableArray *allOfflineFileNames = [NSMutableArray new];
        
        @synchronized([Props global].dbSync) {
            
            //NSLog(@"GUIDEDOWNLOADER - db lock 4 for %i", guideId);
            FMResultSet * rs = [[EntryCollection sharedContentDatabase] executeQuery:@"SELECT description FROM entries where description LIKE '%sutromedia.com/published/offline/%'"];
            
            while ([rs next]){
                
                NSString *entryDescription = [rs stringForColumn:@"description"];
                //NSLog(@"Description = %@", entryDescription);
                NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"http://sutromedia.com/published/offline/.*?\"|http://www.sutromedia.com/published/offline/.*?\"" options:NSRegularExpressionCaseInsensitive error:nil];
				//NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"http://sutromedia.com/published/offline/.*?>" options:NSRegularExpressionCaseInsensitive error:nil];
				//http://sutromedia.com/published/offline/175/Test_maps_jeremy/Brunnenstr182_Wir_bleiben_alle.jpg?o=aa088a491dc715dde5e0b3327ab94977.jpg
                NSArray *regexResults = [regex matchesInString:entryDescription options:0 range:NSMakeRange(0, [entryDescription length])];
                
                for (NSTextCheckingResult *result in regexResults) {
                    NSString *urlWithEndQuote = [entryDescription substringWithRange:result.range];
                    NSString *url = [urlWithEndQuote substringWithRange:NSMakeRange(0, [urlWithEndQuote length] -1)];
					
					//if (![allOfflineFileNames containsObject:url])[allOfflineFileNames addObject:url]; //don't want to add duplicate URLs
					[allOfflineFileNames addObject:url];
                }
			}
            
            [rs close];
        }
		
		NSLog(@"PROPS.buildOfflineLinkURLArray: %0.2f seconds in sync", -[date timeIntervalSinceNow]);
		
		NSMutableArray *uniqueFileNames = [NSMutableArray new];
		for (NSString *urlName in allOfflineFileNames) {
			if (![uniqueFileNames containsObject:urlName]) [uniqueFileNames addObject:urlName];
		}
        
        self.offlineLinkURLs = [NSArray arrayWithArray:uniqueFileNames];
    }
	
	NSLog(@"PROPS.buildOfflineLinkURLArray: Took %0.2f seconds to finish", -[date timeIntervalSinceNow]);
}


- (void)reachabilityChanged:(NSNotification *)note
{
    [self updateInternetStatus];
}

- (void)updateInternetStatus
{
	// Query the SystemConfiguration framework for the state of the device's network connections.
	//self.remoteHostStatus           = [[Reachability sharedReachability] remoteHostStatus];
	//self.internetConnectionStatus	= [[Reachability sharedReachability] internetConnectionStatus];
	//self.localWiFiConnectionStatus	= [[Reachability sharedReachability] localWiFiConnectionStatus];
    self.connectedToInternet = [[Reachability sharedReachability] internetConnectionStatus] == NotReachable ? FALSE : TRUE;
	
	if (self.connectedToInternet != lastConnectivityStatus) [[NSNotificationCenter defaultCenter] postNotificationName:@"kNetworkReachabilityChangedNotification" object:nil];
	
	lastConnectivityStatus = self.connectedToInternet;
    
    //NSLog(@"PROPS.updateInternetStatus: Status = %@", self.connectedToInternet ? @"connected" : @"not connected");
}


#pragma mark 
#pragma mark Singleton Stuff

+ (Props*)global {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

/*
static Props *globalInstance = nil;
+ (Props*)global {
    @synchronized(self) {
        if (globalInstance == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return globalInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (globalInstance == nil) {
            globalInstance = [super allocWithZone:zone];
            return globalInstance;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}*/

@end

