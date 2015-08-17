//
//  TopLevelMapView.h
//  TheProject
//
//  Created by Tobin1 on 10/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMMapView.h"

@class FilterPicker, FilterButton, MapViewController, RMMapView, GlobeViewController;


@interface TopLevelMapView : UIViewController <RMMapViewDelegate> {
	
	MapViewController	*mvc;
    GlobeViewController *globe;
	CLLocationCoordinate2D lastMapCenter;
	FilterPicker		*filterPicker;
	FilterButton		*pickerSelectButton;
	NSString			*filterCriteria;
	NSString			*lastFilterChoice;
	BOOL				filterPickerShowing;
    BOOL                upgradePitchHidden;
	float				lastZoomLevel;
    
}


- (id)init;
- (void) goToEntry:(NSNumber*) theEntryIdObject;

@end
