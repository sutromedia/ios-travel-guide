//
//  SingleSettingView.m
//  TheProject
//
//  Created by Tobin Fisher on 11/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SingleSettingView.h"
#import <QuartzCore/QuartzCore.h>
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "EntryCollection.h"
#import "Reachability.h"

@interface SingleSettingView (Private) 

- (void) updateProgressView:(NSDictionary*) theStatus;

@end


@implementation SingleSettingView


@synthesize title, key;

- (id)initWithFrame:(CGRect)frame
{
    
    float height = [Props global].deviceType == kiPad ? 80 : 60;
    
    frame = CGRectMake(frame.origin.x, frame.origin.y, [Props global].screenWidth, height);
    
    
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        self.title = nil;
        
        //descriptionLabel = nil;
        //downloadProgressLabel = nil;
        downloadProgress = nil;
        
        //************** Update state based on saved defaults **************************
        //Get latest saved status from user defaults
        paused = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, [Props global].appID]];
        
        totalContentSize = kValueNotSet;
        photoSize = [Props global].deviceType == kiPad ? kAverageiPadImageSize : kAverageiPhoneImageSize;
		
		[Reachability sharedReachability].networkStatusNotificationsEnabled = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectivityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];
    }
	
    return self;
}


- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //if (descriptionLabel != nil) [descriptionLabel release];
    
    //self.key = nil;
    
    //if (downloadProgressLabel != nil) [downloadProgressLabel release];
    
}


