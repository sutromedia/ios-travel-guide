//
//  RMTileImage.m
//
// Copyright (c) 2008-2009, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
#import "RMGlobalConstants.h"
#import "RMTileImage.h"
#import "RMWebTileImage.h"
#import "RMTileLoader.h"
#import "RMFileTileImage.h"
#import "RMTileCache.h"
#import "RMPixel.h"
#import <QuartzCore/QuartzCore.h>
#import "RMDBTileImage.h"

@implementation RMTileImage

@synthesize tile, layer, lastUsedTime, topQuality;

- (id) initWithTile: (RMTile)_tile
{
	if (![super init])
		return nil;
	
	tile = _tile;
	layer = nil;
	lastUsedTime = nil;
	screenLocation = CGRectZero;
	topQuality = TRUE;

	[self makeLayer];

	[self touch];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(tileRemovedFromScreen:)
						name:RMMapImageRemovedFromScreenNotification object:self];
		
	return self;
}
	 
-(void) tileRemovedFromScreen: (NSNotification*) notification
{
	[self cancelLoading];
}

-(id) init
{
	[NSException raise:@"Invalid initialiser" format:@"Use the designated initialiser for TileImage"];
	[self release];
	return nil;
}

+ (RMTileImage*) dummyTile: (RMTile)tile
{
	return [[[RMTileImage alloc] initWithTile:tile] autorelease];
}

- (void)dealloc
{
//	RMLog(@"Removing tile image %d %d %d", tile.x, tile.y, tile.zoom);
	
	//NSLog(@"RMTILEIMAGE.dealloc");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[layer release]; layer = nil;
	[lastUsedTime release]; lastUsedTime = nil;
	
	[super dealloc];
}

-(void)draw
{
}

+ (RMTileImage*)imageForTile:(RMTile) _tile withURL: (NSString*)url
{
	return [[[RMWebTileImage alloc] initWithTile:_tile FromURL:url] autorelease];
}

+ (RMTileImage*)imageForTile:(RMTile) _tile fromFile: (NSString*)filename
{
	return [[[RMFileTileImage alloc] initWithTile:_tile FromFile:filename] autorelease];
}

+ (RMTileImage*)imageForTile:(RMTile) tile withData: (NSData*)data
{
	NSLog(@"RMTILEIMAGE.imageForTile:");
	//UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:data], nil, nil, nil);
	UIImage *image = [[UIImage alloc] initWithData:data];
	RMTileImage *tileImage;

	if (!image)
		return nil;

	tileImage = [[self alloc] initWithTile:tile];
	[tileImage updateImageUsingImage:image];
	[image release];
	return [tileImage autorelease];
}

/*
+ (RMTileImage*)imageForTile:(RMTile) _tile fromDB: (FMDatabase*)db
{
	return [[[RMDBTileImage alloc] initWithTile: _tile fromDB:db] autorelease];
}*/


//TF added
+ (RMTileImage*)imageForTile:(RMTile) _tile fromDB: (FMDatabase*)db
{
	//theDatabase = db;
	//***TF RMDBTileImage *image = [[[RMDBTileImage alloc] initWithTile: _tile fromDB:db] autorelease];
	RMDBTileImage *image = [[RMDBTileImage alloc] initWithTile: _tile fromDB:db]; //what about the autorelease?
	
	return (RMTileImage*)image;
}

/* TF added/ removed
+ (void) writeImageToDBCache:(RMTileImage*) theImage forTile:(RMTile) _tile {

	NSLog(@"Time to write image to database cache");
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsFolder = [paths objectAtIndex:0];
	
	NSString *dbFilePath = [NSString stringWithFormat:@"%@/maps-cache.sqlite3", documentsFolder];
	
	FMDatabase *db = [[FMDatabase alloc] initWithPath:dbFilePath];
		
	if (![db open]) NSLog(@"RMTILEIMAGE.writeImageToDBCache - Could not open sqlite database from file = %@", dbFilePath);
	
	NSUInteger zoom, row, col;
	
	zoom = tile.zoom;
	row = tile.x;
	col = tile.y;
		
	NSData* image = (NSData*) theImage.layer.contents;
	
	if (image) {
		
		[db executeUpdate:@"insert into tiles (tilekey, zoom, row, col, image) values (?, ?, ?, ?, ?)", 
		 [NSNumber numberWithLongLong:RMTileKey(_tile)],
		 [NSNumber numberWithInt:zoom], 
		 [NSNumber numberWithInt:row], 
		 [NSNumber numberWithInt:col], 
		 image];
		
		
		/*executeUpdate(db, @"insert into tiles (tilekey, zoom, row, col, image) values (?, ?, ?, ?, ?)", 
					  [NSNumber numberWithLongLong:RMTileKey(_tile)],
					  [NSNumber numberWithInt:zoom], 
					  [NSNumber numberWithInt:row], 
					  [NSNumber numberWithInt:col], 
					  image);
		[image release];
	} 
	
	else NSLog(@"Could not read image");
	
	[db close];
	[db release];
}
*/

