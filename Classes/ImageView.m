//
//  ImageView.m
//
//  Created by Tobin1 on 11/24/09.
//  Copyright 2009 Sutro Media. All rights reserved.
//

#import "ImageView.h"
#import "Constants.h"
#import "Props.h"
#import "SlideController.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "EntryCollection.h"
//#import "ImageDataSource.h"
#import "UIImage+Resize.h"
#import "SMLog.h"
#import "ActivityLogger.h"
#import "Reachability.h"
#import "ASIHTTPRequest.h"
#import "SlideshowUpgradeView.h"

UIImage* resizedImage(UIImage *inImage, CGRect thumbRect);

#define kAttributionLabelHeight 20
#define kCaptionHeight 32
#define kShareIconWidth 23
#define kShareUnderlayWidth 35
#define kImageInfoHeight 30
#define kUnderlayAlpha .65
#define kAttributionAlpha .9
#define kSmallSize @"small"
#define kRegularSize @"regular"
#define kProgressIndicatorTag 2703

@interface ImageView (PrivateMethods)

//- (void) addShareButtonAtPoint:(CGPoint) thePoint andInsidePhoto:(BOOL) insidePhoto;
//- (UIImage*)resizedImage1:(UIImage*)inImage  inRect:(CGRect)thumbRect;
- (void) createAttributionLabelAtPoint:(CGPoint) thePoint andInsidePhoto:(BOOL) insidePhoto;
- (void) createCaptionLabelAtPoint:(CGPoint) thePoint;
- (void) setUpImageInfo;
- (void) addEntryNameButtonForImageFrame:(CGRect) theImageFrame;
- (BOOL) addContent;
- (UIImage*) getImageForId:(int) theImageId withSize:(NSString*) theSize;
- (UIButton*) getPhotoButtonForIndex:(int) theIndex;
- (void) downloadHigherQualityImage;

//Thumbnailview methods
- (BOOL) createPhotoRowAtYPosition:(float) theYPosition;

@end


@implementation ImageView

@synthesize startingImageObject, imageName, license, hyperlink, caption, name, author, firstImageIndex, imageFrame, lastImageIndex, pageNumber;

@synthesize canShowAd;


- (id) initWithPageNumber:(int) thePageNumber andController:(SlideController*) theSlideController {

	//NSLog(@"IMAGEVIEW.initWithPageNumber:%i and screen width = %f", thePageNumber, [Props global].screenWidth);
	
	imageFile = nil;
	imageLabelsTag = -779087149;
	slideController = theSlideController;
	thumbnailMode = slideController.showingThumbnails;
	pageNumber = thePageNumber;
    request = nil;
    self.backgroundColor = [UIColor blackColor];
	
	if(!thumbnailMode){
		
		if ([slideController.imageArray count] > 0) {
			
            /*if ([Props global].deviceType == kiPad && [Props global].showAds && pageNumber + 1 % 10 == 0) { //The plus one is to avoid showing ad for first image
                
                NSLog(@"IMAGEVIEW.initWithPageNumber: %i - time to show Ad", pageNumber);
                interstitialAd = [[ADInterstitialAd alloc] init];
                interstitialAd.delegate = self;
            }
            
            else interstitialAd = nil;*/
            
			if ([slideController.imageArray count] > 1) {
				firstImageIndex = pageNumber % [slideController.imageArray count];
				imageId = [[slideController.imageArray objectAtIndex:firstImageIndex] intValue];
			}
			
			else if (thePageNumber == 0){
				firstImageIndex = 0;
                imageId = [[slideController.imageArray objectAtIndex:firstImageIndex] intValue];
			}
			
			else return nil;
		}
		
		else {
		
			return nil;
		}
		
		lastImageIndex  = firstImageIndex;
	}
	
	else {
        
        //Top Level slideshow
        if (theSlideController.entry == nil) {
            
            if ([Props global].deviceType == kiPad){
                
                //NSString *thumbnailKeyString = [NSString stringWithFormat:@"%@_%i", kThumbnailsDownloaded, [Props global].appID];
                //BOOL thumbnailsDownloaded = [[NSUserDefaults standardUserDefaults] boolForKey:thumbnailKeyString];
                
				rowHeight = [[Props global] inLandscapeMode] ? 100 : 103; //Now that we can include a bunch of 100px photos with the app bundle, it's possible to show smaller thumbnails from the start
				
                //if(slideController.entry == nil && (thumbnailsDownloaded || [Props global].appID == 1)) rowHeight = [[Props global] inLandscapeMode] ? 100 : 103;
                
                //else rowHeight = [[Props global] inLandscapeMode] ? 205.33 : 222;
                
                /*if (slideController.entry == nil) {
                    if(thumbnailsDownloaded || [Props global].appID == 1) rowHeight = [[Props global] inLandscapeMode] ? 100 : 103;
                    
                    else rowHeight = [[Props global] inLandscapeMode] ? 205.33 : 222;
                }
                
                else {
                    if([[NSUserDefaults standardUserDefaults] boolForKey:kThumbnailsDownloaded] || [Props global].appID == 1) rowHeight = [[Props global] inLandscapeMode] ? 100 : 103;
                    
                    else rowHeight = [[Props global] inLandscapeMode] ? 205.33 : 222;
                }*/
                
            }
            
            else rowHeight = [[Props global] inLandscapeMode] ? 81.3 : 74.1;
        }
        
        //Entry level slideshow
        else {
            if ([Props global].deviceType == kiPad) rowHeight = [[Props global] inLandscapeMode] ? 221.33 : ([Props global].screenHeight - [Props global].titleBarHeight - 4* 12)/4;
            else rowHeight = [[Props global] inLandscapeMode] ? 90.63 : 83.7;
        }
        
        
        slideController.roughNumberOfThumbnailsPerPage = ([Props global].screenWidth * [Props global].screenHeight)/(rowHeight * rowHeight) * .7;
        NSLog(@"Rough number of photos per page = %i", slideController.roughNumberOfThumbnailsPerPage);
        
        firstImageIndex = [slideController getFirstImageIndexForPageNumber:thePageNumber];
    } 
	
	CGRect frame = CGRectMake([Props global].screenWidth * thePageNumber, 0, [Props global].screenWidth, [Props global].screenHeight);
	
	//NSLog(@"IMAGEVIEW.initWithPageNumber: %i Frame width = %f, height = %f, x = %f", thePageNumber, frame.size.width, frame.size.height, frame.origin.y);
	
    self = [super initWithFrame:frame];
	if(self) {
		
		if ([self addContent]) {
			[slideController addSlideToIndex:self];
			return self;
		}
		
		else return nil;
	}
	
	else return nil;
	
}


