/*


Version: 1.7
*/


#import "DetailView.h"
#import "LocationViewController.h"
#import "Entry.h"
#import "Constants.h"
#import "ActivityLogger.h"
#import	"EntryCollection.h"
#import "Props.h"
#import "Reachability.h"
#import "Comment.h"
#import "SMLog.h"
#import "SMPitch.h"
#import "SMRichTextViewer.h" 
#import "MapViewController.h"
#import "RMMarker.h"
#import "RMMarkerManager.h"
#import "RMDBMapSource.h"
#import "RMDBMapSource.h"
#import "MapViewController.h"
#import "Deal.h"



#define kBetweenListingSpace 3
#define kRightSideUp 1
#define kUpsideDown 2
#define kWaitingForAppStoreViewTag 430987


@interface DetailView (PrivateMethods)

- (int) drawMainImageAtYPosition:(int) theYPosition;
- (float) drawImageUnderlayAtYPosition: (float) theYPosition;
- (int) drawTextDescriptionAtYPosition: (int) theYPosition;
- (int) drawTagsAtYPosition: (int) theYPosition;
- (int) drawCommentAndFavoritesButtonsAtYPosition: (int) theYPosition;
- (UIButton *) createTextButtonWithIconName: (NSString*) iconName text:(NSString*) theText textColor:(UIColor*) theTextColor clickable:(BOOL) isClickable target: (id) target selector:(SEL) selector yPosition:(float) theYPosition;
- (int) drawCommentAndFavoritesButtonsAtYPosition: (int) theYPosition;
- (int) drawComments:(NSArray *) theComments atYPosition:(int)theYPosition;
- (int) drawEntryPitchAtYPosition:(int) theYPosition;
- (UIImage*) createMapIconForMapFrame:(CGRect) mapFrame withFilePath:(NSString*) theFilePath;
- (void) addMapView:(id) object;
- (int) drawDeals:(NSArray *) theDeals atYPosition:(int)theYPosition;
- (int) addHotelBookingLinksAtYPosition: (int) theYPosition;

@end


@implementation DetailView

@synthesize entry;
@synthesize viewController;
@synthesize drawCount, createMapIcon, mapFrame, fakeTopBar, animating, imageHolder, theGuidesList;


// initialize the view, calling super and setting the  properties to nil

- (id)initWithFrame:(CGRect)frame  andEntry:(Entry*) myEntry andLocationViewController:(LocationViewController*) myViewController{
    
    self = [super initWithFrame:frame];
    if (self) {
		
		//NSLog(@"DETAILVIEW.initWithFrame:called with frame height = %f", frame.size.height);
		
		entry				= nil;
		viewController		= nil;
		scrollToEntryView	= nil;
		fakeTopBar			= nil;
        backgroundHolder    = nil;
		animating			= FALSE;
		createMapIcon		= FALSE;
        canReplaceImage     = TRUE;
		y_Position			= 0;
		
        font                = [Props global].bodyFont;
		drawCount = 0;
		
		viewController = myViewController;
		entry = myEntry;
		self.clearsContextBeforeDrawing = NO;
		self.opaque = TRUE;
		self.autoresizesSubviews = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
				
		if(entry.entryid >= 0) self.backgroundColor = [Props global].entryViewBGColor;
		
		else {
			self.backgroundColor = [UIColor colorWithRed:0.88 green:0.95 blue: 0.996 alpha: 1.0 ];
			[[UIColor colorWithWhite: .18 alpha: 1.0 ] set]; // Set font color
		}
        
        //[NSException raise:NSInvalidArgumentException format:@"Foo must not be nil"];
	}
    return self;
}


//This is necessary to prevent crashes with background threads
/**- (oneway void)release
{
    if (![NSThread isMainThread])[super performSelectorOnMainThread:@selector(release) withObject:nil waitUntilDone:NO];
    
    else [super release];
}*/


- (void)dealloc {
	
	NSLog(@"DETAILVIEW.dealloc:");
    canReplaceImage = FALSE;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	self.viewController = nil;
	
	//TF-Setting the entry to nil will cause its retain count to steadily fall and the program will eventually crash. Don't quite understand why
	//self.entry = nil;
	
	if (scrollToEntryView != nil) {[scrollToEntryView.layer removeAllAnimations]; }
	if (scrollToPreviousEntryView != nil){ [scrollToPreviousEntryView.layer removeAllAnimations]; }
    if (backgroundHolder != nil) { backgroundHolder = nil;}
    
}


- (BOOL)canBecomeFirstResponder {
	return NO;
}


- (BOOL)canResignFirstResponder {
	return YES;
}


