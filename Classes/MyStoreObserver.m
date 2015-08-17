//
//  MyStoreObserver.m
//
//  Created by Tobin Fisher on 10/14/09.
//  Copyright 2009 Sutro Media. All rights reserved.
//

#import "MyStoreObserver.h"
#import "Props.h"
#import "Reachability.h"
#import "ActivityLogger.h"
#import "SMLog.h"
#import "Constants.h"
#import "FMDatabase.h"
#import "FMResultSet.h"

//Product types
#define kOfflineContent @"Offline content"
#define kSutroWorldGuide @"Sutro World Guide"
#define kRestoreDownloadsAlert 234534

@interface MyStoreObserver() 
//private method prototypes here
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response;
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;
- (void) completeTransaction: (SKPaymentTransaction *)transaction;
- (void) restoreTransaction: (SKPaymentTransaction *)transaction;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;
- (void) provideContent: (int) theGuideId;
- (void) downloadOfflineContent;
- (NSString*) getProductTypeForProductIdentifier:(NSString*) theProductIdentifier;
- (int) getSutroWorldGuideIdForProductIdentifier:(NSString*) theProductIdentifier;
- (void) upgradeSampleForGuideId:(int) guideId;

@end


@implementation MyStoreObserver

@synthesize products;


- (id) init {
	
    self = [super init];
	if (self) {
	
        products = [NSMutableArray new];
        guideSyncTimer = nil;
        guidesToDownload = nil;
        pendingTransactions = [NSMutableArray new];
        addRestoredProductsCounter = 0;
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        //[self requestProductData];
        
        //[self getPreviouslyPurchasedProducts];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishPendingTransaction:) name:kBillCustomerForCompletedTransaction object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getPreviouslyPurchasedProducts) name:kLookForPreviouslyPurchasedGuides object:nil];
	}
	
	return self;
}


//Check for prior purchases and adds them (in the event they were purchased on a different device or the app is being reinstalled)
- (void) getPreviouslyPurchasedProducts {
    
    NSLog(@"MYSTOREOBSERVER.getPreviouslyPurchasedProducts");
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions]; //Gets call back at -(void) restoreTransaction: (SKPaymentTransaction *)transaction
}


#pragma mark
#pragma mark Information Getters

-(void)requestProductData
{
	NSLog(@"MYSTOREOBSERVER.requestProductData");
	
    waitingForProductData = TRUE;
    
	if ([SKPaymentQueue canMakePayments])
		
	{
        
        if ([Props global].isShellApp) {
            NSMutableArray *inAppPurchaseProducts = [NSMutableArray new];
            
            FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/content.sqlite3", [Props global].cacheFolder]];
            
            if (![db open]) NSLog(@"ERROR: MYSTOREOBSERVER.requestProductData: Can't open content database");
            
            @synchronized ([Props global].dbSync) {
                
                FMResultSet *rs = [db executeQuery: @"SELECT rowid FROM entries"];
                
                while ([rs next]) {
                    
                    NSString *productId = [NSString stringWithFormat:@"SW1_%i", [rs intForColumn:@"rowid"]];
                    
                    [inAppPurchaseProducts addObject:productId];
                    
                }
                [rs close];
            }
            
            //NSArray *inAppPurchaseProducts = [NSArray arrayWithObjects:@"SW1_3", @"SW1_4", nil]; // Identifer set up in iTunes Connect
            
            SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithArray:inAppPurchaseProducts]];  
            
            request.delegate = self;
            
            [request start];
            
            /*
            NSMutableArray *inAppPurchaseProducts2 = [NSMutableArray new];
            
            @synchronized ([Props global].dbSync) {
                
                FMResultSet *rs = [db executeQuery: @"SELECT rowid FROM entries"];
                
                while ([rs next]) {
                    
                    NSString *productId = [NSString stringWithFormat:@"SW2_%i", [rs intForColumn:@"rowid"]];
                    
                    [inAppPurchaseProducts2 addObject:productId];
                    
                }
                [rs close];
            }
            
            
            //NSArray *inAppPurchaseProducts = [NSArray arrayWithObjects:@"SW1_3", @"SW1_4", nil]; // Identifer set up in iTunes Connect
            
            SKProductsRequest *request2= [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithArray:inAppPurchaseProducts2]];
            
            request2.delegate = self;
            
            [request2 start];
             */
            
            [db close];
        }
        
        else if ([Props global].freemiumType != kFreemiumType_Paid) {
            
            NSArray *inAppPurchaseProducts = [NSArray arrayWithObjects:[NSString stringWithFormat:@"OfflineContent%i", [Props global].appID], [NSString stringWithFormat:@"Offline_Content_%i", [Props global].appID], nil]; // Identifer set up in iTunes Connect
            
            SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithArray:inAppPurchaseProducts]];  
            
            request.delegate = self;
            
            [request start]; 
        }
	}
	
	else NSLog(@"***** ERROR -- MYSTOREOBSERVER.requestProductData: NO PAYMENTS ALLOWED ****************************************************");
}


- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    waitingForProductData = FALSE;
    
	NSArray *invalidProducts = response.invalidProductIdentifiers;
	if ([invalidProducts count] > 0){
        NSLog(@"******** WARNING - MYSTOREOBSERVER.productsRequest: %d invalid products ****************************", [invalidProducts count]);
        
        //In some cases, product ids can get "used up" (like if a product is accidentally deleted). We retry with SW2_xx for products that didn't work the first time around.
        NSString *theProduct = [invalidProducts objectAtIndex:0];
        int codeVersion = [[theProduct substringWithRange:NSMakeRange(2, 1)] intValue];
        NSLog(@"MYSTOREOBSERVER.productRequest:didReceiveResponse: Code version = %i", codeVersion);
        
        if (codeVersion == 1) {
            
            NSMutableArray *productsToRetry = [NSMutableArray new];
            
            for (NSString *theProduct in invalidProducts) {
                
                NSRange range = NSMakeRange(4, [theProduct length]-4);
                int guideId = [[theProduct substringWithRange:range] intValue];
                
                NSLog(@"Invalid guide id %i", guideId);
                
                NSString *productId = [NSString stringWithFormat:@"SW2_%i", guideId];
                [productsToRetry addObject:productId];
            }
            
            SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithArray:productsToRetry]];
            
            request.delegate = self;
            
            [request start];
        }
    }
    
    
	@synchronized ([Props global].dbSync) {
		for (SKProduct *product in response.products) {
                [products addObject:product];
		}
	}
	
	//products = response.products;
    
    if ([products count] > 0) [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateBuyButton object:nil];
    
	NSLog(@"MYSTOREOBSERVER.productsRequest: Number of valid products = %i", [products count]);
}


- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    NSLog(@"MYSTOREOBSERVER.request:didFailWithError: %@ *****************************************************************", [error description]);
}


- (NSString*) getPriceForGuideId:(int) theGuideId {
    
    NSString* price = nil;
    
    SKProduct *theProduct = [self getProductForGuideId:theGuideId];
    
    NSLog(@"MYSTOREOBSERVER.getPriceForGuideId: Found %@", theProduct.localizedTitle);
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:theProduct.priceLocale];
    price = [numberFormatter stringFromNumber:theProduct.price];
    
    NSLog(@"MYSTOREOBSERVER.getPriceForGuideId: Price is %@", price);
    
    return price;
}


- (NSString*) getUpgradePrice {
    
    NSString *price = nil;
    
    if ([products count] != 0) {
        SKProduct *theProduct = [products objectAtIndex:0];
        
        NSLog(@"MYSTOREOBSERVER.getUpgradePrice: Found %@", theProduct.localizedTitle);
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:theProduct.priceLocale];
        price = [numberFormatter stringFromNumber:theProduct.price];
        
        NSLog(@"MYSTOREOBSERVER.getUpgradePrice: Price is %@", price);
    }
    
    else {
       NSLog(@"MYSTOREOBSERVER.getUpgradePrice: No product data available");
        if (!waitingForProductData) [self requestProductData];
    }
    
    return price;
}


