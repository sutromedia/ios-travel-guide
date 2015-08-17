//
//  DataDownloader.m
//  TravelGuideSF
//
//  Created by Tobin1 on 8/10/09.
//  Copyright 2009 Sutro Media. All rights reserved.
//

#import "DataDownloader.h"
#import "Constants.h"
#import "EntryCollection.h"
#import "Entry.h"
#import "Props.h"
#import	"ActivityLogger.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "Reachability.h"
#import "ZipArchive.h"
#include <sys/sysctl.h>  
#include <mach/mach.h>
#include <sys/time.h>
#import "ASIHTTPRequest.h"
#import "Deal.h"
#import "GuideDownloader.h"
#import <QuartzCore/QuartzCore.h>

#define kSmallImageType @"small image type"
#define kDealImageType  @"deal image type"
#define kMovedImagesToCachesFolder @"moved images to caches"


@interface DataDownloader (PrivateMethods)

- (void) downloadPitches;
- (void) showWiFiAlert;
- (BOOL) shouldShowWiFiAlert;
- (void) downloadAudioData;
- (void) downloadDataForEntry;
- (void) setEntryForDownload: (Entry*) entry withImageArray:(NSMutableArray*) theImageArray;
- (void) downloadImagesForImageArray:(NSMutableArray*) tmpImageArray;
- (void) downloadPitchIcons:(BOOL) forSutroWorld;
- (void) downloadLatestSutroWorldDatabase;
- (void) downloadSutroWorldSmallIcons;
- (void) downloadSutroWorldBigIcons;
- (void) downloadSutroWorldImages;
- (BOOL) checkForHigherPriorityStuff;
- (void) getLowPrioritySutroWorldContent;
- (void) getHighPrioritySutroWorldContent;
- (void) getLowPriorityTestAppContent;
- (void) downloadComments: (BOOL) getCommentForSutroWorld;
- (void) waitForNeedingSomething;
//- (NSMutableArray*) createImageArray;
- (void) print_free_memory;
- (BOOL) getFileWithURLString:(NSString*) urlString andFilePath:(NSString*)theFilePath;
- (void) updatePhotoStatuses;
- (void) downloadSmallImages;
- (void) updateDBWithGroupedThumbnailFiles;
- (void) downloadDeals;
- (void) moveOldImagesFolder;
//- (void) updateOfflineMaps;
//- (void) updateOfflinePhotos;

@end


@implementation DataDownloader

@synthesize entry, downloadCounter, initialized;


- (id) init {
    self = [super init];
    
    if (self) {
        
        if ([Props global].appID != 1) imageSource = ([Props global].deviceType == kiPad) ? @"http://www.sutromedia.com/published/ipad-sized-photos" : @"http://www.sutromedia.com/published/480-sized-photos";
        
        else imageSource = @"http://pub1.sutromedia.com/published/dynamic-photos/height/100";
    }
    
    return self;
}


- (void) initializeDownloader {
	
	NSLog(@"Downloader.initializeDownloader");
	
    [NSThread setThreadPriority:0.0];
    
    // initialize variables
    //downloader = nil;
    entryNeedsDownload = FALSE;
    entryBeingDownloaded = FALSE;
    doneDownloadingImageData = FALSE;
    paused = FALSE;
    pauseCount = 0;
    downloadComplete = FALSE;
    alertShown = FALSE;
    littleAppIconsDownloaded = FALSE;
    bigAppIconsDownloaded = FALSE;	
    sutroImagesDownloaded = FALSE;
    sutroCommentsDownloaded = FALSE;
    sutroPitchIconsDownloaded = FALSE;
    workingOnSutroDownloads = FALSE;
    doneSutroDownloads = FALSE;
    workingOnTestAppDownloads = FALSE;
    prioritizingSutroDownloads = FALSE;
    appImagesDownloaded = FALSE;
    groupedThumbnailsForUpdate = nil;
    [Props global].killDataDownloader = FALSE;
    
    downloadCounter = 0;
    sutroDownloadCounter = 0;
    concurrentRequests = 0;
    
    /*if (guideDownloaders == nil) {
        guideDownloaders = [NSMutableDictionary new];
    }
    
    if ([guideDownloaders objectForKey:[NSNumber numberWithInt:[Props global].appID]] == nil) {
        GuideDownloader *guideDownloader = [[GuideDownloader alloc] initWithGuideId:[Props global].appID];
        [guideDownloaders setObject:guideDownloader forKey:[NSNumber numberWithInt:[Props global].appID]];
    }
    
    
    NSString *offlineMapsNotificationName = [NSString stringWithFormat:@"%@_%i", kOfflineMaps, [Props global].appID];
    NSLog(@"DATADOWNLOADER.initializeDownloader: notification name = %@", offlineMapsNotificationName);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOfflineMaps) name:offlineMapsNotificationName object:nil];
    NSString *offlinePhotosNotificationName = [NSString stringWithFormat:@"%@_%i", kOfflinePhotos, [Props global].appID];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOfflinePhotos) name:offlinePhotosNotificationName object:nil];
     */
    
    //This is used for downloading of photos and offline maps from settings. We use a separate object to avoid dupicating code used in Sutro World.
    if (![Props global].isShellApp) downloader = [[GuideDownloader alloc] initWithGuideId:[Props global].appID];
    
    
    //if ([Props global].appID != 1) self.imageNameArray = [self createImageArray];
    
    //NSLog(@"DATADOWNLOADER.initializeDownloader: TURNED OFF");
    
    //check to see if content folder is there and create it if not
    if(![[NSFileManager defaultManager] isWritableFileAtPath:[Props global].contentFolder]) [[NSFileManager defaultManager] createDirectoryAtPath: [Props global].contentFolder withIntermediateDirectories:YES attributes: nil error:nil ];
    
    [Props global].dataDownloaderShouldCheckForUpdates = TRUE;
	
	initialized = TRUE;
    
    if (!waitLoopInitialized) [self waitForNeedingSomething];
}


- (void) waitForNeedingSomething {
    
    NSLog(@"DATADOWNLOADER.waitForNeedingSomething - getting app updates");
	waitLoopInitialized = TRUE;
    
	while(TRUE){
		
        while ([Props global].killDataDownloader) [NSThread sleepForTimeInterval: 2];
        
		//if ([Props global].downloadTestAppContent) [self getLowPriorityTestAppContent];
        
        //NSLog(@"DATADOWNLOADER.waitForNeedingSomething: downloadTestAppContent = %@", [Props global].downloadTestAppContent ? @"TRUE" : @"FALSE");
		
		if ([Props global].dataDownloaderShouldCheckForUpdates) {
			
			NSLog(@"DOWNLOADER.waitforNeedingSomething: Getting app updates for %@ app", [Props global].isShellApp ? @"shell" : @"non-shell");
			
			//Get latest comments and pitches
            if ([Props global].hasDeals && ![self checkForHigherPriorityStuff]) [self downloadDeals];
            if ([Props global].showComments && ![self checkForHigherPriorityStuff]) [self downloadComments:FALSE]; 
			if (![self checkForHigherPriorityStuff] && [Props global].appID != 1) [self downloadPitches];
            
            
            //[self moveOldImagesFolder];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kMovedImagesToCachesFolder]) [self moveOldImagesFolder];
            
            //Moved this to happen from guide downloader method
			//NSString *thumbnailKeyString = [NSString stringWithFormat:@"%@_%i", kThumbnailsDownloaded, [Props global].appID];
            //if (![[NSUserDefaults standardUserDefaults] boolForKey:thumbnailKeyString] && [Props global].appID != 1) [self downloadSmallImages];
            
           			
            sutroImagesDownloaded = FALSE;
			sutroCommentsDownloaded = FALSE;
			sutroPitchIconsDownloaded = FALSE;
			workingOnSutroDownloads = TRUE;
			doneSutroDownloads = FALSE;
			
            
			//if (![Props global].isShellApp) [self getHighPrioritySutroWorldContent];
			//if (!appImagesDownloaded && [Props global].appID != 1) [self downloadImagesForImageArray: self.imageNameArray]; //don't download entire image array for Sutro World
			appImagesDownloaded = TRUE;
			//if (![Props global].isShellApp)[self getLowPrioritySutroWorldContent];
			
			workingOnSutroDownloads = FALSE;
			doneSutroDownloads = TRUE;
			
			[Props global].dataDownloaderShouldCheckForUpdates = FALSE;
			
			NSLog(@"DOWNLOADER.waitforNeedingSomething: Done with updates. Will wait around for needing something new.");
		}
		
        [self checkForHigherPriorityStuff];
        
		[NSThread sleepForTimeInterval: 0.2];
	}
}


