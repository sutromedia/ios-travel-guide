//
//  GuideDownloader.m
//  TheProject
//
//  Created by Tobin1 on 5/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GuideDownloader.h"
#import "Entry.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "Reachability.h"
#import "SMLog.h"
#import "ActivityLogger.h"
#import "ZipArchive.h"
#import "ASIHTTPRequest.h"
//#import "Reachability2.h"
#include <stdlib.h>
#import "EntryCollection.h"
#import "MyStoreObserver.h"

#define kNumberOfTries 3 //number of tries to get a given file before giving up
#define FMDBErrorCheck(db)			{ if ([db hadError]) { NSLog(@"DB error %d on line %d: %@", [db lastErrorCode], __LINE__, [db lastErrorMessage]); } }
#define kSlowWaitTime   1.0
#define kFastWaitTime   0.003
#define kWaitTimeForRequestsToFinish 0.007 //Time we wait for requests to get through the queue before adding more.
#define kMapTileType @"Map tile type"
#define kImageType @"Image type"
#define kIconImageType @"Icon image type"
#define kThumbnailType @"Thumbnail type"
#define kEntryThumbnailType @"Entry thumbnail type"
#define kMaxConsecutiveFailures 2

#define kMapTileUpdateGroupSize 30
#define kPhotoUpdateGroupSize 20
#define kThumbnailUpdateGroupSize 60

#define kMapZoomLevelForBaseContent 14 
#define kMapZoomLevelForSampleContent 12

#define kBaseSampleContentThumbnailCount 300
#define kBaseContentThumbnailCount 1000
#define kMaxNumberOfThumbnails 3000

//#define kDownloadPriorityTop 1
//#define kDwonloadPriorityBottom 2

#define kMaxConcurrentDownloadsForTopPriority 6 //Leave an extra 3 download spots for top priority stuff
#define kMaxConcurrentDownloadsForLowPriority 3

//Executes an update query with error check.
void executeUpdate(FMDatabase* db, NSString* sql, ...) {
	va_list args;
	va_start(args, sql);
	[db executeUpdate:sql arguments:args];
	va_end(args);
	FMDBErrorCheck(db);
}

@interface GuideDownloader (Private)


- (void) getContentDatabase;
- (BOOL) checkForDownloadLimit;
- (void) checkForPause;
- (int) checkForStatus;
//- (float)folderSize:(NSString *)folderPath;
- (float)fileSize:(NSString*) filePath;
- (void) postUpdate;
- (void) setSummaryStatusTo:(int) newStatus;
- (float) estimateTotalMBDownloaded;
- (BOOL) checkForSuccess;
- (UIImage*) cropImage:(UIImage*) image;
//- (void) buildOfflineLinkURLArray;
- (void) updatePhotosTableWithGroupedPhotoIDs;
- (void) updateMapsDBWithGroupedMapTiles;
- (void) updatePhotosTableWithGroupedPhotoIDsForThumbnails;
- (void) setContentSource;
- (NSArray*) getMissingIconPhotoIds;
- (void) updateTotalContentSize;
//- (void) updatePhotoContentSizeForRemoval;
//- (void) updatePhotoContentSizeForDownload;
- (int) getCurrentBundleVersion;
- (void) restartDownloadProcess;
- (void) logWithActionId:(int) actionId;

//Methods for content download in stand alone apps
- (void) postUpdateForKey:(NSString*) downloadTypeKey;

@end

@implementation GuideDownloader


@synthesize guideId, pauseDownload, waiting, status, shouldStop;

- (id) initWithGuideId:(int) theGuideId {
    
    NSLog(@"GUIDEDOWNLOADER.initWithGuideId: %i", theGuideId);
    
    self = [super init];
    
    if (self) {
       
        self.guideId = theGuideId;
        downloadingBaseContent =    FALSE;
        downloadingEntryThumbnails = FALSE;
        downloadingMaps =           FALSE;
        downloadingOfflineLinkFiles = FALSE;
        downloadingPhotos =         FALSE;
        stopped =                   TRUE;
		offlineLinkFileTimer =      nil;
		offlineMapTimer =           nil;
		offlinePhotoTimer =         nil;
        guideDatabase =             nil;
        mainMapDatabase =           nil;
        groupedPhotoIDsToUpdate =   nil;
		groupedThumbnailPhotoIDsToUpdate = nil;
        groupedMapTilesToupdate =   nil;
        //availableSources = nil;
        consecutiveFailureCount =   0;
        concurrentRequests =        0;
        lastStatus =                0;
        waitTime = kFastWaitTime;
        contentSource = [Props global].serverContentSource;
        missingContent = [NSMutableDictionary new];
        badImageArray = [NSMutableArray new];
        averagePhotoSize = [Props global].deviceType == kiPad ? kAverageiPadImageSize : kAverageiPhoneImageSize;
        
        contentFolder = [NSString stringWithFormat:@"%@/%i", [Props global].cacheFolder, guideId];
        
        imageSource = ([Props global].deviceType == kiPad) ? @"ipad-sized-photos" : @"480-sized-photos";
        
        NSString *key = [NSString stringWithFormat:@"%@_%i", kOfflinePhotos, guideId];
        max_OfflinePhotoContentSize = [[NSUserDefaults standardUserDefaults] floatForKey:key];
        
        [[NSURLCache sharedURLCache] setMemoryCapacity:0];
        [[NSURLCache sharedURLCache] setDiskCapacity:0];
        
        //Create content folder as necessary
        if(![[NSFileManager defaultManager] isWritableFileAtPath:contentFolder]){
            
            [[NSFileManager defaultManager] createDirectoryAtPath: contentFolder withIntermediateDirectories:YES attributes: nil error:nil ];
            NSLog(@"GUIDEDOWNLOADER.initWithGuideId - Content folder created at %@", contentFolder);
        }
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseDownload:) name:kPauseGuideDownload object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeDownload:) name:kResumeGuideDownload object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(speedUpDownload:) name:kSetGuideDownloadToFast object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slowDownload:) name:kSetGuideDownloadToSlow object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadOfflineImages:) name:kDownloadOfflineImages object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopDownloadingOfflineImages:) name:kStopDownloadingOfflineImages object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeOfflinePhotos:) name:kRemoveOfflineImages object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopDownloadsForTestApp) name: kEnteringTestApp object:nil];
        
        if (![Props global].isShellApp)[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateContentAfterDynamicUpdate) name:kContentUpdated object:nil];
        
        NSString *redownloadNotification = [NSString stringWithFormat:@"%@_%i", kRedownloadGuide, guideId];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartDownloadProcess) name: redownloadNotification object:nil];
        
        NSString *offlineMapsNotificationName = [NSString stringWithFormat:@"%@_%i", kOfflineMaps_Max_ContentSize, guideId];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOfflineMaps) name:offlineMapsNotificationName object:nil];
        
        NSString *offlinePhotosNotificationName = [NSString stringWithFormat:@"%@_%i", kOfflinePhotos, guideId];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOfflinePhotos) name:offlinePhotosNotificationName object:nil];
        
        NSString *offlineFilesNotificationName = [NSString stringWithFormat:@"%@_%i", kOfflineFiles, guideId];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOfflineLinkFiles) name:offlineFilesNotificationName object:nil];
        
        NSString *entryThumbnailDownloadNotificationName = [NSString stringWithFormat:@"%@_%i", kDownloadEntryPhotos, guideId];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadEntryPhotos:) name:entryThumbnailDownloadNotificationName object:nil];
		
		NSString *samplePurchasedNotification = [NSString stringWithFormat:@"%@_%i", kSampleGuidePurchased, guideId];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startSampleUpgradeDownload) name: samplePurchasedNotification object:nil];
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadHigherResolutionImage:) name:kDownloadHigherResolutionImage object:nil];
        
        
        NSDictionary *theStatus = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, guideId]];
        total_BaseContentSize = (theStatus != nil) ? [[theStatus objectForKey:@"total"] floatValue] : 0;
        current_BaseContentSize = [[theStatus objectForKey:@"current"] floatValue];
        self.status = [[theStatus objectForKey:@"summary"] intValue];
        currentTask = [theStatus objectForKey:@"current task"];
        
        pauseDownload =[[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, guideId]];
        
        //Restart process of downloading offline maps or photos as necessary
		//*** Set current value for map content size
		//Need to save the current content size, as it's tough to measure for shell app guides
		if ([Props global].isShellApp) {
			
			/*
			 int numberOfMapTiles = 0;
			@synchronized ([Props global].mapDbSync) {
				
				FMDatabase *mapDatabase = [[FMDatabase alloc] initWithPath:[Props global].mapDatabaseLocation];
				
				if (![mapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.updateTotalContentSize - Can't open map tile database");
				
				NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) as theCount FROM tiles WHERE downloaded = %i", guideId];
				
				FMResultSet *rs = [mapDatabase executeQuery:query];
				
				if ([rs next]) numberOfMapTiles = [rs intForColumn:@"theCount"];
				
				[rs close];
				
				[mapDatabase close];
			}
			 
			 current_OfflineMapContentSize = numberOfMapTiles * kAverageMapTileSize;
			 */
			
			//NSLog(@"GUIDEDOWNLOADER.updateTotalContentSize: map tiles are %f MB", numberOfMapTiles * kAverageMapTileSize);
			
			//Checking the db for this info was taking way too long, hence the workaround
			NSString *offlineMapSizeKey = [NSString stringWithFormat:@"%@_%i", kCurrentMapContentSize, guideId];
			current_OfflineMapContentSize = [[NSUserDefaults standardUserDefaults] floatForKey:offlineMapSizeKey];
	
			
			NSString *theFilePath= guideId == 1 ? [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].cacheFolder] : [NSString stringWithFormat:@"%@/content.sqlite3", contentFolder];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:theFilePath]) {
				guideDatabase = [[FMDatabase alloc] initWithPath:theFilePath];
				if(![guideDatabase open]) NSLog(@"GUIDEDOWNLOADER.downloadContent: could not open database for %i", guideId);
				
				//See if we need a splash for earlier versions of the code that didn't download one
				NSString *splashFilePath= [NSString stringWithFormat:@"%@/%i/Splash.jpg", [Props global].cacheFolder, guideId];
				
				if (![[NSFileManager defaultManager] fileExistsAtPath:splashFilePath]) {
					[self performSelectorInBackground:@selector(getSplashImage) withObject:nil];
				}
			}
		}
		
		else { //Can just measure the current map size directly for stand alone apps
			
			FMDatabase *mapDatabase = [[FMDatabase alloc] initWithPath:[Props global].mapDatabaseLocation];
			
			if (![mapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.updateTotalContentSize - Can't open map tile database");
			
			int numberOfMapTiles = 0;
			
			@synchronized ([Props global].mapDbSync) {
				FMResultSet *rs = [mapDatabase executeQuery:@"SELECT COUNT(*) as theCount FROM tiles WHERE image NOT NULL"];
				
				if ([rs next]) numberOfMapTiles = [rs intForColumn:@"theCount"];
				
				[rs close];
			}
			
			[mapDatabase close];
			
			guideDatabase = [EntryCollection sharedContentDatabase];
			
			//NSLog(@"GUIDEDOWNLOADER.updateTotalContentSize: map tiles are %f MB", numberOfMapTiles * kAverageMapTileSize);
			
			current_OfflineMapContentSize = numberOfMapTiles * kAverageMapTileSize;
			
			[self setContentDownloadDefaultsAsNeeded];
			
			[self performSelectorInBackground:@selector(removeBadFiles) withObject:nil];
			
			[self updateContent];
			
		}
    }
    
    return self;
}


- (void) updateContentAfterDynamicUpdate {
    
    NSLog(@"Beginning content update after a dynamic update");
    
    //[self updateOfflineMaps];
    //[self updateOfflinePhotos];
    //[self updateOfflineLinkFiles];
    
    thumbnailDownloadQuantity = kMaxNumberOfThumbnails;
    
    if (guideId != 1) [self performSelectorInBackground:@selector(getThumbnails) withObject:nil];
}


- (void) getMaxThumbnailPhotos {
    
    NSString *thumbnailKeyString = [NSString stringWithFormat:@"%@_%i", kThumbnailsDownloaded, guideId];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:thumbnailKeyString] && guideId != 1){
        thumbnailDownloadQuantity = kMaxNumberOfThumbnails;
        [self performSelectorInBackground:@selector(getThumbnails) withObject:nil];
    }
}


- (void) updateContent {
    
    [self updateOfflineMaps];
    [self updateOfflinePhotos];
    [self updateOfflineLinkFiles];
    
    
    NSString *thumbnailKeyString = [NSString stringWithFormat:@"%@_%i", kThumbnailsDownloaded, guideId];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:thumbnailKeyString] && guideId != 1){
        thumbnailDownloadQuantity = kMaxNumberOfThumbnails;
        [self performSelectorInBackground:@selector(getThumbnails) withObject:nil];
    }
}


- (void) setContentDownloadDefaultsAsNeeded {
	
	if (guideId > 1 && (([Props global].isShellApp && ![[MyStoreObserver sharedMyStoreObserver] isGuideFreeSample:guideId]) || [Props global].freemiumType != kFreemiumType_V1)) {
		
		NSString *photo_key = [NSString stringWithFormat:@"%@_%i", kOfflinePhotos, guideId];
		float _Max_OfflinePhotoContentSize = [[NSUserDefaults standardUserDefaults] floatForKey:photo_key];
		
		NSString *map_key = [NSString stringWithFormat:@"%@_%i", kOfflineMaps_Max_ContentSize, guideId];
		float _Max_OfflineMapContentSize = [[NSUserDefaults standardUserDefaults] floatForKey:map_key];
		
		NSString *offline_file_key = [NSString stringWithFormat:@"%@_%i", kOfflineFiles, guideId];
		float _Max_OfflineFileContentSize = [[NSUserDefaults standardUserDefaults] floatForKey:offline_file_key];

		NSString *offline_content_defaults_set_key = [NSString stringWithFormat:@"Offline content defaults set for %i", guideId];
		BOOL offlineContentDefaultsSet = [[NSUserDefaults standardUserDefaults] boolForKey:offline_content_defaults_set_key];
		
        
        
		if (!offlineContentDefaultsSet && _Max_OfflinePhotoContentSize == 0 && _Max_OfflineMapContentSize == 0 && _Max_OfflineFileContentSize == 0) {
			
			//Set defaults values that are likely max, but may be below in crazy cases
			[[NSUserDefaults standardUserDefaults] setFloat:500 forKey:photo_key];
			[[NSUserDefaults standardUserDefaults] setFloat:100 forKey:map_key];
			[[NSUserDefaults standardUserDefaults] setFloat:200 forKey:offline_file_key];
			
			[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:offline_content_defaults_set_key];
		}
	}
}


- (void) removeBadFiles {
	
	//This method is to fix potential issues caused by having zero byte image files present from an earlier bug in the image URL
	//We don't worry about updating the database, as the database will be replaced during the code update either way
	
	@autoreleasepool {
		
		downloadingPhotos = TRUE; //This prevents the photo downloader from starting until this method completes
		
		NSDate *date = [NSDate date];
		NSString *theFolderPath = [NSString stringWithFormat:@"%@/images",contentFolder];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if([fileManager isWritableFileAtPath:theFolderPath]){
			
			NSArray *fileList = [fileManager subpathsAtPath:theFolderPath];
			
			for (NSString *filePath in fileList) {
				//NSLog(@"Filepath = %@", filePath);
				NSString *fullFilePath = [NSString stringWithFormat:@"%@/%@", theFolderPath, filePath];
				unsigned long long fileSize = [[fileManager attributesOfItemAtPath:fullFilePath error:nil] fileSize];
				
				//NSLog(@"File size = %llu", fileSize);
				if (fileSize == 0)[fileManager removeItemAtPath:fullFilePath error:nil]; 
			}
		}
		
		downloadingPhotos = FALSE;
		
		NSLog(@"GUIDEDOWNLOADER.removeBadFiles: Took %0.2f seconds to remove bad files", -[date timeIntervalSinceNow]);
	}
}


- (id) initForTestAppWithGuideId:(int) theGuideId {
    
    NSLog(@"GUIDEDOWNLOADER.initForTestAppWithGuideId: %i", theGuideId);
    
    self = [super init];
    
    if (self) {
        
        self.guideId = theGuideId;
        waitTime = kFastWaitTime;
        guideDatabase = nil;
        mainMapDatabase = nil;
        groupedPhotoIDsToUpdate = nil;
		groupedThumbnailPhotoIDsToUpdate = nil;
        groupedMapTilesToupdate = nil;
        //availableSources = nil;
        contentSource = [Props global].serverContentSource;
        consecutiveFailureCount = 0;
        concurrentRequests = 0;
        
        contentFolder = [NSString stringWithFormat:@"%@/%i", [Props global].cacheFolder, guideId];
        
        if([[NSFileManager defaultManager] isWritableFileAtPath:contentFolder] || [[NSFileManager defaultManager] createDirectoryAtPath: contentFolder withIntermediateDirectories:YES attributes: nil error:nil ])
            NSLog(@"GUIDEDOWNLOADER.downloadContent - Content folder created at %@", contentFolder);
        
        imageSource = ([Props global].deviceType == kiPad) ? @"ipad-sized-photos" : @"480-sized-photos";
        
        [[NSURLCache sharedURLCache] setMemoryCapacity:0];
        [[NSURLCache sharedURLCache] setDiskCapacity:0];
    }
    
    return self;
}


- (void) dealloc {
    
    NSLog(@"GUIDEDOWNLOADER.dealloc: %i", guideId);
    
    [[Props global] decrementIdleTimerRefCount];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (guideId == 1) [guideDatabase close];
}


- (void) updateContentSource {
    
    //[self checkForPause]; //we want to wait if there's no internet connection
    //NSLog(@"GUIDEDOWNLOADER.updateContentSource:%@ main thread", [NSThread isMainThread] ? @"is" : @"is not");
    updatingContentSource = TRUE;
    [[Props global] updateServerContentSource];
    contentSource = [Props global].serverContentSource;
    
    consecutiveFailureCount = 0;
    
    NSLog(@"GUIDEDOWNLOADER.updateContentSource: new source = %@ for %i", [Props global].serverContentSource, guideId);
	updatingContentSource = FALSE;
}

#pragma mark
#pragma mark Content download managers

