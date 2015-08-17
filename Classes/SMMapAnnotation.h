//
//  SMMapAnnotation.h
//  TheProject
//
//  Created by Tobin1 on 10/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Entry, MapViewController, RMMarker, TopLevelMapView;

@interface SMMapAnnotation : UIView {

	MapViewController *controller;
	RMMarker *marker;
	Entry *entry;
}


- (id)initWithMarker:(RMMarker*) theMarker andController:(MapViewController*) controller;
- (id)initWithMarker:(RMMarker*) theMarker  controller:(MapViewController*) theController andEntry:(Entry*) theEntry;
- (id) initWithEntry:(Entry*) theEntry andController:(TopLevelMapView*) theController;

@end
