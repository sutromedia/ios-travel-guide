//
//  LibraryCell.m
//  TheProject
//
//  Created by Tobin1 on 5/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LibraryCell.h"
#import "Entry.h"
#import "Props.h"
#import "Reachability.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "MyStoreObserver.h"



#define kStopDownloadTag 23452635
#define kRemoveImagesTag 90872345
#define kSampleViewTag	89763425
#define kProgressIndicatorTag 9872345

@interface LibraryCell (Private)

- (void) updateDownloadProgress: (NSNotification*) theStatus;
- (void) updateStatusLabel;
- (void) pauseDownload;
- (void) updateSizeText;
- (void) updateDownloadImagesButtonTitle;
- (void) updateProgressView:(NSDictionary*) theStatus;
- (void) removeOfflineImages;
- (void) stopDownloadingOfflineImages;
- (void) setBuyButtonTitle;
//- (void) updateRemoveOfflineImagesButtonTitle;

@end


@implementation LibraryCell

@synthesize entry;
//@synthesize entryTileView;
@synthesize downloader;
@synthesize downloading;
@synthesize waiting;
@synthesize height;
//@synthesize labelView, authorLabelView, downloadProgressLabel, downloaded, noInternetMessage, downloader, waitingMessage, waiting;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		entry = nil;
        connectedToInternet = TRUE;
        self.contentView.opaque = NO;
        currentTask = @"";
        self.height = [Props global].tableviewRowHeight_libraryView;
		//**offlineImagesDownloaded = FALSE;
        lastStatus = nil;
        deleteButton = nil;
        
        //****** Top Row ***********
        titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.minimumFontSize = 12;
		titleLabel.adjustsFontSizeToFitWidth = TRUE;
        float fontSize = [Props global].deviceType == kiPad ? 17 : 14;
        titleLabel.font =  [UIFont boldSystemFontOfSize: fontSize];
        titleLabel.textColor = [UIColor colorWithWhite:0.15 alpha:0.95];
        [self.contentView addSubview:titleLabel];
		
        //****** Second Row ********
        float subtitleFontSize = [Props global].deviceType == kiPad ? 13 : 10;
        UIFont *subtitleFont = [UIFont fontWithName:kFontName size:subtitleFontSize];
        
        authorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		authorLabel.backgroundColor = [UIColor clearColor];
        float byLineFontSize = [Props global].deviceType == kiPad ? 15 : 12;
		authorLabel.font = [UIFont fontWithName:kFontName size:byLineFontSize];
		authorLabel.textAlignment = UITextAlignmentLeft;
		authorLabel.textColor = [Props global].LVEntrySubtitleTextColor;
        [self.contentView addSubview:authorLabel];
        
        /*lastUpdateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		lastUpdateLabel.backgroundColor = [UIColor clearColor];
		lastUpdateLabel.font = [UIFont fontWithName:kFontName size:byLineFontSize];
		lastUpdateLabel.textAlignment = UITextAlignmentLeft;
		lastUpdateLabel.textColor = [Props global].LVEntrySubtitleTextColor;
        [self.contentView addSubview:lastUpdateLabel];*/
		
        downloadProgressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		downloadProgressLabel.backgroundColor = [UIColor clearColor];
		downloadProgressLabel.font = subtitleFont;
		downloadProgressLabel.textAlignment = UITextAlignmentLeft;
		downloadProgressLabel.textColor = [Props global].LVEntrySubtitleTextColor;
        downloadProgressLabel.text = @"0.0 of ? MB";
        downloadProgressLabel.alpha = .95;
        [self.contentView addSubview:downloadProgressLabel];
        
        downloadProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        downloadProgress.alpha = .5;
        downloadProgress.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:downloadProgress];
        
        
        //****** Third row **********
        statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        statusLabel.backgroundColor = [UIColor clearColor];
        statusLabel.font = subtitleFont;
        statusLabel.text = @"";
        statusLabel.textAlignment = UITextAlignmentLeft;
        statusLabel.textColor = [Props global].LVEntrySubtitleTextColor;
        statusLabel.alpha = .95;
        [self.contentView addSubview: statusLabel];
        
        
        //***** Buttons ***************
        float inset = 12;
        UIEdgeInsets insets = UIEdgeInsetsMake(inset, inset, inset, inset); 
        pauseButton = [UIButton buttonWithType:0];
        pauseButton.imageEdgeInsets = insets;
        //pauseButton.frame = buttonFrame;
        [pauseButton addTarget:self action:@selector(pauseDownload) forControlEvents:UIControlEventTouchUpInside];
        [pauseButton setImage:[UIImage imageNamed:@"pause_download.png"] forState:UIControlStateNormal];
        pauseButton.backgroundColor = [UIColor clearColor];
        //pauseButton.alpha = 0.95;
        [self.contentView addSubview:pauseButton];
        
        resumeButton = [UIButton buttonWithType:0];
        resumeButton.imageEdgeInsets = insets;
        //resumeButton.frame = buttonFrame;
        [resumeButton addTarget:self action:@selector(resumeDownload) forControlEvents:UIControlEventTouchUpInside];
        [resumeButton setImage:[UIImage imageNamed:@"resume_download.png"] forState:UIControlStateNormal];
        resumeButton.backgroundColor = [UIColor clearColor];
        //resumeButton.alpha = 0.95;
        [self.contentView addSubview:resumeButton];
        
        
		static NSMutableArray *colors2 = nil;
		
		if (colors2 == nil) {
			colors2 = [[NSMutableArray alloc] initWithCapacity:3];
			UIColor *color = nil;
			color = [UIColor colorWithRed:(31.0/255.0) green:(101.0/255.0) blue:(136.0/255.0) alpha:1.0];
			[colors2 addObject:(id)[color CGColor]];
			//color = [UIColor colorWithWhite:0.0 alpha:0.425];
			//[colors2 addObject:(id)[color CGColor]];
			color = [UIColor colorWithRed:0.0 green:(74.0/255.0) blue:(115.0/255.0) alpha:1.0];
			[colors2 addObject:(id)[color CGColor]];
		}
		
		CAGradientLayer *buttonBackground = [[CAGradientLayer alloc] init];
		//NSLog(@"Y pos for gradient layer = %f", self.frame.origin.y);
		buttonBackground.colors = colors2;
		buttonBackground.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.4], [NSNumber numberWithFloat:0.6], nil];
		buttonBackground.shadowColor = [UIColor blackColor].CGColor;
		buttonBackground.shadowOpacity = 0.3;
		buttonBackground.shadowOffset = CGSizeMake(0, 1.5);
		buttonBackground.shadowRadius = 0.1;
		buttonBackground.cornerRadius = 8;
		buttonBackground.borderColor = [UIColor colorWithRed:(15.0/255.0) green:(86.0/255.0) blue:(125.0/255.0) alpha:0.9].CGColor;
		buttonBackground.borderWidth = 1;
		
		buyButton = [UIButton buttonWithType:0];
        [buyButton addTarget:self action:@selector(buyGuide) forControlEvents:UIControlEventTouchUpInside];
        buyButton.backgroundColor = [UIColor clearColor];
		buyButton.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
		buyButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
		buyButton.titleLabel.shadowColor = [UIColor darkGrayColor];
        [buyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [buyButton setTitleColor:[UIColor lightGrayColor] forState:UIControlEventTouchDown];
        //[buyButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        buyButton.hidden = TRUE;
		[buyButton.layer insertSublayer:buttonBackground atIndex:0];
        [self.contentView addSubview:buyButton];

        
        //******* Background and images ********
        
        UIImageView *selectedImageView = [[UIImageView alloc] initWithImage:[Props global].LVBGView_selected];
        selectedImageView.frame = CGRectMake(0,0, [Props global].screenWidth, [Props global].tableviewRowHeight_libraryView);
        self.selectedBackgroundView = selectedImageView;
        
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[Props global].LVBGView];
        backgroundImageView.frame = CGRectMake(0,0, [Props global].screenWidth, [Props global].tableviewRowHeight_libraryView);
        backgroundImageView.alpha = .70;
        self.backgroundView = backgroundImageView;

        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseDownloadNotification:) name:kPauseGuideDownload object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeDownloadNotification:) name:kResumeGuideDownload object:nil];
        
        connectivityChecker = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateInternetConnectivity) userInfo:nil repeats:YES];
        
        UIGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe)];
        [self addGestureRecognizer:swipeRecognizer];
        swipeRecognizer.delegate = self;
	}
    
    return self;
}