//Gets minimum initial download after guide purchase in library app
- (void) downloadBaseContent {
    
    @autoreleasepool {
    
        downloadingBaseContent = TRUE;
		
		[self checkForPause];
        
        [[Props global] incrementIdleTimerRefCount];
        
        [self logWithActionId: kDownload_Initiated];
        
        [NSThread setThreadPriority:0.2];
        
        maxConcurrentDownloads = kMaxConcurrentDownloadsForTopPriority;
        
        timeInCheckForPause = 0;
        timeInPostUpdate = 0;
        currentTask = @"";
        
        NSDate *date = [NSDate date]; //Used for performance logging only
        
        [self postUpdate]; 
            
        NSLog(@"GUIDEDOWNLOADER.downloadBaseContent: About to start download cycle for %i", guideId);
        
        stopped = FALSE;
        shouldStop = FALSE;
        
        [self logWithActionId: kDownload_ContentSourceSet];
        
        [self setSummaryStatusTo:kDownloadInProgress];
		
		isSample = [[MyStoreObserver sharedMyStoreObserver] isGuideFreeSample:guideId];
        
        if (!doingSampleUpgrade) {
            //We check the bundle version to avoid downloading the database a second time if the app is restarted during a base content downlod
            int currentBundleVersion = [self getCurrentBundleVersion];
            
            if (currentBundleVersion < latestBundleVersion || currentBundleVersion == 0) [self getContentDatabase];
			
			hasMaps = [self doesAppHaveMaps];
			NSLog(@"%i %@ maps", guideId, hasMaps ? @"has" : @"does not have");
            
            if (hasMaps)[self getMapDatabase]; //We use this to estimate map content size when showing settings. This is downloaded multiple times if the app is restarted during the base content download process
            
            [self logWithActionId: kDownload_DatabasesDownloaded];
        }
		
		else hasMaps = [self doesAppHaveMaps];
        
        
        if (shouldStop) return;
        
        //**************** Estimate size of base content *************************
        
        total_BaseContentSize = doingSampleUpgrade ? 0 : 1; //rough estimate of size of content database
        current_BaseContentSize = total_BaseContentSize; //DB is already downloaded
        
        int numberOfIconPhotos = 0;
        
        if (!doingSampleUpgrade) {
            
            @synchronized ([Props global].dbSync) {
                FMResultSet *rs = [guideDatabase executeQuery:@"SELECT COUNT(icon_photo_id) as theCount FROM entries"];
                
                if ([rs next]) numberOfIconPhotos = [rs intForColumn:@"theCount"];
                
                [rs close];
            }
            
            total_BaseContentSize += numberOfIconPhotos * averagePhotoSize; //estimate 1 MB to content DB.
        }
        
        //Size of icon photos
        
        thumbnailDownloadQuantity = isSample ? kBaseSampleContentThumbnailCount : kBaseContentThumbnailCount;
        
        thumbnailDownloadQuantity = MAX(thumbnailDownloadQuantity, numberOfIconPhotos);
        
        int numberOfThumbnails = 0;
        @synchronized ([Props global].dbSync) {
            FMResultSet *rs = [guideDatabase executeQuery:@"SELECT COUNT(*) as theCount FROM photos WHERE downloaded_x100px_photo < 1 OR downloaded_x100px_photo IS NULL"];
            
            if ([rs next]) numberOfThumbnails = [rs intForColumn:@"theCount"];
            
            [rs close];
        }
        
        numberOfThumbnails = MIN(numberOfThumbnails, thumbnailDownloadQuantity);
        
        
        total_BaseContentSize += numberOfThumbnails * kAverageThumbnailSize;

        //Get map size
        if (hasMaps) {
            NSString *shellDBPath = [Props global].isShellApp ? [NSString stringWithFormat:@"%@/offline-map-tiles.sqlite3", contentFolder] : [[NSBundle mainBundle] pathForResource:@"offline-map-tiles.sqlite3" ofType:nil];
            // NSLog(@"GUIDEDOWNLOADER.getOfflineMapTiles: shellDB path = %@ and doing upgrade download = %@", shellDBPath, doingUpgradeDownload ? @"TRUE" : @"FALSE");
            
            FMDatabase *shellMapDatabase = [[FMDatabase alloc] initWithPath: shellDBPath];
            if (![shellMapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.getTotalContentSize - Can't open shell map tile database");
            
            int numberOfMapTiles = 0;
            @synchronized ([Props global].mapDbSync) {
				int mapZoomLevel = isSample ? kMapZoomLevelForSampleContent : kMapZoomLevelForBaseContent;
                NSString *query = (doingSampleUpgrade) ? [NSString stringWithFormat:@"SELECT COUNT(*) as theCount FROM tiles WHERE zoom <= %i AND zoom > %i", kMapZoomLevelForBaseContent, kMapZoomLevelForSampleContent] : [NSString stringWithFormat:@"SELECT COUNT(*) as theCount FROM tiles WHERE zoom <= %i", mapZoomLevel];
                NSLog(@"GUIDEDOWNLOADER.downloadBaseContent: query = %@", query);
                FMResultSet *rs = [shellMapDatabase executeQuery:query];
                
                if ([rs next]) numberOfMapTiles = [rs intForColumn:@"theCount"];
                
                [rs close];
            }
            
            total_BaseContentSize += numberOfMapTiles * kAverageMapTileSize;
            
            NSLog(@"Total base content size = %f", total_BaseContentSize);
        }
        

        [self postUpdate];
        
        [self getThumbnails];
        
        [self getOfflineMapTiles]; //Get up to different zoom levels depending on if it is a sample or not
        
        if (!doingSampleUpgrade) {
			[self getIconPhotos]; //also generates map markers
			[self getSplashImage];
		}
		
        NSLog(@"GUIDEDOWNLOADER.downloadContent: MB downloaded after icon photos for %i = %0.1f", guideId, current_BaseContentSize);
        
        [self setSummaryStatusTo:kReadyForViewing];
        
        //Complete the payment transaction now that we know the guide is ready for viewing
        if (!isSample)[[NSNotificationCenter defaultCenter] postNotificationName:kBillCustomerForCompletedTransaction object:[NSNumber numberWithInt:guideId] userInfo:nil];
        
        [self setSummaryStatusTo:kDownloadComplete];
        
        SMLog *log = [[SMLog alloc] initWithPageID: kInAppPurchase actionID: kDownloadSuccess];
        log.entry_id = guideId;
        [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
        
        stopped = TRUE;
        downloadingBaseContent = FALSE;
		
		[self setContentDownloadDefaultsAsNeeded];
            
        [[Props global] decrementIdleTimerRefCount];
        
        maxConcurrentDownloads = kMaxConcurrentDownloadsForLowPriority;
        
        NSLog(@"GUIDEDOWNLOADER.downloadContent: took %0.0f seconds to download %i. Time in check for pause = %0.0f. Postupdate time = %0.0f", -[date timeIntervalSinceNow], guideId, timeInCheckForPause, timeInPostUpdate);
    }
}


/*
- (void) downloadContent {
    
    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
    
    [self logWithActionId: kDownload_Initiated];
    
    [NSThread setThreadPriority:0.2];
    
    timeInCheckForPause = 0;
    timeInPostUpdate = 0;
    currentTask = @"";
    
    NSDate *date = [NSDate date];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseDownload:) name:kPauseGuideDownload object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeDownload:) name:kResumeGuideDownload object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(speedUpDownload:) name:kSetGuideDownloadToFast object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slowDownload:) name:kSetGuideDownloadToSlow object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadOfflineImages:) name:kDownloadOfflineImages object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopDownloadingOfflineImages:) name:kStopDownloadingOfflineImages object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeOfflineImages:) name:kRemoveOfflineImages object:nil];
    
    NSString *redownloadNotification = [NSString stringWithFormat:@"%@_%i", kRedownloadGuide, guideId];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartDownloadProcess) name: redownloadNotification object:nil];
    
    NSDictionary *theStatus = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, guideId]];
    totalToDownload = (theStatus != nil) ? [[theStatus objectForKey:@"total"] floatValue] : 0;
    mB_Downloaded = [[theStatus objectForKey:@"current"] floatValue];
    self.status = [[theStatus objectForKey:@"summary"] intValue];
    downloadOfflineImages = [[theStatus objectForKey:@"download offline images"] intValue] == 1 ? TRUE : FALSE;
    imageSizeForRemoval = [[theStatus objectForKey:@"image size for removal"] floatValue];
    imageSizeForDownload = [[theStatus objectForKey:@"image size for download"] floatValue];
    currentTask = [theStatus objectForKey:@"current task"];
    
    pauseDownload =[[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, guideId]];
    if (!pauseDownload) [[Props global] incrementIdleTimerRefCount];
    
    last_mB_Update = 0; 
    
    [self checkForPause];
    [self postUpdate]; 
    
    if([[NSFileManager defaultManager] isWritableFileAtPath:contentFolder] || [[NSFileManager defaultManager] createDirectoryAtPath: contentFolder withIntermediateDirectories:YES attributes: nil error:nil ])
        NSLog(@"GUIDEDOWNLOADER.downloadContent - Content folder created at %@", contentFolder);
    
    while (TRUE) {
        
        NSLog(@"GUIDEDOWNLOADER.downloadContent: About to start download cycle for %i", guideId);
        
        stopped = FALSE;
        shouldStop = FALSE;
        int tryCounter = 0;
                
        [self logWithActionId: kDownload_ContentSourceSet];
        
        if (status != kDownloadComplete) {
            
            while (!shouldStop) {
                
                if (self.status == kDownloadNotStarted) [self setSummaryStatusTo:kDownloadInProgress];
                
                if (self.status < kReadyForViewing || tryCounter > 2) { //The try count conditional is a catch in case something went wrong with DB
                    [self checkForPause];
                    
                    int currentBundleVersion = [self getCurrentBundleVersion];
                    
                    if (currentBundleVersion < latestBundleVersion || currentBundleVersion == 0) {
                        [self getContentDatabase];
                        if (guideDatabase != nil) {[guideDatabase close]; [guideDatabase release]; guideDatabase = nil;}
                        NSString *theFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", contentFolder];
                        guideDatabase = [[FMDatabase alloc] initWithPath:theFilePath];
                        if(![guideDatabase open]) NSLog(@"GUIDEDOWNLOADER.downloadContent: could not open database for %i", guideId);
                        
                        hasMaps = [self doesAppHaveMaps];
                        
                        if (hasMaps)[self getMapDatabase];
                        
                        if (offlineLinkURLs == nil) [self buildOfflineLinkURLArray];
                        
                        [guideDatabase close]; [guideDatabase release]; guideDatabase = nil;
                    }
                }
                
                [self logWithActionId: kDownload_DatabasesDownloaded];
                
                if (shouldStop) break;
                
                if (guideDatabase != nil) {[guideDatabase close]; [guideDatabase release]; guideDatabase = nil;}
                NSString *theFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", contentFolder];
                guideDatabase = [[FMDatabase alloc] initWithPath:theFilePath];
                if(![guideDatabase open]) NSLog(@"GUIDEDOWNLOADER.downloadContent: could not open database for %i", guideId);
                
                [self updateTotalContentSize];
                NSLog(@"GUIDEDOWNLOADER.downloadContent: totalToDownload for %i = %0.0f", guideId, totalToDownload);
                [self postUpdate];
                
                [self logWithActionId: kDownload_ContentSizeSet];
                
                if (totalToDownload != 0 && contentSource != nil) { //Databases have not been downloaded correctly if total equals 0
                    
                    if (self.status < kReadyForViewing){
                        
                        mB_Downloaded = 0;
                        [self getThumbnails];
                        NSLog(@"GUIDEDOWNLOADER.downloadContent: MB downloaded after thumbnails for %i = %0.1f", guideId, mB_Downloaded);
                        [self getIconPhotos]; //also generates map markers
                        NSLog(@"GUIDEDOWNLOADER.downloadContent: MB downloaded after icon photos for %i = %0.1f", guideId, mB_Downloaded);
                        [self setSummaryStatusTo:kReadyForViewing];
                    }
                    
                    //Complete the payment transaction now that we know the guide is ready for viewing
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBillCustomerForCompletedTransaction object:[NSNumber numberWithInt:guideId] userInfo:nil];
                    
                    if (hasMaps && !mapsDownloaded)[self getOfflineMapTiles];
                    NSLog(@"GUIDEDOWNLOADER.downloadContent: MB downloaded after maps for %i = %0.1f", guideId, mB_Downloaded);
                    [self getOfflineLinkFiles];
                    if (downloadOfflineImages) [self getOtherPhotos];
                }
                
                if (shouldStop) break;
                
                [self updatePhotoContentSizeForDownload];
                [self updatePhotoContentSizeForRemoval];
                
                //Do this so proper size is shown when user select to download all offline images
                if (!downloadOfflineImages){
                    downloadOfflineImages = TRUE;
                    [self updateTotalContentSize];
                    downloadOfflineImages = FALSE;
                }
                
                [self setSummaryStatusTo:kDownloadComplete];
                
                SMLog *log = [[SMLog alloc] initWithPageID: kInAppPurchase actionID: kDownloadSuccess];
                log.entry_id = guideId;
                [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
                [log release];
                
                break;
            }
        }
            
        NSLog(@"GUIDEDOWNLOADER.downloadContent: took %0.0f seconds to download %i. Time in check for pause = %0.0f. Postupdate time = %0.0f", -[date timeIntervalSinceNow], guideId, timeInCheckForPause, timeInPostUpdate);
        
        waiting = TRUE;
        stopped = TRUE;
        
         @synchronized ([Props global].dbSync) {
             if (guideDatabase != nil) {[guideDatabase close]; [guideDatabase release]; guideDatabase = nil;}
         }
        
        [[Props global] decrementIdleTimerRefCount];
        
        while (waiting) {
            [NSThread sleepForTimeInterval:1];
        }
    }
    
    [autoreleasepool release];
}
*/

- (void) updateOfflinePhotos {
    
    NSString *key = [NSString stringWithFormat:@"%@_%i", kOfflinePhotos, guideId];
    
    float new_Max_OfflinePhotoContentSize = [[NSUserDefaults standardUserDefaults] floatForKey:key];
    
    //set size of current offline photos
    @synchronized([Props global].dbSync) {
        //Get size of all photos first
		NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) AS theCount FROM photos WHERE downloaded_%ipx_photo > 0",[Props global].deviceType == kiPad ? 768:320];
		FMResultSet * rs = [guideDatabase executeQuery:query];
		
		if ([rs next]) current_OfflinePhotosContentSize = [rs intForColumn:@"theCount"] * averagePhotoSize;
		[rs close];
	}
    
    if ([Props global].isShellApp) {
        int entryCount = 0;
        @synchronized([Props global].dbSync) {
            //Get size of entry icon photos next (which aren't counted in total)
            FMResultSet * rs = [guideDatabase executeQuery:@"SELECT COUNT(*) AS theCount FROM entries"];
            
            if ([rs next]) entryCount = [rs intForColumn:@"theCount"];
            [rs close];
        }
        
        current_OfflinePhotosContentSize -= averagePhotoSize * entryCount;
    }
    
    NSLog(@"GUIDEDOWNLOADER.updateOfflinePhotos: guideID = %i, new max amount = %0.2f, old max amount = %0.2f, current downloaded = %0.2f, difference between new and old = %0.2f", guideId, new_Max_OfflinePhotoContentSize, max_OfflinePhotoContentSize, current_OfflinePhotosContentSize, fabsf((new_Max_OfflinePhotoContentSize - max_OfflinePhotoContentSize)/max_OfflinePhotoContentSize < 0.01));
    
    if (new_Max_OfflinePhotoContentSize > current_OfflinePhotosContentSize) {
        NSLog(@"GUIDEDOWNLOADER.updateOfflinePhotos: Time to download offline photos");
        
		max_OfflinePhotoContentSize = new_Max_OfflinePhotoContentSize;
        [self tryToGetOfflinePhotos];
    }
    
    else if (fabsf((new_Max_OfflinePhotoContentSize - max_OfflinePhotoContentSize)/max_OfflinePhotoContentSize) < 0.01) return;
    
    else {
        
        NSLog(@"GUIDEDOWNLOADER.updateOfflinePhotos: Time to remove offline photos");
        max_OfflinePhotoContentSize = new_Max_OfflinePhotoContentSize;
        [self performSelectorInBackground:@selector(removeOfflinePhotos) withObject:nil];
    }
}


- (void) tryToGetOfflinePhotos {
	
	if (offlinePhotoTimer != nil) {
		[offlinePhotoTimer invalidate];
		offlinePhotoTimer = nil;
	}
	
	if (downloadingPhotos) {
		stopImageDownload = TRUE;
		offlinePhotoTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(tryToGetOfflinePhotos) userInfo:nil repeats:NO];
	}
	
	else {
		
		stopImageDownload = FALSE;
		
		[self performSelectorInBackground:@selector(getOfflinePhotos) withObject:nil];
	}
}


- (void) updateOfflineLinkFiles {
    
    NSString *key = [NSString stringWithFormat:@"%@_%i", kOfflineFiles, guideId];
    
    float new_Max_OfflineLinkFileContentSize = [[NSUserDefaults standardUserDefaults] floatForKey:key];
    
    //set size of current offline
    // Can probably measure actual file size here
	NSString *offlineFileDirectory = [NSString stringWithFormat:@"%@/OfflineLinkFiles/", contentFolder];
	NSArray *offlineFileDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:offlineFileDirectory error:nil];
    current_OfflineLinkFileContentSize = [offlineFileDirectoryContents count] * kAverageOfflineLinkFileSize;
    
    NSLog(@"GUIDEDOWNLOADER.updateOfflineLinkFiles: guideID = %i, new max amount = %0.2f, old max amount = %0.2f, current downloaded = %0.2f", guideId, new_Max_OfflineLinkFileContentSize, max_OfflineLinkFileContentSize, current_OfflineLinkFileContentSize);
    
    if (ABS((new_Max_OfflineLinkFileContentSize - max_OfflineLinkFileContentSize)/max_OfflineLinkFileContentSize) < 0.01) return;
    
    else if (new_Max_OfflineLinkFileContentSize > max_OfflinePhotoContentSize || new_Max_OfflineLinkFileContentSize > current_OfflineLinkFileContentSize) {
        NSLog(@"GUIDEDOWNLOADER.updateOfflineLinkFiles: Time to download offline link file");
        
		max_OfflineLinkFileContentSize = new_Max_OfflineLinkFileContentSize;
		[self tryToGetOfflineLinkFiles]; //This method tries to get the offline link files and tries again later if the link file downloader is busy and hasn't exited
    }
    
    else {
        
        NSLog(@"GUIDEDOWNLOADER.updateOfflineLinkFiles: Time to remove offline link files");
        max_OfflineLinkFileContentSize = new_Max_OfflineLinkFileContentSize;
        [self performSelectorInBackground:@selector(removeOfflineLinkFiles) withObject:nil];
    }
}