//This is necessary to prevent crashes with background threads
/*- (oneway void)release
{
    if (![NSThread isMainThread])[super performSelectorOnMainThread:@selector(release) withObject:nil waitUntilDone:NO];
    
    else [super release];
}*/


- (void)dealloc {
	
	//NSLog(@"IMAGEVIEW.dealloc");
	
	//if (imageFile != nil) [imageFile release];
	
    if(request != nil) {request.delegate = nil; [request clearDelegatesAndCancel]; request = nil;}
    
    if (interstitialAd != nil) {interstitialAd.delegate = nil;}

	//self.image = nil;
	//self.imageId = nil;
    	
	 
}


- (BOOL) addContent {
	
	NSLog(@"IMAGEVIEW.addContent for %i", imageId);
    
    //clear screen in the case that we're adding a higher resolution photo
    for (UIView *view in [self subviews]) [view removeFromSuperview];
	
    if (slideController.showSlideshowUpgradePitch && pageNumber > 1) {
        
        SlideshowUpgradeView *upgradeView = [[SlideshowUpgradeView alloc] initWithNumberOfImagesRemaining:[slideController.imageArray count] - 2];
        [self addSubview:upgradeView];
        
        self.tag = kSlideshowUpgradeViewTag;
    }
    
	else if (thumbnailMode) {
		
		float borderHeight = [Props global].deviceType == kiPad ? 12 : 2.5; //used to be 6
		float yPosition = [Props global].titleBarHeight + borderHeight;
		currentImageIndex = firstImageIndex;
		
		while (yPosition <= [Props global].screenHeight - rowHeight) {
	
			if ([self createPhotoRowAtYPosition:yPosition])
				yPosition += rowHeight + borderHeight;
			
			else break;
		}
		
		if (yPosition == [Props global].titleBarHeight + borderHeight) return FALSE;
			
	}
	
	else {
        
        UIImage *image = [self getImageForId:imageId withSize:kRegularSize];
        
        if (image == nil) return FALSE;
        
		UIImageView *imageViewer = [[UIImageView alloc] initWithImage:image];
		
        BOOL showLoadingIndicator = FALSE;
        if ((int)imageViewer.frame.size.height == 100) showLoadingIndicator = TRUE;
        
		[self setUpImageInfo];
		
		//scale image as necessary...
		float xPos;
		float yPos;
		float height;
		float width;
		//float maxScale = 2.2;
		
		float xScale = self.frame.size.width/imageViewer.image.size.width;
		float yScale = self.frame.size.height/imageViewer.image.size.height;
		
		//NSLog(@"IMAGEVIEW.addContent for %i: xScale = %f, yScale = %f", imageId, xScale, yScale);
		
		if (xScale < yScale) {
			
			//if (xScale > maxScale) xScale = maxScale;
			
			//NSLog(@"IMAGEVIEW.addContent: Should be landscape image, xScale = %f, yScale = %f", xScale, yScale);
			
			width = self.frame.size.width;
			height = imageViewer.image.size.height * xScale; 
		}
		
		else {
			//if (yScale > maxScale) yScale = maxScale;
			
			//NSLog(@"IMAGEVIEW.addContent: Should be portrait image, xScale = %f, yScale = %f", xScale, yScale);
			width = imageViewer.image.size.width * yScale;
			height = self.frame.size.height;
		}
		
		yPos = (self.frame.size.height - height)/2.3;;
		xPos = (self.frame.size.width - width)/2;
		
		
		imageViewer.frame = CGRectMake(xPos, yPos, width, height);
		imageViewer.backgroundColor = [UIColor clearColor];
		imageFrame = imageViewer.frame;
		[self addSubview:imageViewer];
		
		float attributionYPosition;
		float shareButtonYPosition;
		float captionYPosition;
		
		BOOL attributionInside;
		
		//leave a bit of extra room for space above the tab bar if we're in a top level slideshow
		float spaceAboveButtons = (slideController.entry == nil) ? 15 : 0;
		
		spaceAboveButtons += ([caption length] > 0) ? kCaptionHeight:0;
		
		if(CGRectGetMaxY(imageViewer.frame) < self.frame.size.height - kImageInfoHeight  - [Props global].tweenMargin - spaceAboveButtons) {
			
			//put attribution and share button below image if we've got enough room
			
			attributionYPosition = CGRectGetMaxY(imageViewer.frame);
			shareButtonYPosition = CGRectGetMaxY(imageViewer.frame);
			captionYPosition = shareButtonYPosition + kImageInfoHeight + [Props global].tweenMargin;
			attributionInside = FALSE;
		}
		
		else {
			
			//NSLog(@"IMAGEVIEW.drawRect: positioning caption");
			attributionYPosition = CGRectGetMaxY(imageViewer.frame) - kImageInfoHeight;
			shareButtonYPosition = CGRectGetMaxY(imageViewer.frame) - kImageInfoHeight;
			captionYPosition = shareButtonYPosition - [Props global].tweenMargin - kCaptionHeight;
			attributionInside = TRUE;
		}
		
		[self createAttributionLabelAtPoint: CGPointMake(imageViewer.frame.origin.x, attributionYPosition) andInsidePhoto:attributionInside];
		
		//[self addShareButtonAtPoint:CGPointMake(CGRectGetMaxX(imageViewer.frame) - kShareUnderlayWidth, shareButtonYPosition) andInsidePhoto:attributionInside];
		
		[self createCaptionLabelAtPoint: CGPointMake(imageViewer.frame.origin.x, captionYPosition)];
		
		if(slideController.entry == nil) [self addEntryNameButtonForImageFrame:imageViewer.frame];
		
		[self updateLabels];
		
        
        if (showLoadingIndicator) {
            float indicatorWidth = 20;
            CGRect indicatorFrame = CGRectMake(([Props global].screenWidth - indicatorWidth)/2, CGRectGetMaxY(imageViewer.frame) - indicatorWidth - 5, indicatorWidth, indicatorWidth);
            UIActivityIndicatorView *progressInd = [[UIActivityIndicatorView alloc] initWithFrame:indicatorFrame];
            progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
            progressInd.tag = kProgressIndicatorTag;
            [progressInd sizeToFit];
            progressInd.alpha = .7;
            [progressInd startAnimating];
            [self addSubview: progressInd];
        }
        
        else {
            
            for (UIView *view in [self subviews]) {
                if (view.tag == kProgressIndicatorTag) [view removeFromSuperview];
            }
        }
        
	}
	
	return TRUE;
}