- (void) updatePhotoStatuses {
	
	//NSLog(@"DOWNLOADER.updatePhotoStatuses: called");
	
	@synchronized([Props global].dbSync) {
		
		NSMutableString *downloadedPhotoList = [[NSMutableString alloc] initWithCapacity:10000];
		NSString *query = ([Props global].deviceType == kiPad) ? @"SELECT rowid from photos WHERE downloaded_768px_photo is null": @"SELECT rowid from photos WHERE downloaded_320px_photo is null";
		
		FMDatabase * db = [EntryCollection sharedContentDatabase];
		FMResultSet * rs = [db executeQuery:query];
		
		if ([db hadError]) NSLog(@"sqlite error in [DataDownloader createImageArray], query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
		
		if (![rs next]) NSLog(@"DOWNLOADER.updatePhotoStatuses - no rows in result set");
		
		while ([rs next]) {
			
			NSString *fileName = [NSString stringWithFormat:@"%i", [rs intForColumn:@"rowid"]];
			NSString *theFilePath = ([Props global].deviceType == kiPad) ? [[NSString alloc] initWithFormat:@"%@/images/%@_768.jpg", [Props global].contentFolder, fileName] : [[NSString alloc] initWithFormat:@"%@/images/%@.jpg", [Props global].contentFolder, fileName];
			
			//NSLog(@"About to look for file at %@", theFilePath);
			
			if([[NSFileManager defaultManager] fileExistsAtPath: theFilePath] || [[NSFileManager defaultManager] fileExistsAtPath: [[NSBundle mainBundle] pathForResource:fileName ofType:@"jpg"]]) 
				[downloadedPhotoList appendString:[NSString stringWithFormat:@"%@,", fileName]];
            
            //[theFilePath release];
		}
		
		[rs close];
		
		//NSLog(@"DATADOWNLOADER.updatePhotoStatuses: Downloaded photos ids has about %i objects", [downloadedPhotoList length]/7);
		
		if ([downloadedPhotoList length] > 0) {
			
			//NSLog(@"DOWNLOADER.updatePhotoStuatuses: updating datebase for %i new photos", [downloadedPhotoList length]/7);
			
			[downloadedPhotoList deleteCharactersInRange:NSMakeRange([downloadedPhotoList length] - 1, 1)];
			
			//NSLog(@"Downloaded photo list = %@", downloadedPhotoList);
			
			query = ([Props global].deviceType == kiPad) ? [NSString stringWithFormat:@"UPDATE photos SET downloaded_768px_photo = 1 WHERE rowid IN (%@)", downloadedPhotoList] : [NSString stringWithFormat:@"UPDATE photos SET downloaded_320px_photo = 1 WHERE rowid IN (%@)", downloadedPhotoList];
			
			//NSLog(@"Query = %@", query);
			[db executeUpdate:@"BEGIN TRANSACTION"];
			[db executeUpdate:query];
			[db executeUpdate:@"END TRANSACTION"];
		}
		//[downloadedPhotoList release];
	}
	
	//NSLog(@"DOWNLOADER.updatePhotoStatuses: completes");
}


- (BOOL) checkForHigherPriorityStuff {
	
    if ([Props global].killDataDownloader) {
        NSLog(@"About to kill downloader");
        return TRUE;
    }
    
    while(paused){
		//NSLog(@"DOWNLOADER.checkForHigherPriorityStuff: PAUSED");
		[NSThread sleepForTimeInterval: 1];
	}
	
	while(![Props global].connectedToInternet){
		
		[NSThread sleepForTimeInterval: 1];
	}
	
	if(entryNeedsDownload && (self.entry != nil) && !entryBeingDownloaded) [self downloadDataForEntry];
	
	//if ([Props global].downloadTestAppContent && !workingOnTestAppDownloads) [self getLowPriorityTestAppContent];
	
	else if (![Props global].inTestAppMode && workingOnTestAppDownloads) return TRUE;
	
	/*if ([Props global].appID == 0 && !(workingOnSutroDownloads || doneSutroDownloads)){
		prioritizingSutroDownloads = TRUE;
		[self getHighPrioritySutroWorldContent];
		[self getLowPrioritySutroWorldContent];
		prioritizingSutroDownloads = FALSE;
	}
	
	//resume regular downloads after leaving sutro world
	if ([Props global].appID != 0 && prioritizingSutroDownloads) {
		prioritizingSutroDownloads = FALSE;
		return TRUE;
	}*/
	
	return FALSE;
}


- (void) downloadDeals {
	
    NSLog(@"DATADOWNLOADER.downloadDeals");
    NSDate *date = [NSDate date];
    
	if ([self checkForHigherPriorityStuff]) return;
	
    @autoreleasepool {
        NSString *theFolderPath = [NSString stringWithFormat:@"%@/images", [Props global].contentFolder];
        
        //check to see if images folder is there and create it if not
        if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath]) [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ];
        
        //****DOWNLOAD DEALS******
        [[NSURLCache sharedURLCache] setMemoryCapacity:0];
        //[[NSURLCache sharedURLCache] setDiskCapacity:0]; 
        NSString *theFilePath = [NSString stringWithFormat:@"%@/deals.sqlite3", [Props global].contentFolder];
        
        NSString *urlString = [[NSString stringWithFormat: @"http://www.sutromedia.com/published/deals/%i.sqlite3", [Props global].appID] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *dataURL = [NSURL URLWithString: urlString];
        
        //Get the data
        NSData *dealsData = [[NSData alloc] initWithContentsOfURL:dataURL];
        
        //Write the data to disk
        NSError * theError = nil;
        
        if([dealsData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE)
            NSLog(@"DATADOWNLOADER, downloadDeals: failed to write file to %@, error = %@, userInfo = %@", theFilePath, theError, [theError userInfo]);
        
        //Clean up
        //[dealsData release];
        
        //Open database
        NSString *dbFilePath = [Props global].isShellApp ? [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].contentFolder]:[NSString stringWithFormat:@"%@/content.sqlite3", [Props global].cacheFolder];
        
        NSMutableArray *dealIcons = [NSMutableArray new];
        
        //Add deal updates to the main database
        @synchronized([Props global].dbSync) {
            
            FMDatabase *db = [[FMDatabase alloc] initWithPath:dbFilePath];
            if (![db open]) NSLog(@"DOWNLOADER - Could not open sqlite database from file = %@", dbFilePath);
            
            [db executeUpdate:@"BEGIN TRANSACTION"];
            
            //delete old deals from primary database
            [db executeUpdate:@"DELETE FROM deals"];
            
            [db executeUpdate:@"DELETE FROM entry_deals"];
            
            //Merge primary database with updates
            FMDatabase *dealsDatabase = [[FMDatabase alloc] initWithPath:theFilePath];
            
            if (![dealsDatabase open]) NSLog(@"DOWNLOADER - Could not open deals database from file = %@", theFilePath);
            
            FMResultSet *rs = [dealsDatabase executeQuery:@"SELECT *,rowid FROM deals"];
            
            if ([dealsDatabase hadError]) NSLog(@"DOWNLOADER - Err %d: %@", [dealsDatabase lastErrorCode], [dealsDatabase lastErrorMessage]);
            
            while ([rs next]) {
                //NSAutoreleasePool *pool = [NSAutoreleasePool new];
                [db executeUpdate:@"INSERT INTO deals (rowid, title, short_title, description, image_url, price, value, discount, expiration, merchant_name, url) VALUES (?, ?, ?, ? ,?, ?, ?, ?, ?, ?, ?)", [NSNumber numberWithInt:[rs intForColumn:@"rowid"]], [rs stringForColumn:@"title"], [rs stringForColumn:@"short_title"], [rs stringForColumn:@"description"], [rs stringForColumn:@"image_url"], [NSNumber numberWithFloat:[rs doubleForColumn:@"price"]], [NSNumber numberWithFloat:[rs doubleForColumn:@"value"]], [NSNumber numberWithFloat:[rs doubleForColumn:@"discount"]], [rs stringForColumn:@"expiration"], [rs stringForColumn:@"merchant_name"], [rs stringForColumn:@"url"]];
                
                Deal *deal = [[Deal alloc] init];
                deal.rowid = [rs intForColumn:@"rowid"];
                deal.imageData = [rs dataForColumn:@"image_data"];
                //[deal createDealImageWithData: [rs dataForColumn:@"image_data"]];
                //deal.imageURL = [rs stringForColumn:@"image_url"];
                
                [dealIcons addObject:deal];
                //[deal release];
                
                //[pool release];
            }
            
            [rs close];
            
            
            rs = [dealsDatabase executeQuery:@"SELECT * FROM entry_deals"];
            
            while ([rs next]) {
                
                [db executeUpdate:@"INSERT INTO entry_deals (dealid, entryid, entry_weight) VALUES (?, ?, ?)", [NSNumber numberWithInt:[rs intForColumn:@"dealid"]], [NSNumber numberWithInt:[rs intForColumn:@"entryid"]], [NSNumber numberWithFloat:[rs doubleForColumn:@"entry_weight"]]];
            }
            
            [db executeUpdate:@"END TRANSACTION"];
            
            [rs close];
            
            [dealsDatabase close];
            //[dealsDatabase release];
            
            [db close];
            //[db release];
        }
        
        //Download deal icons
        for (Deal *deal in dealIcons) {
            
            @autoreleasepool {
                [deal makeDealImage];
            }
        }
        
        [[NSURLCache sharedURLCache] setMemoryCapacity:(1024*1024)]; //should be 1 MB
        //[[NSURLCache sharedURLCache] setDiskCapacity:(1024*1024)]; //should be 1 MB
        
        NSLog(@"DATADOWNLOADER.downloadDeals: Took %0.2f seconds to download deals and create images", -[date timeIntervalSinceNow]);
    }
}


