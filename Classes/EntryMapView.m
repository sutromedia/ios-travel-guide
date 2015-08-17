    //
//  IconMapView.m
//  TheProject
//
//  Created by Tobin1 on 10/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EntryMapView.h"
#import "MapViewController.h"
#import "Entry.h"
#import "Props.h"
#import "LocationManager.h"
#import "RMMarker.h"
#import "SMLog.h"
#import "ActivityLogger.h"
#import "EntryCollection.h"
#import "RMMarkerManager.h"
#import "SMMapAnnotation.h"
#import "Reachability.h"
#import "UpgradePitch.h"

#define kMapActionsTag 98713429
#define kHideTitle @"Hide others"
#define kShowTitle @"Show everything"

@interface EntryMapView (PrivateMethods)

- (void) addDestinationMarker;
- (void) centerMapOnEntry; 
- (void) hideOtherMarkersAsNecessary;
- (void) addOfflineUpgradePitch;
- (void) showIncludedEntries;

@end


@implementation EntryMapView

@synthesize entry;

- (id) initWithEntry:(Entry *)theEntry  {
	
	NSLog(@"EMV.init");
	
    self = [super init];
    
	if (self != nil){
		self.entry = theEntry;
		
		NSLog(@"EMV.init: Entry = %@", entry.name);
		
		//Set back image for returning to this view
		UIImage *backImage =[UIImage imageNamed:@"back.png"];
		UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backImage style: UIBarButtonItemStylePlain target:nil action:nil];
		self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
		sublabelHeight = 0;
        
        //Initially set corners to be equal to marker location. These get updated if there are included entries
        ne_Corner.latitude = [theEntry getLatitude];
        ne_Corner.longitude = [theEntry getLongitude];
        sw_Corner = ne_Corner;
        
        timer = [NSDate date];
		
		[self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
	}
	
	return self;
}


- (void)loadView {
	
	NSLog(@"EMV.loadView time = %0.1f", -[timer timeIntervalSinceNow]);
	
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	contentView.backgroundColor = [UIColor lightGrayColor];
	self.view = contentView;
	
	//******** Set up map view
	mvc = [MapViewController sharedMVC];
	
	[self.view  addSubview:mvc.view];
}


- (void) viewWillAppear:(BOOL)animated {
	
	NSLog(@"EMC.viewWillAppear time = %0.1f", -[timer timeIntervalSinceNow]);
	
    mvc.mapView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	mvc.mapView.delegate = self;
	mvc.mapView.frame = self.view.frame;
    
	[self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
	
	if (![[self.view subviews] containsObject:mvc.view]) {
		[self.view addSubview:mvc.view];
		[self.view sendSubviewToBack:mvc.view];
	}
	
	[mvc startPulsingUser];
    
    //[self performSelectorInBackground:@selector(centerMapOnEntry) withObject:nil];
    NSLog(@"ENTRYMAPVIEW.view will appear 1. Coordinates = %f, %f", [entry getLatitude], [entry getLongitude]);
    [self hideOtherMarkersAsNecessary];
    NSLog(@"ENTRYMAPVIEW.view will appear 2. Coordinates = %f, %f", [entry getLatitude], [entry getLongitude]);
    [self showIncludedEntries];
	[self centerMapOnEntry];
	
    if ([Props global].appID > 1) {
        NSString *showOthersButtonTitle = entry.showOthers ? kHideTitle : kShowTitle;
        
        UIBarButtonItem *showOthersButton = [[UIBarButtonItem alloc] initWithTitle: showOthersButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(showHideOthers:)];
        
        if ([Props global].osVersion >= 7.0)showOthersButton.tintColor = [UIColor whiteColor];
        
        self.navigationItem.rightBarButtonItem = showOthersButton;
    }
	
	[self addDestinationMarker];
    
    [super viewWillAppear:animated];
    
    NSLog(@"EMC.viewWillAppear done time = %0.1f", -[timer timeIntervalSinceNow]);
}


- (void) viewDidAppear:(BOOL)animated {

    NSLog(@"EMC.viewDidAppear time = %0.1f", -[timer timeIntervalSinceNow]);

    [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
    
    if (!mvc.entriesLoaded && !mvc.entriesLoading) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showIncludedEntries) name:kMapMarkersLoaded object:nil];
        [[MapViewController sharedMVC] performSelectorInBackground:@selector(loadEntries) withObject:nil];
    }
    
    /*if (![[NSUserDefaults standardUserDefaults] boolForKey:kOfflineUpgradePurchased]) {
        UpgradePitch *pitch = [[UpgradePitch alloc] initWithYPos:[Props global].titleBarHeight andMessage: @"This map requires an internet connection.  <a class='SMUpgradeLink' href='SMUpgradeLink://1'>Upgrade</a>&nbsp;for&nbsp;offline&nbsp;access"];
        //pitch.delegate = self;
        [self.view addSubview:pitch];
    }*/
    
    if ([Props global].freemiumType == kFreemiumType_V1 && !upgradePitchHidden) [self addOfflineUpgradePitch];
    
    NSLog(@"EMC.viewDidAppear done time = %0.1f", -[timer timeIntervalSinceNow]);
}