- (void) redrawForNewOrientation {

	drawCount = 0;
	y_Position = 0;
	[self setNeedsDisplay];
}

	
- (void)drawRect:(CGRect)rect {
	
	NSLog(@"DETAILVIEW.drawRect");
	
    
	int entryHeight = 0; //Used to workaround bug with methods returning weird values when used directly
	
	
	if (drawCount == 0 || y_Position == 0) {
		
		if (viewController.canScrollToPrevious) y_Position = [self drawScrollToPreviousEntryViews];
		
		y_Position += [Props global].titleBarHeight;
		
		//NSLog(@"DETAILVIEW.drawRect:yPosition = %f and titlebarHeight = %f", y_Position, [Props global].titleBarHeight);
		// draw the location image
		y_Position = [self drawMainImageAtYPosition:y_Position];
		
		// draw the distance and price underlay if it's not an upgrade or about sutro entry
		if (entry.entryid >= 0) y_Position = [self drawImageUnderlayAtYPosition: y_Position] + [Props global].tweenMargin;
		
		// draw the tagline if necessary
		if ([entry.tagline length] > 0) {
			
			entryHeight = [self drawTagLineAtYPosition: y_Position];
			y_Position += entryHeight + [Props global].tweenMargin;
		}
		//NSLog(@"yPos after tagline = %i", y_Position);
		
		if (entry.descriptionHTMLVersion == 0 && entry.entryid != -1) {
			
			//NSLog(@"About to draw regular text descriptionwith yPos = %i and html version = %i", y_Position, entry.descriptionHTMLVersion);
			// draw text description
			entryHeight = [self drawTextDescriptionAtYPosition: y_Position];
			y_Position = y_Position + entryHeight + [Props global].tweenMargin;
		}
	}
	
	
	// show the rich text block if available
	if(entry.descriptionHTMLVersion == 1 || entry.entryid == -1){
		
		if (y_Position > 0) {
			entryHeight = [self drawRichTextAtYPosition: y_Position];
			if(drawCount == 1) y_Position += entryHeight + [Props global].tweenMargin;
			
			//NSLog(@"yPos after rich text = %i", y_Position);
		}
	}
	
	else if ([[self.entry getFilterArray] count] > 0) {
		
		entryHeight = [self drawTagsAtYPosition: y_Position];
		if(drawCount == 1) y_Position += entryHeight + [Props global].tweenMargin; 	
		//NSLog(@"YPos after adding tags = %i", y_Position);
	}
	
	//need to draw buttons only after first loading webview once - probably is a better way to do this. 
	if(drawCount == 1) {
		
        BOOL addBottomDivider = FALSE;
        if (entry.entryid > 0 && [Props global].hasDeals) {
			NSArray *deals = [entry createDealsArray];
			
            if ([deals count] > 0) {
                entryHeight = [self drawDeals: deals atYPosition: y_Position];
                y_Position += entryHeight;
            }
            
		}
        
        //add hotel links if available
        //NSLog(@"Hotel links count = %i", [entry.hotelBookingLinks count]);
        if ([entry.hotelBookingLinks count] > 0) {
            
            for (NSString *link in entry.hotelBookingLinks) {
                NSLog(@"Link = %@", link);
            }
            
            entryHeight = [self addHotelBookingLinksAtYPosition:y_Position];
            y_Position += entryHeight + kBetweenListingSpace;
        }
        
        if (entry.entryid > 0 && !entry.isDemoEntry) {
			NSArray *comments = [entry createCommentsArray];
			entryHeight = [self drawComments: comments atYPosition: y_Position];
			if(entryHeight !=0) y_Position += entryHeight;
            addBottomDivider = TRUE;
		}
		
		//draw the app pitch if it exists
		if (viewController.pitch != nil && [Props global].appID > 1) {
			entryHeight = [self drawEntryPitchAtYPosition: y_Position];
			y_Position += entryHeight;
            addBottomDivider = TRUE;
		}	
        
        //draw bottom divider line as appropriate
        if (addBottomDivider) {
            UIImage *divider = [UIImage imageNamed:@"divider.png"];
            UIImageView *dividerImageViewer2 = [[UIImageView alloc] initWithImage:divider];
            dividerImageViewer2.frame = CGRectMake(0, y_Position, [Props global].screenWidth, divider.size.height);
            [self addSubview:dividerImageViewer2];
            
             y_Position += dividerImageViewer2.frame.size.height + [Props global].tweenMargin;
            
        }
        
        else y_Position += [Props global].tweenMargin;
				
		// draw the hours info as necessary
		if( [entry.hours length] >= 8) //correct hours string would be more than at least 8 characters
		{
			UIButton *hoursButton = [self createTextButtonWithIconName:@"hours" text: entry.hours textColor:[Props global].descriptionTextColor clickable: NO target: nil selector:nil yPosition: y_Position];
			y_Position += hoursButton.frame.size.height + kBetweenListingSpace;
		}
        
        // draw the cost info as necessary
		if( [entry.pricedetails length] >= 1) //correct price string would be more than at least 4 characters
		{
			UIButton *priceDetailsButton = [self createTextButtonWithIconName:@"pricedetails" text: entry.pricedetails textColor:[Props global].descriptionTextColor clickable: NO target: nil selector:nil yPosition: y_Position];
			y_Position += priceDetailsButton.frame.size.height + kBetweenListingSpace;
		}
		
		//draw the address as necessary
		if([entry.address length] >= 1) {
			
			UIButton *addressButton = [self createTextButtonWithIconName:@"addressTile" text: entry.address textColor:[Props global].linkColor clickable: YES target: viewController selector:@selector(showMap:) yPosition: y_Position];
			addressButton.hidden = FALSE;
			y_Position += addressButton.frame.size.height + kBetweenListingSpace;
		}
        
        //draw the call them button as necessary
		if([entry.phoneNumber length] >= 1) {
            
			BOOL canMakeCalls = ([Props global].deviceType == kiPhone) ? YES : NO;
			
			UIButton *callThemButton = [self createTextButtonWithIconName:@"callTile" text: entry.formattedPhoneNumber textColor:[UIColor colorWithHue: .27 saturation: .85 brightness: .5 alpha:1] clickable: canMakeCalls target: viewController selector:@selector(showCallThemAlert:) yPosition: y_Position];
			callThemButton.hidden = FALSE;
			y_Position += callThemButton.frame.size.height + kBetweenListingSpace;
		}
        
        //draw the web button as necessary
		if([entry.mobilewebsite length] >= 11){ //won't have mobilewebsite with URL shorter than this
			
			UIColor *linkColor = [Props global].linkColor;
			
			UIButton *theWebButton = [self createTextButtonWithIconName:@"webTile" text:[viewController processURLStringForDisplay:entry.mobilewebsite] textColor:linkColor clickable: YES target: viewController selector:@selector(showEntryWebView:) yPosition: y_Position];
			y_Position += theWebButton.frame.size.height + kBetweenListingSpace;
		}
        
        if ([entry.twitterUsername length] >= 1) {
            UIButton *button = [self createTextButtonWithIconName:@"twitterTile" text: [NSString stringWithFormat:@"@%@", entry.twitterUsername] textColor:[Props global].linkColor clickable: YES target: viewController selector:@selector(showTwitterPage) yPosition: y_Position];
			y_Position += button.frame.size.height + kBetweenListingSpace;
        }
        
        if ([entry.facebookLink length] >= 1) {
            
            UIButton *button = [self createTextButtonWithIconName:@"facebookTile" text: [viewController processURLStringForDisplay:entry.facebookLink] textColor:[Props global].linkColor clickable: YES target: viewController selector:@selector(showFacebookPage) yPosition: y_Position];
			y_Position += button.frame.size.height + kBetweenListingSpace;
        }
        
        if ([entry.videoLink length] >= 1) {;
            UIButton *button = [self createTextButtonWithIconName:@"videoTile" text: [viewController processURLStringForDisplay:entry.videoLink] textColor:[Props global].linkColor clickable: YES target: viewController selector:@selector(showVideo) yPosition: y_Position];
			y_Position += button.frame.size.height + kBetweenListingSpace;
        }
        
        if ([entry.reservationLink length] >= 1) {
            UIButton *button = [self createTextButtonWithIconName:@"reservationTile" text: [viewController processURLStringForDisplay:entry.reservationLink] textColor:[Props global].linkColor clickable: YES target: viewController selector:@selector(showReservationPage) yPosition: y_Position];
			y_Position += button.frame.size.height + kBetweenListingSpace;
        }
		
		y_Position += [Props global].tweenMargin - kBetweenListingSpace;
		
		//draw the comment and favorite buttons (method positions this element on bottom of screen if content is short)
		//if (entry.entryid > 0 && !entry.isDemoEntry) y_Position = [self drawCommentAndFavoritesButtonsAtYPosition: y_Position];
		
		if (y_Position < [Props global].screenHeight + kTopScrollGraphicHeight) y_Position = [Props global].screenHeight + kTopScrollGraphicHeight;
		
		//NSLog(@"yPos at end = %i", y_Position);
		//draw next page indicator
	
		if (viewController.canScrollToNext) y_Position = [self drawScrollToNextEntryViewsAtYPosition:y_Position];
		
		//if (y_Position < [Props global].screenHeight + kTopScrollGraphicHeight) y_Position = [Props global].screenHeight + kTopScrollGraphicHeight;
	}
	
	[viewController detailViewSetContentHeight: y_Position];
	
	drawCount ++;   
}


