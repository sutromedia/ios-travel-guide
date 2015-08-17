
//
//  
//
//  Created by Tobin1 on 2/24/09.
//  Copyright 2009 Ard ica Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@class Entry;

@interface WebViewController : UIViewController <UIWebViewDelegate, UIGestureRecognizerDelegate> {

	UIWebView				*myWebView;
	UIActivityIndicatorView	*progressInd;
	UILabel					*loadingTag;
	NetworkStatus			internetConnectionStatus;
	Entry					*entry;
    UILabel                 *errorLabel;
    NSURL                   *appURL;
    UIAlertView             *appStoreAlert;
    int                     targetAppID;
		
}

//@property (nonatomic,retain)	UIWebView	*myWebView;
//@property					NetworkStatus	internetConnectionStatus;
//@property (nonatomic, retain)	Entry		*entry;


- (id)initWithEntry:(Entry*) theEntry andURLToLoad:(NSURL*) theURL;

@end