- (void) tryToGetOfflineLinkFiles {
	
	if (offlineLinkFileTimer != nil) {
		[offlineLinkFileTimer invalidate];
		offlineLinkFileTimer = nil;
	}
	
	if (downloadingOfflineLinkFiles) {
		stopOfflineLinkFileDownload = TRUE;
		offlineLinkFileTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(tryToGetOfflineLinkFiles) userInfo:nil repeats:NO];
	}
	
	else {
		
		stopOfflineLinkFileDownload = FALSE;
	
		[self performSelectorInBackground:@selector(getOfflineLinkFiles) withObject:nil];
	}
}


- (void) updateOfflineMaps {
    
    NSString *key = [NSString stringWithFormat:@"%@_%i", kOfflineMaps_Max_ContentSize, guideId];
    float new_Max_OfflineMapContentSize = [[NSUserDefaults standardUserDefaults] floatForKey:key];
    
    NSLog(@"GUIDEDOWNLOADER.updateOfflineMaps: guideID = %i, new max amount = %0.2f, old max amount = %0.2f", guideId, new_Max_OfflineMapContentSize, max_OfflinePhotoContentSize);
    
    if (new_Max_OfflineMapContentSize > max_OfflineMapContentSize || new_Max_OfflineMapContentSize > current_OfflineMapContentSize) {
        NSLog(@"GUIDEDOWNLOADER.updateOfflineMaps: Time to download offline maps");
        
        max_OfflineMapContentSize = new_Max_OfflineMapContentSize;
		[self tryToGetOfflineMaps];
	}
    
    else if (ABS((new_Max_OfflineMapContentSize - max_OfflineMapContentSize)/max_OfflineMapContentSize) < 0.01) return;
    
    else {
        
        NSLog(@"GUIDEDOWNLOADER.updateOfflineMaps: Time to remove offline Maps");
        max_OfflineMapContentSize = new_Max_OfflineMapContentSize;
        [self performSelectorInBackground:@selector(removeOfflineMaps) withObject:nil];
    }
}


- (void) tryToGetOfflineMaps {
	
	if (offlineMapTimer != nil) {
		[offlineMapTimer invalidate];
		offlineMapTimer = nil;
	}
	
	if (downloadingMaps || removingMaps) {
		stopMapDownload = TRUE;
		offlineMapTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(tryToGetOfflineMaps) userInfo:nil repeats:NO];
	}
	
	else {
		stopMapDownload = FALSE;
		[self performSelectorInBackground:@selector(getOfflineMapTiles) withObject:nil];
	}
}



/*- (void) downloadOfflinePhotos {
    
    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
    
    if (downloadingPhotos) return;
    
    downloadingPhotos = TRUE;
    [NSThread setThreadPriority:0.2];
    
    NSDate *date = [NSDate date];
    
    [self checkForPause];
    [self postUpdate]; 
    
    
    NSLog(@"GUIDEDOWNLOADER.downloadOfflinePhotos: About to start download cycle for %i", guideId);
    
    BOOL downloadSuccessful = FALSE;
    stopped = FALSE;
    shouldStop = FALSE;
    stopImageDownload = FALSE;
    imageDownloadStopped = FALSE;
    //int tryCounter = 0;
    
    while (!downloadSuccessful && !shouldStop && !stopImageDownload) {
        
        //guideDatabase = [EntryCollection sharedContentDatabase];
        
        [self getOtherPhotos];
        
        if (shouldStop || stopImageDownload) break;
        
        
        //FMDatabase *db = [EntryCollection sharedContentDatabase];
        
        float downloadFraction = 0;
        
        int totalToDownlad = 0;
        int numberDownloaded = 0;
        
        @synchronized ([Props global].dbSync) {
          
            NSDate *time = [NSDate date];

            NSString * query = [NSString stringWithFormat:@"SELECT COUNT(photos.rowid) as theCount FROM photos WHERE downloaded_%ipx_photo IS NOT NULL", [Props global].deviceType == kiPad ? 768 : 320];
            
            FMResultSet *rs = [guideDatabase executeQuery: query];
            
            if ([rs next]) numberDownloaded = [rs intForColumn:@"theCount"];
            
            [rs close];
            
            float queryTime = -[time timeIntervalSinceNow];
            
            if (queryTime > 0.2) {
                NSLog(@"GUIDEDOWNLOADER.downloadOfflinePhotos 1: Query time = %0.4f", queryTime);
            }
        }
            
        @synchronized ([Props global].dbSync) {
            
            NSDate *time = [NSDate date];
            
            FMResultSet *rs = [guideDatabase executeQuery: @"SELECT COUNT(DISTINCT(photos.rowid)) as theCount FROM photos"];
            
            if ([rs next]) totalToDownlad = [rs intForColumn:@"theCount"];
            
            [rs close];
            
            if (totalToDownlad != 0) downloadFraction = (float)numberDownloaded/(float)totalToDownlad;
            
            float queryTime = -[time timeIntervalSinceNow];
            
            if (queryTime > 0.2) {
                NSLog(@"GUIDEDOWNLOADER.downloadOfflinePhotos 2: Query time = %0.4f", queryTime);
            }
        }
        
        NSLog(@"GUIDEDOWNLOADER.downloadOfflinePhotos: %0.2f downloaded", downloadFraction);
        
        if (downloadFraction > 0.7) downloadSuccessful = TRUE;
        
    }
    
    stopped = TRUE;
    imageDownloadStopped = TRUE;
    downloadingPhotos = FALSE;
    
    NSLog(@"GUIDEDOWNLOADER.offlinePhotos: took %0.0f seconds to download %i. Time in check for pause = %0.0f. Postupdate time = %0.0f", -[date timeIntervalSinceNow], guideId, timeInCheckForPause, timeInPostUpdate);
    
    
    [autoreleasepool release];
}*/


//This method is only used for downloading offline maps in stand-alone guides
/*
- (void) downloadOfflineMaps {
    
    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
    
    if (downloadingMaps) return;
    
    while (removingMaps) {
        
        stopRemovingMaps = TRUE;
        [NSThread sleepForTimeInterval:0.01];
    }
    
    downloadingMaps = TRUE;
    
    [NSThread setThreadPriority:0.2];
    
    NSDate *date = [NSDate date];
    
    [self checkForPause];
    [self postUpdate]; 
    
    
    NSLog(@"GUIDEDOWNLOADER.downloadContent: About to start download cycle for %i", guideId);
    
    BOOL downloadSuccessful = FALSE;
    stopped = FALSE;
    shouldStop = FALSE;
    stopMapTileDownload = FALSE;
    mapDownloadStopped = FALSE;
    int tryCount = 0;
    int maxNumberOfTrys = 5;
    
    while (!downloadSuccessful && !shouldStop && !stopMapTileDownload) {
        
        [self getOfflineMapTiles];
        
        if (shouldStop || stopMapTileDownload) break;
        
        mainMapDatabase = [[FMDatabase alloc] initWithPath:[Props global].mapDatabaseLocation];
        
        if (![mainMapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.updateTotalContentSize - Can't open map tile database");
        
        float missingFraction = 0;
        
        @synchronized ([Props global].mapDbSync) {
            
            FMResultSet *rs = [mainMapDatabase executeQuery:@"SELECT COUNT(*) as theCount FROM tiles WHERE image IS NULL"];
            
            int numberOfMissingMapTiles = 0;
            int totalNumber = 0;
            
            if ([rs next]) numberOfMissingMapTiles = [rs intForColumn:@"theCount"];
            
            [rs close];
            
            //FMResultSet *rs2 = [mainMapDatabase executeQuery:@"SELECT value FROM preferences WHERE name = 'initial_tile_row_count'"];
            FMResultSet *rs2 = [mainMapDatabase executeQuery:@"SELECT value AS theCount FROM preferences WHERE name = 'initial_tile_row_count'"];
            
            //NSString *theCountString = nil;
            if ([rs2 next]) {
                totalNumber = [rs2 intForColumn:@"theCount"];
                //NSLog(@"Just set the count to %@", theCountString);
            }
            
            [rs2 close];
            
            if (totalNumber != 0) missingFraction = (float)numberOfMissingMapTiles/(float)totalNumber;
        }
        
        [mainMapDatabase close];
        [mainMapDatabase release];
        mainMapDatabase = nil;
        
        NSLog(@"GUIDEDOWNLOADER.downloadOfflineMaps: %0.2f missing", missingFraction);
        
        if (missingFraction < 0.05) downloadSuccessful = TRUE;
        
        tryCount ++;
        
        if (tryCount >= maxNumberOfTrys) {
            NSLog(@"GUIDEDOWNLOADER.downloadOfflineMapTiles: giving up after %i trys", tryCount);
            break;
        }
    }
    
    stopped = TRUE;
    mapDownloadStopped = TRUE;
    downloadingMaps = FALSE;
    
    NSLog(@"GUIDEDOWNLOADER.downloadOfflineMaps: took %0.0f seconds to download %i. Time in check for pause = %0.0f. Postupdate time = %0.0f", -[date timeIntervalSinceNow], guideId, timeInCheckForPause, timeInPostUpdate);
    
    
    [autoreleasepool release];
}
*/


#pragma mark
#pragma mark Downloaders for different kinds of content