- (SKProduct*) getProductForGuideId:(int) theGuideId {
    
    NSLog(@"MYSTOREOBSERVER.getProductForGuideId: %i", theGuideId);
    
    SKProduct *theProduct = nil;
    
    if([products count] > 0) {
		
		for (SKProduct *aProduct in products) {
            
            if ([aProduct.productIdentifier isEqualToString:[NSString stringWithFormat:@"SW1_%i", theGuideId]]){
				theProduct = aProduct;
				break;
			}
			
			else if ([aProduct.productIdentifier isEqualToString:[NSString stringWithFormat:@"SW2_%i", theGuideId]]){
				theProduct = aProduct;
				break;
			}
        }
    }
    
    else if (!waitingForProductData) [self requestProductData];
        
    return theProduct;
}


- (BOOL) isGuideFreeSample:(int)guideId {
	
	//Figure out if the guide is a sample
	
	BOOL isFreeSample = FALSE;
	
	FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder]];
	if (![db open]) NSLog(@"ERROR: PROPS.setupPropsDict: Can't open purchased guides database *************************************");
	
	@synchronized ([Props global].dbSync) {
		
		NSString *query = [NSString stringWithFormat:@"SELECT is_sample FROM guides WHERE guideid = %i", guideId];
		
		FMResultSet *rs = [db executeQuery:query];
		
		if ([rs next])isFreeSample = [rs intForColumn:@"is_sample"] == 1 ? TRUE : FALSE;
			
		[rs close];
	}
	
	[db close];

	return isFreeSample;
}


- (NSDictionary*) getGuideStatus: (int) guideId {
	
	NSMutableDictionary *guideStatus = [NSMutableDictionary new];
	
	FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder]];
	if (![db open]) NSLog(@"ERROR: PROPS.setupPropsDict: Can't open purchased guides database *************************************");
	
	@synchronized ([Props global].dbSync) {
		
		NSString *query = [NSString stringWithFormat:@"SELECT is_sample, archived FROM guides WHERE guideid = %i", guideId];
		
        NSLog(@"MSO.getGuideStatus: Query = %@", query);
        
		FMResultSet *rs = [db executeQuery:query];
		
		if ([rs next]){
			
			[guideStatus setObject:[NSNumber numberWithInt:[rs intForColumn:@"is_sample"]] forKey:@"is_sample"];
			[guideStatus setObject:[NSNumber numberWithInt:[rs intForColumn:@"archived"]] forKey:@"archived"];
		}
		
		[rs close];
	}
	
	[db close];
    
    NSLog(@"Guide status count = %i", [guideStatus count]);
	
	if ([guideStatus count] == 0) guideStatus = nil;
	
	return guideStatus;
}


#pragma mark
#pragma mark Methods to talk with Apple and do the purchase transaction

//***************** Initiate the payment transaction ******************
- (void) purchaseGuide:(int)theGuideId {
    
    NSLog(@"MYSTOREOBSERVER.downloadGuide: Guide Id = %i", theGuideId);
    
    if([[Reachability sharedReachability] internetConnectionStatus] != NotReachable) {
        
		if ([Props global].deviceType == kSimulator) {
            
            [self provideContent:theGuideId];
            [[NSNotificationCenter defaultCenter] postNotificationName:kGoHome object:nil];
        }
		
        else if (([SKPaymentQueue canMakePayments])){

			SKMutablePayment *payment = [SKMutablePayment paymentWithProduct: [self getProductForGuideId:theGuideId]];
            
			[[SKPaymentQueue defaultQueue] addPayment:payment];
		}
        
        else NSLog(@"*** ERROR - MYSTOREOBSERVER.downloadGuide: PAYMENTS NOT ALLOWED **************************************");
	}
	
	//Show error if no internet connection is available
	else {
		
        UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle :@"No internet connection available"
																message: @"You'll need a data connection to make this purchase. Give it another shot when you're back on the grid."
															  delegate : self cancelButtonTitle:@"OK"otherButtonTitles:nil];
		[failureAlert show];
	}
}


