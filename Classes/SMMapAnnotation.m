//
//  SMMapAnnotation.m
//  TheProject
//
//  Created by Tobin1 on 10/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SMMapAnnotation.h"
#import "Entry.h"
#import "EntryCollection.h"
#import "Props.h"
#import "Constants.h"
#import "LocationManager.h"
#import "MapViewController.h"
#import "RMMarker.h"
#import "RMMarkerManager.h"
#import "Reachability.h"
#import "TopLevelMapView.h"

//#define kLeftCarrot		1
//#define kRightCarrot	2
//#define kMidLeftCarrot	3
//#define kMidRightCarrot	4

@interface  SMMapAnnotation (PrivateMethods)

- (NSString *)subtitle;
- (void) addSubviews;
- (float) getTaxiFare;
- (NSString*) getDistanceString;

@end


@implementation SMMapAnnotation

- (id) initWithEntry:(Entry*) theEntry andController:(TopLevelMapView*)theController {
    
	controller = theController;
    entry = theEntry; 
	
    if ((self = [super initWithFrame:CGRectZero])) {
		
		self.backgroundColor = [UIColor clearColor];
		[self createMarker];
		//NSLog(@"SMMAPANNOTATION.init:%@", self);
    }
    return self;
}


- (id)initWithMarker:(RMMarker*) theMarker  andController:(MapViewController*) theController {
	
	controller = theController;
	marker = theMarker;
	
	NSNumber *markerNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
	int markerId = [markerNumber intValue];
        
	entry = [EntryCollection entryById:markerId]; 
    
    //demo entry case
    if (entry == nil) entry = [EntryCollection demoEntryById:markerId];
	
    if ((self = [super initWithFrame:CGRectZero])) {
		
		self.backgroundColor = [UIColor clearColor];
		[self addSubviews];
		//NSLog(@"SMMAPANNOTATION.init:%@", self);
    }
    return self;
}


- (id)initWithMarker:(RMMarker*) theMarker  controller:(MapViewController*) theController andEntry:(Entry*) theEntry {
	
	controller = theController;
	marker = theMarker;
	
	entry = theEntry; 
    
    NSLog(@"SMMapAnnotation.initWithMarker: entry name = %@", entry.name);
	
    if ((self = [super initWithFrame:CGRectZero])) {
		
		self.backgroundColor = [UIColor clearColor];
		[self addSubviews];
		//NSLog(@"SMMAPANNOTATION.init:%@", self);
    }
    return self;
}