- (void)dealloc {
    
    if (connectivityChecker != nil) [connectivityChecker invalidate];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}


- (void)layoutSubviews {
    
    //NSLog(@"LIBARYCELL.layoutSubviews: Guide id = %i", entry.entryid);
    
    [super layoutSubviews];

    BOOL showingDeleteButton = deleteButton != nil && !deleteButton.hidden;
    
    float label_origin_x = [Props global].tableviewRowHeight_libraryView + [Props global].leftMargin;
    float title_label_height = titleLabel.font.pointSize + 2;
	
    if (downloading && !showingDeleteButton) {
        
        [self updateStatusLabel];
        float subtitleY = [Props global].tableviewRowHeight_libraryView * .39;
        
        titleLabel.frame = CGRectMake(label_origin_x, 5, [Props global].screenWidth - self.frame.size.height - [Props global].rightMargin - 35, title_label_height);
        
        authorLabel.hidden = TRUE;
        downloadProgressLabel.hidden = FALSE;
        statusLabel.hidden = FALSE; 
        downloadProgress.hidden = FALSE;
        pauseButton.hidden = paused;
        resumeButton.hidden = !paused;
		buyButton.hidden = TRUE;
        
        if (paused && [[lastStatus objectForKey:@"download offline images"] intValue] == 1) {
        
            statusLabel.hidden = TRUE;
        }
        
        downloadProgress.frame = CGRectMake(titleLabel.frame.origin.x, subtitleY + 5, titleLabel.frame.size.width * .5, 18);
        downloadProgressLabel.frame = CGRectMake(CGRectGetMaxX(downloadProgress.frame) + 8, subtitleY, titleLabel.frame.size.width * .4, 18);
        
        statusLabel.frame = CGRectMake(titleLabel.frame.origin.x, [Props global].tableviewRowHeight_libraryView * .7, self.frame.size.width - titleLabel.frame.origin.x, 16);
        
        
        float inset = resumeButton.imageEdgeInsets.left;
        CGRect buttonFrame = CGRectMake(CGRectGetMaxX(self.frame) - self.frame.size.height + (inset - 5), 0, self.frame.size.height, self.frame.size.height);
        resumeButton.frame = buttonFrame;
        pauseButton.frame = buttonFrame;
    }
	
    else if (!showingDeleteButton) {
        statusLabel.hidden = TRUE;
        downloadProgress.hidden = TRUE;
        downloadProgressLabel.hidden = TRUE;
        pauseButton.hidden = TRUE;
        resumeButton.hidden = TRUE;
        authorLabel.hidden = FALSE;
        
        //isSample = [[MyStoreObserver sharedMyStoreObserver] isGuideFreeSample:entry.entryid];
        //NSLog(@"%@ %@ a sample", entry.name, isSample ? @"is" : @"is not");
        
        if (isSample) {
            
            buyButton.hidden = FALSE;
            float button_width = [Props global].deviceType == kiPad ? 80 : 55;
            float button_height = self.frame.size.height * 0.6;
            buyButton.frame = CGRectMake(self.frame.size.width - button_width - [Props global].leftMargin, (self.frame.size.height - button_height)/2,button_width, button_height);
            for (CALayer *layer in [buyButton.layer sublayers]) {
                layer.bounds = buyButton.bounds;
                layer.position = CGPointMake([buyButton bounds].size.width/2, [buyButton bounds].size.height/2); 
            } 
			//buttonBackground.bounds = buyButton.bounds;
			//buttonBackground.position = CGPointMake([buyButton bounds].size.width/2, [buyButton bounds].size.height/2);
			
            titleLabel.frame = CGRectMake(label_origin_x, self.frame.size.height * .2, buyButton.frame.origin.x - self.frame.size.height - [Props global].rightMargin * 2, title_label_height);
            authorLabel.frame =  CGRectMake(titleLabel.frame.origin.x, self.frame.size.height * .5, titleLabel.frame.size.width, 18);
        }
        
        else {
            buyButton.hidden = TRUE;
            titleLabel.frame = CGRectMake(label_origin_x, self.frame.size.height * .2, [Props global].screenWidth - self.frame.size.height - [Props global].rightMargin - 35, title_label_height);
            authorLabel.frame =  CGRectMake(titleLabel.frame.origin.x, self.frame.size.height * .5, titleLabel.frame.size.width, 18);
			
			[[self.contentView viewWithTag:kSampleViewTag] removeFromSuperview];
        }
    }
    
    else {
        
        buyButton.hidden = TRUE;
        pauseButton.hidden = TRUE;
        resumeButton.hidden = TRUE;
        statusLabel.hidden = TRUE;
        
        float button_width = 55;
        float button_height = self.frame.size.height * 0.6;
        deleteButton.frame = CGRectMake(self.frame.size.width - button_width - [Props global].leftMargin, (self.frame.size.height - button_height)/2,0, button_height);
        for (CALayer *layer in [deleteButton.layer sublayers]) {
            layer.bounds = deleteButton.bounds;
            layer.position = CGPointMake([deleteButton bounds].size.width/2, [deleteButton bounds].size.height/2); 
        }
		
		//Animation not currently working - fix me!
		//[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
		//[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
		//[ UIView setAnimationDuration: 4.0f ];
		
		deleteButton.frame = CGRectMake(deleteButton.frame.origin.x, deleteButton.frame.origin.y, 55, deleteButton.frame.size.height);
		for (CALayer *layer in [deleteButton.layer sublayers]) {
            layer.bounds = deleteButton.bounds;
            layer.position = CGPointMake([deleteButton bounds].size.width/2, [deleteButton bounds].size.height/2);
        }
		
		titleLabel.frame = CGRectMake(titleLabel.frame.origin.x, titleLabel.frame.origin.y, deleteButton.frame.origin.x - self.frame.size.height - [Props global].rightMargin * 2, title_label_height);
        authorLabel.frame =  CGRectMake(titleLabel.frame.origin.x, authorLabel.frame.origin.y, titleLabel.frame.size.width, 18);
		
		//[UIView commitAnimations];
    }    
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
        
        if (!downloading || downloadProgress.hidden) {
            downloading = TRUE;
            [self layoutSubviews];
        }
        
        NSLog(@"LIBRARYCELL.updateProgressView: %@ amountDownloaded = %0.1f, total = %0.0f, currentTask = %@, status = %i", entry.name, amountDownloaded, total, newCurrentTask, [[theStatus objectForKey:@"summary"] intValue]);
        
        if (newCurrentTask != nil && newCurrentTask != currentTask) {
            NSLog(@"Updating current task for %i to %@", entry.entryid, newCurrentTask);
            currentTask = newCurrentTask;
            
            [self updateStatusLabel];
        }
        
        //NSLog(@"LIBRARYCELL.updateProgressView: %i total = %f, current = %0.1f, download progress = %0.3f", entry.entryid, total, amountDownloaded, downloadProgress.progress);
        
        float fraction = total > 0 ? amountDownloaded/total : 0;
        
        //The progress contin
        if (!paused || downloadProgress.progress < 0.01 /*make sure to set download progress if we're just starting*/) {
            downloadProgress.progress = fraction;
            downloadProgressLabel.text = total > 0 ? [NSString stringWithFormat:@"%0.1f of %0.0f MB", amountDownloaded, total] : @"0.0 of ? MB";
        }
        
        //NSLog(@"Download progress text = %@", downloadProgressLabel.text);
        
        if ([[theStatus objectForKey:@"summary"] intValue] == kDownloadComplete || fraction > 1) {
            
            //**[self updateDownloadImagesButtonTitle];
            //[self updateRemoveOfflineImagesButtonTitle];
            downloading = FALSE;
            
            //**offlineImagesDownloaded = [[theStatus objectForKey:@"download offline images"] intValue] == 1 ? TRUE : FALSE; //Note, the value of this bool in the status only means that offline images should be downloaded. But this and the summary being download complete means that they also have been downlaoded
            
            //NSLog(@"LIBRARYCELL.updateProgressView: %i is downloaded and offline images %@ downloaded", entry.entryid, offlineImagesDownloaded ? @"are" : @"are not");
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


- (void)setEntry:(Entry *)anEntry {
	
    //NSLog(@"LIBRARYCELL.setEntry");
    
	if (anEntry != entry) {
		entry = anEntry;
	}
    
    isSample = [[MyStoreObserver sharedMyStoreObserver] isGuideFreeSample:entry.entryid];
    
    if (isSample) {
		NSString *samplePurchasedNotification = [NSString stringWithFormat:@"%@_%i", kSampleGuidePurchased, entry.entryid];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sampleUpgraded) name:samplePurchasedNotification object:nil];
		
		NSString *key = [NSString stringWithFormat:@"%@_%i", kTransactionFailed, entry.entryid];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionFailed) name:key object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setBuyButtonTitle) name:kUpdateBuyButton object:nil];
		
		[self setBuyButtonTitle];
    }
    
    
    //************** Add app icon to cell *****************************
    UIImageView *iconImage = [[UIImageView alloc] initWithImage:entry.iconImage];
    iconImage.frame = CGRectMake(0, 0, [Props global].tableviewRowHeight_libraryView, [Props global].tableviewRowHeight_libraryView);
    [self.contentView addSubview:iconImage];
    
	if (isSample) {
		UIImageView *sampleOverlay = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sample_overlay.png"]];
		sampleOverlay.frame = iconImage.frame;
		sampleOverlay.tag = kSampleViewTag;
		[self.contentView addSubview:sampleOverlay];
	}
	
	else if (entry.entryid == 3) {
		UIImageView *sampleOverlay = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"free_guide_overlay.png"]];
		sampleOverlay.frame = iconImage.frame;
		[self.contentView addSubview:sampleOverlay];
	}
	
	
    //**************** Update buttons and titles as necessary ************************
	titleLabel.text = entry.name;
    authorLabel.text = [NSString stringWithFormat:@"By %@", entry.pitchAuthor]; // @"By John Smith";
	
	//[titleLabel setNeedsDisplay];
    
    [self updateStatusLabel];
    
    //**[self updateDownloadImagesButtonTitle];
    
    //[self updateRemoveOfflineImagesButtonTitle];
    
    //************** Update state based on saved defaults **************************
    //Get latest saved status from user defaults
    paused = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, entry.entryid]];
    
    NSDictionary *theStatus = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, entry.entryid]];
    [self updateProgressView: theStatus];
  
    
    //Register to recieve future updates when available from downloader
    NSString *notificationName = [NSString stringWithFormat:@"%@_%i", kUpdateDownloadProgress, entry.entryid];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloadProgress:) name:notificationName object:nil];
}


