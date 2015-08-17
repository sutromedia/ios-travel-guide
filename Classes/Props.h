/*
 
 File: Props.h
 Abstract: Encapsulates the data for the app properties
 
 Version: 1.7
 
 */

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface Props : NSObject {
		
	NSMutableArray		*filters;
	NSMutableArray		*freeImageArray;
    NSMutableArray      *availableSources; //content sources for downloading
	NSArray             *offlineLinkURLs;
    
	MKCoordinateRegion	mapRegion;
    UIDeviceOrientation lastOrientation;
    UIDeviceOrientation lastLastOrientation;
	
	NSString			*appName;
	NSString			*appShortName;
	NSString			*currentFilter;
	NSString			*contentFolder;
	NSString			*cacheFolder;
    NSString            *documentsFolder;
	NSString			*defaultSort;
	NSString			*taxiServicePhoneNumber;
	NSString			*font;
	NSString			*currencyString;
	NSString			*spatialCategoryName;
	NSString			*deviceID;
	NSString			*appLink;
	NSString			*authorName;
	NSString			*aboutSutroHTML;
	NSString			*aboutSutroHTML_NoInternet;
	NSString			*currentFilterPickerTitle;
	NSString			*reviewURL;
	NSString			*abstractPriceSymbol;
	NSString			*adminSuffix;
    NSString            *mapDatabaseLocation;
    NSString            *serverContentSource;
    NSString            *serverDatabaseUpdateSource;
	
	float				taxiServiceMinimumCharge;
	float				taxiServiceChargePerDistance;
	float				sessionID;
	float				osVersion;
    float               startingZoomLevel;
    float               innermostZoomLevel;
    float               latitudeSpan;
	
	int					currentFilterPickerRow;
	int					appID;
	int					deviceType;
	int					defaultMapType;
	int					bundleVersion;
	int					previousBundleVersion; //Used in figuring out whether to auto-upgrade or not
	int					svnRevision;
	int					originalAppId;
    int                 idleRefCount;
    int                 firstVersion;
    int                 concurrentDownloads;
	int					freemiumType;
	int					freemiumNumberofSampleEntriesAllowed;
	
	BOOL				inTestAppMode;
    BOOL                isTestAppDevice;
	BOOL				unitsInMiles;
    BOOL				hasRichText;
	BOOL				free;
	BOOL				sortable;
	BOOL				hasPrices;
	BOOL				hasLocations;
	BOOL				hasSpatialCategories;
    BOOL				hasAbstractPrices;
    BOOL                hasDeals;
    //BOOL                hasOfflineUpgrade;
    BOOL				showComments;
	BOOL				showPremiumContent;
    BOOL                showAds;
	BOOL				mapsNeedUpdating;
	BOOL				entryCollectionNeedsUpdate;
	BOOL				commentsDatabaseNeedsUpdate;
	BOOL				pitchesDatabaseNeedsUpdate;
	BOOL				dataDownloaderShouldCheckForUpdates;
    BOOL                isShellApp;
    BOOL                killDataDownloader;
    BOOL                deviceShowsHighResIcons;
    BOOL                downloadTestAppContent;
    BOOL                contentUpdateInProgress;
    BOOL                connectedToInternet;
	BOOL				lastConnectivityStatus;
	
	NSObject			*dbSync;
    NSObject            *mapDbSync;
	
	
	//Formatting Props
	UIColor				*navigationBarTint;
	UIColor				*navigationBarTint_entryView;
	UIColor				*descriptionTextColor;
	UIColor				*LVEntryTitleTextColor;
	UIColor				*LVEntrySubtitleTextColor;
	UIColor				*entryViewBGColor;
	UIColor				*linkColor;
	
	UIImage				*LVBGView;
	UIImage				*LVBGView_selected;
	
	NSString			*fontName;
    UIFont              *bodyFont;
    UIFont              *subtitleFont;
	
	NSString			*cssTextColor;
	NSString			*cssLinkColor;
	NSString			*cssNonactiveLinkColor;
	NSString			*cssExternalLinkColor;
	
    float				screenWidth;
	float				screenHeight;
	float				titleBarHeight;
	float				tweenMargin;
    float               landscapeSideMargin;
    float               portraitSideMargin;
	float				leftMargin;
	float				rightMargin;
	float				tinyTweenMargin;
	float				bodyTextFontSize;
	float				tableviewRowHeight;
    float               tableviewRowHeight_libraryView;
    float               tabBarHeight;
    
    NSString            *browseViewVariation;
}


