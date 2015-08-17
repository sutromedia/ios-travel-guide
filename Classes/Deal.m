//
//  Deal.m
//  TheProject
//
//  Created by Tobin Fisher on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Deal.h"
#import "FMResultSet.h"
#import "Entry.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "EntryCollection.h"

@implementation Deal

@synthesize title, shortTitle, description, image, squareImage, imageURL, price, value, discount, expiration, merchantName, url, rowid, entry, imageFileLocation, distance, imageData, entryName, distanceString, discountString, priceString;

- (id)initWithRow:(FMResultSet *) rs {
	
	self = [super init];
	
	if (self) {
		
        self.discount = [rs doubleForColumn:@"discount"];
        self.discountString = self.discount > 99.9 ? @"Free" : [NSString stringWithFormat:@"%0.0f%% off", self.discount];
		self.title = [rs stringForColumn:@"title"];
        self.shortTitle = [rs stringForColumn:@"short_title"];
        if ([shortTitle length] == 0)
            self.shortTitle = discount > 0 ? [NSString stringWithFormat:@"%0.0f%% OFF - %@", self.discount, self.title] : self.title;
        
        self.description = [rs stringForColumn:@"description"];
        self.imageURL = [rs stringForColumn:@"image_url"];
        self.merchantName = [rs stringForColumn:@"merchant_name"];
        self.url = [rs stringForColumn:@"url"];
        self.price = [rs doubleForColumn:@"price"];
        self.priceString = self.price == 0 ? @"Free" : [NSString stringWithFormat:@"$%0.2f", self.price];
        self.value = [rs doubleForColumn:@"value"];
        self.rowid = [rs intForColumn:@"rowid"];

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *expirationDate = [dateFormatter dateFromString:[rs stringForColumn:@"expiration"]];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        self.expiration = [dateFormatter stringFromDate:expirationDate];
        
        
        @synchronized([Props global].dbSync) {
            
            FMDatabase * db = [EntryCollection sharedContentDatabase];
            FMResultSet * rs1 = [db executeQuery:[NSString stringWithFormat:@"SELECT entryid FROM entry_deals WHERE dealid = %i", self.rowid]];
            
            if ([db hadError]) NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            
            if ([rs1 next])self.entry = [EntryCollection entryById:[rs1 intForColumn:@"entryid"]];
            
            [rs1 close];
        }
        
        self.entryName = self.entry != nil ? self.entry.name : @"";
        
        self.distance = [[LocationManager sharedLocationManager] getDistanceFromHereToPlaceWithLatitude:entry.latitude andLongitude:entry.longitude];
        
        self.distanceString = self.entry !=nil && self.distance != kNoDistance ? [NSString stringWithFormat:@"%0.1f %@ away", self.distance, [Props global].unitsInMiles ? @"mi" : @"km"] : @" ";//space prevent weird additional line from being added. Dunno why
        
        self.imageFileLocation = [NSString stringWithFormat:@"%@/images/%i_deal.png", [Props global].contentFolder, self.rowid];
	}
	
	return self;
}




- (UIImage*) image {
    
    NSString *path = [NSString stringWithFormat:@"%@/images/%i_deal.jpg", [Props global].contentFolder, rowid];
    NSLog(@"path = %@", path);
    UIImage *theImage = [[UIImage alloc] initWithContentsOfFile:path];
    
    NSLog(@"The image = %@", theImage);
    
    return theImage;
}

- (void) makeDealImage {
    
    @autoreleasepool {
        
        UIImage *_image = [UIImage imageWithData: self.imageData];
        
        if (_image == nil){
            
            @synchronized([Props global].dbSync) {
                
                FMDatabase * db = [EntryCollection sharedContentDatabase];
                FMResultSet * rs1 = [db executeQuery:[NSString stringWithFormat:@"SELECT entryid FROM entry_deals WHERE dealid = %i", self.rowid]];
                
                if ([db hadError]) NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                
                if ([rs1 next])self.entry = [EntryCollection entryById:[rs1 intForColumn:@"entryid"]];
                
                [rs1 close];
            }
            
            _image = self.entry.iconImage;
        }
        
        //Rules
        //No white space
        //Stretch/compress side being cropped a bit to minimize crop
        
        float imageX, imageY;
        float scaledWidth, scaledHeight;
        float imageWidth = 300;
        float imageHeight = 184;
        
        //wider than current aspect ratio
        if (_image.size.width/_image.size.height > imageWidth/imageHeight) {
            imageY  = 0;
            scaledWidth = _image.size.width * (imageHeight/_image.size.height);
            float delta = scaledWidth - imageWidth;
            scaledWidth -= pow(delta, 0.97);
            imageX = (imageWidth - scaledWidth)/2;
            scaledHeight = imageHeight;
            
        }
        
        //taller than current aspect ratio
        else {
            imageX = 0;
            scaledWidth = imageWidth;
            scaledHeight = _image.size.height * (imageWidth/_image.size.width);
            float delta = scaledHeight - imageHeight;
            scaledHeight -= pow(delta, 0.97);
            imageY = (imageHeight - scaledHeight)/2;
        }
        
        UIGraphicsBeginImageContext(CGSizeMake(imageWidth, imageHeight));
        
        [_image drawInRect:CGRectMake(imageX, imageY, scaledWidth, scaledHeight)];
        
        UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *_imageData = UIImageJPEGRepresentation(thumbnail, 1.0);
        
        NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i_deal.png",[Props global].contentFolder, self.rowid];
        
        NSError *theError = nil;
        
        
        if([_imageData writeToFile: theFilePath  options:NSDataWritingFileProtectionNone error:&theError]!= TRUE){
            NSLog(@"**** ERROR:GUIDEDOWNLOADER.requestFinished: failed to write local file to %@, error = %@, userInfo = %@ *******************************************************************", theFilePath, theError, [theError userInfo]);
        }
    }
}


- (UIImage*) squareImage {
    
	float imageX, imageY;
	float scaledWidth, scaledHeight;
	float imageWidth = 100;
    
    UIImage *theImage = self.image;
	
	//landscape
	if (theImage.size.width > theImage.size.height) {
		imageY  = 0;
		imageX = (theImage.size.height - theImage.size.width)/2 * (imageWidth/theImage.size.height);
		scaledWidth = theImage.size.width * (imageWidth/theImage.size.height);
		scaledHeight = imageWidth;
	}
	
	//Portrait
	else {
		imageX = 0;
		imageY = (theImage.size.width - theImage.size.height)/2 * (imageWidth/theImage.size.width);
		scaledWidth = imageWidth;
		scaledHeight = theImage.size.height * (imageWidth/theImage.size.width);
	}
	
	UIGraphicsBeginImageContext(CGSizeMake(imageWidth, imageWidth));
	
	[theImage drawInRect:CGRectMake(imageX, imageY, scaledWidth, scaledHeight)];
	
	UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    //[image release];
    NSLog(@"Thumbnail = %@", thumbnail);
	
	return thumbnail;
}


@end