- (void) sampleUpgraded {
    
    isSample = FALSE;
    [self layoutSubviews];
}


- (void) setBuyButtonTitle {
	
    [[buyButton viewWithTag:kProgressIndicatorTag] removeFromSuperview];
    
	NSString *price = [[MyStoreObserver sharedMyStoreObserver] getPriceForGuideId:entry.entryid];
	NSString* title;
	
	if (price != NULL) {
        
        if ([Props global].deviceType == kiPad){
            
            title = [NSString stringWithFormat:@"BUY:\n%@", price];
            [buyButton.titleLabel setFont:[UIFont boldSystemFontOfSize:13]];
        }
        
        else {
            title = [NSString stringWithFormat:@"BUY: %@", price];
            [buyButton.titleLabel setFont:[UIFont boldSystemFontOfSize:11]];
        }
        
		
	}
	
	else {
		title = @"BUY";
		[buyButton.titleLabel setFont:[UIFont boldSystemFontOfSize:12]];
	}
	
	[buyButton setTitle:title forState:UIControlStateNormal];
}

/*
- (void) updateDownloadImagesButtonTitle {
    
    float offlineImageSize = [[lastStatus objectForKey:@"image size for download"] floatValue];
    
    //NSLog(@"LIBRARYCELL.updateDownloadImagesButtonTitle: Image size = %f", offlineImageSize);
    
    if (offlineImageSize > 0.1) {
        NSString *downloadButtonTitle;
        
        if (offlineImageSize > 10) downloadButtonTitle = [NSString stringWithFormat:@"Download offline photos (%0.0f MB)", offlineImageSize];
        else if (offlineImageSize > 1) downloadButtonTitle = [NSString stringWithFormat:@"Download offline photos (%0.1f MB)", offlineImageSize];
        else downloadButtonTitle = [NSString stringWithFormat:@"Download offline photos (%0.2f MB)", offlineImageSize];
        
        //NSLog(@"LIBRARYCELL.updateDownloadImagesButtonTitle: New title = %@", downloadButtonTitle);
        [downloadImagesButton setTitle:downloadButtonTitle forState:UIControlStateNormal];
    }
    
    else {
        
        offlineImagesDownloaded = TRUE;
        downloadImagesButton.hidden = TRUE;
        removeOfflineImagesButton.hidden = FALSE;
    }

}*/

