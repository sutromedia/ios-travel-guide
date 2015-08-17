
//  IntroView.m
//
//  Created by Tobin1 on 2/24/09.


#import "MapViewController.h"
#import "LocationViewController.h"
#import "Entry.h"
#import "ActivityLogger.h"
#import "LocationManager.h"
#import	"EntryCollection.h"
#import "Reachability.h"
#import "SMLog.h"
#import "DataDownloader.h"
#import "RMMarker.h"
#import "RMMarkerManager.h"
#import "RMMapContents.h"
#import "RMDBMapsource.h"
#import "SMMapAnnotation.h"
#import "UpgradePitch.h"
#import "ImageManipulator.h"
#import <QuartzCore/QuartzCore.h> 

#define kUnselectedMarkerOpacity 1.0
#define kMarkerShadowOpacity 0.9;

@interface MapViewController (PrivateMethods)

- (void) goToEntry:(NSNumber*) sender;
- (void) addUserLocation;
- (void) createEditableCopyOfDatabaseIfNeeded;
- (CLLocationCoordinate2D) getScreen_NE_Corner;
- (CLLocationCoordinate2D) getScreen_SW_Corner;
- (void) getDirectionsForEntry:(Entry*) theEntry;
- (void)callTaxi;
- (UIImage*) generateMapMarkerForEntry:(Entry *) theEntry;

@end

@implementation MapViewController


@synthesize mapView, destinationMarker, userLocationMarker, userLocationBackground, entriesLoaded, entriesLoading, dataRefreshed;


- (id) init {
	
    self = [super init];
	if (self) {
		
		NSString *imageName = @"destinationIcon";
		UIImage *markerImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imageName ofType:@"png"]];
		self.destinationMarker = [[RMMarker alloc]initWithUIImage:markerImage anchorPoint:CGPointMake(.5, 1)];
		//[markerImage release];
		self.destinationMarker.bounds = CGRectMake(0, 0, 64 * 1.3, 35 * 1.3);
		self.destinationMarker.zPosition = kDestinationZPos;
		cornerRadiusFraction = 6;
		maxZoom = 17;
		//Not actually min zoom - used for setting marker sizes
		
		entriesLoaded = FALSE;
		
		CLLocationCoordinate2D mapCenter;
		mapCenter.latitude = [Props global].mapRegion.center.latitude + [Props global].mapRegion.span.latitudeDelta * .06;
		mapCenter.longitude = [Props global].mapRegion.center.longitude; 
		
		startingZoom = [Props global].startingZoomLevel;

		//self.mapView = [[RMMapView alloc]initWithFrame: CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - kTabBarHeight)];
		
		//self.mapView = [[RMMapView alloc]initWithFrame: self.view.bounds];
		//mapView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

        self.mapView = [[RMMapView alloc]initWithFrame: CGRectMake(0, 0, 100, 100)];
		//mapView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	
		id <RMTileSource> tileSource = [[RMDBMapSource alloc] initWithPath:[Props global].mapDatabaseLocation];
        //NSLog(@"Map database location = %@", [Props global].mapDatabaseLocation);
		
		mapContents = [[RMMapContents alloc] initWithView:mapView tilesource:tileSource centerLatLon:mapCenter zoomLevel:startingZoom maxZoomLevel:maxZoom minZoomLevel:1.45 backgroundImage:nil];
        
        //mapContents = [[RMMapContents alloc] initWithView:mapView tilesource:tileSource];
		
		mapView.contents = mapContents;
		mapView.backgroundColor = [UIColor colorWithRed:0.90 green:0.88 blue:0.86 alpha:1.0];
		
		self.view = mapView;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserLocation) name:kLocationUpdated object:nil]; 
		
		[self addUserLocation];
	}
	
	return self;	
}


- (float) getCurrentMarkerWidth {
	
	//The goal is to have the marker be the min size at the opening view and the max size at a fixed zoom level differntial below the opening level
	//This is to avoid having the markers be too small for guides that cover a broad area
	//The marker size stays the same when it is more zoomed in than maxSize zoom or more zoomed out than starting zoom
	
	float maxSizeZoom = fmin(maxZoom, startingZoom + 5); //can't have maxSizeZoom be greater than maxZoom 
	
	float currentZoom = fmax(startingZoom, mapView.contents.zoom); //don't let zoom value be less than starting zoom
	currentZoom = fmin(currentZoom, maxSizeZoom); //don't let zoom value be more than maxSizeZoom
	
	float scaleFactor = (1 - (maxSizeZoom - currentZoom)/(maxSizeZoom - startingZoom)); //should vary between 0 and 1, 0 when current zoom = startingZoom, 1 when zoom = maxSizeZoom
	
	float width = minMarkerWidth + scaleFactor * (maxMarkerWidth - minMarkerWidth);
	
	//NSLog(@"Width = %f, scaleFactor = %f, currentZoom = %f, actual current zoom = %f, maxSizeZoom = %f, maxZoom = %f, starting zoom = %f", width, scaleFactor, currentZoom, mapView.contents.zoom, maxSizeZoom, maxZoom, startingZoom);
	
	return width;
}


