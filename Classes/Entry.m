/*

File: Entry.m
Abstract: Simple object that encapsulates the data for a single data entry.

Version: 1.7

*/

#import "Entry.h"
#import "EntryCollection.h"
#import "Constants.h"
#import "Props.h"
#import "FMResultSet.h"
#import "FMDatabase.h"
#import "Comment.h"
#import "SMRichTextViewer.h"
#import "Reachability.h"
#import "Deal.h"

@implementation Entry

@synthesize entryid;
//@synthesize latitude;
//@synthesize includedEntries;
@synthesize name;
@synthesize description;
@synthesize noHTMLShortDescription;
@synthesize phoneNumber;
@synthesize formattedPhoneNumber;
//@synthesize longitude;
//@synthesize currentDistance;
@synthesize price;
@synthesize mobilewebsite;
@synthesize tagline;
@synthesize pricedetails;
@synthesize icon;
@synthesize hours;
@synthesize address;
@synthesize audiourl;
@synthesize audioprice;
@synthesize tags;
@synthesize	spatial_group_name;
@synthesize images;
@dynamic    demoEntryImages;
@synthesize filterArray;
@synthesize pitchTitle, pitchAuthor, pitchURL;
@synthesize descriptionHTMLVersion;
@synthesize showOthers;
@synthesize iconImage;
@synthesize spatialGroupSortOrder;
@synthesize popularity;
@synthesize isDemoEntry;
@synthesize lastScrollPosition;
@synthesize numberOfEntries; //Only used for SW entries
@synthesize numberOfPhotos; //Only used for SW entries
@synthesize numberOfDeals;
@synthesize latitude;
@synthesize longitude;
@synthesize isBannerEntry;
@synthesize twitterUsername, videoLink, reservationLink, facebookLink;
@synthesize hotelBookingLinks;

//- (int) getEntryId { return entryid; }

- (long) getIconId { return iconid; }

- (int) getPrice { return self.price; }

- (float) getCurrentDistance { return currentDistance; }

- (void) setCurrentDistance:(float) cd { currentDistance = cd; }

- (double) getLatitude {return latitude;}
- (double) getLongitude {return longitude;}


- (id) initDemoEntryWithRow:(FMResultSet *)rs {
    
	self = [super init];
	
    if (self) {
        
        self.isDemoEntry =  TRUE;
        
        [self initializePropertiesWithRow:rs];
        
        if ([Props global].appID <= 1) {
            
            @synchronized([Props global].dbSync) {
                
                FMDatabase * db = [EntryCollection sharedContentDatabase];
                NSString *query = [NSString stringWithFormat:@"SELECT author FROM pitches WHERE entryid = %i", self.entryid];
                FMResultSet * rs = [db executeQuery:query];
                
                if ([db hadError]) NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                
                if ([rs next]){
                    self.pitchAuthor = [rs stringForColumn:@"author"];
                }
                
                [rs close];
            }
        }
	}
	
	return self;
}


- (id)initWithRow:(FMResultSet *) rs {
	
	self = [super init];
	
    if (self)  {

        //NSLog(@"ENTRY.initWithRow");
        
        [self initializePropertiesWithRow:rs];
        
        if ([Props global].appID <= 1) {
           
            @synchronized([Props global].dbSync) {
                
                FMDatabase * db = [EntryCollection sharedContentDatabase];
                NSString *query = [NSString stringWithFormat:@"SELECT author FROM pitches WHERE entryid = %i", self.entryid];
                FMResultSet * rs = [db executeQuery:query];
                
                if ([db hadError]) NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                
                if ([rs next])
                    self.pitchAuthor = [rs stringForColumn:@"author"];
               
                [rs close];
            }
        }
	}
	
	return self;
}


