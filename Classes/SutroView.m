/*
 
 
 Version: 1.7
 */


#import "SutroView.h"
#import "Entry.h"
#import "Constants.h"
#import "ActivityLogger.h"
#import "SMLog.h"
#import "Props.h"
#import "LocationViewController.h"
#import "SMRichTextViewer.h"
#import "EntryCollection.h"
#import "Comment.h"
#import "SMPitch.h"
#import "MyStoreObserver.h"
#import "Reachability.h"


#define kBetweenListingSpace 3

@interface SutroView (PrivateMethods)

- (void) addBackgroundGradient;
- (int) drawMainImage;
- (int) drawFilmStripUnderLayAtYPosition: (int) theYPosition;
- (int) drawTextDescriptionAtYPosition: (int) theYPosition;
- (int) drawTagsAtYPosition: (int) theYPosition;
- (int) drawComments:(NSArray *) theComments atYPosition:(int)theYPosition includeTrailingSeparator:(BOOL) includeTrailingSeparator;
- (int) drawCommentAndFavoritesButtonsAtYPosition: (int) theYPosition;
- (float) drawImageUnderlayAtYPosition: (float) theYPosition;


@end


@implementation SutroView

@synthesize showEntireDescription;

// initialize the view, calling super and setting the  properties to nil

- (id)initWithFrame:(CGRect)frame  andEntry:(Entry*) myEntry andLocationViewController:(LocationViewController*) myViewController{
    
    self = [super initWithFrame:frame];
    if (self) {
		
		entry				= nil;
		viewController		= nil;
        refreshViewTimer    = nil;
		y_Position			= 0;
		showEntireDescription = FALSE;
		tagsViewTag			= 1;
		buttonBarViewTag	= 2;
		descriptionViewTag	= 3;
		commentsViewTag		= 4;
		appPitchViewTag		= 5;
		
		drawCount = 0;
		
		viewController = myViewController;
		entry = myEntry;
		self.clearsContextBeforeDrawing = FALSE;
		self.opaque = TRUE;
		
		self.backgroundColor = [Props global].entryViewBGColor;
		font				= [Props global].bodyFont;
        
        if ([Props global].appID == 1) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeLoadingAnimation:) name:kTransactionComplete object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeLoadingAnimation:) name:kTransactionInitiated object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeLoadingAnimation:) name:kTransactionFailed object:nil];
        }
	}
    return self;
}


- (void)dealloc {
	
	NSLog(@"Sutroview.dealloc:");
    
    if (refreshViewTimer != nil) {
        [refreshViewTimer invalidate];
        refreshViewTimer = nil;
    }
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	self.viewController = nil;
	//self.entry = nil;
}