- (void) setKey:(NSString *)_key {
    
    key = _key;
    
    //Register to recieve future updates when available from downloader
    NSString *notificationName = [NSString stringWithFormat:@"%@_%@", kUpdateOfflineContentDownloadProgress, key];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloadProgress:) name:notificationName object:nil];
    
    if ([key  isEqual: kOfflinePhotos]) {
        int totalNumberOfPhotos = 0;
        
        FMDatabase *db = [EntryCollection sharedContentDatabase];
        
        @synchronized ([Props global].dbSync) {
            FMResultSet *rs = [db executeQuery: @"SELECT COUNT(*) AS theCount FROM entries"];
            
            if ([db hadError]) NSLog(@"\n **** WARNING: SQLITE ERROR: SINGLESETTINGVIEW.setKey, %d: %@\n", [db lastErrorCode], [db lastErrorMessage]);
            
            int totalNumberOfEntries = 1;
            if ([rs next]) totalNumberOfEntries = [rs intForColumn:@"theCount"];
            else NSLog(@"GUIDEDOWNLOADER.updateTotalContentSize: Error with query");
            
            [rs close];
            
            NSLog(@"Entry count = %i", totalNumberOfEntries);
        }
        
        @synchronized ([Props global].dbSync) {
            FMResultSet *rs = [db executeQuery: @"SELECT COUNT(*) AS theCount FROM photos"];
            
            if ([db hadError]) NSLog(@"\n **** WARNING: SQLITE ERROR: SINGLESETTINGVIEW.setKey, %d: %@\n", [db lastErrorCode], [db lastErrorMessage]);
            
            if ([rs next]) totalNumberOfPhotos = [rs intForColumn:@"theCount"];
            else NSLog(@"GUIDEDOWNLOADER.updateTotalContentSize: Error with query");
            
            [rs close];
        }
        
        if ([Props global].isShellApp) {
            @synchronized ([Props global].dbSync) {
                FMResultSet *rs = [db executeQuery: @"SELECT COUNT(*) AS theCount FROM entries"];
                int totalIconPhotos = 0;
                if ([rs next]) totalIconPhotos = [rs intForColumn:@"theCount"];
                else NSLog(@"GUIDEDOWNLOADER.updateTotalContentSize: Error with query");
                
                totalNumberOfPhotos -= totalIconPhotos;
                
                [rs close];
            }
        }
        
        totalContentSize = totalNumberOfPhotos * photoSize;
        //totalContentSize = 101; //484;
        //NSLog(@"SINGLESETTINGSVIEW.setKey: photos are %f MB", totalNumberOfPhotos * photoSize);
    }
    
    else if ([key  isEqual: kOfflineMaps_Max_ContentSize]) {
        
        //NSDate *date = [NSDate date];
        NSString *mapDatabaseLocation = [Props global].isShellApp ? [NSString stringWithFormat:@"%@/offline-map-tiles.sqlite3",[Props global].contentFolder] : [Props global].mapDatabaseLocation;
        FMDatabase *mapDatabase = [[FMDatabase alloc] initWithPath:mapDatabaseLocation];
        
        if (![mapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.updateTotalContentSize - Can't open map tile database");
        
        int numberOfMapTiles = 0;
        
        @synchronized ([Props global].mapDbSync) {
            //NSLog(@"SINGLESETTINGSVIEW.setKey: time up to getting sync = %f", -[date timeIntervalSinceNow]);
            FMResultSet *rs = [mapDatabase executeQuery:@"SELECT value AS theCount FROM preferences WHERE name = 'initial_tile_row_count'"];
            //FMResultSet *rs = [mapDatabase executeQuery:@"SELECT value as theCount FROM preferences WHERE name = 'map.maxZoom'"];
            
            if ([rs next]) numberOfMapTiles = [rs intForColumn:@"theCount"];
            
            //NSLog(@"SINGLESETTINGSVIEW.setKey: time up to getting sync = %f", -[date timeIntervalSinceNow]);
            [rs close];
        }
        
        [mapDatabase close];
        
        //NSLog(@"GUIDEDOWNLOADER.updateTotalContentSize: map tiles are %f MB", numberOfMapTiles * kAverageMapTileSize);
        
        totalContentSize = numberOfMapTiles * kAverageMapTileSize;
        //totalContentSize = 97; //37.3;
        
        //NSLog(@"SINGLESETTINGSVIEW.setKey: total time = %f", -[date timeIntervalSinceNow]);
    }
	
	else if ([key  isEqual: kOfflineFiles]) {
		
		totalContentSize = [[Props global].offlineLinkURLs count] * kAverageOfflineLinkFileSize;
	}
	
	NSString *downloadAmountKey = [NSString stringWithFormat:@"%@_%i", self.key, [Props global].appID];
    amountToDownload = [[NSUserDefaults standardUserDefaults] floatForKey:downloadAmountKey];
	
	if (amountToDownload > totalContentSize) {
		amountToDownload = totalContentSize;
		[[NSUserDefaults standardUserDefaults] setFloat:amountToDownload forKey:downloadAmountKey];
	}
    
    [self updateProgressView]; //Views aren't created yet, but we do this to set the current values in advance in creating the views
}


- (void)drawRect:(CGRect)rect {
    
    /*float frameHeight = 70;
    CALayer *background = [[CALayer alloc] init];
    background.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0].CGColor;
    background.cornerRadius = 10;
    background.borderColor = [UIColor colorWithRed:0.63 green:0.68 blue:0.69 alpha:1.0].CGColor;
    background.borderWidth = 1;
    background.frame = CGRectMake([Props global].leftMargin, 0, self.frame.size.width - [Props global].leftMargin * 2, frameHeight);
    background.shadowColor = [UIColor whiteColor].CGColor;
    background.shadowOffset = CGSizeMake(0, .5);
    background.shadowRadius = 0.5;
    background.shadowOpacity = 0.7;
    background.opacity = 0.9;
    [self.layer addSublayer:background];
    [background release];
     */

    UIColor *textColor = [UIColor blackColor];
    
    float fontSize = 16;
    float labelHeight = fontSize + 2;
    UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
    
    mainLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin * 2, [Props global].leftMargin, [Props global].screenWidth - [Props global].leftMargin * 4, labelHeight)];
    
    NSString *mainLabelTitle = self.title;
    
    //NSLog(@"SINGLESETTINGSVIEW.drawRect: current size = %f and target = %f", currentContentSize, amountToDownload);
    
    if (currentContentSize < amountToDownload * .9){
        if ([Props global].connectedToInternet) mainLabelTitle = [mainLabelTitle stringByAppendingString:@" - downloading"];
        else mainLabelTitle = [mainLabelTitle stringByAppendingString:@" - waiting for internet"];
    }
    
    mainLabel.text =   mainLabelTitle;
    mainLabel.font = font;
    mainLabel.textColor = textColor;
    mainLabel.backgroundColor = [UIColor clearColor];
    
    [self addSubview:mainLabel];
    
    
    downloadProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    downloadProgress.alpha = 1.0;
    downloadProgress.backgroundColor = [UIColor clearColor];
    //downloadProgress.hidden = !downloading;
    float downloadFraction = currentContentSize/totalContentSize;
    NSLog(@"SINGLESETTINGVIEW.drawRect:Key = %@ currentContentSize = %0.2f, total content size = %0.2f, amount to download = %f", self.key, currentContentSize, totalContentSize, amountToDownload);
    downloadProgress.progress = downloadFraction;
    downloadProgress.frame = CGRectMake(mainLabel.frame.origin.x + 2, CGRectGetMaxY(mainLabel.frame) + 15, mainLabel.frame.size.width - 74, 40);
    [self addSubview:downloadProgress];
    
    UIFont *labelFont = [UIFont fontWithName:kFontName size:15];
    UILabel *totalLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, labelFont.pointSize + 2)];
    totalLabel.font = labelFont;
    totalLabel.text = [NSString stringWithFormat:@"%0.0f MB", totalContentSize];
    totalLabel.textColor = [UIColor colorWithRed:0.30 green:0.34 blue:0.42 alpha:1];
    totalLabel.shadowColor = [UIColor whiteColor];
    totalLabel.shadowOffset = CGSizeMake(0, 1);
    totalLabel.backgroundColor = [UIColor clearColor];
    totalLabel.numberOfLines = 0;
    totalLabel.textAlignment = UITextAlignmentLeft;
    
    UIGraphicsBeginImageContext(totalLabel.bounds.size);
    [totalLabel.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *totalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    downloadAmount = [[UISlider alloc] initWithFrame:CGRectZero];
    downloadAmount.backgroundColor = [UIColor clearColor];
    //downloadAmount.alpha = 0.90;
    downloadAmount.maximumValueImage = totalImage;
    
    if ([downloadAmount respondsToSelector:@selector(setMinimumTrackTintColor:)])
        downloadAmount.minimumTrackTintColor = [UIColor colorWithRed:0.4 green:0.5 blue:0.9 alpha:0.3];
	
	else downloadAmount.alpha = 0.7;
    
    downloadAmount.frame = CGRectMake(mainLabel.frame.origin.x, 0, mainLabel.frame.size.width, downloadProgress.frame.size.height);
    
    //There is a weird glitch where the download indicator is displayed differently on pre- iOS 5 OS. Dunno why. 
    if ([Props global].osVersion >= 5.0) downloadAmount.center = CGPointMake(downloadAmount.center.x, downloadProgress.center.y);
        
    else downloadAmount.center = CGPointMake(downloadAmount.center.x, downloadProgress.center.y - 16);
	
	
	NSLog(@"Download amount frame = %@, download amount = %@", downloadAmount, downloadProgress);
    
    downloadAmount.value = totalContentSize > 0 ? amountToDownload/totalContentSize : 0;
    
    [downloadAmount addTarget:self action:@selector(sliderMoved) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:downloadAmount];
    
    downloading = FALSE;
    
    /*
    UIFont *descriptionFont = [UIFont fontWithName:kFontName size:15];
    float textBoxWidth = self.frame.size.width - [Props global].leftMargin * 4;
    //CGSize textBoxSizeMax = CGSizeMake(textBoxWidth, 5000); // height value does not matter as long as it is larger than height needed for text box
    //CGSize textBoxSize = [self.description sizeWithFont:descriptionFont constrainedToSize: textBoxSizeMax lineBreakMode: 0];
    
    descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin * 2, CGRectGetMaxY(background.frame) + 7, textBoxWidth, descriptionFont.pointSize + 2)];
    descriptionLabel.font = descriptionFont;
    descriptionLabel.text = [NSString stringWithFormat:@"%@ require %0.0f MB", self.title, totalContentSize];
    descriptionLabel.textColor = [UIColor colorWithRed:0.30 green:0.34 blue:0.42 alpha:1];
    descriptionLabel.shadowColor = [UIColor whiteColor];
    descriptionLabel.shadowOffset = CGSizeMake(0, 1);
    descriptionLabel.backgroundColor = [UIColor clearColor];
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.textAlignment = UITextAlignmentCenter;
    descriptionLabel.hidden = downloading;
    [self addSubview:descriptionLabel];
    
    //float height = CGRectGetMaxY(descriptionLabel.frame);

    
    downloadProgressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    downloadProgressLabel.backgroundColor = [UIColor clearColor];
    downloadProgressLabel.font = [UIFont fontWithName:kFontName size:12];
    downloadProgressLabel.textAlignment = UITextAlignmentLeft;
    downloadProgressLabel.textColor = [UIColor grayColor];
    downloadProgressLabel.text = [NSString stringWithFormat:@"0.0 of %0.0f MB", totalContentSize];
    downloadProgressLabel.alpha = .95;
    downloadProgressLabel.hidden = !downloading;
    [self addSubview:downloadProgressLabel];
     */
}


