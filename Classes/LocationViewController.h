/*

File: LocationViewController.h
Abstract: Controller for single location views.

Version: 1.0

*/

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <iAD/iAD.h>

@class	Entry;
@class	DetailView;
@class	LocationManager;
@class  EntriesTableViewController;
@class  SMPitch;
@class	YouTubePlayer;
@class	SMRichTextViewer;


@interface LocationViewController : UIViewController <UIPickerViewDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate,UIScrollViewDelegate, UIGestureRecognizerDelegate, ADBannerViewDelegate> {
	
	Entry						*entry;
	UIScrollView				*detailScrollView; 
	DetailView					*detailView;
	SMPitch						*pitch;
	UIBarButtonItem				*originalBackButton;
	SMRichTextViewer			*richTextViewer;
	BOOL						canLoadNextPage;
    BOOL                        changingTopBar;
    
    CGPoint                     lastOffset;
	
	//Private variables
	EntriesTableViewController	*__unsafe_unretained controller;
    NSOperationQueue            *operationQueue;
	UIImage						*titleBarImage_portrait;
	UIImage						*titleBarImage_landscape;
	NSURL						*appURL;
	NSURL						*iTunesURL;
	NSMutableArray				*entryHistory;
	YouTubePlayer				*videoPlayer;
	NSTimer						*refreshTimer;
	NSDate						*scrollPastTime;
    NSDate                      *loadTimer;
	float						scrollCounter;
	float						lastScrollPosition;
	int							counter;
    int                         entryLoadingCounter; //used for performance testing
	int							targetAppID;
	int							titleLabelTag;	
	BOOL						scrollOffsetHasReset;
	BOOL						showGoToTopButton;
	BOOL						goToNextEntry;
	BOOL						goToPreviousEntry;
	BOOL						canScrollToPrevious;
	BOOL						canScrollToNext;
	BOOL						entryLoaded;
	BOOL						shouldScrollTableView;
	BOOL						goToNextOrPreviousEntry;
}


@property (nonatomic, strong)	Entry				*entry;
@property (nonatomic, strong)   NSOperationQueue    *operationQueue;
@property (nonatomic, strong)	SMPitch				*pitch;
@property (assign)				BOOL				moving;
@property (nonatomic, strong)	UIScrollView		*detailScrollView;
@property (nonatomic, strong)	SMRichTextViewer	*richTextViewer;
@property (assign)				BOOL				showGoToTopButton;
@property (assign)				BOOL				canScrollToPrevious;
@property (assign)				BOOL				canScrollToNext;
@property (assign)				BOOL				goToNextOrPreviousEntry;

//iAd properties
@property (nonatomic, strong) ADBannerView *adView;
@property (nonatomic) BOOL adBannerIsVisible;


- (id)initWithController: (EntriesTableViewController*) theTableViewController;
- (void) detailViewSetContentHeight: (float) height;
- (void) showTopView: (id) sender; 
- (void)showPics:(id)sender;
- (void)callThem;
- (void) showTwitterPage;
- (NSString*) processURLStringForDisplay:(NSString*) retVal;
- (NSString*) consistifyURLStringForUse: (NSString*) inconsistentURL;
- (UIImage*)resizedImage1:(UIImage*)inImage  inRect:(CGRect)thumbRect;
- (void) loadURL:(NSURL*) theURL;
- (void) downloadIcon;
- (void) showOrHideBars;
- (void) loadVideoWithoutYouTubePlayer;

@end
