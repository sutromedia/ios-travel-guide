//
//  SutroTileSource.m
//  MapView
//
//  Created by Tobin1 on 12/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SutroTileSource.h"

@implementation SutroTileSource

-(id) init
{       
	self = [super init];
    
    if (self) {
		//http://wiki.openstreetmap.org/index.php/FAQ#What_is_the_map_scale_for_a_particular_zoom_level_of_the_map.3F 
		[self setMaxZoom:18];
		[self setMinZoom:1];
	}
	return self;
} 

-(NSString*) tileURL: (RMTile) tile
{
	NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
			  @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f", 
			  self, tile.zoom, self.minZoom, self.maxZoom);
	
	NSString *url = [NSString stringWithFormat:@"http://pub1.sutromedia.com/published/sutro-map-tiles/%d/%d/%d.png", tile.zoom, tile.x, tile.y];
	NSLog(@"Looking for tile at %@", url);
	return url;
}

-(NSString*) uniqueTilecacheKey
{
	return @"SutroTileSource1";
}

-(NSString *)shortName
{
	return @"Open Street Map";
}
-(NSString *)longDescription
{
	return @"Open Street Map, the free wiki world map, provides freely usable map data for all parts of the world, under the Creative Commons Attribution-Share Alike 2.0 license.";
}
-(NSString *)shortAttribution
{
	return @"© OpenStreetMap CC-BY-SA";
}
-(NSString *)longAttribution
{
	return @"Map data © OpenStreetMap, licensed under Creative Commons Share Alike By Attribution.";
}

@end
