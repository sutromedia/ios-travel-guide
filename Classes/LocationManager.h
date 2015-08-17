//
//  LocationManager.h
//  TheElements
//
//  Created by Tobin1 on 2/20/09.
//  Copyright 2009 Ard ica Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@class MKReverseGeocoder;


@interface LocationManager : NSObject <CLLocationManagerDelegate, MKReverseGeocoderDelegate> {
	CLLocationManager	*locationManager;
	CLLocation			*currentLocation; 
	float				getDistanceToHere;
	NSNumber			*test;
	BOOL				userAllowedUsingLocation;
	BOOL				locationSet;
	NSString			*address;
	MKReverseGeocoder	*geoCoder;
	NSDate				*lastAddressUpdate;
}


@property (nonatomic, strong)	CLLocationManager	*locationManager; 
@property (nonatomic, strong)	CLLocation			*currentLocation;
@property (nonatomic, strong)	NSString			*address;
@property (nonatomic)			BOOL				locationSet;
@property (nonatomic, strong)	MKReverseGeocoder	*geoCoder;


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
- (float) getDistanceFromHereToPlaceWithLatitude:(float)destinationLatitude andLongitude:(float)destinationLongitude;
- (CLLocationDistance) getDistanceInMetersFromHereToPlace:(CLLocation*) destination;
- (float) getLatitude;
- (float) getLongitude;
+ (LocationManager *) sharedLocationManager;
- (void) reset;


@end