- (int) drawMainImageAtYPosition:(int) theYPosition {
	
	CGRect imageFrame = CGRectZero;
	//NSArray *imageArray = [[entry createImageArray] retain];
		
	UIImage *introImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i",entry.icon] ofType:@"jpg"]];
	
	if(introImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
		
		NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i_768.jpg",[Props global].contentFolder , entry.icon];
		
		introImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];		
	}
    
    if(introImage == nil) { //a 768 image might be in the bundle if it's a banner entry
		
		introImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_768",entry.icon] ofType:@"jpg"]];		
	}
	
	if(introImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
		
		NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i.jpg",[Props global].contentFolder , entry.icon];
		
		//NSLog(@"Looking for image at %@", theFilePath);
		
		introImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
	}
    
    if(introImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
		
		introImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100",entry.icon] ofType:@"jpg"]];
        
        if (introImage == nil) introImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , entry.icon]];
        
        if (introImage == nil) {
            NSLog(@"Image not found at %@", [NSString stringWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , entry.icon]);
        }
		
        NSString *notificationName = [NSString stringWithFormat:@"%@_%i",kHigherQualityImageDownloaded, entry.entryid];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replaceImageIfAlive:) name:notificationName object:nil];
	}
	
	if (introImage == nil) {
		
		//big image has not yet been downloaded, so we'll use a small one
		introImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_151x", entry.icon] ofType:@"jpg"]];
	}
	
	
	if(introImage != nil) {
	
		float imageWidth = ([Props global].screenWidth)/2;
		//float imageHeight = introImage.size.height * (imageWidth/
	
		if ([Props global].hasLocations && (!(float)[entry getLatitude]) == 0 && ((float)[entry getLongitude])) { // BUGGY FIXME!! :)
			
			self.mapFrame = CGRectMake(imageWidth, theYPosition, imageWidth, imageWidth * [introImage size].height / [introImage size].width);
            //self.mapFrame = CGRectMake(imageWidth, theYPosition, imageWidth, 50);
		
            UILabel *loadingLabel = [[UILabel alloc] initWithFrame:mapFrame];
            loadingLabel.text = @"Loading map...";
            loadingLabel.textAlignment = UITextAlignmentCenter;
            loadingLabel.font = [UIFont fontWithName:[Props global].fontName size:16];
            loadingLabel.backgroundColor = [UIColor clearColor];
            loadingLabel.textColor = [UIColor grayColor];
            [self addSubview:loadingLabel];
            
			MapViewController *map = [MapViewController sharedMVC];
            map.view.frame = mapFrame;
            map.mapView.frame = mapFrame;
            map.mapView.autoresizingMask = UIViewAutoresizingNone;
            
            
            CLLocationCoordinate2D newPinSpot;
            newPinSpot.latitude = [entry getLatitude];
            newPinSpot.longitude = [entry getLongitude];
            
            //Add marker on map
            [map.mapView.contents.markerManager removeMarker: map.destinationMarker];
            [map hideAllMarkers];
            map.userLocationMarker.bounds = CGRectMake(0, 0, kUserLocationMarkerWidth, kUserLocationMarkerWidth);
            map.userLocationBackground.bounds = CGRectMake(0, 0, kUserLocationMarkerWidth, kUserLocationMarkerWidth);
            [map.mapView.contents.markerManager addMarker:map.destinationMarker AtLatLong:newPinSpot];
            
            float theZoomLevel = [Props global].startingZoomLevel + 1;
            if (theZoomLevel > 14) theZoomLevel = 14;
            if (theZoomLevel > [Props global].innermostZoomLevel) theZoomLevel = [Props global].innermostZoomLevel;
            if (self.entry.isDemoEntry) theZoomLevel = [[Reachability sharedReachability] internetConnectionStatus] == NotReachable ? 5 : 10; //Fixed zoom level for demo entries in Sutro libary apps
            
            [map.mapView moveToLatLong: newPinSpot];
            [map.mapView.contents setZoom:theZoomLevel];
            [self addSubview: map.view];
            
            NSLog(@"Map frame height = %0.0f, mapView frame height = %0.0f", map.view.frame.size.height, map.mapView.frame.size.height);
             
            /*RMMapContents *mapContents = [[RMMapContents alloc] initWithView:mapView tilesource:tileSource centerLatLon:newPinSpot zoomLevel:theZoomLevel maxZoomLevel:theZoomLevel + 1 minZoomLevel:theZoomLevel - 1 backgroundImage:nil];
            
            NSString *imageName = @"destinationIcon";
            UIImage *markerImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imageName ofType:@"png"]];
            RMMarker *destinationMarker = [[RMMarker alloc]initWithUIImage:markerImage anchorPoint:CGPointMake(.5, 1)];
            [markerImage release];
            destinationMarker.bounds = CGRectMake(0, 0, 64 * 1.3, 35 * 1.3);
            
            [mapView.contents.markerManager addMarker:destinationMarker AtLatLong:newPinSpot];
            [destinationMarker release];
             [mapContents release];
             [tileSource release];
            
            [self addSubview:mapView];
            [mapView release];*/

            
            // draw button overlay
            UIButton *mapButton = [UIButton buttonWithType: 0];
            mapButton.frame = mapFrame;
            [mapButton addTarget:viewController action:@selector(showMap:) forControlEvents:UIControlEventTouchUpInside];
            [mapButton setBackgroundColor: [UIColor clearColor]];
            [self addSubview:mapButton];
            
            
			imageFrame = CGRectMake(0, theYPosition, imageWidth,  imageWidth * [introImage size].height / [introImage size].width);
		}
		
		else {
			
			float maxImageHeight = [Props global].screenHeight * .5;
			
			if (introImage.size.height > maxImageHeight) {
				
				float shrinkFraction = maxImageHeight/introImage.size.height;
				
				imageFrame = CGRectMake(([Props global].screenWidth - introImage.size.width * shrinkFraction)/2, theYPosition, introImage.size.width * shrinkFraction, introImage.size.height * shrinkFraction);
			}
			
			
			else imageFrame = CGRectMake(([Props global].screenWidth - introImage.size.width)/2, theYPosition, [introImage size].width, [introImage size].height);
		}	

		
        imageHolder = [[UIImageView alloc] initWithImage:introImage];
        
        if (entry.entryid != -1) imageHolder.frame = imageFrame;
        
        else imageHolder.frame = CGRectMake(0, theYPosition, [Props global].screenWidth, introImage.size.height * ([Props global].screenWidth/introImage.size.width));
		
        imageFrame = imageHolder.frame;
        [self insertSubview:imageHolder atIndex:0];	
        
		if(entry.entryid >= 0) {
			
			UIButton *imageButton = [UIButton buttonWithType: 0];
			imageButton.frame = imageFrame;
			[imageButton addTarget:viewController action:@selector(showPics:) forControlEvents:UIControlEventTouchUpInside];
			//[imageButton setBackgroundImage:introImage forState:normal];
			[self insertSubview:imageButton atIndex:0];	
		}
	}
	
	//if (imageArray != nil) [imageArray release];
	
	return CGRectGetMaxY(imageFrame);
}


- (void) addMapView:(id) object {
    
    RMMapView *mapView = (RMMapView*) object;
    [self addSubview:mapView];
    
    // draw button overlay
    UIButton *mapButton = [UIButton buttonWithType: 0];
    mapButton.frame = mapFrame;
    [mapButton addTarget:viewController action:@selector(showMap:) forControlEvents:UIControlEventTouchUpInside];
    [mapButton setBackgroundColor: [UIColor clearColor]];
    [self addSubview:mapButton];
    
}


- (float) drawImageUnderlayAtYPosition: (float) theYPosition {
	
	float underlayHeight = 23;
	
	//NSLog(@"DETAILVIEW - Drawing image underlay at %i", theYPosition);
	
	// draw underlay
	UIImage *underlayImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"underlayBar" ofType:@"png"]];
	
	CGRect underlayBarRect = CGRectMake(0, theYPosition - 1, [Props global].screenWidth, underlayHeight);
	UIImageView *underlayImageViewer = [[UIImageView alloc] initWithImage:underlayImage];
	underlayImageViewer.frame = underlayBarRect;
	[self addSubview:underlayImageViewer];
	

	NSString *priceString = nil;
	
	if ([Props global].hasPrices) {
		
		if([entry getPrice] == -1) priceString = @"";	
		
		else if([entry getPrice] == 0) priceString = @"Free!";
		
		else if([entry getPrice] > 0 && ![Props global].hasAbstractPrices) priceString = [[NSString alloc] initWithFormat:@"%@ %i/ adult", [Props global].currencyString, [entry getPrice]];
		
		else if ([entry getPrice] > 0 && [Props global].hasAbstractPrices) {
			
			NSString *thePriceString = @"";
			
			int i;
			
			for (i = 0; i < [entry getPrice]; i++) {
				thePriceString = [thePriceString stringByAppendingString:[NSString stringWithFormat:@"%@ ",[Props global].abstractPriceSymbol]];
			}
			
			priceString = [[NSString alloc] initWithString:thePriceString];
		}
		
		else {
			priceString = @"";
			NSLog(@"FIXME - Something is wrong with price data");
		}
	}
	
	else priceString = @"";
		
	NSString * locationString = nil;
	
	if([Props global].hasLocations) {
		
		double latitude = [entry getLatitude];
		double longitude = [entry getLongitude];
		float distance = [[LocationManager sharedLocationManager] getDistanceFromHereToPlaceWithLatitude:latitude andLongitude:longitude];
		NSString *distanceUnit = ([Props global].unitsInMiles) ? @"mi" : @"km";
		
		if (distance < 100)
			locationString = (distance != kNoDistance) ? [[NSString alloc] initWithFormat:@"      About %.1f %@ from you", distance, distanceUnit] 
		: @"";
		
		else locationString = (distance != kNoDistance) ? [[NSString alloc] initWithFormat:@"      About %0.0f %@ from you", distance, distanceUnit] 
			: @"";
	}
	
	else locationString = @"";
	
	
	CGRect imageUnderlayLabelRect = CGRectMake(0, theYPosition + 2, [Props global].screenWidth, underlayHeight - 4);
	
	NSString *labelText = [[NSString alloc] initWithFormat:@"%@%@", priceString, locationString];
	UILabel *imageUnderlayLabel = [[UILabel alloc] initWithFrame:imageUnderlayLabelRect];
	imageUnderlayLabel.backgroundColor = [UIColor clearColor];
	imageUnderlayLabel.textColor = [UIColor whiteColor];
	imageUnderlayLabel.font = font;
	
	imageUnderlayLabel.text = labelText;
	imageUnderlayLabel.textAlignment = UITextAlignmentCenter;
	
	[self addSubview:imageUnderlayLabel];
	
	
	return CGRectGetMaxY(underlayBarRect);
}


- (int) drawTagLineAtYPosition: (int) theYPosition {
	
	NSString *tagLineString = entry.tagline; 
	
	CGSize tagLineBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, 60);
	CGSize tagLineBoxSize = [tagLineString sizeWithFont: [Props global].subtitleFont constrainedToSize: tagLineBoxSizeMax lineBreakMode: 0];
	
	CGRect tagLineRect = CGRectMake ([Props global].leftMargin, theYPosition, [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, tagLineBoxSize.height);
	
	UILabel *tagLineLabel = [[UILabel alloc] initWithFrame:tagLineRect];
	tagLineLabel.backgroundColor = [UIColor clearColor];
	tagLineLabel.textColor = [Props global].descriptionTextColor;	
	tagLineLabel.font = [Props global].subtitleFont;
	tagLineLabel.numberOfLines = 0;
	tagLineLabel.text = tagLineString;
	tagLineLabel.textAlignment = UITextAlignmentCenter;
	
	[self addSubview:tagLineLabel];
	
	
	int height = (int) CGRectGetHeight(tagLineRect);
	
	return height;
}