- (void) getContentDatabase {
	
    NSLog(@"GUIDEDOWNLOADER.getContentDatabase: %i", guideId);
    currentTask = kGettingDatabase;
    [self postUpdate];
    
    [self checkForPause];
    
    int tryCount = 0;
    
    while (!shouldStop) {
        @autoreleasepool {
        
            NSString *unzippedFilePath= [NSString stringWithFormat:@"%@/%i.sqlite3", contentFolder, guideId];
            NSString *theFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", contentFolder];
            
            NSString *zippedFilePath= [NSString stringWithFormat:@"%@.zip", unzippedFilePath];
            
            NSString *urlString = [[NSString stringWithFormat: @"%@/%i.sqlite3.zip", [Props global].serverDatabaseUpdateSource, guideId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
            
            NSURL *dataURL = [NSURL URLWithString: urlString];
            NSLog(@"GUIDEDOWNLOADER.ContentDatabase: About to try and download database at %@", urlString);
            
            //Get the data
            NSData *databaseData = [[NSData alloc] initWithContentsOfURL:dataURL options:NSDataReadingUncached error:nil];
            
            //Write the data to disk
            [databaseData writeToFile: zippedFilePath atomically:YES];
            
            //Unzip file
            ZipArchive *za = [[ZipArchive alloc] init];
            if ([za UnzipOpenFile: zippedFilePath]) {
                BOOL ret = [za UnzipFileTo: contentFolder overWrite: YES];
                if (NO == ret){} [za UnzipCloseFile];
            }
            
            [[NSFileManager defaultManager] removeItemAtPath:theFilePath error:nil];
            [[NSFileManager defaultManager] moveItemAtPath:unzippedFilePath toPath: theFilePath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:zippedFilePath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:unzippedFilePath error:nil];
        
        }
        
        NSString *dbFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", contentFolder];
        guideDatabase = [[FMDatabase alloc] initWithPath:dbFilePath];
        if(![guideDatabase open]) NSLog(@"GUIDEDOWNLOADER.downloadContent: could not open database for %i", guideId);
        
        int currentBundleVersion = [self getCurrentBundleVersion];
        
        if ((currentBundleVersion >= latestBundleVersion && currentBundleVersion > 0) || (tryCount > 10 && currentBundleVersion > 0)) break;
        
        else NSLog(@"******* WARNING: GUIDEDOWNLOADER.getContentDatabase: Download failed. current bundle version = %i, latest bundle version = %i, and try count = %i", currentBundleVersion, latestBundleVersion, tryCount);
        
        [NSThread sleepForTimeInterval:1];
        
        tryCount ++;
        
        if (tryCount == 2) [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadProblems object:nil];
    }
}


- (void) getMapDatabase {
    
    NSLog(@"GUIDEDOWNLOADER.getMapDatabase for %i", guideId);
    
    [self checkForPause];
    
    currentTask = kGettingDatabase;
    
    int tryCount = 0;
    
    while (!shouldStop) {
       //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        [[NSURLCache sharedURLCache] setMemoryCapacity:0];
        [[NSURLCache sharedURLCache] setDiskCapacity:0]; 
        
        NSString *theFilePath= [NSString stringWithFormat:@"%@/offline-map-tiles.sqlite3", contentFolder];
        NSString *unzippedFilePath= [NSString stringWithFormat:@"%@/%i.sqlite3", contentFolder, guideId];
        
        NSString *zippedFilePath= [NSString stringWithFormat:@"%@.zip", unzippedFilePath];
        
        NSString *urlString = [[NSString stringWithFormat: @"http://www.sutromedia.com/published/map-tile-dbs/%i.sqlite3.zip", guideId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
        
        NSURL *dataURL = [NSURL URLWithString: urlString];
        NSLog(@"GUIDEDOWNLOADER.getMapDatabase: About to try and download database at %@", urlString);
        
        //Get the data
        NSData *databaseData = [[NSData alloc] initWithContentsOfURL:dataURL options:NSDataReadingUncached error:nil];
        
        //Write the data to disk
        [databaseData writeToFile: zippedFilePath atomically:YES];
        
        //Clean up
        
        ZipArchive *za = [[ZipArchive alloc] init];
        if ([za UnzipOpenFile: zippedFilePath]) {
            BOOL ret = [za UnzipFileTo: contentFolder overWrite: YES];
            if (NO == ret){} [za UnzipCloseFile];
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:theFilePath error:nil];
        [[NSFileManager defaultManager] moveItemAtPath:unzippedFilePath toPath: theFilePath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:zippedFilePath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:unzippedFilePath error:nil];
        
        //Check to see if we got a viable database
        FMDatabase *mapDatabase2 = [[FMDatabase alloc] initWithPath:theFilePath];
        if (![mapDatabase2 open]) NSLog(@"GUIDEDOWNLOADER.getMapDatabase - Error opening database **********************************************");
        
        int numberOfTiles = 0;
        
        FMResultSet *rs = [mapDatabase2 executeQuery:@"SELECT value FROM preferences WHERE name = 'initial_tile_row_count'"];
        
        if ([rs next]) numberOfTiles = [rs intForColumn:@"value"];
        
        [rs close];
        [mapDatabase2 close];
        
        //[pool release];
        
        if (numberOfTiles > 0 || tryCount > 20) break;
        
        else if (tryCount > 0) {
            NSLog(@"*******WARNING: GUIDEDOWNLOADER.getMapDatabase: failed after %i trys", tryCount);
            [NSThread sleepForTimeInterval:1];
        }
        
        tryCount ++;
    }    
}


- (void) getSplashImage {
	
	NSString *sourceURL = [[NSString stringWithFormat:@"http://sutroproject.com/published-content/%i/%i Static Content/Default.jpg", guideId, guideId]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	NSString *theFilePath= [NSString stringWithFormat:@"%@/Splash.jpg", contentFolder];
	
	NSURL *dataURL = [NSURL URLWithString: sourceURL];
	
	//Get the data
	NSData *splashData = [[NSData alloc] initWithContentsOfURL:dataURL options:NSDataReadingUncached error:nil];
	
	//Write the data to disk
	[splashData writeToFile: theFilePath atomically:YES];
}


- (void) getIconPhotos {
    
    @autoreleasepool {
        NSLog(@"GUIDEDOWNLOADER.getIconPhotos: %i", guideId);
        
        /*if (guideDatabase == nil){
         NSString *theFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", contentFolder];
         guideDatabase = [[FMDatabase alloc] initWithPath:theFilePath];
         if(![guideDatabase open]) NSLog(@"GUIDEDOWNLOADER.downloadContent: could not open database for %i", guideId);
         }*/
        
        currentTask = kDownloadingIcons;
        
        [self checkForPause];
        
        NSDate *date = [NSDate date];
        
        NSString *theFilePath;
        
        NSString *theFolderPath = [NSString stringWithFormat:@"%@/images", contentFolder];
        
        NSError *theError = nil;
        
        //Create folder for content as necessary
        if(!([[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath] || [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:&theError]))
            NSLog(@"GUIDEDOWNLOADER.getSmallIcons: ERROR CREATING CONTENT FOLDER at %@ with error = %@ *******************************************", theFolderPath, [theError description]);
        
        imageDownloadCounter = 1;
        
        [self checkForPause];
        
        int tryCount = 0;
        NSArray *iconPhotos = nil;
        
        while (!shouldStop) {
            
            iconPhotos = [self getMissingIconPhotoIds];
            
            NSLog(@"Missing icon photo count = %i and tryCount - 2 = %i should break = %@", [iconPhotos count], tryCount - 2, [iconPhotos count] < tryCount ? @"TRUE" : @"FALSE");
            
            if ([iconPhotos count] <= tryCount && tryCount < 10) break; //We're willing to be more forgiving of missing photos after enough trys
            
            else if (tryCount > 0) {
                [NSThread sleepForTimeInterval:1];
                NSLog(@"*******WARNING:GUIDEDOWNLOADER.getIconPhotos: Missing %i photos after %i trys", [iconPhotos count], tryCount);
            }
            
            NSLog(@"GUIDEDOWNLOADER.getIconPhotos: - Starting to download %i icons for %i", [iconPhotos count], guideId);
            
            for(NSNumber *iconPhoto in iconPhotos) {
                
                @autoreleasepool {
                    
                    if (shouldStop) break;
                    [self checkForPause];
                    
                    int iconId = [iconPhoto intValue];
                    
                    //Get full sized icon photos****************************
                    theFilePath = [NSString stringWithFormat:@"%@/%i%@.jpg", theFolderPath, iconId, [Props global].deviceType == kiPad ? @"_768" : @""];
                    
                    if ([[NSFileManager defaultManager] fileExistsAtPath: theFilePath]) {
                        
                        current_BaseContentSize += [Props global].deviceType == kiPad ? kAverageiPadImageSize : kAverageiPhoneImageSize;
                        
                        NSString *query = [[NSString alloc] initWithFormat:@"UPDATE photos SET downloaded_%ipx_photo = 1 WHERE rowid = %i", [Props global].deviceType == kiPad ? 768:320, iconId];
                        
                        //NSLog(@"GUIDEDOWNLOADER.requestFinished: Updating photo table for icon photo, query = %@", query);
                        /*if (guideDatabase == nil){
                         NSString *theFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", contentFolder];
                         guideDatabase = [[FMDatabase alloc] initWithPath:theFilePath];
                         if(![guideDatabase open]) NSLog(@"GUIDEDOWNLOADER.downloadContent: could not open database for %i", guideId);
                         }*/
                        
                        @synchronized([Props global].dbSync) {
                            [guideDatabase executeUpdate:@"BEGIN TRANSACTION"];
                            [guideDatabase executeUpdate:query];
                            [guideDatabase executeUpdate:@"END TRANSACTION"];
                        }
                        
                        
                        //[self postUpdate];
                    }
                    
                    else {
                        
                        //We may need to change to one download here, as processing of image files into markers can bog down the system
                        while ([Props global].concurrentDownloads > maxConcurrentDownloads) {
                            [NSThread sleepForTimeInterval:kWaitTimeForRequestsToFinish];
                        }

                        
                        //Source for the data
                        NSString *tempString = [[NSString alloc] initWithFormat: @"http://%@/published/%@/%i.jpg", contentSource, imageSource, [iconPhoto intValue]];
                        //NSLog(@"Icon source = %@", tempString);
                        
                        NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
                        
                        //Get the data
                        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:dataURL];
                        [request setDelegate:self];
                        
                        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:kIconImageType, @"type", iconPhoto , @"photo_id", nil];
                        request.info = info;
                        [request startAsynchronous];
                        concurrentRequests ++;
                        
                    }
                    
                }
            }
            
            int waitCounter = 0;
            while (concurrentRequests > 0 && waitCounter < 30) {
                [NSThread sleepForTimeInterval:1.0];
                waitCounter ++;
                NSLog(@"GUIDEDOWNLOADER.getIconPhotos: Waiting for last few requests");
            }
            
            tryCount ++;
        }
        
        NSLog(@"GUIDEDOWNLOADER.getIconsPhotos: took %0.0f seconds to download %i", -[date timeIntervalSinceNow], guideId);
    }

}


- (void) getThumbnails {
    
    //Downloaded icon photos as a first priority and then gets additional photos as possible
	
	@autoreleasepool {
		NSLog(@"GUIDEDOWNLOADER.getThumbnails for %i", guideId);
		
		if (shouldStop) return;
		currentTask = kGetThumbnails;
		
		[self checkForPause];
		
		NSDate *date = [NSDate date];
		float timeInSyc = 0;
		
		thumbnailImageDownloadCounter = 0;
		
		[[NSURLCache sharedURLCache] setMemoryCapacity:0];
		[[NSURLCache sharedURLCache] setDiskCapacity:0];
		
		NSString *theFolderPath = [NSString stringWithFormat:@"%@/images",contentFolder];
		
		//check to see if images folder is there and create it if not
		if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath])
			[[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ];
		
		int numberDownloaded = 0;
		//Figure out how many images are already downloaded
        @synchronized([Props global].dbSync) {
            
            FMResultSet * rs = [guideDatabase executeQuery:@"SELECT COUNT(*) AS theCount FROM photos WHERE downloaded_x100px_photo > 0"];
            
            if ([rs next]) numberDownloaded = [rs intForColumn:@"theCount"];
            [rs close];
        }
        
        //And the total number of images
        int totalNumberOfPhotos = 0;
        
        @synchronized([Props global].dbSync) {
            
            FMResultSet * rs = [guideDatabase executeQuery:@"SELECT COUNT(*) AS theCount FROM photos"];
            
            if ([rs next]) totalNumberOfPhotos = [rs intForColumn:@"theCount"];
            [rs close];
        }
		 
		 //mB_Downloaded += numberDownloaded * kAverageThumbnailSize;
		
		
		NSMutableArray *photoIDs = [NSMutableArray new];
		int tryCount = 0;
        
        int numberOfThumbnailsToDownload = MIN(thumbnailDownloadQuantity, totalNumberOfPhotos);
        
        NSLog(@"Number of thumbnails to download = %i", numberOfThumbnailsToDownload);
        
        //Add thumbnails for icon photos first
        @synchronized([Props global].dbSync){
            //We want to get all the thumbnails, so we don't limit this query
            //This could result in more content actually being downloaded than predicted, but probably not by much
            NSString *query = [NSString stringWithFormat:@"SELECT rowid FROM photos, entries WHERE downloaded_x100px_photo IS NULL AND rowid IN (SELECT icon_photo_id FROM entries)"];
    
            FMResultSet *rs = [guideDatabase executeQuery:query];
            
            while ([rs next]) {
                
                int photoID = [rs intForColumn:@"rowid"];
                [photoIDs addObject:[NSNumber numberWithInt:photoID]];
            }
            
            [rs close];
        }
        
        //Add additional thumbnails if possible
        int photosLeftToDownload = numberDownloaded - [photoIDs count];
        
        if (photosLeftToDownload > 0) {
            @synchronized([Props global].dbSync){
                //NSLog(@"GUIDEDOWNLOADER - db lock 5 for %i", guideId);
                NSString *query = [NSString stringWithFormat:@"SELECT rowid FROM photos WHERE downloaded_x100px_photo IS NULL LIMIT %i", numberOfThumbnailsToDownload];
                NSLog(@"GUIDEDOWNLOADER.getThumbnails: query = %@", query);
                FMResultSet *rs = [guideDatabase executeQuery:query];
                
                while ([rs next]) {
                    
                    int photoID = [rs intForColumn:@"rowid"];
                    [photoIDs addObject:[NSNumber numberWithInt:photoID]];
                }
                
                [rs close];
            }
        }
		
		while (!shouldStop) {
			
			if (numberDownloaded > numberOfThumbnailsToDownload - tryCount * 100 || tryCount > 10)break;
			
			else if (tryCount > 0) {
				NSLog(@"****** WARNING: GUIDEDOWNLOADER.getThumbnails: download failed with number downloaded = %i and tryCount = %i", numberDownloaded, tryCount);
				[NSThread sleepForTimeInterval:1];
                
                if (photoIDs != nil) { photoIDs = nil;}
                
                photoIDs = [NSMutableArray new];
                
                @synchronized([Props global].dbSync){
                    //NSLog(@"GUIDEDOWNLOADER - db lock 5 for %i", guideId);
                    NSString *query = [NSString stringWithFormat:@"SELECT rowid FROM photos WHERE downloaded_x100px_photo IS NULL LIMIT %i", numberOfThumbnailsToDownload];
                    NSLog(@"GUIDEDOWNLOADER.getThumbnails: query = %@", query);
                    FMResultSet *rs = [guideDatabase executeQuery:query];
                    
                    while ([rs next]) {
                        
                        int photoID = [rs intForColumn:@"rowid"];
                        [photoIDs addObject:[NSNumber numberWithInt:photoID]];
                    }
                    
                    [rs close];
                }
			}
			
			if ([photoIDs count] < tryCount * 100) break;
			
			NSLog(@"GUIDEDOWNLOADER.getThumbnailPhotos: about to download %i thumbnail photos for %i. concurrent downloads = %i", [photoIDs count], guideId, [Props global].concurrentDownloads);
			
			for(NSNumber *photoID in photoIDs) {
				
				@autoreleasepool {
					
					if (shouldStop) break;
					[self checkForPause];
					
					//Source for the data
					NSString *tempString = [[NSString alloc] initWithFormat: @"http://%@/published/dynamic-photos/height/100/%i.jpg", contentSource, [photoID intValue]];
					//NSLog(@"URL for thumbnail = %@", tempString);
					
					NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
					
					//NSLog(@"GUIDEDOWNLOADER.getThumbnails: concurrent downloads = %i", [Props global].concurrentDownloads);
					
					while ([Props global].concurrentDownloads > maxConcurrentDownloads) {
						[NSThread sleepForTimeInterval:kWaitTimeForRequestsToFinish];
					}
					
					//Get the data
					ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:dataURL];
					[request setDelegate:self];
					
					NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:kThumbnailType, @"type", photoID , @"photo_id", nil];
					request.info = info;
					[request startAsynchronous];
					concurrentRequests ++;
					[Props global].concurrentDownloads ++;
				}
			}
			
			NSLog(@"GUIDEDOWNLOADER.getThumbnails: About to wait to finish operations in queue");
			//[[ASIHTTPRequest sharedQueue] waitUntilAllOperationsAreFinished];
			int waitCounter = 0;
			while (concurrentRequests > 0 && waitCounter < 30) {
				[NSThread sleepForTimeInterval:1.0];
				waitCounter ++;
				NSLog(@"GUIDEDOWNLOADER.getThumbnails: Waiting for last few requests");
			}
			
			NSLog(@"GUIDEDOWNLOADER.getThumbnails: Queue should be empty");
			if ([groupedThumbnailPhotoIDsToUpdate count] > 0) [self updatePhotosTableWithGroupedPhotoIDsForThumbnails];
			NSLog(@"GUIDEDOWNLOADER.getThumbnails: took %0.0f seconds to download %i with %0.0f seconds updating database", -[date timeIntervalSinceNow], guideId, timeInSyc);
			
			@synchronized([Props global].dbSync) {
				
				//NSLog(@"GUIDEDOWNLOADER - db lock 4 for %i", guideId);
				NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) AS theCount FROM photos WHERE downloaded_x100px_photo > 0"];
				FMResultSet * rs = [guideDatabase executeQuery:query];
				
				if ([rs next]) numberDownloaded = [rs intForColumn:@"theCount"];
				[rs close];
			}
			
			tryCount ++;
		}
		
		if (photoIDs != nil) { photoIDs = nil;}
		
        if (thumbnailDownloadQuantity == kMaxNumberOfThumbnails) {
            NSString *thumbnailKeyString = [NSString stringWithFormat:@"%@_%i", kThumbnailsDownloaded, guideId];
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:thumbnailKeyString];
        }
	}
}



/*- (void) getThumbnails {
	
	NSLog(@"GUIDEDOWNLOADER.getThumbnails for %i", guideId);
 
    if (shouldStop) return;
    currentTask = kGetThumbnails;
 
    [self checkForPause];
 
	NSDate *date = [NSDate date];
    float timeInSyc = 0;
 
    thumbnailImageDownloadCounter = 0;
 
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
	
	NSString *theFolderPath = [NSString stringWithFormat:@"%@/images",contentFolder];
	
	//check to see if images folder is there and create it if not
	if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath])
        [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ];
    
    int numberDownloaded = 0;
    //Figure out how many images are already there for download counter
    
    @synchronized([Props global].dbSync) {
        
		FMResultSet * rs = [guideDatabase executeQuery:@"SELECT COUNT(*) AS theCount FROM photos WHERE downloaded_x100px_photo > 0"];
		
		if ([rs next]) numberDownloaded = [rs intForColumn:@"theCount"];
		[rs close];
	}
    
    mB_Downloaded += numberDownloaded * kAverageThumbnailSize;

    
    NSMutableArray *photoIDs = nil;
    int tryCount = 0;
    
    while (!shouldStop) {
        
        if (numberDownloaded > kMaxNumberOfThumbnails - tryCount * 100 || tryCount > 10)break;
        
        else if (tryCount > 0) {
            NSLog(@"****** WARNING: GUIDEDOWNLOADER.getThumbnails: download failed with number downloaded = %i and tryCount = %i", numberDownloaded, tryCount);
            [NSThread sleepForTimeInterval:1];
        }
        
        if (photoIDs != nil) {[photoIDs release]; photoIDs = nil;}
        
        photoIDs = [NSMutableArray new];
        
        @synchronized([Props global].dbSync){
            //NSLog(@"GUIDEDOWNLOADER - db lock 5 for %i", guideId);
            NSString *query = [NSString stringWithFormat:@"SELECT rowid FROM photos WHERE downloaded_x100px_photo IS NULL LIMIT %i", kBaseContentThumbnailCount];
            NSLog(@"GUIDEDOWNLOADER.getThumbnails: query = %@", query);
            FMResultSet *rs = [guideDatabase executeQuery:query];
            
            while ([rs next]) {
                
                int photoID = [rs intForColumn:@"rowid"];
                [photoIDs addObject:[NSNumber numberWithInt:photoID]];
            }
            
            [rs close];
        }
        
        if ([photoIDs count] < tryCount * 100) break;
        
        NSLog(@"GUIDEDOWNLOADER.getThumbnailPhotos: about to download %i thumbnail photos for %i", [photoIDs count], guideId);
        
        for(NSNumber *photoID in photoIDs) {
            
            NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
            
            if (shouldStop) break;
            [self checkForPause];
            
            //Sort out where to write the data/ check if it's already there
            NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/%i_x100.jpg", theFolderPath, [photoID intValue]];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath: theFilePath]){
                
                mB_Downloaded += kAverageThumbnailSize;
                
                //NSLog(@"GUIDEDDOWNLOADER.requestFinished: Got thumbnail. MB downloaded = %f", mB_Downloaded);
                
                if (groupedPhotoIDsToUpdate == nil) groupedPhotoIDsToUpdate = [NSMutableArray new];
                
                @synchronized([Props global].dbSync) {[groupedPhotoIDsToUpdate addObject: photoID];}
                
                if ([groupedPhotoIDsToUpdate count] > kThumbnailUpdateGroupSize) [self updatePhotosTableWithGroupedPhotoIDsForThumbnails];
                
                //[self postUpdate];
            }
            
            else {
                //Source for the data
                NSString *tempString = [[NSString alloc] initWithFormat: @"http://%@/published/dynamic-photos/height/100/%i.jpg", contentSource, [photoID intValue]];
                //NSLog(@"URL for thumbnail = %@", tempString);
                
                NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];	
                NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
                
                while (concurrentRequests > kMaxConcurrentRequests) {
                    [NSThread sleepForTimeInterval:kWaitTimeForRequestsToFinish];
                }
                
                //Get the data
                ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:dataURL];
                [request setDelegate:self];
                
                NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:kThumbnailType, @"type", photoID , @"photo_id", nil];
                request.info = info;
                [info release];
                [request startAsynchronous];
                concurrentRequests ++;
                
                //Clean up
                [tempString release];
                [dataURL release];
            }
            
            [theFilePath release];
            
            [autoreleasepool release];
        }
        
        NSLog(@"GUIDEDOWNLOADER.getThumbnails: About to wait to finish operations in queue");
        //[[ASIHTTPRequest sharedQueue] waitUntilAllOperationsAreFinished];
        int waitCounter = 0;
        while (concurrentRequests > 0 && waitCounter < 30) {
            [NSThread sleepForTimeInterval:1.0];
            waitCounter ++;
            NSLog(@"GUIDEDOWNLOADER.getThumbnails: Waiting for last few requests");
        }
        
        NSLog(@"GUIDEDOWNLOADER.getThumbnails: Queue should be empty");
        if ([groupedPhotoIDsToUpdate count] > 0) [self updatePhotosTableWithGroupedPhotoIDsForThumbnails];
        NSLog(@"GUIDEDOWNLOADER.getThumbnails: took %0.0f seconds to download %i with %0.0f seconds updating database", -[date timeIntervalSinceNow], guideId, timeInSyc);
        
        @synchronized([Props global].dbSync) {
            
            //NSLog(@"GUIDEDOWNLOADER - db lock 4 for %i", guideId);
            NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) AS theCount FROM photos WHERE downloaded_x100px_photo > 0"];
            FMResultSet * rs = [guideDatabase executeQuery:query];
            
            if ([rs next]) numberDownloaded = [rs intForColumn:@"theCount"];
            [rs close];
        }
        
        tryCount ++;
    }
    
    if (photoIDs != nil) {[photoIDs release]; photoIDs = nil;}
    
    //NSString *thumbnailKeyString = [NSString stringWithFormat:@"%@_%i", kThumbnailsDownloaded, [Props global].appID];
    //[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:thumbnailKeyString];
}*/