- (void) loadEntries {
	
	//[NSThread setStackSize:1024];
	
	@autoreleasepool {
	
	//Not actually min zoom - used for setting marker sizes
	//Also defined in init, but it appears that this is sometimes called first
		startingZoom = [Props global].startingZoomLevel;
		self.entriesLoading = TRUE;
		
		//add markers for surrounding entries
		float percentMapCoverage = .10; //actual coverage will be less than this, as many markers overlap
		float screenArea = [Props global].screenWidth * [Props global].screenHeight;
		
		minMarkerWidth = pow((percentMapCoverage * screenArea)/(float)[[EntryCollection sharedEntryCollection] numberOfEntries], .5);
		maxMarkerWidth = 55;
		
    //self.mapView.contents.zoom = [Props global].startingZoomLevel;
		CGRect markerBounds = CGRectMake(0, 0, [self getCurrentMarkerWidth], [self getCurrentMarkerWidth]);
    
    //NSLog(@"MVC.loadEntries: marker width = %f", markerBounds.size.width);
			
		NSString *theFolderPath = [NSString stringWithFormat:@"%@/images",[Props global].contentFolder];
		
		if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath])
			[[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ];
		
		//NSString *theImagePath = [[NSBundle mainBundle]  pathForResource:[NSString stringWithFormat:@"102022-marker"] ofType:@"png"];
		
		//UIImage *markerImage = [[UIImage alloc] initWithContentsOfFile:theImagePath];
		UIImage *genericMarkerImage = nil;
		
		showGenericMarkers = ([[EntryCollection sharedEntryCollection] numberOfEntries] > 350 && [Props global].osVersion <= 4.1 ) || [[EntryCollection sharedEntryCollection] numberOfEntries] > 500;
		
		if (showGenericMarkers) genericMarkerImage = [[UIImage alloc] initWithContentsOfFile: [[NSBundle mainBundle]  pathForResource:@"marker-blue" ofType:@"png"]];
		
    NSLog(@"Entries collection has %i entries", [[EntryCollection sharedEntryCollection].allEntries count]);
    
    [Props global].killDataDownloader = FALSE;
			
		for(Entry *theEntry in [EntryCollection sharedEntryCollection].allEntries) {
			
        if (!([theEntry getLatitude]== 0 && [theEntry getLongitude]== 0)) {
				
				@autoreleasepool {
				
				//NSLog(@"MVC.loadEntries: loading %@ at %f, %f", theEntry.name, [theEntry getLatitude], [theEntry getLongitude]);
                //NSLog(@"MVC.loadEntries: loading %@", theEntry.name);
				
				CLLocationCoordinate2D newPinSpot;
				newPinSpot.latitude = [theEntry getLatitude];
				newPinSpot.longitude = [theEntry getLongitude];
				
				RMMarker *marker = nil;
				
				if (showGenericMarkers) marker = [[RMMarker alloc]initWithUIImage:genericMarkerImage];
				
				else {
					
					UIImage *markerImage = nil;
					NSString *theImagePath = [[NSBundle mainBundle]  pathForResource:[NSString stringWithFormat:@"%i-marker", theEntry.icon] ofType:@"png"];
                    
                    //NSLog(@"MVC.loadEntries: trying to load image from %@", theImagePath);
                    markerImage = [UIImage imageWithContentsOfFile:theImagePath];
					
					
					if (markerImage == nil) {
						//NSLog(@"MVC.loadEntries: Loading entry from images folder");
						theImagePath = [NSString stringWithFormat:@"%@/images/%i-marker.png",[Props global].contentFolder , theEntry.icon];
						//markerImage = [[UIImage alloc] initWithContentsOfFile:theImagePath];
						markerImage = [UIImage imageWithContentsOfFile:theImagePath];
					}
					
					if (markerImage == nil) {
						
						NSLog(@"*******WARNING: MVC.loadEntries: Missing map marker for %@, %i", theEntry.name, theEntry.icon);
						markerImage = [self generateMapMarkerForEntry:theEntry];
					}
					
					if (markerImage != nil) marker = [[RMMarker alloc]initWithUIImage:markerImage];
				}
				
				if (marker != nil) {
					
					//NSLog(@"Adding %@ at %f,%f", theEntry.name, newPinSpot.latitude, newPinSpot.longitude);
					marker.bounds = markerBounds;
					marker.opaque = NO;
					marker.opacity = kUnselectedMarkerOpacity;
					marker.zPosition = kEntryMarkerZPos;
					marker.hidden = TRUE; //![[EntryCollection sharedEntryCollection] containsEntry:theEntry];
                
                if (!showGenericMarkers) {
                    marker.shadowOpacity = kMarkerShadowOpacity;
                    marker.shadowOffset = CGSizeMake(markerBounds.size.width/12, markerBounds.size.width/7);
                    marker.shadowRadius = marker.shadowOffset.width/12;
                    marker.shadowColor = [UIColor darkGrayColor].CGColor;
                }
					
					//NSLog(@"%@ is %@ hidden",theEntry.name, marker.hidden ? @"" : @"not");
					
					NSNumber *idValue = [NSNumber numberWithInt:theEntry.entryid];
					marker.data = [[NSMutableDictionary alloc] init];
					[marker.data setValue:idValue forKey:@"ID"];
                    [marker.data setValue:[NSNumber numberWithFloat:newPinSpot.latitude] forKey:@"latitude"];
                    [marker.data setValue:[NSNumber numberWithFloat:newPinSpot.longitude] forKey:@"longitude"];
					
					[self.mapView.contents.markerManager addMarker:marker AtLatLong:newPinSpot];
				}
            
            if ([Props global].killDataDownloader) {
                NSLog(@"MVC.loadEntries: About to break");
                break;
            }
            
            //else NSLog(@"MVC.loadEntries: loading");

				
				}
            
				[NSThread sleepForTimeInterval:0.002];
			}
		}
		
		//if (showGenericMarkers) [genericMarkerImage release];
		
        entriesLoading = FALSE;
		entriesLoaded = TRUE;
		
        [[NSNotificationCenter defaultCenter] postNotificationName:kMapMarkersLoaded object:nil];
		NSLog(@"MVC.loadEntries: done");
	}
}