- (int) drawTextDescriptionAtYPosition: (int) theYPosition {
	
	int textBoxWidth = [Props global].screenWidth - ([Props global].leftMargin + [Props global].rightMargin);
	
	NSString *descriptionString = entry.description; 
	CGSize textBoxSizeMax	= CGSizeMake(textBoxWidth, 5000); // height value does not matter as long as it is larger than height needed for text box
	CGSize textBoxSize = [descriptionString sizeWithFont:font constrainedToSize: textBoxSizeMax lineBreakMode: 0];
	
	CGRect descriptionRect = CGRectMake ([Props global].leftMargin, theYPosition, textBoxWidth, textBoxSize.height);
	
	UILabel *descriptionLabel = [[UILabel alloc] initWithFrame: descriptionRect];
	descriptionLabel.backgroundColor = [UIColor clearColor];
	descriptionLabel.numberOfLines = 0;
	descriptionLabel.textColor = [Props global].descriptionTextColor;
	descriptionLabel.font = font;
	descriptionLabel.text = descriptionString;
	descriptionLabel.textAlignment = UITextAlignmentLeft;
	
	[self addSubview:descriptionLabel];
	
	
	
	return CGRectGetHeight(descriptionRect);
}


- (int) drawTagsAtYPosition: (int) theYPosition {
	
	float height = (viewController.richTextViewer.frame.size.height > 0) ? viewController.richTextViewer.frame.size.height : 22;
	
	viewController.richTextViewer.frame = CGRectMake (0, theYPosition, [Props global].screenWidth, height);
	
	[self addSubview:viewController.richTextViewer];
	
	return viewController.richTextViewer.frame.size.height;
}


- (int) drawRichTextAtYPosition: (int) theYPosition {
	
	//NSLog(@"DETAILVIEW.drawRichTextAtYPosition: richTextViewer height before drawing = %f", viewController.richTextViewer.frame.size.height);
	if ([[self subviews] containsObject:viewController.richTextViewer])[viewController.richTextViewer removeFromSuperview];
	
	viewController.richTextViewer.frame = CGRectMake (0, theYPosition, [Props global].screenWidth, viewController.richTextViewer.frame.size.height);
	
	[self addSubview:viewController.richTextViewer];
	 
	return viewController.richTextViewer.contentSize; //[SMRichTextViewer sharedCopy].frame.size.height;
}


- (int) drawDeals:(NSArray *) theDeals atYPosition:(int)theYPosition {
	
    NSLog(@"DETAILVIEW.drawDeals: %i deals", [theDeals count]);
    
	int height = 0;
	
	UIImage *divider = [UIImage imageNamed:@"divider.png"];
	
	CGRect dividerRect = CGRectMake(0, theYPosition, [Props global].screenWidth, divider.size.height);
	UIImageView *dividerImageViewer = [[UIImageView alloc] initWithImage:divider];
	dividerImageViewer.frame = dividerRect;
	[self addSubview:dividerImageViewer];
	
	height += CGRectGetHeight(dividerRect) + [Props global].tinyTweenMargin;
    
    
    UIImage *dealImage = [UIImage imageNamed:@"deals.png"];
    UIButton *dealButton = [UIButton buttonWithType:0];
    [dealButton setImage:dealImage forState:UIControlStateNormal];
    dealButton.backgroundColor = [UIColor clearColor];
    [dealButton addTarget:viewController action:@selector(showDeals) forControlEvents:UIControlEventTouchUpInside];
    float buttonWidth = 31;
    dealButton.frame = CGRectMake([Props global].leftMargin, theYPosition + height, buttonWidth, dealImage.size.height * (buttonWidth/dealImage.size.width));
    [self addSubview:dealButton];
    
    
    NSString * linkText = ([theDeals count] > 1) ? [NSString stringWithFormat:@"View all deals (%i)", [theDeals count]] : [NSString stringWithFormat:@"View deal"];
    
    UIButton * linkButton = [UIButton buttonWithType:0];
    linkButton.titleLabel.font = [UIFont boldSystemFontOfSize:font.pointSize];
    [linkButton setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
    linkButton.titleLabel.shadowOffset = CGSizeMake(-1, -1);
    [linkButton setTitleShadowColor:[UIColor grayColor] forState:UIControlEventTouchDown];
    [linkButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    //[linkButton setTitleColor:[Props global].descriptionTextColor forState:UIControlEventTouchDown];
    [linkButton setTitle:linkText forState:0];
    CGSize textBoxSize = [linkButton.titleLabel.text sizeWithFont: linkButton.titleLabel.font constrainedToSize: CGSizeMake([Props global].screenWidth, 50) lineBreakMode: 0];
    linkButton.frame = CGRectMake([Props global].leftMargin + 31 + kInnerVerticalMargin, dealButton.frame.origin.y + (dealButton.frame.size.height - textBoxSize.height)/2, textBoxSize.width, 20);
    //linkButton.frame = CGRectMake([Props global].leftMargin + [Props global].screenWidth/3, theYPosition + height, [Props global].screenWidth - [Props global].leftMargin - 100, 20);
    [linkButton addTarget:viewController action:@selector(showDeals) forControlEvents:UIControlEventTouchUpInside];
    
    linkButton.backgroundColor = [UIColor clearColor];
    [self addSubview:linkButton];
	
	height += dealButton.frame.size.height + [Props global].tinyTweenMargin;
	
    Deal *deal = [theDeals objectAtIndex:0];
    UILabel *dealLabel;
	
	if ([Props global].deviceType == kiPad) {
        UIImage *dealIcon = deal.squareImage;
        float iconHeight = 31;
        //CGRect buttonFrame = CGRectMake([Props global].leftMargin + 2.5, theYPosition + height, dealIcon.size.width * iconHeight/dealIcon.size.height, iconHeight);
        CGRect buttonFrame = CGRectMake([Props global].leftMargin, theYPosition + height, dealIcon.size.width * iconHeight/dealIcon.size.height, iconHeight);
        UIButton *dealButton = [UIButton buttonWithType: 0];
        dealButton.frame = buttonFrame;
        [dealButton addTarget:viewController action:@selector(showDeals) forControlEvents:UIControlEventTouchUpInside];
        [dealButton setBackgroundImage:dealIcon forState:normal];
        dealButton.backgroundColor = [UIColor clearColor];
        [self addSubview:dealButton];		
        
        
        UIFont *theFont = [UIFont boldSystemFontOfSize:font.pointSize];
        float textBoxWidth = [Props global].screenWidth - [Props global].rightMargin - CGRectGetMaxX(buttonFrame) - kInnerVerticalMargin;
        
        CGSize textBoxSizeMax	= CGSizeMake(textBoxWidth, 5000);
        CGSize textBoxSize = [deal.shortTitle sizeWithFont: theFont constrainedToSize: textBoxSizeMax lineBreakMode: 0];
        
        
        float theYOffset;
        float textBoxHeight;
        
        if( textBoxSize.height > dealButton.frame.size.height) {
            
            textBoxHeight = 36;
            theYOffset = (dealButton.frame.size.height - textBoxHeight)/2;
        }
        else {
            
            theYOffset = 0; 
            textBoxHeight = dealButton.frame.size.height;
        }
        
        dealLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(dealButton.frame) + kInnerVerticalMargin, CGRectGetMinY(dealButton.frame) + theYOffset, textBoxWidth, textBoxHeight)];
    }
    
    else {
        
        UIFont *theFont = [UIFont boldSystemFontOfSize:font.pointSize];
        float textBoxWidth = [Props global].screenWidth - [Props global].rightMargin - [Props global].leftMargin;
        
        CGSize textBoxSizeMax	= CGSizeMake(textBoxWidth, 5000);
        CGSize textBoxSize = [deal.shortTitle sizeWithFont: theFont constrainedToSize: textBoxSizeMax lineBreakMode: 0];
        
        float textBoxHeight = fminf(textBoxSize.height, 36);
        
        dealLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin, theYPosition + height, textBoxWidth, textBoxHeight)];
    }
    
    dealLabel.font = font;
    dealLabel.numberOfLines = 2;
    dealLabel.textColor = [Props global].descriptionTextColor;		
    dealLabel.backgroundColor = [UIColor clearColor];
    
    NSLog(@"DETAILVIEW.drawDeals: deal title = %@", deal.shortTitle);
    dealLabel.text = deal.shortTitle;
    [self addSubview:dealLabel];
    height += dealLabel.frame.size.height + [Props global].tinyTweenMargin;
    
    //[titleLabel release];
		
    
	return (int)height;
}