+ (Props *) global;
- (void) setBasicProps;
- (void) setupPropsDictionary;
- (BOOL) supportsAudioFiles;
- (void) setTheAppID: (NSString*) theAppName;
- (int)	 getOriginalAppId;
- (void) setContentFolder;
- (BOOL) inLandscapeMode;
- (float) titleBarHeight;
- (void) updateScreenDimensions:(UIInterfaceOrientation)toInterfaceOrientation;
- (void) incrementIdleTimerRefCount;
- (void) decrementIdleTimerRefCount;
- (void) updateServerContentSource;
- (void) buildOfflineLinkURLArray;
- (void) updateInternetStatus;


@property (nonatomic, strong)	NSMutableArray		*filters;
@property (nonatomic)			MKCoordinateRegion	mapRegion;
@property (nonatomic, strong)	NSMutableArray	*freeImageArray;
@property (nonatomic, strong)   NSArray     *offlineLinkURLs;
@property (nonatomic, strong)	NSString	*taxiServicePhoneNumber;;
@property (nonatomic, strong)	NSString	*currencyString;
@property (nonatomic, strong)	NSString	*currentFilterPickerTitle;
@property (nonatomic, strong)	NSString	*contentFolder;
@property (nonatomic, strong)	NSString	*cacheFolder;
@property (nonatomic, strong)	NSString	*documentsFolder;
@property (nonatomic, strong)	NSString	*defaultSort;
@property (nonatomic, strong)	NSString	*spatialCategoryName;
@property (nonatomic, strong)	NSString	*deviceID;
@property (nonatomic, strong)	NSString	*appLink;
@property (nonatomic, strong)	NSString	*authorName;
@property (nonatomic, strong)	NSString	*abstractPriceSymbol;
@property (nonatomic, strong)	NSString	*aboutSutroHTML;
@property (nonatomic, strong)	NSString	*aboutSutroHTML_NoInternet;
@property (nonatomic, strong)	NSString	*reviewURL;
@property (nonatomic, strong)	NSString	*appName;
@property (nonatomic, strong)	NSString	*appShortName;
@property (nonatomic, strong)	NSString	*currentFilter;
@property (nonatomic, strong)	NSString	*adminSuffix;
@property (nonatomic, strong)	NSString	*mapDatabaseLocation;
@property (nonatomic, strong)   NSString    *serverContentSource;
@property (nonatomic, strong)   NSString    *serverDatabaseUpdateSource;


@property (nonatomic, strong)	NSObject	*dbSync;
@property (nonatomic, strong)   NSObject    *mapDbSync;

@property (nonatomic)           UIDeviceOrientation lastOrientation;
@property (nonatomic)           UIDeviceOrientation lastLastOrientation;
@property (nonatomic)			float		sessionID;
@property (nonatomic)			float		taxiServiceMinimumCharge;
@property (nonatomic)			float		taxiServiceChargePerDistance;
@property (nonatomic)			float		osVersion;
@property (nonatomic)           float       tabBarHeight;
@property (nonatomic)			float		startingZoomLevel;
@property (nonatomic)           float       innermostZoomLevel;
@property (nonatomic)           float       latitudeSpan;
@property (nonatomic)			int			currentFilterPickerRow;
@property (nonatomic)			int			bundleVersion;
@property (nonatomic)			int			appID;
@property (nonatomic)			int			deviceType;
@property (nonatomic)			int			svnRevision;
@property (nonatomic)			int 		defaultMapType;
@property (nonatomic)           int         firstVersion;
@property (nonatomic)           int         concurrentDownloads;
@property (nonatomic)			int			previousBundleVersion;
@property (nonatomic)			int			freemiumType;
@property (nonatomic)			int			freemiumNumberofSampleEntriesAllowed;