- (void)drawRect:(CGRect)rect {
	
	//NSLog(@"SUTROVIEW.drawRect: rtv frame height at start = %f", viewController.richTextViewer.frame.size.height);
	
	int entryHeight = 0; //Used to workaround bug with methods returning weird values when used directly
	
	if (drawCount == 0 || y_Position == [Props global].titleBarHeight ) {
		
		[self addBackgroundGradient];
		
		if (viewController.canScrollToPrevious) {
            y_Position = [self drawScrollToPreviousEntryViews];
            y_Position += [Props global].titleBarHeight;
        }
        
        else y_Position = [Props global].titleBarHeight;
        
        //y_Position = [Props global].titleBarHeight;
		
		
		// draw film strip underlay
		entryHeight = [self drawFilmStripUnderLayAtYPosition:y_Position];
		y_Position += entryHeight;
        
        // draw the distance and price underlay if it's not an upgrade or about sutro entry
		if (entry.entryid >= 0) y_Position = [self drawImageUnderlayAtYPosition: y_Position] + [Props global].tweenMargin;
		
		// draw the tagline if necessary
		if ([entry.tagline length] > 0) {
			//NSLog(@"SUTROVIEW.drawRect:About to draw tagline");
			entryHeight = [self drawTagLineAtYPosition: y_Position];
			y_Position += entryHeight + [Props global].tweenMargin;
		}
		
		
		heightAfterTagline = y_Position;
		//NSLog(@"yPos after tagline = %i", y_Position);
	}
	
	if ((drawCount == 0) && entry.descriptionHTMLVersion == 0 && entry.entryid != -1) {
		
		// draw text description
		entryHeight = [self drawTextDescriptionAtYPosition: heightAfterTagline];
		y_Position = heightAfterTagline + entryHeight + [Props global].tweenMargin;
	}
    
    
    // show the rich text block if available
	if(entry.descriptionHTMLVersion == 1 || entry.entryid == -1){
		
		if (y_Position > 0) {
			entryHeight = (int)[self drawRichTextAtYPosition: y_Position];
			if(drawCount == 1) y_Position += entryHeight + [Props global].tweenMargin;
			
			//NSLog(@"yPos after rich text = %i", y_Position);
		}
	}
	
	else if ([[self.entry getFilterArray] count] > 0) {
		
		entryHeight = [self drawTagsAtYPosition: y_Position];
		if(drawCount == 1) y_Position += entryHeight + [Props global].tweenMargin; 	
		//NSLog(@"YPos after adding tags = %i", y_Position);
	}
	
	
	//need to draw buttons only after first loading webview once - there probably is a better way to do this. 
	if(drawCount == 1) {
		
		// draw the app pitch
		//entryHeight = [self drawAppPitchAtYPosition:y_Position];
		//y_Position += entryHeight;
		
		
		NSArray *comments = [entry createCommentsArray];
		
		if ([comments count] > 0) {
			entryHeight = [self drawComments:comments atYPosition: y_Position includeTrailingSeparator: YES];
			y_Position += entryHeight + [Props global].tweenMargin;
		}
				
		/*if ([[self.entry getFilterArray] count] > 0) {
			NSLog(@"About to draw regular filters yPos = %i", y_Position);
			entryHeight = [self drawTagsAtYPosition: y_Position];
			y_Position += entryHeight + [Props global].tweenMargin; 	
			//NSLog(@"YPos after adding tags = %i", y_Position);
		}
		
		else y_Position += [Props global].tweenMargin;*/
		
		//y_Position += [Props global].tweenMargin - kBetweenListingSpace;
		
		//draw the comment and favorite buttons
		//make sure that these buttons appear at the bottom of the screen for really short entries
		//if (viewController.canScrollToPrevious && y_Position < [Props global].screenHeight + kTopScrollGraphicHeight - 61) y_Position = [Props global].screenHeight + kTopScrollGraphicHeight - 61;
		//else if (!viewController.canScrollToPrevious && y_Position < [Props global].screenHeight - 61) y_Position = [Props global].screenHeight - 61;
        
        if (viewController.canScrollToPrevious && y_Position < [Props global].screenHeight + kTopScrollGraphicHeight) y_Position = [Props global].screenHeight + kTopScrollGraphicHeight;
		else if (!viewController.canScrollToPrevious && y_Position < [Props global].screenHeight) y_Position = [Props global].screenHeight;
		
		//entryHeight = [self drawCommentAndFavoritesButtonsAtYPosition: y_Position];
		//y_Position += entryHeight;
		
		//if (y_Position < [Props global].screenHeight - kTitleBarHeight + 10) y_Position = [Props global].screenHeight - kTitleBarHeight;
		
		if (viewController.canScrollToNext) y_Position = [self drawScrollToNextEntryViewsAtYPosition:y_Position];
		
		//if (y_Position < [Props global].screenHeight + kTopScrollGraphicHeight) y_Position = [Props global].screenHeight + kTopScrollGraphicHeight;
	}
	
	if(showEntireDescription) {
		
		for (UIView *subview in [self subviews]) {
			if (subview.tag == descriptionViewTag) {
				[subview removeFromSuperview];
			}
		}
		
		entryHeight = [self drawTextDescriptionAtYPosition: heightAfterTagline];
		y_Position = heightAfterTagline + entryHeight + [Props global].tweenMargin;

		
		for (UIView *subview in [self subviews]) {
			if (subview.tag == commentsViewTag) {
				subview.center = CGPointMake(subview.center.x, y_Position + subview.frame.size.height/2);
				y_Position += subview.frame.size.height + [Props global].tweenMargin;
			}
		}
		
		//NSLog(@"Y position before tags = %i", y_Position);
		
		for (UIView *subview in [self subviews]) {
			if (subview.tag == tagsViewTag) {
			
				subview.center = CGPointMake(subview.center.x, y_Position + subview.frame.size.height/2);
				
				y_Position += subview.frame.size.height + [Props global].tweenMargin;
			}
		}
		
		if (y_Position < [Props global].screenHeight + kTopScrollGraphicHeight) y_Position = [Props global].screenHeight + kTopScrollGraphicHeight;
		
		/*for (UIView *subview in [self subviews]) {
			if (subview.tag == buttonBarViewTag) {
				subview.center = CGPointMake(subview.center.x, y_Position + subview.frame.size.height/2);
				y_Position += subview.frame.size.height;
			}
		}*/
		
		//NSLog(@"Y position after button bar = %i", y_Position);
		
		for (UIView *subview in [self subviews]) {
			if (subview.tag == kNextPageViewTag) {
				subview.center = CGPointMake(subview.center.x, y_Position + subview.frame.size.height/2);
				y_Position += subview.frame.size.height;
			}
		}
	}
	
	//NSLog(@"yPos at end = %i", y_Position);
	
	[viewController detailViewSetContentHeight: y_Position];
	
	drawCount ++;
	//NSLog(@"SUTROVIEW.drawRect: rtv frame height at end = %f", viewController.richTextViewer.frame.size.height);
}