/*
- (void) downloadOfflineImages {
    
    NSLog(@"LIBRARYCELL.downloadOfflineImages");
    
    if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Looks like you don't have an internet connection. You'll need one to download content." delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:nil];   
		
		[alert show];  
		[alert release];
    }
    
    else {
        downloading = TRUE;
        paused = FALSE;
        
        NSDictionary *theStatus = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%i", kDownloadStatusKey, entry.entryid]];
        
        float total = [[theStatus objectForKey:@"total"] floatValue];
        float amountDownloaded = [[theStatus objectForKey:@"current"] floatValue];
        
        float fraction = amountDownloaded/total;
    
        downloadProgress.progress = fraction;
        downloadProgressLabel.text = total > 0 ? [NSString stringWithFormat:@"%0.1f of %0.0f MB", amountDownloaded, total] : @"0.0 of ? MB";
        [downloadProgress setNeedsDisplay];
        [downloadProgressLabel setNeedsDisplay];
        
        [[NSUserDefaults standardUserDefaults] setBool:paused forKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, entry.entryid]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadOfflineImages object:[NSNumber numberWithInt:entry.entryid]];
        [self setNeedsLayout];
    }
}
*/



- (void) pauseDownloadNotification:(NSNotification*) theNotification {
    
    if (theNotification.object == nil || [theNotification.object intValue] == entry.entryid) {
        
        NSLog(@"LIBRARYCELL.pauseDownloadNotification: %i", entry.entryid);
        paused = TRUE;
        pauseButton.hidden = TRUE;
        resumeButton.hidden = FALSE;
        [[NSUserDefaults standardUserDefaults] setBool:paused forKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, entry.entryid]];
        [self performSelectorOnMainThread:@selector(updateStatusLabel) withObject:nil waitUntilDone:NO];
    }
}