- (void) addSubviews {
	
	float markerWidth = marker.bounds.size.width;
	CGPoint markerPoint = [controller.mapView.contents.markerManager screenCoordinatesForMarker:marker];
	NSNumber *markerNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
	int markerId = [markerNumber intValue];
	
	[entry hydrateEntry];
	
	float maxWidth = 300;
	float frameWidth = 180;  //sets minimum frame width
	float contentHeight;
	float leftMargin = 10;
	
	//**** Add title label
	NSString *title = (entry != nil) ? entry.name : (markerId == kUserLocation) ? @"Your location" : @"";
	
	NSLog(@"Title = %@ and id = %i", title, markerId);
	
	CGSize textBoxSizeMax = CGSizeMake(maxWidth - leftMargin * 2, 60);
	UIFont *font =  [UIFont boldSystemFontOfSize:18];
	CGSize textBoxSize = [title sizeWithFont: font constrainedToSize: textBoxSizeMax lineBreakMode: 2];
	UIButton *entryButton = nil;
	UILabel *entryName = nil;
	
	if (marker == controller.destinationMarker || markerId == kUserLocation) {
		
		float labelWidth = (textBoxSize.width > maxWidth - 20) ? maxWidth - 20 : textBoxSize.width;
		entryName = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, 8, labelWidth, font.pointSize + 2)];
		entryName.font = font;
		entryName.shadowColor = [UIColor blackColor];
		entryName.shadowOffset = CGSizeMake(1, 1);
		entryName.text = title;
		entryName.textColor = [UIColor whiteColor];
		entryName.backgroundColor = [UIColor clearColor];
		contentHeight = CGRectGetMaxY(entryName.frame);
		frameWidth = fmax(CGRectGetMaxX(entryName.frame), frameWidth);
	}
	
	else {
		
		float labelWidth, labelX;
		
		if (textBoxSize.width > maxWidth - 2 * leftMargin) {
			labelWidth = maxWidth - 2 * leftMargin;
			labelX = leftMargin;
		}
		
		else {
			labelWidth = textBoxSize.width + 2*leftMargin;
			labelX = 0;
		}

		
		entryButton = [UIButton buttonWithType:0];
		entryButton.frame = CGRectMake(labelX, -11, labelWidth, font.pointSize + 42);
		entryButton.backgroundColor = [UIColor clearColor];
		[entryButton setTitle:entry.name forState:UIControlStateNormal];
		[entryButton setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
		entryButton.titleLabel.shadowColor = [UIColor blackColor];
		entryButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
		entryButton.titleLabel.font = font;
		entryButton.tag = entry.entryid;
		contentHeight = CGRectGetMaxY(entryButton.frame) - 21;
		frameWidth = fmax(CGRectGetMaxX(entryButton.frame) - 10, frameWidth);
	}

	
	//***** Add tagline as appropriate
	UILabel *taglineLabel = nil;
	if ([entry.tagline length] > 1) {
		
		font = [UIFont italicSystemFontOfSize:12];
		textBoxSize = [entry.tagline sizeWithFont: font constrainedToSize: textBoxSizeMax lineBreakMode: 0];
		
		taglineLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin - .5, contentHeight + 2, textBoxSize.width, textBoxSize.height)];
		taglineLabel.font = font;
		taglineLabel.shadowColor = [UIColor blackColor];
		taglineLabel.shadowOffset = CGSizeMake(1, 1);
		taglineLabel.text = entry.tagline;
		taglineLabel.textColor = [UIColor whiteColor];
		taglineLabel.backgroundColor = [UIColor clearColor];
		
		frameWidth = fmax(CGRectGetMaxX(taglineLabel.frame), frameWidth);
		contentHeight = CGRectGetMaxY(taglineLabel.frame);
	}
	
	
	//***** Add address label as appropriate
	UILabel *addressLabel = nil;
	NSString *address = (markerId != kUserLocation) ? entry.address : [LocationManager sharedLocationManager].address;
	
	if ([address length] > 1) {
		
		font =  [UIFont systemFontOfSize:12];
		textBoxSize = [address sizeWithFont: font constrainedToSize: textBoxSizeMax lineBreakMode: 2];
		
		float addressLabelWidth = textBoxSize.width; // (textBoxSize.width > maxWidth - 48) ? maxWidth - 48 : textBoxSize.width;
		
		addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, contentHeight + 3, addressLabelWidth, 14)];
		addressLabel.font = font;
		addressLabel.shadowColor = [UIColor blackColor];
		addressLabel.shadowOffset = CGSizeMake(1, 1);
		addressLabel.text = address;
		addressLabel.textColor = [UIColor whiteColor];
		addressLabel.backgroundColor = [UIColor clearColor];
		
		frameWidth = fmax(CGRectGetMaxX(addressLabel.frame), frameWidth);
		contentHeight = fmax(CGRectGetMaxY(addressLabel.frame), contentHeight);
	}
	
	UILabel *distanceLabel = nil;
	UILabel *taxiLabel = nil;
	UIButton *taxiButton = nil;
	UIButton *getDirectionsButton = nil;
	
	if (markerId != kUserLocation) {
		
		CLLocation* destination = [[CLLocation alloc] initWithLatitude: [entry getLatitude] longitude: [entry getLongitude]];
		float distanceInMiles = [[LocationManager sharedLocationManager] getDistanceInMetersFromHereToPlace:destination]/1609;
		
		BOOL canCallTaxi = [[Props global].taxiServicePhoneNumber length] >= 10 && ([Props global].deviceType == kiPhone || [Props global].deviceType == kSimulator) && distanceInMiles < 200;
		
		//NSLog(@"Can call taxi = %@, distance = %f, taxi number = %@, deviceType = %i", canCallTaxi ? @"TRUE" : @"FALSE" , distanceInMiles, [Props global].taxiServicePhoneNumber, [Props global].deviceType);
		
		BOOL canShowDirections = [[Reachability sharedReachability] internetConnectionStatus] != NotReachable && [LocationManager sharedLocationManager].locationSet && [Props global].appID > 1;
		// add a buffer before the buttons
		
		if (canShowDirections || canCallTaxi) {
			contentHeight = contentHeight + 8;
			
			font =  [UIFont boldSystemFontOfSize:14];
			
			//**** Add get directions button
			float buttonHeight = 36;
			if (canShowDirections) {
				
				getDirectionsButton = [UIButton buttonWithType:0];
				getDirectionsButton.frame = CGRectMake(0, contentHeight - 9, 114, buttonHeight);
				getDirectionsButton.backgroundColor = [UIColor clearColor];
				//getDirectionsButton.alpha = .8;
				[getDirectionsButton setTitle:@"Get directions" forState:UIControlStateNormal];
				[getDirectionsButton setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
				getDirectionsButton.titleLabel.shadowColor = [UIColor blackColor];
				getDirectionsButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
				getDirectionsButton.titleLabel.font = font;
				getDirectionsButton.tag = kGetDirectionsTag;
				//xPosition = CGRectGetMaxX(getDirectionsButton.frame);
			}
			
			//*** Add taxi label button as appropriate
			if (canCallTaxi) {
				taxiButton = [UIButton buttonWithType:0];
				float taxiButtonYPosition = (getDirectionsButton == nil) ? contentHeight - 9 : getDirectionsButton.frame.origin.y;
				taxiButton.frame = CGRectMake(frameWidth - 54, taxiButtonYPosition, 55, buttonHeight);
				taxiButton.backgroundColor = [UIColor clearColor];
				//taxiButton.alpha = .8;
				[taxiButton setTitle:@"Call taxi" forState:UIControlStateNormal];
				[taxiButton setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
				taxiButton.titleLabel.shadowColor = [UIColor blackColor];
				taxiButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
				taxiButton.titleLabel.font = font;
				taxiButton.tag = kCallTaxiTag;
				
				//xPosition = CGRectGetMaxX(taxiButton.frame) - 2;
				float taxiLabelButtonWidth = CGRectGetMaxX(taxiButton.frame) - 10;
				
				frameWidth = (taxiLabelButtonWidth > frameWidth) ? taxiLabelButtonWidth : frameWidth;
			}
			
			contentHeight = fmax(fmax(CGRectGetMaxY(getDirectionsButton.frame) - 8, CGRectGetMaxY(taxiButton.frame) - 8), contentHeight);
		}
		
		else contentHeight += 3; //space above distance and taxi info if there aren't any buttons

		
		NSString *distanceString = [self getDistanceString];
		
		if (distanceString != nil) {
			
			UIFont *distanceFont = [UIFont fontWithName:kFontName size:11];
			textBoxSize = [distanceString sizeWithFont: distanceFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
			
			float distanceLabelWidth = textBoxSize.width; // (textBoxSize.width > maxWidth - 48) ? maxWidth - 48 : textBoxSize.width;
			
			distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, contentHeight, distanceLabelWidth, 14)];
			distanceLabel.font = distanceFont;
			distanceLabel.shadowColor = [UIColor blackColor];
			distanceLabel.shadowOffset = CGSizeMake(1, 1);
			distanceLabel.text = distanceString;
			distanceLabel.textColor = [UIColor whiteColor];
			distanceLabel.backgroundColor = [UIColor clearColor];
			frameWidth = (CGRectGetMaxX(distanceLabel.frame) > frameWidth) ? CGRectGetMaxX(distanceLabel.frame) : frameWidth;
		}
		
		//Show taxi fare info as appropriate
		float taxiFare = [self getTaxiFare];
				
		if (taxiFare != kValueNotSet) {
			
			NSString *taxiString = (canCallTaxi) ? [NSString stringWithFormat:@"Est. %@%0.0f fare",[Props global].currencyString, taxiFare] : [NSString stringWithFormat:@"(est. %@%0.0f cab fare)",[Props global].currencyString, taxiFare];
			
			UIFont *taxiFont = [UIFont fontWithName:kFontName size:11];
			textBoxSize = [taxiString sizeWithFont: taxiFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
			
			float taxiLabelWidth = textBoxSize.width; // (textBoxSize.width > maxWidth - 48) ? maxWidth - 48 : textBoxSize.width;
			
			float xPos = (canCallTaxi) ? CGRectGetMaxX(taxiButton.frame) - taxiLabelWidth - 1 : (distanceLabel != nil) ? CGRectGetMaxX(distanceLabel.frame) + 4 : leftMargin;
			
			taxiLabel = [[UILabel alloc] initWithFrame:CGRectMake(xPos, contentHeight, taxiLabelWidth, 14)];
			taxiLabel.font = taxiFont;
			taxiLabel.shadowColor = [UIColor blackColor];
			taxiLabel.shadowOffset = CGSizeMake(1, 1);
			taxiLabel.text = taxiString;
			taxiLabel.textColor = [UIColor whiteColor];
			taxiLabel.backgroundColor = [UIColor clearColor];
			frameWidth = (taxiLabel.frame.size.width > frameWidth) ? taxiLabel.frame.size.width : frameWidth;
			frameWidth = (CGRectGetMaxX(taxiLabel.frame) > frameWidth) ? CGRectGetMaxX(taxiLabel.frame) : frameWidth;
		}
		
		contentHeight = fmax(fmax(CGRectGetMaxY(taxiLabel.frame), CGRectGetMaxY(distanceLabel.frame)), contentHeight);
	}
	
	frameWidth += 10;
	
	if (markerId == kUserLocation) contentHeight += 3;
	
	else contentHeight +=1;
	
	UIImageView *backgroundView = [[UIImageView alloc] init];
	backgroundView.backgroundColor = [UIColor clearColor];
	
	UIImage *bodyImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Marker_popup_body" ofType:@"png"]];
	
	UIImage *stretchableBody = [bodyImage stretchableImageWithLeftCapWidth:40 topCapHeight:0];
	
	UIImage *carrotImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Marker_popup_carrot" ofType:@"png"]];
	
	//need to sort out marker position on icon and popup position on screen
	float screenMarginWidth = 60;
	float popupMarginWidth = 15;
	float theCarrotPosition;
	float tweakLeft = -1; //tweak for some blank space on left side of popup body
	float tweakRight = 2; //tweak for some blank space on right side of popup body
	float frameX;
	
	//far left side of screen
	if (markerPoint.x < screenMarginWidth){
		//NSLog(@"Far left, marker Width = %f, carrotImageWidth = %f", markerWidth, carrotImage.size.width);
		frameX = tweakLeft - popupMarginWidth;
		theCarrotPosition = (markerWidth -carrotImage.size.width/2)/2;
		theCarrotPosition = theCarrotPosition - frameX; //adjust for frame offset
		//NSLog(@"Carrot postion = %f", theCarrotPosition);
	}
	
	//far right side of screen
	else if (markerPoint.x > [Props global].screenWidth - screenMarginWidth) {
		//NSLog(@"Far right");
		frameX =  -frameWidth + markerWidth + tweakRight + popupMarginWidth;
		//first relative to popup frame
		theCarrotPosition = frameWidth - carrotImage.size.width/4 - markerWidth/2 - 15;
		
		//NSLog(@"Carrot position = %f, carrot Width/2 = %f frame width = %f, markerWidth = %f, frameX = %f", theCarrotPosition, carrotImage.size.width/2, frameWidth, markerWidth, frameX);
	}
	
	//centered on screen
	else {
		//NSLog(@"Centered");
		float frameX_absolute =  ([Props global].screenWidth - frameWidth)/2;
		frameX = frameX_absolute - markerPoint.x + markerWidth/2;
		
		//fix it if the popup if it is too far off to either side
		
		//off of the left side 
		if ( frameX < -(frameWidth - markerWidth - popupMarginWidth)) {
			NSLog(@"Fixing off to left issue");
			frameX = -frameWidth + markerWidth + tweakRight + 15;
			theCarrotPosition = frameWidth - carrotImage.size.width/4 - markerWidth/2 - 15;
		}
		
		//off to the right side
		else if ( frameX >  - popupMarginWidth) {
			NSLog(@"Fixing off to right issue");
			frameX = tweakLeft - popupMarginWidth;
			theCarrotPosition = -frameX + (markerWidth - carrotImage.size.width/2)/2;
		}
		
		else theCarrotPosition = -frameX + (markerWidth - carrotImage.size.width/2)/2;
	}
	
	float height = contentHeight * 2.35; //magic value from trial and error, we draw background image at 2x scale for high resolution devices, so some scaleup from pixel values is necessary + extra for carrot height. There is problably a better way to do this.
	
	CGSize contextSize = CGSizeMake(frameWidth * 2 + 10, height);
	
	float frameYOffset = (marker == controller.destinationMarker) ? 5 : -1;
	self.frame =CGRectMake(frameX, -contextSize.height/2 + frameYOffset, frameWidth, contextSize.height/2);
	
	NSLog(@"Context width =  %f, height = %f", contextSize.width, contextSize.height);
	
	//UIGraphicsBeginImageContextWithOptions(contextSize, NO, 1);
	UIGraphicsBeginImageContext(contextSize);
	[stretchableBody drawInRect:CGRectMake(0, 0, contextSize.width, contextSize.height)];
	[carrotImage drawInRect:CGRectMake(theCarrotPosition * 2,0,carrotImage.size.width,contextSize.height)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	//UIImageWriteToSavedPhotosAlbum(newImage,  nil, nil, nil);

	backgroundView.image = newImage;
	backgroundView.frame = CGRectMake(0, 2, contextSize.width/2, contextSize.height/2);
	backgroundView.alpha = 0.85;
	backgroundView.backgroundColor = [UIColor clearColor];
	
	[self addSubview:backgroundView];
	
	//[newImage release];
	
	if (entryButton != nil) [self addSubview:entryButton];
	
	if (entryName != nil) {
		[self addSubview:entryName];
	}
	
	if (addressLabel != nil) {
		[self addSubview:addressLabel];
	}
	
	if (taglineLabel != nil) {
		[self addSubview:taglineLabel];
	}
	
	//buttons are autoreleased, so no need to release them
	if (getDirectionsButton != nil) [self addSubview: getDirectionsButton];
	
	if (taxiButton != nil) 	[self addSubview:taxiButton];

	if (taxiLabel != nil) {
		[self addSubview:taxiLabel];
	}
	
	if (distanceLabel != nil) {
		[self addSubview:distanceLabel];
	}
}


- (void) createMarker {
	
	float markerWidth = 10;
	CGPoint markerPoint = CGPointMake([Props global].screenWidth/2, [Props global].screenHeight/2); //**
	//**NSNumber *markerNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
	//**int markerId = [markerNumber intValue];
	
	[entry hydrateEntry];
	
	float maxWidth = 300;
	float frameWidth = 180;  //sets minimum frame width
	float contentHeight;
	float leftMargin = 10;
	
	//**** Add title label
	NSString *title = entry.name;
	
	CGSize textBoxSizeMax = CGSizeMake(maxWidth - leftMargin * 2, 60);
	UIFont *font =  [UIFont boldSystemFontOfSize:18];
	CGSize textBoxSize = [title sizeWithFont: font constrainedToSize: textBoxSizeMax lineBreakMode: 2];
	UIButton *entryButton = nil;
	UILabel *entryName = nil;
	
	/**if (marker == controller.destinationMarker || markerId == kUserLocation) {
		
		float labelWidth = (textBoxSize.width > maxWidth - 20) ? maxWidth - 20 : textBoxSize.width;
		entryName = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, 8, labelWidth, font.pointSize + 2)];
		entryName.font = font;
		entryName.shadowColor = [UIColor blackColor];
		entryName.shadowOffset = CGSizeMake(1, 1);
		entryName.text = title;
		entryName.textColor = [UIColor whiteColor];
		entryName.backgroundColor = [UIColor clearColor];
		contentHeight = CGRectGetMaxY(entryName.frame);
		frameWidth = fmax(CGRectGetMaxX(entryName.frame), frameWidth);
	}
	
	else {*/
		
		float labelWidth, labelX;
		
		if (textBoxSize.width > maxWidth - 2 * leftMargin) {
			labelWidth = maxWidth - 2 * leftMargin;
			labelX = leftMargin;
		}
		
		else {
			labelWidth = textBoxSize.width + 2*leftMargin;
			labelX = 0;
		}
        
		
		entryButton = [UIButton buttonWithType:0];
		entryButton.frame = CGRectMake(labelX, -11, labelWidth, font.pointSize + 42);
		entryButton.backgroundColor = [UIColor clearColor];
		[entryButton setTitle:entry.name forState:UIControlStateNormal];
    [entryButton addTarget:controller action:@selector(goToEntryFromButton:) forControlEvents:UIControlEventTouchUpInside];
		[entryButton setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
		entryButton.titleLabel.shadowColor = [UIColor blackColor];
		entryButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
		entryButton.titleLabel.font = font;
		entryButton.tag = entry.entryid;
		contentHeight = CGRectGetMaxY(entryButton.frame) - 21;
		frameWidth = fmax(CGRectGetMaxX(entryButton.frame) - 10, frameWidth);
	//**}
    
	
	//***** Add tagline as appropriate
	UILabel *taglineLabel = nil;
	if ([entry.tagline length] > 1) {
		
		font = [UIFont italicSystemFontOfSize:12];
		textBoxSize = [entry.tagline sizeWithFont: font constrainedToSize: textBoxSizeMax lineBreakMode: 0];
		
		taglineLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin - .5, contentHeight + 2, textBoxSize.width, textBoxSize.height)];
		taglineLabel.font = font;
		taglineLabel.shadowColor = [UIColor blackColor];
		taglineLabel.shadowOffset = CGSizeMake(1, 1);
		taglineLabel.text = entry.tagline;
		taglineLabel.textColor = [UIColor whiteColor];
		taglineLabel.backgroundColor = [UIColor clearColor];
		
		frameWidth = fmax(CGRectGetMaxX(taglineLabel.frame), frameWidth);
		contentHeight = CGRectGetMaxY(taglineLabel.frame);
	}
	
	
	//***** Add address label as appropriate
	UILabel *addressLabel = nil;
	NSString *address = entry.address;
	
	if ([address length] > 1) {
		
		font =  [UIFont systemFontOfSize:12];
		textBoxSize = [address sizeWithFont: font constrainedToSize: textBoxSizeMax lineBreakMode: 2];
		
		float addressLabelWidth = textBoxSize.width; // (textBoxSize.width > maxWidth - 48) ? maxWidth - 48 : textBoxSize.width;
		
		addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, contentHeight + 3, addressLabelWidth, 14)];
		addressLabel.font = font;
		addressLabel.shadowColor = [UIColor blackColor];
		addressLabel.shadowOffset = CGSizeMake(1, 1);
		addressLabel.text = address;
		addressLabel.textColor = [UIColor whiteColor];
		addressLabel.backgroundColor = [UIColor clearColor];
		
		frameWidth = fmax(CGRectGetMaxX(addressLabel.frame), frameWidth);
		contentHeight = fmax(CGRectGetMaxY(addressLabel.frame), contentHeight);
	}
	
	UILabel *distanceLabel = nil;
	UILabel *taxiLabel = nil;
	UIButton *taxiButton = nil;
	UIButton *getDirectionsButton = nil;
	
	//**if (markerId != kUserLocation) {
		
		CLLocation* destination = [[CLLocation alloc] initWithLatitude: [entry getLatitude] longitude: [entry getLongitude]];
		float distanceInMiles = [[LocationManager sharedLocationManager] getDistanceInMetersFromHereToPlace:destination]/1609;
		
		BOOL canCallTaxi = [[Props global].taxiServicePhoneNumber length] >= 10 && ([Props global].deviceType == kiPhone || [Props global].deviceType == kSimulator) && distanceInMiles < 200;
		
		//NSLog(@"Can call taxi = %@, distance = %f, taxi number = %@, deviceType = %i", canCallTaxi ? @"TRUE" : @"FALSE" , distanceInMiles, [Props global].taxiServicePhoneNumber, [Props global].deviceType);
		
		BOOL canShowDirections = [[Reachability sharedReachability] internetConnectionStatus] != NotReachable && [LocationManager sharedLocationManager].locationSet && [Props global].appID > 1;
		// add a buffer before the buttons
		
		if (canShowDirections || canCallTaxi) {
			contentHeight = contentHeight + 8;
			
			font =  [UIFont boldSystemFontOfSize:14];
			
			//**** Add get directions button
			float buttonHeight = 36;
			if (canShowDirections) {
				
				getDirectionsButton = [UIButton buttonWithType:0];
				getDirectionsButton.frame = CGRectMake(0, contentHeight - 9, 114, buttonHeight);
				getDirectionsButton.backgroundColor = [UIColor clearColor];
				//getDirectionsButton.alpha = .8;
				[getDirectionsButton setTitle:@"Get directions" forState:UIControlStateNormal];
				[getDirectionsButton setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
				getDirectionsButton.titleLabel.shadowColor = [UIColor blackColor];
				getDirectionsButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
				getDirectionsButton.titleLabel.font = font;
				getDirectionsButton.tag = kGetDirectionsTag;
				//xPosition = CGRectGetMaxX(getDirectionsButton.frame);
			}
			
			//*** Add taxi label button as appropriate
			if (canCallTaxi) {
				taxiButton = [UIButton buttonWithType:0];
				float taxiButtonYPosition = (getDirectionsButton == nil) ? contentHeight - 9 : getDirectionsButton.frame.origin.y;
				taxiButton.frame = CGRectMake(frameWidth - 54, taxiButtonYPosition, 55, buttonHeight);
				taxiButton.backgroundColor = [UIColor clearColor];
				//taxiButton.alpha = .8;
				[taxiButton setTitle:@"Call taxi" forState:UIControlStateNormal];
				[taxiButton setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
				taxiButton.titleLabel.shadowColor = [UIColor blackColor];
				taxiButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
				taxiButton.titleLabel.font = font;
				taxiButton.tag = kCallTaxiTag;
				
				//xPosition = CGRectGetMaxX(taxiButton.frame) - 2;
				float taxiLabelButtonWidth = CGRectGetMaxX(taxiButton.frame) - 10;
				
				frameWidth = (taxiLabelButtonWidth > frameWidth) ? taxiLabelButtonWidth : frameWidth;
			}
			
			contentHeight = fmax(fmax(CGRectGetMaxY(getDirectionsButton.frame) - 8, CGRectGetMaxY(taxiButton.frame) - 8), contentHeight);
		}
		
		else contentHeight += 3; //space above distance and taxi info if there aren't any buttons
        
		
		NSString *distanceString = [self getDistanceString];
		
		if (distanceString != nil) {
			
			UIFont *distanceFont = [UIFont fontWithName:kFontName size:11];
			textBoxSize = [distanceString sizeWithFont: distanceFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
			
			float distanceLabelWidth = textBoxSize.width; // (textBoxSize.width > maxWidth - 48) ? maxWidth - 48 : textBoxSize.width;
			
			distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, contentHeight, distanceLabelWidth, 14)];
			distanceLabel.font = distanceFont;
			distanceLabel.shadowColor = [UIColor blackColor];
			distanceLabel.shadowOffset = CGSizeMake(1, 1);
			distanceLabel.text = distanceString;
			distanceLabel.textColor = [UIColor whiteColor];
			distanceLabel.backgroundColor = [UIColor clearColor];
			frameWidth = (CGRectGetMaxX(distanceLabel.frame) > frameWidth) ? CGRectGetMaxX(distanceLabel.frame) : frameWidth;
		}
		
		//Show taxi fare info as appropriate
		float taxiFare = [self getTaxiFare];
        
		if (taxiFare != kValueNotSet) {
			
			NSString *taxiString = (canCallTaxi) ? [NSString stringWithFormat:@"Est. %@%0.0f fare",[Props global].currencyString, taxiFare] : [NSString stringWithFormat:@"(est. %@%0.0f cab fare)",[Props global].currencyString, taxiFare];
			
			UIFont *taxiFont = [UIFont fontWithName:kFontName size:11];
			textBoxSize = [taxiString sizeWithFont: taxiFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
			
			float taxiLabelWidth = textBoxSize.width; // (textBoxSize.width > maxWidth - 48) ? maxWidth - 48 : textBoxSize.width;
			
			float xPos = (canCallTaxi) ? CGRectGetMaxX(taxiButton.frame) - taxiLabelWidth - 1 : (distanceLabel != nil) ? CGRectGetMaxX(distanceLabel.frame) + 4 : leftMargin;
			
			taxiLabel = [[UILabel alloc] initWithFrame:CGRectMake(xPos, contentHeight, taxiLabelWidth, 14)];
			taxiLabel.font = taxiFont;
			taxiLabel.shadowColor = [UIColor blackColor];
			taxiLabel.shadowOffset = CGSizeMake(1, 1);
			taxiLabel.text = taxiString;
			taxiLabel.textColor = [UIColor whiteColor];
			taxiLabel.backgroundColor = [UIColor clearColor];
			frameWidth = (taxiLabel.frame.size.width > frameWidth) ? taxiLabel.frame.size.width : frameWidth;
			frameWidth = (CGRectGetMaxX(taxiLabel.frame) > frameWidth) ? CGRectGetMaxX(taxiLabel.frame) : frameWidth;
		}
		
		contentHeight = fmax(fmax(CGRectGetMaxY(taxiLabel.frame), CGRectGetMaxY(distanceLabel.frame)), contentHeight);
	//**}
	
	frameWidth += 10;
	
	//**if (markerId == kUserLocation) contentHeight += 3;
	
	/**else*/ contentHeight +=1;
	
	UIImageView *backgroundView = [[UIImageView alloc] init];
	backgroundView.backgroundColor = [UIColor clearColor];
	
	UIImage *bodyImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Marker_popup_body" ofType:@"png"]];
	
	UIImage *stretchableBody = [bodyImage stretchableImageWithLeftCapWidth:40 topCapHeight:0];
	
	UIImage *carrotImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Marker_popup_carrot" ofType:@"png"]];
	
	//need to sort out marker position on icon and popup position on screen
	float popupMarginWidth = 15;
	float theCarrotPosition;
	float tweakLeft = -1; //tweak for some blank space on left side of popup body
	//float tweakRight = 2; //tweak for some blank space on right side of popup body
	float frameX;
	
	
    //NSLog(@"Centered");
    float frameX_absolute =  ([Props global].screenWidth - frameWidth)/2;
    frameX = frameX_absolute - markerPoint.x + markerWidth/2;
    //NSLog(@"FrameX_abs = %f, frameX = %f, frameWidth = %f", frameX_absolute,frameX, frameWidth);
    
    //fix it if the popup if it is too far off to either side
    
    //off of the left side 
    if ( frameX < -(frameWidth - markerWidth - popupMarginWidth)) {
        NSLog(@"Fixing off to left issue");
        //frameX = -frameWidth + markerWidth + tweakRight + 15;
        theCarrotPosition = frameWidth - carrotImage.size.width/4 - markerWidth/2 - 15;
    }
    
    //off to the right side
    else if ( frameX >  - popupMarginWidth) {
        NSLog(@"Fixing off to right issue");
        frameX = tweakLeft - popupMarginWidth;
        theCarrotPosition = -frameX + (markerWidth - carrotImage.size.width/2)/2;
    }
    
    else theCarrotPosition = -frameX + (markerWidth - carrotImage.size.width/2)/2;
	
	
	float height = contentHeight * 2.35; //magic value from trial and error, we draw background image at 2x scale for high resolution devices, so some scaleup from pixel values is necessary + extra for carrot height. There is problably a better way to do this.
	
	CGSize contextSize = CGSizeMake(frameWidth * 2 + 10, height);
	
	self.frame =CGRectMake(0, 0, frameWidth, contextSize.height/2); //Center is set later
	
	NSLog(@"Context width =  %f, height = %f", contextSize.width, contextSize.height);
	
	//UIGraphicsBeginImageContextWithOptions(contextSize, NO, 1);
	UIGraphicsBeginImageContext(contextSize);
	[stretchableBody drawInRect:CGRectMake(0, 0, contextSize.width, contextSize.height)];
	[carrotImage drawInRect:CGRectMake(theCarrotPosition * 2,0,carrotImage.size.width,contextSize.height)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	//UIImageWriteToSavedPhotosAlbum(newImage,  nil, nil, nil);
    
	backgroundView.image = newImage;
	backgroundView.frame = CGRectMake(0, 2, contextSize.width/2, contextSize.height/2);
	backgroundView.alpha = 0.85;
	backgroundView.backgroundColor = [UIColor clearColor];
	
	[self addSubview:backgroundView];
    
	//[newImage release];
	
	if (entryButton != nil) [self addSubview:entryButton];
	
	if (entryName != nil) {
		[self addSubview:entryName];
	}
	
	if (addressLabel != nil) {
		[self addSubview:addressLabel];
	}
	
	if (taglineLabel != nil) {
		[self addSubview:taglineLabel];
	}
	
	//buttons are autoreleased, so no need to release them
	if (getDirectionsButton != nil) [self addSubview: getDirectionsButton];
	
	if (taxiButton != nil) 	[self addSubview:taxiButton];
    
	if (taxiLabel != nil) {
		[self addSubview:taxiLabel];
	}
	
	if (distanceLabel != nil) {
		[self addSubview:distanceLabel];
	}
}


- (NSString*) getDistanceString {
	
	NSString* distanceString;
	
	double latitude = [entry getLatitude];
	double longitude = [entry getLongitude];
	float distance = [[LocationManager sharedLocationManager] getDistanceFromHereToPlaceWithLatitude:latitude andLongitude:longitude];
	
	if(distance != kNoDistance) {
		
		NSString *distanceUnit;
		if ([Props global].unitsInMiles) distanceUnit = @"mi";
		else distanceUnit = @"km";
		
		if (distance < 100) distanceString = [NSString stringWithFormat:@"%0.1f %@ from you", distance, distanceUnit];
		
		else distanceString = [NSString stringWithFormat:@"%0.0f %@ from you", distance, distanceUnit];
	}
	
	else distanceString = nil;

	return distanceString;
}

/*
- (NSString *)subtitle {
	
	NSNumber *markerNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
	int markerId = [markerNumber intValue];
	
	NSString* subtitle = nil;
	
	if (entry != nil) {
		NSString* priceLabel;
		NSString* distanceLabel;
		
		int price = [entry getPrice];
		
		if(price == 0 && [Props global].appID != 0)
			priceLabel = [NSString stringWithFormat: @"Free!"];	
		
		else if(price == 0 && [Props global].appID == 0)
			priceLabel = [NSString stringWithFormat: @""];	
		
		else if (price > 0)
			priceLabel = [NSString stringWithFormat: @"%@%i", [Props global].currencyString, [entry getPrice]];
		
		else {
			NSLog(@"FIXME - Something weird going on with price info");
			priceLabel= @"";	
		}	 
		
		double latitude = [entry getLatitude];
		double longitude = [entry getLongitude];
		float distance = [[LocationManager sharedLocationManager] getDistanceFromHereToPlaceWithLatitude:latitude andLongitude:longitude];
		
		if(distance != kNoDistance) {
			
			NSString *distanceUnit;
			if ([Props global].unitsInMiles) distanceUnit = @"mi";
			else distanceUnit = @"km";
			
			if (distance < 100) distanceLabel = [NSString stringWithFormat:@"%0.1f %@ from you", distance, distanceUnit];
			
			else distanceLabel = [NSString stringWithFormat:@"%0.0f %@ from you", distance, distanceUnit];
		}
		
		else distanceLabel = @"";
		
		if ([priceLabel length] == 0) subtitle = distanceLabel;
		
		else subtitle = [NSString stringWithFormat:@"%@     %@", priceLabel, distanceLabel];
	}
	
	else if (markerId == kUserLocation)
		subtitle = [LocationManager sharedLocationManager].address;
	
	return subtitle;
}*/


- (float) getTaxiFare {
	
	float taxiFare = kValueNotSet;
	
	double latitude = [entry getLatitude];
	double longitude = [entry getLongitude];
	
	CLLocation* destination = [[CLLocation alloc] initWithLatitude: latitude longitude: longitude];
	
	float distanceInMeters = [[LocationManager sharedLocationManager] getDistanceInMetersFromHereToPlace:destination];
	
	
	if(distanceInMeters > 0 && distanceInMeters != kNoDistance && distanceInMeters < 1000 * 1000 && [Props global].taxiServiceChargePerDistance != kValueNotSet && ([Props global].taxiServiceChargePerDistance + [Props global].taxiServiceMinimumCharge) > 0) {
		
		float distanceInLocalUnits = ([Props global].unitsInMiles) ? distanceInMeters/1609.3 : distanceInMeters/ 1000;
		
		if(distanceInLocalUnits < 1000) {
			
			taxiFare = [Props global].taxiServiceMinimumCharge + distanceInLocalUnits * [Props global].taxiServiceChargePerDistance; //First order estimate - needs to be refined for waiting in traffic, airport, longer trips
		}
	}	
	
	return taxiFare;
}


@end