- (void) addBackgroundGradient {
	
	UIImage *theImage= [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"background_gradient" ofType:@"png"]];
	UIImageView *imageViewer = [[UIImageView alloc] initWithImage:theImage];
	imageViewer.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight * .2);
	[self addSubview:imageViewer];
}


- (void) refreshFilmStrip:(NSTimer*) timer {
    
    int theYPosition = [timer.userInfo intValue];
    [self drawFilmStripUnderLayAtYPosition:theYPosition];
    
    refreshViewTimer = nil;
}


- (int)drawFilmStripUnderLayAtYPosition: (int) theYPosition {
	
	NSLog(@"SUTROVIEW.drawFilmStripUnderlayAtYPosition: yPostion = %i", theYPosition);
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	float minBorderWidth = 2;
	NSMutableArray *buttonArray = [NSMutableArray new];
    
    //Create image array
    //NSMutableArray *imageArray = [[NSMutableArray alloc] initWithArray: entry.demoEntryImages];
    NSArray *imageArray = entry.demoEntryImages;
    
    //int numberOfImages = [Props global].deviceType == kiPad ? 18 : 10;
    //NSLog(@"%@ has %i demo entry images", entry.name, [imageArray count]);
    int firstRowEstimate = [Props global].screenWidth/80;
    
    if ([imageArray count] < firstRowEstimate && [[Reachability sharedReachability] internetConnectionStatus] != NotReachable) {
        NSLog(@"Setting refresh timer");
        refreshViewTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshFilmStrip:) userInfo:[NSNumber numberWithInt:theYPosition] repeats:NO];
        doNotShowSecondRow = TRUE;
    }
	
	float imageHeight = [[Props global] inLandscapeMode] ? [Props global].screenWidth/8 : [Props global].screenWidth/4;
    if ([Props global].appID == 1 && imageHeight > 100) imageHeight = 100;
    float minimumImageWidth = imageHeight/3;
	float imageY = (float)theYPosition;
    
    float cumulativeRowWidth = 0;
    float borderWidth1 = 0;
    float borderWidth2 = 0;
    float imageX1 = 0;
    float imageX2 = 0;
    int theCounter = 0;
    int row1ImageCount = 0;
    float totalWidth = 0;
    float firstImageWidth = 0;
    
    //Put all of the images in an array as buttons and figure out the space between them
    for (NSNumber *imageName in imageArray) {
		
		UIImage *theImage;
		theImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i", [imageName intValue]] ofType:@"jpg"]];
		
		if (theImage == nil) {
			NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i.jpg",[Props global].contentFolder , [imageName intValue]];
			//NSLog(@"Looking for image at %@", theFilePath);
			theImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
		}
		
		if (theImage == nil) {
			NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i_768.jpg",[Props global].contentFolder , [imageName intValue]];
			//NSLog(@"Looking for image at %@", theFilePath);
			theImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
		}
        
        if (theImage == nil) {
            //NSLog(@"Looking for %i at %@", [imageName intValue], [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100",[imageName intValue]] ofType:@"jpg"]);
			theImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100",[imageName intValue]] ofType:@"jpg"]];
		}
        
        if (theImage == nil) {
            NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , [imageName intValue]];
			//NSLog(@"Looking for image at %@", theFilePath);
			theImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
		}
		
		if (theImage != nil) {
			
            CGRect imageRect = CGRectMake(0, 0, theImage.size.width/theImage.size.height * imageHeight, imageHeight);
            
            UIButton *imageButton = [UIButton buttonWithType:0];
            [imageButton setImage:theImage forState:UIControlStateNormal];
			imageButton.frame = imageRect;
            imageButton.tag = [imageName intValue];
            [imageButton addTarget:viewController action:@selector(goToImageEntry:) forControlEvents:UIControlEventTouchUpInside];
			
            [buttonArray addObject:imageButton];
            
            float buttonWidth = imageButton.frame.size.width;
            
            //NSLog(@"Cumulative row width = %0.0f, buttonWidth = %0.0f, counter = %i", cumulativeRowWidth, buttonWidth, theCounter);
            
            if (cumulativeRowWidth + buttonWidth < [Props global].screenWidth) {
                totalWidth += buttonWidth + minBorderWidth;
                cumulativeRowWidth += buttonWidth + minBorderWidth;
                theCounter ++;
                if (firstImageWidth == 0) firstImageWidth = buttonWidth;
            }
            
            else { //This image goes past edge of screen
                if (borderWidth1 == 0) { //We're still on the first row
                    
                    if (cumulativeRowWidth + minimumImageWidth/2 < [Props global].screenWidth) { //squeeze this image onto the row
                    
                        cumulativeRowWidth += buttonWidth;
                        borderWidth1 = minBorderWidth;
                        float extra = [Props global].screenWidth - cumulativeRowWidth;
                        imageX1 = extra/2 * (firstImageWidth/buttonWidth); //take a proportionally equal amount off first and last image
                        cumulativeRowWidth = 0; //reset for next row
                        theCounter ++;
                    }
                    
                    else { //Don't try to squeeze image on and just balance border widths
                        //subtract off the last image border, as it should be full bleed to edge
                        cumulativeRowWidth -= minBorderWidth * theCounter;
                        totalWidth -= minBorderWidth * theCounter;
                        imageX1 = 0;
                        
                        borderWidth1 = ([Props global].screenWidth - cumulativeRowWidth)/(theCounter - 1);
                        cumulativeRowWidth = buttonWidth; //add this button to the second row
                    }
                    
                    row1ImageCount = theCounter;
                    firstImageWidth = 0;
                    totalWidth += buttonWidth;
                    theCounter = 0;
                }
                
                else  {
                    
                    if (cumulativeRowWidth + buttonWidth * .25 < [Props global].screenWidth) { //squeeze this image onto the row
                        
                        cumulativeRowWidth += buttonWidth;
                        
                        borderWidth2 = minBorderWidth;
                        float extra = [Props global].screenWidth - cumulativeRowWidth;
                        imageX1 = extra/2 * (firstImageWidth/buttonWidth); //take a proportionally equal amount off first and last image
                        cumulativeRowWidth = 0; //reset for next row
                    }
                    
                    break; //set borderWidth2 below to avoid having the same code in two places
                }
            }
		}
        
        else NSLog(@"%i not found *****************************************", [imageName intValue]);
	}
    
    
    //NSLog(@"Border width1 = %0.1f, borderWidth2 = %0.2f, imageX1 = %0.1f, imageX2 = %0.2f, counter = %i, totalWidth = %0.0f, row1ImageCount = %i", borderWidth1, borderWidth2, imageX1, imageX2, theCounter, totalWidth, row1ImageCount);
    
    if (borderWidth2 == 0) {
        imageX2 = 0;
        cumulativeRowWidth -= minBorderWidth * theCounter;
        //totalWidth -= minBorderWidth * theCounter;
        
        if (theCounter > 1) borderWidth2 = ([Props global].screenWidth - cumulativeRowWidth)/(theCounter - 1);
        else { //unlikely scenario where only one image fits on a row
            borderWidth2 = ([Props global].screenWidth - cumulativeRowWidth)/2;
        }
    }
    
    //Need to create the only one row scenario
    
    //Actually draw the images now
    int cumulativeRow1Count = 0;
    cumulativeRowWidth = 0;
    BOOL canDoSecondRow = (borderWidth2 < minBorderWidth * 14) && refreshViewTimer == nil && !doNotShowSecondRow;
    
    //NSLog(@"Can do second row = %@, borderWidth 2 = %0.0f && row1ImageCount = %i", canDoSecondRow ? @"TRUE" : @"FALSE", borderWidth2, row1ImageCount);
    
    for (UIButton *imageButton in buttonArray) {
        
        if (cumulativeRow1Count == row1ImageCount) cumulativeRowWidth = 0;
        
        float imageX;
        float imageWidth = imageButton.frame.size.width;
        
        if (cumulativeRow1Count < row1ImageCount || row1ImageCount == 0) {
            
            if (cumulativeRowWidth == 0) {
                
                imageX = imageX1;
                cumulativeRowWidth = (imageX + imageWidth + borderWidth1);
            }
            
            else {
                imageX = cumulativeRowWidth;
                cumulativeRowWidth += imageWidth + borderWidth1;
            }
                
            cumulativeRow1Count ++;
        }
        
        else if (canDoSecondRow) {
            
            if (cumulativeRowWidth == 0) {
                
                imageX = imageX2;
                imageY += imageHeight;
                cumulativeRowWidth = (imageX + imageWidth + borderWidth2);
                cumulativeRow1Count ++;
            }
            
            else if (cumulativeRowWidth > [Props global].screenWidth) break;
            
            else {
                imageX = cumulativeRowWidth;
                
                cumulativeRowWidth += imageWidth + borderWidth2;
            }
        }
        
        else break;
        
        CGRect frame = CGRectMake(imageX, imageY, imageWidth, imageButton.frame.size.height);
        imageButton.frame = frame;
        
        [self addSubview:imageButton];
    }
    

    //[pool release];
    
    return (int) ((imageY + imageHeight) - theYPosition);
}


