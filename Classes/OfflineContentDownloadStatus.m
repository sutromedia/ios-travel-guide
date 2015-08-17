//
//  OfflineContentDownloadStatus.m
//  TheProject
//
//  Created by Tobin Fisher on 11/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OfflineContentDownloadStatus.h"
#import "Entry.h"
#import "Props.h"
#import "Reachability.h"
#import "FMDatabase.h"
#import "FMResultSet.h"


#define kStopDownloadTag 23452635
#define kRemoveImagesTag 90872345

@interface OfflineContentDownloadStatus (Private)

- (void) updateDownloadProgress: (NSNotification*) theStatus;
- (void) updateStatusLabel;
- (void) pauseDownload;
- (void) updateSizeText;
- (void) updateDownloadImagesButtonTitle;
- (void) updateProgressView:(NSDictionary*) theStatus;
- (void) removeOfflineImages;
- (void) stopDownloadingOfflineImages;
//- (void) updateRemoveOfflineImagesButtonTitle;

@end

@implementation OfflineContentDownloadStatus


@synthesize downloader;
@synthesize downloading;
@synthesize waiting;
@synthesize height;



- (id)init {
    
    height = 32;
    
    self = [super initWithFrame:CGRectMake(0, [Props global].screenHeight - [Props global].titleBarHeight - [Props global].tabBarHeight - height, [Props global].screenWidth, height)];
    
    if (self) {
        connectedToInternet = TRUE;
        self.opaque = NO;
        self.alpha = 0.7;
        self.backgroundColor = [UIColor blackColor];
        currentTask = @"";
        self.height = [Props global].tableviewRowHeight_libraryView;
        lastStatus = nil;
        
        [self updateStatusLabel];
        
        [self updateDownloadImagesButtonTitle];
        
        //[self updateRemoveOfflineImagesButtonTitle];
        
        //************** Update state based on saved defaults **************************
        //Get latest saved status from user defaults
        paused = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, [Props global].appID]];
        
        NSDictionary *theStatus = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, [Props global].appID]];
        [self updateProgressView: theStatus];
        
        
        //Register to recieve future updates when available from downloader
        NSString *notificationName = [NSString stringWithFormat:@"%@_%i", kUpdateDownloadProgress, [Props global].appID];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloadProgress:) name:notificationName object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseDownloadNotification:) name:kPauseGuideDownload object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeDownloadNotification:) name:kResumeGuideDownload object:nil];
        
        connectivityChecker = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateInternetConnectivity) userInfo:nil repeats:YES];
        
	}
    
    return self;
}


- (void)dealloc {

    
    if (connectivityChecker != nil) [connectivityChecker invalidate];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}