- (void) downloadComments: (BOOL) getCommentForSutroWorld {
	
	NSLog(@"DOWNLOADER - Downloading comments for %@", getCommentForSutroWorld ? @"Sutro World":@"Main app");
	
	@autoreleasepool {
        //****DOWNLOAD PITCHES******
        [[NSURLCache sharedURLCache] setMemoryCapacity:0];
        [[NSURLCache sharedURLCache] setDiskCapacity:0]; 
        
        
        //****DOWNLOAD COMMENTS AND SET DATABASE******
        NSString *theFilePath = nil;
        NSString *urlString = nil; 
        FMDatabase *db = nil;
        NSString *dbFilePath = nil;
        int latestCommentsVersion = 0;
        int currentCommentsVersion = 0;
        
        //If we're in the main app and want to update the comments for that app, update the singleton database
        if (!getCommentForSutroWorld) {
            theFilePath = [NSString stringWithFormat:@"%@/comments.sqlite3", [Props global].contentFolder];
            
            if ([Props global].appID == 1) {
                urlString = [@"http://www.sutromedia.com/published/comments/0.sqlite3" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                dbFilePath = [Props global].isShellApp ? [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].cacheFolder] : [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].contentFolder];
                NSLog(@"DB File Path = %@", dbFilePath);
            }
            
            else {
                urlString = [[NSString stringWithFormat: @"http://www.sutromedia.com/published/comments/%i.sqlite3", [Props global].appID] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                dbFilePath = [Props global].isShellApp || [Props global].inTestAppMode ? [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].contentFolder] : [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].cacheFolder];
            }
        }
        
        //If we're in the main app and want to update the comments for the sutro world app, then update the file
        else {
            theFilePath = [NSString stringWithFormat:@"%@/0/comments.sqlite3", [Props global].cacheFolder];
            urlString = [[NSString stringWithFormat: @"http://www.sutromedia.com/published/comments/0.sqlite3"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            dbFilePath = [NSString stringWithFormat:@"%@/0.sqlite3", [Props global].cacheFolder];
        }
        
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.sutromedia.com/published/comments/%i-commentversion.txt", [Props global].appID]];
        NSError* error;
        latestCommentsVersion = [[NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error] intValue];
        
        //Check the latest comments version that we have, assuming that we have a recent enough DB to do this
        db = [[FMDatabase alloc] initWithPath:dbFilePath];
        if (![db open]) NSLog(@"DOWNLOADER - Could not open sqlite database from file = %@", dbFilePath);
        
        @synchronized([Props global].dbSync) {
            
            FMResultSet *rs = [db executeQuery:@"SELECT value FROM app_properties WHERE key = 'comment_version'"];
            
            if ([rs next]) currentCommentsVersion = [rs intForColumn:@"value"];
            
            [rs close];
        }
        
        NSLog(@"Current comment version = %i and latest version = %i", currentCommentsVersion, latestCommentsVersion);
        
        //Call it quits if we have the latest version of the comments
        if (currentCommentsVersion >= latestCommentsVersion){
            NSLog(@"DD.downloadComments: Comments are up to date, exiting comment downloader");
            [db close];
            return; 
        }
        
        
        if (urlString != nil) {
            NSURL *dataURL = [NSURL URLWithString: urlString];
            
            //Get the data
            NSData *commentsData = [[NSData alloc] initWithContentsOfURL:dataURL]; //TF - Crash on this line 102811
            
            //Write the data to disk
            NSError * theError = nil;
            
            if([commentsData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) {
                NSLog(@"DATADOWNLOADER, downloadComments: [Props global].leftMargin file to %@, error = %@, userInfo = %@", theFilePath, theError, [theError userInfo]);
            }
        }
        
        
        // ************ Merge primary database with updates *******************
        NSDate *date = [NSDate date];
        
        FMDatabase *tempCommentsDatabase = [[FMDatabase alloc] initWithPath:theFilePath];
        
        if (![tempCommentsDatabase open]) NSLog(@"DOWNLOADER - Could not open sqlite database from file = %@", theFilePath);
        
        NSString *query = [NSString stringWithFormat:@"SELECT *,rowid FROM comments WHERE version > %i", currentCommentsVersion];
		
		NSLog(@"DD.downloadComments: query = %@", query);
		
        FMResultSet *rs = [tempCommentsDatabase executeQuery:query];
        
        if ([tempCommentsDatabase hadError]) {
            NSLog(@"DOWNLOADER - Error opening temp comments database from %@", theFilePath);
            
            NSLog(@"DOWNLOADER - Err %d: %@", [tempCommentsDatabase lastErrorCode], [tempCommentsDatabase lastErrorMessage]);
            
            [db close];
            [tempCommentsDatabase close];
            
            return;
        }
        
        /*while ([rs next]) {
            
            @synchronized([Props global].dbSync) {
                
                NSDate *date = [NSDate date];
                
                [db executeUpdate:@"BEGIN TRANSACTION"];
                [db executeUpdate:@"INSERT OR REPLACE INTO comments (rowid, entryid, subentry_name, created, commenter_alias, comment, response_date, response, responder_name) VALUES (?, ?, ?, ? ,? ,?, ?, ?, ?)", [NSNumber numberWithInt:[rs intForColumn:@"rowid"]], [NSNumber numberWithInt:[rs intForColumn:@"entryid"]], [rs stringForColumn:@"subentry_name"], [rs stringForColumn:@"created"],  [rs stringForColumn:@"commenter_alias"], [rs stringForColumn:@"comment"], [rs stringForColumn:@"response_date"], [rs stringForColumn:@"response"], [rs stringForColumn:@"responder_name"]];
                [db executeUpdate:@"END TRANSACTION"];
                
                float timeInSync = -[date timeIntervalSinceNow];
                
                if (timeInSync > 0.5) {
                    NSLog(@"************* WARNING: DATADOWNLOADER.downloadComments: time in sync = %0.2f seconds", timeInSync);
                }
            }
            
            [NSThread sleepForTimeInterval:0.002];
        }*/
		
		 @synchronized([Props global].dbSync) {
		
			 NSDate *date = [NSDate date];
			 
			 [db executeUpdate:@"BEGIN TRANSACTION"];
			 
			 while ([rs next]) {
				 
				 [db executeUpdate:@"INSERT OR REPLACE INTO comments (rowid, entryid, subentry_name, created, commenter_alias, comment, response_date, response, responder_name) VALUES (?, ?, ?, ? ,? ,?, ?, ?, ?)", [NSNumber numberWithInt:[rs intForColumn:@"rowid"]], [NSNumber numberWithInt:[rs intForColumn:@"entryid"]], [rs stringForColumn:@"subentry_name"], [rs stringForColumn:@"created"],  [rs stringForColumn:@"commenter_alias"], [rs stringForColumn:@"comment"], [rs stringForColumn:@"response_date"], [rs stringForColumn:@"response"], [rs stringForColumn:@"responder_name"]];
			 }
		
			 [db executeUpdate:@"END TRANSACTION"];
			 
			 float timeInSync = -[date timeIntervalSinceNow];
			 
			 if (timeInSync > 0.5) {
				 NSLog(@"************* WARNING: DATADOWNLOADER.downloadComments: time in sync = %0.2f seconds", timeInSync);
			 }
        }
        
		
        [rs close];
        
        
        // ***** Delete any comments that were deleted in the update *******
        
        rs = [tempCommentsDatabase executeQuery:@"SELECT rowid FROM comments ORDER BY rowid DESC LIMIT 500"];
        NSMutableString *earlierComments = [NSMutableString stringWithString:@""];
        int rowid = 0; //We use this variable to save the last row id, which should be the smallest
        
        while ([rs next]) {
            rowid = [rs intForColumn:@"rowid"];
            [earlierComments appendFormat:@"%i,", rowid];
        }
        
        if ([earlierComments length] > 2)[earlierComments deleteCharactersInRange:NSMakeRange([earlierComments length] -1, 1)]; //delete the last comma
         
        @synchronized([Props global].dbSync) {
            NSDate *date = [NSDate date];
            NSString *query = [NSString stringWithFormat:@"DELETE FROM COMMENTS WHERE rowid NOT IN (%@) AND rowid >= %i", earlierComments, rowid];             
            NSLog(@"DD.downloadComments: Query = %@", query);
            
            [db executeUpdate:@"BEGIN TRANSACTION"];
            [db executeUpdate:query];
            [db executeUpdate:@"END TRANSACTION"];
            
            NSLog(@"DD.downloadComments: took %0.2f seconds to delete comments", -[date timeIntervalSinceNow]);
        }
        
        [tempCommentsDatabase close];
        
        @synchronized([Props global].dbSync) {
            
            NSString *query = [NSString stringWithFormat:@"UPDATE app_properties SET value = %i WHERE key = 'comment_version'", latestCommentsVersion];
            
            [db executeUpdate:@"BEGIN TRANSACTION"];
            [db executeUpdate:query];
            [db executeUpdate:@"END TRANSACTION"];
        }
        
        [db close];
        
        NSLog(@"DATADOWNLOADER.downloadComments: Took %0.1f seconds to merge comments databases", -[date timeIntervalSinceNow]);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshComments object:nil];
		
        
        [[NSURLCache sharedURLCache] setMemoryCapacity:(1024*1024)]; //should be 1 MB
        [[NSURLCache sharedURLCache] setDiskCapacity:(1024*1024)]; //should be 1 MB	
    }
}
	

