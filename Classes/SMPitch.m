//
//  SMPitch.m
//  TheProject
//
//  Created by Tobin1 on 2/9/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import "SMPitch.h"
#import "EntryCollection.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "Props.h"


@implementation SMPitch

@synthesize appID, author, appName, linkshareURL;

- (id)initWithEntryID:(int) theEntryId {
	
	self = [super init];
	
	if (self) {
		
		//Get the appID		
		@synchronized([Props global].dbSync) {
           
            FMDatabase * db = [EntryCollection sharedContentDatabase];

			FMResultSet * rs = [db executeQuery:@"SELECT appid,author,app_name, linkshare_url FROM pitches WHERE entryid = ?", [NSNumber numberWithInt:theEntryId]];

			if ([db hadError]) NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
	
			while ([rs next]){
				self.appID = [rs intForColumn:@"appid"];
				self.author = [rs stringForColumn:@"author"];
				self.appName = [rs stringForColumn:@"app_name"];
				self.linkshareURL = [rs stringForColumn:@"linkshare_url"];
			}
		
			[rs close];
		}
		
		//NSLog(@"App id = %i, author = %@, appName = %@, linkShareURL = %@", appID, author, appName, linkshareURL);
		
		if (self.appID <= 1 || self.author == nil || self.appName == nil || self.linkshareURL == nil) return nil;
		
		/*
		//Get the author
		@synchronized([Props global].dbSync) {
			
			FMResultSet *rs = [db executeQuery:@"SELECT author FROM pitches WHERE entryid = ?", [NSNumber numberWithInt:theEntryId]];
		
			if ([db hadError]) NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		
			while ([rs next]) self.author = [rs stringForColumn:@"author"];
		
			[rs close];
		}
		
		if (self.author == nil) return nil;
		
		
		//Get the appName
		@synchronized([Props global].dbSync) {
			
			FMResultSet *rs = [db executeQuery:@"SELECT app_name FROM pitches WHERE entryid = ?", [NSNumber numberWithInt:theEntryId]];
		
			if ([db hadError]) NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		
			while ([rs next]) self.appName = [rs stringForColumn:@"app_name"];
		
			[rs close];
		
			if (self.appName == nil) return nil;
		}
		
		
		//Get the Linshare URL
		@synchronized([Props global].dbSync) {
			
			FMResultSet *rs = [db executeQuery:@"SELECT linkshare_url FROM pitches WHERE entryid = ?", [NSNumber numberWithInt:theEntryId]];
		
			if ([db hadError]) NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		
			while ([rs next]) self.linkshareURL = [rs stringForColumn:@"linkshare_url"];
		
			[rs close];
		
			if (self.linkshareURL == nil) return nil;
		}*/
	}
	return self;
}

- (void) dealloc {
	
	NSLog(@"Dealloc called in SMPitch");
}
	

@end
