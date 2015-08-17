//
//  SlideController.h
//  PageControl
//
//  Created by Tobin1 on 11/24/09.
//  Copyright 2009 Sutro Media. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@class ImageView, Entry, FilterButton;

@interface SlideController : UIViewController <UIScrollViewDelegate, UITableViewDelegate, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate> {
	
	UIScrollView		*scrollView;
	ImageView			*previousSlide;
	ImageView			*nextSlide;
	ImageView			*currentSlide;
    ImageView           *rotationOverlay;
	NSMutableArray		*imageArray;
	NSMutableArray		*updateArray;
	NSMutableArray		*firstImageIndex;
	//DownloadStatus		*downloadStatus;
	Entry				*entry;
	UISegmentedControl	*slideModeControl;
//  UIViewController    *rotationOverlay;
	
	NSTimer				*slideShowTimer;
	NSTimer				*fadeControlsTimer;
	NSTimer				*touchTimer;
	NSTimer				*updateTimer;
	NSTimer				*hideBarsTimer;
	
	UIButton			*cancelButton;
	NSString			*filterCriteria;
	NSString			*lastFilterChoice;
	CGRect				screenRect;
	float				thumbnailRowWidth;
	float				thumbnailRowHeight;
	//int					downloadCounter;
	int					currentPage;
	int					maxImageIndex;
	int					tmpCounter; //Used as an ugly workaround to prevent view from being redrawn on startup
    int                 totalNumberOfImages;
	BOOL				visible;
	BOOL				deviceCanShowThumbnails;
	BOOL				userControllingMotion;
	BOOL				filterPickerShowing;
	BOOL				playing;
	BOOL				viewDidJustAppear;
	BOOL				viewDidJustAppear2;
	BOOL				resetingContentSize;
	BOOL				showingThumbnails;
	BOOL				settingUpSlideshow;
    BOOL                upgradePitchHidden;
    BOOL                thumbnailViewEnabled;
    BOOL                showSlideshowUpgradePitch;
    int                 roughNumberOfThumbnailsPerPage;
	
}


@property (nonatomic, strong)	FilterButton		*pickerSelectButton;
@property (nonatomic, strong)	NSMutableArray		*imageArray;
@property (nonatomic, strong)	NSString			*filterCriteria;
@property (nonatomic, strong)	NSString			*lastFilterChoice;
//@property (nonatomic, strong)	UIButton			*cancelButton;
@property (nonatomic, strong)	Entry				*entry;
@property (nonatomic)			BOOL				playing;
@property (nonatomic)			BOOL				showingThumbnails;
@property (nonatomic)           BOOL                showSlideshowUpgradePitch;
@property (nonatomic)           int                 roughNumberOfThumbnailsPerPage;
@property (nonatomic, strong)	NSTimer				*touchTimer;
@property (nonatomic, strong)	NSMutableArray		*firstImageIndex;


- (id) initWithEntry:(Entry *)theEntry;
- (void) initImageArray;
- (void) playPauseSlideshow:(id) sender;
- (void) pauseSlideshow;
- (void) hideOrShowTopAndBottomBars:(id) sender;
- (void) addSlideToIndex:(ImageView*) slide; 
- (int) getFirstImageIndexForPageNumber:(int) thePageNumber;
- (void) removeUpgradePitch;

	
@end