- (void) downloadPitches {
	
	if ([self checkForHigherPriorityStuff]) return;
	 
    @autoreleasepool {
	
         //****DOWNLOAD PITCHES******
         [[NSURLCache sharedURLCache] setMemoryCapacity:0];
         [[NSURLCache sharedURLCache] setDiskCapacity:0]; 
         NSString *theFilePath = [NSString stringWithFormat:@"%@/pitches.sqlite3", [Props global].contentFolder];
         
         NSString *urlString = [[NSString stringWithFormat: @"http://www.sutromedia.com/published/pitches/%i.sqlite3", [Props global].appID] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
         NSURL *dataURL = [NSURL URLWithString: urlString];
         
         //Get the data
         NSData *pitchesData = [[NSData alloc] initWithContentsOfURL:dataURL];
         
         //Write the data to disk
         NSError * theError = nil;
         
         if([pitchesData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE)
             NSLog(@"DATADOWNLOADER, downloadPitches: failed to write file to %@, error = %@, userInfo = %@", theFilePath, theError, [theError userInfo]);
         
         //Clean up
         //[pitchesData release];
         
         //Open database
         NSString *dbFilePath = [Props global].isShellApp ? [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].contentFolder]:[NSString stringWithFormat:@"%@/content.sqlite3", [Props global].cacheFolder];
         
         //Add pitch updates to the main database
         @synchronized([Props global].dbSync) {
             //NSLog(@"DOWNLOADER.downloadPitches:lock");
             
             FMDatabase *db = [[FMDatabase alloc] initWithPath:dbFilePath];
             if (![db open]) NSLog(@"DOWNLOADER - Could not open sqlite database from file = %@", dbFilePath);
             
             [db executeUpdate:@"BEGIN TRANSACTION"];
             //[[EntryCollection sharedContentDatabase] executeUpdate:@"PRAGMA synchronous=OFF"];
             
             
             //delete old comments from primary database
             [db executeUpdate:@"DELETE FROM pitches"];
             
             //Merge primary database with updates
             FMDatabase *tempPitchesDatabase = [[FMDatabase alloc] initWithPath:theFilePath];
             
             if (![tempPitchesDatabase open]) NSLog(@"DOWNLOADER - Could not open sqlite database from file = %@", theFilePath);
             
             FMResultSet *rs = [tempPitchesDatabase executeQuery:@"SELECT *,rowid FROM pitches"];
             
             if ([tempPitchesDatabase hadError]) {
                 NSLog(@"DOWNLOADER - Error opening temp pitches database from %@", theFilePath);
                 
                 NSLog(@"DOWNLOADER - Err %d: %@", [tempPitchesDatabase lastErrorCode], [tempPitchesDatabase lastErrorMessage]);
             }
             
             while ([rs next]) {
                 
                 [db executeUpdate:@"INSERT INTO pitches (rowid, entryid, appid, author, linkshare_url, app_name) VALUES (?, ?, ?, ? ,?, ?)", [NSNumber numberWithInt:[rs intForColumn:@"rowid"]], [NSNumber numberWithInt:[rs intForColumn:@"entryid"]], [NSNumber numberWithInt:[rs intForColumn:@"appid"]],  [rs stringForColumn:@"author"], [rs stringForColumn:@"linkshare_url"], [rs stringForColumn:@"app_name"]];
             }
             
             [db executeUpdate:@"END TRANSACTION"];
             
             [rs close];
             
             [tempPitchesDatabase close];
             //[tempPitchesDatabase release];
             
             [db close];
         }
         
         [[NSURLCache sharedURLCache] setMemoryCapacity:(1024*1024)]; //should be 1 MB
         [[NSURLCache sharedURLCache] setDiskCapacity:(1024*1024)]; //should be 1 MB
         
     }
	
	//Work on downloading the pitch icons even if pitch database was not dowloaded, as there may be one from a previous session with icons that still need download
	[self downloadPitchIcons:FALSE];
}


- (void) downloadSmallImages {
    
	NSDate *date = [NSDate date];
    
    smallImageDownloadCounter = 0;
    //NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    //[queue setMaxConcurrentOperationCount:6];
    
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0]; 
    
    //Figure out how many images are already there for download counter
    @synchronized([Props global].dbSync) {
        
        //NSLog(@"GUIDEDOWNLOADER - db lock 4 for %i", guideId);
		NSString *query = [NSString stringWithFormat:@"SELECT MAX(downloaded_x100px_photo) AS theMax FROM photos"];
		FMResultSet * rs = [[EntryCollection sharedContentDatabase] executeQuery:query];
		
		if ([rs next]) smallImageDownloadCounter = [rs intForColumn:@"theMax"];
		[rs close];
	}
    
    //NSLog(@"DATADOWNLOADER.downloadSmallImages: download counter = %i", smallImageDownloadCounter);
	
    NSString *theFolderPath = [NSString stringWithFormat:@"%@/images", [Props global].contentFolder];
    
    //NSLog(@"DOWNLOADER.downloadSmallImages: Folder path = %@", theFolderPath);
	
	//check to see if images folder is there and create it if not
	if([[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath] || [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ]) {
        
        int downloadBatchSize = 100;
        int maxDownloadAmount = 2000;
        int lastBatchSize = downloadBatchSize;
        int totalDownloaded = 0;
        
        while (totalDownloaded < maxDownloadAmount && lastBatchSize == downloadBatchSize) {
            NSString * query = [Props global].appID == 1 ? @"SELECT demo_entries.icon_photo_id AS ID FROM demo_entries, photos WHERE photos.rowid = demo_entries.icon_photo_id AND photos.downloaded_x100px_photo is NULL" : @"SELECT DISTINCT rowid AS ID FROM photos WHERE photos.downloaded_x100px_photo is NULL";
            
            query = [query stringByAppendingString:[NSString stringWithFormat:@" LIMIT %i", downloadBatchSize]];
            
            //NSLog(@"DATADOWNLOADER.downloadSmallImages: Query = %@", query);
            
            NSMutableArray *photoIDs = [NSMutableArray new];
            
            @synchronized([Props global].dbSync){
                
                NSDate *date = [NSDate date];
                
                //NSLog(@"GUIDEDOWNLOADER - db lock 5 for %i", guideId);
                FMDatabase *db = [EntryCollection sharedContentDatabase];
                
                FMResultSet *rs = [db executeQuery:query];
                
                //NSLog(@"DATADOWNLOADER.downloadSmallImages: time up execute = %0.4f", -[date timeIntervalSinceNow]);
                
                while ([rs next]) {
                    //NSLog(@"DATADOWNLOADER.downloadSmallImages: in while loop time = %0.4f", -[date timeIntervalSinceNow]);
                    int photoID = [rs intForColumn:@"ID"];
                    [photoIDs addObject:[NSNumber numberWithInt:photoID]];
                }
                
                [rs close];
                
                float timeInSync = -[date timeIntervalSinceNow];
                
                if (timeInSync > 0.2) {
                    NSLog(@"******* WARNING: DATADOWNLOADER.downloadSmallImages: Time in sync = %0.2f", timeInSync);
                }
            }
            
            //NSLog(@"DataDownloader.downloadSmallImages: about to download %i small photos", [photoIDs count]);
            
            for(NSNumber *photoID in photoIDs) {
                
                @autoreleasepool {
                
                    if ([self checkForHigherPriorityStuff]) return;
                    [NSThread sleepForTimeInterval:0.005];
                    
                    //Source for the data
                    NSString *tempString = [[NSString alloc] initWithFormat: @"http://%@/published/dynamic-photos/height/100/%i.jpg",[Props global].serverContentSource, [photoID intValue]];
                    
                    NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];	
                    NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
                    
                    //NSLog(@"Concurrent requests = %i", concurrentRequests);
                    
                    while (concurrentRequests > kMaxConcurrentRequests) {
                        [NSThread sleepForTimeInterval:0.005];
                    }
                    
                    //Get the data
                    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:dataURL];
                    [request setDelegate:self];
                    
                    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:kSmallImageType, @"type", photoID , @"photo_id", nil];
                    request.info = info;
                    
                    //[queue addOperation:request];
                    [request startAsynchronous];
                    concurrentRequests ++;
                    //NSLog(@"Added object to queue");
                }
            }
            
            lastBatchSize = [photoIDs count];
            totalDownloaded += lastBatchSize;
            
            
            [self checkForHigherPriorityStuff];
            if ([Props global].commentsDatabaseNeedsUpdate) return;
            
            [NSThread sleepForTimeInterval: 0.10];
        }
    }
    
    int waitCounter = 0;
    while (concurrentRequests > 0 && waitCounter < 30) {
        [NSThread sleepForTimeInterval:1.0];
        waitCounter ++;
        NSLog(@"DATADOWNLOADER.downloadSmallImages: Waiting for last few requests");
    }
    //[queue waitUntilAllOperationsAreFinished];
     NSLog(@"DATADOWNLOADER.downloadSmallImages: Finished adding images");
    //[queue release];
    
    NSLog(@"DATADOWNLOADER.downloadSmallImages: took %0.0f seconds to download thumbnails", -[date timeIntervalSinceNow]);
    
    NSString *thumbnailKeyString = [NSString stringWithFormat:@"%@_%i", kThumbnailsDownloaded, [Props global].appID];
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:thumbnailKeyString];
}