- (void) resumeDownloadNotification:(NSNotification*) theNotification {
    
    //NSLog(@"LIBRARYCELL.resumeDownloadNotification");
    paused = FALSE;
}


- (void) pauseDownload {
    
    NSLog(@"LIBRARYCELL.pauseDownload: Guide ID = %i", entry.entryid);
    NSNumber *guide = [NSNumber numberWithInt:entry.entryid];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPauseGuideDownload object:guide];
    //[[NSNotificationCenter defaultCenter] postNotificationName:kUpdateWaitStatuses object:nil];
    pauseButton.hidden = TRUE;
    resumeButton.hidden = FALSE;
    paused = TRUE;
    [[NSUserDefaults standardUserDefaults] setBool:paused forKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, entry.entryid]];
    [self setNeedsLayout];
}


- (void) resumeDownload {
    
     NSLog(@"LIBRARYCELL.resumeDownload: Guide ID = %i", entry.entryid);
    NSNumber *guide = [NSNumber numberWithInt:entry.entryid];
    [[NSNotificationCenter defaultCenter] postNotificationName:kResumeGuideDownload object:guide];
    //[[NSNotificationCenter defaultCenter] postNotificationName:kUpdateWaitStatuses object:nil];
    pauseButton.hidden = FALSE;
    resumeButton.hidden = TRUE;
    paused = FALSE;
    [[NSUserDefaults standardUserDefaults] setBool:paused forKey:[NSString stringWithFormat:@"%@_%i", kPauseStatusKey, entry.entryid]];
    [self setNeedsLayout];
}