- (int) addHotelBookingLinksAtYPosition: (int) theYPosition {
    
    SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kHotelAdShown];
    log.entry_id = entry.entryid;
    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
    
    float height = 0;
	
	UIImage *divider = [UIImage imageNamed:@"divider.png"];
	
	CGRect dividerRect = CGRectMake(0, theYPosition, [Props global].screenWidth, divider.size.height);
	UIImageView *dividerImageViewer = [[UIImageView alloc] initWithImage:divider];
	dividerImageViewer.frame = dividerRect;
	[self addSubview:dividerImageViewer];
	
	height += CGRectGetHeight(dividerRect) + [Props global].tinyTweenMargin;
    
    
    /*UIImage *dealImage = [UIImage imageNamed:@"deals.png"];
    UIButton *dealButton = [UIButton buttonWithType:0];
    [dealButton setImage:dealImage forState:UIControlStateNormal];
    dealButton.backgroundColor = [UIColor clearColor];
    [dealButton addTarget:viewController action:@selector(showDeals) forControlEvents:UIControlEventTouchUpInside];
    float buttonWidth = 31;
    dealButton.frame = CGRectMake([Props global].leftMargin, theYPosition + height, buttonWidth, dealImage.size.height * (buttonWidth/dealImage.size.width));
    [self addSubview:dealButton];*/
    
    
    UILabel *hotelLabel = [[UILabel alloc] init];
    hotelLabel.font = [UIFont boldSystemFontOfSize:font.pointSize];
    hotelLabel.textColor = [Props global].descriptionTextColor;
    hotelLabel.text = @"Check prices and availability";
    CGSize textBoxSize = [hotelLabel.text sizeWithFont: hotelLabel.font constrainedToSize: CGSizeMake([Props global].screenWidth, 50) lineBreakMode: 0];
    //hotelLabel.frame = CGRectMake([Props global].leftMargin /*+ 31 + kInnerVerticalMargin*/, dealButton.frame.origin.y + (dealButton.frame.size.height - textBoxSize.height)/2, textBoxSize.width, 20);
    hotelLabel.frame = CGRectMake([Props global].leftMargin, theYPosition + height, textBoxSize.width, 20);
    hotelLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:hotelLabel];
	
	height += hotelLabel.frame.size.height + [Props global].tinyTweenMargin;
    
    NSString *otelLink = [entry.hotelBookingLinks objectForKey:@"otel"];
    NSString *hotelscomLink = [entry.hotelBookingLinks objectForKey:@"hotelscom"];
    NSString *expediaLink = [entry.hotelBookingLinks objectForKey:@"expedia"];
    
    float theXPosition = [Props global].leftMargin;
    float spaceBetween = 10;
    float tallestIconHeight = 0;
    float width = fminf(([Props global].screenWidth - [Props global].leftMargin * 2 - spaceBetween * 2)/3, 100);
    
    /*UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont boldSystemFontOfSize:20];
    label.frame = CGRectMake(theXPosition, theYPosition, [Props global].screenWidth, label.font.pointSize * 1.2);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [Props global].descriptionTextColor;
    [self addSubview:label];*/
    
    if (otelLink != nil) {
        UIButton *button = [UIButton buttonWithType:0];
        UIImage *buttonImage = [UIImage imageNamed:@"otel.png"];
        [button setImage:buttonImage forState:UIControlStateNormal];
        [button addTarget:viewController action:@selector(openOtelsPage) forControlEvents:UIControlEventTouchUpInside];
        float buttonHeight = buttonImage.size.height * width/buttonImage.size.width;
        float downshift = hotelscomLink != nil ? 10 : 0;
        button.frame = CGRectMake(theXPosition, theYPosition + height + downshift, width, buttonHeight);
        [self addSubview:button];
        
        theXPosition = CGRectGetMaxX(button.frame) + spaceBetween;
        tallestIconHeight = fmaxf(tallestIconHeight, button.frame.size.height);
    }
    
    if (hotelscomLink != nil) {
        UIButton *button = [UIButton buttonWithType:0];
        UIImage *buttonImage = [UIImage imageNamed:@"hotelscom.png"];
        [button setImage:buttonImage forState:UIControlStateNormal];
        [button addTarget:viewController action:@selector(openHotelscomPage) forControlEvents:UIControlEventTouchUpInside];
        float smallerWidth = width * .75;
        float buttonHeight = buttonImage.size.height * smallerWidth/buttonImage.size.width;
        button.frame = CGRectMake(theXPosition, theYPosition + height, smallerWidth, buttonHeight);
        [self addSubview:button];
        
        theXPosition = CGRectGetMaxX(button.frame) + spaceBetween;
        tallestIconHeight = fmaxf(tallestIconHeight, button.frame.size.height);    
    }
    
    if (expediaLink != nil) {
        UIButton *button = [UIButton buttonWithType:0];
        UIImage *buttonImage = [UIImage imageNamed:@"expedia.png"];
        [button setImage:buttonImage forState:UIControlStateNormal];
        [button addTarget:viewController action:@selector(openExpediaPage) forControlEvents:UIControlEventTouchUpInside];
        float buttonHeight = buttonImage.size.height * width/buttonImage.size.width;
        float downshift = hotelscomLink != nil ? 10 : 0;
        button.frame = CGRectMake(theXPosition, theYPosition + height + downshift, width, buttonHeight);
        [self addSubview:button];
        
        tallestIconHeight = fmaxf(tallestIconHeight, button.frame.size.height);
    }
    
    height += tallestIconHeight + [Props global].tinyTweenMargin;
    
    NSLog(@"Returning height of %f", height);
    
    return height;
}