- (void) setUpImageInfo {
	
	NSString *query = [NSString stringWithFormat:@"SELECT entries.name AS name, photos.rowid, photos.author, photos.license, photos.url, photos.caption FROM photos, entry_photos, entries WHERE entry_photos.photoid = photos.rowid AND entries.rowid = entry_photos.entryid AND photos.rowid = %i", imageId];
	
	NSLog(@"IMAGEVIEW.setUpImageInfo: query = %@", query);
	
	@synchronized([Props global].dbSync) {
		
        FMDatabase *db = [EntryCollection sharedContentDatabase];
		FMResultSet *rs = [db executeQuery:query];
		
		if ([db hadError]) NSLog(@"IMAGEVIEW.setUpImageInfo: SQLITE ERROR, query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
		
		//			if (![rs next]) NSLog(@"Image.initWithImageId: no rows in result set!");
		
		if([rs next]) {
			self.author = [rs stringForColumn:@"author"];
			self.imageName = [NSString stringWithFormat:@"%i", imageId];
			self.license = [rs stringForColumn:@"license"];
			self.hyperlink = [rs stringForColumn:@"url"];
			self.name = [rs stringForColumn:@"name"];
			self.caption = [rs stringForColumn:@"caption"]; 
		}
        
        else {
            
            NSString *query = [NSString stringWithFormat:@"SELECT entries.name AS name, photos.rowid, photos.author, photos.license, photos.url, photos.caption FROM photos, entries WHERE entries.icon_photo_id = %i", imageId];
            
            NSLog(@"IMAGEVIEW.setUpImageInfo: query = %@", query);
            
            
            FMDatabase *db = [EntryCollection sharedContentDatabase];
            FMResultSet *rs2 = [db executeQuery:query];
            
            if ([db hadError]) NSLog(@"IMAGEVIEW.setUpImageInfo: SQLITE ERROR, query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
            
            //			if (![rs next]) NSLog(@"Image.initWithImageId: no rows in result set!");
            
            if([rs2 next]) {
                self.author = [rs2 stringForColumn:@"author"];
                self.imageName = [NSString stringWithFormat:@"%i", imageId];
                self.license = [rs2 stringForColumn:@"license"];
                self.hyperlink = [rs2 stringForColumn:@"url"];
                self.name = [rs2 stringForColumn:@"name"];
                self.caption = [rs2 stringForColumn:@"caption"]; 
            }
            
            else {
                NSLog(@"IMAGEVIEW.setUpImageInfo:No rows in result set");
                self.author = @"";
                self.imageName = @"";
                self.license = @"";
                self.hyperlink = @"";
                self.name = @"";
                self.caption = @"";
            }
            
            [rs2 close];
        }
		
		[rs close];		
	}
}


- (UIImage*) getImageForId:(int) theImageId withSize:(NSString*) theSize {
	
	//NSLog(@"IMAGEVIEW.getImageForId:%i", theImageId);	
	
	
	NSString *smallImagePath = [NSString stringWithFormat:@"%@/images/%i_thumbnail.jpg",[Props global].contentFolder , theImageId];
	
	if ([theSize  isEqual: kSmallSize]) {
		
		UIImage *theImage = nil;
		
		//Need to return image with correct dimensions for iPhones running 3.x
		if ([Props global].osVersion < 4) {
			
			theImage = [[UIImage alloc] initWithContentsOfFile: smallImagePath];
			
			if (theImage == nil) {
				
                theImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100", theImageId] ofType:@"jpg"]];
                
                if (theImage == nil) 
                    theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , theImageId]];
                
                if (theImage == nil){
                    NSLog( @"About to resize image for old device");
                    theImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i", theImageId] ofType:@"jpg"]];
                    
                    if(theImage == nil) //look for the image in the documents/app name directory if it's not in the resources folder
                        theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i.jpg",[Props global].contentFolder , theImageId]];
                    
                    if(theImage == nil) //look for the image in the documents/app name directory if it's not in the resources folder
                    {   theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_768.jpg",[Props global].contentFolder , theImageId]];
                        NSLog(@"Getting 768 size photo");
                    }
                    
                    if (theImage != nil) {
                        float imageWidth = theImage.size.width * (rowHeight/theImage.size.height);
                        theImage = [theImage resizedImage:CGSizeMake(imageWidth, rowHeight) interpolationQuality:1];
                        NSData *theData = UIImageJPEGRepresentation(theImage,1);
                        
                        //Write the data to disk
                        NSError * theError = nil;
                        [theData writeToFile: smallImagePath options:NSAtomicWrite error:&theError];
                    }
                    
                    else {
                       NSLog(@"********WARNING: IMAGEVIEW.getImageForId:%i withSize:%@ returing nil*****", imageId, theSize);
                        return nil; 
                    }
                }
				
				NSLog(@"Done resizing image");
			}
			
			return theImage;
		}
		
		else {
            
            theImage = nil;
            
            if ([Props global].deviceType == kiPad && rowHeight < 200) {
                theImage = [[UIImage alloc] initWithContentsOfFile: smallImagePath];
                
                if (theImage == nil){ 
                    theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , theImageId]];
                }
                
                if(theImage == nil) {
                    theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_768.jpg",[Props global].contentFolder , theImageId]];
                    
                    if(theImage == nil) {
                        theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i.jpg",[Props global].contentFolder , theImageId]];
                    }
                    
                    if (theImage != nil) {
                        
                        @autoreleasepool {
                        
                            float imageWidth = theImage.size.width * (rowHeight/theImage.size.height);
                            theImage = [theImage resizedImage:CGSizeMake(imageWidth, rowHeight) interpolationQuality:1]; //this image is autoreleased, so retain is necessary to avoid double release
                            NSData *theData = UIImageJPEGRepresentation(theImage,1);
                            
                            //Write the data to disk
                            NSError * theError = nil;
                            [theData writeToFile: smallImagePath options:NSAtomicWrite error:&theError];
                        
                        }
                    }
                }
            }
        
            if (theImage == nil) 
            theImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100", theImageId] ofType:@"jpg"]];
            
            if (theImage == nil) 
                theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , theImageId]];
            
            if (theImage == nil) 
                theImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i", theImageId] ofType:@"jpg"]];
            
            if(theImage == nil) //look for the image in the documents/app name directory if it's not in the resources folder
                theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i.jpg",[Props global].contentFolder , theImageId]];
            
            //should only be necessary in test app mode...
            if(theImage == nil) //look for the image in the documents/app name directory if it's not in the resources folder
                theImage = [[UIImage alloc] initWithContentsOfFile: smallImagePath];
            
            if(theImage == nil) {
                theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_768.jpg",[Props global].contentFolder , theImageId]];
                
                if (theImage != nil) {
                    
                    float imageWidth = theImage.size.width * (rowHeight/theImage.size.height);
                    theImage = [theImage resizedImage:CGSizeMake(imageWidth, rowHeight) interpolationQuality:1]; //this image is autoreleased, so retain is necessary to avoid double release
                    NSData *theData = UIImageJPEGRepresentation(theImage,1);
                    
                    //Write the data to disk
                    NSError * theError = nil;
                    [theData writeToFile: smallImagePath options:NSAtomicWrite error:&theError];
                }
            }
            
            if(theImage == nil) NSLog(@"*********ERROR1:IMAGEVIEW.getImageForId:image %i not found!!!", theImageId);
            
            return theImage;
        }
	}
		
	else {
		
		UIImage *theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_768.jpg",[Props global].contentFolder , theImageId]];
        
        if(theImage == nil) theImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_768", theImageId] ofType:@"jpg"]];
		
        if (theImage == nil && [Props global].deviceType == kiPad) [self downloadHigherQualityImage];
            
		// Look in the app bundle next
		if(theImage == nil) theImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i", theImageId] ofType:@"jpg"]];
		
		if(theImage == nil) //look for the image in the documents/app name directory if it's not in the resources folder
			theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i.jpg",[Props global].contentFolder , theImageId]];
        
        if(theImage == nil) {
            //NSLog(@"Need to download higher quality image or show warning that higher quality images are available");
            if ([Props global].deviceType != kiPad) [self downloadHigherQualityImage];
			theImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100", theImageId] ofType:@"jpg"]];
            
            if (theImage == nil)
                theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , theImageId]];
            
            if (theImage == nil) NSLog(@"**********ERROR:IMAGEVIEW.getImageForId: image %i not found at %@ or %@", theImageId, [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100", theImageId] ofType:@"jpg"], [NSString stringWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , theImageId]);
        }
		
		if(theImage == nil) NSLog(@"*********ERROR2:IMAGEVIEW.getImageForId:image %i not found!!!", theImageId);
		
		return theImage;
	}
	
	NSLog(@"About to return nil");
	return nil;
}