- (void) upgradeSamplePurchaseForGuideId:(int) theGuideId {
    
    NSLog(@"MYSTOREOBSERVER.upgradeSamplePurchaseForGuideId: %i", theGuideId);
    
    if([[Reachability sharedReachability] internetConnectionStatus] != NotReachable) {
        
        if ([Props global].deviceType == kSimulator) {
            
            [self upgradeSampleForGuideId:theGuideId];
        }
        
        else if (([SKPaymentQueue canMakePayments])){
            
            SKProduct *product = [self getProductForGuideId:theGuideId];
            
            if (product != nil) {
                SKMutablePayment *payment = [SKMutablePayment paymentWithProduct: product];
                
                [[SKPaymentQueue defaultQueue] addPayment:payment];
            }
            
            else {
                
                NSString *key = [NSString stringWithFormat:@"%@_%i", kTransactionFailed, theGuideId];
                [[NSNotificationCenter defaultCenter] postNotificationName:key object: self];
                
                UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle :@"Cannot connect with App Store"
                                                                        message: @"Something seems to be going wrong with the App Store. Give it another shot in a few minutes. Sorry for the wait!"
                                                                      delegate : self cancelButtonTitle:@"OK"otherButtonTitles:nil];
                [failureAlert show];
            }
		}
        
        else NSLog(@"*** ERROR - MYSTOREOBSERVER.downloadGuide: PAYMENTS NOT ALLOWED **************************************");
	}
	
	//Show error if no internet connection is available
	else {
		
        UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle :@"No internet connection available"
																message: @"You'll need a data connection to make this purchase. Give it another shot when you're back on the grid."
															  delegate : self cancelButtonTitle:@"OK"otherButtonTitles:nil];
		[failureAlert show];
	}
}


- (void) getOfflineContentUpgrade {
    
    NSLog(@"MYSTOREOBSERVER.getOfflineContentUpgrade");
    
    if([[Reachability sharedReachability] internetConnectionStatus] != NotReachable) {
        
        if ([Props global].deviceType == kSimulator){
			[self downloadOfflineContent];
		}
        
		else if ([SKPaymentQueue canMakePayments] && [products count] != 0){ 
            
            SKProduct *product = [products objectAtIndex:0];
            
            NSLog(@"MYSTOREOBSERVER.getOfflineContentUpgrade: product = %@", product.productIdentifier);

			SKMutablePayment *payment = [SKMutablePayment paymentWithProduct: product];
            
			[[SKPaymentQueue defaultQueue] addPayment:payment];
		}
        
        else NSLog(@"*** ERROR - MYSTOREOBSERVER.downloadGuide: PAYMENTS NOT ALLOWED **************************************");
	}
	
	//Show error if no internet connection is available
	else {
		
        UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle :@"No internet connection available"
																message: @"You'll need a data connection to make this purchase. Give it another shot when you're back on the grid."
															  delegate : self cancelButtonTitle:@"OK"otherButtonTitles:nil];
		[failureAlert show];
	}
}


//************************** Listen for responses from Apple after initiating a purchase transation ********************

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    NSLog(@"MYSTOREOBSERVER.paymentQueue: updatedTransactions");
	
	for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                //[[NSNotificationCenter defaultCenter] postNotificationName:kTransactionInitiated object: nil];
                break;
                
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                
            default:
                break;
        }
    }
}


//We know here that the customer can be billed, but we don't actually get $$ until finishTransaction is called