- (void) updateStatusLabel {
    
    //cancelImageDownloadButton.hidden = TRUE; //easier to make this true by default and then only show it when appropriate
    //statusLabel.hidden = FALSE;
    
    if (paused) {
        statusLabel.text = @"Download paused - tap arrow to resume";
        statusLabel.textColor = [UIColor blackColor];
    }
    
    else if (!connectedToInternet) {
        statusLabel.text = [NSString stringWithFormat:@"Waiting for internet"];
        statusLabel.textColor = [UIColor blackColor];
    }
    
    else {
       statusLabel.text = [NSString stringWithFormat:@"%@", currentTask]; 
        statusLabel.textColor = [Props global].LVEntrySubtitleTextColor;
    }
    
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


- (void) buyGuide {
    
    [[MyStoreObserver sharedMyStoreObserver] upgradeSamplePurchaseForGuideId:entry.entryid];
	
	float ind_height = 22;
	UIActivityIndicatorView *progressInd = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, ind_height, ind_height)];
	progressInd.tag = kProgressIndicatorTag;
	progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
	[progressInd sizeToFit];
	progressInd.center = CGPointMake(buyButton.frame.size.width/2, buyButton.frame.size.height/2);
	[progressInd startAnimating];
	[buyButton setTitle:@"" forState:UIControlStateNormal];
	[buyButton addSubview: progressInd];
    buyButton.enabled = FALSE;
}


