//File: Constants.h
//Abstract: Common constants across source files (screen coordinate consts, etc.)


//********* GLOBAL SIZES ****************

// screen dimensions and key coordinates
#define kTitleBarHeight			44
#define kContentYPosition		0
#define kIntroImageHeight		170
#define	kTabBarHeight			50
#define kPartialHideTabBarHeight 13

// padding for margins
#define	kInnerVerticalMargin	7
#define kFilterButtonXPos		20
#define kBottomMargin			10
#define kTopMargin				10

// control dimensions
#define kToolbarHeight			40
#define kToolbarFrameHeight		0
#define kButtonHeight			30
#define kMapHeight				120
#define kCustomButtonHeight		30
#define	kIconWidth				41
#define kTextLeftSide			[Props global].leftMargin + kIconWidth + kInnerVerticalMargin
#define kTextBoxWidth			[Props global].screenWidth - (kTextLeftSide + [Props global].rightMargin) //extra bit to avoid having text run into close button
#define kPickerBorderSize		0

// UITableView row heights
#define kUIRowHeight			50
#define kUIRowLabelHeight		22

// table view cell content offsets
#define kCellLeftOffset			8
#define kCellTopOffset			12

#define kTopScrollGraphicHeight	45

#define kSearchBarHeight    45


//**** Other Global Graphical Parameters *****
//Colors
#define kHyperlinkRed			0.21
#define kHyperlinkGreen			0.47
#define kHyperlinkBlue			0.70

// specific font metrics used in our text fields and text views
#define kFontName				@"Arial"


//**********GLOBAL MATHEMATICAL CONSTANTS******

#define kPI                     3.14159265

//********** GLOBAL KEYS *********************
// Global Map Variables
#define kUserLocation			-9078912
#define kDestination			-1234808
#define kUserLocationBackground	-1234131
#define kUserLocationZPos		-10
#define kUserLocationBackZPos	-11
#define kDestinationZPos		-20
#define kEntryMarkerZPos		-30
#define kSelectedEntryMarkerZPos	0
#define kUserLocationMarkerWidth 16
#define kUserLocationBackgroundWidth 48
#define kDownloadStatusHidden	@"Download status hidden"

//Global View tags
#define kCallTaxiTag			-8143087
#define kCallTaxiAlertTag		-9871234
#define kGetDirectionsTag		-5385642
#define kNextPageViewTag		-34252987
#define kOfflineUpgradePitchTag 84849848
#define kAdViewTag              4024939
#define kSlideshowUpgradeViewTag    3459087

#define kPlayButtonPressed		@"PlayButtonPressed"
#define kFilterButtonPressed	@"FilterButtonPressed"


#define kSearchCellID			-666666

#define kValueNotSet			-666
#define kStringNotSet			@"Not set"

// transition destinations
#define kTestAppLogin			@"Test app login"
#define kTestApp				@"Test app"
#define kSutroWorld				@"Sutro world"
#define kOriginalApp			@"Original App"

#define kTransitionDuration		1.00

#define kTravelDistanceFactor	1.200
#define kOverlayAlpha			.8
#define kProgressIndicatorSize	60
#define kFeedbackButtonYPosition 330

#define kSortByName				@"Name"
#define kSortByDistance			@"Distance"
#define kSortByCost				@"Cost"
#define kSortByDate				@"Date"
#define	kSortBySpatialCategory	@"Neighborhood"
#define kSortByPopularity       @"Popularity"

#define kFavorites              @"Favorites"

#define kNoSorter				0
#define kPlaceSorter			1
#define kEventSorter			2
#define kPicker					3
#define kSegmentAndPicker		4
#define kBigPicker				5
#define kLeftAndRightPicker		6

#define kDistanceCellType		1
#define kNameCellType			2
#define	kCostCellType			3
#define	kLocationCellType		4
#define	kSpatialCategoryCellType	5

#define kUpgradeView			-2

//User default access keys
#define kCurrentMapContentSize @"Current map content size"


