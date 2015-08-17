/*

File: PeriodicElements.m
Abstract: Encapsulates the collection of elements and returns them in presorted
states.

Version: 1.7

*/

#import "EntryCollection.h"
#import "Entry.h"
#import "Constants.h"
#import	"Props.h"
#import "FilterPicker.h"
#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "ActivityLogger.h"
#import "Reachability.h"
#import "ZipArchive.h"
#import "SMLog.h"
#import "Region.h"

//TF Test 4

#define FMDBQuickCheck(SomeBool) { if (!(SomeBool)) { NSLog(@"Failure on line %d", __LINE__); return 123; } }

@interface EntryCollection(mymethods) 

- (void)setupEntriesArray;
- (void) setupRegionsArray;
- (NSMutableArray*) sortEntries:(NSMutableArray*)theEntries withSortCriteria:(NSString*) sort;

@end


@implementation EntryCollection

@synthesize entriesDictionary;
@synthesize allEntries, sortedEntries, regions, sortedRegions;
@synthesize aboutSutroEntry;
@synthesize currentIndex, currentSort;


// setup the data collection
- init {
	
    self = [super init];
    
	if (self) {NSLog(@"EC.init");}
    
	return self;
}


- (void) initialize {
 
    //sharedContentDatabase = nil;
    [self setupEntriesArray];
    [self setupRegionsArray];
}