- (void) initializePropertiesWithRow:(FMResultSet *) rs {
    
    entryLoaded = NO;
    self.tags =			nil;
    self.filterArray =	nil;
    self.noHTMLShortDescription = nil;
    self.hotelBookingLinks = nil;
    numberOfDeals = kValueNotSet;
    iconImage = nil;
    lastScrollPosition = 0;
    self.showOthers =   FALSE;
    currentDistance =	kNoDistance;
    
    self.entryid =                  [rs intForColumn:@"rowid"];
    self.icon =                     [rs intForColumn:@"icon_photo_id"];
    iconid =                        [rs intForColumn:@"icon_photo_id"];
    self.name =                     [rs stringForColumn:@"name"];
    latitude =                      [rs doubleForColumn:@"latitude"];
    longitude =                     [rs doubleForColumn:@"longitude"];
    self.descriptionHTMLVersion =	[rs intForColumn:@"description_html_version"];
    self.tagline =					[rs stringForColumn:@"subtitle"];
    self.price =                    [rs intForColumn:@"price"];
    self.spatial_group_name =       [rs stringForColumn:@"spatial_group_name"];
    self.description =              [rs stringForColumn:@"description"];
    self.popularity =   [Props global].appID <= 1 && !self.isDemoEntry ? [rs intForColumn:@"popularity"] : 0;
}