- (void) completeTransaction: (SKPaymentTransaction *)transaction {
    
    NSString *productType = [self getProductTypeForProductIdentifier:transaction.payment.productIdentifier];
    
    if ([productType  isEqual: kOfflineContent]){
        
        [self downloadOfflineContent];
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }
    
    else if ([productType  isEqual: kSutroWorldGuide]) {
        
        int guideId = [self getSutroWorldGuideIdForProductIdentifier:transaction.payment.productIdentifier];
        
        if ([self isGuideFreeSample:guideId]) {
            [self upgradeSampleForGuideId:guideId];
        }
        
        else {
            SMLog *log = [[SMLog alloc] initWithPageID: kInAppPurchase actionID: kPurchaseSuccess];
            log.entry_id = guideId;
            log.note = [NSString stringWithFormat:@"%@", transaction.transactionIdentifier];
            [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
            
            [self provideContent:guideId];
            
            //We don't actually complete the transaction until the content is ready to view
            [pendingTransactions addObject:transaction];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kGoHome object:nil];

        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransactionComplete object:self];
}


- (void) restoreTransaction: (SKPaymentTransaction *)transaction {
    
    NSLog(@"MYSTOREOBSERVER.restoreTransaction: transaction identifier = %@", transaction.payment.productIdentifier);
    
    if ([[self getProductTypeForProductIdentifier:transaction.payment.productIdentifier]  isEqual: kSutroWorldGuide]) {
        
        int guideId = [self getSutroWorldGuideIdForProductIdentifier:transaction.payment.productIdentifier];
        
        if (guidesToDownload == nil) guidesToDownload = [NSMutableArray new];  
        
        FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder]];
        if (![db open]) NSLog(@"ERROR: LIBRARYHOME.checkForUpdates: Can't open purchased guides database *************************************");
        
        @synchronized ([Props global].dbSync) {
            
            NSString *query = [NSString stringWithFormat:@"SELECT * FROM guides WHERE guideid = %i", guideId];
            
            FMResultSet *rs = [db executeQuery:query];
            
            if (![rs next]) {
                NSLog(@"MYSTOREOBSERVER.restoreTransaction: Missing product id = %i", guideId);
                
                
                [guidesToDownload addObject:[NSNumber numberWithInt:guideId]];
                
                [pendingTransactions addObject:transaction]; //make sure we get paid in the event that the app quit before a transaction completed
                
                if (guideSyncTimer == nil) {
                    guideSyncTimer =  [NSTimer scheduledTimerWithTimeInterval: 1 target:self selector:@selector(addRestoredProducts) userInfo:nil repeats:YES];
                }
            }
            
            [rs close];
        }
        
        [db close];
        
    }
    
    else [self completeTransaction:transaction];
}


- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {

	NSLog(@"PaymentQueue restoreCompletedTransactionsFailedWithError called");
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransactionFailed object: self];
	
}


- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {

	for (SKPaymentTransaction *transaction in transactions){
        NSLog(@"MYSTOREOBSERVER.paymentQueue: Transaction removed for %@", transaction.payment.productIdentifier);
    }
}


