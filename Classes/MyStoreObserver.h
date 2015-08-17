//
//  MyStoreObserver.h
//  TravelGuideSF
//
//  Created by Tobin1 on 10/15/09.
//  Copyright 2009 Sutro Media. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>


@interface MyStoreObserver : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>  {
	
    NSMutableArray *products;
   	SKProduct *testForRemoval;
	UIAlertView	*appStoreAlert;
    NSTimer *guideSyncTimer;
    NSMutableArray *guidesToDownload;
    NSMutableArray *pendingTransactions;
    int addRestoredProductsCounter;
    BOOL waitingForProductData;
    BOOL showGuideSyncNotification;
    BOOL acceptedGuideSync;
    
}

@property (nonatomic, strong) NSArray *products;

+ (MyStoreObserver*) sharedMyStoreObserver;
- (SKProduct*) getProductForGuideId:(int) theGuideId;
- (NSString*) getPriceForGuideId:(int) theGuideId;
- (NSString*) getUpgradePrice;
- (void) purchaseGuide:(int) theGuideId;
- (void) provideContent:(int) theGuideId;
- (void) provideSampleContent:(int) theGuideId;
- (void) requestProductData;
- (void) getOfflineContentUpgrade;
- (void) getPreviouslyPurchasedProducts;
- (void) upgradeSamplePurchaseForGuideId:(int) guideId;
- (BOOL) isGuideFreeSample:(int) guideId;
- (NSDictionary*) getGuideStatus: (int) guideId;
- (void) unarchiveGuide: (int) theGuideId;
- (void) deleteOrArchiveGuide: (int) theGuideId;

//- (void) restoreUpgrade;


@end