- (void) drawRect:(CGRect)rect {
    
    /*background = [[UIView alloc] initWithFrame:self.frame];
    background.backgroundColor = [UIColor blackColor];
    background.alpha = 0.7;
    [self addSubview:background];*/
    
    
    //****** First Row ********
    float fontSize = 10;
    UIFont *font = [UIFont fontWithName:kFontName size:fontSize];
    UIColor *textColor = [UIColor lightGrayColor];
    
    downloadProgressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    downloadProgressLabel.backgroundColor = [UIColor clearColor];
    downloadProgressLabel.font = font;
    downloadProgressLabel.textAlignment = UITextAlignmentLeft;
    downloadProgressLabel.textColor = textColor;
    downloadProgressLabel.text = @"0.0 of ? MB";
    downloadProgressLabel.alpha = .95;
    [self addSubview:downloadProgressLabel];
    
    downloadProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    downloadProgress.alpha = .5;
    downloadProgress.backgroundColor = [UIColor clearColor];
    [self addSubview:downloadProgress];
    
    //****** Second row **********
    statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    statusLabel.backgroundColor = [UIColor clearColor];
    statusLabel.font = font;
    statusLabel.text = @"";
    statusLabel.textAlignment = UITextAlignmentLeft;
    statusLabel.textColor = textColor;
    statusLabel.alpha = .95;
    [self addSubview: statusLabel];
    
    
    //***** Buttons ***************
    float inset = 3;
    UIEdgeInsets insets = UIEdgeInsetsMake(inset, inset, inset, inset); 
    pauseButton = [UIButton buttonWithType:0];
    pauseButton.imageEdgeInsets = insets;
    //pauseButton.frame = buttonFrame;
    [pauseButton addTarget:self action:@selector(pauseDownload) forControlEvents:UIControlEventTouchUpInside];
    [pauseButton setImage:[UIImage imageNamed:@"pause_download.png"] forState:UIControlStateNormal];
    pauseButton.backgroundColor = [UIColor clearColor];
    //pauseButton.alpha = 0.95;
    [self addSubview:pauseButton];
    
    resumeButton = [UIButton buttonWithType:0];
    resumeButton.imageEdgeInsets = insets;
    //resumeButton.frame = buttonFrame;
    [resumeButton addTarget:self action:@selector(resumeDownload) forControlEvents:UIControlEventTouchUpInside];
    [resumeButton setImage:[UIImage imageNamed:@"resume_download.png"] forState:UIControlStateNormal];
    resumeButton.backgroundColor = [UIColor clearColor];
    //resumeButton.alpha = 0.95;
    [self addSubview:resumeButton];

    
    cancelImageDownloadButton = [UIButton buttonWithType:0];
    [cancelImageDownloadButton addTarget:self action:@selector(showStopDownloadingImagesAlert) forControlEvents:UIControlEventTouchUpInside];
    cancelImageDownloadButton.backgroundColor = [UIColor clearColor];
    cancelImageDownloadButton.titleLabel.font = statusLabel.font;
    [cancelImageDownloadButton setTitle:@"Stop downloading photos" forState:UIControlStateNormal];
    [cancelImageDownloadButton setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
    [cancelImageDownloadButton setTitleColor:[UIColor lightGrayColor] forState:UIControlEventTouchDown];
    [cancelImageDownloadButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    cancelImageDownloadButton.hidden = TRUE;
    [self addSubview:cancelImageDownloadButton];
}


- (void)layoutSubviews {
    
    //NSLog(@"LIBARYCELL.layoutSubviews: Guide id = %i", entry.entryid);
    
    [super layoutSubviews];
    
    //background.frame = self.frame;
    
    [self updateStatusLabel];
    
    // position the entry name in the content rect
    
    downloadImagesButton.hidden = TRUE;
    removeOfflineImagesButton.hidden = TRUE;
    downloadProgressLabel.hidden = FALSE;
    statusLabel.hidden = FALSE; 
    downloadProgress.hidden = FALSE;
    pauseButton.hidden = paused;
    resumeButton.hidden = !paused;
    cancelImageDownloadButton.hidden = TRUE;
    
    if (paused && [[lastStatus objectForKey:@"download offline images"] intValue] == 1) {
        
        statusLabel.hidden = TRUE;
        cancelImageDownloadButton.hidden = FALSE;
    }
    
    float yPos = 5;
    
    downloadProgress.frame = CGRectMake([Props global].leftMargin, yPos, self.frame.size.width - 100, 12);
    downloadProgressLabel.frame = CGRectMake(CGRectGetMaxX(downloadProgress.frame) + 8, yPos - 1, 60, 12);
    
    statusLabel.frame = CGRectMake([Props global].leftMargin, CGRectGetMaxY(downloadProgress.frame) + 3, self.frame.size.width - [Props global].leftMargin - [Props global].rightMargin, 16);
    //cancelImageDownloadButton.frame = CGRectMake(statusLabel.frame.origin.x, statusLabel.frame.origin.y, 200, 18);
    
    //NSLog(@"Cancel button is%@ hidden and text = %@", cancelImageDownloadButton.hidden ? @"" : @" not", cancelImageDownloadButton.titleLabel.text);
    
    
    float inset = resumeButton.imageEdgeInsets.left;
    CGRect buttonFrame = CGRectMake(CGRectGetMaxX(self.frame) - self.frame.size.height + (inset - 5), 0, self.frame.size.height, self.frame.size.height);
    resumeButton.frame = buttonFrame;
    pauseButton.frame = buttonFrame;
}


- (void) updateDownloadProgress: (NSNotification *) theNotification  {
    
    // NSLog(@"LIBRARYCELL.updateDownloadProgress: %i", entry.entryid);
    NSDictionary *status = [theNotification object];
    
    [self performSelectorOnMainThread:@selector(updateProgressView:) withObject:status waitUntilDone:NO];
}


- (void) updateProgressView:(NSDictionary*) theStatus {
    
    if (theStatus != nil) {
        
        if (lastStatus != nil) { lastStatus = nil;}
        lastStatus = theStatus;
        
        float amountDownloaded = [[theStatus objectForKey:@"current"] floatValue];
        float total = [[theStatus objectForKey:@"total"] floatValue];
        NSString *newCurrentTask = [theStatus objectForKey:@"current task"];
        downloading = TRUE;
        
        //NSLog(@"LIBRARYCELL.updateProgressView: amountDownloaded = %0.1f, total = %0.0f, currentTask = %@, status = %i", amountDownloaded, total, newCurrentTask, [[theStatus objectForKey:@"summary"] intValue]);
        
        if (newCurrentTask != nil && newCurrentTask != currentTask) {
            NSLog(@"Updating current task to %@", newCurrentTask);
            currentTask = newCurrentTask;
            
            [self updateStatusLabel];
        }
        
        //NSLog(@"LIBRARYCELL.updateProgressView: %i total = %f, current = %0.1f, download progress = %0.3f", entry.entryid, total, amountDownloaded, downloadProgress.progress);
        
        float fraction = amountDownloaded/total;
        
        //The progress contin
        if (!paused || downloadProgress.progress < 0.01 /*make sure to set download progress if we're just starting*/) {
            downloadProgress.progress = fraction;
            downloadProgressLabel.text = total > 0 ? [NSString stringWithFormat:@"%0.1f of %0.0f MB", amountDownloaded, total] : @"0.0 of ? MB";
        }
        
        //NSLog(@"Download progress text = %@", downloadProgressLabel.text);
        
        if ([[theStatus objectForKey:@"summary"] intValue] == kDownloadComplete) {
            
            [self updateDownloadImagesButtonTitle];
            //[self updateRemoveOfflineImagesButtonTitle];
            downloading = FALSE;
            
            [self layoutSubviews];
        }
        
        else if ([[theStatus objectForKey:@"summary"] intValue] >= kReadyForViewing){
            
            readyForViewing = TRUE;
            [self updateStatusLabel];
        }
    }
    
    else {
        downloadProgressLabel.text = @"0.0 of ? MB";
        downloading = TRUE;
    }
    
    
    [downloadProgressLabel setNeedsDisplay];
    [downloadProgress setNeedsDisplay];
    
    //NSLog(@"LIBRARYCELL.updateDownloadProgress:Download progress for %i. Downloading = %@", entry.entryid, downloading ? @"TRUE" : @"FALSE");
}


- (void) updateDownloadImagesButtonTitle {
    
    float offlineImageSize = [[lastStatus objectForKey:@"image size for download"] floatValue];
    
    NSLog(@"LIBRARYCELL.updateDownloadImagesButtonTitle: Image size = %f", offlineImageSize);
    
    if (offlineImageSize > 0.1) {
        NSString *downloadButtonTitle;
        
        if (offlineImageSize > 10) downloadButtonTitle = [NSString stringWithFormat:@"Download offline photos (%0.0f MB)", offlineImageSize];
        else if (offlineImageSize > 1) downloadButtonTitle = [NSString stringWithFormat:@"Download offline photos (%0.1f MB)", offlineImageSize];
        else downloadButtonTitle = [NSString stringWithFormat:@"Download offline photos (%0.2f MB)", offlineImageSize];
        
        NSLog(@"LIBRARYCELL.updateDownloadImagesButtonTitle: New title = %@", downloadButtonTitle);
        [downloadImagesButton setTitle:downloadButtonTitle forState:UIControlStateNormal];
    }
    
    else {
        
        downloadImagesButton.hidden = TRUE;
        removeOfflineImagesButton.hidden = FALSE;
    }
    
}


- (void) downloadOfflineImages {
    
    NSLog(@"LIBRARYCELL.downloadOfflineImages");
    
    if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Looks like you don't have an internet connection. You'll need one to download content." delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:nil];   
		
		[alert show];  
    }
    
    else {
        downloading = TRUE;
        paused = FALSE;
        
        NSDictionary *theStatus = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, [Props global].appID]];
        
        float total = [[theStatus objectForKey:@"total"] floatValue];
        float amountDownloaded = [[theStatus objectForKey:@"current"] floatValue];
        
        float fraction = amountDownloaded/total;
        
        downloadProgress.progress = fraction;
        downloadProgressLabel.text = total > 0 ? [NSString stringWithFormat:@"%0.1f of %0.0f MB", amountDownloaded, total] : @"0.0 of ? MB";
        [downloadProgress setNeedsDisplay];
        [downloadProgressLabel setNeedsDisplay];
        
        [[NSUserDefaults standardUserDefaults] setBool:paused forKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, [Props global].appID]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadOfflineImages object:[NSNumber numberWithInt:[Props global].appID]];
        [self setNeedsLayout];
    }
}


