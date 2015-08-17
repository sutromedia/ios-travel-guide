//
//  DataDownloader.h
//  TravelGuideSF
//
//  Created by Tobin1 on 8/10/09.
//  Copyright 2009 Sutro Media. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Entry, GuideDownloader;

@interface DataDownloader : NSObject {

	//NSMutableArray *imageNameArray;
    NSMutableArray *groupedThumbnailsForUpdate;
    //NSMutableDictionary *guideDownloaders;
    GuideDownloader *downloader;
	BOOL initialized;
	BOOL entryNeedsDownload;
	BOOL entryBeingDownloaded;
	BOOL doneDownloadingImageData;
	BOOL paused;
	BOOL downloadComplete;
	BOOL alertShown;
	BOOL littleAppIconsDownloaded;
	BOOL bigAppIconsDownloaded;
	BOOL sutroImagesDownloaded;
	BOOL sutroCommentsDownloaded;
	BOOL workingOnSutroDownloads;
	BOOL doneSutroDownloads;
	BOOL sutroPitchIconsDownloaded;
	BOOL workingOnTestAppDownloads;
	BOOL testAppContentDownloaded;
	BOOL prioritizingSutroDownloads;
    BOOL waitLoopInitialized;
	BOOL appImagesDownloaded;
	int downloadCounter;
	int sutroDownloadCounter;
    int smallImageDownloadCounter;
    int concurrentRequests;
	Entry *entry;
	NSString *documentsDirectory;
	NSString *imageSource;
	int	pauseCount;
}


@property (nonatomic, strong) Entry *entry;
//@property (nonatomic, strong) NSMutableArray *imageNameArray;
@property (nonatomic) int downloadCounter;
@property (nonatomic) BOOL initialized;

- (void) initializeDownloader;
- (void) setEntryForDownload: (Entry*) theEntry;
- (void) pauseDownload;
- (void) resumeDownload;

+ (DataDownloader*) sharedDataDownloader;

@end