- (CLLocationCoordinate2D) getScreen_NE_Corner {
	
	float latitude = mapView.contents.mapCenter.latitude;
	
	float metersPerDegreeLong = 111132*cos(latitude * 3.17159/180);
	
	//float maxLat = mapView.contents.mapCenter.latitude + mapView.contents.metersPerPixel * (self.mapView.frame.size.height/2) / metersPerDegreeLat;
	
	float zoom = mapView.contents.zoom; // 9.24561688214405 - 3.3203169287079 * log10([Props global].mapRegion.span.latitudeDelta * 2);
	
	//float deltaLat = pow(10, ((zoom - 9.24561688214405)/-3.3203169287079));
	
	float deltaLat = 445/pow(2, zoom);
	
	
	//NSLog(@"Center lat = %f, Delta lat = %f, zoom = %f",latitude, deltaLat, zoom);
	
	float maxLat = latitude + deltaLat/2;
	
	//float minLat = mapView.center.latitude - mapView.contents.metersPerPixel * [Props global].screenHeight * metersPerDegreeLat;
	float maxLong = mapView.contents.mapCenter.longitude + mapView.contents.metersPerPixel * (self.mapView.frame.size.width/2) / metersPerDegreeLong;
	//float minLong = mapView.center.longitude - mapView.contents.metersPerPixel * [Props global].screenWidth * metersPerDegreeLong;
	 
	CLLocationCoordinate2D NE_corner;
	NE_corner.latitude = maxLat;
	NE_corner.longitude = maxLong;
	
	return NE_corner;
}


- (CLLocationCoordinate2D) getScreen_SW_Corner {
		
	float latitude = mapView.contents.mapCenter.latitude;
	
	float metersPerDegreeLong = 111132*cos(latitude * 3.17159/180);
	
	//float maxLat = mapView.center.latitude + mapView.contents.metersPerPixel * [Props global].screenHeight * metersPerDegreeLat;
	//float minLat = mapView.contents.mapCenter.latitude - mapView.contents.metersPerPixel * (self.mapView.frame.size.height/2) / metersPerDegreeLat;
	
	float zoom = mapView.contents.zoom;
	float deltaLat = 445/pow(2, zoom);
	
	
	//NSLog(@"Center lat = %f, Delta lat = %f, zoom = %f",latitude, deltaLat, zoom);
	
	float minLat = latitude - deltaLat/2;
	
	//float maxLong = mapView.center.longitude + mapView.contents.metersPerPixel * [Props global].screenWidth * metersPerDegreeLong;
	float minLong = mapView.contents.mapCenter.longitude - mapView.contents.metersPerPixel * (self.mapView.frame.size.width/2) / metersPerDegreeLong;
	
	CLLocationCoordinate2D SW_corner;
	SW_corner.latitude = minLat;
	SW_corner.longitude = minLong;
	
	
	return SW_corner;
}


- (BOOL) shouldMove:(CGSize) delta {
	
	CLLocationCoordinate2D NE_corner = [self getScreen_NE_Corner];
	CLLocationCoordinate2D SW_corner = [self getScreen_SW_Corner];
	
	float maxLat = 104; //[Props global].mapRegion.center.latitude + 2 * [Props global].mapRegion.span.latitudeDelta;
	float minLat = -72; //[Props global].mapRegion.center.latitude - 2 * [Props global].mapRegion.span.latitudeDelta;
	float maxLong = 280; //[Props global].mapRegion.center.longitude + 2 * [Props global].mapRegion.span.longitudeDelta;
	float minLong = -280; //[Props global].mapRegion.center.longitude - 2 * [Props global].mapRegion.span.longitudeDelta;
	
	//NSLog(@"Delta width = %f", delta.width);
	//NSLog(@"Min long = %f, max long = %f", SW_corner.longitude, NE_corner.longitude);
    
	//move up
	//NSLog(@"NE Corner lat = %f, delta.height = %f, and maxLat = %f", NE_corner.latitude, delta.height, maxLat);
	if (delta.height >= 0 && NE_corner.latitude >= maxLat) {
		//NSLog(@"About to return no");
		float deltaOver = (NE_corner.latitude - maxLat) * .5;
		
		//NSLog(@"Current map center = %f", mapView.contents.mapCenter.latitude);
		
		CLLocationCoordinate2D newCenter;
		newCenter.longitude = mapView.contents.mapCenter.longitude;
		newCenter.latitude = mapView.contents.mapCenter.latitude - deltaOver;
		
		//NSLog(@"Delta over = %f and new center lat = %f", deltaOver, newCenter.latitude);
		[mapView moveToLatLong:newCenter];
		
		return NO;
	}
	
	//move down
	else if (delta.height <= 0 && SW_corner.latitude <= minLat){
		
		float deltaOver = (SW_corner.latitude - minLat) * .5;
		
		//NSLog(@"Current map center = %f", mapView.contents.mapCenter.latitude);
		
		CLLocationCoordinate2D newCenter;
		newCenter.longitude = mapView.contents.mapCenter.longitude;
		newCenter.latitude = mapView.contents.mapCenter.latitude - deltaOver;
		
		//NSLog(@"Delta over = %f and new center lat = %f", deltaOver, newCenter.latitude);
		[mapView moveToLatLong:newCenter];
		
		return NO;
	}
	
	//move left
	else if (delta.width < 0 && NE_corner.longitude >= maxLong){
		NSLog(@"Don't go left");
		return NO;
	}
	
	//move right
	else if (delta.width > 0 && SW_corner.longitude <= minLong){
		NSLog(@"Don't go right");
		return NO;
	}
	
	//NSLog(@"NE Corner = %f, %f", NE_corner.latitude, NE_corner.longitude);
	//NSLog(@"SW Corner = %f, %f", SW_corner.latitude, SW_corner.longitude);
	//NSLog(@"Maxlat = %f, Maxlong = %f, MinLat = %f, MinLong = %f", maxLat, maxLong, minLat, minLong);
	//NSLog(@"User location = %f, %f", newPinSpot.latitude, newPinSpot.longitude);
	
	return YES;
}