- (void) transactionFailed {
	
    NSLog(@"LIBRARYCELL.transactionFailed");
    buyButton.enabled = TRUE;
	[self setBuyButtonTitle];
}


- (void) didSwipe {
    
    NSLog(@"I got swiped");
    
    if (deleteButton == nil) [self makeDeleteButton];
	
	UIGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
	[self addGestureRecognizer:tapRecognizer];
	tapRecognizer.delegate = self;

    deleteButton.hidden = FALSE;

    [self setNeedsLayout];
}


- (void) didTap: (UIGestureRecognizer*) gestureRecognizer {
	
	NSLog(@"I got taped");
    CGPoint touchLocation = [gestureRecognizer locationInView:self.contentView];
    
    if (touchLocation.x >= deleteButton.frame.origin.x && touchLocation.y >= deleteButton.frame.origin.y) {
        [self deleteGuide];
    }
	
    else {
        if (deleteButton.hidden == FALSE) {
            
            deleteButton.hidden = TRUE;
            
            [self setNeedsLayout];
        }
        
        [self removeGestureRecognizer:gestureRecognizer];
    }
}


- (void) makeDeleteButton {
    
    //******* Add delete button ***********
    static NSMutableArray *colors3 = nil;
    
    if (colors3 == nil) {
        colors3 = [[NSMutableArray alloc] initWithCapacity:3];
        UIColor *color = nil;
        color = [UIColor colorWithRed:(244.0/255.0) green:(147.0/255.0) blue:(150.0/255.0) alpha:1.0];
        [colors3 addObject:(id)[color CGColor]];
        //color = [UIColor colorWithWhite:0.0 alpha:0.425];
        //[colors2 addObject:(id)[color CGColor]];
        color = [UIColor colorWithRed:(207.0/255.0) green:(43.0/255.0) blue:(45.0/255.0) alpha:1.0];
        [colors3 addObject:(id)[color CGColor]];
    }
    
    CAGradientLayer *deleteButtonBackground = [[CAGradientLayer alloc] init];
    //NSLog(@"Y pos for gradient layer = %f", self.frame.origin.y);
    deleteButtonBackground.colors = colors3;
    deleteButtonBackground.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.4], [NSNumber numberWithFloat:0.6], nil];
    deleteButtonBackground.shadowColor = [UIColor blackColor].CGColor;
    deleteButtonBackground.shadowOpacity = 0.3;
    deleteButtonBackground.shadowOffset = CGSizeMake(0, -1.5);
    deleteButtonBackground.shadowRadius = 0.1;
    deleteButtonBackground.cornerRadius = 6;
    deleteButtonBackground.borderColor = [UIColor colorWithRed:(220.0/255.0) green:(60.0/255.0) blue:(100.0/255.0) alpha:0.9].CGColor;
    deleteButtonBackground.borderWidth = 1;
    
    deleteButton = [UIButton buttonWithType:0];
    [deleteButton addTarget:self action:@selector(deleteGuide) forControlEvents:UIControlEventTouchUpInside];
    deleteButton.backgroundColor = [UIColor clearColor];
    deleteButton.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
    deleteButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
    deleteButton.titleLabel.shadowColor = [UIColor darkGrayColor];
    deleteButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [deleteButton setTitleColor:[UIColor lightGrayColor] forState:UIControlEventTouchDown];
    [deleteButton.layer insertSublayer:deleteButtonBackground atIndex:0];
	
    if (isSample) [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    
    else [deleteButton setTitle:@"Archive" forState:UIControlStateNormal];
	
	[self.contentView addSubview:deleteButton];
}


- (void) deleteGuide {
    
    NSLog(@"Time to delete guide");
    
    deleteButton.enabled = FALSE;
    [self performSelectorInBackground:@selector(showDeletingProgressInd) withObject:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteGuide object:[NSNumber numberWithInt:entry.entryid]];
}


- (void) showDeletingProgressInd {
    
    @autoreleasepool {
        float ind_height = 22;
        UIActivityIndicatorView *progressInd = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, ind_height, ind_height)];
        progressInd.tag = kProgressIndicatorTag;
        progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        [progressInd sizeToFit];
        progressInd.center = CGPointMake(deleteButton.frame.size.width/2, deleteButton.frame.size.height/2);
        [progressInd startAnimating];
        [deleteButton setTitle:@"" forState:UIControlStateNormal];
        [deleteButton addSubview: progressInd];
    }
}

	@end