- (void) viewWillDisappear:(BOOL)animated {
	
	NSLog(@"ENTRYMAPVIEW.viewWillDisapear");
	
	[mvc stopPulsingUser];
	
	for (UIView *subview in [self.navigationController.navigationBar subviews]) {
		if (subview.tag == kMapActionsTag) [subview removeFromSuperview];
	}
	
	[mvc performSelectorInBackground:@selector(hideAnyMarkerAnnotations) withObject:nil];		
}


- (BOOL)prefersStatusBarHidden {return YES;}


- (void) hideOtherMarkersAsNecessary {
    
    CGRect markerBounds = CGRectMake(0, 0, [mvc getCurrentMarkerWidth], [mvc getCurrentMarkerWidth]);
	
	for (RMMarker *marker in [mvc.mapView.contents.markerManager markers]){
		
		if(marker != mvc.userLocationMarker && marker != mvc.destinationMarker && marker != mvc.userLocationBackground) {
			marker.hidden = !entry.showOthers;
			marker.bounds = markerBounds;
		}
		
		NSNumber *markerIdNumber = (NSNumber*) [marker.data valueForKey:@"ID"];
		int markerId = [markerIdNumber intValue];
		
		if (markerId == entry.entryid && marker != mvc.destinationMarker) marker.hidden = TRUE;
	}
}

- (void) addDestinationMarker {
	
	[mvc.mapView.contents.markerManager removeMarker:mvc.destinationMarker];
	
	CLLocationCoordinate2D destinationSpot;
	
	destinationSpot.latitude = [self.entry getLatitude];
	destinationSpot.longitude = [self.entry getLongitude];
	
	mvc.userLocationMarker.bounds = CGRectMake(0, 0, kUserLocationMarkerWidth, kUserLocationMarkerWidth);
	mvc.userLocationBackground.bounds = CGRectMake(0, 0, kUserLocationMarkerWidth, kUserLocationMarkerWidth);
	
	NSNumber *idValue = [[NSNumber alloc] initWithInt:entry.entryid];
	mvc.destinationMarker.data = [[NSMutableDictionary alloc] init];
	[mvc.destinationMarker.data setValue:idValue forKey:@"ID"];
	
	[mvc.mapView.contents.markerManager addMarker:mvc.destinationMarker AtLatLong:destinationSpot];
	
	SMMapAnnotation *label = [[SMMapAnnotation alloc] initWithMarker:mvc.destinationMarker controller:mvc andEntry:entry];
	
	[mvc.destinationMarker setLabel:label];
	
	[mvc.destinationMarker showLabel];
}


