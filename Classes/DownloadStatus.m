//
//  DownloadStatus.m
//  TheProject
//
//  Created by Tobin1 on 8/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DownloadStatus.h"
#import "Constants.h"
#import "Props.h"
#import "Entry.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "EntryCollection.h"
#import "SlideController.h"
#import "Reachability.h"
#import "DataDownloader.h"

@interface DownloadStatus (PrivateMethods)

- (int) getTotalImageCount;
- (int) getNumberDownloadedImageCount;
- (void) remove: (id) selector;

@end


@implementation DownloadStatus

@synthesize totalNumber;
//@synthesize controller;

- (id)initWithFrame:(CGRect)frame andController:(SlideController*) theController {
    
    self = [super initWithFrame:frame];
	if (self) {
        NSLog(@"DOWNLOADSTATUS.initWithFrame: frame height = %f", frame.size.height);
        
		self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
		self.alpha = .05;
		self.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
		self.autoresizesSubviews = YES;
		controller = theController;
		updateTimer = nil;
		statusLabel = nil;
		downloadProgress = nil;
		hideButton = nil;
		noProgressCounter = 0;
		lastNumberDownloaded = 0;
		numberDownloaded = [self getNumberDownloadedImageCount];
		totalNumber = [self getTotalImageCount];
		
		if (totalNumber <= numberDownloaded || [Props global].isShellApp)[self remove:nil];
    }
    return self;
}


- (void)dealloc {
	
	NSLog(@"DOWNLOADSTATUS.dealloc: called");
	
	controller = nil;
	
	if (updateTimer != nil) {
		[updateTimer invalidate];
		updateTimer = nil;
	}
	
	if (downloadProgress != nil) {
		downloadProgress = nil;
	}
	
	if ( statusLabel != nil) {
		statusLabel = nil;
	}
	
}


