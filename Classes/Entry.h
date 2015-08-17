/*

File: Entry.h
Abstract: Encapsulates the data for a single data entry

Version: 1.7

*/

#import <Foundation/Foundation.h>
#import "LocationManager.h"

@class FMResultSet;

@interface Entry : NSObject {

	UIImage		*iconImage;
	NSArray		*images;
    NSArray     *demoEntryImages;
	NSArray		*tags;
	NSArray		*filterArray;
    //NSArray     *includedEntries;
    NSDictionary *hotelBookingLinks;
	NSString	*name;
	NSString	*description;
    NSString    *noHTMLShortDescription;
	NSString	*formattedPhoneNumber;
	NSString	*phoneNumber;
	NSString	*mobilewebsite;
	NSString	*tagline;
	NSString	*pricedetails;
	NSString	*hours;
	NSString	*address;
	NSString	*audiourl;
	NSString	*audioprice;
	NSString	*spatial_group_name;
	NSString	*pitchTitle;
	NSString	*pitchAuthor;
	NSString	*pitchURL;
    NSString    *twitterUsername;
    NSString    *facebookLink;
    NSString    *videoLink;
    NSString    *reservationLink;
	double		latitude;
	double		longitude;
	float		currentDistance;
    float       lastScrollPosition;
	long		iconid;
	int			entryid;
	int			icon;
	int			price;
    int         popularity;
	int			descriptionHTMLVersion;
    int         spatialGroupSortOrder;
    int         numberOfEntries;
    int         numberOfPhotos;
    int         numberOfDeals;
	BOOL		entryLoaded;
	BOOL		showOthers;
    BOOL        isDemoEntry;
    BOOL        hydrated;
    BOOL        isBannerEntry;
}
 
- (long) getIconId;
- (double) getLatitude;
- (double) getLongitude;
- (int) getPrice;
- (float) getCurrentDistance;
- (void) setCurrentDistance:(float) cd;
- (void) hydrateEntry;
- (NSMutableArray*) createImageArray;
- (NSMutableArray*) getFilterArray;
- (NSMutableArray*) createCommentsArray;
- (NSArray*) createDealsArray;
- (id)initWithRow:(FMResultSet *) rs;
- (id) initDemoEntryWithRow: (FMResultSet*) rs;
- (NSString*) createHTMLFormatedString;
- (NSString*) createHTMLForTags;
- (UIImage*) cropImage:(UIImage*) image;
- (void) headerView; //debugging method - remove me 

- (NSString*) shortDescriptionHTML;
//- (NSString*) noHTMLDescription;
- (NSString*) extractURL: (NSString*) fullHTML;
- (NSSet*)  generateIncludedEntries;


@property (nonatomic, strong)   NSDictionary    *hotelBookingLinks;
//@property (nonatomic, strong)   NSArray     *includedEntries;
@property (nonatomic, strong)	NSString	*name;
@property (nonatomic, strong)	NSString	*tagline;
@property (nonatomic, strong)	NSString	*pricedetails;
@property (nonatomic, strong)	NSString	*description;
@property (nonatomic, strong)	NSString	*noHTMLShortDescription;
@property (nonatomic, strong)	NSString	*formattedPhoneNumber;
@property (nonatomic, strong)	NSString	*phoneNumber;
@property (nonatomic)			int			price;
@property (nonatomic)			int			icon;
@property (nonatomic)			int			popularity;
@property (nonatomic, strong)	NSString	*hours;
@property (nonatomic, strong)	NSString	*address;
@property (nonatomic, strong)	NSString	*audiourl;
@property (nonatomic, strong)	NSString	*audioprice;
@property (nonatomic)			int			entryid;
@property (nonatomic, strong)	UIImage		*iconImage;
@property (nonatomic, strong)	NSString	*mobilewebsite;
@property (nonatomic, strong)	NSArray		*tags;
@property (nonatomic, strong)   NSArray     *demoEntryImages;
@property (nonatomic, strong)	NSString	*spatial_group_name;
@property (nonatomic, strong)	NSArray		*images;
@property (nonatomic, strong)	NSArray		*filterArray;
@property (nonatomic, strong)	NSString	*pitchTitle;
@property (nonatomic, strong)	NSString	*pitchAuthor;
@property (nonatomic, strong)	NSString	*pitchURL;
@property (nonatomic, strong)   NSString    *twitterUsername;
@property (nonatomic, strong)   NSString    *facebookLink;
@property (nonatomic, strong)   NSString    *videoLink;
@property (nonatomic, strong)   NSString    *reservationLink;
@property (nonatomic)			int			descriptionHTMLVersion;
@property (nonatomic)			int			spatialGroupSortOrder;
@property (nonatomic)           int         numberOfEntries;
@property (nonatomic)           int         numberOfPhotos;
@property (nonatomic)           int         numberOfDeals;
@property (nonatomic)           float       lastScrollPosition;
@property (nonatomic)			BOOL		showOthers;
@property (nonatomic)           BOOL        isDemoEntry;
@property (nonatomic)           BOOL        isBannerEntry;
@property (nonatomic)           double       latitude;
@property (nonatomic)           double       longitude;
//@property (nonatomic, retain) NSNumber *longitude;
//@property (nonatomic, retain) NSNumber *currentDistance;
//@property (nonatomic, retain) NSNumber *latitude;


@end