- (void) addUserLocation {

	//Add blue dot for person
	CLLocationCoordinate2D newPinSpot;
	newPinSpot.latitude = [[LocationManager sharedLocationManager] getLatitude];
	newPinSpot.longitude = [[LocationManager sharedLocationManager] getLongitude];
	NSString *imageName = @"userLocation";
	
	UIImage *markerImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imageName ofType:@"png"]];
	
	userLocationMarker = [[RMMarker alloc]initWithUIImage:markerImage anchorPoint:CGPointMake(0.5, 0.5)];
	
	
	userLocationMarker.bounds = CGRectMake(0, 0, kUserLocationMarkerWidth, kUserLocationMarkerWidth);
	userLocationMarker.data = [[NSMutableDictionary alloc] init];
	NSNumber *idValue = [NSNumber numberWithInt:kUserLocation];
	userLocationMarker.zPosition = kUserLocationZPos;
	[userLocationMarker.data setValue:idValue forKey:@"ID"];
	userLocationMarker.hidden = FALSE;
	
	[self.mapView.contents.markerManager addMarker:userLocationMarker
										 AtLatLong:newPinSpot];
	
	UIImage *markerImage2 = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"userLocationBackground2" ofType:@"png"]];
	
	userLocationBackground = [[RMMarker alloc]initWithUIImage:markerImage2 anchorPoint:CGPointMake(0.5, 0.5)];
	
	
	userLocationBackground.bounds = CGRectMake(0, 0, kUserLocationMarkerWidth, kUserLocationMarkerWidth);
	userLocationBackground.data = [[NSMutableDictionary alloc] init];
	idValue = [NSNumber numberWithInt:kUserLocationBackground];
	[userLocationBackground.data setValue:idValue forKey:@"ID"];
	userLocationBackground.zPosition = kUserLocationBackZPos;
	
	[self.mapView.contents.markerManager addMarker:userLocationBackground AtLatLong:newPinSpot];
	
	//This causes dealloc to get called???
	//[NSTimer scheduledTimerWithTimeInterval: 3 target:self selector:@selector(updateUserLocation:) userInfo:nil repeats:YES];
	
	[self performSelectorInBackground:@selector(pulseUser:) withObject:nil];
}


- (void) updateUserLocation {

	CLLocationCoordinate2D newPinSpot;
	newPinSpot.latitude = [[LocationManager sharedLocationManager] getLatitude];
	newPinSpot.longitude = [[LocationManager sharedLocationManager] getLongitude];
    
    NSLog(@"MVC.updateUserLocation to %0.5f, %0.5f", newPinSpot.latitude, newPinSpot.longitude);
    
    [ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
    [ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
    [ UIView setAnimationDuration: 0.2f ];
	
	[mapView.contents.markerManager moveMarker:userLocationMarker AtLatLon:newPinSpot];
	[mapView.contents.markerManager moveMarker:userLocationBackground AtLatLon:newPinSpot];
    
    [UIView commitAnimations];
}

- (void) pulseUser: (id) sender {

	//NSLog(@"MVC.pulseUser");
	@autoreleasepool {
	
		float duration = 1.5; //seconds
		
		
		[CATransaction begin];
		
		
		[CATransaction setValue:[NSNumber numberWithFloat:duration] forKey:kCATransactionAnimationDuration];	
		
		
		//bloom does the fading in and out
		
		CABasicAnimation* bloom = [CABasicAnimation animationWithKeyPath:@"opacity"];
		bloom.fromValue = [NSNumber numberWithFloat:1.0];
		bloom.toValue = [NSNumber numberWithFloat:0.2];
		bloom.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		bloom.duration = duration;
		bloom.autoreverses = NO;
		bloom.repeatCount = 0; //1e100;
		bloom.delegate = self;
		//bloom.removedOnCompletion = YES;
		
		[userLocationBackground addAnimation:bloom forKey:@"bloom"];
		
		
		
		//scalingAnimation makes it grow
		
		CABasicAnimation *scalingAnimation;
		
		scalingAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
		scalingAnimation.duration=duration;
		scalingAnimation.autoreverses=NO;
		scalingAnimation.repeatCount = 0; //1e100;
		scalingAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		scalingAnimation.fromValue=[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)];
		scalingAnimation.toValue=[NSValue valueWithCATransform3D:CATransform3DMakeScale(13, 13, 13)];
		
		[userLocationBackground addAnimation:scalingAnimation forKey:@"scaling"];
		
		[CATransaction commit];
	
	//[userLocationBackground addAnimation:bounce forKey:@"bounceAnimation"];
	}
}


- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	
	//NSLog(@"Animation finished - %@", theAnimation);
	
	//This causes dealloc to get called?????
	if (shouldPulse) [NSTimer scheduledTimerWithTimeInterval: 1.5 target:self selector:@selector(pulseUser:) userInfo:nil repeats:NO];
	//[self pulseUser];
}

- (void) stopPulsingUser {

	shouldPulse = FALSE;
}

- (void) startPulsingUser {
	
	shouldPulse = TRUE;
	[self pulseUser:nil];
}