- (void) showIncludedEntries {
    
    NSSet *includedEntries = [self.entry generateIncludedEntries];
    
    if ([includedEntries count] > 0) {
        for (RMMarker *marker in [mvc.mapView.contents.markerManager markers]){
            
            if([includedEntries member:[marker.data valueForKey:@"ID"]] && marker != mvc.userLocationMarker && marker != mvc.userLocationBackground){
                
                marker.hidden = FALSE;
                
                float latitude = [[marker.data valueForKey:@"latitude"] floatValue];
                float longitude = [[marker.data valueForKey:@"longitude"] floatValue];
                
                //Condition below trys to avoid having map centered to far away from entry in the event that one of the included entries is mis-mapped
                //if (fabs(latitude - [entry getLatitude])  < [Props global].latitudeSpan * 30 && fabs(longitude - [entry getLongitude]) < [Props global].latitudeSpan * 30) {
                    if (latitude > ne_Corner.latitude) ne_Corner.latitude = latitude;
                    if (latitude < sw_Corner.latitude) sw_Corner.latitude = latitude;
                    
                    if (longitude > ne_Corner.longitude) ne_Corner.longitude = longitude;
                    if (longitude < sw_Corner.longitude) sw_Corner.longitude = longitude;
                //}
                
               // else NSLog(@"**** WARNING ENTRYMAPVIEW.showIncludedEntries: not including entry with id = %i for re-centering because the position appears to be off", [[marker.data valueForKey:@"ID"] intValue]);
            }
        }
    }
}