- (void) getOfflinePhotos {

	@autoreleasepool {
		NSLog(@"GUIDEDOWNLOADER.getOtherPhotos for %i. current downloaded = %0.2f, max = %0.2f", guideId, current_OfflinePhotosContentSize, max_OfflinePhotoContentSize);
        
        currentTask = kDownloadImages;
        downloadingPhotos = TRUE;
        
        [self checkForPause];
        
		NSDate *date = [NSDate date]; //Used for measuring performance
        float timeInSyc = 0; //Used for measuring performance
        
        //Setting these values to zero seems to avoid a caching memory leak of sorts
        [[NSURLCache sharedURLCache] setMemoryCapacity:0];
        [[NSURLCache sharedURLCache] setDiskCapacity:0];
        
        
        //check to see if images folder is there and create it if not
		NSString *theFolderPath = [NSString stringWithFormat:@"%@/images",contentFolder];
		
		if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath])[[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ];
        
        
        //Figure out how many images are already there for download counter
        @synchronized([Props global].dbSync) {
            
            //NSLog(@"GUIDEDOWNLOADER - db lock 4 for %i", guideId);
            imageDownloadCounter = 0;
			NSString *query = [NSString stringWithFormat:@"SELECT MAX(downloaded_%ipx_photo) AS theMax FROM photos",[Props global].deviceType == kiPad ? 768:320];
			FMResultSet * rs = [guideDatabase executeQuery:query];
			
			if ([rs next]) imageDownloadCounter = [rs intForColumn:@"theMax"];
			[rs close];
		}
        
    	
        //Create query that downloads the correct number of photos
        //*** could improve this by prioritizing which photos to download
        NSString * query = ([Props global].deviceType == kiPad) ? [NSString stringWithFormat:@"SELECT rowid FROM photos WHERE downloaded_768px_photo is NULL"] : [NSString stringWithFormat:@"SELECT rowid FROM photos WHERE downloaded_320px_photo is NULL"];
        
        //Limit the number to download based on the max allowed photo size
        NSLog(@"Max photosize = %0.2f, mB_Downloaded = %0.2f, averagePhotoSize = %0.2f", max_OfflinePhotoContentSize, current_OfflinePhotosContentSize, averagePhotoSize);
        int numberToDownload = (max_OfflinePhotoContentSize - current_OfflinePhotosContentSize)/averagePhotoSize;
        
        if (numberToDownload <= 0 || shouldStop || stopImageDownload) {
            NSLog(@"GUIDEDOWNLOADER.getOfflinePhotos: Stopping at first exit. Number to download = %i, shouldStop = %@ and stopImage = %@", numberToDownload, shouldStop ? @"TRUE" : @"FALSE", stopImageDownload ? @"TRUE" : @"FALSE");
            downloadingPhotos = FALSE;
            return;
        }
        
        query = [query stringByAppendingFormat:@" LIMIT %i", numberToDownload];
        
        NSLog(@"GUIDEDOWNLOADER.getOfflinePhotos: Query = %@", query);
        
        NSMutableArray *photoIDs = nil;
        
        int tryCount = 0;
        
        while (!shouldStop && !stopImageDownload) {
            
            if (photoIDs != nil) { photoIDs = nil;}
            
            photoIDs = [NSMutableArray new];
            
            if (tryCount == 0) {
                @synchronized([Props global].dbSync){
                    //NSLog(@"GUIDEDOWNLOADER - db lock 5 for %i", guideId);
                    FMResultSet *rs = [guideDatabase executeQuery:query];
                    
                    while ([rs next]) {
                        
                        int photoID = [rs intForColumn:@"rowid"];
                        [photoIDs addObject:[NSNumber numberWithInt:photoID]];
                    }
                    
                    [rs close];
                }
            }
            
            else {
                //Get any missing images
                NSMutableArray *missingImageArray = [missingContent objectForKey:kImageType];
                
                for (NSDictionary *imageInfo in missingImageArray) {
                    [photoIDs addObject:[imageInfo objectForKey:@"photo_id"]];
                }
                
                if ([photoIDs count] < tryCount * 100) {
                    NSLog(@"GUIDEDOWNLOADER.getOtherPhotos: about to break after %i trys with %i missing photos", tryCount, [photoIDs count]);
                    break;
                }
            }
            
            
            NSLog(@"GUIDEDOWNLOADER.getOtherPhotos: about to download %i photos for %i after %i trys", [photoIDs count], guideId, tryCount);
            
            for(NSNumber *photoID in photoIDs) {
                
                @autoreleasepool {
                    
                    if (shouldStop || stopImageDownload) break;
                    [self checkForPause];
                    
                    //Sort out where to write the data/ check if it's already there
                    NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/%i%@.jpg", theFolderPath, [photoID intValue], [Props global].deviceType == kiPad ? @"_768" : @""];
                    
                    //Update records if file currently exists
                    if ([[NSFileManager defaultManager] fileExistsAtPath: theFilePath]){
                        
                        current_OfflinePhotosContentSize += [Props global].deviceType == kiPad ? kAverageiPadImageSize : kAverageiPhoneImageSize;
                        
                        if (groupedPhotoIDsToUpdate == nil) groupedPhotoIDsToUpdate = [NSMutableArray new];
                        
                        @synchronized([Props global].dbSync) {[groupedPhotoIDsToUpdate addObject: photoID];}
                        
                        if ([groupedPhotoIDsToUpdate count] > kPhotoUpdateGroupSize) [self updatePhotosTableWithGroupedPhotoIDs];
                        
                        //[self postUpdate];
                    }
                    
                    //Download the file if it doesn't
                    else {
                        
                        //Source for the data
                        NSString *tempString = [[NSString alloc] initWithFormat: @"http://%@/published/%@/%i.jpg",contentSource, imageSource, [photoID intValue]];
                        //NSLog(@"URL for image = %@", tempString);
                        
                        NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
                        
                        //NSLog(@"Current concurrent downloads = %i", [Props global].concurrentDownloads);
                        
                        while ([Props global].concurrentDownloads > maxConcurrentDownloads && !shouldStop && !stopImageDownload) {
                            [NSThread sleepForTimeInterval:kWaitTimeForRequestsToFinish];
                        }
                        
                        //Get the data
                        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:dataURL];
                        [request setDelegate:self];
                        
                        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:kImageType, @"type", photoID , @"photo_id", nil];
                        request.info = info;
                        [request startAsynchronous];
                        concurrentRequests ++;
                        [Props global].concurrentDownloads ++;
                    }
                }
            }
            
            tryCount ++;
        }
        
        int waitCounter = 0;
        while (concurrentRequests > 0 && waitCounter < 30 && !shouldStop && !stopImageDownload) {
            [NSThread sleepForTimeInterval:1.0];
            waitCounter ++;
            NSLog(@"GUIDEDOWNLOADER.otherPhotos: Waiting for last few requests");
        }
        
        if ([groupedPhotoIDsToUpdate count] > 0) [self updatePhotosTableWithGroupedPhotoIDs];
        
        
        downloadingPhotos = FALSE;
        
        /*
         //Used for debugging content size issues
         float currentContentSize = 0;
         
         FMDatabase *db = [EntryCollection sharedContentDatabase];
         
         int numberOfPhotos = 0;
         
         @synchronized ([Props global].dbSync) {
         
         //NSDate *date = [NSDate date];
         
         NSString * query = [NSString stringWithFormat:@"SELECT COUNT(photos.rowid) as theCount FROM photos WHERE downloaded_%ipx_photo is NOT NULL", [Props global].deviceType == kiPad ? 768 : 320];
         
         FMResultSet *rs = [db executeQuery: query];
         
         if ([rs next]) numberOfPhotos = [rs intForColumn:@"theCount"];
         else NSLog(@"SINGLESETTINGSVIEW.updateTotalContentSize: Error with query");
         
         [rs close];
         }
         
         if ([Props global].isShellApp) numberOfPhotos -= [[EntryCollection sharedEntryCollection] numberOfEntries];
         
         currentContentSize = numberOfPhotos * averagePhotoSize;
         
         NSLog(@"Current content size from db = %f, content size from float = %f, max content size = %f", currentContentSize, current_OfflinePhotosContentSize, max_OfflinePhotoContentSize);
         */
        
        NSLog(@"GUIDEDOWNLOADER.getOtherPhotos: took %0.0f seconds to download %i with %0.0f seconds updating database. Content size = %f", -[date timeIntervalSinceNow], guideId, timeInSyc, current_OfflinePhotosContentSize);
        
    }
}



- (void) getOfflineMapTiles {
    
    //We don't do any succuess checking on this method as the overhead for doing so is so high
	
	@autoreleasepool {
		NSLog(@"GUIDEDOWNLOADER.getOfflineMapTiles for %i", guideId);
		NSDate *time = [NSDate date];
		
		if (shouldStop || stopMapDownload){
			NSLog(@"GUIDEDOWNLOADER.getOfflineMapTiles - stopping at Exit 1");
			return;
		}
		
		currentTask = kDownloadingMaps;
		downloadingMaps = TRUE;
		[self checkForPause];
		
		//NSString *shellDBPath = doingUpgradeDownload ? [[NSBundle mainBundle] pathForResource:@"offline-map-tiles.sqlite3" ofType:nil] : [NSString stringWithFormat:@"%@/offline-map-tiles.sqlite3", contentFolder];
		NSString *shellDBPath = [Props global].isShellApp ? [NSString stringWithFormat:@"%@/offline-map-tiles.sqlite3", contentFolder] : [[NSBundle mainBundle] pathForResource:@"offline-map-tiles.sqlite3" ofType:nil];
		// NSLog(@"GUIDEDOWNLOADER.getOfflineMapTiles: shellDB path = %@ and doing upgrade download = %@", shellDBPath, doingUpgradeDownload ? @"TRUE" : @"FALSE");
		
		FMDatabase *shellMapDatabase = [[FMDatabase alloc] initWithPath: shellDBPath];
		if (![shellMapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.getTotalContentSize - Can't open shell map tile database");
		
		@synchronized([Props global].mapDbSync) {
			
			if (mainMapDatabase != nil) {
				[mainMapDatabase close];
				mainMapDatabase = nil;
			}
		}
		
		mainMapDatabase = [[FMDatabase alloc] initWithPath:[Props global].mapDatabaseLocation];
		if (![mainMapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.getTotalContentSize - Can't open main map tile database");
		
		
		NSString *query;
		int zoomLevel = isSample ? kMapZoomLevelForSampleContent : kMapZoomLevelForBaseContent;
		if (downloadingBaseContent) query = doingSampleUpgrade ? [NSString stringWithFormat:@"SELECT * FROM tiles WHERE zoom <= %i AND zoom > %i", kMapZoomLevelForBaseContent, kMapZoomLevelForSampleContent] : [NSString stringWithFormat:@"SELECT * FROM tiles WHERE zoom <= %i", zoomLevel];
        
		else {
			
			int numberOfTilesToDownload = max_OfflineMapContentSize/kAverageMapTileSize;
			
			if (numberOfTilesToDownload <= 0) {
				downloadingMaps = FALSE;
				return;
			}
			
			query = [NSString stringWithFormat:@"SELECT * FROM tiles ORDER BY zoom LIMIT %i", numberOfTilesToDownload];
		}
		
		NSLog(@"GUIDEDOWNLOADER.getOfflineMapTiles: query = %@", query);
		
		FMResultSet *rs = [shellMapDatabase executeQuery:query];
		float timeInSync = 0;
		int counter = 0;
		NSDate *timer = [NSDate date];
		
		float timeCheckingForDownloadStatus = 0;
		current_OfflineMapContentSize = 0; //Reset this as there isn't a good way to use previous value
		int updateCounterForExistingMapTiles = 0;
		
		while ([rs next]) {
			
			//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			@autoreleasepool {
				
				if (shouldStop || stopMapDownload) {
					downloadingMaps = FALSE;
					return;
				}
				
				[self checkForPause];
				
				NSNumber *tileKey = [NSNumber numberWithLongLong:[rs longLongIntForColumn:@"tilekey"]];
				
				//check if this tile is downloaded in the database
				BOOL downloaded = FALSE;
				NSDate *time = [NSDate date];
				@synchronized([Props global].mapDbSync) {
					
					FMResultSet *rs1 = [mainMapDatabase executeQuery:@"SELECT downloaded FROM tiles WHERE tilekey = ?", tileKey];
					if ([rs1 next]) downloaded = [rs1 intForColumn:@"downloaded"] > 0 ? TRUE : FALSE;
					[rs1 close];
				}
				
				timeCheckingForDownloadStatus += -[time timeIntervalSinceNow];
				
				if (downloaded) {
					current_OfflineMapContentSize += kAverageMapTileSize;
					
					updateCounterForExistingMapTiles ++;
					 if (updateCounterForExistingMapTiles % 100 == 0){
					 [self postUpdateForKey:kOfflineMaps_Max_ContentSize];
					 }
				}
				
				//if it isn't there or hasn't been downloaded then download it and add it
				else {
					
					int zoom = [rs intForColumn:@"zoom"];
					int row = [rs intForColumn:@"row"];
					int column = [rs intForColumn:@"col"];
					
					NSString *urlString = [[NSString alloc] initWithFormat:@"http://%@/published/sutro-map-tiles/%i/%i/%i.png", contentSource, zoom, column, row];
					//NSLog(@"URL string = %@", urlString);
					NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
					
					while ([Props global].concurrentDownloads > maxConcurrentDownloads && !shouldStop && !stopMapDownload) {
						[NSThread sleepForTimeInterval:kWaitTimeForRequestsToFinish];
					}
					
					ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:dataURL];
					[request setDelegate:self];
					
					NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:kMapTileType, @"type", [NSNumber numberWithInt:zoom], @"zoom", [NSNumber numberWithInt:row], @"row", [NSNumber numberWithInt:column], @"column", tileKey,  @"tilekey", nil];
					request.info = info;
					[request startAsynchronous];
					concurrentRequests ++;
					[Props global].concurrentDownloads ++;
					
					
					counter ++;
					
					if (counter == 1000) {
						NSLog(@"GUIDEDOWNLOADER.getOfflineMapTiles - took %0.3f seconds for last thousand", -[timer timeIntervalSinceNow]);
						counter = 0;
						timer = [NSDate date];
					}
				}
			}
		}
		
		[rs close];
		[shellMapDatabase close];
		
		//NSLog(@"GUIDEDOWNLOADER.getOfflineMapTiles: About to wait until last few requests are finished");
		int waitCounter = 0;
		while (concurrentRequests > 0 && waitCounter < 60 && !shouldStop && !stopMapDownload) {
			[NSThread sleepForTimeInterval:1.0];
			waitCounter ++;
			NSLog(@"GUIDEDOWNLOADER.getOfflineMapTiles: Waiting for last few requests");
		}
		
		for (NSString *badImage in badImageArray) {
			NSLog(@"%@", badImage);
		}
		
		//[[ASIHTTPRequest sharedQueue] waitUntilAllOperationsAreFinished];
		
		NSLog(@"GUIDEDOWNLOADER.getOfflineMapTiles: About to update database with last few map tiles");
		if ([groupedMapTilesToupdate count] > 0) [self updateMapsDBWithGroupedMapTiles];
		
		[mainMapDatabase close];
		mainMapDatabase = nil;
		
		if (current_OfflineMapContentSize/total_OfflineMapContentSize > .8) [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kOfflineMaps];
		
		current_OfflineMapContentSize = max_OfflineMapContentSize;
		
		mapsDownloaded = TRUE;
		downloadingMaps = FALSE;
		
		NSLog(@"GUIDEDOWNLOADER.getOfflineMapTiles for %i - took %0.0f seconds with %0.0f seconds in sync and %0.3f seconds checking download status", guideId, -[time timeIntervalSinceNow], timeInSync, timeCheckingForDownloadStatus);
	}
}


//We don't do any success checking on this method, as the files are not critical
- (void) getOfflineLinkFiles {
    
    NSLog(@"GUIDEDOWNLOADER.downloadOffineLinkFiles");
    
    currentTask = kDownloadingOfflineFiles;
	downloadingOfflineLinkFiles = TRUE;
	
    
    @autoreleasepool {
    
        NSString *folderPath = [NSString stringWithFormat:@"%@/OfflineLinkFiles/",contentFolder];
        
        if(![[NSFileManager defaultManager] isWritableFileAtPath:folderPath]) [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes: nil error:nil];
        
        for (NSString *urlString in [Props global].offlineLinkURLs) {
            NSLog(@"GUIDEDOWNLOADER.getOfflineLinkFiles:URL from array = %@", urlString);
            
            if (shouldStop || stopOfflineLinkFileDownload) break;
            [self checkForPause];
			if (current_OfflineLinkFileContentSize > max_OfflineLinkFileContentSize) break;
            
            @autoreleasepool {
                
                NSArray *urlNameArray = [urlString componentsSeparatedByString:@"?o="];
                
                NSArray *filenameArray = [[urlNameArray lastObject] componentsSeparatedByString:@"."];
                
                if ([filenameArray count] >= 2) {
                    
                    NSString *filename = [filenameArray objectAtIndex:0];
                    NSString *fileType = [filenameArray objectAtIndex:1];
                    
                    NSString *theFilePath = [NSString stringWithFormat:@"%@/OfflineLinkFiles/%@.%@", [Props global].contentFolder, filename, fileType];
                    
                    NSLog(@"GUIDEDOWNLOADER.getOfflineLinkFiles: Name = %@", theFilePath);
                    
                    BOOL filePresent = [[NSFileManager defaultManager] fileExistsAtPath: theFilePath];
                    
                    if (!filePresent) {
						
						NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
						NSData *fileData = [[NSData alloc] initWithContentsOfURL:dataURL options:NSDataReadingUncached error:nil];
						
						//Write the data to disk
						NSError * theError = nil;
						
                        if([fileData writeToFile: theFilePath  options:NSDataWritingFileProtectionNone error:&theError]!= TRUE)
                            NSLog(@"**** ERROR:GUIDEDOWNLOADER.getOfflineLinkFiles: failed to write local file to %@, error = %@, userInfo = %@ *******************************************************************", theFilePath, theError, [theError userInfo]);
                        
                        else {
                            current_OfflineLinkFileContentSize += kAverageOfflineLinkFileSize;
                            [self postUpdateForKey:kOfflineFiles];
                        }
                    }
                    
                    //else NSLog(@"GUIDEDOWNLOADER.getOfflineLinkFiles: File already present");
                }
            }
        }
    }
    
	
	downloadingOfflineLinkFiles = FALSE;
}


- (void) downloadEntryPhotos: (NSNotification*) theNotification {
    
    [self performSelectorInBackground:@selector(downloadEntryPhotosInBackground:) withObject:theNotification.object];
}


- (void) downloadEntryPhotosInBackground:(Entry*) theEntry {
    
    if (![Props global].connectedToInternet) {
        NSLog(@"GUIDEDOWLOADER.downloadEntryPhotosInBackground: Returning becuase we aren't connected");
        return;
    }
    
    while (downloadingEntryThumbnails) {
        NSLog(@"GUIDEDOWNLOADER.downloadEntryImagesInBackground: waiting for other downloader to stop");
        stopEntryThumbnailDownload = TRUE;
        [NSThread sleepForTimeInterval:0.05];
    }
    
    stopEntryThumbnailDownload = FALSE;
    downloadingEntryThumbnails = TRUE;
    
    NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i%@.jpg", [Props global].contentFolder, theEntry.icon, [Props global].deviceType == kiPad ? @"_768" : @""];
    
    if ((guideId != 1 || theEntry.isDemoEntry) && ![[NSFileManager defaultManager] fileExistsAtPath:theFilePath]) {
        
        [self checkForPause];
        
        //Source for the data
        NSString *tempString = [[NSString alloc] initWithFormat: @"http://cdn.sutromedia.com/published/%@-sized-photos/%i.jpg", [Props global].deviceType == kiPad ? @"ipad":@"480", theEntry.icon];
        
        NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
        
            
        //Get the data
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:dataURL];
        
        //Write the data to disk
        NSError * theError = nil;
        
        if([imageData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) NSLog(@"**** ERROR:DETAILVIEW.downloadHigherQualityImage: failed to write local file to %@, error = %@, userInfo = %@ *******************************************************************", theFilePath, theError, [theError userInfo]);
        
        else {
            
            NSLog(@"Successfully got photo from %@ and wrote it to %@", theFilePath, tempString);
            NSString *notificationName = [NSString stringWithFormat:@"%@_%i",kHigherQualityImageDownloaded, theEntry.entryid];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:imageData];
        }
    }
    
    // ***** Download thumbnail images ******
    
	// Get the images that still need downloading for the entry
	NSMutableArray *entryImagesArray = [NSMutableArray new];
	
	NSString *query = [NSString stringWithFormat:@"SELECT photos.rowid from photos, entries, entry_photos WHERE downloaded_x100px_photo IS NULL AND entry_photos.entryid = %i AND entry_photos.photoid = photos.rowid AND entry_photos.entryid = entries.rowid", theEntry.entryid];
    
	@synchronized([Props global].dbSync) {
		//NSLog(@"DOWNLOADER.downDataForEntry:lock");
		FMResultSet * rs = [guideDatabase executeQuery:query];
		
		if ([guideDatabase hadError]) NSLog(@"sqlite error in [DataDownloader createImageArray], query = %@, %d: %@", query, [guideDatabase lastErrorCode], [guideDatabase lastErrorMessage]);
		
		while ([rs next]) {
			[entryImagesArray addObject:[NSNumber numberWithInt:[rs intForColumn:@"rowid"]]];
		}
		[rs close];
	}
    
    NSLog(@"GUIDEDOWNLOADER.downloadThumbnailsForEntryInBackground: %i missing photos", [entryImagesArray count]);
    
    for (NSNumber *photoID in entryImagesArray) {
        
        if (stopEntryThumbnailDownload) {
            NSLog(@"GUIDEDOWNLOADER.downloadThumbnailsForEntryInBackground: breaking for %@", theEntry.name);
            break; 
        }
        
        //Source for the data
        NSString *tempString = [[NSString alloc] initWithFormat: @"http://%@/published/dynamic-photos/height/100/%i.jpg", contentSource, [photoID intValue]];
        //NSLog(@"GUIDEDOWNLOADER.downloadThumbnailsForEntryInBackground: id = %@, URL for thumbnail = %@", theEntry.name, tempString);
        
        NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];	
        NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
        
        //NSLog(@"GUIDEDOWNLOADER.getThumbnails: concurrent downloads = %i", [Props global].concurrentDownloads);
        [self checkForPause];
        
        //give some extra bandwidth for this 
        while ([Props global].concurrentDownloads > maxConcurrentDownloads + 4 && !stopEntryThumbnailDownload) {
            [NSThread sleepForTimeInterval:kWaitTimeForRequestsToFinish];}
        
        //Get the data
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:dataURL];
        [request setDelegate:self];
        
        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:kEntryThumbnailType, @"type", photoID , @"photo_id", nil];
        request.info = info;
        [request startAsynchronous];
        concurrentRequests ++;
        [Props global].concurrentDownloads ++;
    }
    
    if ([entryImagesArray count] > 0) {
        int waitCounter = 0;
        while (concurrentRequests > 0 && waitCounter < 100 && !shouldStop && !stopEntryThumbnailDownload) {
            [NSThread sleepForTimeInterval:0.1];
            waitCounter ++;
        }
        
        if ([groupedPhotoIDsToUpdate count] > 0) [self updatePhotosTableWithGroupedPhotoIDs];
    }
    
    downloadingEntryThumbnails = FALSE;
}