- (BOOL) createPhotoRowAtYPosition:(float) theYPosition {
	
	//NSLog(@"IMAGEVIEW.createPhotoRow at yPostion = %f", theYPosition);
	@autoreleasepool {
	
		float maxX = 0;
		float minBorderWidth = 2;
		float totalPhotoWidth = 0;
		NSMutableArray *buttonArray = [NSMutableArray new];
		
		while (maxX <= self.frame.size.width) {
			
			UIButton *photoButton = [self getPhotoButtonForIndex:currentImageIndex];
			
			if (photoButton == nil) {
				NSLog(@"Image = nil");
				
				if (currentImageIndex >= [slideController.imageArray count]){
					//NSLog(@"Last image -- breaking");
					if (maxX == 0) {
                    return FALSE;
                }
                
					break;
				}
				
				else currentImageIndex ++;
			}
			
			if (photoButton != nil) {
				lastImageIndex = currentImageIndex;
				
				float width = photoButton.frame.size.width * (rowHeight/photoButton.frame.size.height);
				float height = rowHeight;
				
				if (width > [Props global].screenWidth - minBorderWidth) {
					height = rowHeight * [Props global].screenWidth/width;
					width = [Props global].screenWidth - minBorderWidth;
					theYPosition += (rowHeight - height)/2;
				}
				
				photoButton.frame = CGRectMake(0, theYPosition, width, height);
				
				maxX += minBorderWidth + photoButton.frame.size.width /** (rowHeight/photoButton.frame.size.height)*/;
				
				//NSLog(@"MaxX = %f", maxX);
				
				if (maxX <= [Props global].screenWidth) {
					[buttonArray addObject:photoButton];
					currentImageIndex ++;
					totalPhotoWidth += photoButton.frame.size.width /** (rowHeight/photoButton.frame.size.height)*/;
				}
				
				else {
					//NSLog(@"About to break. MaxX = %f", maxX);
					break;
				}
			}
		}
		
		float borderWidth = ([Props global].screenWidth - totalPhotoWidth)/([buttonArray count] + 1);
		//NSLog(@"borderWidth = %f totalPhotoWdith = %f", borderWidth, totalPhotoWidth);
		maxX = borderWidth;
		
		if ([buttonArray count] == 0) NSLog(@"***************ERROR*************** IMAGEVIEW.createPhotoRowAtYPosition:No images in row");
		
		for (UIButton *button in buttonArray) {
			
			button.frame = CGRectMake(maxX, button.frame.origin.y, button.frame.size.width, button.frame.size.height);
			maxX += borderWidth + button.frame.size.width;
			[self addSubview:button];
		}
		
	
	}
	
	return TRUE;
}


