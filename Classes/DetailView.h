/*

Abstract: Displays the overview screen for a given entry.

Version: 1.7

*/

#import <UIKit/UIKit.h>


@class Entry;
@class LocationViewController, SMPitch;


@interface DetailView : UIScrollView {
	Entry					*__unsafe_unretained entry;
	LocationViewController	*__unsafe_unretained viewController;
	int						contentHeight;
	UIFont					*font;
	UIImageView				*scrollToPreviousEntryView;
	CGRect					imageFrame2;
	CGPoint					gestureStartPoint;
	UIImageView				*scrollToEntryView;
	UIImageView				*fakeTopBar;
    UIImageView             *viewToRotate;
    UIImageView             *backgroundHolder;
    UIImageView             *imageHolder;
    UIWebView               *theGuidesList;
    //UILabel                 *loadingTag;
	CGRect					mapFrame;
    //CGRect                  imageFrame;
	float					touchTime;
	int						y_Position;
	int						drawCount;
	BOOL					animating;
	BOOL					createMapIcon;
    BOOL                    canReplaceImage;
}

@property (nonatomic, unsafe_unretained)    Entry					*entry;
@property (nonatomic, unsafe_unretained)	LocationViewController	*viewController;
@property (nonatomic, strong)                       UIImageView             *imageHolder;
@property (nonatomic, strong)                       UIImageView				*fakeTopBar;
@property (nonatomic)                       int						drawCount;
@property (nonatomic)                       BOOL					createMapIcon;
@property (nonatomic)                       CGRect					mapFrame;
@property (nonatomic)                       BOOL					animating;
@property (nonatomic, strong)                       UIWebView               *theGuidesList;


- (id)initWithFrame:(CGRect)frame  andEntry:(Entry*) myEntry andLocationViewController: (LocationViewController*) myLocationViewController;
- (void) flipScrollIcon:(NSString*) iconToFlipCode direction:(NSString*) theDirection;
- (float) drawScrollToNextEntryViewsAtYPosition:(float) theYPosition;
- (float) drawScrollToPreviousEntryViews;
- (int) drawTagLineAtYPosition: (int) theYPosition;
- (int) drawRichTextAtYPosition: (int) theYPosition;
- (void) redrawForNewOrientation;
- (void) createLoadingAnimation;

@end
