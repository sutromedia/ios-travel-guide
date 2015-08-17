#import "LocationManager.h"
#import "Constants.h"
#import "ActivityLogger.h"
#import "Props.h"
#import <AddressBook/AddressBook.h>
//#import "FlurryAnalytics.h"


@implementation LocationManager

@synthesize locationManager, currentLocation, address, locationSet, geoCoder;
//@synthesize delegate;
float longitude;
float latitude;

+ (LocationManager*)sharedLocationManager {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}


/*
static LocationManager *sharedLocationManagerInstance = nil;
+ (LocationManager*)sharedLocationManager {
    @synchronized(self) {
        if (sharedLocationManagerInstance == nil && [Props global].hasLocations) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedLocationManagerInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedLocationManagerInstance == nil) {
            sharedLocationManagerInstance = [super allocWithZone:zone];
            return sharedLocationManagerInstance;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}
*/

- (void) reset {
	
	NSLog(@"LOCATIONMANAGER.reset");
	if (geoCoder.querying) [geoCoder cancel];
	//sharedLocationManagerInstance = nil;
}

- (id) init {

	NSLog(@"LOCATIONMANAGER.init");
    self = [super init];
    if (self != nil) {

		if (nil == locationManager) {
			locationManager = [[CLLocationManager alloc] init];
			self.locationManager.delegate = self; // send loc updates to myself
			//[locationManager startUpdatingLocation];
			longitude = kValueNotSet;//*/ -122.470064; //defaults for video
			latitude = kValueNotSet; //*/ 37.760966; //defaults for video
		}
		
		self.geoCoder = nil;
		lastAddressUpdate = nil;
		self.address = @"";
		locationManager.delegate = self;
		locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		
		// Set a movement threshold for new events
		locationManager.distanceFilter = 200;
		
		if ([Props global].hasLocations){
            [locationManager startUpdatingLocation];
            NSLog(@"LOCATIONMANAGER.init: starting to update locations");
        }
		locationSet = FALSE;
	}	
    return self;
}


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
	userAllowedUsingLocation = TRUE;
	currentLocation = newLocation;
	
	int timeSinceUpdate = (int)[lastAddressUpdate timeIntervalSinceNow];
	//NSLog(@"Time since last address update = %i", timeSinceUpdate);
	//NSLog(@"Geocoder is %@loading", (geoCoder != nil && geoCoder.querying) ? @"not " : @""); 
    
    NSLog(@"Location manager did update accuracy = %f", currentLocation.horizontalAccuracy);
    
    if (currentLocation.horizontalAccuracy < 1000 && currentLocation.horizontalAccuracy > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationUpdated object:nil];
        
        if (!locationSet) {
            
            [[ActivityLogger sharedActivityLogger] setLocation: currentLocation];
            //[FlurryAnalytics setLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude horizontalAccuracy:currentLocation.horizontalAccuracy verticalAccuracy:currentLocation.verticalAccuracy];
            locationSet = TRUE;
        }
        
        //CLLocation* venueLocation = [[CLLocation alloc] initWithLatitude: 37.8265 longitude: -122.421];
        
        //CLLocationDistance distance = [venueLocation getDistanceFrom:currentLocation];
        
        //NSLog(@"****HARDCODED USER LOCATION - CHANGE ME BEFORE SUBMITTING!!!!!!!!!!!!!!!!!!!!!! ****");
        
        latitude =	currentLocation.coordinate.latitude; //37.760966; //defaults for video 40.75; //
        longitude = currentLocation.coordinate.longitude; // -122.470064; placeholder for videod -74; //
    }
	
	if (currentLocation.horizontalAccuracy < 200 && currentLocation.horizontalAccuracy > 0 && [Props global].osVersion >= 3.2 && !geoCoder.querying && (timeSinceUpdate > 120 || lastAddressUpdate == nil)) {
		
		NSLog(@"LOCATIONMANAGER.didUpdateToLocation:horizontal accuracy good enough to set address");
		MKReverseGeocoder *tmpCoder = [[MKReverseGeocoder alloc] initWithCoordinate:currentLocation.coordinate];
		self.geoCoder = tmpCoder;
		geoCoder.delegate = self;
		[geoCoder start];
	}
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	
	NSLog(@"Error: %@", [error description]);
	//[self.delegate locationError:error];
	if(error.code == kCLErrorDenied) {
		userAllowedUsingLocation = FALSE;
	}
}

 
- (float) getDistanceFromHereToPlaceWithLatitude:(float)destinationLatitude andLongitude:(float)destinationLongitude
{
	float distance = kNoDistance;
	CLLocation* whereWeAt = [[CLLocation alloc] initWithLatitude: latitude longitude: longitude];
	//NSLog(@"Current lat and long = %f, %f", latitude, longitude);
	
	if((destinationLatitude != 0) && (destinationLongitude != 0) && (currentLocation != nil)) {
		
		CLLocation* venueLocation = [[CLLocation alloc] initWithLatitude: destinationLatitude longitude: destinationLongitude];
	
		//Need to use a different method for determining distance for 
		CLLocationDistance distanceInMeters = ([Props global].osVersion >= 3.2) ? [venueLocation distanceFromLocation:whereWeAt]:[venueLocation distanceFromLocation:whereWeAt]; 	
		
		//NSLog(@"Distance in meters = %f", distanceInMeters);
		
		if ([Props global].unitsInMiles)
			distance = distanceInMeters/1609.344 * kTravelDistanceFactor;
		
		else distance = distanceInMeters/1000 * kTravelDistanceFactor;
			
	}
	

	return distance;
}


- (CLLocationDistance) getDistanceInMetersFromHereToPlace:(CLLocation*) destination
{
	CLLocationDistance distanceInMeters = kNoDistance;
	
	CLLocation* whereWeAt = [[CLLocation alloc] initWithLatitude: latitude longitude: longitude];
	//NSLog(@"Current lat and long = %f, %f", latitude, longitude);
	
	if((destination != nil) && (currentLocation != nil)) {
		
		//Need to use a different method for determining distance for 
		distanceInMeters = ([Props global].osVersion >= 3.2) ? [destination distanceFromLocation:whereWeAt]:[destination distanceFromLocation:whereWeAt]; 	
	}
	
	//we need to go from crow fly distance to actual distance for shorter trips (figure there are more direct routes for longer trips
	if (distanceInMeters < 1000*10) distanceInMeters = distanceInMeters * kTravelDistanceFactor;
	
	
	return distanceInMeters;
}


- (float) getLatitude {
	return  latitude;
}

- (float) getLongitude {
	return longitude;
}


// this delegate is called when the reverseGeocoder finds a placemark
- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark
{
    NSLog(@"LOCATIONMANAGER.reverseGeocoder.didFindPlacemark");
	
	MKPlacemark * myPlacemark = placemark;
	
	NSString *theAddress = [NSString stringWithFormat:@"%@ %@, %@ %@", myPlacemark.subThoroughfare, myPlacemark.thoroughfare, myPlacemark.locality, myPlacemark.administrativeArea];
	
	if ([theAddress length] > 0) {
		self.address = theAddress;
		
		if (lastAddressUpdate != nil) {
			lastAddressUpdate = nil;
		}
		
		lastAddressUpdate = [NSDate date];
	}
	
	else self.address = @"";

	NSLog(@"Address = %@", address);	
}

// this delegate is called when the reversegeocoder fails to find a placemark
- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error
{
   NSLog(@"reverseGeocoder:%@ didFailWithError:%@", geocoder, error);
}


@end