- (UIButton*) getPhotoButtonForIndex:(int) theIndex {
	
	//NSLog(@"IMAGEVIEW.getPhotoButtonForIndex: index = %i and image array count = %i", theIndex, [slideController.imageArray count]);
	
	if (theIndex > ((int)[slideController.imageArray count] - 1)) {
		NSLog(@"IMAGEVIEW.getPhotoButtonForIndex: About to return nil");
		return nil;
	}
	
	NSNumber *theImageIdObject = [slideController.imageArray objectAtIndex:theIndex];
	UIImage *theImage = [self getImageForId:[theImageIdObject intValue] withSize:kSmallSize];
	
	if (theImage == nil) return nil;
	
	UIButton *button = [UIButton buttonWithType:0];
    [button setImage:theImage forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, theImage.size.width, theImage.size.height);
	[button addTarget:slideController action:@selector(showSingleImageView:) forControlEvents:UIControlEventTouchUpInside];
	button.tag = [theImageIdObject intValue];
	
	//NSLog(@"IMAGEVIEW.getPhotoButtonForIndex:about to return button with width = %f", button.frame.size.width);
	
	return button;
}


- (UIImage*) cropImage:(UIImage*) image {
	
	float imageX, imageY;
	float scaledWidth, scaledHeight;
	float imageWidth = 77.5;
	
	//landscape
	if (image.size.width > image.size.height) {
		imageY  = 0;
		imageX = (image.size.height - image.size.width)/2 * (imageWidth/image.size.height);
		scaledWidth = image.size.width * (imageWidth/image.size.height);
		scaledHeight = imageWidth;
	}
	
	//Portrait
	else {
		imageX = 0;
		imageY = (image.size.width - image.size.height)/2 * (imageWidth/image.size.width);
		scaledWidth = imageWidth;
		scaledHeight = image.size.height * (imageWidth/image.size.width);
	}
	
	UIGraphicsBeginImageContext(CGSizeMake(imageWidth, imageWidth));
	
	//CGRect thumbnailRect = CGRectZero;
	//thumbnailRect.origin = thumbnailPoint;
	//thumbnailRect.size.width  = scaledWidth;
	//thumbnailRect.size.height = scaledHeight;
	
	[image drawInRect:CGRectMake(imageX, imageY, scaledWidth, scaledHeight)];
	
	UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return thumbnail;
}


- (void) downloadHigherQualityImage {
    
    NSLog(@"IMAGEVIEW.downloadHigherQualityImage");
    
    if ([Props global].connectedToInternet) {
        NSString *tempString = [[NSString alloc] initWithFormat: @"http://%@/published/%@-sized-photos/%i.jpg", [Props global].serverContentSource, [Props global].deviceType == kiPad ? @"ipad":@"480", imageId];
		NSLog(@"Image source = %@", tempString);
        NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
        
        request = [ASIHTTPRequest requestWithURL:dataURL];
        [request setDelegate:self];
        
        [request startAsynchronous];
    }
    
    else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"offline photo warning shown"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"It looks like you might be offline. Note that if offline photos have not yet been downloaded, some images will require an internet connection for full resolution."  delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        
        [alert show];
        
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"offline photo warning shown"];
    }
        
    /*[[NSNotificationCenter defaultCenter] postNotificationName:kDownloadHigherResolutionImage object:[NSNumber numberWithInt:imageId]];
    
    NSString *notificationKey = [NSString stringWithFormat:@"%@_%i", kHigherQualityImageDownloaded, imageId];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addContent) name:notificationKey object:nil];*/
}