/*- (void) downloadHigherResolutionImage:(NSNotification*) theNotification {
    
    [self performSelectorInBackground:@selector(downloadHigherResolutionImageInBackground:) withObject:theNotification.object];
}


- (void) downloadHigherResolutionImageInBackground:(NSNumber*) thePhotoId {

    NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i%@.jpg", [Props global].contentFolder, [thePhotoId intValue], [Props global].deviceType == kiPad ? @"_768" : @""];
    
    [self checkForPause];
    
    //Source for the data
    NSString *tempString = [[NSString alloc] initWithFormat: @"http://cdn.sutromedia.com/published/%@-sized-photos/%i.jpg", [Props global].deviceType == kiPad ? @"ipad":@"480", theEntry.icon];
    
    NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
    
    
    //Get the data
    NSData *imageData = [[NSData alloc] initWithContentsOfURL:dataURL];
    
    //Write the data to disk
    NSError * theError = nil;
    
    if([imageData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) NSLog(@"**** ERROR:DETAILVIEW.downloadHigherQualityImage: failed to write local file to %@, error = %@, userInfo = %@ *******************************************************************", theFilePath, theError, [theError userInfo]);
    
    else {
        
        NSLog(@"Successfully got photo from %@ and wrote it to %@", theFilePath, tempString);
        NSString *notificationName = [NSString stringWithFormat:@"%@_%i",kHigherQualityImageDownloaded, [thePhotoId intValue]];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:imageData];
    }
}
*/

- (void) updateMapsDBWithGroupedMapTiles {
    
    //NSDate *date = [NSDate date];
    
    @autoreleasepool {
        
        @synchronized([Props global].mapDbSync) {
            
            [mainMapDatabase executeUpdate:@"BEGIN TRANSACTION"];
            
            for (NSMutableDictionary *mapInfo in groupedMapTilesToupdate) {
                [mainMapDatabase executeUpdate:@"REPLACE into tiles (tilekey, zoom, row, col, image, downloaded) values (?, ?, ?, ?, ?, ?)", [mapInfo objectForKey:@"tilekey"], [mapInfo objectForKey:@"zoom"], [mapInfo objectForKey:@"row"], [mapInfo objectForKey:@"column"], [mapInfo objectForKey:@"image"], [NSNumber numberWithInt:guideId]];
            }
            
            [mainMapDatabase executeUpdate:@"END TRANSACTION"]; 
        }
        
        [groupedMapTilesToupdate removeAllObjects];
        
        [self postUpdateForKey:kOfflineMaps_Max_ContentSize];
        
        if (downloadingBaseContent) [self postUpdate];
        
    }
    
    //NSLog(@"GUIDEDOWNLOADER.updateMapsDBWithGroupedMapTiles: time in sync = %0.2f", - [date timeIntervalSinceNow]);
}


- (void) updatePhotosTableWithGroupedPhotoIDsForThumbnails {
    
    //NSDate *date = [NSDate date];
    //NSLog(@"GUIDEDOWNLOADER.updatePhotosTableWithGroupedPhotoIDsForThumbnails");
    @autoreleasepool {
        
        if (shouldStop || stopImageDownload) return;
        
        @synchronized([Props global].dbSync) {
            
            NSMutableString *photoIdsToUpdate = [[NSMutableString alloc] initWithString:@""];
            
            for (NSNumber *photoId in groupedThumbnailPhotoIDsToUpdate) {
                [photoIdsToUpdate appendFormat:@"%i,", [photoId intValue]];
            }
            
             [groupedThumbnailPhotoIDsToUpdate removeAllObjects];
            
            if ([photoIdsToUpdate length] > 0)[photoIdsToUpdate deleteCharactersInRange:NSMakeRange([photoIdsToUpdate length] - 1, 1)]; //delete the last comma
            
            NSString *query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_x100px_photo = 1 WHERE rowid in (%@)", photoIdsToUpdate];
            
            [guideDatabase executeUpdate:@"BEGIN TRANSACTION"];
            
            /*
            for (NSNumber *photoID in groupedThumbnailPhotoIDsToUpdate) {
                
                thumbnailImageDownloadCounter ++;
                
                NSString *query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_x100px_photo = %i WHERE rowid = %i",thumbnailImageDownloadCounter, [photoID intValue]];
                
                //NSLog(@"The query = %@", query);
                [guideDatabase executeUpdate:query];
            }*/
            
            [guideDatabase executeUpdate:query];
            [guideDatabase executeUpdate:@"END TRANSACTION"];
            
            //NSLog(@"GUIDEDOWNLOADER.updatePhotosTableWithGroupedPhotoIDsForThumbnails: query = %@", query);
        }
                
        if ([Props global].isShellApp) [self postUpdate];
        
    }
    //NSLog(@"GUIDEDOWNLOADER.updatePhotosTableWithGroupedPhotoIDs: time in sync = %0.2f", - [date timeIntervalSinceNow]);
}


- (void) updatePhotosTableWithGroupedPhotoIDs {
    
    //NSDate *date = [NSDate date];
    //NSLog(@"GUIDEDOWNLOADER.updatePhotosTableWithGroupedPhotoIDs");
    @autoreleasepool {
        
        if (shouldStop || stopImageDownload || guideDatabase == nil) return;
        
        @synchronized([Props global].dbSync) {
            
            NSMutableString *photoIdsToUpdate = [[NSMutableString alloc] initWithString:@""];
            
            for (NSNumber *photoId in groupedPhotoIDsToUpdate) {
                [photoIdsToUpdate appendFormat:@"%i,", [photoId intValue]];
            }
            
            if ([photoIdsToUpdate length] > 0) [photoIdsToUpdate deleteCharactersInRange:NSMakeRange([photoIdsToUpdate length] - 1, 1)]; //delete the last comma
            
            NSString *query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_%ipx_photo = 1 WHERE rowid in (%@)", [Props global].deviceType == kiPad ? 768:320, photoIdsToUpdate];

            
            [groupedPhotoIDsToUpdate removeAllObjects];
            [guideDatabase executeUpdate:@"BEGIN TRANSACTION"];
            
            //NSLog(@"The query = %@", query);
            [guideDatabase executeUpdate:query];
            
            /*for (NSNumber *photoID in groupedPhotoIDsToUpdate) {
                
                imageDownloadCounter ++;
                
                NSString *query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_%ipx_photo = %i WHERE rowid = %i", [Props global].deviceType == kiPad ? 768:320, imageDownloadCounter, [photoID intValue]];
                
                //NSLog(@"The query = %@", query);
                [guideDatabase executeUpdate:query];
            }*/
            
            [guideDatabase executeUpdate:@"END TRANSACTION"];
        }
        
        
        [self postUpdateForKey:kOfflinePhotos];
        //if (![Props global].isShellApp && !stopImageDownload) [self postUpdateForKey:kOfflinePhotos];
        //else [self postUpdate];
        
    }
    //NSLog(@"GUIDEDOWNLOADER.updatePhotosTableWithGroupedPhotoIDs: time in sync = %0.2f", - [date timeIntervalSinceNow]);
}


#pragma mark
#pragma mark ASIHTTP Delegate Methods

- (void)requestFinished:(ASIHTTPRequest *)request
{
    //NSLog(@"GUIDEDOWNLOADER.requestFinished:");
    //[self checkForPause];
    
    NSDictionary *info = request.info;
    //NSLog(@"GUIDEDOWNLOADER.requestFinished: zoom = %i", [[tileInfo objectForKey:@"zoom"] intValue]);
    
    // Use when fetching binary data
    NSData *responseData = [request responseData];
    
    if ([[info objectForKey:@"type"]  isEqual: kMapTileType]) {
        
        //NSLog(@"Response data is %i long", [responseData length]);
        
        /*if ([responseData length] == 103) {
         NSLog(@"Writing image to album");
         UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:responseData],nil,nil,nil);
         }*/
        
        /* if ([responseData hash] == 159546528) {
         NSLog(@"Got a bad image from %@", [request.url absoluteString]);
         [badImageArray addObject:[request.url absoluteString]];
         }
         
         else {*/
        
        NSMutableDictionary *mapInfo = [NSMutableDictionary dictionaryWithDictionary:info];
        
        [mapInfo setObject:responseData forKey:@"image"];
        
        if (groupedMapTilesToupdate == nil) groupedMapTilesToupdate = [NSMutableArray new];
        
        [groupedMapTilesToupdate addObject:mapInfo];
        
        if ([groupedMapTilesToupdate count] > kMapTileUpdateGroupSize) [self updateMapsDBWithGroupedMapTiles];
        
        if (downloadingBaseContent) current_BaseContentSize += kAverageMapTileSize;
        else current_OfflineMapContentSize += kAverageMapTileSize; 
        
        // }
    }
    
    else if ([[info objectForKey:@"type"]  isEqual: kImageType]) {
        
        NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i%@.jpg",contentFolder, [[info objectForKey:@"photo_id"] intValue], [Props global].deviceType == kiPad ? @"_768" : @""];
        
        NSError *theError = nil;
        
        if([responseData writeToFile: theFilePath  options:NSDataWritingFileProtectionNone error:&theError]!= TRUE){
            NSLog(@"**** ERROR:GUIDEDOWNLOADER.requestFinished: failed to write local file to %@, error = %@, userInfo = %@ *******************************************************************", contentFolder, theError, [theError userInfo]);
        }
        else {
            
            current_OfflinePhotosContentSize += [Props global].deviceType == kiPad ? kAverageiPadImageSize : kAverageiPhoneImageSize;
            
            if (groupedPhotoIDsToUpdate == nil) groupedPhotoIDsToUpdate = [NSMutableArray new];
            
            @synchronized([Props global].dbSync) {[groupedPhotoIDsToUpdate addObject:[info objectForKey:@"photo_id"]];}
            
            if ([groupedPhotoIDsToUpdate count] > kPhotoUpdateGroupSize) [self updatePhotosTableWithGroupedPhotoIDs];
        }
    }
    
    else if ([[info objectForKey:@"type"]  isEqual: kThumbnailType] || [[info objectForKey:@"type"]  isEqual: kEntryThumbnailType]) {
        
        NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i_x100.jpg",contentFolder, [[info objectForKey:@"photo_id"] intValue]];
        
        NSError *theError = nil;
        
        if([responseData writeToFile: theFilePath  options:NSDataWritingFileProtectionNone error:&theError]!= TRUE){
            NSLog(@"**** ERROR:GUIDEDOWNLOADER.requestFinished: failed to write local file to %@, error = %@, userInfo = %@ *******************************************************************", contentFolder, theError, [theError userInfo]);
        }
        
        else {
            
            current_BaseContentSize += kAverageThumbnailSize;
            
            //NSLog(@"GUIDEDDOWNLOADER.requestFinished: Got thumbnail. MB downloaded = %f", mB_Downloaded);
            
            if (groupedThumbnailPhotoIDsToUpdate == nil) groupedThumbnailPhotoIDsToUpdate = [NSMutableArray new];
            
            @synchronized([Props global].dbSync) {[groupedThumbnailPhotoIDsToUpdate addObject:[info objectForKey:@"photo_id"]];}
            
            int updateCount = [[info objectForKey:@"type"]  isEqual: kEntryThumbnailType] ? 4 : 30;
            
            if ([groupedThumbnailPhotoIDsToUpdate count] > updateCount) [self updatePhotosTableWithGroupedPhotoIDsForThumbnails];
            
            //else NSLog(@"GroupedThumbnailPhotoIDsToUpdate = %i, updateLimit = %i", [groupedThumbnailPhotoIDsToUpdate count], updateCount);
        }
    }
    
        
    else if ([[info objectForKey:@"type"]  isEqual: kIconImageType]) {
		
        //Write the data to disk
        int iconId = [[info objectForKey:@"photo_id"] intValue];
        NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i%@.jpg",contentFolder, iconId, [Props global].deviceType == kiPad ? @"_768" : @""];
        NSError * theError = nil;
        
        if([responseData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) NSLog(@"**** ERROR:GUIDEDOWNLOADER.requestFinised: failed to write icon file to %@, error = %@, userInfo = %@ *******************************************************************", contentFolder, theError, [theError userInfo]);
        
        else {
            
            current_BaseContentSize += [Props global].deviceType == kiPad ? kAverageiPadImageSize : kAverageiPhoneImageSize;
            
            NSString *query = [[NSString alloc] initWithFormat:@"UPDATE photos SET downloaded_%ipx_photo = 1 WHERE rowid = %i", [Props global].deviceType == kiPad ? 768:320, iconId];
            
            //NSLog(@"GUIDEDOWNLOADER.requestFinished: Updating photo table for icon photo, query = %@", query);
            
            @synchronized([Props global].dbSync) {
                [guideDatabase executeUpdate:@"BEGIN TRANSACTION"];
                [guideDatabase executeUpdate:query];
                [guideDatabase executeUpdate:@"END TRANSACTION"];
            }
            
            
            
            if ([Props global].hasLocations) 
                [self performSelectorInBackground:@selector(makeMapMarker:) withObject:[NSNumber numberWithInt:iconId]];
            
            [self postUpdate];
        }
    }
    
    else {
        NSLog(@"*******************ERROR - GUIDEDOWNLOADER.requestFinished: Type not found. Type = %@ ***************************", [info objectForKey:@"type"]);
        return;
    }
    
    concurrentRequests --;
    [Props global].concurrentDownloads --;
    consecutiveFailureCount = 0;
}


- (void)requestFailed:(ASIHTTPRequest *)request
{
    concurrentRequests --;
    [Props global].concurrentDownloads --;
    NSLog(@"GUIDEDOWNLOADER.requestFailed: error = %@, URL = %@", [[request error] description], [request.url absoluteString]);
    
    if ([[request.url absoluteString] length] > 27) {
        //We need to check that the bad source is the same is the current source to avoid counting failed requests left in the queue from the last source for the current one
        NSString *source = [[request.url absoluteString] substringWithRange:NSMakeRange(7, 19)];
        
        if ([source isEqualToString:contentSource]) {
            consecutiveFailureCount ++;
            
            if (consecutiveFailureCount >= kMaxConsecutiveFailures && !updatingContentSource) [self performSelectorInBackground:@selector(updateContentSource) withObject:nil];
        }
    }
    
    //Keep track of what we missed so we can try again later
    NSString *objectType = [request.info objectForKey:@"type"];
    NSMutableArray *missingContentArray = [missingContent objectForKey:objectType];
    if (missingContentArray == nil) missingContentArray = [NSMutableArray new];
    [missingContentArray addObject:request.info];
    [missingContent setObject:missingContentArray forKey:objectType];
}


#pragma mark
#pragma mark Information and status getters and senders
- (void) postBaseContentDownloadUpdate {
    
}


- (void) postUpdate {
    
    if (current_BaseContentSize - last_BaseContentSizeUpdate > .1 || self.status == kDownloadComplete || self.status != lastStatus || lastCurrentTask != currentTask) {
        NSDate *date = [NSDate date];
        
        /*if (mB_Downloaded > totalToDownload * 1.1) {
            NSLog(@"********* ERROR: GUIDEDOWNLOADER.postUpdate: current = %0.1f and total = %0.1f for %i with status %i", mB_Downloaded, totalToDownload, guideId, self.status);
        }*/
        
        NSNumber *current = [NSNumber numberWithFloat:current_BaseContentSize];
        NSNumber *total = [NSNumber numberWithFloat:total_BaseContentSize];
        NSNumber *summary = [NSNumber numberWithInt:self.status];
        //NSNumber *shouldDownloadOfflineImages = [NSNumber numberWithInt:(downloadOfflineImages ? 1 : 0)];
        //NSNumber *_imageSizeForRemoval = [NSNumber numberWithFloat:imageSizeForRemoval];
        //NSNumber *_imageSizeForDownload = [NSNumber numberWithFloat:imageSizeForDownload];
        
        NSDictionary *detailedStatus = [NSDictionary dictionaryWithObjectsAndKeys: current, @"current", total, @"total", summary, @"summary", currentTask, @"current task", nil];
        [[NSUserDefaults standardUserDefaults] setObject:detailedStatus forKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, guideId]];
        
        //NSLog(@"GUIDEDOWNLOADER.postUpdate: for guide %i. Current = %f, total = %f, status = %i", guideId, mB_Downloaded, totalToDownload, self.status);
        //[[NSUserDefaults standardUserDefaults] synchronize]; //Remove me
        
        NSString *notificationName = [NSString stringWithFormat:@"%@_%i", kUpdateDownloadProgress, guideId];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:detailedStatus];
        
        
        last_BaseContentSizeUpdate = current_BaseContentSize;
        lastStatus = self.status;
        lastCurrentTask = currentTask;
        
        timeInPostUpdate += -[date timeIntervalSinceNow];
    }
    
    //else NSLog(@"GUIDEDOWNLOADER.postUpdate: not posting. mB downloaded = %0.2f, last update = %0.2f", mB_Downloaded, last_mB_Update);
}