- (void) centerMapOnEntry {
	
    @autoreleasepool {
		
        NSLog(@"ENTRYMAPVIEW.centerMapOnEntry. Coordinates = %f, %f", [entry getLatitude], [entry getLongitude]);
        
		CLLocationCoordinate2D destinationSpot;
		
		destinationSpot.latitude = [self.entry getLatitude];
		destinationSpot.longitude = [self.entry getLongitude];
		
		CLLocation* destination = [[CLLocation alloc] initWithLatitude: destinationSpot.latitude longitude: destinationSpot.longitude];
		
		float distanceInMiles = [[LocationManager sharedLocationManager] getDistanceInMetersFromHereToPlace: destination] / 1609;
    
        if (ne_Corner.latitude != 0 && ne_Corner.longitude != 0 && sw_Corner.longitude != 0 && sw_Corner.latitude != 0 && (ne_Corner.latitude > [entry getLatitude] || ne_Corner.longitude > [entry getLongitude] || sw_Corner.latitude < [entry getLatitude] || sw_Corner.longitude < [entry getLongitude])) {
            
            float latitude_range = ne_Corner.latitude - sw_Corner.latitude;
            float longitude_range = ne_Corner.longitude - sw_Corner.longitude;
            
            float lateralMoveFactor = 0.2; //Higher number centers the entry laterally more 
            
            NSLog(@"long range = %f, lat range = %f", latitude_range, longitude_range);
            NSLog(@"ne_corner = %f, %f  sw_corner = %f, %f", ne_Corner.latitude, ne_Corner.longitude, sw_Corner.latitude, sw_Corner.longitude);
            NSLog(@"Entry coordinates = %f, %f", [entry getLatitude], [entry getLongitude]);
            
            //Corrent if entry is too high on screen
            if (ne_Corner.latitude < [entry getLatitude] + latitude_range * .75) {
                ne_Corner.latitude = [entry getLatitude] + latitude_range * .75;
            }
            
            //Correct if entry if too far right on screen
            if (ne_Corner.longitude < [entry getLongitude] + longitude_range * lateralMoveFactor) {
                ne_Corner.longitude = [entry getLongitude] + longitude_range * lateralMoveFactor;
            }
            
            //Correct if entry if too far left on screen
            if (sw_Corner.longitude > [entry getLongitude] - longitude_range * lateralMoveFactor) {
                sw_Corner.longitude = [entry getLongitude] - longitude_range * lateralMoveFactor;
            }
            
            [mvc.mapView.contents zoomWithLatLngBoundsNorthEast: ne_Corner SouthWest: sw_Corner];
            
            //center the map either on the destination or user and destination depending on the distance
            float maxZoomLevel = [Props global].startingZoomLevel + 1;
            
            //if (maxZoomLevel > 13 && [Props global].hasOfflineUpgrade && ![[NSUserDefaults standardUserDefaults] boolForKey:kOfflineMaps] && [[Reachability sharedReachability] internetConnectionStatus] == NotReachable) maxZoomLevel = 13;
            if (maxZoomLevel > [Props global].innermostZoomLevel) maxZoomLevel = [Props global].innermostZoomLevel;
            else if (maxZoomLevel > 14) maxZoomLevel = 14;
            
            if (self.entry.isDemoEntry) maxZoomLevel = [[Reachability sharedReachability] internetConnectionStatus] == NotReachable ? 5 : 10; //Fixed zoom level for demo entries in Sutro libary apps

            
            //float minZoomLevel =[Props global].startingZoomLevel - 3;
            //if (minZoomLevel < 0) minZoomLevel = 0;
            
            //NSLog(@"Max zoom = %0.2f, min zoom = %0.2f, zoom level = %0.2f", maxZoomLevel, minZoomLevel, mvc.mapView.contents.zoom);
            
            if (mvc.mapView.contents.zoom > maxZoomLevel){
               [mvc.mapView.contents setZoom:maxZoomLevel]; 
            }
            
            //else if (mvc.mapView.contents.zoom < minZoomLevel) {
            //    [mvc.mapView.contents setZoom:minZoomLevel];
            //}
        }
        
        else if (distanceInMiles > 20 || [[LocationManager sharedLocationManager] getLongitude] == kValueNotSet || [[LocationManager sharedLocationManager] getLatitude] == kValueNotSet) {
			
			[mvc.mapView moveToLatLong: destinationSpot];
			
            float theZoomLevel = [Props global].startingZoomLevel + 1;
            if (theZoomLevel > 14) theZoomLevel = 14;
            if (theZoomLevel > [Props global].innermostZoomLevel) theZoomLevel = [Props global].innermostZoomLevel;
            if (self.entry.isDemoEntry) theZoomLevel = [[Reachability sharedReachability] internetConnectionStatus] == NotReachable ? 5 : 10; //Fixed zoom level for demo entries in Sutro libary apps
            
            [mvc.mapView.contents setZoom:theZoomLevel];
			
			if ([[Props global] inLandscapeMode]) [mvc.mapView moveBy:CGSizeMake(0, [Props global].titleBarHeight + 10)];
		}
		
		else {
			
			CLLocationCoordinate2D mapCenter;
			CLLocationCoordinate2D userLocation;
			userLocation.latitude = [[LocationManager sharedLocationManager] getLatitude];
			userLocation.longitude = [[LocationManager sharedLocationManager] getLongitude];
			
			float vBorderFactor = 0.4; //make this smaller for a smaller border
			float hBorderFactor = 0.2;
			float vOffsetFactor = 0.15; //used to offset the map downwards for the trasparent title
			
			if (destinationSpot.latitude > userLocation.latitude && [Props global].deviceType != kiPad) vOffsetFactor = .35; 
			
			float magicRatio = fabs((destinationSpot.latitude - userLocation.latitude)/(destinationSpot.longitude - userLocation.longitude));
			
			//user location is roughly vertically in line with destination
			if (magicRatio > 10) hBorderFactor = 0;
			
			//user location is roughly horizontally in line with destination
			else if (magicRatio < .3) {
				vOffsetFactor = [[Props global] inLandscapeMode] && [Props global].deviceType != kiPad ? .12/magicRatio + .1: .15; //crazy formula developed by trial and error
				hBorderFactor = .3;
			}
			
			if ([[Props global] inLandscapeMode] && [Props global].deviceType != kiPad) {
				vOffsetFactor += .35;
				vBorderFactor += .5;
			}
			
			NSLog(@"Magic ratio = %f, vOffsetFactor = %f", magicRatio, vOffsetFactor);
			
			CLLocationCoordinate2D NECorner;
			NECorner.latitude = MAX(userLocation.latitude, destinationSpot.latitude) + fabs(userLocation.latitude - destinationSpot.latitude) * vBorderFactor + fabs(userLocation.latitude - destinationSpot.latitude) * vOffsetFactor;
			//Additional term used to offset map down a bit for title bar
			NECorner.longitude = MAX(userLocation.longitude, destinationSpot.longitude) + fabs(userLocation.longitude - destinationSpot.longitude) * hBorderFactor;
			
			//NSLog(@"User Loc - lat = %f, long = %f", userLocation.latitude, userLocation.longitude);
			//NSLog(@"Destinat - lat = %f, long = %f", newPinSpot.latitude, newPinSpot.longitude);
			//NSLog(@"NECorner - lat = %f, long = %f", NECorner.latitude, NECorner.longitude);
			
			CLLocationCoordinate2D SWCorner;
			SWCorner.latitude = MIN(userLocation.latitude, destinationSpot.latitude) - fabs(userLocation.latitude - destinationSpot.latitude) * vBorderFactor + fabs(userLocation.latitude - destinationSpot.latitude) * vOffsetFactor;
			SWCorner.longitude = MIN(userLocation.longitude, destinationSpot.longitude) - fabs(userLocation.longitude - destinationSpot.longitude) * hBorderFactor;
			
			//NSLog(@"SWCorner - lat = %f, long = %f", SWCorner.latitude, SWCorner.longitude);
			
			[mvc.mapView.contents zoomWithLatLngBoundsNorthEast: NECorner SouthWest: SWCorner];
			NSLog(@"Map zoom = %f", mvc.mapView.contents.zoom);
            
            //center the map either on the destination or user and destination depending on the distance
            float maxZoomLevel;
            
            if (self.entry.isDemoEntry) maxZoomLevel = [[Reachability sharedReachability] internetConnectionStatus] == NotReachable ? 5 : 10;
            
            else if ([Props global].freemiumType == kFreemiumType_V1 && ![[NSUserDefaults standardUserDefaults] boolForKey:kOfflineMaps] && [[Reachability sharedReachability] internetConnectionStatus] == NotReachable) maxZoomLevel = 13;
            
            else maxZoomLevel = 16;
			
			if (mvc.mapView.contents.zoom > maxZoomLevel) {
				
				NSLog(@"Setting zoom to max limit of %f", maxZoomLevel);
				[mvc.mapView.contents setZoom:maxZoomLevel];
				
				mapCenter.latitude = (destinationSpot.latitude + userLocation.latitude)/2;
				mapCenter.longitude =  (destinationSpot.longitude + userLocation.longitude)/2;
				
				[mvc.mapView moveToLatLong:mapCenter];
			}
		}	        
    }
}