- (void)requestFinished:(ASIHTTPRequest *)_request {
    
    NSString *theFolderPath = [NSString stringWithFormat:@"%@/images", [Props global].contentFolder];
	
	//check to see if images folder is there and create it if not
	if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath]) 
        [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ]; 
    
    NSString *theFilePath = [NSString stringWithFormat:@"%@/%i%@.jpg", theFolderPath, imageId, [Props global].deviceType == kiPad ? @"_768" : @""];
    
    //Write the data to disk
    NSError * theError = nil;
    
    if([_request.responseData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) NSLog(@"**** ERROR:GUIDEDOWNLOADER.getOtherImages: failed to write local file to %@, error = %@, userInfo = %@ *******************************************************************", theFilePath, theError, [theError userInfo]);
    
    else {
        //NSLog(@"Successfully got photo and wrote it to %@", theFilePath);
        [self performSelectorOnMainThread:@selector(addContent) withObject:nil waitUntilDone:NO];
        
        NSString *query = [[NSString alloc] initWithFormat:@"UPDATE photos SET downloaded_%ipx_photo = 1 WHERE rowid = %@", [Props global].deviceType == kiPad ? 768:320, imageName];
        FMDatabase *db = [EntryCollection sharedContentDatabase];
        
        @synchronized([Props global].dbSync) {
            [db executeUpdate:@"BEGIN TRANSACTION"];
            [db executeUpdate:query];
            [db executeUpdate:@"END TRANSACTION"];
        }
    }
    
    request = nil;
}


- (void)requestFailed:(ASIHTTPRequest *)_request {

    NSLog(@"IMAGEVIEW.requestFailed: URL = %@, ERROR = %@", _request.url.absoluteString, _request.error.description);
    [[self viewWithTag:kProgressIndicatorTag] removeFromSuperview];
}



/*- (void) addShareButtonAtPoint:(CGPoint) thePoint andInsidePhoto:(BOOL) insidePhoto {
	
	UIView *shareView = [[UIView alloc] init];
	shareView.backgroundColor = [UIColor clearColor];
	shareView.tag = imageLabelsTag;
	shareView.frame = CGRectMake(thePoint.x, thePoint.y, kShareUnderlayWidth, kImageInfoHeight);
	
	UIImage *underlay;
	
	if (insidePhoto) underlay = [[UIImage imageNamed:@"toolsUnderlay.png"] stretchableImageWithLeftCapWidth:17.0 topCapHeight:0.0];
	
	else underlay = [[UIImage imageNamed:@"toolsUnderlay_flipped.png"] stretchableImageWithLeftCapWidth:17.0 topCapHeight:0.0];
	
	
	UIImageView *toolsUnderlayViewer = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, shareView.frame.size.width, shareView.frame.size.height)];
	toolsUnderlayViewer.image = underlay;
	toolsUnderlayViewer.alpha = kUnderlayAlpha;
	[shareView addSubview:toolsUnderlayViewer];
	
	//if (!insidePhoto) [shareView sendSubviewToBack: toolsUnderlayViewer];
	
	UIImage *shareButtonImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"share_slideshow" ofType:@"png"]];
	
	CGRect shareButtonRect = CGRectMake((shareView.frame.size.width - shareButtonImage.size.width)/2,(shareView.frame.size.height - shareButtonImage.size.height)/2, shareButtonImage.size.width, shareButtonImage.size.width);
	UIButton *shareButton = [[UIButton alloc] initWithFrame:shareButtonRect];
	shareButton.alpha = kAttributionAlpha;
	[shareButton setImage:shareButtonImage forState:0];
	[shareButton addTarget:slideController action:@selector(sharePic:) forControlEvents:UIControlEventTouchUpInside];
	
	[shareView addSubview:shareButton];
	
	[self addSubview:shareView];
	
	[shareButtonImage release];
	[shareButton release];
	[toolsUnderlayViewer release];
	[shareView release];
}*/


