//
//  MapView.h
//
//  Created by Tobin1 on 2/24/09.
//

#import <UIKit/UIKit.h>
#import "LocationViewController.h"
#import "RMMapView.h"
 
@class RMMapView, RMMarker;

@interface MapViewController : UIViewController {
	
	RMMarker			*destinationMarker;
	RMMarker			*userLocationMarker;
	RMMarker			*userLocationBackground;
	RMMapView			*mapView;
	RMMapContents		*mapContents;
	NSTimer				*userLocationUpdateTimer;
	float				maxMarkerWidth;
	float				minMarkerWidth;
	float				maxZoom;
	//float				minZoom;
	float				startingZoom;
	float				cornerRadiusFraction;
	BOOL				shouldRefresh;
	BOOL				shouldPulse;
	BOOL				entriesLoaded;
    BOOL                entriesLoading;
    BOOL                dataRefreshed;
    BOOL                showGenericMarkers;
}


@property (nonatomic, strong)	RMMapView			*mapView;
@property (nonatomic, strong)	RMMarker			*destinationMarker;
@property (nonatomic, strong)	RMMarker			*userLocationMarker;
@property (nonatomic, strong)	RMMarker			*userLocationBackground;
@property (nonatomic)			BOOL				entriesLoaded;
@property (nonatomic)           BOOL                dataRefreshed;
@property (nonatomic)           BOOL                entriesLoading;


- (void) afterMapZoom: (RMMapView*) map byFactor: (float) zoomFactor near:(CGPoint) center;
- (void) singleTapOnMap: (RMMapView*) map At: (CGPoint) point;
- (void) tapOnMarker: (RMMarker*) marker onMap: (RMMapView*) map withViewRect:(CGRect) viewRect fromSender:(id) sender;
- (void) tapOnLabelForMarker: (RMMarker*) marker onMap: (RMMapView*) map onLayer: (CALayer *)layer fromSender:(id) sender;
- (float) getCurrentMarkerWidth;
- (void) stopPulsingUser;
- (void) startPulsingUser;
- (BOOL) shouldMove:(CGSize) delta;
+ (MapViewController*)sharedMVC;
- (void) reset;
- (void) stopPulsingUser;
- (void) loadEntries;
- (void) hideAnyMarkerAnnotations;
- (void) hideAnnotationForMarker:(RMMarker*) marker;
- (void) hideAllMarkers;


@end