- (float) drawImageUnderlayAtYPosition: (float) theYPosition {
	
	float underlayHeight = 23;
	
	// draw underlay
	UIImage *underlayImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"underlayBar" ofType:@"png"]];
	
	CGRect underlayBarRect = CGRectMake(0, theYPosition - 1, [Props global].screenWidth, underlayHeight);
	UIImageView *underlayImageViewer = [[UIImageView alloc] initWithImage:underlayImage];
	underlayImageViewer.frame = underlayBarRect;
	[self addSubview:underlayImageViewer];
	
    
	
	CGRect imageUnderlayLabelRect = CGRectMake(0, theYPosition + 2, [Props global].screenWidth, underlayHeight - 4);
	
	NSString *labelText = [[NSString alloc] initWithFormat:@"%i entries             %i photos", entry.numberOfEntries, entry.numberOfPhotos];
	
	UILabel *imageUnderlayLabel = [[UILabel alloc] initWithFrame:imageUnderlayLabelRect];
	imageUnderlayLabel.backgroundColor = [UIColor clearColor];
	imageUnderlayLabel.textColor = [UIColor whiteColor];
	imageUnderlayLabel.font = font;
	
	imageUnderlayLabel.text = labelText;
	imageUnderlayLabel.textAlignment = UITextAlignmentCenter;
	
	[self addSubview:imageUnderlayLabel];
	
	
	return CGRectGetMaxY(underlayBarRect);
}