- (void) afterMapZoom: (RMMapView*) map byFactor: (float) zoomFactor near:(CGPoint) center {
	
	NSLog(@"MVC.afterMapZoom:Current map center = %f, %f", mapView.contents.mapCenter.latitude, mapView.contents.mapCenter.longitude);
    
	//float deltaLat = [self getScreen_NE_Corner].latitude - [self getScreen_SW_Corner].latitude;
	
	//float predictedZoom = 9.24561688214405 - 3.3203169287079 * log10(deltaLat);
	
	//NSLog(@"MVC.afterMapZoom: zoom = %f, predictedZoom = %f, error = %f", mapView.contents.zoom, predictedZoom, (mapView.contents.zoom - predictedZoom)/mapView.contents.zoom);
	float markerWidth = [self getCurrentMarkerWidth];
	//NSLog(@"MVC.afterMapZoom: marker width = %f", markerWidth);
	CGRect markerBounds = CGRectMake(0, 0, markerWidth, markerWidth);
	
    if (entriesLoaded) {
    
        for (RMMarker *marker in [map.contents.markerManager markers]){
            
            if (marker != userLocationMarker && marker != destinationMarker && marker != userLocationBackground) {
                
                marker.shadowOffset = CGSizeMake(markerWidth/12, markerWidth/7);
                marker.shadowRadius = markerWidth/12;
                
                if (marker.label == nil || [marker.label isHidden]) {
                    
                    //Replace any higher resolution images (a few may slip through the cracks of this approach, not a big deal though)
                    if (marker.bounds.size.width != marker.bounds.size.height) {
                        NSNumber *markerNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
                        int markerId = [markerNumber intValue];
                        
                        Entry *theEntry = [EntryCollection entryById:markerId];
                        
                        //UIImage *markerImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"%i-icon", theEntry.icon] ofType:@"jpg"]];
                         UIImage *markerImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100", theEntry.icon] ofType:@"jpg"]];
                        
                        if (markerImage == nil) 
                            markerImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , theEntry.icon]];
                        
                        float cornerRadius = markerImage.size.height/cornerRadiusFraction;
                        
                        UIImage *roundedImage = [ImageManipulator makeRoundCornerImage:markerImage :cornerRadius :cornerRadius];
                        
                        [marker replaceUIImage:roundedImage];
                        
                        
                        marker.opaque = NO;
                        marker.opacity = kUnselectedMarkerOpacity;
                    }
                    
                    
                    marker.bounds = markerBounds;
                }
                
                else {
                    marker.bounds = CGRectMake(0, 0, markerWidth * 2.5, markerWidth * 2.5);

                    
                    //go to a higher resolution image as necessary
                    if (marker.bounds.size.width > 45) {
                        NSNumber *markerNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
                        int markerId = [markerNumber intValue];
                        
                        Entry *theEntry = [EntryCollection entryById:markerId];
                        
                        UIImage *markerImage = theEntry.iconImage;
                        
                        float cornerRadius = markerImage.size.height/cornerRadiusFraction;
                        
                        UIImage *roundedImage = [ImageManipulator makeRoundCornerImage:markerImage :cornerRadius :cornerRadius];
                        
                        [marker replaceUIImage:roundedImage];
                        
                        markerWidth = markerWidth * 2.5;
                        //keep area constant and proportions correct
                        float area = markerWidth * markerWidth;
                        float aspect = roundedImage.size.width/roundedImage.size.height;
                        
                        float markerHeight = pow(area/aspect, 0.5);
                        markerWidth = aspect * markerHeight;
                        
                        marker.bounds = CGRectMake(0, 0, markerWidth, markerHeight);
                        
                    }
                }
            }
        }
		//NSLog(@"Marker width = %f", marker.bounds.size.width);
	}
    
    else NSLog(@"**Ha ha, looks like we avoided a race!");
}


- (void) hideAllMarkers {
	
	if (entriesLoaded) {
        for (RMMarker *marker in [mapView.contents.markerManager markers]){
            
            if(marker != userLocationMarker && marker != userLocationBackground) marker.hidden = TRUE;
        }
    }
}


- (void) singleTapOnMap: (RMMapView*) map At: (CGPoint) point {

	[self performSelectorInBackground:@selector(hideAnyMarkerAnnotations) withObject:nil];
	/*for (RMMarker *marker in [map.contents.markerManager markers]){
	
		if (marker.label != nil && ![marker.label isHidden]) {
			
			NSLog(@"Hiding marker label");
			[marker hideLabel];
			
			if (marker.bounds.size.width != marker.bounds.size.height && marker != destinationMarker && marker != userLocationMarker && marker != userLocationBackground) {
				
				NSNumber *markerNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
				int markerId = [markerNumber intValue];
				
				Entry *theEntry = [EntryCollection entryById:markerId];
				
				UIImage *markerImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"%i-icon", theEntry.icon] ofType:@"jpg"]];
				
				float cornerRadius =markerImage.size.width/cornerRadiusFraction;
				
				UIImage *roundedImage = [ImageManipulator makeRoundCornerImage:markerImage :cornerRadius :cornerRadius];
				
				[marker replaceUIImage:roundedImage];
				
				marker.opaque = NO;
				marker.opacity = kUnselectedMarkerOpacity;
				
				[roundedImage release];
			}
			
			if(marker != userLocationMarker && marker != destinationMarker && marker != userLocationBackground){
				marker.bounds = CGRectMake(0, 0, [self getCurrentMarkerWidth], [self getCurrentMarkerWidth]);
				marker.zPosition = -3;
			}
			
			else if (marker == userLocationMarker) marker.zPosition = kUserLocationZPos;
			
			else if (marker == destinationMarker) marker.zPosition = kDestinationZPos;
		}
	}*/
}


