//
//  GuideDownloader.h
//  TheProject
//
//  Created by Tobin1 on 5/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;

@interface GuideDownloader : NSObject {
    
    int guideId;
    //int downloadPriority;
    int maxConcurrentDownloads;
    NSString *contentFolder;
    NSString *contentSource;
    NSString *imageSource;
    NSString *currentTask;
    NSString *lastCurrentTask;
    FMDatabase *guideDatabase;
    FMDatabase *mainMapDatabase;
   
    
    NSMutableDictionary *missingContent;
    
	BOOL updatingContentSource;
	BOOL isSample;
    BOOL doingSampleUpgrade;
    
    //Base content
    BOOL pauseDownload;
    BOOL waiting;
    BOOL shouldStop;
    BOOL stopped;
    BOOL downloadingBaseContent;
    float current_BaseContentSize;
    float last_BaseContentSizeUpdate;
    float total_BaseContentSize;
    
    //Offline photos
	NSTimer *offlinePhotoTimer;
	NSMutableArray *groupedPhotoIDsToUpdate;
	NSMutableArray *groupedThumbnailPhotoIDsToUpdate;
    BOOL stopImageDownload;
    BOOL downloadingPhotos;
    float current_OfflinePhotosContentSize;
    float max_OfflinePhotoContentSize;
    float averagePhotoSize;
    
    //Offline maps
	NSTimer *offlineMapTimer;
    NSMutableArray *groupedMapTilesToupdate;
    float current_OfflineMapContentSize;
    float total_OfflineMapContentSize;
    float max_OfflineMapContentSize;
    BOOL hasMaps;
    BOOL stopMapDownload;
    BOOL mapsDownloaded;
    BOOL downloadingMaps;
    BOOL removingMaps;
    BOOL stopRemovingMaps;
    
    //Offline link files
	NSTimer *offlineLinkFileTimer;
    BOOL stopOfflineLinkFileDownload;
    BOOL offlineLinkFileDownloadStopped;
    BOOL downloadingOfflineLinkFiles;
    float current_OfflineLinkFileContentSize;
    float max_OfflineLinkFileContentSize;
    
    //Entry thumbnail download
    BOOL stopEntryThumbnailDownload;
    BOOL downloadingEntryThumbnails;
    int thumbnailDownloadQuantity;
    
    int status;
    int concurrentRequests;
    int imageDownloadCounter;
    int thumbnailImageDownloadCounter;
    int consecutiveFailureCount;
    int orginalDatabaseMemoryAddress; //Used to identify going into test app mode
    int lastStatus;
    int latestBundleVersion;
    float waitTime; //used to slow down or speed up download rate
    
    //Performance checking variables
    float timeInCheckForPause; 
    float timeInPostUpdate; 
    
       
    //Test variables
    NSMutableArray *badImageArray;
}


- (id) initWithGuideId:(int) theGuideId;
- (id) initForTestAppWithGuideId:(int) theGuideId;
//- (id) initForUpgradeContentDownload;

- (void) downloadBaseContent;
- (void) getIconPhotos;
- (void) getOfflinePhotos;
- (void) getOfflineLinkFiles;
- (void) getOfflineMapTiles;
- (void) getMapDatabase;
//- (void) getThumbnails;
- (BOOL) doesAppHaveMaps;
- (void) removeOfflinePhotos;
//- (void) downloadOfflineImages;
- (void) updateOfflineMaps;
- (void) updateOfflinePhotos;
//- (void) downloadOfflineMaps;
//- (void) removeOfflineMaps;
- (void) checkForContentUpdate;
- (void) removeAllContent;
- (void) getMaxThumbnailPhotos;
- (void) updateContent;


@property (nonatomic) BOOL pauseDownload;
@property (nonatomic) BOOL waiting;
@property (nonatomic) int  guideId;
@property (nonatomic) int  status;
@property (nonatomic) BOOL shouldStop;


@end