// NOTIFICATION KEYS
#define kTransactionInitiated   @"transaction initiated"
#define	kTransactionComplete	@"transactionComplete"
#define kTransactionFailed		@"transactionFailed"
#define kImageDownloaded		@"imageDownloaded"
#define	kShowTestApp			@"Show test app"
#define kFlipWorlds				@"Flip worlds"
#define kOrientationChange      @"Orientation change"
#define kGoHome                 @"Go Home"
#define kUpdateDownloadProgress @"Update download progress"
#define kUpdateOfflineContentDownloadProgress @"Update offline content download progress"
#define kPurchasedGuides        @"Purchased Guides"
#define kPauseGuideDownload     @"Pause guide download"
#define kResumeGuideDownload    @"Resume guide download"
#define kWaitGuideDownload      @"Wait guide download"
#define kUnwaitGuideDownload    @"Unwait guide download"
#define kUpdateWaitStatuses     @"Update wait statuses"
#define kDownloadStatusKey      @"Download status"
#define kSuccessfulDownload      @"Successful download"
#define kSetGuideDownloadToFast @"Set guide to fast"
#define kSetGuideDownloadToSlow @"Set guide to slow"
#define kPauseStatusKey         @"pause status key"
#define kUpdateBuyButton        @"Update buy button"
#define kDownloadHigherResolutionImage @"Download higher resolution image"
#define kHigherQualityImageDownloaded   @"Higher quality image downloaded"
#define kDownloadOfflineImages  @"Download offline images"
#define kRemoveOfflineImages    @"Remove offline images"
#define kStopDownloadingOfflineImages   @"Stop downloading offline images"
#define kUpgradeToOffline       @"Upgrade to offline"
#define kOfflineUpgradePurchased @"Offline upgrade purchased" //Phasing this variable out with kFreemiumType
#define kSampleGuidePurchased   @"Sample guide purchased"
#define kDownloadProblems       @"Having problems downloading"
#define kFreemiumUpgradePurchased @"Freemium upgrade purchased"

#define kOfflineMaps            @"Offline maps"
#define kOfflineMaps_Current_ContentSize @"Offline maps current content size"
#define kOfflineMaps_Max_ContentSize    @"Offline maps max content size"

#define kOfflinePhotos          @"Offline photos"
#define kOfflineFiles           @"Offline files"
#define kShowUpgrade            @"Show upgrade"
#define kShowLocation           @"Show location"
#define kLocationUpdated        @"Location updated"
#define kDistanceSortAdded      @"Distance sort added"
#define kRefreshComments        @"Refresh comments"
#define kEnteringTestApp        @"Entering test app"
#define kRedownloadGuide        @"Redownload guide"
#define kShowFilter             @"Show filter"
#define kShowSettings           @"Show settings"
#define kShowMapAnnotation      @"Show map annotation"
#define kRemoveMapAnnotations   @"Remove map annotations"
#define kEntriesRefreshed       @"Entries refreshed"
#define kRefreshLibraryHome     @"Refresh library home"
#define kLookForPreviouslyPurchasedGuides @"Look for previously purchased guides"
#define kBillCustomerForCompletedTransaction @"Bill customer for completed transaction"
#define kContentUpdated         @"Content updated"
#define kMapMarkersLoaded       @"Map markers loaded"
#define kContentDownloaded      @"Content downloaded"

#define kDeleteGuide            @"Delete guide" //Used for deleting or archiving guides in Sutro World

//Notification keys for intro tutorial
#define kExploreGuidesNotification  @"Explore guides"
//#define kCatalogLoadedNotification  @"Catalog loaded"
#define kGoToMapsNotification       @"Go to maps"
#define kMapLoadedNotification      @"Map loaded"

//Guide download statuses
#define kDownloadNotStarted     0
#define kDownloadInProgress     1
#define kReadyForViewing        2
#define kDownloadingImages      3
#define kDownloadComplete       4

//Guide download tasks
#define kGettingDatabase        @"Getting guide data"
#define kDownloadingIcons       @"Downloading photos"
#define kDownloadingMaps        @"Downloading maps"
#define kDownloadingOfflineFiles @"Downloading offline files"
#define kGetThumbnails          @"Downloading thumbnails"
#define kDownloadImages         @"Downloading photos"
#define kDownloadEntryPhotos @"Download entry photos"

#define kMaxConcurrentRequests  4

//Saving state in SW
#define kLastSort               @"last sort"
#define kLastFilter             @"last filter"


//Average File sizes
#define kAverageiPhoneImageSize 0.080 //average size in MB for 480 px images
#define kAverageiPadImageSize 0.134 
#define kAverageMapTileSize 0.006  // Average of .008, 0.009, 0.0036, 0.0049 - reasonable amount of variation here
#define kAverageThumbnailSize 0.004
#define kAverageOfflineLinkFileSize 0.42 //average size of offline files for VLVB and Berlin

/*
#define kDownloadNotStarted     @"Download not started"
#define kPartialDownload        @"Partial download"
#define kReadyForViewing        @"Ready for viewing"
#define kDownloadComplete       @"Download complete"*/


#define kiPhone					1
#define kSimulator				2
#define kiPodTouch				3
#define kiPad					4


//User default keys
#define kBundleVersionKey		@"BundleVersionKey"
#define kShouldQuit				@"Should quit"
#define kThumbnailsDownloaded   @"Thumbnails downloaded"
#define kSampleEntryList       @"Sample entry list"
#define kInitialDownloadPrice   @"Initial download price"

#define kNoDistance				66666

//keys for icon flipping for scrolling transition between entries
#define kTopScrollIcon			@"Top scroll icon"
#define kBottomScrollIcon		@"Bottom scroll icon"
#define kFlipUpright			@"Flip upright"
#define kFlipUpsidedown			@"Flip upsidedown"