- (void) hydrateEntry {
	
	if (!hydrated && self.entryid != -1) {
		
        FMDatabase * db = [EntryCollection sharedContentDatabase];
        
		@synchronized([Props global].dbSync) {
			
			NSString * query = !self.isDemoEntry ? @"SELECT * FROM entries WHERE rowid = ?" : @"SELECT * FROM demo_entries WHERE rowid = ?";
            
			FMResultSet * rs = [db executeQuery:query,[NSNumber numberWithInt:self.entryid]];
			
			if ([db hadError]) NSLog(@"sqlite error in Entry get description, query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
			
			else if ([rs next]) {
				
				self.mobilewebsite =			[rs stringForColumn:@"website"];
				self.phoneNumber =				[rs stringForColumn:@"phone"];
				self.formattedPhoneNumber =		[rs stringForColumn:@"formatted_phone"];
				self.pricedetails =				[rs stringForColumn:@"pricedetails"];
				self.hours =					[rs stringForColumn:@"hours"];
				self.address =					[rs stringForColumn:@"address"];
                self.twitterUsername =          [rs stringForColumn:@"twitter_username"];
                self.pricedetails =				[rs stringForColumn:@"pricedetails"];
                
                if ([Props global].bundleVersion > 34930 && [Props global].appID > 1) {
                    self.facebookLink  =            [rs stringForColumn:@"facebook_url"];
                    self.videoLink =                [rs stringForColumn:@"video_url"];
                    self.reservationLink =          [rs stringForColumn:@"make_a_reservation_url"];
                }
                
                if ([Props global].appID == 37) {
                    NSMutableDictionary *tmpHotelsDict = [NSMutableDictionary dictionaryWithCapacity:3];
                    
                    NSString *otel_booking_link = [rs stringForColumn:@"otel_booking_url"];
                    if ([otel_booking_link length] > 0) [tmpHotelsDict setValue:otel_booking_link forKey:@"otel"];
                    
                    NSString *hotelscomBookingLink = [rs stringForColumn:@"hotelscom_booking_url"];
                    if ([hotelscomBookingLink length] > 0) [tmpHotelsDict setValue:hotelscomBookingLink forKey:@"hotelscom"];
                    
                    NSString *expediaBookingLink = [rs stringForColumn:@"expedia_booking_url"];
                    if ([expediaBookingLink length] > 0) [tmpHotelsDict setValue:expediaBookingLink forKey:@"expedia"];
                    
                    if ([tmpHotelsDict count] > 0){
                        NSLog(@"Adding booking link for %@", self.name);
                        self.hotelBookingLinks = tmpHotelsDict;
                    }
                    
                    else self.hotelBookingLinks = nil;
                }
                
                if ([Props global].appID <= 1 && !isDemoEntry) {
                    
                    self.numberOfEntries = [rs intForColumn:@"entry_count"];
                    self.numberOfPhotos = [rs intForColumn:@"photo_count"];
                }
			}
			
			[rs close];
		}
        
        hydrated = TRUE;
	}
}


- (void) headerView {
    
    NSLog(@"ERROR: Entry.headerView called for entry %@", self.name);
}

/*
- (void) release {
    
     if ([name isEqualToString:@"San Francisco Exploration Guide"]) {
         NSLog(@"ENTRY.release: name = %@, retain count = %i", name, [self retainCount]);
     }
    
    [super release];
}

- (id) retain {
    
    if ([name isEqualToString:@"San Francisco Exploration Guide"]) {
        NSLog(@"ENTRY.retain: name = %@, retain count = %i", name, [self retainCount]);
    }
    
    return [super retain];
}
*/

- (void)dealloc {
	
	if (isDemoEntry) NSLog(@"ENTRY.dealloc: demo entry = %@ entry with ID %i", self.name, self.entryid);

}
 

- (UIImage *)iconImage {

	//TF 072909 Having weird issue with this method occassionally returning an NSInvocation type object and crashing the program - changes to code below are attempts to avoid these crashes
   //NSLog(@"ENTRY.iconImage: looking for image for %@", name);
    if (entryid == -1)return nil;
    
	if(iconImage == nil) {
       
        //NSLog(@"ENTRY.iconImage: creating image for %@ with image id = %i", name, icon);
        UIImage *tmpImage = nil;
        
        if ([Props global].deviceShowsHighResIcons){
            
            tmpImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i", icon] ofType:@"jpg"]]; 
            
            if(tmpImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
                
                NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/images/%i.jpg",[Props global].contentFolder , icon];
                tmpImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
            }
            
            if(tmpImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
                
                NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , icon];
                tmpImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
            }
            
            if(tmpImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
                
                tmpImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100", icon] ofType:@"jpg"]]; 
            }
            
            if(tmpImage == nil) { //look for a big version of the image (if we're on the iPad)
                
                NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/images/%i_768.jpg",[Props global].contentFolder , icon];
                tmpImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
            }
            
            if (tmpImage != nil) tmpImage = [self cropImage:tmpImage];
            
            else tmpImage =[[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i-icon", icon] ofType:@"jpg"]];
            
            if (tmpImage == nil) NSLog(@"Missing image at %@", [[NSString alloc] initWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , icon]);
        }
        
        else {
            tmpImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i-icon", icon] ofType:@"jpg"]];
            
            if(tmpImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
                
                NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/images/%i-icon.jpg",[Props global].contentFolder , icon];
                tmpImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
            }
            
            if(tmpImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
                
                NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/%i-icon.jpg",[Props global].contentFolder , icon];
                tmpImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
            }
			
			if(tmpImage == nil) { //Use an 100 px image if necessary
                
                NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/%i_x100.jpg",[Props global].contentFolder , icon];
                tmpImage = [[UIImage alloc] initWithContentsOfFile:theFilePath];
            }
			
			if(tmpImage == nil) { //look for the image in the documents/app name directory if it's not in the resources folder
                
                tmpImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100", icon] ofType:@"jpg"]];
            }
        }
        
        if (tmpImage == nil) NSLog(@"ENTRY.iconImage:Could not find image with id %i for %@", icon, name);
        
        self.iconImage = tmpImage;
    }
    
    //NSLog(@"ENTRY.iconImage: About to return icon image of class %@", [iconImage class]);
	
    return iconImage;
}


- (UIImage*) cropImage:(UIImage*) image {
	
	float imageX, imageY;
	float scaledWidth, scaledHeight;
	float imageWidth = 100;
	
	//landscape
	if (image.size.width > image.size.height) {
		imageY  = 0;
		imageX = (image.size.height - image.size.width)/2 * (imageWidth/image.size.height);
		scaledWidth = image.size.width * (imageWidth/image.size.height);
		scaledHeight = imageWidth;
	}
	
	//Portrait
	else {
		imageX = 0;
		imageY = (image.size.width - image.size.height)/2 * (imageWidth/image.size.width);
		scaledWidth = imageWidth;
		scaledHeight = image.size.height * (imageWidth/image.size.width);
	}
	
	UIGraphicsBeginImageContext(CGSizeMake(imageWidth, imageWidth));
	
	//CGRect thumbnailRect = CGRectZero;
	//thumbnailRect.origin = thumbnailPoint;
	//thumbnailRect.size.width  = scaledWidth;
	//thumbnailRect.size.height = scaledHeight;
	
	[image drawInRect:CGRectMake(imageX, imageY, scaledWidth, scaledHeight)];
	
	UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
	
	return thumbnail;
}

- (int) numberOfDeals {
    
    if (numberOfDeals == kValueNotSet && [Props global].hasDeals) {
        
        @synchronized([Props global].dbSync) {
            //NSLog(@"ENTRY.createImageArray:lock");
            FMDatabase * db = [EntryCollection sharedContentDatabase];
            //NSString *ending = ([Props global].screenWidth > 320) ? @"downloaded_768px_photo" : @"downloaded_320px_photo";
            NSString * query = @"SELECT COUNT(*) AS theCount FROM entry_deals WHERE entryid = ?";
            
            FMResultSet * rs = [db executeQuery:query, [NSNumber numberWithInt:self.entryid]];
            if ([db hadError]) NSLog(@"sqlite error in [ENTRY numberOfDeals], query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
            if ([rs next]) self.numberOfDeals = [rs intForColumn:@"theCount"];

            [rs close];
        }
    }
    
    return numberOfDeals;
}


- (NSArray*) createDealsArray {
    
    if ([Props global].hasDeals) {
        NSMutableArray * mutableDealsArray = [[NSMutableArray alloc] init];
        
        @synchronized([Props global].dbSync) {
            //NSLog(@"ENTRY.createImageArray:lock");
            FMDatabase * db = [EntryCollection sharedContentDatabase];
            //NSString *ending = ([Props global].screenWidth > 320) ? @"downloaded_768px_photo" : @"downloaded_320px_photo";
            NSString * query = @"SELECT deals.title, deals.short_title, deals.description, deals.image_url, deals.price, deals.value, deals.discount, deals.expiration, deals.merchant_name, deals.url, deals.provider, deals.general_weight, deals.rowid from deals, entry_deals, entries WHERE entry_deals.entryid = ? AND entry_deals.dealid = deals.rowid AND entry_deals.entryid = entries.rowid";
            
            FMResultSet * rs = [db executeQuery:query, [NSNumber numberWithInt:self.entryid]];
            if ([db hadError]) NSLog(@"sqlite error in [ENTRY createDealsArray], query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
            while ([rs next]) {
                
                Deal *deal = [[Deal alloc] initWithRow:rs];
                [mutableDealsArray addObject:deal];
            }
            [rs close];
        }
        
        NSArray *dealsArray = [[NSArray alloc] initWithArray:mutableDealsArray];
        
        
        return dealsArray;
    }
    
    else return nil;
}


- (NSMutableArray*) createImageArray {
	NSMutableArray * imageArray = [[NSMutableArray alloc] init];
	
	@synchronized([Props global].dbSync) {
		//NSLog(@"ENTRY.createImageArray:lock");
		FMDatabase * db = [EntryCollection sharedContentDatabase];
		//NSString *ending = ([Props global].screenWidth > 320) ? @"downloaded_768px_photo" : @"downloaded_320px_photo";
		NSString * query;
        
        if (([Props global].appID == 1 && !self.isDemoEntry) || [Props global].appID > 1) query = @"SELECT photos.rowid FROM photos, entry_photos, entries WHERE entry_photos.entryid = ? AND entry_photos.photoid = photos.rowid AND entry_photos.entryid = entries.rowid AND (photos.downloaded_320px_photo OR photos.downloaded_768px_photo OR photos.downloaded_x100px_photo) > 0 ORDER BY entry_photos.slideshow_order, photos.downloaded_768px_photo";
        
        else if (self.isDemoEntry) query = @"SELECT photos.rowid FROM photos, demo_entry_photos, demo_entries WHERE demo_entry_photos.entryid = ? AND demo_entry_photos.photoid = photos.rowid AND demo_entry_photos.entryid = demo_entries.rowid AND (photos.downloaded_320px_photo OR photos.downloaded_768px_photo OR photos.downloaded_x100px_photo) > 0 ORDER BY demo_entry_photos.slideshow_order, photos.downloaded_768px_photo";
        
        else query = @"SELECT photos.rowid FROM photos, entry_photos, entries WHERE entry_photos.entryid = ? AND entry_photos.photoid = photos.rowid AND entry_photos.entryid = entries.rowid AND (photos.downloaded_320px_photo OR photos.downloaded_768px_photo) > 0 ORDER BY entry_photos.slideshow_order, photos.downloaded_768px_photo";
	
        
		FMResultSet * rs = [db executeQuery:query, [NSNumber numberWithInt:self.entryid]];
		if ([db hadError]) NSLog(@"sqlite error in [ENTRY createImageArray], query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
		while ([rs next]) {
			NSNumber *imageName = [[NSNumber alloc] initWithInt:[rs intForColumn:@"rowid"]];
			[imageArray addObject:imageName];
		}
		[rs close];
		
		if ([imageArray count] == 0) {
			query = [NSString stringWithFormat:@"SELECT icon_photo_id FROM entries where rowid = %i", self.entryid];
			
			
			FMResultSet * rs = [db executeQuery:query];
			if ([db hadError]) NSLog(@"sqlite error in [ENTRY createImageArray], query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
			if ([rs next]) {
				NSNumber *imageName = [[NSNumber alloc] initWithInt:[rs intForColumn:@"icon_photo_id"]];
				[imageArray addObject:imageName];
			}
			[rs close];
		}
	}
	
	return imageArray;
}


- (NSArray*) getFilterArray {
	
	if(entryid != -1) {
		
		if ( self.filterArray == nil) {
		
			NSMutableArray * tempFilterArray = [[NSMutableArray alloc] init];
			
			@synchronized([Props global].dbSync) {
				//NSLog(@"ENTRY.createFilterArray:lock");
				FMDatabase * db = [EntryCollection sharedContentDatabase];
				NSString * query = [NSString stringWithFormat:@"SELECT groups.name as name FROM entry_groups, groups WHERE entry_groups.entryid = %i AND entry_groups.groupid = groups.rowid ORDER BY name", self.entryid];
				
				FMResultSet * rs = [db executeQuery:query, [NSNumber numberWithInt:self.entryid]];
				
				if ([db hadError]) NSLog(@"sqlite error in [PictureView initImageArray], query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
				
				while ([rs next]) {
					
					[tempFilterArray addObject:[rs stringForColumn:@"name"]];
					
				}
				
				[rs close];
			}
			
			self.filterArray = tempFilterArray;
		}
		
		return self.filterArray;
	}
	
	else return nil;
}


- (NSArray*) demoEntryImages {
    
    //NSLog(@"ENTRY.getDemoEntryImages");
    NSDate *date = [NSDate date];
    NSMutableArray * imageArray = [[NSMutableArray alloc] initWithCapacity:15];
    
    
	@synchronized([Props global].dbSync) {
		FMDatabase * db = [EntryCollection sharedContentDatabase];
        
        NSString *query = [NSString stringWithFormat: @"SELECT icon_photo_id FROM demo_entries, photos WHERE app_id = %i AND demo_entries.icon_photo_id = photos.rowid AND photos.downloaded_x100px_photo NOT NULL LIMIT 15", self.entryid];
        
        FMResultSet * rs = [db executeQuery:query];
        
		if ([db hadError]) NSLog(@"sqlite error in [Entry demoEntryImages], %d: %@",[db lastErrorCode], [db lastErrorMessage]);
        
		while ([rs next]) {
			NSNumber *imageName = [NSNumber numberWithInt:[rs intForColumn:@"icon_photo_id"]];
			[imageArray addObject:imageName];
		}
		[rs close];
	}
	
    float time = -[date timeIntervalSinceNow];
    if (time > 0.1) {
        NSLog(@"***WARNING: ENTRY.getDemoEntryImages took %0.2f s to complete", time);
    }
              
    NSLog(@"ENTRY.getDemoEntryImages: Returing %i images", [imageArray count]);
    
	return imageArray;
}

- (FMResultSet*) getFilterResultSet {
	
	if(entryid != -1) {
		
		@synchronized([Props global].dbSync) {
			//NSLog(@"ENTRY.createFilterArray:lock");
			FMDatabase * db = [EntryCollection sharedContentDatabase];
			NSString * query = [NSString stringWithFormat:@"SELECT groups.name as name , groups.rowid as rowid FROM entry_groups, groups WHERE entry_groups.entryid = %i AND entry_groups.groupid = groups.rowid ORDER BY name", self.entryid];
			
			FMResultSet * rs = [db executeQuery:query, [NSNumber numberWithInt:self.entryid]];
			
			if ([db hadError]) NSLog(@"sqlite error in [PictureView initImageArray], query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
			
			else return rs;
			
		}
	}
	
	return nil;
}


- (NSMutableArray*) createCommentsArray {
	NSMutableArray * commentsArray = [NSMutableArray new];
	
	@synchronized([Props global].dbSync) {
		//NSLog(@"ENTRY.createCommentsArray:lock");
		FMDatabase * db = [EntryCollection sharedContentDatabase];
		NSString * query = @"SELECT rowid, comments.*, '' AS name FROM comments WHERE entryid = ? ORDER BY rowid DESC";
		//NSString *query = @"SELECT entries.name AS name, comments.created, comments.subentry_name, comments.comment, comments.commenter_alias, comments.response_date, comments.response, comments.responder_name FROM comments, entries WHERE comments.entryid = ? AND entries.rowid = ? ORDER BY comments.rowid DESC";
		
		FMResultSet * rs = [db executeQuery:query, [NSNumber numberWithInt:self.entryid], [NSNumber numberWithInt:self.entryid]];
		if ([db hadError]) NSLog(@"sqlite error in Entry.createCommentsArray, query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
		while ([rs next]) {
			Comment * tmpComment = [[Comment alloc] initWithRow:rs];
			[commentsArray addObject:tmpComment];
			
		}
		[rs close];
	}
	
	return commentsArray;
}


/*
- (void) initRichTextViewer {
	
	[SMRichTextViewer sharedCopy].frame =  CGRectMake (0, 0, [Props global].screenWidth, 20);
	
	NSString *htmlString = [self createHTMLFormatedString];	
	
	[[SMRichTextViewer sharedCopy] loadHTMLString:htmlString baseURL:nil];
	
	//NSLog(@"HTML string = %@", htmlString);
}
*/

- (NSString*) createHTMLFormatedString {
	
	NSString *externalWebsiteColor = [Props global].cssExternalLinkColor; // ([[Reachability sharedReachability] internetConnectionStatus] != NotReachable) ? [Props global].cssExternalLinkColor : [Props global].cssNonactiveLinkColor;
	
	NSString *header = [NSString stringWithFormat:@"\
                        <html><head><title>Sutro Media</title>\
                        <style type=\"text/css\"> A:link{text-decoration: none; -webkit-tap-highlight-color:rgba(0,0,0,0);} .ext{font-weight:400; color:%@;} .SMEntryLink{font-weight:700; color:%@} .SMTag{font-weight:700; color:%@} body{padding:0; font-family:'Arial'; font-size:%0.0fpx; margin-bottom:0; padding:0; margin:0 %0.1fpx 0px %0.1fpx; width:%0.1fpx; border:0; color:%@; overflow:hidden;} </style>\
                        </head><body><div id='pageContent'>", [Props global].cssLinkColor, externalWebsiteColor, [Props global].cssLinkColor, [Props global].bodyTextFontSize, [Props global].rightMargin, [Props global].leftMargin, [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, [Props global].cssTextColor];
	
	NSString *htmlDescription = self.description;
	
	NSString *theTags =  [self createHTMLForTags];
	
	NSString *tagString = [NSString stringWithFormat:@"<p style='text-align:left; font-weight:700; width:%f; border-top:%0.1fpx;'>%@</p>",[Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, [Props global].tweenMargin, theTags];
	
	NSString *footer = @"</div></body></html>";
	
	NSString *formattedString = nil;
	
	if (descriptionHTMLVersion == 1 || entryid == -1) {
		
		if (theTags != nil)
			formattedString = [NSString stringWithFormat:@"%@%@%@%@",header,htmlDescription,tagString,footer];
		
		else formattedString = [NSString stringWithFormat:@"%@%@%@",header,htmlDescription,footer];
	}
	
	//if rich text isn't available, just show the tags
	else formattedString = [NSString stringWithFormat:@"%@%@%@",header,tagString,footer];
											
	return formattedString;
}


- (NSString*) createHTMLForTags {
	
	FMResultSet *rs = [self getFilterResultSet];
	
	NSString *htmlTagString = @"";
	
	while ([rs next]) {
		
		NSString *tagString = [[rs stringForColumn:@"name"] stringByReplacingOccurrencesOfString:@" " withString:@"&nbsp;"];
		
		htmlTagString = [htmlTagString stringByAppendingString:[NSString stringWithFormat:@"<a class='SMTag' href='SMTag:%i'>%@</a>, ",[rs intForColumn:@"rowid"], tagString]];
	}
		
		
	if ([htmlTagString length] >= 2) htmlTagString = [htmlTagString substringToIndex:([htmlTagString length]-3)];
		
	else htmlTagString = nil;
	
	
	return htmlTagString;
}


- (NSString*) noHTMLShortDescription {
    
    if (noHTMLShortDescription == nil) {
        
        if (self.description == nil) [self hydrateEntry];
        
        if (self.description == nil || entryid == -1) return nil;
        
        //NSLog(@"Entry name = %@", self.name);
        //NSLog(@"Description = %@", self.description);
        NSScanner *thescanner;
        NSString *text = nil;
        NSString *flatString = [NSString stringWithString:self.description];
        
        //NSLog(@"Description = %@", self.description);
        
        thescanner = [NSScanner scannerWithString:flatString];
        
        while ([thescanner isAtEnd] == NO) {
            
            // find start of tag
            [thescanner scanUpToString:@"<" intoString:nil] ; 
            
            // find end of tag
            [thescanner scanUpToString:@">" intoString:&text] ;
            
            // replace the found tag with a space
            //(you can filter multi-spaces out later if you wish)
            flatString = [flatString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@" "];
            
        }
        
        float length = ([Props global].screenWidth - 50) * 0.7;
        
        flatString = [flatString length] > length ? [flatString substringToIndex:length] : flatString;
        
        flatString = [flatString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        flatString = [flatString stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
        flatString = [flatString stringByReplacingOccurrencesOfString:@"&nbsb;" withString:@" "];
        flatString = [flatString stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
        flatString = [flatString stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        flatString = [flatString stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        
        flatString = [flatString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        flatString = [flatString stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        flatString = [flatString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        flatString = [flatString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        flatString = [flatString stringByReplacingOccurrencesOfString:@"  " withString:@" "];
        
        [self setNoHTMLShortDescription:flatString];
    }
    
    return noHTMLShortDescription;    
}


- (NSString*) shortDescriptionHTML {
    
    //box-shadow: 0px 3px 3px rgba(0, 0, 0, 0.8);
    //background-color:rgba(0,0,0,0.7);
    
    NSString *header = [NSString stringWithFormat:@"\
                        <html><head><title>Sutro Media</title>\
                        <style type=\"text/css\">\
                        A:link{text-decoration: none; -webkit-tap-highlight-color:rgba(0,0,0,0); opacity:1.0;}\
                        .SMEntryLink{font-weight:700; color:%@; opacity:0.9}\
                        body{padding:0; font-family:'Arial'; font-size:11px; margin-bottom:0; padding:0; margin:0; border:0; color:#444444; text-align:left;}\
                        </style>\
                        </head><body>\
                        <div id='pageContent'>\
                        ", [Props global].cssLinkColor];    
    
    NSString *truncatedDescription = [self.description length] > 450 ? [self.description substringToIndex:450] : self.description;
    NSString *htmlDescription = truncatedDescription;    
    
    NSString *footer = @"</div></body></html>";
    
    NSString *formattedString = [NSString stringWithFormat:@"%@%@%@",header,htmlDescription,footer];
    
    //NSLog(@"Formatted string = %@", formattedString);
    
    return formattedString;
}

- (NSString*) extractURL: (NSString*) fullHTML {
    
    NSString *urlString = nil;
    NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"<a href=\"http://www.*?>" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *regexResults = [regex matchesInString:fullHTML options:0 range:NSMakeRange(0, [fullHTML length])];
    
    for (NSTextCheckingResult *result in regexResults) {
        NSString *urlWithEndQuote = [fullHTML substringWithRange:result.range];
        urlString = [urlWithEndQuote substringWithRange:NSMakeRange(0, [urlWithEndQuote length] -1)];
        urlString = [urlString stringByReplacingOccurrencesOfString:@"<a href=\"" withString:@""];
        urlString = [urlString stringByReplacingOccurrencesOfString:@"\" target=\"_top\"" withString:@""];
    }
    
    NSLog(@"ENTRY.extractURL:URL = %@", urlString);
    
    return urlString;
}

- (NSSet*) generateIncludedEntries {
    
    if ([Props global].osVersion >= 4) {
        NSMutableSet *theIncludedEntries = [NSMutableSet new];
        
        NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"SMEntryLink://[0-9]*\">" options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *regexResults = [regex matchesInString:self.description options:0 range:NSMakeRange(0, [self.description length])];
        
        for (NSTextCheckingResult *result in regexResults) {
            NSString *fullString = [self.description substringWithRange:result.range];
            int theEntryID = [[fullString substringWithRange:NSMakeRange(14, [fullString length] -16)] intValue];
            [theIncludedEntries addObject:[NSNumber numberWithInt:theEntryID]]; 
        }
        
        return theIncludedEntries;
    }
        
    else return nil;
}



@end