- (void) showStopDownloadingImagesAlert {
    
    NSLog(@"LIBRARYCELL.stopDownloadingImages");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"This will stop downloading offline photos. Want to delete the ones you have downloaded so far?"  delegate: self cancelButtonTitle:@"cancel" otherButtonTitles:@"Stop only", @"Stop and delete", nil];
	
    alert.tag = kStopDownloadTag;
	[alert show];
}


- (void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) index {
    
    if (theAlert.tag == kStopDownloadTag) {
        switch (index)
        {
            case 0:
                NSLog(@"Case 0");
                break;
            case 1:
                NSLog(@"Case 1");
                [self stopDownloadingOfflineImages];
                break;
            case 2: NSLog(@"Case 1");
                [self removeOfflineImages];
                break;
            default:
                break;
        }
    }
    
    else if (theAlert.tag == kRemoveImagesTag && index != 0) [self removeOfflineImages];
}


- (void) pauseDownloadNotification:(NSNotification*) theNotification {
    
    if (theNotification.object == nil || [theNotification.object intValue] == [Props global].appID) {
        
        NSLog(@"LIBRARYCELL.pauseDownloadNotification: %i", [Props global].appID);
        paused = TRUE;
        pauseButton.hidden = TRUE;
        resumeButton.hidden = FALSE;
        [[NSUserDefaults standardUserDefaults] setBool:paused forKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, [Props global].appID]];
        [self performSelectorOnMainThread:@selector(updateStatusLabel) withObject:nil waitUntilDone:NO];
    }
}