- (void) tapOnMarker: (RMMarker*) marker onMap: (RMMapView*) map withViewRect:(CGRect) viewRect fromSender:(id) sender {
	
	CGPoint markerPoint = [self.mapView.contents.markerManager screenCoordinatesForMarker:marker];
	
	NSNumber *markerNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
	int markerId = [markerNumber intValue];
	
	NSLog(@"MapViewController.tapOnMarker: markerid = %i, screen position = %f, %f", markerId, markerPoint.x, markerPoint.y);
		
		
	Entry *theEntry = (marker != userLocationMarker && marker != userLocationBackground) ? [EntryCollection entryById:markerId] : nil;
	
	//go to entry if it's currently showing
	if (marker.label != nil && ![marker.label isHidden]){
		
		if (marker == destinationMarker || marker == userLocationMarker) [self hideAnnotationForMarker:marker];
		
		else [sender goToEntry:[NSNumber numberWithInt:theEntry.entryid]]; 
	}
		
	//Otherwise show the label, expand the marker, and hide and labels currently showing
	else {
		
		marker.zPosition = 0;
		float scaleFactor = 2.5;
		float maxWidth = 100;
		float markerWidth = marker.bounds.size.width * scaleFactor;
		markerWidth = (markerWidth > maxWidth) ? maxWidth : markerWidth;
		
		if (marker != userLocationMarker && marker != userLocationBackground && marker != destinationMarker) {
			
			//if (markerWidth < 44) marker.bounds = CGRectMake(0, 0, markerWidth, markerWidth);
			
			//Replace image with higher resolution one as necessary
			//else {
				
			UIImage *markerImage = theEntry.iconImage;
			
			float cornerRadius = markerImage.size.height/cornerRadiusFraction;
			
			UIImage *roundedImage = [ImageManipulator makeRoundCornerImage:markerImage :cornerRadius :cornerRadius];
			
			[marker replaceUIImage:roundedImage];
			
			//keep area constant and proportions correct
			float area = markerWidth * markerWidth;
			float aspect = roundedImage.size.width/roundedImage.size.height;
			
			float markerHeight = pow(area/aspect, 0.5);
			markerWidth = aspect * markerHeight;
			
			marker.bounds = CGRectMake(0, 0, markerWidth, markerHeight);
			
			//[roundedImage release];
			//[markerImage release];
			//}
			
			marker.opaque = YES;
			marker.opacity = 1;
            marker.opacity = 1.0;
            
            if (!showGenericMarkers) {
                marker.shadowOpacity = kMarkerShadowOpacity;
                marker.shadowOffset = CGSizeMake(markerWidth/15, markerWidth/7);
                marker.shadowRadius = markerWidth/12;
                marker.shadowColor = [UIColor darkGrayColor].CGColor;
            }
		}
	
		
		SMMapAnnotation *label = [[SMMapAnnotation alloc] initWithMarker:marker andController:self];
		
		//Adjust map to make sure that the marker label isn't off the screen
		float borderMargin = 5;
		float yMinHeight = viewRect.origin.y + borderMargin;
		
		NSLog(@"Y-Min height = %f", yMinHeight);
		
		//x-axis adjustments
		//too far to left
		if (markerPoint.x - marker.bounds.size.width/2 - (-label.frame.origin.x) < borderMargin) {
			[self.mapView moveBy:CGSizeMake(borderMargin - (markerPoint.x - marker.bounds.size.width/2 - (-label.frame.origin.x)), 0)];
		}
		
		//too far to right
		else if (markerPoint.x - marker.bounds.size.width/2 + CGRectGetMaxX(label.frame)  > [Props global].screenWidth - borderMargin) {
			float moveDistance = ([Props global].screenWidth - borderMargin) - (markerPoint.x - marker.bounds.size.width/2 + CGRectGetMaxX(label.frame)) ;
			[self.mapView moveBy:CGSizeMake(moveDistance, 0)];
			NSLog(@"Move distance = %f", moveDistance);
		}
		
		//y-axis adjustments
		//move markers that are too high downwards
		if (markerPoint.y - marker.bounds.size.height - (-label.frame.origin.y) < yMinHeight) {
			NSLog(@"Label y origin = %f", label.frame.origin.y);
			float moveDistance = yMinHeight - (markerPoint.y - marker.bounds.size.height - (-label.frame.origin.y));
			[self.mapView moveBy:CGSizeMake(0, moveDistance)];
		}
		
		
		//move markers that are too low upwards
		else if (markerPoint.y > [Props global].screenHeight - kTabBarHeight - borderMargin) {
			NSLog(@"Label y origin = %f", label.frame.origin.y);
			float moveDistance = [Props global].screenHeight - kTabBarHeight - borderMargin - markerPoint.y;
			[self.mapView moveBy:CGSizeMake(0, moveDistance)];
		}
		
		[marker setLabel:label];
		
		[marker showLabel];
		
		
		//Shrink down any previously expanded markers and hide their labels
		//CGRect markerBounds = CGRectMake(0, 0, [self getCurrentMarkerWidth], [self getCurrentMarkerWidth])
        
        for (RMMarker *theMarker in [map.contents.markerManager markers]){
            
            //only worry about markers with labels showing
            if (theMarker.label != nil && theMarker != marker) {
                
                [theMarker hideLabel];
                theMarker.label = nil;
                
                //Don't shrink destination or user location markers
                if (theMarker != userLocationMarker && theMarker != userLocationBackground && theMarker != destinationMarker){
                    
                    [self hideAnnotationForMarker:theMarker];
                    
                    /*
                     theMarker.zPosition = -3;
                     
                     //Replace image if it's a non-square higher resolution image (minor issue here if image happens to be square)
                     if (theMarker.bounds.size.width != theMarker.bounds.size.height) {
                     NSNumber *markerNumber = (NSNumber*) [theMarker.data valueForKey:@"ID"];
                     int markerId = [markerNumber intValue];
                     
                     Entry *e = [EntryCollection entryById:markerId];
                     NSLog(@"MVC.tapOnMarker: replacing high resolution image with smaller one for %@", e.name);
                     UIImage *markerImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"%i-icon", e.icon] ofType:@"jpg"]];
                     
                     //Get it from the docs folder as necessary for the test app
                     if (markerImage == nil) markerImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i-icon.jpg",[Props global].contentFolder , theEntry.icon]];
                     
                     //Use a smaller resolution one if necessary
                     if (markerImage == nil) markerImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"%i_151x", theEntry.icon] ofType:@"jpg"]];
                     
                     float cornerRadius = markerImage.size.height/cornerRadiusFraction;
                     
                     UIImage *roundedImage = [ImageManipulator makeRoundCornerImage:markerImage :cornerRadius :cornerRadius];
                     
                     [theMarker replaceUIImage:roundedImage];
                     }
                     
                     theMarker.bounds = markerBounds;
                     theMarker.opaque = NO;
                     theMarker.opacity = kUnselectedMarkerOpacity;
                     */
                }
                
                else if (marker == userLocationMarker) marker.zPosition = kUserLocationZPos; //set the destination and user location markers to -1
                else if (marker == userLocationBackground) marker.zPosition = kUserLocationBackZPos;
                
                else if (marker == destinationMarker) marker.zPosition = kDestinationZPos;
            }
        }
	}
}