// The way we handle failed transactions could probably use some work

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
	NSLog(@"MYSTOREOBSERVER.failedTransaction: Failed for %@", transaction.payment.productIdentifier);
	[[NSNotificationCenter defaultCenter] postNotificationName:kTransactionFailed object: self];
	
    
    //Identifier is SWx_y
    NSLog(@"Identifier = %@ and length = %i", transaction.payment.productIdentifier, [transaction.payment.productIdentifier length]);
    NSRange range = NSMakeRange(4, [transaction.payment.productIdentifier length]-4);
    int guideId = [[transaction.payment.productIdentifier substringWithRange:range] intValue];
	
	NSString *key = [NSString stringWithFormat:@"%@_%i", kTransactionFailed, guideId];
	[[NSNotificationCenter defaultCenter] postNotificationName:key object: self];
    
    SMLog *log = [[SMLog alloc] initWithPageID: kInAppPurchase actionID: kPurchaseError];
    log.entry_id = guideId;
    log.note = [NSString stringWithFormat:@"Error: %@", [transaction.error localizedDescription]];
    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
    
	
	if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Unknown Error (%d), product: %@", (int)transaction.error.code, transaction.payment.productIdentifier);
        UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle :@"In-App-Purchase Error:"
                                                                message: [transaction.error localizedDescription]
                                                              delegate : self cancelButtonTitle:@"OK"otherButtonTitles:nil];
        [failureAlert show];
		
        
    }
    
    //Save transaction to disk to finish once content has been successfully delivered
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) finishPendingTransaction:(NSNotification*) theNotification {
    
    int guideID = [theNotification.object intValue];
    
    for (SKPaymentTransaction *transaction in pendingTransactions) {
        if ([self getSutroWorldGuideIdForProductIdentifier:transaction.payment.productIdentifier] == guideID) {
            
            NSLog(@"MYSTOREOBSERVER.finishPendingTransaction: Finishing transaction for guide id = %i", guideID);
            [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        }
    }
}


# pragma mark
# pragma mark Provide content after a successful purchase

- (void) downloadOfflineContent {
    
    NSLog(@"MYSTOREOBSERVER.downloadOfflineContent");
    [Props global].showAds = FALSE;
	[Props global].freemiumType = kFreemiumType_Paid;
    [[NSUserDefaults standardUserDefaults] setInteger:kFreemiumType_Paid forKey:kFreemiumType];
    [[NSNotificationCenter defaultCenter] postNotificationName: kFreemiumUpgradePurchased object:nil]; 
}


- (void) provideContent:(int) theGuideId {
    
    NSLog(@"MYSTOREOBSERVER.provideContent: Guide Id = %i", theGuideId);
	
	if ([self isGuideFreeSample:theGuideId]) {
        
        [self upgradeSampleForGuideId:theGuideId];
		
		/*FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder]];
		
		if (![db open]) NSLog(@"ERROR: MYSTOREOBSERVER.provideContent: Can't open purchased guides database");
		
		@synchronized ([Props global].dbSync) {
			
			[db executeUpdate:@"BEGIN TRANSACTION"];
			[db executeUpdate:[NSString stringWithFormat:@"UPDATE guides SET is_sample = 1 WHERE guideid = %i", theGuideId]];
			[db executeUpdate:@"END TRANSACTION"];
		}
		
		[db close];*/
	}
    
	else {
	
		FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder]];
		
		if (![db open]) NSLog(@"ERROR: MYSTOREOBSERVER.provideContent: Can't open purchased guides database");
		
		@synchronized ([Props global].dbSync) {
			
			[db executeUpdate:@"BEGIN TRANSACTION"];
			[db executeUpdate:[NSString stringWithFormat:@"INSERT OR IGNORE INTO guides (guideid, purchase_date,archived,is_sample) VALUES (%i, datetime('now', 'localtime'),0,0)", theGuideId]];
			[db executeUpdate:@"END TRANSACTION"];
		}
		
		[db close];
	}
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:kGoHome object:nil];
}

- (void) unarchiveGuide: (int) theGuideId {
	
	FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder]];
    
    if (![db open]) NSLog(@"ERROR: MYSTOREOBSERVER.provideContent: Can't open purchased guides database");
    
    @synchronized ([Props global].dbSync) {
        
        [db executeUpdate:@"BEGIN TRANSACTION"];
        [db executeUpdate:[NSString stringWithFormat:@"UPDATE guides SET archived = 0 WHERE guideid = %i", theGuideId]];
        [db executeUpdate:@"END TRANSACTION"];
    }
    
    [db close];
}


- (void) provideSampleContent:(int) theGuideId {
    
    NSLog(@"MYSTOREOBSERVER.provideContent: Guide Id = %i", theGuideId);
    
    FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder]];
    
    if (![db open]) NSLog(@"ERROR: MYSTOREOBSERVER.provideContent: Can't open purchased guides database");
    
    @synchronized ([Props global].dbSync) {
        
        [db executeUpdate:@"BEGIN TRANSACTION"];
        [db executeUpdate:[NSString stringWithFormat:@"INSERT OR IGNORE INTO guides (guideid, purchase_date,archived,is_sample) VALUES (%i, datetime('now', 'localtime'),0,1)", theGuideId]];
        [db executeUpdate:@"END TRANSACTION"];
    }
    
    [db close];
}


- (void) upgradeSampleForGuideId:(int) theGuideId {
    
    NSLog(@"MYSTOREOBSERVER.upgradeSampleForGuideId: %i", theGuideId);
	
	FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder]];
    if (![db open]) NSLog(@"ERROR: LIBRARYHOME.checkForUpdates: Can't open purchased guides database *************************************");
	
    @synchronized ([Props global].dbSync) {
		
		NSString *query = [NSString stringWithFormat:@"UPDATE guides SET is_sample = 0 WHERE guideid = %i", theGuideId];
		
		[db executeUpdate:@"BEGIN TRANSACTION"];
		[db executeUpdate:query];
        [db executeUpdate:@"END TRANSACTION"];
	}
    
    [db close];
    
	NSString *samplePurchasedNotification = [NSString stringWithFormat:@"%@_%i", kSampleGuidePurchased, theGuideId];
    [[NSNotificationCenter defaultCenter] postNotificationName:samplePurchasedNotification object:nil];
}