- (void) resumeDownloadNotification:(NSNotification*) theNotification {
    
    //NSLog(@"LIBRARYCELL.resumeDownloadNotification");
    paused = FALSE;
}


- (void) pauseDownload {
    
    NSLog(@"LIBRARYCELL.pauseDownload");
    NSNumber *guide = [NSNumber numberWithInt:[Props global].appID];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPauseGuideDownload object:guide];
    //[[NSNotificationCenter defaultCenter] postNotificationName:kUpdateWaitStatuses object:nil];
    pauseButton.hidden = TRUE;
    resumeButton.hidden = FALSE;
    paused = TRUE;
    [[NSUserDefaults standardUserDefaults] setBool:paused forKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, [Props global].appID]];
    [self setNeedsLayout];
}


- (void) resumeDownload {
    
    NSLog(@"LIBRARYCELL.resumeDownload");
    NSNumber *guide = [NSNumber numberWithInt:[Props global].appID];
    [[NSNotificationCenter defaultCenter] postNotificationName:kResumeGuideDownload object:guide];
    //[[NSNotificationCenter defaultCenter] postNotificationName:kUpdateWaitStatuses object:nil];
    pauseButton.hidden = FALSE;
    resumeButton.hidden = TRUE;
    paused = FALSE;
    [[NSUserDefaults standardUserDefaults] setBool:paused forKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, [Props global].appID]];
    [self setNeedsLayout];
}

/*
 - (void) updateRemoveOfflineImagesButtonTitle {
 
 float offlineImageSize = [[lastStatus objectForKey:@"image size for removal"] floatValue];
 NSLog(@"LIBRARYCELL.updateRemoveOfflineImagesButtonTitle: offline images are %f MB", offlineImageSize);
 
 NSString *removeTitle;
 
 if (offlineImageSize > 10) removeTitle = [NSString stringWithFormat:@"Remove offline photos (%0.0f MB)", offlineImageSize];
 else if (offlineImageSize > 1) removeTitle = [NSString stringWithFormat:@"Remove offline photos (%0.1f MB)", offlineImageSize];
 else removeTitle = [NSString stringWithFormat:@"Remove offline photos (%0.2f MB)", offlineImageSize];
 
 [removeOfflineImagesButton setTitle:removeTitle forState:UIControlStateNormal];
 }*/


- (void) updateStatusLabel {
    
    //cancelImageDownloadButton.hidden = TRUE; //easier to make this true by default and then only show it when appropriate
    //statusLabel.hidden = FALSE;
    
    NSString *statusLabelEnding;
    if (readyForViewing) statusLabelEnding = @"(Ready to view)";
    else statusLabelEnding = @"(Not ready to view)";
    
    if (paused) {
        
        if (readyForViewing) statusLabel.text = [NSString stringWithFormat:@"Download paused %@", statusLabelEnding];
        else statusLabel.text = @"Download paused - tap arrow to resume";
    }
    
    else if (!connectedToInternet) statusLabel.text = [NSString stringWithFormat:@"Waiting for internet %@", statusLabelEnding];
    
    else statusLabel.text = [NSString stringWithFormat:@"%@ %@", currentTask, statusLabelEnding];
    
    //NSLog(@"LIBRARYCELL.updateStatusLabel: Status label = %@ and paused = %@", statusLabel.text, paused ? @"TRUE" : @"FALSE");
    
    [statusLabel setNeedsDisplay];
}


- (void) updateInternetConnectivity {
    
    if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable){
        
        if (connectedToInternet) {
            connectedToInternet = FALSE;
            [self performSelectorOnMainThread:@selector(updateStatusLabel) withObject:nil waitUntilDone:NO];
        }
    }
    
    else if (!connectedToInternet) {
        
        connectedToInternet = TRUE;
        [self performSelectorOnMainThread:@selector(updateStatusLabel) withObject:nil waitUntilDone:NO];
    }
}


@end