- (void) sliderMoved {
    
    NSLog(@"New slider value = %0.2f", downloadAmount.value);
    NSString *theKey = [NSString stringWithFormat:@"%@_%i", self.key, [Props global].appID];
    
    float newAmountToDownload = downloadAmount.value * totalContentSize;
    
    if (newAmountToDownload > amountToDownload){
     
        if (![Props global].connectedToInternet)
            mainLabel.text = [NSString stringWithFormat:@"%@ - waiting for internet", self.title];
        
        else mainLabel.text = [NSString stringWithFormat:@"%@ - downloading", self.title];
    }
    
    amountToDownload = newAmountToDownload;
    
     NSLog(@"SSV.sliderMoved: The key = %@, value = %f", theKey, amountToDownload);
    
    [[NSUserDefaults standardUserDefaults] setFloat:amountToDownload forKey:theKey];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //Send notification to guide downloader to update
    NSString *notificationName = [NSString stringWithFormat:@"%@_%i", self.key, [Props global].appID];;
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
}

- (void) connectivityChanged {
	
	if (downloading) {
		if (![Props global].connectedToInternet)
			mainLabel.text = [NSString stringWithFormat:@"%@ - waiting for internet", self.title];
		
		else mainLabel.text = [NSString stringWithFormat:@"%@ - downloading", self.title];
	}
}


