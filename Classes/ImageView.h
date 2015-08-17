//
//  ImageView.h
//
//  Created by Tobin1 on 11/24/09.
//  Copyright 2009 Sutro Media. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAD/iAD.h>

@class SlideController, ASIHTTPRequest;


@interface ImageView : UIView <ADInterstitialAdDelegate> {
    
    //Image			*image;
	UIImage			*imageFile;
	UIButton		*entryNameButton;
	SlideController	*slideController;
	CGRect			imageFrame;
	float			rowHeight;
	int				imageId;
	int				currentImageId;
	int				firstImageIndex;
	int				lastImageIndex;
	int				currentImageIndex;
	int				pageNumber;
	NSString		* author;
	NSString		* imageName;
	NSString		* license;
	NSString		* hyperlink;
	NSString		* caption;
	NSString		* name;
	int				imageLabelsTag;
	BOOL			thumbnailMode;
	BOOL			isGoingForward;
	SlideController *controller;
	NSNumber		*__unsafe_unretained startingImageObject;
    ASIHTTPRequest  *request;
    
    ADInterstitialAd *interstitialAd;
}

//@property (nonatomic, retain) Image		*image;
//@property (nonatomic, retain) SlideController *slideController;
//@property (nonatomic, retain) NSNumber *imageId;
@property (nonatomic, strong) NSString	*imageName;
@property (nonatomic, strong) NSString	*author;
@property (nonatomic, strong) NSString	*license;
@property (nonatomic, strong) NSString	*hyperlink;
@property (nonatomic, strong) NSString	*name;
@property (nonatomic, strong) NSString	*caption;
@property (unsafe_unretained, nonatomic) NSNumber	*startingImageObject;
//@property (nonatomic, retain) UIButton  *entryNameButton;
@property (nonatomic)			int		firstImageIndex;
@property (nonatomic)			int		lastImageIndex;
@property (nonatomic)			int		pageNumber;
@property (nonatomic)			CGRect	imageFrame;
@property (nonatomic)           BOOL    canShowAd;


//- (id)initWithImageId:(NSNumber*)theImageId andController:(SlideController*) theSlidecontroller;
//- (id)initWithStartingImageId:(NSNumber*)theStartingImageObject direction:(BOOL) _goingForward thumbnailMode:(BOOL) _thumbNailMode andController:(SlideController*) theSlidecontroller;
//- (id)initWithFrame:(CGRect) frame goingForward:(BOOL) _isGoingForward thumbnailMode:(BOOL) _thumbNailMode imageId:(NSNumber*) theImageId andController:(SlideController*) theSlidecontroller;
- (id) initWithPageNumber:(int) thePageNumber andController:(SlideController*) theSlideController;
- (void) updateLabels;
- (void) hideLabels;
- (void) showLabels;
- (void) updateTitleLabelPosition;

@end