- (void) filterDataTo:(NSString *) filter { 
	
	NSLog(@"ENTRYCOLLECTION.filterDataTo:%@", filter);
    
    currentFilter = filter;
    
    NSMutableArray *tmpArray = [NSMutableArray new];
    self.sortedEntries = tmpArray;
	
	Entry * e = nil;
	
	if(filter == nil || [filter isEqualToString:@"Everything"]) 
		for(e in allEntries) [sortedEntries addObject:e];
	
	else if(![filter  isEqual: kFavorites]) {
		
		NSString *query = @"SELECT entries.name FROM entries, groups, entry_groups WHERE entries.rowid = entry_groups.entryid AND entry_groups.groupid = groups.rowid AND groups.name = ?";
		
		@synchronized([Props global].dbSync) {
			NSLog(@"ENTRYCOLLECTION.getCurrentEntries:lock");
			FMDatabase * db = [EntryCollection sharedContentDatabase];
			FMResultSet * rs = [db executeQuery:query, filter];
			if ([db hadError]) NSLog(@"sqlite error in [EntryCollection getCurrentEntries] %d: %@", [db lastErrorCode], [db lastErrorMessage]);
			while ([rs next]) {
				NSObject * entryToAdd = [self.entriesDictionary objectForKey:[rs stringForColumn:@"name"]];
                
				if (entryToAdd != nil) [self.sortedEntries addObject:entryToAdd];
				//Entry *e = entryToAdd;
				//NSLog(@"ENTRYCOLLECTION.getCurrentEntries:Just added %@", e.name);
			}
			[rs close];
		}
		
	}
	else if([filter  isEqual: kFavorites]) {
		
		NSArray *theFavorites = [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]]; //get the array of names of favorite entries
		
		if([theFavorites count] > 0) {
			for(NSString* entryName in theFavorites){
				Entry *e = [self.entriesDictionary objectForKey:entryName];
				
				if (e != nil)[sortedEntries addObject: e];
			}
		}
		
		if ([theFavorites count] == 0 || [sortedEntries count] == 0) {
			NSLog(@"ERROR ******* Something going wrong with favorites ********************");
			for(e in allEntries) [sortedEntries addObject:e];
			[[FilterPicker sharedFilterPicker] removeFavoriteChoice];
			
			SMLog *log = [[SMLog alloc] initWithPageID: kError  actionID: kFavoritesMissing];
             [[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
		}
	}
	
	else {
		NSLog(@"ERROR *********** Entry collection - filter criter not found");
		for(e in allEntries) [sortedEntries addObject:e];
	}
    
    
    NSLog(@"EC.filterDataTo:%i entries", [sortedEntries count]);
}	


- (void) filterDataTo:(NSString *) filter withSortCriteria:(NSString *) sort { 
	
	NSLog(@"ENTRYCOLLECTION.filterDataTo:%@ withSortCriteria:%@", filter, sort);
	
    [self filterDataTo:filter];
    
	currentSort = sort;
    
    //Save last sort as default for SW and restarts
    NSString *sortKey = [NSString stringWithFormat:@"%@_%i", kLastSort, [Props global].appID];
    [[NSUserDefaults standardUserDefaults] setObject:currentSort forKey:sortKey];
    
    //Save last filter as default for SW and restarts
    NSString *filterKey = [NSString stringWithFormat:@"%@_%i", kLastFilter, [Props global].appID];
    [[NSUserDefaults standardUserDefaults] setObject:filter forKey:filterKey];
    
    
    NSLog(@"EC.filterDataTo:withSortCriteria: %i entries", [sortedEntries count]);
    
    if (sort != [Props global].spatialCategoryName) self.sortedEntries = [self sortEntries:sortedEntries withSortCriteria:sort];
    
    /*
    //Add About Sutro Media entry at the very end if we aren't showing favorites
        if (![filter isEqualToString:@"Favorites"]) [sortedEntries addObject: aboutSutroEntry];
        
        //if ((filter == nil || [filter isEqualToString: @"Everything"])) {
            //NSLog(@"ENTRYCOLLECTION.getCurrentEntries: adding search entry");
            Entry *e = [[Entry alloc] init];
            e.name = @"_Search cell";
            e.entryid = kSearchCellID;
            [sortedEntries insertObject:e atIndex:0];
            [e release];
        //}
    }*/
    
    if (sort == [Props global].spatialCategoryName) {
        self.sortedRegions = [self sortEntries:sortedEntries withSortCriteria:sort];
        
        if (self.sortedRegions != nil && [self.sortedRegions count] > 0) {
            Region *region = [self.sortedRegions objectAtIndex:0];
            Entry *entry = [region.entries objectAtIndex:0];
            NSLog(@"EC.filterDataTo: sorted regions has %i objects with first entry = %@", [self.sortedRegions count], entry.name);
        }
    }
}	


- (void) updateDataWithSearchTerm:(NSString*) searchTerms withSortCriteria:(NSString *) sort { 	
	
	NSLog(@"ENTRYCOLLECTION.updateDataWithSearchTerms: %@", searchTerms);
    
    currentSort = sort;
	
	if ([searchTerms length] == 0) [self filterDataTo:@"Everything" withSortCriteria:sort];
	
	else {
        
        NSMutableArray * tmpArray = [NSMutableArray new];
        self.sortedEntries = tmpArray;
        
        NSString *substitutionTerm = [NSString stringWithFormat:@"%@%@%@", @"'%",searchTerms, @"%'"];
        
        NSString *query = [NSString stringWithFormat:@"SELECT entries.name FROM entries WHERE entries.name LIKE %@ OR entries.description LIKE %@ OR entries.subtitle LIKE %@ OR entries.rowid IN (SELECT comments.entryid FROM comments WHERE comments.comment LIKE %@ OR comments.response LIKE %@)", substitutionTerm, substitutionTerm, substitutionTerm, substitutionTerm, substitutionTerm];
        
        @synchronized([Props global].dbSync) {
            NSLog(@"ENTRYCOLLECTION.getCurrentEntriesForSearchTerms:lock");
            FMDatabase * db = [EntryCollection sharedContentDatabase];
            FMResultSet * rs = [db executeQuery:query];
            if ([db hadError]) NSLog(@"sqlite error in [EntryCollection getCurrentEntries] %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            while ([rs next]) {
                //NSLog(@"About to add %@", [rs stringForColumn:@"name"]);
                Entry * entryToAdd = [self.entriesDictionary objectForKey:[rs stringForColumn:@"name"]];
                if (entryToAdd != nil && entryToAdd.entryid != -1) [self.sortedEntries addObject:entryToAdd];
            }
            [rs close];
        }
        
        NSLog(@"EC.updateDataWithSearchTerm: sorted entries has %i objects", [sortedEntries count]);
        
        if (sort == [Props global].spatialCategoryName){
            sort = kSortByPopularity;
            currentSort = kSortByPopularity;
        }
        
        sortedEntries = [self sortEntries:sortedEntries withSortCriteria:sort];
    }
}	


- (NSMutableArray*) sortEntries:(NSMutableArray*)theEntries withSortCriteria:(NSString*) sort {
	
	NSSortDescriptor * sortDescriptor = nil;
	
	if([sort  isEqual: kSortByDistance]) {
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"currentDistance" ascending:YES selector:@selector(compare:)] ;
		
		double currentTime = [NSDate timeIntervalSinceReferenceDate];
		
		if((currentTime - lastLocationRecalculationTimestamp) > 5) // have we waited more than 1 second
		{
			currentTime = [NSDate timeIntervalSinceReferenceDate];
			lastLocationRecalculationTimestamp = currentTime;
			
			NSArray * entries = [[EntryCollection sharedEntryCollection] allEntries];
			int i = 0;
			for(i = 0; i < [entries count]; i++) {			
				Entry * e = [entries objectAtIndex:i];
				float latitude = [e getLatitude];
				float longitude = [e getLongitude];
				float nextDistance = [[LocationManager sharedLocationManager] getDistanceFromHereToPlaceWithLatitude:latitude andLongitude:longitude];
				[e setCurrentDistance:nextDistance];
				//NSLog(@"Distance for %@ = %f", e.name, nextDistance);
			}
		}
	}
	
	else if([sort  isEqual: kSortByName]) {
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] ;
	}
	
	else if([sort  isEqual: kSortByCost]) {
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"price" ascending:YES selector:@selector(compare:)];
	}
    
    else if([sort  isEqual: kSortByPopularity]) {
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"popularity" ascending:NO selector:@selector(compare:)];
		
	}
	
	else if(sort == [Props global].spatialCategoryName) {
        
        //This sorts the entries within a given region
        sortDescriptor = [Props global].appID == 1 ? [[NSSortDescriptor alloc] initWithKey:@"popularity" ascending:NO selector:@selector(compare:)] : [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    }
	
	//if all else fails, sort by name
	else sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	
	if(sortDescriptor != nil) {
		
		NSArray *descriptors = [NSArray arrayWithObject:sortDescriptor];
		[theEntries sortUsingDescriptors:descriptors];
	}
    
    //Remove the cost not applicable entries and add them back at the end
	if([sort  isEqual: kSortByCost]) {
		NSMutableArray *costNotApplicableEntries = [NSMutableArray new];
		
		for(Entry *e in sortedEntries) {
			if([e getPrice] == -1)
				[costNotApplicableEntries addObject:e];
		}
		
		for(Entry *e in costNotApplicableEntries) {
			[theEntries removeObject: e];
			[theEntries insertObject:e atIndex: [theEntries count]];
		}
		
	}
    
    if(sort == [Props global].spatialCategoryName) {
        
        sortDescriptor = nil;
        NSMutableArray *tmpRegions = [[NSMutableArray alloc] initWithArray:regions];
        
        //NSLog(@"EC.sortEntries: %i regions", [tmpRegions count]);
        
        NSMutableArray *regionsToRemove = [NSMutableArray new];
        
        for (Region *region in tmpRegions) {
            NSMutableArray *entries = [NSMutableArray new];
            region.open = FALSE;
            
            for (Entry *e in theEntries) {
                
                if ([e.spatial_group_name isEqualToString:region.name] || ([e.spatial_group_name length] == 0 && region.name == noRegionName)) [entries addObject:e];
            }
            
            if ([entries count] == 0) [regionsToRemove addObject:region];
            
            else region.entries = entries;
            
            region.headerView = nil;
            
            
             //NSLog(@"EC.sortEntries: %i entries for = %@", [region.entries count], [region name]);
        }
        
        //**[theEntries release];
        
        for (Region *region in regionsToRemove) [tmpRegions removeObject:region];
        
        
        return tmpRegions;
    }
    
    //Bring the banner entries to the front
    
    else if ([Props global].bundleVersion >= 27000) {
        
        int bannerEntryID = 0;
        
        if(currentFilter == nil || [currentFilter isEqualToString:@"Everything"]){
            @synchronized([Props global].dbSync) {
                FMDatabase * db = [EntryCollection sharedContentDatabase];
                NSString *query = @"SELECT value from app_properties WHERE key = 'top_level_intro_entry_id'";
                
                FMResultSet * rs = [db executeQuery:query];
                if ([db hadError]) NSLog(@"sqlite error in [EntryCollection getCurrentEntries] %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                if ([rs next]) bannerEntryID = [rs intForColumn:@"value"];
                
                [rs close];
            }
        }
        
        else {
            @synchronized([Props global].dbSync) {
                FMDatabase * db = [EntryCollection sharedContentDatabase];
                NSString *escapedName = [currentFilter stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
                NSString *query = [NSString stringWithFormat:@"SELECT intro_entry_id FROM groups WHERE name = '%@'", escapedName];
                
                FMResultSet * rs = [db executeQuery:query];
                if ([db hadError]) NSLog(@"sqlite error in [EntryCollection getCurrentEntries] %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                if ([rs next]) bannerEntryID = [rs intForColumn:@"intro_entry_id"];
                
                NSLog(@"Banner entry id = %i", bannerEntryID);
                
                [rs close];
            }
        }
        
        Entry *bannerEntry = nil;
        
        for(Entry *e in sortedEntries) {
			if(e.entryid == bannerEntryID){
                bannerEntry = e;
                bannerEntry.isBannerEntry = TRUE;
            }
            
            else e.isBannerEntry = FALSE;
		}
        
        //We'll need to add the entry to the top of the list in the event that the author didn't include the banner entry within the category
        if (bannerEntry == nil) {
            NSString *query = [NSString stringWithFormat:@"SELECT entries.name FROM entries WHERE rowid = %i", bannerEntryID];
            
            @synchronized([Props global].dbSync) {
                NSLog(@"ENTRYCOLLECTION.getCurrentEntries:lock");
                FMDatabase * db = [EntryCollection sharedContentDatabase];
                FMResultSet * rs = [db executeQuery:query];
                if ([db hadError]) NSLog(@"sqlite error in [EntryCollection getCurrentEntries] %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                if ([rs next]) bannerEntry = [self.entriesDictionary objectForKey:[rs stringForColumn:@"name"]];
                bannerEntry.isBannerEntry = TRUE;
                [rs close];
            }
        }
        
        if (bannerEntry != nil) {
            
            [sortedEntries removeObject:bannerEntry];
            [sortedEntries insertObject:bannerEntry atIndex:0];
        }
    }
    
	return theEntries;
}


- (void) setupRegionsArray {
    
    NSMutableArray *tmpRegions = [NSMutableArray new];
    self.regions = tmpRegions;
    
    noRegionName = [Props global].appID == 1 ? @"Reference" : [NSString stringWithFormat:@"No %@", [Props global].spatialCategoryName];
    
    FMDatabase *db = [EntryCollection sharedContentDatabase];
    
    @synchronized([Props global].dbSync) {
        
        NSString *query;
        
        if ([[Props global].defaultSort isEqualToString:@"month"]) query = @"SELECT DISTINCT spatial_group_name, CASE WHEN spatial_group_name ='January' then 1 WHEN spatial_group_name ='February' then 2 WHEN spatial_group_name ='March' then 3 WHEN spatial_group_name ='April' then 4 WHEN spatial_group_name ='May' then 5 WHEN spatial_group_name ='June' then 6 WHEN spatial_group_name ='July' then 7 WHEN spatial_group_name ='August' then 8 WHEN spatial_group_name ='September' THEN 9 WHEN spatial_group_name ='October' THEN 10 WHEN spatial_group_name ='November' THEN 11 WHEN spatial_group_name ='December' THEN 12 else 13 end as month_order FROM entries ORDER BY month_order";
        
        else query = @"SELECT DISTINCT spatial_group_name FROM entries ORDER BY spatial_group_name";
        
        FMResultSet *rs = [db executeQuery:query];
        
        while ([rs next]) {
            Region *region = [[Region alloc] init];
            NSString *regionName =[rs stringForColumn:@"spatial_group_name"];
            if ([regionName length] == 0) regionName = noRegionName;
            region.name = regionName;
            [self.regions addObject:region];
        }
    }
    
    Region *noRegion = nil;
    for (Region *region in self.regions) {
        if (region.name == noRegionName) {
            noRegion = region;
        }
    }
    
    if (noRegion != nil) {
        [regions removeObject:noRegion];
        [regions addObject:noRegion];
    }
}


- (void)setupEntriesArray {
	
	self.entriesDictionary = [NSMutableDictionary new];
	self.allEntries = [NSMutableArray new];
	
	
	NSString *query;
    int spatialGroupSortOrder = 1;
	
	if ([Props global].appID <= 1) 
		query = [NSString stringWithFormat: @"SELECT rowid,* FROM entries WHERE NOT rowid = %i ORDER BY %@", [[Props global] getOriginalAppId], [Props global].defaultSort];
	
	else query = [NSString stringWithFormat: @"SELECT rowid,* FROM entries ORDER BY %@",[Props global].defaultSort];
    
    NSLog(@"EC.setupEntriesArray: Query = %@", query);
	
	@synchronized([Props global].dbSync) {
		//NSLog(@"ENTRYCOLLECTION.setupEntriesArray:lock");
		FMDatabase * db = [EntryCollection sharedContentDatabase]; 
		FMResultSet *rs = [db executeQuery:query];
		
		if ([db hadError]) {
			NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		}
		while ([rs next]) {
			
			Entry *anEntry = [[Entry alloc] initWithRow:rs];
            //NSLog(@"Just created entry for %@", [anEntry name]);
			
			if (anEntry != nil) {
                anEntry.spatialGroupSortOrder = spatialGroupSortOrder;
				[allEntries addObject:anEntry];
				
				// store that item in the entries dictionary with the name as the key
				[self.entriesDictionary setObject:anEntry forKey:anEntry.name];
				
                
                spatialGroupSortOrder ++;
			}
		}
		[rs close];
	}
	
	NSLog(@"ENTRYCOLLECTION.setupEntriesArray with %i entries", [self.entriesDictionary count]);
    
	// setup About Sutro Entry
	Entry *tmpSutroEntry = [[Entry alloc] init];
	tmpSutroEntry.entryid = -1;
	tmpSutroEntry.price = -1;
	tmpSutroEntry.name = @"About Sutro Media";

    if ([Props global].isShellApp) 
        tmpSutroEntry.description = @"<br>By enabling local authors to publish their expertise on mobile phones, <a class='ext' href='http://sutromedia.com'>Sutro Media</a> makes it easier and more fun for you to explore the world!<p>\
        If you have any comments or suggestions, we'd love to hear from you at <a class='ext' href='mailto:letusknow@sutromedia.com'>letusknow@sutromedia.com</a></p></p>\
        <p>Thank you!</p><hr><br>\
        We also very much appreciate the various and talented contributors of flexibly licensed photographs, maps and software.<br><br> We are particularly indebted to the many Flickr Creative Commons photographers (whose pages are clickable from their photos) and the OpenStreetMap developers and contributors -> 'Map data (c) <a class='ext' href='http://www.openstreetmap.org/'>OpenStreetMap</a> (and) contributors, <a class='ext' href='http://creativecommons.org/licenses/by-sa/2.0/'>CC-BY-SA</a>'";
    else
        tmpSutroEntry.description = @"<br>By enabling local authors to publish their expertise on mobile phones, <a class='ext' href='http://sutromedia.com'>Sutro Media</a> makes it easier and more fun for you to explore the world!<p>\
        To explore, sample, and purchase our wide world of guides, download (for free!) <a class='ext' href = 'http://www.sutromedia.com/world'> Sutro World</a>, our travel library for the world.<p>\
        If you have any comments or suggestions, we'd love to hear from you at <a class='ext' href='mailto:letusknow@sutromedia.com'>letusknow@sutromedia.com</a></p></p>\
        <p>Thank you!</p><hr><br>\
        We also very much appreciate the various and talented contributors of flexibly licensed photographs, maps and software.<br><br> We are particularly indebted to the many Flickr Creative Commons photographers (whose pages are clickable from their photos) and the OpenStreetMap developers and contributors -> 'Map data (c) <a class='ext' href='http://www.openstreetmap.org/'>OpenStreetMap</a> (and) contributors, <a class='ext' href='http://creativecommons.org/licenses/by-sa/2.0/'>CC-BY-SA</a>'";

	tmpSutroEntry.icon = -666;
	self.aboutSutroEntry = tmpSutroEntry;
}


// return the entry at the index in the sorted by numbers array
- (Entry *)entryForIndexPath:(NSIndexPath *)indexPath {
	
    //NSLog(@"EC.entryForIndexPath: %i, %i entries in sorted entries array", indexPath.row, [sortedEntries count]);
	int index = indexPath.row;
	
    if (currentSort != [Props global].spatialCategoryName) {
        if([self.sortedEntries count] > index && (index >= 0)) {
            //NSLog(@"Entry class = %@", [[sortedEntries objectAtIndex:index] class]);
            return [sortedEntries objectAtIndex:index];
        }
        
        else if (index >= [self.sortedEntries count]) {
            //NSLog(@"ERROR - Trying to access out of range element in sortedEntries with indexPath of > count, which = %i", [self.sortedEntries count]);
            return aboutSutroEntry; // [self.sortedEntries objectAtIndex:([sortedEntries count] - 1)];
        }
        
        else {
            return nil;
            NSLog(@"ERROR - Something very weird happening in EntryCollection");
        }
    }
    
    else if ([sortedRegions count] > indexPath.section) {
        
        Region *region = [self.sortedRegions objectAtIndex:indexPath.section];
        return [region.entries objectAtIndex:indexPath.row];
    }
      
    else {
        NSLog(@"EC.entryForIndexPath: ERROR *****************");
        return nil;
    }
}


- (Entry *) getNextEntry:(Entry *) currentEntry {
	
    if (currentSort == [Props global].spatialCategoryName) {
        
        int regionIndex = 0;
        
        for (Region *region in self.sortedRegions) {
            
            int entryIndex = 0;
            
            for (Entry *e in region.entries) {
                
                if (e == currentEntry) {
                    
                    if (entryIndex != [region.entries count] - 1) {
                        
                        //unsigned indexes[2] = {regionIndex, entryIndex + 1};
                        //currentIndex = [NSIndexPath indexPathWithIndexes:indexes length:2];
                        NSLog(@"Entry index = %i", entryIndex);
                        return [region.entries objectAtIndex:entryIndex + 1];
                    }
                    
                    else if (regionIndex != [self.sortedEntries count] - 1) {
                        
                        NSLog(@"2");
                        //unsigned indexes[2] = {regionIndex - 1,0};
                        //currentIndex = [NSIndexPath indexPathWithIndexes:indexes length:2];
                        
                        Region *r = [self.sortedRegions objectAtIndex:regionIndex + 1];
                        return [r.entries objectAtIndex:0];
                    }
                    
                    else {
                        NSLog(@"3");
                        return currentEntry; //presumably we're on the last entry of the last region   
                    }
                }
                 entryIndex ++;
            }
            regionIndex++;
        }
        
        return currentEntry;
    }
    
    else {
    
        Entry * retVal = currentEntry;
        int currentEntryIndex = [self.sortedEntries indexOfObject:currentEntry];
        
        if(currentEntryIndex < [self.sortedEntries count] - 1) {
            retVal = [self.sortedEntries objectAtIndex:currentEntryIndex + 1];
        }
        
        return retVal;
    }
}


- (Entry *) getPreviousEntry:(Entry *) currentEntry {
    
    NSLog(@"EC.getPreviousEntry: current sort = %@", currentSort);
    
    if (currentSort == [Props global].spatialCategoryName) {
        
        int regionIndex = 0;
        
        for (Region *region in self.sortedRegions) {
            
            int entryIndex = 0;
            
            for (Entry *e in region.entries) {
                if (e == currentEntry) {
                    if (entryIndex != 0) {
                        
                        //unsigned indexes[2] = {regionIndex, entryIndex - 1};
                        //currentIndex = [NSIndexPath indexPathWithIndexes:indexes length:2];
                        
                        return [region.entries objectAtIndex:entryIndex - 1];
                    }
                    
                    else if (regionIndex != 0) {
                        //unsigned indexes[2] = {regionIndex - 1,0};
                        //currentIndex = [NSIndexPath indexPathWithIndexes:indexes length:2];
                        
                        Region *r = [self.sortedRegions objectAtIndex:regionIndex - 1];
                        return [r.entries objectAtIndex:[r.entries count] - 1];
                    }
                    
                    else return currentEntry;
                }
                
                entryIndex ++;
            }
            
            regionIndex++;
        }
        
        return currentEntry;
    }
    
    else {
        
        int currentEntryIndex = [self.sortedEntries indexOfObject:currentEntry];
        
        if(currentEntryIndex > 0) {
            
            unsigned indexes[2] = {0,currentEntryIndex - 1};
            currentIndex = [NSIndexPath indexPathWithIndexes:indexes length:2];
            
            //Exception handling added to address crashing issue on TestFlight
            @try {
                return [self.sortedEntries objectAtIndex:currentEntryIndex - 1];
            }
            @catch (NSException *exception) {
                return currentEntry;
            }
            @finally {
            }
        }
        
        else return currentEntry;
        
    }
}

#pragma mark 
#pragma mark Info About Entry Collection 

- (int) numberOfEntries {
	
	int count;
	
	@synchronized([Props global].dbSync) {
		
		//NSLog(@"ENTRYCOLLECTION.numberOfEntries:lock");
		FMDatabase * db = [EntryCollection sharedContentDatabase]; 
		
		FMResultSet *rs = [db executeQuery:@"SELECT COUNT(rowid) AS count FROM entries"];
		
		if ([db hadError]) {
			NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
		}
		
		if ([rs next]) {
			
			count = [rs intForColumn:@"count"];
		}
		
		else{ 
			count = 0;
			NSLog(@"ERROR - EntryCollection, Something wrong with database counting");
		}
		
		[rs close];
	}
	
	return count;
}


- (BOOL) containsEntry:(Entry*) theEntry {
	
	if (currentSort != [Props global].spatialCategoryName) {
        BOOL containsEntry = [self.sortedEntries containsObject:theEntry];
        
        //if (!containsEntry) NSLog(@"Sorted entries does not contain %@ in its %i objects", theEntry.name, [sortedEntries count]);
        
        return containsEntry;
    }
    
    else {
        
        for( Region *region in sortedEntries) {
            
            if ([region.entries containsObject:theEntry]) return TRUE;
        }
                 
        return FALSE;        
    }
}



#pragma mark 
#pragma mark Favorites Code

- (BOOL) entryIsInFavorites: (Entry *) theEntry {
	
	return [[[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]] containsObject: theEntry.name];
}


- (BOOL) favoritesExist {
	
	if ([[[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]] count] > 0)
		return TRUE;
	
	else 
		return FALSE;
}


- (void) addToFavorites:(Entry*) theEntry {

	NSMutableArray *theFavorites = [[NSMutableArray alloc] initWithArray: [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]] copyItems:TRUE]; //get the array of names of favorite entries
	
	[theFavorites addObject: theEntry.name];
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: [NSString stringWithFormat:@"favorites-%i", [Props global].appID]]; //doesn't seem to work to just write over existing data, need to remove first
	
	[[NSUserDefaults standardUserDefaults] setObject: theFavorites forKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if([theFavorites count] == 1) 
		[[FilterPicker sharedFilterPicker] addFavoriteChoice];
	
	  //*** Uncommented out on 090210

	SMLog *log = [[SMLog alloc] initPopularityLog];
	log.favorite_entry_id = theEntry.entryid;
    log.favorite_value = 1;
	[[ActivityLogger sharedActivityLogger] sendPopularityLog: [log createPopularityLog]];
}


- (void) removeFromFavorites: (Entry *) theEntry {
	
	NSMutableArray *theFavorites = [[NSMutableArray alloc] initWithArray: [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]]]; //get the array of names of favorite entries
	
	[theFavorites removeObject: theEntry.name];
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: [NSString stringWithFormat:@"favorites-%i", [Props global].appID]]; //doesn't seem to work to just write over existing data, need to remove first
	
	if([theFavorites count] > 0)
		[[NSUserDefaults standardUserDefaults] setObject: theFavorites forKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]];
	
	if([theFavorites count] == 0)
		[[FilterPicker sharedFilterPicker] removeFavoriteChoice];
	
	
	[[NSUserDefaults standardUserDefaults] synchronize];
    
    SMLog *log = [[SMLog alloc] initPopularityLog];
	log.favorite_entry_id = theEntry.entryid;
    log.favorite_value = 0;
	[[ActivityLogger sharedActivityLogger] sendPopularityLog: [log createPopularityLog]];
}