- (int) drawComments:(NSArray *) theComments atYPosition:(int)theYPosition {
	
	float height = 0;
	
	UIImage *divider = [UIImage imageNamed:@"divider.png"];
	
	CGRect dividerRect = CGRectMake(0, theYPosition, [Props global].screenWidth, divider.size.height);
	UIImageView *dividerImageViewer = [[UIImageView alloc] initWithImage:divider];
	dividerImageViewer.frame = dividerRect;
	[self addSubview:dividerImageViewer];
	
	height += CGRectGetHeight(dividerRect) + [Props global].tinyTweenMargin - 1;
    
	
	if([theComments count] == 0) {	
		
		UIImage *commentIcon = [UIImage imageNamed:@"goBackComment.png"];
		CGRect buttonFrame = CGRectMake([Props global].leftMargin, theYPosition + height, commentIcon.size.width, commentIcon.size.height);
		UIButton *commentButton = [UIButton buttonWithType: 0];
		commentButton.frame = buttonFrame;
		[commentButton addTarget:viewController action:@selector(showCommentMaker:) forControlEvents:UIControlEventTouchUpInside];
		[commentButton setBackgroundImage:commentIcon forState:normal];
		commentButton.backgroundColor = [UIColor clearColor];
		[self addSubview:commentButton];
		
		
		//float titleLabelWidth = [Props global].screenWidth / 1.9;
        
        float labelHeight = font.pointSize + 2;
		/*UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin + 31 + kInnerVerticalMargin, CGRectGetMinY(buttonFrame) + (buttonFrame.size.height - labelHeight)/2, titleLabelWidth, labelHeight)];
		titleLabel.font = font;
		titleLabel.textColor = [Props global].descriptionTextColor;
		titleLabel.textAlignment = UITextAlignmentLeft;
		titleLabel.backgroundColor = [UIColor clearColor];
        
		titleLabel.text = @"Got somethin' to add?";
		[self addSubview:titleLabel];*/
		
		UIButton * linkButton = [UIButton buttonWithType:0];
		linkButton.titleLabel.font = [UIFont boldSystemFontOfSize:font.pointSize];
        [linkButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
		[linkButton setTitleColor:[Props global].linkColor forState:0];
		[linkButton setTitle: @"Add your comment or question!" forState:0];
        CGSize textBoxSize = [linkButton.titleLabel.text sizeWithFont: linkButton.titleLabel.font constrainedToSize: CGSizeMake([Props global].screenWidth, 50) lineBreakMode: 0];
        linkButton.frame = CGRectMake([Props global].leftMargin + 31 + kInnerVerticalMargin, CGRectGetMinY(buttonFrame) + (buttonFrame.size.height - labelHeight)/2, textBoxSize.width, labelHeight);
        
		[linkButton addTarget:viewController action:@selector(showCommentMaker:) forControlEvents:UIControlEventTouchUpInside];
		
		linkButton.backgroundColor = [UIColor clearColor];
		[self addSubview:linkButton];
		
		
		height += commentButton.frame.size.height + [Props global].tinyTweenMargin;
        
		//[titleLabel release];		
	}
	
    else if([theComments count] > 0) {
        
        height += [Props global].tinyTweenMargin;
		
		UIImage *playIcon = [UIImage imageNamed:@"goBackComment.png"];
		CGRect buttonFrame = CGRectMake([Props global].leftMargin, theYPosition + height, playIcon.size.width, playIcon.size.height);
		UIButton *playButton2 = [UIButton buttonWithType: 0];
		playButton2.frame = buttonFrame;
		[playButton2 addTarget:viewController action:@selector(showComments:) forControlEvents:UIControlEventTouchUpInside];
		[playButton2 setBackgroundImage:playIcon forState:normal];
		playButton2.backgroundColor = [UIColor clearColor];
		[self addSubview:playButton2];	
        
        
        NSString * linkText = ([theComments count] > 1) ? 
        [NSString stringWithFormat:@"View all comments (%i)", [theComments count]] : 
        [NSString stringWithFormat:@"View full comment"];
		
		UIButton * linkButton = [UIButton buttonWithType:0];
		linkButton.frame = CGRectMake([Props global].leftMargin + 31 + kInnerVerticalMargin, playButton2.frame.origin.y + 2, [Props global].screenWidth - [Props global].leftMargin - 40, 20);
        //linkButton.center = CGPointMake(linkButton.center.x, playButton2.center.y - 4);
		[linkButton setTitleColor:[Props global].linkColor forState:0];
		[linkButton setTitle:linkText forState:0];
		[linkButton addTarget:viewController action:@selector(showComments:) forControlEvents:UIControlEventTouchUpInside];
        linkButton.titleLabel.font = [UIFont boldSystemFontOfSize:font.pointSize];
        [linkButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        
		linkButton.backgroundColor = [UIColor clearColor];
		[self addSubview:linkButton];
		
        height += playButton2.frame.size.height + [Props global].tinyTweenMargin;
		
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin, theYPosition + height, [Props global].screenWidth - [Props global].rightMargin - [Props global].leftMargin, 20)];
		titleLabel.font = font;
		titleLabel.textColor = [Props global].descriptionTextColor;		
		titleLabel.backgroundColor = [UIColor clearColor];
		
		titleLabel.text = [(Comment *)[theComments objectAtIndex:0] commentText];// [NSString stringWithFormat:@"“%@…”", commentString];
		[self addSubview:titleLabel];
		height += titleLabel.frame.size.height + [Props global].tinyTweenMargin;
		
	}
    
	/*else if([theComments count] > 0) {
		
		UIImage *playIcon = [UIImage imageNamed:@"goBackComment.png"];
		CGRect buttonFrame = CGRectMake([Props global].leftMargin, theYPosition + height + [Props global].tinyTweenMargin, playIcon.size.width, playIcon.size.height);
		UIButton *playButton2 = [UIButton buttonWithType: 0];
		playButton2.frame = buttonFrame;
		[playButton2 addTarget:viewController action:@selector(showComments:) forControlEvents:UIControlEventTouchUpInside];
		[playButton2 setBackgroundImage:playIcon forState:normal];
		playButton2.backgroundColor = [UIColor clearColor];
		[self addSubview:playButton2];		
		
		
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin + 31 + kInnerVerticalMargin, CGRectGetMinY(buttonFrame), [Props global].screenWidth - [Props global].rightMargin - [Props global].leftMargin - 31 - kInnerVerticalMargin, 20)];
		titleLabel.font = font;
		titleLabel.textColor = [Props global].descriptionTextColor;		
		titleLabel.backgroundColor = [UIColor clearColor];
		
		titleLabel.text = [(Comment *)[theComments objectAtIndex:0] commentText];// [NSString stringWithFormat:@"“%@…”", commentString];
		[self addSubview:titleLabel];
		height += titleLabel.frame.size.height + [Props global].tinyTweenMargin;
		
		NSString * linkText = ([theComments count] > 1) ? 
        [NSString stringWithFormat:@"View all comments (%i)", [theComments count]] : 
        [NSString stringWithFormat:@"View full comment"];
		
		UIButton * linkButton = [UIButton buttonWithType:0];
		linkButton.frame = CGRectMake([Props global].leftMargin + [Props global].screenWidth/3, theYPosition + height + [Props global].tinyTweenMargin, [Props global].screenWidth - [Props global].leftMargin - 100, 20);
		linkButton.titleLabel.font = [UIFont boldSystemFontOfSize:font.pointSize];
		[linkButton setTitleColor:[Props global].linkColor forState:0];
		[linkButton setTitle:linkText forState:0];
		[linkButton addTarget:viewController action:@selector(showComments:) forControlEvents:UIControlEventTouchUpInside];
        
		linkButton.backgroundColor = [UIColor clearColor];
		[self addSubview:linkButton];
        
		height += linkButton.frame.size.height + [Props global].tinyTweenMargin;
        
		[titleLabel release];
		
	}*/
	
	return (int)height;
}


- (int) drawEntryPitchAtYPosition:(int) theYPosition {
	
	int height = 0;
    
    UIImage *divider = [UIImage imageNamed:@"divider.png"];
	
	CGRect dividerRect = CGRectMake(0, theYPosition, [Props global].screenWidth, divider.size.height);
	UIImageView *dividerImageViewer = [[UIImageView alloc] initWithImage:divider];
	dividerImageViewer.frame = dividerRect;
	[self addSubview:dividerImageViewer];
	
	height += CGRectGetHeight(dividerRect) + [Props global].tinyTweenMargin;
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin, theYPosition + height, [Props global].screenWidth - [Props global].leftMargin, font.pointSize + 4)];
	if([Props global].appID > 1) titleLabel.text = @"See more in...";
	else titleLabel.text = @"Get the app!";
	titleLabel.font = [UIFont boldSystemFontOfSize: font.pointSize];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.textColor = [Props global].descriptionTextColor;	
	[self addSubview:titleLabel];
	
	height += titleLabel.frame.size.height + [Props global].tinyTweenMargin + 1;
	
	//draw app icon tile
	UIImage *appTile = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_87x87", viewController.pitch.appID] ofType:@"jpg"]];

    if(appTile == nil) { //look for the image in the documents/app name/images directory if it's not in the resources folder
		
		NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i_87x87.jpg",[Props global].contentFolder , viewController.pitch.appID];
		
		appTile = [[UIImage alloc] initWithContentsOfFile:theFilePath];
	}
	
	
	CGRect appTileRect = CGRectMake([Props global].leftMargin, theYPosition + height,31,31);
	UIImageView *appTileViewer = [[UIImageView alloc] initWithImage:appTile];
	appTileViewer.frame = appTileRect;
	[self addSubview: appTileViewer];
	
	//draw Guide title and author's name
	float labelX = [Props global].leftMargin + CGRectGetWidth(appTileRect) + kInnerVerticalMargin;
	UILabel *appTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX,height + theYPosition - 3.5, [Props global].screenWidth - labelX - [Props global].leftMargin, 18)];
	appTitleLabel.text = viewController.pitch.appName;
	appTitleLabel.font = [UIFont boldSystemFontOfSize:font.pointSize];
	appTitleLabel.textColor = [Props global].linkColor;
	appTitleLabel.backgroundColor = [UIColor clearColor];
	[self addSubview: appTitleLabel];
	
	UILabel *authorNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(appTitleLabel.frame) + 2, [Props global].screenWidth - labelX - [Props global].leftMargin, font.pointSize + 3)];
	authorNameLabel.text = [NSString stringWithFormat:@"by %@", viewController.pitch.author];
	authorNameLabel.font = [UIFont fontWithName:kFontName size:appTitleLabel.font.pointSize];
	authorNameLabel.textColor = [Props global].descriptionTextColor;
	authorNameLabel.backgroundColor = [UIColor clearColor];
	[self addSubview: authorNameLabel];
	
	//draw overlay button
	CGRect buttonFrame = CGRectMake(0, theYPosition + height - [Props global].tinyTweenMargin, [Props global].screenWidth, CGRectGetHeight(appTileViewer.frame) + [Props global].tinyTweenMargin * 2);
	UIButton *button = [[UIButton alloc] initWithFrame: buttonFrame];
	
	[button addTarget:viewController action:@selector(showGoToAppStoreAlert:) forControlEvents:UIControlEventTouchUpInside];
	button.backgroundColor = [UIColor clearColor];
	
	UIImage *newPressedImage = [[UIImage imageNamed:@"blankImage.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
	[button setBackgroundImage:newPressedImage forState:UIControlStateHighlighted];
	[self addSubview:button];
	
	height += CGRectGetHeight(appTileRect) + [Props global].tinyTweenMargin;
	
	
	
	return height;
}


- (float) drawScrollToPreviousEntryViews {
	
	UILabel *previousPageLabel = [[UILabel alloc] init];
	previousPageLabel.frame = CGRectMake(0, 0, [Props global].screenWidth, kTopScrollGraphicHeight);
	previousPageLabel.text = @"Go to previous entry";
	previousPageLabel.textAlignment = UITextAlignmentCenter;
	previousPageLabel.font = [UIFont fontWithName:kFontName size:18];
	previousPageLabel.textColor = [UIColor darkGrayColor];
	previousPageLabel.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
	[self addSubview:previousPageLabel];
	
	UIImage *scrollToEntry = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"scrollToPreviousEntry" ofType:@"png"]];
	scrollToPreviousEntryView = [[UIImageView alloc] initWithImage:scrollToEntry];
	scrollToPreviousEntryView.frame = CGRectMake(10, (kTopScrollGraphicHeight - 30)/2, 30, 30);
	[self addSubview:scrollToPreviousEntryView];
	
	return CGRectGetMaxY(previousPageLabel.frame);
}