- (void) postUpdateForKey:(NSString*) downloadTypeKey {
	
	if ([downloadTypeKey  isEqual: kOfflineMaps_Max_ContentSize]) {
        //NSLog(@"Offline map size in guidedownloader = %0.2f", current_OfflineMapContentSize);
		NSString *offlineMapSizeKey = [NSString stringWithFormat:@"%@_%i", kCurrentMapContentSize, guideId];
		[[NSUserDefaults standardUserDefaults] setFloat:current_OfflineMapContentSize forKey:offlineMapSizeKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
    
    if ([Props global].appID == guideId || [Props global].appID == 1) {
        
        NSString *notificationName = [NSString stringWithFormat:@"%@_%@", kUpdateOfflineContentDownloadProgress, downloadTypeKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kContentDownloaded object:nil];
    }
}


- (void) setSummaryStatusTo:(int) newStatus {
    
    NSLog(@"Setting status to %i", newStatus);
    
    self.status = newStatus;
    
    [self postUpdate];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (NSArray*) getMissingIconPhotoIds {
    
    NSDate *date = [NSDate date];
    
    NSString * query = [NSString stringWithFormat:@"SELECT icon_photo_id FROM entries WHERE icon_photo_id NOT IN (SELECT rowid FROM photos WHERE downloaded_%ipx_photo NOT NULL)", [Props global].deviceType == kiPad ? 768 : 320];
    NSMutableArray *iconPhotoIds = [NSMutableArray new];
    
    @synchronized ([Props global].dbSync) {
        FMResultSet *rs = [guideDatabase executeQuery:query];
        
        while ([rs next]) [iconPhotoIds addObject:[NSNumber numberWithInt:[rs intForColumn:@"icon_photo_id"]]];
        [rs close];
    }
    
    /*NSMutableArray *missingIconPhotoIds = [NSMutableArray new];
     for (NSNumber *photoId in iconPhotoIds) {
     
     NSString *theQuery = [NSString stringWithFormat:@"SELECT downloaded_%ipx_photo AS downloaded FROM photos WHERE rowid = %i", [Props global].deviceType == kiPad ? 768 : 320,[photoId intValue]];
     
     @synchronized ([Props global].dbSync) {
     FMResultSet *rs = [guideDatabase executeQuery:theQuery];
     BOOL downloaded = FALSE;
     
     if ([rs next]) downloaded = [rs intForColumn:@"downloaded"] == 1 ? TRUE : FALSE;
     [rs close];
     
     if (!downloaded) [missingIconPhotoIds addObject:photoId];
     }
     }
     
     NSArray *missingIds = [NSArray arrayWithArray:missingIconPhotoIds];
     [missingIconPhotoIds release];*/
    
    NSArray *missingIds = [NSArray arrayWithArray:iconPhotoIds];
    
    NSLog(@"GUIDEDOWNLOADER.getMissingIconPhotoIds: took %0.3f seconds, %i missing photos", -[date timeIntervalSinceNow], [missingIds count]);
    
    return missingIds;
}


/*- (void) buildOfflineLinkURLArray {
    
    if ([Props global].osVersion >= 4) {
        NSMutableArray *allOfflineFileNames = [NSMutableArray new];
        
        @synchronized([Props global].dbSync) {
            
            //NSLog(@"GUIDEDOWNLOADER - db lock 4 for %i", guideId);
            FMResultSet * rs = [guideDatabase executeQuery:@"SELECT description FROM entries where description LIKE '%sutromedia.com/published/offline/%'"];
            
            while ([rs next]){
                
                NSString *entryDescription = [rs stringForColumn:@"description"];
                //NSLog(@"Description = %@", entryDescription);
                NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"http://www.sutromedia.com/published/offline/.*?\"" options:NSRegularExpressionCaseInsensitive error:nil];
                NSArray *regexResults = [regex matchesInString:entryDescription options:0 range:NSMakeRange(0, [entryDescription length])];
                [regex release];
                
                for (NSTextCheckingResult *result in regexResults) {
                    NSString *urlWithEndQuote = [entryDescription substringWithRange:result.range];
                    NSString *url = [urlWithEndQuote substringWithRange:NSMakeRange(0, [urlWithEndQuote length] -1)];
                    NSLog(@"URL = %@", url);
                    [allOfflineFileNames addObject:url]; 
                }
            }
            
            [rs close];
        }
        
        offlineLinkURLs = [NSArray arrayWithArray:allOfflineFileNames];
        
        [allOfflineFileNames release];
    }
}*/


- (BOOL) doesAppHaveMaps {
    
    BOOL appHasMaps = FALSE;
    
    @synchronized ([Props global].dbSync){
        FMResultSet *rs = [guideDatabase executeQuery:@"SELECT value FROM app_properties WHERE key = 'has_locations'"];
        
        if ([rs next]) appHasMaps = [rs intForColumn:@"value"] == 1 ? TRUE : FALSE;
        
        [rs close];
    }
    
    return appHasMaps;
}


- (void) checkForContentUpdate {
    
    if (downloadingBaseContent) return;
    
    NSDictionary *theStatus = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, guideId]];
    self.status = [[theStatus objectForKey:@"summary"] intValue]; //set status here in case it has not yet been set
    
    NSLog(@"GUIDEDOWNLODAER.checkForContentUpdate: Checking for %i with status = %i", guideId, status);
    
    if (status == kDownloadNotStarted) return;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%i-bundleversion.txt", [Props global].serverDatabaseUpdateSource, guideId]];
    NSError* error;
    latestBundleVersion = [[NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error] intValue];
    int currentBundleVersion = [self getCurrentBundleVersion];
    
    NSLog(@"GUIDEDOWNLODAER.checkForContentUpdate:Latest bundle version = %i, current bundle version = %i, guide id = %i", latestBundleVersion, currentBundleVersion, guideId);
    
    if (latestBundleVersion > currentBundleVersion) [self performSelectorInBackground:@selector(restartDownloadProcess) withObject:nil];
}


- (int) getCurrentBundleVersion {
    
    int currentBundleVersion = 0;
    
    @synchronized([Props global].dbSync){
        
        /*BOOL needToCloseDatabase = FALSE;
        
        if (guideDatabase == nil) {
            NSString *filePath = [NSString stringWithFormat:@"%@/%i/content.sqlite3", [Props global].cacheFolder, guideId];
            guideDatabase = [[FMDatabase alloc] initWithPath: filePath];
            if (![guideDatabase open]) NSLog(@"GUIDEDOWNLOADER.checkForContentUpdate: Error opening database");
            needToCloseDatabase = TRUE; //Leave database as we found it
        } */
        
        FMResultSet *rs = [guideDatabase executeQuery:@"SELECT Value FROM app_properties WHERE key = 'bundle_version'"];
        
        if ([rs next]) currentBundleVersion = [rs intForColumn:@"Value"];
        
        [rs close];
        
        //if (needToCloseDatabase) {[guideDatabase close]; [guideDatabase release]; guideDatabase = nil;}
    }
    
    return currentBundleVersion;
}


- (void) restartDownloadProcess {
    
    @autoreleasepool {
    
        NSLog(@"GUIDEDOWNLOADER.restartDownloadProcess");
        
        shouldStop = TRUE;
        
        while (!stopped) {
            NSLog(@"GUIDEDOWNLOADER.restartDownloadProcess: Waiting for stop for %i", guideId);
            shouldStop = TRUE; //In case this gets set otherwise somewhere else
            [NSThread sleepForTimeInterval:1];
        }
        
        [self setSummaryStatusTo:kDownloadInProgress];
        
        mapsDownloaded = FALSE;
        waiting = FALSE;
        
        [self performSelectorInBackground:@selector(downloadBaseContent) withObject:nil];
    }
}


- (void) startSampleUpgradeDownload {
    
    @autoreleasepool {
		
        NSLog(@"GUIDEDOWNLOADER.startSampleUpgradeDownload");
        
        shouldStop = TRUE;
        
        while (!stopped) {
            NSLog(@"GUIDEDOWNLOADER.restartDownloadProcess: Waiting for stop for %i", guideId);
            shouldStop = TRUE; //In case this gets set otherwise somewhere else
            [NSThread sleepForTimeInterval:1];
        }
        
        [self setSummaryStatusTo:kDownloadInProgress];
        
        mapsDownloaded = FALSE;
        waiting = FALSE;
        
        doingSampleUpgrade = TRUE;
        
        [self performSelectorInBackground:@selector(downloadBaseContent) withObject:nil];
    }
}




#pragma mark
#pragma mark Control downloader - pause, slow down, speed up, stop, resume, download more, and removal

- (void) checkForPause {
    
    //NSLog(@"GUIDEDOWNLOADER.checkForPause: %@ main thread", [NSThread isMainThread] ? @"in" : @"not in");
    
    NSDate *date = [NSDate date];
    
    [NSThread sleepForTimeInterval: waitTime]; //Sleep thread a little bit no matter what to let other events through
    
    //Content source is nil when no internet is available or all content servers are down. Prop keeps trying in both cases until it successfully gets a content source
    
    while ([Props global].serverContentSource == nil)  {
        [NSThread sleepForTimeInterval:1.0];
    }

    contentSource = [Props global].serverContentSource;
    
    while ((pauseDownload || waiting) && !shouldStop) {
        [NSThread sleepForTimeInterval: 2.0];
        //NSLog(@"GUIDEDOWNLOADER:Paused for %i", guideId);
    }
    
    while (![Props global].connectedToInternet && !shouldStop) {
        [NSThread sleepForTimeInterval: 1.0];
        NSLog(@"GUIDEDOWNLOADER: No internet for %i", guideId);
        //NSLog(@"Should stop = %@", shouldStop ? @"TRUE" : @"FALSE");
    }
    
    timeInCheckForPause += -[date timeIntervalSinceNow];
}


- (void) slowDownload:(NSNotification*) theNotification {
    
    NSLog(@"GUIDEDOWNLOADER.slowDownload");
    //Don't slow the guide that is currently being used
    if ([Props global].appID != guideId) waitTime = kSlowWaitTime; //wait time in seconds between each download
    
    else NSLog(@"GUIDEDOWNLOADER.slowDownload: Keeping %@ fast", [Props global].appName);
    //[NSThread setThreadPriority:0.0];
    
}


- (void) speedUpDownload:(NSNotification*) theNotification {
    
    NSLog(@"GUIDEDOWNLOADER.speedUpDownload");
    waitTime = kFastWaitTime; //wait time in seconds between each download
    //[NSThread setThreadPriority:0.9];
    
}


- (void) pauseDownload:(NSNotification*) theNotification {
    
    if ([theNotification object] == nil || [[theNotification object] intValue] == guideId){
        
        pauseDownload = TRUE;
        [[Props global] decrementIdleTimerRefCount];
        NSLog(@"GUIDEDOWNLOADER.pauseDownload: Got notification to pause for %i with object = %i", guideId, [[theNotification object] intValue]);
    }
}


- (void) resumeDownload:(NSNotification*) theNotification {
    
    if ([theNotification object] == nil || [[theNotification object] intValue] == guideId){
        
        pauseDownload = FALSE;
        [[Props global] incrementIdleTimerRefCount];
        NSLog(@"GUIDEDOWNLOADER.resumeDownload: paused set to %@ for %i", pauseDownload ? @"TRUE" : @"FALSE", guideId);
    }
}


/*- (void) downloadOfflinePhotos:(NSNotification*) theNotification {

    if ([theNotification object] == nil || [[theNotification object] intValue] == guideId){
        
        NSLog(@"GUIDEDOWNLOADER.downloadOfflinePhotos");
        //Update user defaults to indicate that offline images should be downloaded
        downloadOfflineImages = TRUE;
        pauseDownload = FALSE;
        [self setSummaryStatusTo:kDownloadingImages];
        [self postUpdate];
        
        waiting = FALSE;
    }
}*/


- (void) removeOfflinePhotos:(NSNotification*) theNotification {
    
    if ([theNotification object] == nil || [[theNotification object] intValue] == guideId){
        
        shouldStop = TRUE;
        
        [self removeOfflinePhotos];
        
        shouldStop = FALSE;
    }       
}


- (void) removeOfflinePhotos {
    
    @autoreleasepool {
    
        NSLog(@"GUIDEDOWNLOADER.removeOfflinePhotos for %i", guideId);
        
        // NSLog(@"**********************OFFLINE IMAGE REMOVE DISABLED ********************");
        
        stopImageDownload = TRUE; //This is used for exiting image download from stand alone app
        
        if(!pauseDownload) [[Props global] incrementIdleTimerRefCount];
        
        NSLog(@"GUIDEDOWNLOADER.removeOfflinePhotos: About to wait for main download loop to exit");
        
        while (downloadingPhotos) { //Wait for main download loop to exit
            [NSThread sleepForTimeInterval:0.005]; 
            stopImageDownload = TRUE;
        }
        
        NSLog(@"GUIDEDOWNLOADER.removeOfflinePhotos: Main download loop has exited");
        
        
        //******* Populate array of photos to remove (all images except icon photos) **********
        NSString * query = [NSString stringWithFormat:@"SELECT DISTINCT(photos.rowid) FROM photos, entries WHERE downloaded_%ipx_photo is NOT NULL AND photos.rowid NOT IN (SELECT icon_photo_id FROM entries)", [Props global].deviceType == kiPad ? 768 : 320];
        
        //Limit the number to remove based on the max allowed photo size
        NSLog(@"Max photosize = %0.2f, mB_Downloaded = %0.2f, averagePhotoSize = %0.2f", max_OfflinePhotoContentSize, current_OfflinePhotosContentSize, averagePhotoSize);
        int numberToRemove = (current_OfflinePhotosContentSize - max_OfflinePhotoContentSize)/averagePhotoSize;
        
        //if ([Props global].isShellApp) numberToRemove -= [[EntryCollection sharedEntryCollection] numberOfEntries];
        
        if (numberToRemove <= 0) {
            shouldStop = FALSE;
            stopImageDownload = FALSE;
            return;
        }
        
        query = [query stringByAppendingFormat:@" LIMIT %i", numberToRemove];
        
        NSLog(@"GUIDEDOWNLOADER.removeOfflinePhotos for %i. Query = %@", guideId, query);
        NSMutableArray *photoIDs = [NSMutableArray new];
        
        //NSString *theFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", contentFolder];
        
        //FMDatabase *_guideDatabase = [Props global].isShellApp ? [[FMDatabase alloc] initWithPath:theFilePath] : [EntryCollection sharedContentDatabase];
        
        //if(![_guideDatabase open]) NSLog(@"GUIDEDONWLOADER.ContentDatabase: could not open database for %i", guideId);
        
        @synchronized([Props global].dbSync){
            //NSLog(@"GUIDEDOWNLOADER - db lock 5 for %i", guideId);
            FMResultSet *rs = [guideDatabase executeQuery:query];
            
            while ([rs next]) {
                
                int photoID = [rs intForColumn:@"rowid"];
                [photoIDs addObject:[NSNumber numberWithInt:photoID]];
            }
            
            [rs close];
        }
        
        //******* Delete all images in that array from the file system **********
        NSMutableString *deletedPhotos = [NSMutableString stringWithString:@""];
        
        for (NSNumber *photoID in photoIDs) {
            
            NSString *imagePath = [NSString stringWithFormat:@"%@/images/%i%@.jpg", contentFolder, [photoID intValue], [Props global].deviceType == kiPad ? @"_768" : @""]; 
            
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath: imagePath error:&error];
            
            if (error != nil) NSLog(@"GUIDEDOWNLOADER.removeOfflinePhotos: ERROR - %@ for %@", [error description], imagePath); 
            
            else [deletedPhotos appendFormat:@"%i,", [photoID intValue]];
        }
        
        if ([deletedPhotos length] > 2) [deletedPhotos deleteCharactersInRange:NSMakeRange([deletedPhotos length] -1, 1)]; //delete off the last comma
        
        //******** Update the content database to mark all of the photos as deleted
        //query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_%ipx_photo = NULL WHERE rowid NOT IN (SELECT icon_photo_id FROM entries)", [Props global].deviceType == kiPad ? 768:320];
        
        query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_%ipx_photo = NULL WHERE rowid IN (%@)", [Props global].deviceType == kiPad ? 768:320, deletedPhotos];
        
        NSLog(@"GUIDEDOWNLOADER.removeOfflinePhotos: Query = %@", query);
        
        @synchronized([Props global].dbSync) {
            
            [guideDatabase executeUpdate:@"BEGIN TRANSACTION"];
            [guideDatabase executeUpdate:query];
            [guideDatabase executeUpdate:@"END TRANSACTION"];
        }
        
        //**********  update statuses as necessary **************
   /* downloadOfflineImages = FALSE;
        
        if ([Props global].isShellApp) {
            [self setSummaryStatusTo:kDownloadComplete];
            [self updateTotalContentSize];
            mB_Downloaded = totalToDownload;
            [self updatePhotoContentSizeForDownload];
        }*/
        
        [self postUpdateForKey:kOfflinePhotos]; //This updates the user defaults and posts a notification to update the display
        
        //Clean up
        /*if ([Props global].isShellApp) {
            [_guideDatabase close];
            [_guideDatabase release];
        }*/
        
        
        shouldStop = FALSE;
        stopImageDownload = FALSE;
    
    }
}