- (void) showHideOthers: (id) sender {

	NSLog(@"Time to show or hide others");
	UIBarButtonItem *showHideOthers = (UIBarButtonItem*) sender;
	
	//Show others
    if ([showHideOthers.title isEqualToString:kShowTitle]){
		showHideOthers.title = kHideTitle;
		entry.showOthers = TRUE;
		for (RMMarker *theMarker in [mvc.mapView.contents.markerManager markers]){
			
			NSNumber *markerIdNumber = (NSNumber*) [theMarker.data valueForKey:@"ID"];
			int markerId = [markerIdNumber intValue];
			
			if(markerId != entry.entryid) theMarker.hidden = FALSE;
			
			if (theMarker != mvc.userLocationMarker && theMarker != mvc.destinationMarker && theMarker != mvc.userLocationBackground)
				theMarker.zPosition = kEntryMarkerZPos;
		}	
	}
	
	//Hide others
    else {
		showHideOthers.title = kShowTitle;
		entry.showOthers = FALSE;
		for (RMMarker *theMarker in [mvc.mapView.contents.markerManager markers]){
			
			if(theMarker != mvc.userLocationMarker && theMarker != mvc.destinationMarker && theMarker != mvc.userLocationBackground) {
				
                if (theMarker.label != nil && ![theMarker.label isHidden]) [mvc hideAnnotationForMarker:theMarker];
				theMarker.hidden = TRUE;
			}
		}
        
        [self showIncludedEntries];
	}
}