- (float) drawScrollToNextEntryViewsAtYPosition:(float) theYPosition {

	//NSLog(@"DETAILVIEW.drawScrollToNextEntryViewAtYPosition: theYPosition = %f", theYPosition);
	
	UILabel *nextPageLabel = [[UILabel alloc] init];
	nextPageLabel.frame = CGRectMake(0, theYPosition, [Props global].screenWidth, kTopScrollGraphicHeight);
	nextPageLabel.text = @"Go to next entry";
	nextPageLabel.textAlignment = UITextAlignmentCenter;
	nextPageLabel.font = [UIFont fontWithName:kFontName size:18];
	nextPageLabel.textColor = [UIColor darkGrayColor];
	nextPageLabel.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
	nextPageLabel.tag = kNextPageViewTag;
	
	UIImage* dropShadow =[[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dropShadow" ofType:@"png"]];
	UIImageView *dropViewer = [[UIImageView alloc] initWithImage:dropShadow];
	dropViewer.frame =  CGRectMake(0, 0, [Props global].screenWidth, 5);
	dropViewer.alpha = .8;
	[nextPageLabel addSubview:dropViewer];
	
	UIImage *scrollToEntry = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"scrollToNextEntry" ofType:@"png"]];
	scrollToEntryView = [[UIImageView alloc] initWithImage:scrollToEntry];
	scrollToEntryView.transform = CGAffineTransformIdentity;
	scrollToEntryView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
	scrollToEntryView.frame = CGRectMake(10, (kTopScrollGraphicHeight - 30)/2, 30, 30);
	[nextPageLabel addSubview:scrollToEntryView];
	
	[self addSubview:nextPageLabel];
	CGRect nextPageLabelFrame = nextPageLabel.frame;
	
	return CGRectGetMaxY(nextPageLabelFrame);
}