//SF coords
#define kSanFranLatitude		37.760966
#define kSanFranLongitude		-122.45
//#define kLatitudeDelta            0.107
//#define kLongitudeDelta            0.11

#define kHideLoadingView        @"Hide loading view"


// ** Map Types **

#define kMapView			0
#define kHybridView			1
#define kSatelliteView		2

// ** Cell variations **
#define kTaglineOnlyWithCost        @"Tagline with cost"
#define kTaglineAndDescription      @"Tagline and description"


// Freemium upgrade types
#define kFreemiumType			@"Freemium type" //Key to access which type of freemium upgrade this is
#define kFreemiumType_NotSet	0
#define kFreemiumType_Paid		1 //Either a paid download or an upgraded freemium user
#define kFreemiumType_V1		2 //First offline upgrade type
#define kFreemiumType_V2		3 //Try some set of free entries upgrade type


// ******* Analytics IDs **********

// PageIDs
#define kStartup			10
#define kTLLV				11
#define kTLSS				12
#define kTLMV				13
#define kTLCV				22
#define kTLDV				23
#define kEntryIntroView		14
#define kEntrySlideShow		15
#define kEntryMapView		16
#define kCommentsView		17
#define kEntryWebView		18
#define kError				19
#define kDebug				20
#define kInAppPurchase      21
#define kUpgradePopup       22
#define kReviewPopup        23
#define kShutdown			99

//Actions
#define kStarting			100
#define kTerminating		101

// List View
#define kLVGoToEntry		111
#define kLVSortByDistance	112
#define	kLVSortByCost		113
#define	kLVSortBySpatial	114
#define kLVSortByName		115
#define kLVFilter			116
#define kLVViewSelected		117
#define kLVEnterSutroWorld	118
#define kLVLeaveSutroWorld	119
#define kLVLeaveTestApp		1110
#define kLVSearch			1111
#define kLVSWDownload       1112
#define kLVOfflineUpgradePurchased  1113
#define kLVOfflineUpgradePressed    1114


// TLSS
#define kSSGoToEntry		121
#define kSSFilter			122
#define kSSNextImage		123
#define kSSPreviousImage	124
#define kSSViewSelected		125
#define kSSPause			126
#define kSSPlay				127
#define kSSShareImage		128
#define kSSHyperlink		129

// TLMV
#define kMVGoToEntry		131
#define kMVFilter			132
#define kMVViewSelected		133

//TLCV
#define kCVGoToEntry		181
#define kCVViewSelected		183
#define kCVReviewButtonClicked_No  184
#define kCVReviewButtonClicked_Yes 185


//TLDV
#define kGetDeal            230



//Entry Intro View
#define kIVGoToSlideshow	141
#define kIVGoToMapView		142
#define kIVGoToWebPage		143
#define kIVPhoneCall		144
#define kIVMakeFavorite		145
#define kIVComment			146
#define kIVGoToAppStore		147
#define kIVDontGoToAppStore	148
#define kIVScrollToNextEntry		149
#define kIVScrollToPreviousEntry	1410
#define kIVTagClicked		1411
#define kIVSwipeOut			1412
#define kIVSwipeToPhotos	1413
#define kIVRemoveFromFavorites		1414
#define kIVErrorGoingToAppStore		1415
#define kIVShareEntry		1416
#define kIVGoToComments		1417
#define kIVGoToOfflineContent	1418
#define kHotelAdClicked     1419
#define kHotelAdShown       1420

//Entry slide show
#define kESSNextSlide		151
#define kESSPreviousSlide	152
#define kESSHyperlink		153
#define kESSShareImage		154

//Entry Map View
#define kEMVCallTaxi		161
#define kEMVHideActionView	162
#define kEMVShowActionView	163
#define kEMVCenterMap		164

//Entry Comments View
#define kLeaveComment		171

//Errors
#define kLowMemory			191
#define kFavoritesMissing	192
#define kImageMissing       193
#define kMapTileMissing     194
#define kDownloadFailure    195
#define kDownloadRecovery   196

//Debug notes
#define kMapDebug			201

//In App Purchase
#define kPurchaseSuccess    211
#define kTestPurchaseStart  212 
#define kPurchaseStart      213
#define kNoPriceNoInternet  214
#define kNoPrice            215
#define kDownloadSuccess    216
#define kPurchaseError      217
#define kAdClicked          218
#define kDownload_Initiated  219
#define kDownload_ContentSourceSet  2110    //Changed from 220 052212
#define kDownload_DatabasesDownloaded 2111 //Changed from 221 052212
#define kDownload_ContentSizeSet      2112 //Changed from 222 052212
#define kDownloadStep3      2113 //Changed from 223 052212

//Review popup
#define kReviewFromPopup    221

//Upgrade popup
#define kUpgradeFromPopup   231