/*
- (void) applicationWillTerminate:(UIApplication *)application {
	
	[NSUserDefaults resetStandardUserDefaults];
	
}
*/

#pragma mark 
#pragma mark Class reset

/*- (void) initializeContent {
    sharedContentDatabase = nil;
    [self initialize];
}*/


#pragma mark 
#pragma mark Singleton stuff

// we use the singleton approach, one collection for the entire application
//static EntryCollection * sharedEntryCollection = nil;
static FMDatabase * sharedContentDatabase = nil;

//static bool needsReset;

+ (FMDatabase *) sharedContentDatabase {
	
	@synchronized([Props global].dbSync) {
		
		if(sharedContentDatabase == nil) {
			
			NSString * thePath;
            
            //Path for test app or guide in Shell app
			if ([Props global].inTestAppMode || ([Props global].isShellApp && [Props global].appID != 1)) thePath = [NSString stringWithFormat:@"%@/%i/content.sqlite3",[Props global].cacheFolder, [Props global].appID];	
			
			//Path for SW in shell app, SW in guide, and regular guide
            else thePath = [NSString stringWithFormat:@"%@/%@.sqlite3",[Props global].cacheFolder, @"content"];
						
			sharedContentDatabase = [[FMDatabase alloc] initWithPath:thePath];
			if (![sharedContentDatabase open]) NSLog(@"Could not open sqlite database from file = %@", thePath);
            
            NSLog(@"EC.sharedContentDatabase: path = %@", thePath);
		}
	}
    
	return sharedContentDatabase;
}