- (void)requestFinished:(ASIHTTPRequest *)request {
    
    //NSLog(@"DATADOWNLOADER.requestFinished:");
    if ([Props global].killDataDownloader) return;
    
    NSDictionary *info = request.info;
    
    NSData *responseData = [request responseData];
    
    if ([[info objectForKey:@"type"]  isEqual: kSmallImageType]) {
        
        if (groupedThumbnailsForUpdate == nil) groupedThumbnailsForUpdate = [NSMutableArray new];
        
        NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder, [[info objectForKey:@"photo_id"] intValue]];
        
        //NSLog(@"The file path = %@", theFilePath);
        
        NSError *theError = nil;
        
        if([responseData writeToFile: theFilePath  options:NSDataWritingFileProtectionNone error:&theError]!= TRUE){
            NSLog(@"**** ERROR:DATADOWNLOADER.requestFinished: failed to write local file to %@, error = %@, userInfo = %@ *******************************************************************", theFilePath, theError, [theError userInfo]);
        }
        
        else {
            
            [groupedThumbnailsForUpdate addObject:[info objectForKey:@"photo_id"]];
            
            if ([groupedThumbnailsForUpdate count] > 20) [self updateDBWithGroupedThumbnailFiles];
        }
    }
    
    else if ([[info objectForKey:@"type"]  isEqual: kDealImageType]) {}
    
    else {
        NSLog(@"*******************ERROR - GUIDEDOWNLOADER.requestFinished: Type not found. Type = %@ ***************************", [info objectForKey:@"type"]);
        return;
    }
    
    concurrentRequests --;
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    concurrentRequests --;
    NSLog(@"DATADOWNLOADER.requestFailed: error = %@ for downloading image from %@", [[request error] description], [request.url absoluteString]);
    //NSError *error = [request error];
    
    /*NSDictionary *info = request.info;
    
    if ([info objectForKey:@"type"] == kDealImageType) {
        
        while (concurrentRequests > kMaxConcurrentRequests) {
            [NSThread sleepForTimeInterval:0.01];
        }
    
        NSString *imageURL = [[request.url absoluteString] stringByReplacingOccurrencesOfString:@"gigantic.png" withString:@"huge.png"];
        
        NSLog(@"About to look for smaller image at %@", imageURL);
        
        NSURL *dealURL = [NSURL URLWithString:imageURL];
        ASIHTTPRequest *_request = [ASIHTTPRequest requestWithURL:dealURL];
        [_request setDelegate:self];
        
        _request.info = info;
        [_request startAsynchronous];
        concurrentRequests ++;
    }*/
}