- (void) tapOnLabelForMarker: (RMMarker*) marker onMap: (RMMapView*) map onLayer: (CALayer *)layer fromSender:(id) sender {
	
	NSLog(@"MVC.tapOnLableForMarker: class = %@", [marker class]);
	NSLog(@"MVC.tapOnLabelForMarker with %i control layers", [marker.controlLayers count] );
  
	for (UIView *controlLayer in marker.controlLayers) {
        if (controlLayer.layer == layer) {
			UIButton *button = (UIButton*) controlLayer;
			if (button.tag == kCallTaxiTag && ([Props global].deviceType == kiPhone || [Props global].deviceType == kSimulator)){
				UIAlertView *callAlert = [[UIAlertView alloc] initWithTitle: nil message:@"Leave app to call taxi?" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Okay", nil];
				callAlert.tag = kCallTaxiAlertTag;
				[callAlert performSelector:@selector(show) withObject:nil afterDelay:0.01];
			}
			
			else if (button.tag == kGetDirectionsTag){
				NSNumber *markerNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
			
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle: nil message:@"Leave app to get directions?" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Okay", nil];
				alert.tag = [markerNumber intValue];
				[alert performSelector:@selector(show) withObject:nil afterDelay:0.01];
			}
            //NSLog(@"Point contained within control layer:  %@", [controlLayer description]);
			else {
				[sender goToEntry:[NSNumber numberWithInt:controlLayer.tag]];
			}
        } 
    }
	
	[self hideAnnotationForMarker:marker];
}


- (void) hideAnyMarkerAnnotations {
    
    @autoreleasepool {
    
        while (!entriesLoaded) {
            [NSThread sleepForTimeInterval:0.1];
        }
	
	for (RMMarker *marker in [self.mapView.contents.markerManager markers]){
		
		if (marker.label != nil && ![marker.label isHidden]) [self hideAnnotationForMarker:marker];
	}
    
    }
}


- (void) hideAnnotationForMarker:(RMMarker*) marker {
	
	//NSLog(@"Hiding marker label");
	
	marker.zPosition = -3;
	
	[marker hideLabel];
	
	NSNumber *markerNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
	int markerId = [markerNumber intValue];
	
	Entry *theEntry = (marker != userLocationMarker && marker != userLocationBackground) ? [EntryCollection entryById:markerId] : nil;
	
	if (marker != userLocationMarker && marker != userLocationBackground && marker != destinationMarker) {
		
		if (marker.bounds.size.width != [self getCurrentMarkerWidth]) {
			
			UIImage *markerImage;
            
            if (showGenericMarkers) {
                markerImage = [[UIImage alloc] initWithContentsOfFile: [[NSBundle mainBundle]  pathForResource:@"marker-blue" ofType:@"png"]];
            }
            
            else markerImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"%i-marker", theEntry.icon] ofType:@"png"]];
            
			//Get it from the docs folder as necessary for the test app
			if (markerImage == nil) { markerImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i-marker.png",[Props global].contentFolder , theEntry.icon]];
			}
			
			
			[marker replaceUIImage:markerImage];
			
		}
		
        float markerWidth = [self getCurrentMarkerWidth];
		marker.bounds = CGRectMake(0, 0, [self getCurrentMarkerWidth], [self getCurrentMarkerWidth]);
		marker.opaque = NO;
		marker.opacity = kUnselectedMarkerOpacity;
		marker.zPosition = kEntryMarkerZPos;
        marker.opacity = 1.0;
        
        if (!showGenericMarkers) {
            marker.shadowOpacity = kMarkerShadowOpacity;
            marker.shadowOffset = CGSizeMake(markerWidth/15, markerWidth/7);
            marker.shadowRadius = markerWidth/12;
            marker.shadowColor = [UIColor darkGrayColor].CGColor;
        }
    }
	
	else if (marker == userLocationMarker) marker.zPosition = kUserLocationZPos;
	
	else if (marker == userLocationBackground) marker.zPosition = kUserLocationZPos - 1;
	
	else if (marker == destinationMarker) marker.zPosition = kDestinationZPos;
}


- (void) showAnnotationForEntry:(Entry*) _entry {
    
    @autoreleasepool {
    
        NSLog(@"About to show annotation for entry. with entries %@ loaded", entriesLoaded ? @"" : @"NOT");
        
        while (!entriesLoaded && !dataRefreshed) {
            [NSThread sleepForTimeInterval:0.2];
            NSLog(@"Sleeping...");
        }
        
        NSLog(@"Entry = %@, id = %i", _entry.name, _entry.entryid);                                                             
        
        [self performSelectorInBackground:@selector(hideAnyMarkerAnnotations) withObject:nil];
        
        mapView.contents.zoom = 16;
        [self afterMapZoom:mapView byFactor:0 near:CGPointZero];
        
        CLLocationCoordinate2D mapCenter;
        
        mapCenter.latitude = [_entry getLatitude] + 0.001;
        mapCenter.longitude = [_entry getLongitude];
        
        [self.mapView moveToLatLong:mapCenter];
        
        @synchronized([Props global].mapDbSync) {
        
            for (RMMarker *marker in [self.mapView.contents.markerManager markers]){
                
                NSLog(@"Marker id = %i", [[marker.data valueForKey:@"ID"] intValue]);
                
                if ([[marker.data valueForKey:@"ID"] intValue] == _entry.entryid) {
                    NSLog(@"Marker id matches.");
                    marker.zPosition = 0;
                    float scaleFactor = 2.5;
                    float maxWidth = 100;
                    float markerWidth = marker.bounds.size.width * scaleFactor;
                    markerWidth = (markerWidth > maxWidth) ? maxWidth : markerWidth;
                    
                    
                    UIImage *markerImage = _entry.iconImage;
                    
                    float cornerRadius = markerImage.size.height/cornerRadiusFraction;
                    
                    UIImage *roundedImage = [ImageManipulator makeRoundCornerImage:markerImage :cornerRadius :cornerRadius];
                    
                    [marker replaceUIImage:roundedImage];
                    
                    //keep area constant and proportions correct
                    float area = markerWidth * markerWidth;
                    float aspect = roundedImage.size.width/roundedImage.size.height;
                    
                    float markerHeight = pow(area/aspect, 0.5);
                    markerWidth = aspect * markerHeight;
                    
                    marker.bounds = CGRectMake(0, 0, markerWidth, markerHeight);
                    
                    marker.opaque = YES;
                    marker.opacity = 1.0;
                    
                    if (!showGenericMarkers) {
                        marker.shadowOpacity = kMarkerShadowOpacity;
                        marker.shadowOffset = CGSizeMake(markerWidth/10, markerWidth/7);
                        marker.shadowRadius = markerWidth/12;
                        marker.shadowColor = [UIColor darkGrayColor].CGColor;
                    }
                    
                    SMMapAnnotation *label = [[SMMapAnnotation alloc] initWithMarker:marker andController:self];
                    
                    [marker setLabel:label];
                    
                    [marker showLabel];
                    
                    break;
                }
            }
        }
    
    /*mapView.contents.zoom = 15;
    [self afterMapZoom:mapView byFactor:0 near:CGPointZero];
    
    CLLocationCoordinate2D mapCenter;
    
    mapCenter.latitude = [_entry getLatitude];
    mapCenter.longitude = [_entry getLongitude];
    
    [self.mapView moveToLatLong:mapCenter];*/
    
    }
}


