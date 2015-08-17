//
//  CommentsViewController.h
//  TheProject
//
//  Created by Tobin1 on 3/31/10.
//  Copyright 2010 Sutro Media. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <iAD/iAD.h>

@class FilterButton, Entry;

@interface CommentsViewController : UIViewController <UIWebViewDelegate, ADBannerViewDelegate, UIGestureRecognizerDelegate> {

    UIWebView           *commentViewer;
    FilterButton		*pickerSelectButton;
    NSString            *filterCriteria;
    NSString            *lastFilterChoice;
	Entry				*entry;	
	NSMutableArray		*commentsArray;
	UIAlertView			*iTunesAlert;
	//UITableView			*tableView;
    BOOL                visible;
    BOOL                commentsLoaded;
}


//@property (nonatomic,retain) CommentsDatasource* dataSource;
@property (nonatomic, strong) Entry* entry;

@property (nonatomic, strong) ADBannerView *adView;
@property (nonatomic) BOOL adBannerIsVisible; 

- (id) initWithEntry:(Entry*) theEntry;


@end