@property (nonatomic)			BOOL		commentsDatabaseNeedsUpdate;
@property (nonatomic)			BOOL		showComments;
@property (nonatomic)			BOOL		pitchesDatabaseNeedsUpdate;
@property (nonatomic)			BOOL		dataDownloaderShouldCheckForUpdates;
@property (nonatomic)			BOOL		inTestAppMode;
@property (nonatomic)           BOOL        isTestAppDevice;
@property (nonatomic)			BOOL		unitsInMiles;
@property (nonatomic)			BOOL		sortable;
@property (nonatomic)			BOOL		hasSpatialCategories;
@property (nonatomic)			BOOL		hasPrices;
@property (nonatomic)			BOOL		hasLocations;
@property (nonatomic)			BOOL		showPremiumContent;
@property (nonatomic)			BOOL		mapsNeedUpdating;
@property (nonatomic)			BOOL		hasRichText;
@property (nonatomic)			BOOL		entryCollectionNeedsUpdate;
@property (nonatomic)			BOOL		hasAbstractPrices;
@property (nonatomic)			BOOL		free;
@property (nonatomic)           BOOL        isShellApp;
@property (nonatomic)           BOOL        killDataDownloader;
@property (nonatomic)           BOOL        deviceShowsHighResIcons;
@property (nonatomic)           BOOL        hasDeals;
@property (nonatomic)           BOOL        downloadTestAppContent;
//@property (nonatomic)           BOOL        hasOfflineUpgrade;
@property (nonatomic)           BOOL        showAds;
@property (nonatomic)           BOOL        contentUpdateInProgress;
@property (nonatomic)           BOOL        connectedToInternet;
@property (nonatomic)           BOOL        isFreeSample;


//Formatting Props
@property (nonatomic, strong)	UIColor		*descriptionTextColor;
@property (nonatomic, strong)	UIColor		*navigationBarTint;
@property (nonatomic, strong)	UIColor		*navigationBarTint_entryView;
@property (nonatomic, strong)	UIColor		*LVEntryTitleTextColor;
@property (nonatomic, strong)	UIColor		*LVEntrySubtitleTextColor;
@property (nonatomic, strong)	UIColor		*entryViewBGColor;
@property (nonatomic, strong)	UIColor		*linkColor;
@property (nonatomic, strong)	UIImage		*LVBGView;
@property (nonatomic, strong)	UIImage		*LVBGView_selected;
@property (nonatomic, strong)	UIFont		*subtitleFont;
@property (nonatomic, strong)	UIFont		*bodyFont;
@property (nonatomic, strong)	NSString	*fontName;
@property (nonatomic, strong)	NSString	*cssTextColor;
@property (nonatomic, strong)	NSString	*cssLinkColor;
@property (nonatomic, strong)	NSString	*cssNonactiveLinkColor;
@property (nonatomic, strong)	NSString	*cssExternalLinkColor;
@property (nonatomic)			float		tweenMargin;
@property (nonatomic)			float		tableviewRowHeight;
@property (nonatomic)			float		tableviewRowHeight_libraryView;
@property (nonatomic)			float		screenWidth;
@property (nonatomic)			float		screenHeight;
@property (nonatomic)           float       landscapeSideMargin;
@property (nonatomic)           float       portraitSideMargin;
@property (nonatomic)			float		rightMargin;
@property (nonatomic)			float		leftMargin;
@property (nonatomic)			float		tinyTweenMargin;
@property (nonatomic)			float		bodyTextFontSize;
@property (nonatomic)			float		titleBarHeight;


//AB Testing
@property (nonatomic, strong)   NSString    *browseViewVariation;


@end