-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
	
	if (buttonIndex != 0) {
		
		if(theAlert.tag == kCallTaxiAlertTag) { 
			
			[self callTaxi];
			
			SMLog *log = [[SMLog alloc] initWithPageID: kTLMV actionID: kEMVCallTaxi];
			[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
		}
		
		else {
			[self getDirectionsForEntry:[EntryCollection entryById:theAlert.tag]];
		}

	}
}


- (void)callTaxi {
	
	NSLog(@"MVC.callTaxi");
	NSString *phoneNumberString = [NSString stringWithFormat:@"tel://%@", [Props global].taxiServicePhoneNumber];
		
	SMLog *log = [[SMLog alloc] initWithPageID: kEntryMapView actionID: kEMVCallTaxi];
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumberString]];
}
			 

- (void) getDirectionsForEntry:(Entry*) theEntry {
	
	CLLocationCoordinate2D location;
	location.latitude = [[LocationManager sharedLocationManager] getLatitude];
	location.longitude = [[LocationManager sharedLocationManager] getLongitude];
	
	CLLocationCoordinate2D destination;
	destination.latitude = [theEntry getLatitude];
	destination.longitude = [theEntry getLongitude];
	
	NSString* urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?daddr=(%f,%f)&saddr=(%f,%f)", destination.latitude, destination.longitude ,location.latitude, location.longitude];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: urlString]];
}


- (UIImage*) generateMapMarkerForEntry:(Entry *) theEntry {
	
	//NSLog(@"MVC.generateMapMarker for %@", theEntry.name);
	
	UIImage *markerImage = nil;
	
	@synchronized(self) {
		
		@autoreleasepool {
		
			NSString *theFolderPath = [NSString stringWithFormat:@"%@/images",[Props global].contentFolder];
			
			if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath])
				[[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ];
			
			float scaledWidth = 70;
			float imageWidth = 58;
			CGRect imageRect = CGRectMake((scaledWidth - imageWidth)/2, (scaledWidth - imageWidth)/2 - 4, imageWidth, imageWidth);
			
			
			NSString *theImagePath = [NSString stringWithFormat:@"%@/images/%i-marker.png",[Props global].contentFolder , theEntry.icon];
			
			if (![[NSFileManager defaultManager] fileExistsAtPath: theImagePath]) {
				
            /*NSString *imageName = [NSString stringWithFormat:@"%i-icon", theEntry.icon];
				
				UIImage *squareImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i-icon.jpg",[Props global].contentFolder , theEntry.icon]];
				
				if (squareImage == nil) squareImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imageName ofType:@"jpg"]];
            
            if (squareImage == nil) squareImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100", theEntry.icon] ofType:@"jpg"]];*/
				
				if (theEntry.iconImage != nil) {
					
					UIImage *background2 = [UIImage imageNamed:@"Marker_background4.png"];
					
					float scaledHeight = background2.size.height * (scaledWidth/background2.size.width);
					
					CGSize backgroundSize = CGSizeMake(scaledWidth, scaledHeight);
					
					//NSLog(@"Marker image retain = %i and background retain = %i and background width = %f imageRect width = %f, backgroundRectWidth = %f, background size width = %f", [markerImage retainCount], [background2 retainCount], background2.size.width, imageRect.size.width, backgroundRect.size.width, backgroundRect.size.width);
					
					UIGraphicsBeginImageContext(backgroundSize);
					[theEntry.iconImage drawInRect:imageRect];
					[background2 drawAtPoint:CGPointZero];
					
					markerImage = UIGraphicsGetImageFromCurrentImageContext();
					UIGraphicsEndImageContext();
					
					NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(markerImage)];
					
					if(![imageData writeToFile:theImagePath atomically:YES])
						NSLog(@"MVC.generateMapMarker: getFileWithName() failed to write file to %@", theImagePath);
					
					//[squareImage release];
				}
			}
		
		}
	}
	
	return markerImage;
}



- (void)didReceiveMemoryWarning {
	
    NSLog(@"MVC.didReceiveMemoryWarning");

	[super didReceiveMemoryWarning];
}


- (void) reset {
	
	NSLog(@"MAPVIEWCONTROLLER.reset");
	
	NSMutableArray *markersToRemove = [NSMutableArray new];
	
	for (RMMarker *marker in [mapView.contents.markerManager markers]) {
		if (marker != userLocationMarker) {
			[markersToRemove addObject:marker];
		}
	}
	
	[mapView.contents.markerManager removeMarkers:markersToRemove];
	
	self.entriesLoaded = FALSE;
	
	//[self.mapView.contents.markerManager removeMarkers];
	
	/*
	 CLLocationCoordinate2D mapCenter;
	 mapCenter.latitude = [Props global].mapRegion.center.latitude + [Props global].mapRegion.span.latitudeDelta * .06;
	 mapCenter.longitude = [Props global].mapRegion.center.longitude; 
	 
	 float zoom = 9.24561688214405 - 3.3203169287079 * log10([Props global].mapRegion.span.latitudeDelta * 2);
	*/
	/*if (sharedMVC != nil){
	 [sharedMVC release];
	 }
	 
	 sharedMVC = nil;*/
}

#pragma mark
#pragma mark Singleton stuff

+ (MapViewController*)sharedMVC {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

@end