+ (void) resetContent{
	
    NSLog(@"EntryCollection.resetContent");
    
    //needsReset = TRUE;
    
    
	@synchronized([Props global].dbSync) {
        
		sharedContentDatabase = nil;
        
        //sharedEntryCollection.entriesDictionary = nil;
        //sharedEntryCollection.allEntries = nil;
        //sharedEntryCollection.regions = nil;
        //sharedEntryCollection.sortedEntries = nil;
        //sharedEntryCollection.sortedRegions = nil;
     
		//sharedEntryCollection = nil;
	}
}

/*
+ (EntryCollection*)sharedEntryCollection {
	
    @synchronized(self) {
		
        if (sharedEntryCollection == nil) {
			
			[[self alloc] init]; // assignment not done here
        }
    }
	
    return sharedEntryCollection;
}*/

+ (EntryCollection*)sharedEntryCollection {
	
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}


+ (Entry *) entryByName:(NSString *) theName {
	EntryCollection * ec = [EntryCollection sharedEntryCollection];
	return [ec.entriesDictionary objectForKey:theName];
}


+ (Entry *) entryById:(int) entryId {
	
	Entry *theEntry;
	
	@synchronized([Props global].dbSync) {

		FMDatabase *db = [EntryCollection sharedContentDatabase];
		
		FMResultSet *rs = [db executeQuery:@"SELECT name FROM entries WHERE rowid = ?",[NSNumber numberWithInt:entryId]];
		
		if ([rs next]){ 
			NSString *theName = [rs stringForColumn:@"name"];
			theEntry = [[EntryCollection sharedEntryCollection].entriesDictionary objectForKey:theName];
		}
        
		else theEntry = nil;
		
		[rs close];
	}

	return theEntry;
}


+ (Entry *) demoEntryById: (int) entryId {
    
    Entry *theEntry;
	
	@synchronized([Props global].dbSync) {
        
		FMDatabase *db = [EntryCollection sharedContentDatabase];
		
        FMResultSet *rs = [db executeQuery:@"SELECT rowid,* FROM demo_entries WHERE rowid = ?",[NSNumber numberWithInt:entryId]];
        
        NSLog(@"EC.demoEntryById: Query = %@", [rs query]);
        
        if ([rs next]){
            
            theEntry = [[Entry alloc] initDemoEntryWithRow:rs];
            //theEntry.isDemoEntry = TRUE;
        }
        
        else theEntry = nil;
		
		[rs close];
	}

	return theEntry;
}

/*
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedEntryCollection == nil) {
            sharedEntryCollection = [super allocWithZone:zone];
            return sharedEntryCollection;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}


- (void)dealloc {
    
    NSLog(@"ENTRYCOLLECTION.dealloc");
    [allEntries release];
    self.allEntries = nil;
}


- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}


- (unsigned)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released
}


- (oneway void)release {
    //do nothing
}


- (id)autorelease {
    return self;
}
*/


@end