- (int) drawTextDescriptionAtYPosition: (int) theYPosition {
	
	int textBoxWidth = [Props global].screenWidth - ([Props global].leftMargin + [Props global].rightMargin);
	UIFont *descriptionFont = font;
	
	NSString *descriptionString = entry.description; 
	CGSize textBoxSizeMax	= CGSizeMake(textBoxWidth, 10000); // height value does not matter as long as it is larger than height needed for text box
	
	float reducedTextBoxHeight = [[Props global] inLandscapeMode] && [Props global].deviceType != kiPad ? [Props global].screenHeight - 220 : [Props global].screenHeight - 320;
	
	CGSize textBoxSize = [descriptionString sizeWithFont:descriptionFont constrainedToSize: textBoxSizeMax lineBreakMode: 0];
	
	if (!showEntireDescription && textBoxSize.height > reducedTextBoxHeight)
		textBoxSize = CGSizeMake(textBoxWidth, reducedTextBoxHeight);
		
	CGRect descriptionRect = CGRectMake ([Props global].leftMargin, theYPosition, textBoxWidth, textBoxSize.height);
	
	UILabel *descriptionLabel = [[UILabel alloc] initWithFrame: descriptionRect];
	descriptionLabel.backgroundColor = [UIColor clearColor];
	descriptionLabel.numberOfLines = 0;
	descriptionLabel.textColor = [Props global].descriptionTextColor;
	descriptionLabel.font = descriptionFont;
	descriptionLabel.text = descriptionString;
	descriptionLabel.textAlignment = UITextAlignmentLeft;
	descriptionLabel.tag = descriptionViewTag;
	
	[self addSubview:descriptionLabel];
	
	
	if (!showEntireDescription && textBoxSize.height == reducedTextBoxHeight) {
	
		UIButton *seeMoreButton = [UIButton buttonWithType:0];
		seeMoreButton.frame = CGRectMake([Props global].screenWidth - [Props global].leftMargin - 190, CGRectGetMaxY(descriptionLabel.frame), 190, font.pointSize + 1);
		seeMoreButton.titleLabel.font = [UIFont boldSystemFontOfSize:font.pointSize - 2];
		seeMoreButton.titleLabel.textAlignment = UITextAlignmentRight;
		seeMoreButton.titleLabel.textColor = [Props global].linkColor;
		[seeMoreButton addTarget: viewController action:@selector(showEntireDescription:) forControlEvents:UIControlEventTouchUpInside];
		[seeMoreButton setBackgroundColor: [UIColor clearColor]];
		[seeMoreButton setTitle:@"See full description ▼" forState:UIControlStateNormal];
		[seeMoreButton setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
		seeMoreButton.tag = descriptionViewTag;
		[self addSubview:seeMoreButton];
		
		return CGRectGetHeight(descriptionRect) + CGRectGetHeight(seeMoreButton.frame) + 4;
	}
	
	else return CGRectGetHeight(descriptionRect);
}


- (int) drawComments:(NSArray *) theComments atYPosition:(int)theYPosition includeTrailingSeparator:(BOOL) includeTrailingSeparator {
	
	int height = 0;
	
	UIView *commentsPreview = [[UIView alloc] init];
	commentsPreview.tag = commentsViewTag;
	
	if([theComments count] > 0) {
		
		UIImage *divider = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"divider" ofType:@"png"]];
		
		CGRect dividerRect = CGRectMake(0, 0, [Props global].screenWidth, divider.size.height);
		UIImageView *dividerImageViewer = [[UIImageView alloc] initWithImage:divider];
		dividerImageViewer.frame = dividerRect;
		[commentsPreview addSubview:dividerImageViewer];
		
		height += CGRectGetHeight(dividerRect);// + [Props global].tinyTweenMargin;
	}
	
		
	UIImage *playIcon = [UIImage imageNamed:@"goBackComment.png"];
	CGRect buttonFrame = CGRectMake([Props global].leftMargin, height + [Props global].tinyTweenMargin, playIcon.size.width, playIcon.size.height);
	UIButton *playButton2 = [UIButton buttonWithType: 0];
	playButton2.frame = buttonFrame;
	[playButton2 addTarget:viewController action:@selector(showComments:) forControlEvents:UIControlEventTouchUpInside];
	[playButton2 setBackgroundImage:playIcon forState:normal];
	playButton2.backgroundColor = [UIColor clearColor];
	[commentsPreview addSubview:playButton2];		
	
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin + 30, CGRectGetMinY(buttonFrame), [Props global].screenWidth - CGRectGetMaxX(buttonFrame) - [Props global].leftMargin, 20)];
	titleLabel.font = font;
	titleLabel.textColor = [Props global].descriptionTextColor;		
	titleLabel.backgroundColor = [UIColor clearColor];
	
	NSString * commentString = [(Comment *)[theComments objectAtIndex:0] commentText];
	/*int maxStringLength = ([Props global].screenWidth == 768) ? 80: 35; // highly arbitrary value
	if([commentString length] > maxStringLength) {
		int lastSpaceIndex = maxStringLength;
		while(lastSpaceIndex > 0 && ' ' != [commentString characterAtIndex:lastSpaceIndex]) lastSpaceIndex--;
		commentString = (lastSpaceIndex == 0) ? [commentString substringToIndex:maxStringLength] : [commentString substringToIndex:lastSpaceIndex];
	}*/
	titleLabel.text = commentString; // [NSString stringWithFormat:@"“%@…”", commentString];
	[commentsPreview addSubview:titleLabel];
	height += titleLabel.frame.size.height + [Props global].tinyTweenMargin + 1;
	
	NSString * linkText = ([theComments count] > 1) ? 
	[NSString stringWithFormat:@"View all comments (%i)", [theComments count]] : 
	[NSString stringWithFormat:@"View full comment"];
	
	CGSize maxButtonSize = CGSizeMake([Props global].screenWidth - [Props global].leftMargin * 2, 20);
	
	CGSize buttonFrameSize = [linkText sizeWithFont:[UIFont boldSystemFontOfSize:font.pointSize -2] constrainedToSize: maxButtonSize lineBreakMode: 0];
	
	UIButton * linkButton = [UIButton buttonWithType:0];
	linkButton.frame = CGRectMake([Props global].screenWidth - [Props global].leftMargin - buttonFrameSize.width, height + [Props global].tinyTweenMargin, buttonFrameSize.width, 20);
	linkButton.titleLabel.font = [UIFont boldSystemFontOfSize:font.pointSize -2];
	[linkButton setTitleColor:[Props global].linkColor forState:0];
	[linkButton setTitle:linkText forState:0];
	[linkButton addTarget:viewController action:@selector(showComments:) forControlEvents:UIControlEventTouchUpInside];
	
	linkButton.backgroundColor = [UIColor clearColor];
	linkButton.titleLabel.textAlignment = UITextAlignmentRight;
	[commentsPreview addSubview:linkButton];
	
	height += linkButton.frame.size.height + [Props global].tinyTweenMargin;
	
		
	
	if(includeTrailingSeparator) {
		
		UIImage *divider = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"divider" ofType:@"png"]];
		
		CGRect dividerRect = CGRectMake(0, height + [Props global].tinyTweenMargin, [Props global].screenWidth, divider.size.height);
		UIImageView *dividerImageViewer = [[UIImageView alloc] initWithImage:divider];
		dividerImageViewer.frame = dividerRect;
		[commentsPreview addSubview:dividerImageViewer];
		height += dividerImageViewer.frame.size.height + [Props global].tinyTweenMargin;
	}
	
	commentsPreview.frame = CGRectMake(0, theYPosition, [Props global].screenWidth, height);
	[self addSubview:commentsPreview];
    
	
	return commentsPreview.frame.size.height;
}


- (int) drawTagsAtYPosition: (int) theYPosition {
	
	//NSLog(@"SUTROVIEW.drawTagsAtYPosition:frame height at start = %f", viewController.richTextViewer.frame.size.height);
	
	float height = (viewController.richTextViewer.frame.size.height > 0) ? viewController.richTextViewer.frame.size.height : 20;
	
	viewController.richTextViewer.frame = CGRectMake (0, theYPosition, [Props global].screenWidth, height);
	
	//viewController.richTextViewer.backgroundColor = [UIColor redColor];
	viewController.richTextViewer.tag = tagsViewTag;
	[self addSubview:viewController.richTextViewer];
	
	return viewController.richTextViewer.frame.size.height;
}


@end