- (void) updateDBWithGroupedThumbnailFiles {
    
    @autoreleasepool {
    
        @synchronized([Props global].dbSync) {
            
            [[EntryCollection sharedContentDatabase] executeUpdate:@"BEGIN TRANSACTION"];
            
            for (NSNumber *photoID in groupedThumbnailsForUpdate) {
                smallImageDownloadCounter ++;
                
                NSString *query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_x100px_photo = %i WHERE rowid = %i", smallImageDownloadCounter, [photoID intValue]];
                
                //NSLog(@"The query = %@", query);
                [[EntryCollection sharedContentDatabase] executeUpdate:query];

            }
            
            [[EntryCollection sharedContentDatabase] executeUpdate:@"END TRANSACTION"];
        }
        
        [groupedThumbnailsForUpdate removeAllObjects];
    
    }
}



- (BOOL) getFileWithName:(NSString*) fileName andType:(NSString*) fileType withURLString:(NSString*) urlString andFilePath:(NSString*)theFilePath {
	
	BOOL downloadSuccessful = FALSE;
	
	[[NSURLCache sharedURLCache] setMemoryCapacity:0];
	[[NSURLCache sharedURLCache] setDiskCapacity:0];  //TF - Crash on this line on 10/24/11
	
	//NSLog(@"About to look for %@.%@ from %@ and save it to %@", fileName, fileType, urlString, theFilePath);
	
	if(([[NSFileManager defaultManager] fileExistsAtPath: theFilePath] != TRUE) && ([[NSFileManager defaultManager] fileExistsAtPath: [[NSBundle mainBundle] pathForResource:fileName ofType:fileType]] != TRUE)) {
		
		while(![Props global].connectedToInternet){
			
			[NSThread sleepForTimeInterval: 10];
		}
		
		@autoreleasepool {
		
		//Source for the data
			NSString *encodedURLString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			NSURL *dataURL = [[NSURL alloc] initWithString: encodedURLString];
			
			//Get the data
			NSData *theData = [[NSData alloc] initWithContentsOfURL:dataURL];
			
			//Write the data to disk
			NSError * theError = nil;
			
			if([theData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) {
				downloadSuccessful = FALSE;
				//NSLog(@"DATADOWNLOADER: getFileWithName() failed to write file to %@, error = %@, userInfo = %@", theFilePath, theError, [theError userInfo]);
			}
			
			else downloadSuccessful = TRUE;
			 
			
			//downloadSuccessful = [theData writeToFile:theFilePath atomically:TRUE];
			
			//Clean up
		
		}
	}
	
	return downloadSuccessful;
}


//This version of the file getter doesn't check if the file is present, it just gets the data
- (BOOL) getFileWithURLString:(NSString*) urlString andFilePath:(NSString*)theFilePath {
	
	BOOL downloadSuccessful = FALSE;
	
	[[NSURLCache sharedURLCache] setMemoryCapacity:0];
	[[NSURLCache sharedURLCache] setDiskCapacity:0]; 
	
	//NSLog(@"About to check for internet");
	
	while(![Props global].connectedToInternet){
		[NSThread sleepForTimeInterval: 10];
		NSLog(@"Datadownloader.getFileWithURLString: internet not available");
	}
	
	@autoreleasepool {
	
		NSString *encodedURLString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //Source for the data
		
		NSURL *dataURL = [[NSURL alloc] initWithString: encodedURLString];
		
		NSData *theData = [[NSData alloc] initWithContentsOfURL:dataURL]; //Get the data
		
		/*
		NSError * theError = nil; //Write the data to disk
		
		if([theData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) {
			downloadSuccessful = FALSE;
			//NSLog(@"DATADOWNLOADER: getFileWithName() failed to write file to %@, error = %@, userInfo = %@", theFilePath, theError, [theError userInfo]);
		}*/
		
		if([theData writeToFile: theFilePath  atomically:YES]!= TRUE) {
			downloadSuccessful = FALSE;
			//NSLog(@"DATADOWNLOADER: getFileWithName() failed to write file to %@, error = %@, userInfo = %@", theFilePath, theError, [theError userInfo]);
		}
		
		else {
			downloadSuccessful = TRUE;
			//NSLog(@"DATADOWNLOADER.getFileWithName: just wrote file to %@", theFilePath);
		}
		
		
		//NSLog(@"Retain count for theData = %i", [theData retainCount];)
		theData = nil;
		
		return downloadSuccessful;
	}
}


- (void) downloadPitchIcons:(BOOL) forSutroWorld {
	
	//NSLog(@"DOWNLOADER - Downloading pitch icons for %@", (forSutroWorld) ? @"Sutro World" : @"main app");
	
	NSMutableArray *appIDs = [NSMutableArray new];
	
	FMDatabase *db = nil;
	
	@synchronized([Props global].dbSync) {
        
        if (!forSutroWorld ||(forSutroWorld && [Props global].appID <= 1)) db = [EntryCollection sharedContentDatabase];
        
        //For sutro world, but not in sutro world - update database on file
        else if (forSutroWorld && [Props global].appID > 1) {
            NSString *dbFilePath = [NSString stringWithFormat:@"%@/0.sqlite3",[Props global].cacheFolder];
            db = [[FMDatabase alloc] initWithPath:dbFilePath];
            
            if (![db open]) NSLog(@"DOWNLOADER - Could not open sqlite database from file = %@", dbFilePath);
        }
		//NSLog(@"DOWNLOADER.downloadPitchIcons:lock");		
		NSString * query = @"SELECT DISTINCT appid FROM pitches";
		
		FMResultSet * rs = [db executeQuery:query];
		
		if ([db hadError]) NSLog(@"\n **** WARNING: SQLITE ERROR: DATADOWNLOADER.downloadPitchIcons, query = %@, %d: %@\n", query, [db lastErrorCode], [db lastErrorMessage]);
		
		while ([rs next]){
			
			[appIDs addObject:[NSNumber numberWithInt:[rs intForColumn:@"appid"]]];
		}
		
		[rs close];

		
		if (forSutroWorld && [Props global].appID != 0) {
			[db close];
		}
	}
	
	
	NSMutableArray *missingImageArray = [NSMutableArray new];
	
	int counter = 0;
	
	NSString *theFolderPath;
	
	if (forSutroWorld)
		theFolderPath= [NSString stringWithFormat:@"%@/0/images", [Props global].cacheFolder];
	
	else 
		theFolderPath= [NSString stringWithFormat:@"%@/images", [Props global].contentFolder];
	
	if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath]) {
		[[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil];
		//NSLog(@"DATADOWNLOADER - Just created image file for pitches at %@", theFolderPath);
	}
	
	//try to download images as long as it's making progress (ie - there are fewer images to go after each try)
    
	while (TRUE) {
		
		@autoreleasepool {
		
			for(NSString *appID in appIDs) {
				
				if ([self checkForHigherPriorityStuff])break;
				
				//Sort out where to write the data/ check if it's already there
				NSString *theFilePath = [NSString stringWithFormat:@"%@/%i_87x87.jpg", theFolderPath, [appID intValue]];
				NSString *urlString = [[NSString alloc] initWithFormat: @"http://sutromedia.com/app-icons/%i_87x87_whitebg.jpg",[appID intValue]];
				
				[self getFileWithName:[NSString stringWithFormat:@"%i_87x87",[appID intValue]] andType:@"jpg" withURLString:urlString andFilePath: theFilePath];
			}
		}
		
		if([appIDs count] <= [missingImageArray count]) {
			counter ++;
			
			// if we don't make any progress after two times through, let's call it quits for this session
			if (counter > 1) 
				break;
		}
		
		appIDs = missingImageArray;
		[missingImageArray removeAllObjects];
	}
	
	//[appIDs release]; don't know why this release is problematic - definitly a leak here.
	
	if(forSutroWorld) sutroPitchIconsDownloaded = TRUE;	
}