- (void) addEntryNameButtonForImageFrame:(CGRect) theImageFrame {

	//NSLog(@"IMAGEVIEW.addEntryNameButton");
	UIImage *background = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"titleUnderlay" ofType:@"png"]];
	UIImage *stretchableBackground = [background stretchableImageWithLeftCapWidth:20 topCapHeight:0];
	
	UIFont *buttonFont = [UIFont boldSystemFontOfSize:15];
    NSString *title = [NSString stringWithFormat:@"%@ ➤",self.name];
	CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, 120);
	CGSize buttonSize = [title sizeWithFont: buttonFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
	
	float width = buttonSize.width + 20;
	//NSLog(@"The top bar %@ hidden", slideController.navigationController.navigationBarHidden ? @"is" : @"is not");
	
	//NSLog(@"Top = %f, imageYOrigin = %f, yPos = %f", top, theImageFrame.origin.y, yPos);
	
	entryNameButton = [UIButton buttonWithType:0];
	entryNameButton.frame = CGRectMake(([Props global].screenWidth - width)/2, 0, width, 40);
	[entryNameButton setTitle:title forState:UIControlStateNormal];
	[entryNameButton setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
	[entryNameButton addTarget:controller action:@selector(goThere:) forControlEvents:UIControlEventTouchUpInside];
	entryNameButton.titleLabel.font = buttonFont;
	entryNameButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
	entryNameButton.tag = imageLabelsTag;
	[entryNameButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
	[entryNameButton setTitleShadowColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
	[entryNameButton setBackgroundImage:stretchableBackground forState:UIControlStateNormal];
	
	[self updateTitleLabelPosition];
	
	[self addSubview:entryNameButton];
}
	

#pragma mark Attribution Stuff

- (void) createAttributionLabelAtPoint:(CGPoint) thePoint andInsidePhoto:(BOOL) insidePhoto {
	
	UIView *attributionView = [[UIView alloc] init];
	attributionView.backgroundColor = [UIColor clearColor];
	attributionView.tag = imageLabelsTag;
	
	//initialize necessary bits and pieces
	//image viewers
	UIImage *theIcon1 = nil;
	UIImage *theIcon2 = nil;
	
	//figure out what we are showing and its dimensions

	// figure out attribution icon widths
	
	int licenseCode = [license intValue];
	
	if([self.author length] == 0 || licenseCode == 7) {
		theIcon1 = nil;
		theIcon2 = nil;
	} 
	else if(licenseCode == 0) {
		theIcon1 = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"copyright" ofType:@"png"]];
		theIcon2 = nil;
	}
	
	else if(licenseCode == 1 || licenseCode == 5) {
		
		theIcon1 = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"attribution" ofType:@"png"]];
		theIcon2 = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"shareAlike" ofType:@"png"]];
	}
	
	else if(licenseCode == 2 || licenseCode == 4) {
		
		theIcon1 = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"attribution" ofType:@"png"]];
		theIcon2 = nil;
	}
	
	else if(licenseCode == 3 || licenseCode == 6) {
		
		theIcon1 = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"attribution" ofType:@"png"]];
		theIcon2 =[[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"noderivative" ofType:@"png"]];
	}
	
	float attributionIconsWidth = theIcon1.size.width + theIcon2.size.width;
	
	float attributionX = 4; // ([Props global].screenWidth - totalAttributionWidth)/2;
	
	//set frame sizes appropriately
	
	float iconY = (30 - theIcon1.size.height)/2;
	CGRect icon1Frame = CGRectMake(attributionX, iconY, theIcon1.size.width, theIcon1.size.height);
	CGRect icon2Frame = CGRectMake(CGRectGetMaxX(icon1Frame), iconY, theIcon2.size.width, theIcon2.size.height);
	
	UIImageView *iconViewer1 = [[UIImageView alloc] init];
	UIImageView *iconViewer2 = [[UIImageView alloc] init];
	iconViewer1.frame = icon1Frame;
	iconViewer2.frame = icon2Frame;
	
	iconViewer1.image = theIcon1;
	iconViewer2.image = theIcon2;
	
	if(theIcon1 != nil){
		theIcon1 = nil;
	}
	
	if(theIcon2 != nil){
		theIcon2 = nil;
	}
	
	UIFont *font = (hyperlink == nil) ? [UIFont fontWithName: kFontName size:12]:[UIFont boldSystemFontOfSize:12];;
	
	//figure out attribution label width
	CGSize textBoxSizeMax	= CGSizeMake(self.frame.size.width - kShareUnderlayWidth - [Props global].leftMargin, 200); // height value does not matter as long as it is larger than height needed for text box
	CGSize textBoxSize = [self.author sizeWithFont:font constrainedToSize: textBoxSizeMax lineBreakMode: 0];
	CGRect attributionLabelRect = CGRectMake (attributionX + attributionIconsWidth + 3, 5, textBoxSize.width + 10, kAttributionLabelHeight);
	UILabel *attributionLabel = [[UILabel alloc] initWithFrame:attributionLabelRect];
	
	attributionLabel.font = font;
	attributionLabel.lineBreakMode = 0;
	attributionLabel.numberOfLines = 1;
	attributionLabel.textAlignment = UITextAlignmentCenter;
	attributionLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	attributionLabel.backgroundColor = [UIColor clearColor];
	attributionLabel.shadowColor = [UIColor blackColor];
	attributionLabel.shadowOffset = CGSizeMake(1, 1);
	attributionLabel.text = self.author;
	attributionLabel.alpha = kAttributionAlpha;
	
	UIButton *button = nil;
	if (hyperlink != nil) {
		attributionLabel.textColor = [Props global].linkColor;
		attributionLabel.alpha = 0.9;
		button = [[UIButton alloc] init]; // buttonWithType: 0];
		[button addTarget:slideController action:@selector(showWebPageView:) forControlEvents:UIControlEventTouchUpInside];
		button.backgroundColor = [UIColor clearColor];
		button.frame = attributionLabel.frame;
	}
	
	else attributionLabel.textColor = [UIColor colorWithWhite:.7 alpha:1.0];
	
	
	attributionView.frame = CGRectMake(thePoint.x, thePoint.y, attributionIconsWidth + attributionLabel.frame.size.width + 13, kImageInfoHeight);
	
	CGRect underlayFrame = CGRectMake(0, 0, attributionView.frame.size.width, attributionView.frame.size.height);	
	UIImage *underlay;
	
	if (insidePhoto) underlay = [[UIImage imageNamed:@"attributionUnderlay.png"] stretchableImageWithLeftCapWidth:17.0 topCapHeight:0.0];
	
	else underlay= [[UIImage imageNamed:@"attributionUnderlay_flipped.png"] stretchableImageWithLeftCapWidth:17.0 topCapHeight:0.0];
	
	UIImageView *attributionUnderlayViewer = [[UIImageView alloc] initWithFrame:underlayFrame];
	attributionUnderlayViewer.image = underlay;
	attributionUnderlayViewer.alpha = kUnderlayAlpha;
	[attributionView addSubview:attributionUnderlayViewer];
	
	//if (!insidePhoto) [self sendSubviewToBack:attributionUnderlayViewer];
	
	[attributionView addSubview:attributionLabel];
	[attributionView addSubview:iconViewer1];
	[attributionView addSubview:iconViewer2];
	
	if (button != nil) [attributionView insertSubview:button atIndex:0];
	
	[self addSubview:attributionView];
	
}