- (void)layoutSubviews {
    
    //NSLog(@"SINGLESETTINGSVIEW.layoutSubviews: downloading = %@", downloading ? @"TRUE" : @"FALSE");
    
    [super layoutSubviews];
    
    //background.frame = self.frame;
    
    // position the entry name in the content rect
    
    //downloadProgressLabel.hidden = !downloading;
    //downloadProgress.hidden = !downloading;
    pauseButton.hidden = !downloading && paused;
    resumeButton.hidden = !downloading && !paused;
    //descriptionLabel.hidden = downloading;
    
    //float yPos = descriptionLabel.frame.origin.y;
    
    //downloadProgress.frame = CGRectMake([Props global].leftMargin * 2, yPos, self.frame.size.width - [Props global].leftMargin * 4 - 100, 12);
    //downloadProgressLabel.frame = CGRectMake(CGRectGetMaxX(downloadProgress.frame) + 8, yPos - 1, 100, 12);
    
    
    float inset = resumeButton.imageEdgeInsets.left;
    CGRect buttonFrame = CGRectMake(CGRectGetMaxX(self.frame) - self.frame.size.height + (inset - 5), 0, self.frame.size.height, self.frame.size.height);
    resumeButton.frame = buttonFrame;
    pauseButton.frame = buttonFrame;
}


- (void) updateDownloadProgress: (NSNotification *) theNotification  {
    
    //NSLog(@"SINGLESETTINGVIEW.updateDownloadProgress:");
    
    [self performSelectorOnMainThread:@selector(updateProgressView) withObject:nil waitUntilDone:NO];
}