-(void) cancelLoading
{
	[[NSNotificationCenter defaultCenter] postNotificationName:RMMapImageLoadingCancelledNotification
														object:self];
}


- (void)updateImageUsingData: (NSData*) data
{
	[self updateImageUsingImage:[UIImage imageWithData:data]];

    NSDictionary *d = [NSDictionary dictionaryWithObject:data forKey:@"data"];
    [[NSNotificationCenter defaultCenter] postNotificationName:RMMapImageLoadedNotification object:self userInfo:d];

    
    //TF added
    //Send out message to cache to update
    /*NSDictionary *tileDict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:self.tile.zoom], @"zoom", [NSNumber numberWithInt:self.tile.x], @"row", [NSNumber numberWithInt:self.tile.y], @"column", data,  @"data", nil];
    
     NSString *notificationKey = [NSString stringWithFormat:@"%@-%i_%i_%i", RMMapImageLoadedNotification, tile.x, tile.y, tile.zoom];
    
     NSLog(@"RMTILEIMAGE.updateImageUsingData: About to send notification for tile = %i, %i, %i and key %@", tile.x, tile.y, tile.zoom, notificationKey);   
    
     [[NSNotificationCenter defaultCenter] postNotificationName:notificationKey object:nil userInfo:tileDict];*/
    
    //need to figure out how to release dict
}

//* TF added
- (void)replaceImageUsingData: (NSData*) data
{
	NSLog(@"RMTILEIMAGE.replaceImageUsingData");
	
	[self updateImageUsingImage:[UIImage imageWithData:data]];
	
	//UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:data],nil,nil,nil);
	NSDictionary *d = [NSDictionary dictionaryWithObject:data forKey:@"data"];
	[[NSNotificationCenter defaultCenter] postNotificationName:RMMapReplacementImageLoadedNotification object:self userInfo:d];
}


- (void)updateImageUsingImage: (UIImage*) rawImage
{
	//layer.contents = (id)[rawImage CGImage]; //TF removed

    //TF added
    //UIImageWriteToSavedPhotosAlbum(rawImage,nil,nil,nil);
	if (rawImage.size.width > 0 && rawImage.size.height > 0) {
        
        //NSLog(@"RMTILEIMAGE.updateImageUsingImage: imageWidth = %f and height = %f", rawImage.size.width, rawImage.size.height);
        
        CGImageRef theCGImage = rawImage.CGImage;
        
        layer.contents = (id)theCGImage;
        layer.name = [NSString stringWithFormat:@"imageWidth = %f and height = %f", rawImage.size.width, rawImage.size.height];
    }
}

- (BOOL)isLoaded
{
	return (layer != nil && layer.contents != NULL);
}

- (NSUInteger)hash
{
	return (NSUInteger)RMTileHash(tile);
}

-(void) touch
{
	[lastUsedTime release];
	lastUsedTime = [[NSDate date] retain];
}

- (BOOL)isEqual:(id)anObject
{
	if (![anObject isKindOfClass:[RMTileImage class]])
		return NO;

	return RMTilesEqual(tile, [(RMTileImage*)anObject tile]);
}

- (void)makeLayer
{
	if (layer == nil)
	{
		layer = [[CALayer alloc] init];
		layer.contents = nil;
		layer.anchorPoint = CGPointZero;
		layer.bounds = CGRectMake(0, 0, screenLocation.size.width, screenLocation.size.height);
		layer.position = screenLocation.origin;
		
		NSMutableDictionary *customActions=[NSMutableDictionary dictionaryWithDictionary:[layer actions]];
		
		[customActions setObject:[NSNull null] forKey:@"position"];
		[customActions setObject:[NSNull null] forKey:@"bounds"];
		[customActions setObject:[NSNull null] forKey:kCAOnOrderOut];
		
		CATransition *fadein = [[CATransition alloc] init];
		fadein.duration = 0.3;
		fadein.type = kCATransitionReveal;
		[customActions setObject:fadein forKey:@"contents"];
		[fadein release];
        
		layer.actions=customActions;
		
		layer.edgeAntialiasingMask = 0;
	}
}

- (void)moveBy: (CGSize) delta
{
	self.screenLocation = RMTranslateCGRectBy(screenLocation, delta);
}

- (void)zoomByFactor: (float) zoomFactor near:(CGPoint) center
{
	self.screenLocation = RMScaleCGRectAboutPoint(screenLocation, zoomFactor, center);
}


- (CGRect) screenLocation
{
	return screenLocation;
}

- (void) setScreenLocation: (CGRect)newScreenLocation
{
//	RMLog(@"location moving from %f %f to %f %f", screenLocation.origin.x, screenLocation.origin.y, newScreenLocation.origin.x, newScreenLocation.origin.y);
	screenLocation = newScreenLocation;
	
	if (layer != nil)
	{
		// layer.frame = screenLocation;
		layer.position = screenLocation.origin;
		layer.bounds = CGRectMake(0, 0, screenLocation.size.width, screenLocation.size.height);
	}
	
	[self touch];
}


- (void) displayProxy:(UIImage*) img
{
	layer.contents = (id)[img CGImage]; 
}

@end