- (void) addOfflineUpgradePitch {
    
    [[self.view viewWithTag:kOfflineUpgradePitchTag] removeFromSuperview];
    
    UpgradePitch *pitch = [[UpgradePitch alloc] initWithYPos:[Props global].titleBarHeight andMessage: @"<a class='SMUpgradeLink' href='SMUpgradeLink://1'>Upgrade</a>&nbsp;for&nbsp;fast&nbsp;offline&nbsp;access"];
    pitch.tag = kOfflineUpgradePitchTag;
    [self.view addSubview:pitch];
}


- (void) singleTapOnMap: (RMMapView*) map At: (CGPoint) point {
	
	[mvc singleTapOnMap:map At:point];
}


- (void) afterMapZoom: (RMMapView*) map byFactor: (float) zoomFactor near:(CGPoint) center {
	
	[mvc afterMapZoom:map byFactor:zoomFactor near:center];
}


- (void) tapOnMarker: (RMMarker*) marker onMap: (RMMapView*) map {
	
	//CGRect viewRect = [[Props global] inLandscapeMode] ? CGRectMake(0, [Props global].titleBarHeight + sublabelHeight, [Props global].screenWidth, [Props global].screenHeight - kTitleBarHeight - 40) : CGRectMake(0, kTitleBarHeight + sublabelHeight, [Props global].screenWidth, [Props global].screenHeight - kTitleBarHeight - 40)
	
	[mvc tapOnMarker:marker onMap:map withViewRect:CGRectMake(0, kTitleBarHeight + sublabelHeight, [Props global].screenWidth, [Props global].screenHeight - kTitleBarHeight - 40) fromSender:self];
}


- (void) tapOnLabelForMarker: (RMMarker*) marker onMap: (RMMapView*) map onLayer: (CALayer *)layer {

	[mvc tapOnLabelForMarker:marker onMap:map onLayer:layer fromSender:self];
}


- (BOOL) shouldMove:(CGSize) delta {
	
	return [mvc shouldMove:delta];
}


- (void) goToEntry:(NSNumber*) theEntryIdObject {
	
    int theEntryId = [theEntryIdObject intValue];
	//UIButton *button = (UIButton*) sender;
	 
	LocationViewController *entryController = [[LocationViewController alloc] initWithController: nil];
	entryController.showGoToTopButton = TRUE;
	Entry *theEntry = [EntryCollection entryById:theEntryId];
	
	entryController.entry = theEntry; 
	[[self navigationController] pushViewController:entryController animated:YES];
	
	//Log event
	SMLog *log = [[SMLog alloc] initWithPageID: kTLMV actionID: kMVGoToEntry];
	log.entry_id = theEntry.entryid;
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
}


- (void)dealloc {
	
	mvc.mapView.delegate = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        
        return YES;
    }
    
    else return NO;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	if (toInterfaceOrientation != UIDeviceOrientationFaceUp && toInterfaceOrientation != UIDeviceOrientationFaceDown && toInterfaceOrientation != UIDeviceOrientationUnknown) {
        
        [[Props global] updateScreenDimensions: toInterfaceOrientation];
        lastMapCenter = mvc.mapView.contents.mapCenter;
	}
}


- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
	//[self centerMapOnEntry];
	[mvc.mapView moveToLatLong:lastMapCenter];
    
    if ([Props global].freemiumType == kFreemiumType_V1 && !upgradePitchHidden) [self addOfflineUpgradePitch];
}

@end