- (void) updateProgressView {
    
    downloading = TRUE;
    
    if ([self.key  isEqual: kOfflinePhotos]) {
        
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
        
        if (numberOfPhotos < 0) numberOfPhotos = 0;
        
        currentContentSize = numberOfPhotos * photoSize;
        
        //NSLog(@"SINGLESETTINGSVIEW.updateProgressView: photos are %f MB", numberOfPhotos * photoSize);
    }
    
    else if ([self.key  isEqual: kOfflineMaps_Max_ContentSize]) {
        
        /*FMDatabase *mapDatabase = [[FMDatabase alloc] initWithPath:[Props global].mapDatabaseLocation];
        
        if (![mapDatabase open]) NSLog(@"ERROR: GUIDEDOWNLOADER.updateTotalContentSize - Can't open map tile database");
        
        int numberOfMapTiles = 0;
        
        @synchronized ([Props global].mapDbSync) {
			
			NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) as theCount FROM tiles WHERE downloaded = %i", [Props global].appID];
			
            FMResultSet *rs = [mapDatabase executeQuery:query];
            
            if ([rs next]) numberOfMapTiles = [rs intForColumn:@"theCount"];
            
            [rs close];
        }
        
        [mapDatabase close];
        
        //NSLog(@"GUIDEDOWNLOADER.updateTotalContentSize: map tiles are %f MB", numberOfMapTiles * kAverageMapTileSize);
        
        currentContentSize = numberOfMapTiles * kAverageMapTileSize;*/
		
		NSString *offlineMapSizeKey = [NSString stringWithFormat:@"%@_%i", kCurrentMapContentSize, [Props global].appID];
		currentContentSize = [[NSUserDefaults standardUserDefaults] floatForKey:offlineMapSizeKey];
        NSLog(@"Offline map content size = %0.2f", currentContentSize);
    }
	
	else if ([self.key  isEqual: kOfflineFiles]) {
		
		NSString *offlineFileDirectory = [NSString stringWithFormat:@"%@/OfflineLinkFiles/", [Props global].contentFolder];
		NSArray *offlineFileDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:offlineFileDirectory error:nil];
		currentContentSize = [offlineFileDirectoryContents count] * kAverageOfflineLinkFileSize;
	}
    
    //NSLog(@"SINGLESETTINGSVIEW.updateProgressView: amountDownloaded = %0.1f, total = %0.0f", currentContentSize, totalContentSize);
    
    //The progress contin
    if (!paused || downloadProgress.progress < 0.01 /*make sure to set download progress if we're just starting*/) {
        downloadProgress.progress = currentContentSize/totalContentSize;
        //downloadProgressLabel.text = currentContentSize > 0 ? [NSString stringWithFormat:@"%0.1f of %0.0f MB", currentContentSize, totalContentSize] : @"0.0 of ? MB";
    }
    
    
    //NSLog(@"Download progress text = %@", downloadProgressLabel.text);
    float fraction = amountToDownload > 0 ? currentContentSize/amountToDownload : 0;
    
    //NSLog(@"SINGLESETTINGVIEW.updateProgressView: content type =%@ amount to download = %0.7f, current content size = %0.2f, fraction = %0.2f",self.key, amountToDownload, currentContentSize, fraction);
    
    if (fraction > 0.95 || fraction < 0.001) {
        downloading = FALSE;
        mainLabel.text = [NSString stringWithFormat:@"%@", self.title];
    }
    
    else mainLabel.text = [NSString stringWithFormat:@"%@ - downloading", self.title];
    
    [self layoutSubviews];
    
    //NSLog(@"LIBRARYCELL.updateDownloadProgress:Download progress for %i. Downloading = %@", entry.entryid, downloading ? @"TRUE" : @"FALSE");
}

- (void) setSliderToDefault {
    
    if ([self.key  isEqual: kOfflineMaps_Max_ContentSize]) {
        [downloadAmount setValue:1.0 animated:YES];
    }
    
    else if ([self.key  isEqual: kOfflinePhotos]) {
        [downloadAmount setValue:1.0 animated:YES];
    }
    
    else if ([self.key  isEqual: kOfflineFiles]) {
        [downloadAmount setValue:1.0 animated:YES];
    }
    
    [self sliderMoved];
}


@end