- (void) drawRect:(CGRect)rect {
	
	//NSLog(@"DOWNLOADSTATUS.drawRect");
	//NSLog(@"DOWNLOADSTATUS.drawRect: downloadProgress frame x = %f, y = %f", downloadProgress.frame.origin.x, downloadProgress.frame.origin.y);
	CGRect hideButtonFrame = CGRectZero;
	
	if (hideButton == nil) {
		UIImage *icon = [UIImage imageNamed:@"xButton.png"];
		hideButtonFrame = CGRectMake(CGRectGetMaxX(self.frame) - icon.size.width/2 - [Props global].rightMargin, (self.frame.size.height - icon.size.height/2)/2, icon.size.width/2, icon.size.height/2);
		hideButton = [UIButton buttonWithType:0];
		hideButton.alpha = .4;
		[hideButton setBackgroundImage: icon forState:UIControlStateNormal];
		hideButton.frame = hideButtonFrame;
		[hideButton addTarget:self action:@selector(removeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		hideButton.backgroundColor = [UIColor clearColor];
		[self addSubview:hideButton];
	}
	
	CGRect statusLabelFrame = CGRectMake([Props global].leftMargin, kTopMargin * .5, CGRectGetMinX(hideButtonFrame) - [Props global].leftMargin - [Props global].rightMargin, 17);
	
	if (statusLabel == nil) {
		//NSLog(@"DOWNLOADSTATUS.drawRect: creating statusLabel");
		statusLabel = [[UILabel alloc] initWithFrame:statusLabelFrame];
		statusLabel.adjustsFontSizeToFitWidth = YES;
		statusLabel.textAlignment = UITextAlignmentCenter;
		statusLabel.font = [UIFont systemFontOfSize:13];
		statusLabel.minimumFontSize = 10;
		statusLabel.alpha = .7;
		statusLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		statusLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:statusLabel];
	}
	
	if (downloadProgress == nil) {
		
		downloadProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		downloadProgress.frame = CGRectMake([Props global].leftMargin, CGRectGetMaxY(statusLabelFrame) + [Props global].tinyTweenMargin, statusLabelFrame.size.width, 20);
		downloadProgress.alpha = .5;
		downloadProgress.backgroundColor = [UIColor clearColor];
		[self addSubview:downloadProgress];
	}
	
	downloadProgress.progress = (float) numberDownloaded/ (float) totalNumber;
	
	[statusLabel setNeedsDisplay];
	[downloadProgress setNeedsDisplay];
}


- (void) setActive {

	NSLog(@"DOWNLOADSTATUS.setActive");
	if (updateTimer != nil) {
		[updateTimer invalidate];
		updateTimer = nil;
	}
	
	updateTimer = [NSTimer scheduledTimerWithTimeInterval: 1 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
}
	

- (void) setInactive {
	
	//NSLog(@"DOWNLOADSTATUS.setInactive");
	if (updateTimer != nil) {
		[updateTimer invalidate];
		updateTimer = nil;
	}
}

- (void) removeButtonPressed:(id) sender {

	[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kDownloadStatusHidden];
	[self remove:nil];
}

- (void) remove: (id) selector {
	
	//NSLog(@"DOWNLOADSTATUS.remove");
	if (updateTimer != nil) {
		[updateTimer invalidate];
		updateTimer = nil;
	}
	
	[self hide];
	
	[NSTimer scheduledTimerWithTimeInterval: 0.3 target:controller selector:@selector(destroyDownloadStatus:) userInfo:nil repeats:NO];
}

- (void) hide {
	
	//NSLog(@"DOWNLOADSTATUS.hide");
	float animationDuration = .3;
	
	[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
	[ UIView setAnimationDuration: animationDuration ]; // Set the duration
	
	self.frame = CGRectOffset(self.frame, 0, self.frame.size.height);
	
	[ UIView commitAnimations ];
	
	[self setInactive];
	[self performSelector:@selector(hideView) withObject:nil afterDelay:animationDuration];
}


- (void) show {
	
	//NSLog(@"DOWNLOADSTATUS.show");
	float animationDuration = .3;
	
	self.hidden = FALSE;
	[self setActive];
	
	[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
	[ UIView setAnimationDuration: animationDuration ]; // Set the duration
	
	self.frame = CGRectOffset(self.frame, 0, -self.frame.size.height);
	
	[ UIView commitAnimations ];
}


- (void) hideView { self.hidden = TRUE;}


- (void) updateProgress: (id) sender {

	//NSLog(@"DOWNLOADSTATUS.updateProgress: updating");
	numberDownloaded = [self getNumberDownloadedImageCount];
	NSLog(@"DOWNLOADSTATUS.updateProgress: numberDownloaded = %i, total = %i", numberDownloaded, totalNumber);
		
	if (numberDownloaded == lastNumberDownloaded) noProgressCounter ++;
	else lastNumberDownloaded = numberDownloaded;
	
	
	if ((noProgressCounter > 10 && controller.entry != nil) || noProgressCounter > 30){
		NSLog(@"DownloadStatus.updateProgress: getting rid of progress indicator, since no progress is being made");
		[self remove:nil];
	}
	
	else if (numberDownloaded >= totalNumber && totalNumber != 0) {
		
		statusLabel.text = @"All photos downloaded";
		self.hidden = FALSE;
		if (controller.entry == nil) [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kDownloadStatusHidden];
	}
		
	else if([[Reachability sharedReachability] internetConnectionStatus] == NotReachable)
		statusLabel.text = [NSString stringWithFormat:@"No internet. %i %@images awaiting download.", totalNumber - numberDownloaded, [Props global].deviceType == kiPad ? @"full size " : @""];
	
	else if (numberDownloaded == 0){
		//NSLog(@"DOWNLOADSTATUS.updateProgress:hiding download status with number downloaded = %i", numberDownloaded);
		self.hidden = TRUE;
	}
	
	//else if (noProgressCounter > 30) statusLabel.text = @"Problem downloading images - will try again next time.";
	
	else {
		self.hidden = FALSE;
		statusLabel.text = [NSString stringWithFormat:@"Downloading %i of %i %@images ...", numberDownloaded, totalNumber, [Props global].deviceType == kiPad ? @"full size " : @""];
		//NSLog(@"DOWNLOADSTATUS.updateProgress:unhiding download bar and setting text to %@", statusLabel.text);
	}
		
	[self setNeedsDisplay];
}


- (int) getNumberDownloadedImageCount {
	
	int count = 0;
	
	NSString *query;
	int photoSize = ([Props global].deviceType == kiPad) ? 768 : 320;
	
	if (controller.entry == nil) query = [NSString stringWithFormat:@"SELECT count(rowid) AS thecount from photos WHERE downloaded_%ipx_photo > 0", photoSize];
		
	else query = [NSString stringWithFormat:@"SELECT count(photos.rowid) AS thecount from photos, entries, entry_photos WHERE downloaded_%ipx_photo > 0 AND entry_photos.entryid = %i AND entry_photos.photoid = photos.rowid AND entry_photos.entryid = entries.rowid", photoSize, controller.entry.entryid];
	
	//NSLog(@"DOWNLOADSTATUS.getNumberDownloadedImageCount: query = %@", query);
	FMDatabase * db = [EntryCollection sharedContentDatabase];
    
	@synchronized([Props global].dbSync) {
		
		FMResultSet * rs = [db executeQuery:query];
		
		if ([rs next]) count = [rs intForColumn:@"thecount"];
		
		[rs close];
	}
	//NSLog(@"DOWNLOADSTATUS.getNumberDownloadedImageCount: count = %i", count);
	
	return count;
}


- (int) getTotalImageCount {
	
	int count = 0;
	
    //Where clause to first query added for sutro world with demo entries to avoid counting demo entries in photo count
	NSString *query1 = (controller.entry == nil) ? @"SELECT count(DISTINCT photos.rowid) AS thecount from photos, entry_photos WHERE entry_photos.awesome = 1 AND entry_photos.photoid = photos.rowid" : [NSString stringWithFormat: @"SELECT count(photos.rowid) AS thecount from photos, entry_photos, entries WHERE entry_photos.entryid = %i AND entry_photos.photoid = photos.rowid AND entry_photos.entryid = entries.rowid", controller.entry.entryid];
	
    FMDatabase * db1 = [EntryCollection sharedContentDatabase];
    
	@synchronized([Props global].dbSync) {
		
		FMResultSet * rs1 = [db1 executeQuery:query1];
		
		if ([db1 hadError]) NSLog(@"sqlite error in [DataDownloader createImageArray], query = %@, %d: %@", query1, [db1 lastErrorCode], [db1 lastErrorMessage]);
		
		if (![rs1 next]) NSLog(@"DOWNLOADSTATUS.getTotalImageCount - no rows in result set");
		
		else count = [rs1 intForColumn:@"thecount"];
		
		[rs1 close];
	}
	
	//NSLog(@"DOWNLOADSTATUS.getTotalImageCount: returning %i total images", count);
	 
	return count;
}


@end