- (void) addRestoredProducts {
    
    if ([guidesToDownload count] > 0) {
        
        @synchronized ([Props global].dbSync) {
            
            for (NSNumber *guideId in guidesToDownload) {
                [self provideContent:[guideId intValue]];
            }
            
            [guidesToDownload removeAllObjects];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kRefreshLibraryHome object:nil];
        
        addRestoredProductsCounter = 0;
    }
    
    else addRestoredProductsCounter ++;
    
    //In the event that we've been check for restored products for over 60 seconds and there are still none to add, call it quits
    if (addRestoredProductsCounter > 60) {
        [guideSyncTimer invalidate];
        guideSyncTimer = nil;
    }
}


-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
    
    if (theAlert.tag == kRestoreDownloadsAlert && buttonIndex != 0) acceptedGuideSync = TRUE;

    else [[NSNotificationCenter defaultCenter] postNotificationName:kTransactionFailed object: nil];
}


- (void) deleteOrArchiveGuide: (int) theGuideId {
    
    FMDatabase *db = [[FMDatabase alloc] initWithPath:[NSString stringWithFormat:@"%@/purchased_guides.sqlite3", [Props global].documentsFolder]];
    if (![db open]) NSLog(@"ERROR: LIBRARYHOME.checkForUpdates: Can't open purchased guides database *************************************");
    
	BOOL isSample = FALSE;
	//Figure out if the guide is a sample or a purchased guide
	@synchronized ([Props global].dbSync) {
		
		NSString *query = [NSString stringWithFormat:@"SELECT is_sample FROM guides WHERE guideid = %i", theGuideId];
        
		FMResultSet *rs = [db executeQuery:query];
        
		if ([rs next]) isSample = [rs intForColumn:@"is_sample"] == 1 ? TRUE : FALSE;
        
        [rs close];
	}
	
	
	//Remove from database or mark it as archived
	
    @synchronized ([Props global].dbSync) {
		
		NSString *query = isSample ? [NSString stringWithFormat:@"DELETE FROM guides WHERE guideid = %i", theGuideId] : [NSString stringWithFormat:@"UPDATE guides SET archived = 1 WHERE guideid = %i", theGuideId];
		
		NSLog(@"GUIDEDOWNLOADER.deleteGuide: Query = %@", query);
		
		[db executeUpdate:@"BEGIN TRANSACTION"];
		[db executeUpdate:query];
        [db executeUpdate:@"END TRANSACTION"];
	}
    
    [db close];
}

# pragma mark
# pragma mark Helper Methods

- (int) getSutroWorldGuideIdForProductIdentifier:(NSString*) theProductIdentifier {
    
    //Identifier is SWx_y
    
    if ([theProductIdentifier length] > 5) {
        //NSLog(@"Identifier = %@ and length = %i", theProductIdentifier, [theProductIdentifier length]);
        NSRange range = NSMakeRange(4, [theProductIdentifier length] - 4);
        NSString *guideId = [theProductIdentifier substringWithRange:range];
        
        return [guideId intValue];
    }
    
    else {
        
        NSLog(@"************* ERROR: MYSTOREOBSERVER.getSutroWorldGuideIdForProductIdentifier: fails for %@", theProductIdentifier);
        return 0;
        
    }
}


- (NSString*) getProductTypeForProductIdentifier:(NSString*) theProductIdentifier {
    
    if (([theProductIdentifier length] > 15 && [[theProductIdentifier substringToIndex:15] isEqualToString:@"Offline_Content"]) || ([theProductIdentifier length] > 14 && [[theProductIdentifier substringToIndex:14] isEqualToString:@"OfflineContent"])) {
        
        return kOfflineContent;
    }
    
    else return kSutroWorldGuide; //Should do some confirmation checks here for unexpected third alternatives
}



# pragma mark
# pragma mark Singleton Stuff

+ (MyStoreObserver*)sharedMyStoreObserver {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

@end