- (UIButton *) createTextButtonWithIconName: (NSString*) iconName text:(NSString*) theText textColor:(UIColor*) theTextColor clickable:(BOOL) isClickable target: (id) target selector:(SEL) selector yPosition:(float) theYPosition {
	
	NSString *imageName = [[NSString alloc] initWithFormat:@"%@.png",iconName];
	UIImage *theIcon = [UIImage imageNamed:imageName];
	
    float textBoxWidth = [Props global].screenWidth - [Props global].leftMargin - theIcon.size.width - [Props global].rightMargin - kInnerVerticalMargin - 5; //additional 5 to account for the reflections on the button that stick out from the edges of the squares

	UIFont *theFont;
	
	if(isClickable) theFont = [UIFont boldSystemFontOfSize:font.pointSize];
	
	else theFont = [UIFont fontWithName:kFontName size:font.pointSize]; 
	
	CGSize textBoxSizeMax	= CGSizeMake(textBoxWidth, 5000);
	CGSize textBoxSize = [theText sizeWithFont: theFont constrainedToSize: textBoxSizeMax lineBreakMode: 0];
	
	
	float theYOffset;
	float height;
	
	if( textBoxSize.height > theIcon.size.height)
	{
		theYOffset = - 2;
		height = textBoxSize.height; 
	}
	else
	{
		theYOffset = (([theIcon size].height - 6) - textBoxSize.height)/2; //the - 6 is there so it doesn't center around the icons shodow
		height = [theIcon size].height;
	}
	
	CGRect labelRect = CGRectMake ([Props global].leftMargin + 31 + kInnerVerticalMargin, theYPosition + theYOffset, textBoxWidth, textBoxSize.height);
	UILabel *theLabel = [[UILabel alloc] initWithFrame:labelRect];
	
	theLabel.text = theText;
	
	theLabel.font = theFont;
	
	theLabel.textColor = (isClickable) ? theTextColor: [Props global].descriptionTextColor;	
	
	theLabel.lineBreakMode = 0;
	theLabel.numberOfLines = 6;
	theLabel.backgroundColor = [UIColor clearColor];
	
	[self addSubview: theLabel];
	
	CGRect iconFrame = CGRectMake([Props global].leftMargin - 2.5, theYPosition, [theIcon size].width, [theIcon size].height); //offset is for icon shadows, which should bleed into margins
	//Code below is a workaround for a problem with images not showing up on a iPod touch
	UIImageView *iconImageHolder = [[UIImageView alloc] initWithImage:theIcon];
	iconImageHolder.frame = iconFrame;
	[self addSubview:iconImageHolder];
	
	
	CGRect buttonFrame = CGRectMake(0, theYPosition, [Props global].screenWidth, height);
	UIButton *button = [[UIButton alloc] initWithFrame: buttonFrame];
	
	if(isClickable) {
		
		[button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
		button.backgroundColor = [UIColor clearColor];
		
		UIImage *newPressedImage = [[UIImage imageNamed:@"blankImage.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
		[button setBackgroundImage:newPressedImage forState:UIControlStateHighlighted];
		[self addSubview:button];
	}
	
	return button; //[button autorelease]; //TF 102209

}


- (void) flipScrollIcon:(NSString*) iconToFlipCode direction:(NSString*) theDirection {
	
    NSLog(@"Flip scroll Icon to %@", theDirection);
    
	animating = TRUE;
    viewController.goToNextOrPreviousEntry = FALSE;
	viewToRotate = ([iconToFlipCode  isEqual: kTopScrollIcon]) ? scrollToPreviousEntryView : scrollToEntryView;
	NSNumber *theFromValue;
	NSNumber *theToValue;
	
	if ([theDirection  isEqual: kFlipUpright]) {
		theFromValue = [NSNumber numberWithFloat:3.14159];
		theToValue = [NSNumber numberWithFloat:0];
         viewToRotate.tag = kRightSideUp;
	}
	
	else {
		theFromValue = [NSNumber numberWithFloat:0];
		theToValue = [NSNumber numberWithFloat:3.14159];
        viewToRotate.tag = kUpsideDown;
	}
	
    
	CABasicAnimation  *rotate;
	rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	rotate.fromValue = theFromValue; //[[dialView.layer presentationLayer] valueForKeyPath:@"transform.rotation.z"];
	rotate.toValue = theToValue;
	rotate.fillMode = kCAFillModeForwards;
	rotate.duration = .3;
	rotate.removedOnCompletion = YES;
	rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	rotate.delegate = self;
	
	[viewToRotate.layer addAnimation: rotate forKey: @"someKey"];
}


- (void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {

    NSString *rotationImage;
    
    if (viewToRotate == scrollToEntryView) rotationImage = viewToRotate.tag == kUpsideDown ? @"scrollToPreviousEntry" : @"scrollToNextEntry";
    
    else rotationImage = viewToRotate.tag == kUpsideDown ? @"scrollToNextEntry" : @"scrollToPreviousEntry";
    
    UIImage *scrollToEntry = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:rotationImage ofType:@"png"]];
    viewToRotate.image = scrollToEntry;
    
	animating = FALSE;
	viewController.goToNextOrPreviousEntry = TRUE;
}


- (void) updateIcon {
    
    NSLog(@"Updating icon");
    UIImage *introImage = nil;
	
	if(introImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
		
		NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i_768.jpg",[Props global].contentFolder , entry.icon];
		
		NSLog(@"Didn't find it there, so looking for image at %@", theFilePath);
		
		introImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];		
	}
	
	if(introImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
		
		NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i.jpg",[Props global].contentFolder , entry.icon];
		
		//NSLog(@"Looking for image at %@", theFilePath);
		
		introImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
	}
	
    
    if (introImage != nil) {
        imageHolder.image = introImage;
        [imageHolder setNeedsDisplay];
    }
    
    else NSLog(@"DETAILVIEW.updateIcon: Can't find image %i for %@", entry.icon, entry.name);
}


- (void) replaceImageIfAlive:(NSNotification*) theNotification {
    
    NSLog(@"DETAILVIEW.replaceImage");
    
    NSData *imageData = (NSData*)theNotification.object;
    
    [self performSelectorOnMainThread:@selector(replaceImage:) withObject:imageData waitUntilDone:NO];
}


- (void) replaceImage:(id) untypedImageData; {
    
    NSLog(@"DETAILVIEW.replaceImage");
    
    @try {
        NSData *imageData = (NSData*) untypedImageData;
        
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        if (imageHolder != nil) imageHolder.image = image;
        
        
        if (entry == nil) {
            NSLog(@"ENTRY IS NIL");
        }
        
        NSLog(@"DETAILVIEW.replaceImage: entry name = %@", entry.name);
        
        //Update database - this needs to be done in the main thread to avoid bad access issues if self is dealloced while the background thread is running
        NSString *query = [[NSString alloc] initWithFormat:@"UPDATE photos SET downloaded_%ipx_photo = 1 WHERE rowid = %i", [Props global].deviceType == kiPad ? 768:320, self.entry.icon];
        
        FMDatabase *db = [EntryCollection sharedContentDatabase];
        
        @synchronized([Props global].dbSync) {
            [db executeUpdate:@"BEGIN TRANSACTION"];
            [db executeUpdate:query];
            [db executeUpdate:@"END TRANSACTION"];
        }

    }
    @catch (NSException *exception) {
        NSLog(@"I got caught!");
    }
}


- (void) createLoadingAnimation {
	
    @autoreleasepool {
    
		NSString *loadingTagMessage = @"Waiting for the App Store...";
		
		UIFont *errorFont = [UIFont fontWithName:kFontName size:17];
		CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].rightMargin - [Props global].leftMargin, 19);
    
		CGSize textBoxSize = [loadingTagMessage sizeWithFont: errorFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
		
		float borderWidth = 10; //side of border between background and stuff on inside
    float height = textBoxSize.height + borderWidth * 2;
    float loadingAnimationSize = 20; //This variable is weird - only sort of determines size at best.
		float messageWidth = loadingAnimationSize + textBoxSize.width + borderWidth * 3;
		
    float yPosition = ([Props global].screenHeight - [Props global].titleBarHeight)/2;
    UIView *waitingBackground = [[UIView alloc] initWithFrame:CGRectMake(([Props global].screenWidth - messageWidth)/2, yPosition, messageWidth, height)];
    waitingBackground.opaque = NO;
    waitingBackground.backgroundColor = [UIColor clearColor];
    waitingBackground.tag = kWaitingForAppStoreViewTag;
    
		CALayer *backgroundLayer = [[CALayer alloc] init];
    backgroundLayer.borderColor = [UIColor colorWithRed:0.85 green:0.85 blue:1.0 alpha:1.0].CGColor;
    backgroundLayer.borderWidth = 1.5;
    backgroundLayer.cornerRadius = 12;
    backgroundLayer.backgroundColor = [UIColor blackColor].CGColor;
    backgroundLayer.opacity = 0.45;
    backgroundLayer.shadowOpacity = 0.8;
    backgroundLayer.shadowColor = [UIColor blackColor].CGColor;
    backgroundLayer.shadowOffset = CGSizeMake(2, 2);
    backgroundLayer.bounds = waitingBackground.bounds;
    backgroundLayer.position = CGPointMake([waitingBackground bounds].size.width/2, [waitingBackground bounds].size.height/2);
    [waitingBackground.layer addSublayer:backgroundLayer];
    
    CGRect frame = CGRectMake(borderWidth, (waitingBackground.frame.size.height - loadingAnimationSize)/2, loadingAnimationSize, loadingAnimationSize);
		
    UIActivityIndicatorView *progressInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
		progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
		[progressInd sizeToFit];
		[progressInd startAnimating];
		[waitingBackground addSubview: progressInd];
		
		CGRect labelRect = CGRectMake (CGRectGetMaxX(progressInd.frame) + borderWidth, (waitingBackground.frame.size.height - textBoxSize.height)/2, textBoxSize.width, textBoxSize.height);
		
		UILabel *loadingTag = [[UILabel alloc] initWithFrame:labelRect];
		loadingTag.text = loadingTagMessage;
		loadingTag.font = errorFont;
		loadingTag.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
		loadingTag.lineBreakMode = 0;
		loadingTag.numberOfLines = 2;
		loadingTag.backgroundColor = [UIColor clearColor];
		[waitingBackground addSubview:loadingTag];
    
    [self addSubview: waitingBackground];
    
    }
}


- (void) removeLoadingAnimation:(NSNotification *)aNotification {
	
	NSLog(@"Got message to remove loading animation");
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.1];
    
    for (UIView *view in [self subviews]) {
        if (view.tag == kWaitingForAppStoreViewTag) view.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    }
    
    [UIView commitAnimations];
    
    [self performSelector:@selector(removeMessage) withObject:nil afterDelay:0.1];
}


- (void) removeMessage {
    
    for (UIView *view in [self subviews]) {
        if (view.tag == kWaitingForAppStoreViewTag) [view removeFromSuperview];
    }
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [touches anyObject];
	gestureStartPoint = [touch locationInView:[touch view]];
    
    //UITouch *touch = [touches anyObject];
	
	if (([[Props global] getOriginalAppId] == 3 || [[Props global] getOriginalAppId] == 37)  && entry.entryid == -1 && ![Props global].inTestAppMode) {
		
		CGPoint touchPoint = [touch locationInView:[touch view]];
		
		if( touchPoint.x < [Props global].screenWidth/6 && touchPoint.y < [Props global].screenHeight/2 && touch.tapCount == 3){

			//[[UIDevice currentDevice] setOrientation:(UIPrintInfoOrientation)UIDeviceOrientationPortrait];
			[[viewController navigationController] popToRootViewControllerAnimated:NO];
			[[NSNotificationCenter defaultCenter] postNotificationName:kShowTestApp object:nil];
		}
	}
    
    else if(touch.tapCount == 1){
        
        [viewController showOrHideBars];
    }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	//NSLog(@"Detected touches moved");
	
	 UITouch *touch = [touches anyObject];
	 CGPoint currentPosition = [touch locationInView:[touch view]];
	 
	 CGFloat deltaX = gestureStartPoint.x - currentPosition.x;
	 CGFloat deltaY = fabsf(gestureStartPoint.y - currentPosition.y);
	 
	 //NSLog(@"Delta X = %f and Delta y = %f", deltaX, deltaY);
	 
	if (deltaX >= 15 && deltaY <= 10 /*&& !viewController.moving && viewController.currentView == viewController.detailScrollView*/) {
		
		//NSLog(@"Touch right size");
		
		if (!viewController.moving) {
			//NSLog(@"View controller not moving");
			
			if (entry.entryid >= 0) {
				//NSLog(@"Current view is detail view");
				 [viewController showPics:nil];
				
				SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVSwipeToPhotos];
				log.entry_id = entry.entryid;
				[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
			}
		}
	}
	 
	else if (deltaX <= -15 && deltaY <= 10 && !viewController.moving) {
		
		[viewController showTopView:nil];
		
		SMLog *log = [[SMLog alloc] initWithPageID: kEntryIntroView actionID: kIVSwipeOut];
		log.entry_id = entry.entryid;
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	 
	}
}


@end
