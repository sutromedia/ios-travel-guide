//
//  DownloadStatus.h
//  TheProject
//
//  Created by Tobin1 on 8/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SlideController;

@interface DownloadStatus : UIView {
	
	SlideController *controller;
	UIProgressView	*downloadProgress;
	UILabel			*statusLabel;
	NSTimer			*updateTimer;
	UIButton		*hideButton;
	int				numberDownloaded;
	int				lastNumberDownloaded;
	int				totalNumber;
	int				noProgressCounter;
}


- (id)initWithFrame:(CGRect)frame andController:(SlideController*) theController;
- (void) setActive;
- (void) setInactive;
- (void) show;
- (void) hide; 


//@property (nonatomic, retain)	SlideController *controller;
@property (nonatomic) int totalNumber;


@end
