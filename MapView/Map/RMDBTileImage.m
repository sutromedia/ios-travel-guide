//
// RMDBTileImage.m
//
// Copyright (c) 2009, Frank Schroeder, SharpMind GbR
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

// RMDBTileImage is a tile image implementation for the RMDBMapSource.
// 
// See RMDBMapSource.m for a full documentation on the database schema.
//    


#import "RMDBTileImage.h"

#define FMDBErrorCheck(db)		{ if ([db hadError]) { NSLog(@"DB error %d on line %d: %@", [db lastErrorCode], __LINE__, [db lastErrorMessage]); } }


@implementation RMDBTileImage

@synthesize isGood;

/*
- (id)initWithTile:(RMTile)_tile fromDB:(FMDatabase*)db {
	self = [super initWithTile:_tile];
	if (self != nil) {
		// get the unique key for the tile
		int zoom = _tile.zoom;
		
		RMTile theTile;
		theTile.x = (int)_tile.x/((_tile.zoom - zoom) * 2);
		theTile.y = (int)_tile.y/((_tile.zoom - zoom) * 2);
		theTile.zoom = zoom;
		
		NSNumber* key = [NSNumber numberWithLongLong:RMTileKey(_tile)];
		RMLog(@"fetching tile %@ (y:%d, x:%d)@%d", key, _tile.y, _tile.x, _tile.zoom);
		
		// fetch the image from the db
		FMResultSet* rs = [db executeQuery:@"select image from tiles where tilekey = ?", key];
		FMDBErrorCheck(db);
		if ([rs next]) {
			UIImage *image = [[UIImage alloc] initWithData:[rs dataForColumn:@"image"]];
			//UIImageWriteToSavedPhotosAlbum(image,nil,nil,nil);
			[self updateImageUsingImage:image];
		}
		
		[rs close];
	}

	return self;
}*/


- (id)initWithTile:(RMTile)_tile fromDB:(FMDatabase*)db {
	self = [super initWithTile:_tile];
	if (self != nil) {
		// get the unique key for the tile
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		int zoom = _tile.zoom;
		FMResultSet* rs = nil;
		NSData *imageData;
		
		while (zoom >= 0) {
			RMTile theTile;
			int deltaZoom = _tile.zoom - zoom;
            
			float deltaZoomFract = pow(2, deltaZoom);
				
			theTile.x = (int)(_tile.x/deltaZoomFract);
			theTile.y = (int)(_tile.y/deltaZoomFract);
			
			theTile.zoom = zoom;
			
			NSNumber* key = [NSNumber numberWithLongLong:RMTileKey(theTile)];
            //NSLog(@"fetching tile %@ (y:%d, x:%d)@%d", key, theTile.y, theTile.x, theTile.zoom);
            
            //NSLog(@"Delta zoom = %i for %i, %i, %i", deltaZoom, theTile.x, theTile.y, theTile.zoom);
			
			// fetch the image from the db
			rs = [db executeQuery:@"SELECT image FROM tiles WHERE tilekey = ? AND downloaded = 1", key];
			FMDBErrorCheck(db);
            
            //NSLog(@"Query = %@, %llu", [rs query], [key longLongValue]);
			
			if ([rs next]) {
                
				imageData = [rs dataForColumnIndex:0];
                
				UIImage *image = [[UIImage alloc] initWithData:imageData];
				
				if (deltaZoom > 0) {
					//take the top right corner to start
					float xFraction = _tile.x/deltaZoomFract - theTile.x;
					float yFraction = _tile.y/deltaZoomFract - theTile.y;
					
					//UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
					//NSLog(@"RMDBTILEIMAGE.initWithTile: xFraction = %f, yFract = %f, deltaZoom = %i, deltaZoomFract = %f", xFraction, yFraction, deltaZoom, deltaZoomFract);
					
					CGRect zoomRect = CGRectMake(-image.size.width * deltaZoomFract * xFraction, -image.size.height * deltaZoomFract * yFraction, image.size.width * deltaZoomFract, image.size.height * deltaZoomFract);
					
					//NSLog(@"RMDBTILEIMAGE.initWithTile: zoom rect = (%f,%f,%f,%f)", zoomRect.origin.x, zoomRect.origin.y, zoomRect.size.width, zoomRect.size.height);
					
					UIGraphicsBeginImageContext(CGSizeMake(image.size.width, image.size.height));
					[image drawInRect:zoomRect];
					[image release];
					image = UIGraphicsGetImageFromCurrentImageContext();
					UIGraphicsEndImageContext();
					
					[self updateImageUsingImage:image];
					self.topQuality = FALSE;
				}
				
				else {
					self.topQuality = TRUE;
                    
                    NSLog(@"Tile found at %@ (y:%d, x:%d)@%d", key, theTile.y, theTile.x, theTile.zoom);
                    //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);

					[self updateImageUsingImage:image];
					
					[image release];
				}

				
				//NSLog(@"Retain count for data = %i", [imageData retainCount]);
				
				break;
			}
			
			 
			else {
                
                //NSLog(@"Tile not found at %@ (y:%d, x:%d)@%d", key, theTile.y, theTile.x, theTile.zoom);
                zoom --;
            }
		}
	
		[rs close];
		//[db clearCachedStatements]; //** TF addition - may cause slowdown
		[pool drain];
		
		//NSLog(@"Retain count for data2 = %i", [imageData retainCount]);
		//imageData = nil;
	}
	
return self;
	
}
 

@end