- (void) downloadImagesForImageArray:(NSMutableArray*) tmpImageArray {
	
	
	NSString *theFolderPath = [NSString stringWithFormat:@"%@/images",[Props global].contentFolder];
	
	NSLog(@"DOWNLOADER.downloadImagesForImageArray: Will write %i images to %@", [tmpImageArray count], theFolderPath);
	
	NSMutableArray *missingImageArray = [NSMutableArray new];
	
	int counter = 0;
	
	@synchronized([Props global].dbSync) {
	
		FMDatabase *db = [EntryCollection sharedContentDatabase];
		NSString *query;
        if ([Props global].appID != 1) query = [NSString stringWithFormat:@"SELECT MAX(downloaded_%ipx_photo) AS theMax FROM photos",[Props global].deviceType == kiPad ? 768:320];
        
        else query = @"SELECT MAX(downloaded_x100px_photo) AS theMax FROM photos";
        
		FMResultSet * rs = [db executeQuery:query];
		
		if ([rs next]) downloadCounter = [rs intForColumn:@"theMax"];
		[rs close];
	}
	
	//check to see if images folder is there and create it if not
	if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath]) [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ];
	
    //try to download images as long as it's making progress (ie - there are fewer images to go after each try)
    while (TRUE) {
        
        //NSLog(@"DOWNLOADER - Going through while loop in downloadImageData with tmpImageArray count = %i and missingImageArrayCount = %i", [tmpImageArray count], [missingImageArray count]);
        
        for(NSString *imageName in tmpImageArray) {
            
            @autoreleasepool {
            
                if([self checkForHigherPriorityStuff]) {
                    //NSLog(@"DOWNLOADER.downloadeImagesForImageArray: breaking loop after leaving test app");
                    break;
                }
                
                //Sort out where to write the data/ check if it's already there
                
                NSString *fileName;
                
                if ([Props global].appID != 1 && !entryBeingDownloaded) fileName = [[NSString alloc] initWithFormat:@"%@%@", imageName, ([Props global].deviceType == kiPad) ? @"_768":@""];
                
                else fileName = [[NSString alloc] initWithFormat:@"%@_x100", imageName];
                
                NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/%@.jpg", theFolderPath, fileName];
                
                NSString *urlString = [[NSString alloc] initWithFormat: @"%@/%@.jpg",imageSource, imageName];
                
                BOOL filePresent = ([[NSFileManager defaultManager] fileExistsAtPath: theFilePath] || [[NSFileManager defaultManager] fileExistsAtPath: [[NSBundle mainBundle] pathForResource:fileName ofType:@"jpg"]]);
                
                //if (filePresent) NSLog(@"DOWNLOADER.downloadImagesForImageArray: %@ is present", imageName);
                //NSLog(@"About to look for file at %@", theFilePath);
                
                if(!filePresent && [self getFileWithURLString:urlString andFilePath: theFilePath]!= TRUE) {
                    if (imageName != nil) {
                        [missingImageArray addObject:imageName];
                        NSLog(@"**** WARNING: DOWNLOADER.downloadImagesForImageArray:could not get image from %@", urlString);
                    }
                    
                    else NSLog(@"DOWNLOADER.downloadImagesForImageArray: ERROR, IMAGE NIL");
                }
                
                else {
				
                    //NSLog(@"DOWNLOADER.downloadImageDataforImageArray: updating database with new image");
                    
                    downloadCounter ++;
                    
                    NSString *query;
                    
                    if ([Props global].appID != 1) query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_%ipx_photo = %i WHERE rowid = %@", [Props global].deviceType == kiPad ? 768:320, downloadCounter, imageName];
                    
                    else query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_x100px_photo = %i WHERE rowid = %@", downloadCounter, imageName];
                    
                    //NSLog(@"DATADOWNLOADER.downloadImageForImageArray: Updating photo_downloaded, query = %@", query);
                    
                    @synchronized([Props global].dbSync) {
                        FMDatabase *db = [EntryCollection sharedContentDatabase];
                        //NSLog(@"DOWNLOADER.imagesForImageArray:lock");
                        [db executeUpdate:@"BEGIN TRANSACTION"];
                        [db executeUpdate:query];
                        [db executeUpdate:@"END TRANSACTION"];
                    }
                }
                
            
            //Sleep for a moment each cycle to give the event loop time to respond
            }
            [NSThread sleepForTimeInterval: 0.10];
        }
        
        if([tmpImageArray count] <= [missingImageArray count]) {
            counter ++;
            //NSLog(@"DOWNLOADER.downloadImageDataForImageArray: counter = %i", counter);
            
            // if we don't make any progress after two times through, let's call it quits for this session
            if (counter > 1 || [missingImageArray count] == 0) 
                break;
        }
        
        tmpImageArray = missingImageArray;
        missingImageArray = [NSMutableArray new];
    }
		
    
    doneDownloadingImageData = TRUE;
	
}

				 
- (void) downloadDataForEntry {
	
	NSLog(@"DOWNLOADER.downloadDataForEntry:%@", self.entry.name);
    
    int entryid = entry.entryid;
	
	// Get the images that still need downloading for the entry
	NSMutableArray *entryImagesArray = [NSMutableArray new];
	
	int photoSize = ([Props global].deviceType == kiPad) ? 768 : 320;
	
	NSString *query;
    
    if ([Props global].appID > 1) query = [NSString stringWithFormat:@"SELECT photos.rowid from photos, entries, entry_photos WHERE downloaded_%ipx_photo IS NULL AND entry_photos.entryid = %i AND entry_photos.photoid = photos.rowid AND entry_photos.entryid = entries.rowid", photoSize, self.entry.entryid];
    
    else query = [NSString stringWithFormat:@"SELECT photos.rowid from photos, entries, entry_photos WHERE downloaded_x100px_photo IS NULL AND entry_photos.entryid = %i AND entry_photos.photoid = photos.rowid AND entry_photos.entryid = entries.rowid", self.entry.entryid];
	
	@synchronized([Props global].dbSync) {
		//NSLog(@"DOWNLOADER.downDataForEntry:lock");
		FMDatabase * db = [EntryCollection sharedContentDatabase];
		FMResultSet * rs = [db executeQuery:query];
		
		if ([db hadError]) NSLog(@"sqlite error in [DataDownloader createImageArray], query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
		
		while ([rs next]) {
			[entryImagesArray addObject:[rs stringForColumn:@"rowid"]];
		}
		[rs close];
	}		
	
	NSLog(@"DOWNLOADER.downloadDataForEntry:%i images need to be downloaded for %@", [entryImagesArray count], self.entry.name);
	
	entryBeingDownloaded = TRUE;
	[self downloadImagesForImageArray:entryImagesArray];
	entryBeingDownloaded = FALSE;
	
    //In the event that a new entry for download is set while the first is still downloading, we don't want to inadvertantly stop the new entry from downloading
    //Neeed to figure out something better than this!
    if (entry.entryid == entryid) {
        self.entry = nil;
        entryNeedsDownload = FALSE;
    }
    
    else [self downloadDataForEntry];
    
	
	NSLog(@"DOWNLOADER.downloadDataForEntry:completes");
}


/*- (NSMutableArray*) createImageArray {
	
	//NSMutableArray *theImageNameArray = [NSMutableArray new];
	
	NSString * query = ([Props global].deviceType == kiPad) ? [NSString stringWithFormat:@"SELECT rowid FROM photos WHERE downloaded_768px_photo is NULL"] : [NSString stringWithFormat:@"SELECT rowid FROM photos WHERE downloaded_320px_photo is NULL"];
	
	@synchronized([Props global].dbSync) {
		//NSLog(@"DOWNLOADER.createImageArray:lock");
		FMDatabase * db = [EntryCollection sharedContentDatabase];
		FMResultSet * rs = [db executeQuery:query];
		
		if ([db hadError]) NSLog(@"sqlite error in [DataDownloader createImageArray], query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
		
		while ([rs next]) {
			[theImageNameArray addObject:[rs stringForColumn:@"rowid"]];
		}
		[rs close];
	}
	
	//NSLog(@"DOWNLOADER.createImageArray:outside lock");
	
	return theImageNameArray;
}*/


- (void) setEntryForDownload: (Entry*) theEntry {
	
	NSLog(@"DOWNLOADER.setEntryForDowload: %@", theEntry.name);
	self.entry = theEntry;
	entryNeedsDownload = TRUE;	
}


- (void) pauseDownload {
	pauseCount ++;
	
	if(pauseCount > 0)
		paused = TRUE;	
}


- (void) resumeDownload {
	pauseCount --;
	
	if(pauseCount < 0)
		pauseCount = 0;
	
	if(pauseCount == 0)
		paused = FALSE;
}


- (void) moveOldImagesFolder {
    
    @autoreleasepool {
    
        NSLog(@"DATADOWNLOADER.moveOldImagesFolder: start");
        
        //Copy image files
        NSString *oldImagesFolderLocation = [NSString stringWithFormat:@"%@/%i/images", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], [Props global].appID];
        NSArray *imageFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:oldImagesFolderLocation error:nil];
        
        NSLog(@"DATADOWNLOAER.moveOldImagesFolderIfNeeded: %i images to be copied", [imageFiles count]);
        
        NSString *newImagesFolderPath = [NSString stringWithFormat:@"%@/%i/images", [Props global].cacheFolder, [Props global].appID];
        
        NSError *error = nil;
        if(![[NSFileManager defaultManager] isWritableFileAtPath:newImagesFolderPath]) [[NSFileManager defaultManager] createDirectoryAtPath: newImagesFolderPath withIntermediateDirectories:YES attributes: nil error: &error];
        
        if (error != nil){
            NSLog(@"Error creating folder. Error = %@", [error description]);
            error = nil;
        }
        
        for (NSString *oldFile in imageFiles) {
            
            //NSString *fileName = [[oldPath componentsSeparatedByString:@"/"] lastObject];
            NSString *oldPath = [NSString stringWithFormat:@"%@/%@", oldImagesFolderLocation, oldFile];
            NSString *newPath = [NSString stringWithFormat:@"%@/%@", newImagesFolderPath, oldFile]; 
            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error];
            
            //NSLog(@"Moved file from %@ to %@", oldPath, newPath);
            
            if (error != nil) {
                NSLog(@"Error moving file. Error = %@", [error description]);
            }
            
            [NSThread sleepForTimeInterval:0.002];
        }
        
        //Copy Sutro World Files
        oldImagesFolderLocation = [NSString stringWithFormat:@"%@/0/", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
            
        [[NSFileManager defaultManager] removeItemAtPath:oldImagesFolderLocation error:&error];
        if (error != nil) {
            NSLog(@"Error deleting files. Error = %@", [error description]);
            error = nil;
        }
        
             
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kMovedImagesToCachesFolder]; //We only need to do this once for apps being upgraded
        
        
        NSLog(@"DATADOWNLOADER.moveOldImagesFolder: completes");
    
    }
}