- (void) createCaptionLabelAtPoint:(CGPoint) thePoint {
	
	CGRect captionFrame = CGRectMake([Props global].leftMargin, thePoint.y, self.frame.size.width - [Props global].leftMargin - [Props global].rightMargin, kCaptionHeight);
	
	UIFont *captionFont = [UIFont fontWithName: kFontName size:14];
	
	UILabel *captionLabel = [[UILabel alloc] initWithFrame:captionFrame];
	captionLabel.lineBreakMode = 0;
	captionLabel.tag = imageLabelsTag;
	captionLabel.numberOfLines = 2;
	captionLabel.backgroundColor = [UIColor clearColor];
	captionLabel.textAlignment = UITextAlignmentCenter;
	captionLabel.textColor = [UIColor lightGrayColor];
	captionLabel.shadowColor = [UIColor blackColor];
	captionLabel.shadowOffset = CGSizeMake(1, 1);
	captionLabel.font = captionFont;
	captionLabel.text = caption;
	[self addSubview:captionLabel];
	
}


- (void) updateLabels {
	
	[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[ UIView setAnimationDuration: 0.6f ]; // Set the duration to 1 second.
	
	if (slideController.playing) [self hideLabels];
	
	else [self showLabels];

	[ UIView commitAnimations ];
}


- (void) showLabels {

	for (UIView *view in [self subviews]) {
		if (view.tag == imageLabelsTag) {
			view.alpha = 1;
		}
	}
}


- (void) hideLabels {
	
	for (UIView *view in [self subviews]) {
		if (view.tag == imageLabelsTag) {
			view.alpha = 0;
		}
	}
}


- (void) updateTitleLabelPosition {

	//NSLog(@"Updating title label position for navigation bar = %@", slideController.navigationController.navigationBarHidden ? @"hidden" : @"not hidden");
	float top;
    if(slideController.navigationController.navigationBarHidden) {
        if([[Props global] inLandscapeMode])top = [Props global].screenHeight/30;
       
       else top = [Props global].screenHeight/16; 
    }
    
    else top = [Props global].titleBarHeight + [Props global].screenHeight/48;
    
    if ([Props global].showAds) top += 18;
	
	float titleHeight = entryNameButton.frame.size.height;
	float yPos = top;
	
	if (top < imageFrame.origin.y + 10 && top + titleHeight > imageFrame.origin.y) yPos = imageFrame.origin.y + ([[Props global] inLandscapeMode] ? 7:  10);
	
	//float yPos = (top + titleHeight + horizontalMargin > imageFrame.origin.y) ? fmax(top + horizontalMargin top,imageFrame.origin.y + 3) : imageFrame.origin.y + 3;
	
	entryNameButton.frame = CGRectMake(entryNameButton.frame.origin.x, yPos, entryNameButton.frame.size.width, entryNameButton.frame.size.height);
}


#pragma mark -
#pragma mark iAd Delegates

- (void)interstitialAdDidLoad:(ADInterstitialAd *)_interstitialAd
{
    NSLog(@"Interstitial ad did load");
    [_interstitialAd presentInView:self];
}


- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    
    int pageId = controller.entry == nil ? kTLSS : kEntrySlideShow;
    
    SMLog *log = [[SMLog alloc] initWithPageID: pageId actionID: kAdClicked];
    //log.entry_id = guideId;
    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
    
    return TRUE;
}

// The application should implement this method so that when the user dismisses the interstitial via
// the top left corner dismiss button (which will hide the content of the interstitial) the
// application can then move the view offscreen.
- (void)interstitialAdDidUnload:(ADInterstitialAd *)_interstitialAd
{
    //[self removeInterstitial];
    NSLog(@"Interstitial ad did unload");
}


// This method will be invoked when an error has occurred attempting to get advertisement content. 
// The ADError enum lists the possible error codes.
- (void)interstitialAd:(ADInterstitialAd *)_interstitialAd didFailWithError:(NSError *)error
{
    NSLog(@"interstitialAd <%@> recieved error <%@>", _interstitialAd, error);
}

// This message will be sent when the user taps on the interstitial and some action is to be taken.
// The delegate may return NO to block the action from taking place, but this
// should be avoided if possible because most advertisements pay significantly more when 
// the action takes place and, over the longer term, repeatedly blocking actions will 
// decrease the ad inventory available to the application. Applications should reduce
// their own activity while the advertisement's action executes.
- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)_interstitialAd willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

// This message is sent when a modal action has completed and control is returned to the application. 
// Games, media playback, and other activities that were paused in response to the beginning
// of the action should resume at this point.
- (void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd
{
}

#pragma mark
#pragma mark Touch Recognizers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	//UITouch *touch = [touches anyObject];
	
	//CGPoint touchPoint = [touch locationInView:[touch view]];
	
	//NSLog(@"Registered touches");
	
	NSUInteger numTaps = [[touches anyObject] tapCount];
	if (numTaps == 1 /*&& touchPoint.y < CGRectGetMaxY(imageFrame)*/)
		slideController.touchTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:slideController selector:@selector(respondToTap:) userInfo:nil repeats:NO];
}


- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer {

	NSLog(@"IMAGEVIEW.handleGesture");
	
}


@end