- (void) removeOfflineMaps {
    
    @autoreleasepool {
    
    //NSLog(@"**********************OFFLINE MAP REMOVE DISABLED ********************");
        stopMapDownload = TRUE; //This is used for stopping map tile download from stand alone app
        
        if(!pauseDownload) [[Props global] incrementIdleTimerRefCount];
        
        NSLog(@"GUIDEDOWNLOADER.removeOfflineMaps: About to wait for main download loop to exit");
        
        while (downloadingMaps) { //Wait for main download loop to exit
            [NSThread sleepForTimeInterval:0.005]; 
            stopMapDownload = TRUE; //Keep setting this here in case it gets changed elsewhere
        }

        NSLog(@"Main download loop has exited");
        //stopped = FALSE; //reset quickly in case remove gets called for another content type in standalone app
        removingMaps = TRUE;
        
        //NSDate *date = [NSDate date];
        
        NSString *mapDatabaseLocation = [Props global].isShellApp ? [NSString stringWithFormat:@"%@/offline-map-tiles.sqlite3",[Props global].contentFolder] : [Props global].mapDatabaseLocation;
        NSLog(@"Map db location = %@", mapDatabaseLocation);
        FMDatabase *mapDatabase = [[FMDatabase alloc] initWithPath:mapDatabaseLocation];
        
        if (![mapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.updateTotalContentSize - Can't open map tile database");
        
        int numberOfMapTiles = 0;
        
        @synchronized ([Props global].mapDbSync) {
            FMResultSet *rs = [mapDatabase executeQuery:@"SELECT value AS theCount FROM preferences WHERE name = 'initial_tile_row_count'"];
            //FMResultSet *rs = [mapDatabase executeQuery:@"SELECT value as theCount FROM preferences WHERE name = 'map.maxZoom'"];
            
            if ([rs next]) numberOfMapTiles = [rs intForColumn:@"theCount"];
            
            [rs close];
        }
        
        //NSLog(@"GUIDEDOWNLOADER.updateTotalContentSize: map tiles are %f MB", numberOfMapTiles * kAverageMapTileSize);
        
        total_OfflineMapContentSize = numberOfMapTiles * kAverageMapTileSize;
        
        //float fractionOfTotal = max_OfflineMapContentSize/total_OfflineMapContentSize;
        
        //Figure out what the max zoom level is
        int maxZoom = 0;
        
        @synchronized ([Props global].mapDbSync) {
            
            FMResultSet *rs2 = [mapDatabase executeQuery:@"SELECT value FROM preferences WHERE name = 'map.maxZoom'"];
            
            if ([rs2 next]) maxZoom = [rs2 intForColumn:@"value"];
            
            [rs2 close];
        }
        
        

        NSMutableString *tiles_to_delete = [[NSMutableString alloc] initWithString:@""];
        //if ([Props global].isShellApp) {
		//NSString *mapDatabaseLocation = [NSString stringWithFormat:@"%@/offline-map-tiles.sqlite3",[Props global].contentFolder];
		
		//FMDatabase *mapDatabase = [[FMDatabase alloc] initWithPath:mapDatabaseLocation];
		
		//if (![mapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.updateTotalContentSize - Can't open map tile database");
		
		int zoom_level = maxZoom;
		float amount_to_delete = 0;
		float total_amount_to_delete = total_OfflineMapContentSize - max_OfflineMapContentSize;
		
		while (zoom_level > kMapZoomLevelForBaseContent && amount_to_delete < total_amount_to_delete) { //Leave all tiles higher than zoom level 14
			
			@synchronized ([Props global].mapDbSync) {
				
				NSString *query = [NSString stringWithFormat:@"SELECT tilekey FROM tiles WHERE zoom = %i", zoom_level];
				//NSLog(@"Query = %@", query);
				FMResultSet *rs = [mapDatabase executeQuery:query];
				
				while ([rs next]) {
					unsigned long long int tileKey = [rs longLongIntForColumn:@"tilekey"];
					//NSLog(@"Tilekey = %llu", tileKey);
					[tiles_to_delete appendFormat:@"%llu,",tileKey];
					amount_to_delete += kAverageMapTileSize;
					if (amount_to_delete > total_amount_to_delete) break;
				}
				
				[rs close];
			}
			
			zoom_level --;
		}
		
		[mapDatabase close];
		
		if ([tiles_to_delete length] > 0) {
			//NSLog(@"Tiles to delete length = %i", [tiles_to_delete length]);
			
			[tiles_to_delete deleteCharactersInRange:NSMakeRange([tiles_to_delete length] - 1, 1)];
			
			//NSLog(@"Tiles to remove = %@", tiles_to_delete);
		}
		
        
        @synchronized([Props global].mapDbSync) {
			
			if (mainMapDatabase != nil) {
				[mainMapDatabase close];
				mainMapDatabase = nil;
			}
			
			mainMapDatabase = [[FMDatabase alloc] initWithPath:[Props global].mapDatabaseLocation];
			if (![mainMapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.removeOfflineMaps - Can't open main map tile database");
            
            NSDate *date = [NSDate date];
            NSString *query = [NSString stringWithFormat:@"UPDATE tiles SET image = NULL WHERE tilekey IN (%@) AND downloaded = %i", tiles_to_delete, guideId];
            NSString *query2 = [NSString stringWithFormat:@"UPDATE tiles SET downloaded = NULL WHERE tilekey IN (%@) AND downloaded = %i", tiles_to_delete, guideId];
            
            //NSLog(@"Query 1 = %@, query 2 = %@", query, query2);
            
            [mainMapDatabase executeUpdate:@"BEGIN TRANSACTION"];
            [mainMapDatabase executeUpdate:query];
            [mainMapDatabase executeUpdate:query2];
            //if(sqlite3_exec(mainMapDatabase, "VACUUM;", 0, 0, NULL)==SQLITE_OK) {NSLog(@"Vacuumed DataBase");}
            [mainMapDatabase executeUpdate:@"END TRANSACTION"];
            [mainMapDatabase executeUpdate:@"VACUUM"];
            
            float syncTime = -[date timeIntervalSinceNow];
            
            NSLog(@"GUIDEDOWNLOADER.removeOfflineMaps: Took %0.4f seconds to remove tiles", -[date timeIntervalSinceNow]);
            
            if (syncTime > 0.2) {
                NSLog(@"****WARNING GUIDEDOWNLOADER.removeOfflineMaps - took %f seconds in sync", syncTime);
            }
			
			[mainMapDatabase close];
			mainMapDatabase = nil;
        }
        
        /*
        //Check to see if correct amount was deleted 
        int downloadedTiles = 0;
        @synchronized ([Props global].mapDbSync) {
            
            FMResultSet *rs2 = [mainMapDatabase executeQuery:@"SELECT COUNT(*) as theCount FROM tiles WHERE downloaded = 1"];
            
            if ([rs2 next]) downloadedTiles = [rs2 intForColumn:@"theCount"];
            
            [rs2 close];
        }
        
        current_OfflineMapContentSize = downloadedTiles * kAverageMapTileSize;
        
        NSLog(@"Current offline map content size = %f and max offline tile size = %f", current_OfflineMapContentSize, max_OfflineMapContentSize);
*/
        
        current_OfflineMapContentSize = max_OfflineMapContentSize;
		
        stopped = TRUE;
        stopMapDownload = FALSE;
        removingMaps = FALSE;
        
        if (current_OfflineMapContentSize/total_OfflineMapContentSize < .8) [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:kOfflineMaps];
        
        [self postUpdateForKey:kOfflineMaps_Max_ContentSize]; //This updates the user defaults and posts a notification to update the display
    
    }
}


- (void) removeOfflineLinkFiles {
	
	NSString *offlineFileDirectory = [NSString stringWithFormat:@"%@/OfflineLinkFiles/", contentFolder];
	NSArray *offlineFileDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:offlineFileDirectory error:nil];
	
	for (NSString *file in offlineFileDirectoryContents){
		
		if (current_OfflineLinkFileContentSize < max_OfflineLinkFileContentSize) break;
		
		NSString *filePath = [NSString stringWithFormat:@"%@%@", offlineFileDirectory, file];
		NSLog(@"File to remove = %@", filePath);
		[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
		current_OfflineLinkFileContentSize -= kAverageOfflineLinkFileSize;
	}
	
	[self postUpdateForKey:kOfflineFiles];
}


- (void) removeAllContent {
    
    NSLog(@"GUIDEDOWNLOADER.removeAllContent: start");
    
	max_OfflineMapContentSize = 0;
	[self removeOfflineMaps];
	
    [guideDatabase close];
    [[NSFileManager defaultManager] removeItemAtPath:contentFolder error:nil];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, guideId]];
    
    NSString *photoKey = [NSString stringWithFormat:@"%@_%i", kOfflinePhotos, guideId];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:photoKey];
    
    NSString *thumbnailKeyString = [NSString stringWithFormat:@"%@_%i", kThumbnailsDownloaded, guideId];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:thumbnailKeyString];
    
    NSString *key = [NSString stringWithFormat:@"%@_%i", kOfflineFiles, guideId];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
	
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    

    
    NSLog(@"GUIDEDOWNLOADER.removeAllContent: complete");
}


- (void) stopDownloadsForTestApp {
    
    NSLog(@"GUIDEDOWNLOADER.stopDownloadForTestApp");
    
    shouldStop = TRUE;
    guideDatabase = nil;
}


- (void) logWithActionId:(int) actionId {
    
    SMLog *log = [[SMLog alloc] initWithPageID: kInAppPurchase actionID: actionId];
    log.entry_id = guideId;
    log.note = [NSString stringWithFormat:@"Content source = %@, total to download = %0.1f, current downloaded = %0.1f, currentTask = %@", contentSource, total_BaseContentSize, current_BaseContentSize, currentTask];
    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
}


#pragma mark
#pragma mark image manipulation

- (void) makeMapMarker:(NSNumber*) theIconId {
    
    @autoreleasepool {
        int iconId = [theIconId intValue];
        
        //Try to get map marker from server first
        
        NSString *urlString = [NSString stringWithFormat:@"http://www.sutroproject.com/content/%i/%i Static Content/images/%i-marker.png", guideId, guideId, iconId];
        
        NSString *theImagePath = [NSString stringWithFormat:@"%@/images/%i-marker.png",contentFolder , iconId];
        
        //Source for the data
        NSString *encodedURLString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSURL *dataURL = [[NSURL alloc] initWithString: encodedURLString];
        
        //Get the data
        NSData *theData = [[NSData alloc] initWithContentsOfURL:dataURL];
        
        UIImage *testImage = [UIImage imageWithData:theData];
        
        //Write the data to disk
        NSError * theError = nil;
        BOOL downloadSuccessful = FALSE;
        
        if(testImage.size.width > 0 && [theData writeToFile: theImagePath  options:NSAtomicWrite error:&theError]) downloadSuccessful = TRUE;
        
        
        //Clean up
        
        //[autoreleasepool drain];
        
        if (downloadSuccessful) return;
        
        UIImage *squareImage;
        
        /*if ([Props global].deviceShowsHighResIcons) {
         
         UIImage *bigIcon = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i.jpg",contentFolder , iconId]];
         
         if (bigIcon == nil) bigIcon = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_768.jpg",contentFolder , iconId]];
         
         if (bigIcon == nil) bigIcon = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i-icon.jpg",contentFolder , iconId]];
         
         squareImage = [[self cropImage:bigIcon] retain];
         
         [bigIcon release];
         }
         
         else squareImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i-icon.jpg",contentFolder , iconId]];*/
        
        UIImage *bigIcon = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_x100.jpg",contentFolder , iconId]];
        
        //if (bigIcon == nil) NSLog(@"************** WARNING - GUIDEDOWNLOADER.requestFinished: missing icon thumbnail for %i", iconId);
        
        if (bigIcon == nil) bigIcon = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i.jpg",contentFolder , iconId]];
        
        if (bigIcon == nil) bigIcon = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_768.jpg",contentFolder , iconId]];
        
        if (bigIcon == nil) bigIcon = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i-icon.jpg",contentFolder , iconId]];
        
        squareImage = [self cropImage:bigIcon];
        
        
        if (squareImage != nil) {
            
            float scaledWidth = 70;
            float imageWidth = 58;
            CGRect imageRect = CGRectMake((scaledWidth - imageWidth)/2, (scaledWidth - imageWidth)/2 - 4, imageWidth, imageWidth); //used for making map markers
            
            UIImage *background2 = [UIImage imageNamed:@"Marker_background4.png"];
            
            float scaledHeight = background2.size.height * (scaledWidth/background2.size.width);
            
            CGSize backgroundSize = CGSizeMake(scaledWidth, scaledHeight);
            
            UIGraphicsBeginImageContext(backgroundSize);
            [squareImage drawInRect:imageRect];
            [background2 drawAtPoint:CGPointZero];
            
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(newImage)];
            
            if(![imageData writeToFile:theImagePath atomically:YES])
                NSLog(@"GUIDEDOWNLOADER.makeMapMarker: getFileWithName() failed to write file to %@", theImagePath);
            
            else NSLog(@"GUIDEDOWNLOADER.makeMapMarker: wrote marker to %@", theImagePath);
        }
    }
}


- (UIImage*) cropImage:(UIImage*) image {
	
	float imageX, imageY;
	float scaledWidth, scaledHeight;
	float imageWidth = 100;
	
	//landscape
	if (image.size.width > image.size.height) {
		imageY  = 0;
		imageX = (image.size.height - image.size.width)/2 * (imageWidth/image.size.height);
		scaledWidth = image.size.width * (imageWidth/image.size.height);
		scaledHeight = imageWidth;
	}
	
	//Portrait
	else {
		imageX = 0;
		imageY = (image.size.width - image.size.height)/2 * (imageWidth/image.size.width);
		scaledWidth = imageWidth;
		scaledHeight = image.size.height * (imageWidth/image.size.width);
	}
	
	UIGraphicsBeginImageContext(CGSizeMake(imageWidth, imageWidth));
	
	[image drawInRect:CGRectMake(imageX, imageY, scaledWidth, scaledHeight)];
	
	UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    //[image release];
	
	return thumbnail;
}

/*
- (float) fileSize:(NSString*) filePath {
    
    float fileSize;
    
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:YES];
    fileSize = (float)[fileDictionary fileSize]/(1024.0 * 1024.0);
    
    return fileSize;
}


- (float)folderSize:(NSString *)folderPath { //returns folder size in MB
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    float folderSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] fileAttributesAtPath:[folderPath stringByAppendingPathComponent:fileName] traverseLink:YES];
        folderSize += (float)[fileDictionary fileSize]/(1024.0 * 1024.0);
    }
    
    return folderSize;
}
 
 
 - (float) estimateTotalMBDownloaded {
 
 float currentMBDownloaded = 0;
 
 //Estimate size of big photos
 NSString * query = @"SELECT COUNT(rowid) as theCount FROM photos WHERE downloaded_320px_photo > 0 OR downloaded_768_photo > 0";
 int numberOfPhotos = 0;
 
 @synchronized ([Props global].dbSync) {
 FMResultSet *rs = [guideDatabase executeQuery:query];
 
 if ([rs next]) numberOfPhotos = [rs intForColumn:@"theCount"];
 
 [rs close];
 }
 
 currentMBDownloaded += numberOfPhotos * ([Props global].deviceType == kiPad ? kAverageiPadImageSize : kAverageiPhoneImageSize);
 
 //Estimate size of map tiles
 
 NSString *theFilePath= [NSString stringWithFormat:@"%@/offline-map-tiles.sqlite3", contentFolder];
 FMDatabase *mapDatabase = [[FMDatabase alloc] initWithPath:theFilePath];
 
 if (![mapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.getTotalContentSize - Can't open map tile database");
 
 query = @"SELECT COUNT(*) as THECOUNT FROM tiles";
 
 FMResultSet *rs = [mapDatabase executeQuery:query];
 
 int numberOfMapTiles = 0;
 
 if ([rs next]) numberOfMapTiles = [rs intForColumn:@"theCount"];
 
 [rs close];
 
 [mapDatabase close];
 [mapDatabase release];
 
 
 FMDatabase *mainMapDatabase = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/offline-map-tiles.sqlite3", [Props global].documentsFolder]];
 
 if (![mainMapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.postUpdate - Can't open map tile database");
 
 int numberOfMapTilesNotYetCompleted = 0;
 
 @synchronized([Props global].dbSync){
 //NSLog(@"GUIDEDOWNLOADER - thread lock 1 for %i", guideId);
 NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) as THECOUNT FROM tiles WHERE image != %i", guideId];
 
 FMResultSet *rs = [mainMapDatabase executeQuery:query];
 
 if ([rs next]) numberOfMapTilesNotYetCompleted = [rs intForColumn:@"theCount"];
 
 [rs close];
 
 //NSLog(@"GUIDEDOWNLOADER - thread lock 1 for %i release", guideId);
 }
 
 [mainMapDatabase close];
 [mainMapDatabase release];
 
 int numberOfMapTilesCompleted = numberOfMapTiles - numberOfMapTilesNotYetCompleted;
 
 currentMBDownloaded += numberOfMapTilesCompleted * kAverageMapTileSize;
 
 NSLog(@"GUIDEDOWNLOADER.postUpdate: for guide %i completes DB operation", guideId);
 
 return currentMBDownloaded;
 }

 
 */

@end