/*
#pragma mark
#pragma mark Notification Response Methods

- (void) updateOfflineMaps {
    
    if (downloader == nil) downloader = [[GuideDownloader alloc] initForUpgradeContentDownload];
    
    [downloader updateOfflineMaps];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOfflineMaps]) {
        
        [downloader performSelectorInBackground:@selector(downloadOfflineMaps) withObject:nil];
    }
    
    else {
        
        NSLog(@"Time to remove offline maps");
        [downloader performSelectorInBackground:@selector(removeOfflineMaps) withObject:nil];
    }
}


- (void) updateOfflinePhotos {
    
    if (downloader == nil) downloader = [[GuideDownloader alloc] initForUpgradeContentDownload];
    
    [downloader updateOfflinePhotos];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOfflinePhotos]) {
        NSLog(@"Time to download offline images");
        [downloader performSelectorInBackground:@selector(downloadOfflineImages) withObject:nil];
    }
    
    else {
        
        NSLog(@"Time to remove offline images");
        [downloader performSelectorInBackground:@selector(removeOfflineImages) withObject:nil];
    }
}
*/

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


#pragma mark
#pragma mark Authors Tool Stuff

//Here's where we get the content that downloads as the test app runs
- (void) getLowPriorityTestAppContent {
	
	//NSLog(@"DOWNLOADER - Downloading low priority test app content");
	
	workingOnTestAppDownloads = TRUE;
	
	[self downloadPitchIcons:FALSE];
	[self downloadComments:FALSE];
	
	// get rest of the images
	NSLog(@"DOWNLOADER - About to start downloading all images for Test App");
	
	NSMutableArray *tmpImageArray = [NSMutableArray new];
	
	NSString *documentsFolderPath = [NSString stringWithFormat:@"%@/%i/content.sqlite3",[Props global].cacheFolder, [Props global].appID];

    @synchronized([Props global].dbSync) {
        NSLog(@"DOWNLOADER.getLowPriorityTestAppContent:lock");
        FMDatabase *db = [[FMDatabase alloc] initWithPath:documentsFolderPath];
        
        if (![db open]) NSLog(@"Error opening database");
        
        NSString *searchString = @"SELECT photoid FROM entry_photos";
        
        //NSLog(@"Setting up database with search string %@", searchString);
        
        FMResultSet *rs = [db executeQuery:searchString];
        
        if ([db hadError]) {
            NSLog(@"DOWNLOADER - Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
        while ([rs next]) {
            
            [tmpImageArray addObject:[NSString stringWithFormat: @"%i",[rs intForColumn:@"photoid"]]];
        }
        
        [rs close];
        [db close];
    }
	
	
	[self downloadImagesForImageArray: tmpImageArray];
	
	workingOnTestAppDownloads = FALSE;
	
	//hang out as long as we're in the test app
	while ([Props global].inTestAppMode) { [NSThread sleepForTimeInterval: 1];}
}


#pragma mark
#pragma mark Singleton stuff

//static DataDownloader * sharedDataDownloader = nil;
+ (DataDownloader*)sharedDataDownloader {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}


@end
