//
//  IconMapView.h
//  TheProject
//
//  Created by Tobin1 on 10/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RMMapView.h>

@class Entry, MapViewController;

@interface EntryMapView : UIViewController <RMMapViewDelegate> {
	
	Entry					*__unsafe_unretained entry;
	MapViewController		*mvc;
	float					sublabelHeight;
	CLLocationCoordinate2D	lastMapCenter;
    CLLocationCoordinate2D  ne_Corner; //Used for making sure to show any included entries
    CLLocationCoordinate2D  sw_Corner;
    NSDate                  *timer;
    BOOL                    upgradePitchHidden;
    
}

@property (unsafe_unretained, nonatomic) Entry *entry;

- (void) goToEntry:(NSNumber*) theEntryIdObject;
- (id) initWithEntry:(Entry *)theEntry;

@end
