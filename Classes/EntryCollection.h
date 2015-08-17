//Manages the cached entry collection

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@class Entry;

@interface EntryCollection : NSObject {
	NSMutableDictionary *entriesDictionary;
	NSMutableArray *allEntries;
    NSMutableArray *sortedEntries;
	NSString * currentFilter;
    NSString *currentSort;
	double lastLocationRecalculationTimestamp;
	Entry *aboutSutroEntry;
	NSUserDefaults *userDefaults;
    NSMutableArray *regions;
    NSMutableArray *sortedRegions;
    NSIndexPath *currentIndex;
    NSString *noRegionName;
}

@property (nonatomic, strong) NSMutableArray *allEntries;
@property (nonatomic, strong) NSMutableDictionary *entriesDictionary;
@property (nonatomic, strong) NSMutableArray *sortedEntries;
@property (nonatomic, strong) Entry *aboutSutroEntry;
@property (nonatomic, strong) NSIndexPath *currentIndex;
@property (nonatomic, strong) NSString *currentSort;
@property (nonatomic, strong) NSMutableArray *regions;
@property (nonatomic, strong) NSMutableArray *sortedRegions;


+ (EntryCollection*)sharedEntryCollection;
+ (Entry*) entryByName:(NSString*) theName;
+ (FMDatabase*) sharedContentDatabase;
+ (Entry *) entryById:(int) entryId;
+ (Entry *) demoEntryById: (int) entryId;
+ (void) resetContent;

//- (void) resetContent;
- (void) initialize;
- (void) filterDataTo:(NSString *) filter;
- (void) filterDataTo:(NSString *) filter withSortCriteria:(NSString *) sort;
- (void) updateDataWithSearchTerm:(NSString*) searchTerms withSortCriteria:(NSString *) sort;
- (void) addToFavorites:(Entry*) theEntry;
- (void) removeFromFavorites: (Entry *) theEntry;
- (BOOL) entryIsInFavorites:(Entry*) theEntry;
- (BOOL) favoritesExist;
- (Entry *) getPreviousEntry:(Entry *) currentEntry;
- (Entry *) getNextEntry:(Entry *) currentEntry;
- (int) numberOfEntries;
- (BOOL) containsEntry:(Entry*) theEntry;
- (Entry *)entryForIndexPath:(NSIndexPath *)indexPath;


@end
