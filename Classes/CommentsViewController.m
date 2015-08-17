//
//  CommentsViewController.m
//  TheProject
//
//  Created by Tobin1 on 3/31/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import "CommentsViewController.h"
#import "Comment.h"
#import "CommentPageView.h"
#import "LocationViewController.h"
#import "Entry.h"
#import "Constants.h"
#import "ActivityLogger.h"
#import	"EntryCollection.h"
#import "Props.h"
#import "Reachability.h"
#import "FilterButton.h"
#import "FilterPicker.h"
#import "SMLog.h"
#import <QuartzCore/QuartzCore.h>
#import "WebViewController.h"

#define kNoInternetViewTag 923458
#define kBeTheFirstViewTag 8762498
#define kProgressIndTag 9087234


@interface CommentsViewController (Private)

- (void) refreshComments;
- (void) addCommentButton;
- (void) addReviewButton;
- (void) updateCommentsDatabase;
- (void) showBeTheFirstMessage;
- (void) showNoInternetMessage;
- (void)goToExternalWebPageWithURL:(NSURL*) webPageURL;
- (void) addTitleLabel;
- (int) countComments;
- (void) loadViewContents;
- (NSString*) generateHTML;
- (void) goToEntry: (NSNumber*) theEntryId; 

- (void)fixupAdViewWithAnimation:(BOOL) shouldAnimate;
- (void)createAdBannerView;
- (void) hideAdBannerWithAnimation:(BOOL) shouldAnimate;

@end

@implementation CommentsViewController

@synthesize entry;

//iAd Synthesizes
@synthesize adView, adBannerIsVisible;

- (id) init  {
	self = [super init];
    if (self) {
		
		self.tabBarItem.image = [UIImage imageNamed: @"chat.png"];
		self.title = @"Comments";
		self.navigationItem.title= nil;
		self.entry = nil;
		commentsArray = nil;
        lastFilterChoice = nil;
		iTunesAlert = nil;
        visible = FALSE;
		
		//Create a custom back button image
		UIImage *backImage =[UIImage imageNamed:@"goBackComment.png"];
		UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backImage style: UIBarButtonItemStylePlain target:nil action:nil];
		//[backImage release];
		
		self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
        
        if([Props global].filters != nil) {
			pickerSelectButton = [[FilterButton alloc] initWithController:self];
            //***[pickerSelectButton resize];
			self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
			filterCriteria = [[FilterPicker sharedFilterPicker] getPickerTitle];
		}
	}
	
	return self;
}


- (id) initWithEntry:(Entry*) theEntry {
	
	self = [super init];
    if (self) {
		
		self.title = @"Comments";
		self.navigationItem.title= nil;
		self.entry = theEntry;
        
        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)];
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        swipeRight.delegate = self;
        [self.view addGestureRecognizer:swipeRight];
	}
	
	return self;	
}


- (void)dealloc {
	
	NSLog(@"COMMENTSVIEWCONTROLLER.dealloc *********************************************");

    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    commentViewer.delegate = nil;
	
    self.adView.delegate = nil;
}


- (void)loadView {
	
	UIView *contentView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = [UIColor lightGrayColor];
	contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	
	self.view = contentView;
    
    commentViewer = [[UIWebView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
    commentViewer.backgroundColor = [UIColor grayColor];
    commentViewer.dataDetectorTypes = (UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber | UIDataDetectorTypeAddress);
    commentViewer.scalesPageToFit = NO;
    commentViewer.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    commentViewer.delegate = self;	
    
    //NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    //[NSURLCache setSharedURLCache:sharedCache];
    //[sharedCache release];
    
    //NSString *path = [[NSBundle mainBundle] bundlePath];
    //NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    //[commentViewer loadHTMLString:[self generateHTML] baseURL:baseURL];
    
    commentViewer.dataDetectorTypes = UIDataDetectorTypeLink;
    
    [self.view addSubview:commentViewer];
	
	float ind_height = 30;
	UIActivityIndicatorView *progressInd = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, ind_height, ind_height)];
	progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
	[progressInd sizeToFit];
	progressInd.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
	progressInd.tag = kProgressIndTag;
	[progressInd startAnimating];
	[self.view addSubview:progressInd];
	
	self.view.autoresizesSubviews = YES;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	self.navigationController.navigationBar.translucent = FALSE;
	
	if([Props global].appID > 1)[self addCommentButton];
	if(entry == nil && ![Props global].isShellApp)[self addReviewButton];
	
	if ([Props global].appID <= 1) [self addTitleLabel];
    
    [self refreshComments];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name: kOrientationChange object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshComments) name: kRefreshComments object:nil];
}


-(void)viewWillAppear:(BOOL)animated {	
	
	NSLog(@"COMMENTSVIEWCONTROLLER.viewWillAppear");
	
	for (UIView *subview in [self.navigationController.navigationBar subviews]) {
		if (subview.tag > 0) {
			[subview removeFromSuperview];
			NSLog(@"Removing old views from nav controller");
		}
	}
	
	self.navigationController.navigationBar.translucent = FALSE;
	[self.navigationController setNavigationBarHidden:FALSE animated:FALSE];
	
	self.navigationController.navigationBar.alpha = 1.0;
	if ([Props global].osVersion < 7.0) self.navigationController.navigationBar.tintColor = [Props global].navigationBarTint;
    else self.navigationController.navigationBar.barStyle = UIBarStyleDefault;

	self.navigationController.navigationBar.translucent = FALSE;
	
	
	if ([Props global].deviceType != kiPad) {
        if ([[Props global] inLandscapeMode] && [Props global].osVersion > 3.1){
            
            //original version for regular app
            float xPos =  [[UIDevice currentDevice] orientation]==UIDeviceOrientationLandscapeLeft ? -kPartialHideTabBarHeight : 0;
            if(![Props global].isShellApp) self.tabBarController.view.frame = CGRectMake( xPos,0, [Props global].screenHeight + kPartialHideTabBarHeight, [Props global].screenWidth);
            
            //update for SW - WHY????
            else self.tabBarController.view.frame = CGRectMake( 0,0, [Props global].screenWidth, [Props global].screenHeight + kPartialHideTabBarHeight);
        }
        
        else self.tabBarController.view.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
	}
    
    if([Props global].isShellApp && [Props global].filters != nil){
		
		[[FilterPicker sharedFilterPicker] hideSorterPicker];
        
        [pickerSelectButton update];
        self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
		
		//Set view to show all if the filter is set to favorites and the last favorite was removed
		if(([[EntryCollection sharedEntryCollection] favoritesExist] == FALSE) && [filterCriteria  isEqual: kFavorites]){
			filterCriteria = nil; //kFilterAll;
			[[FilterPicker sharedFilterPicker].theFilterPicker selectRow:0 inComponent:0 animated: NO];
            [self refreshComments];
		}
		
		//remove favorites as necessary if they are showing and one was removed in another view
		else if ([[EntryCollection sharedEntryCollection] favoritesExist] && [[[FilterPicker sharedFilterPicker] getPickerTitle]  isEqual: kFavorites]) {
			NSMutableArray *theFavorites = [[NSMutableArray alloc] initWithArray: [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]]];
			
			if ([theFavorites count] != [[EntryCollection sharedEntryCollection].sortedEntries count] ) [self refreshComments];
		}
        
        //Update button and data if filter was changed in another view
        else if (filterCriteria != [[FilterPicker sharedFilterPicker] getPickerTitle]){
            
            NSLog(@"TLMV.viewWillAppear: About to refresh data for new filter");
            filterCriteria = [[FilterPicker sharedFilterPicker] getPickerTitle];
            [self refreshComments];
        }
        
        [FilterPicker sharedFilterPicker].delegate = self;
	}
	
    [super viewWillAppear:animated];
    
	NSLog(@"COMMENTSVIEWCONTROLLER.viewWillAppear: done");
}


- (void) viewDidAppear:(BOOL)animated {
	
    visible = TRUE;
    
    
    if ([Props global].showAds) {
        
        NSLog(@"CVC.viewDidAppear: creating AdBannerView and attaching to detailView");
        if (self.adView != nil)
            [self fixupAdViewWithAnimation:YES];
        else
            [self createAdBannerView];
    }
    
    
	SMLog *log = [[SMLog alloc] initWithPageID: kTLCV actionID: kCVViewSelected];
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	
	/*[Apsalar eventWithArgs:@"comments view",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
}


- (void) viewDidDisappear:(BOOL)animated {visible = FALSE;}


- (BOOL)prefersStatusBarHidden { return YES;}


- (void) refreshComments {
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    NSString *commentHTML = [self generateHTML];
    
    if (commentHTML != nil) {
        commentViewer.hidden = FALSE;
        [commentViewer loadHTMLString:commentHTML baseURL:baseURL];
    }
	
    else { 
        
        commentViewer.hidden = TRUE;
        
        if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) [self showNoInternetMessage];
        
        else [self showBeTheFirstMessage];
    }
}

- (NSString*) generateHTML {
    
    if (commentsArray != nil) { commentsArray = nil;}
    
    for (UIView *view in [self.view subviews]) {
		if (view.tag == kBeTheFirstViewTag || view.tag == kNoInternetViewTag) {
			[view removeFromSuperview];
		}
	}
	
	commentsArray = [NSMutableArray new];
	
	//Set up the comments array
	FMResultSet * rs;
	BOOL shouldShowEntry;
    
    NSString *header = @"<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>\
    <html lang='en-US' xmlns='http://www.w3.org/1999/xhtml' dir='ltr'>\
    <head>\
	<title>Comments</title>\
	<meta http-equiv='Content-type' content='text/html; charset=utf-8' />\
    <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0'/>\
    \
	<link rel='shortcut icon' href='favicon.ico' />\
	<link rel='stylesheet' href='comments_style.css' type='text/css' media='all' />\
    </head>\
    <body>\
    <div class='comm-list'>\
	<ul>";

    
    NSMutableString *htmlDescription = [NSMutableString stringWithString:@""]; 
    
    @synchronized([Props global].dbSync) {
        FMDatabase *db = [EntryCollection sharedContentDatabase];
        
		if (self.entry == nil){
			
            NSString *query;
            
            if (filterCriteria == nil || [filterCriteria isEqualToString:@"Everything"]) {
                query = @"SELECT entries.name AS name, entries.rowid, comments.created, comments.subentry_name, comments.comment, comments.commenter_alias, comments.response_date, comments.response, comments.responder_name, entries.rowid as id FROM comments LEFT JOIN entries ON entries.rowid = comments.entryid ORDER BY comments.rowid DESC LIMIT 0, 50";
            }
            
            else if ([filterCriteria  isEqual: kFavorites]) {
                NSArray *theFavorites = [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"favorites-%i", [Props global].appID]]; //get the array of names of favorite entries
                
                if([theFavorites count] > 0) {
                    
                    NSMutableString *entryList = [NSMutableString stringWithFormat:@""];
                    
                    for(NSString* entryName in theFavorites){
                        
                        Entry *e = [[EntryCollection sharedEntryCollection].entriesDictionary objectForKey:entryName];
                        [entryList appendString:[NSString stringWithFormat:@"%i,", e.entryid]];
                    }
                    
                    [entryList deleteCharactersInRange:NSMakeRange([entryList length] - 1, 1)]; //Delete the last comma on the end
                    
                    query = [NSString stringWithFormat:@"SELECT entries.name AS name, entries.rowid, comments.created, comments.subentry_name, comments.comment, comments.commenter_alias, comments.response_date, comments.response, comments.responder_name, entries.rowid as id FROM comments LEFT JOIN entries ON entries.rowid = comments.entryid WHERE entries.rowid IN (%@) ORDER BY comments.rowid DESC LIMIT 0, 50", entryList];
                    
                    NSLog(@"Query = %@", query);
                }
            }
            
            else query = [NSString stringWithFormat:@"SELECT entries.name AS name, entries.rowid, comments.created, comments.subentry_name, comments.comment, comments.commenter_alias, comments.response_date, comments.response, comments.responder_name, entries.rowid as id FROM entry_groups, groups, comments LEFT JOIN entries ON entries.rowid = comments.entryid WHERE comments.entryid = entry_groups.entryid AND entry_groups.groupid = groups.rowid AND groups.name = '%@' ORDER BY comments.rowid DESC LIMIT 0, 50", filterCriteria];
            
            //NSLog(@"Query = %@", query);
            
            rs = [db executeQuery:query];
			shouldShowEntry = TRUE;
		}
		
		else {
			rs = [db executeQuery:@"SELECT entries.name AS name, comments.created, comments.subentry_name, comments.comment, comments.commenter_alias, comments.response_date, comments.response, comments.responder_name, entries.rowid as id FROM comments, entries WHERE entries.rowid = comments.entryid AND comments.entryid = ? ORDER BY comments.rowid DESC", [NSNumber numberWithInt:entry.entryid]];
			
			shouldShowEntry = FALSE;
		}
		
		
		if ([[EntryCollection sharedContentDatabase] hadError]) NSLog(@"Err %d: %@", [[EntryCollection sharedContentDatabase] lastErrorCode], [[EntryCollection sharedContentDatabase] lastErrorMessage]);
		
		int repeatCounter = 0;
        int lastEntryID;
        
        while ([rs next]) {
            
            int entryID = [rs intForColumn:@"id"];
            if (entryID == lastEntryID) repeatCounter ++;
            else repeatCounter = 0;
            
            if (![Props global].appID == 1 || repeatCounter < 3 || self.entry != nil) {
                Comment *comment = [[Comment alloc] initWithRow: rs];
                
                comment.controller = self;
                comment.shouldShowEntry = shouldShowEntry;
                
                [commentsArray addObject:comment];
                
            }
			
            lastEntryID = entryID;
		}
		
		[rs close];	
	}
    
    if ([commentsArray count] == 0) return nil;
        
    else {
    
        for (Comment *comment in commentsArray) {
            
            //NSLog(@"Comment description = %@", comment.commentText);
            Entry *commentEntry = [EntryCollection entryByName:comment.entryName];
            
            NSString *commentImageSource = nil;;
            
            //NSBundle mainBundle returns nil if the file is not present, so we cannot use the array approach for these files
            NSString *bundle_x100 = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_x100", commentEntry.icon] ofType:@"jpg"];
            
            NSString *bundle_Icon = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i-icon", commentEntry.icon] ofType:@"jpg"];
            
            if (bundle_x100 != nil) commentImageSource = bundle_x100;
            
            else if (bundle_Icon != nil) commentImageSource = bundle_Icon;
           
            else {
                
                NSString *contentFolder_x100 = [NSString stringWithFormat:@"%@/images/%i_x100.jpg", [Props global].contentFolder, commentEntry.icon];
                NSString *contentFolder_Icon = [NSString stringWithFormat:@"%@/images/%i-icon.jpg", [Props global].contentFolder, commentEntry.icon];
                NSString *contentFolder_Big_Image = [NSString stringWithFormat:@"%@/images/%i.jpg", [Props global].contentFolder, commentEntry.icon];
                
                NSString *contentFolder_iPad_Image = [NSString stringWithFormat:@"%@/images/%i_768.jpg", [Props global].contentFolder, commentEntry.icon];
                
                NSString *bundle_Big_Image = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i", commentEntry.icon] ofType:@"jpg"];
                
                NSLog(@"bundle_x100 = %@, %@, %@", bundle_x100, bundle_Icon, contentFolder_Big_Image);
                
                NSArray *filePaths = [NSArray arrayWithObjects: contentFolder_x100, contentFolder_Icon, contentFolder_Big_Image, contentFolder_iPad_Image, bundle_Big_Image,  nil];
                
                for (NSString *path in filePaths) {
                    
                    NSLog(@"Looking for image at %@", path);
                    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                        commentImageSource = path;
                        break;
                    }
                }
            }
            
            if (commentImageSource == nil) NSLog(@"*********** ERROR: CVC.generateHTML: Comment image not found for %@", commentEntry.name);
            
            //NSString *commentImageSource = [Props global].inTestAppMode ? [NSString stringWithFormat:@"%@/images/%i-icon.jpg", [Props global].contentFolder, commentEntry.icon] : [NSString stringWithFormat:@"%i_x100.jpg", commentEntry.icon];
            
            //NSLog(@"Comment image source = %@", commentImageSource);
            NSString *commentHTML;
            
            if (comment.entryName == NULL || (self.entry != nil && [Props global].appID != 1)) commentHTML = [NSString stringWithFormat:@"\
                                                          <div class='comment'>\
                                                          <span class='tail'>&nbsp;</span>\
                                                          \
                                                          <div class='c-body'>\
                                                          <p>%@</p>\
                                                          </div>\
                                                          \
                                                          <div class='c-footer'>\
                                                          <p class='left'>posted by %@</p>\
                                                          <p class='right'>%@</p>\
                                                          </div>\
                                                          </div>\
                                                          ", comment.commentText, comment.userName, comment.date];  
                else if (self.entry != nil && [Props global].appID == 1 && [comment.subEntryName length] > 0)  commentHTML = [NSString stringWithFormat:@"\
                                    <div class='comment'>\
                                    <span class='tail'>&nbsp;</span>\
                                    \
                                    <h3>User comment on \"%@\"</h3>\
                                    \
                                    <div class='c-body'>\
                                    <p>%@</p>\
                                    </div>\
                                    \
                                    <div class='c-footer'>\
                                    <p class='left'>posted by %@</p>\
                                    <p class='right'>%@</p>\
                                    </div>\
                                    </div>\
                                    ", comment.subEntryName, comment.commentText, comment.userName, comment.date];
            
                
                else commentHTML = [NSString stringWithFormat:@"\
                                <div class='comment'>\
                                <span class='tail'>&nbsp;</span>\
                                \
                                <div class='c-header'>\
                                <img src='%@' alt='' height='30' width='30'/>\
                                <h3><a class='SMEntryLink' href='SMEntryLink://%i'>%@</a></h3>\
                                </div>\
                                \
                                <div class='c-body'>\
                                <p>%@</p>\
                                </div>\
                                \
                                <div class='c-footer'>\
                                <p class='left'>posted by %@</p>\
                                <p class='right'>%@</p>\
                                </div>\
                                </div>\
                                ", commentImageSource, commentEntry.entryid, comment.entryName, comment.commentText, comment.userName, comment.date];
            
            NSString *responseHTML = @"";
            
            if ([comment.response length] > 0) {
                responseHTML = [NSString stringWithFormat:@"\
                                <div class='comment ans-comm'>\
                                <span class='tail'>&nbsp;</span>\
                                \
                                <div class='c-body'>\
                                <p>%@</p>\
                                </div>\
                                \
                                <div class='c-footer'>\
                                <p class='left'>%@</p>\
                                <p class='right'>%@</p>\
                                </div>\
                                </div>\
                                ", comment.response, comment.responseDate, comment.responderName];
            }
            
            NSString *fullComment = [NSString stringWithFormat:@"<li>%@%@</li>", commentHTML, responseHTML];
            
            //NSLog(@"Full comment =\n%@", fullComment);
            
            [htmlDescription appendString:fullComment];
        }
        
        
        NSString *footer = @"</ul></div></body></html>";
        
        NSString *formattedString = [NSString stringWithFormat:@"%@%@%@",header,htmlDescription,footer];
        
        //NSLog(@"Formatted string = %@", formattedString);
        
        return formattedString;
    }
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        
        NSString *scheme = [request.URL scheme];
        
        if ([scheme caseInsensitiveCompare:@"SMEntryLink"] == NSOrderedSame) {
            
            NSString *idString = [[[request.URL resourceSpecifier] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"//" withString:@""];
            
            int entryID = [idString intValue]; 
            NSLog(@"abs string = %@, id string = %@ and id = %i", [request.URL absoluteString], idString, entryID);
            [self goToEntry:[NSNumber numberWithInt:entryID]];
            return NO;
        }
        
        else if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
            
            WebViewController *webPageView = [[WebViewController alloc] initWithEntry:nil andURLToLoad:request.URL];
            [self.navigationController pushViewController:webPageView animated:YES];
            
            return NO;
        }
    }
    
    return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    if ([webView respondsToSelector:@selector(scrollView)] && [webView.scrollView respondsToSelector:@selector(setContentSize:)]) {
        [webView.scrollView setContentSize: CGSizeMake(webView.frame.size.width, webView.scrollView.contentSize.height)];
    }
    
	[[self.view viewWithTag:kProgressIndTag] removeFromSuperview];
    
}


- (void) addTitleLabel {
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, 30)];
	
	[label setFont:[UIFont boldSystemFontOfSize:20.0]];
    label.adjustsFontSizeToFitWidth = TRUE;
    label.minimumFontSize = 12;
	[label setBackgroundColor:[UIColor clearColor]];
	[label setTextColor:[UIColor colorWithWhite:0.9 alpha:0.8]];
	label.textAlignment = UITextAlignmentCenter;
	if ([Props global].appID <= 1) {
        if (self.entry == nil) [label setText: @"Comments from Sutro guides"];
        else [label setText:[NSString stringWithFormat:@"Comments on %@", entry.name]];
    }
	self.navigationItem.titleView = label;
}



- (void) postComment: (id) sender {

	if([[Reachability sharedReachability] internetConnectionStatus] != NotReachable) {
	
		CommentPageView *commentPage = [[CommentPageView alloc] initWithEntry: entry];
		
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:commentPage];
		
		[self presentModalViewController:navigationController animated:YES];
		
		
		SMLog *log = [[SMLog alloc] initWithPageID: kTLCV actionID: kIVComment ];
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}
	
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Looks like you don't have an internet connection. You'll need one to post comments." delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:nil];   
		 
		[alert show];  
	}
}


- (void) showBeTheFirstMessage {
	
	float contentHeight = 30;
	
	for (UIView *view in [self.view subviews]) {
		if (view.tag == kBeTheFirstViewTag) {
			[view removeFromSuperview];
		}
	}
	
	CGRect labelFrame = CGRectMake([Props global].leftMargin, contentHeight, [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, 19);
	UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
	
	label.backgroundColor = [UIColor clearColor];
	label.text = lastFilterChoice != nil ? @"There are not comments yet for this topic." : @"There are no comments yet for this guide.";
	label.font = [UIFont fontWithName:kFontName size:15];
	label.textAlignment = UITextAlignmentCenter;
	label.numberOfLines = 0;
	label.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];
	label.tag = kBeTheFirstViewTag;
	
	[self.view addSubview:label];
	
	contentHeight += label.frame.size.height + [Props global].tinyTweenMargin;
	
	
	CGRect buttonFrame = CGRectMake([Props global].leftMargin, contentHeight, [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, 25);
	UIButton *beFirstButton = [UIButton buttonWithType: 0];
	beFirstButton.frame = buttonFrame;
	beFirstButton.backgroundColor = [UIColor clearColor];
	beFirstButton.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
	beFirstButton.titleLabel.textAlignment = UITextAlignmentCenter;
	[beFirstButton setTitle:@"Be the first to make one!" forState:0];
	[beFirstButton setTitleColor:[Props global].linkColor forState:0];
	beFirstButton.titleLabel.numberOfLines = 3;
	beFirstButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
	beFirstButton.tag = kBeTheFirstViewTag;
	[beFirstButton addTarget:self action:@selector(postComment:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:beFirstButton];
	
}


- (void) showNoInternetMessage {
	
	float contentHeight = 50;
	
	for (UIView *view in [self.view subviews]) {
		if (view.tag == kNoInternetViewTag) {
			NSLog(@"Removing view");
			[view removeFromSuperview];
		}
	}
	
	CGRect labelFrame = CGRectMake([Props global].leftMargin, contentHeight, [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, 150);
	UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
	
	label.backgroundColor = [UIColor clearColor];
	label.text = @"Looks like you might not have an internet connection.\n\nYou'll need to get connected in order to see the latest comments and participate.";
	label.font = [UIFont boldSystemFontOfSize:17];
	label.textAlignment = UITextAlignmentCenter;
	label.numberOfLines = 0;
	label.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];
	label.tag = kNoInternetViewTag;
    label.shadowColor = [UIColor whiteColor];
    label.shadowOffset = CGSizeMake(0, 1.5);
	
	[self.view addSubview:label];
	
}


- (void) goToEntry: (NSNumber*) theEntryIdObject {

    int theEntryId = [theEntryIdObject intValue];
    //self.tabBarController.view.frame = [[UIScreen mainScreen] bounds];
    self.tabBarController.view.frame = [Props global].isShellApp ? CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight) : [[UIScreen mainScreen] bounds];
    
	LocationViewController *entryController = [[LocationViewController alloc] initWithController: nil];
	
	// set the entry for the controller
	entryController.entry = [EntryCollection entryById:theEntryId];
	
	// push the entry view controller onto the navigation stack to display it
	[[self navigationController] pushViewController:entryController animated:YES];
	[entryController.view setNeedsDisplay];
	
	//log event
	SMLog *log = [[SMLog alloc] initWithPageID: kTLCV actionID: kCVGoToEntry];
	log.entry_id = entryController.entry.entryid;
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	
}


- (void) goBack {
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (void) addCommentButton {
    
    UIBarButtonItem *commentBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Comment or Ask" style:UIBarButtonItemStylePlain target:self action:@selector(postComment:)];
    self.navigationItem.rightBarButtonItem = commentBarButton;
	
}


- (void) addReviewButton {
    
    UIBarButtonItem *reviewBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Review on iTunes" style:UIBarButtonItemStylePlain target:self action:@selector(showReviewConfirmation:)];
    self.navigationItem.leftBarButtonItem = reviewBarButton;
}


- (void) updateButtonHeights {

	CGRect frame = self.navigationItem.leftBarButtonItem.customView.frame;
	float newHeight = [Props global].titleBarHeight * .7;
	self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(frame.origin.x, ([Props global].titleBarHeight - newHeight)/2 - 1, frame.size.width, newHeight);
	
	CGRect frame2 = self.navigationItem.rightBarButtonItem.customView.frame;
	self.navigationItem.rightBarButtonItem.customView.frame = CGRectMake(frame2.origin.x, ([Props global].titleBarHeight - newHeight)/2 - 1, frame2.size.width, newHeight);
}


- (void) showReviewConfirmation: (id) sender {
	
	iTunesAlert = [[UIAlertView alloc] initWithTitle: nil message:@"This will leave the guide and open iTunes" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Go for it!", nil];
	[iTunesAlert show];
}


-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
	
	if(theAlert == iTunesAlert) { 
		
		NSLog(@"About to open %@", [Props global].reviewURL);
		
		if (buttonIndex != 0){
			
			SMLog *log = [[SMLog alloc] initWithPageID: kTLCV actionID: kCVReviewButtonClicked_Yes ];
			[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
			
			[self goToExternalWebPageWithURL: [NSURL URLWithString:[Props global].reviewURL ]];
		}
		
		else {
			
			SMLog *log = [[SMLog alloc] initWithPageID: kTLCV actionID: kCVReviewButtonClicked_No ];
			[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
		}
	}
}


- (void)goToExternalWebPageWithURL:(NSURL*) webPageURL  {
	
	if (![[UIApplication sharedApplication] openURL:webPageURL])
	{
		SMLog *log = [[SMLog alloc] initWithPageID: kTLCV actionID: kIVErrorGoingToAppStore];
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}
}


- (int) countComments {
	
	int numberOfComments = 0;
	FMResultSet *rs;
	
	@synchronized([Props global].dbSync) {
		
		if (self.entry == nil) rs = [[EntryCollection sharedContentDatabase] executeQuery:@"SELECT COUNT(comments.comment) AS commentsCount FROM comments LEFT JOIN entries ON entries.rowid = comments.entryid"];
		
		else rs = [[EntryCollection sharedContentDatabase] executeQuery:@"SELECT COUNT(comments.comment) AS commentsCount  FROM comments, entries WHERE entries.rowid = comments.entryid AND comments.entryid = ? ORDER BY comments.rowid DESC", [NSNumber numberWithInt:entry.entryid]];
		
		
		
		if ([[EntryCollection sharedContentDatabase] hadError]) {
			
			NSLog(@"Err %d: %@", [[EntryCollection sharedContentDatabase] lastErrorCode], [[EntryCollection sharedContentDatabase] lastErrorMessage]);
		}
		
		while ([rs next]) {
			
			numberOfComments = [rs intForColumn:@"commentsCount"];
			
		}
		
		[rs close];	
	}
	
	NSLog(@"COMMENTSVIEWCONTROLLER.countComments: Looks like there are %i comments in the database", numberOfComments);
	
	return numberOfComments;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


#pragma mark TitleBar Interaction Elements

- (void) showFilterPicker: (id) sender {
	
	[self.view addSubview: [FilterPicker sharedFilterPicker]];
	[self.view bringSubviewToFront:[FilterPicker sharedFilterPicker]];
	[[FilterPicker sharedFilterPicker] showControls];
	
	lastFilterChoice = [[FilterPicker sharedFilterPicker] getPickerTitle];
	
	self.navigationItem.leftBarButtonItem = pickerSelectButton.cancelBarButton;
}


- (void) hideFilterPicker: (id) sender {
	
	[[FilterPicker sharedFilterPicker] hideControls];
	
	filterCriteria = [[FilterPicker sharedFilterPicker] getPickerTitle];
	
	[pickerSelectButton update];
	self.navigationItem.leftBarButtonItem = pickerSelectButton.selectBarButton;
	
	//[self performSelector:@selector(removePickerFromView:) withObject:nil afterDelay:.8];
	
	if([filterCriteria isEqualToString:lastFilterChoice] == FALSE) 
		[self refreshComments];
}


#pragma 
#pragma View Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	//NSLog(@"CVC.shouldAutorotateToInterfaceOrientation");
    
    if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        
        return YES;
    }
    
    else return NO;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	if (toInterfaceOrientation != UIDeviceOrientationFaceUp && toInterfaceOrientation != UIDeviceOrientationFaceDown && toInterfaceOrientation != UIDeviceOrientationUnknown) {
        
        if ([Props global].showAds) [self hideAdBannerWithAnimation:NO];
	}
}


- (void) orientationChange: (NSNotification *)notification {
    
    //NSLog(@"CVC.orientationChange");
    
    //[self updateButtonHeights];
}


- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
    NSLog(@"CVC.didRotateFromInterfaceOrientation");
    
	if ([Props global].deviceType != kiPad && [Props global].osVersion >= 4.0 && [[Props global] inLandscapeMode]){
		
		[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
		[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
		[ UIView setAnimationDuration: 0.2f ]; 
		
		float xPos =  [[UIDevice currentDevice] orientation]==UIDeviceOrientationLandscapeLeft ? -kPartialHideTabBarHeight : 0;
		//original version for regular app
		if(![Props global].isShellApp) self.tabBarController.view.frame = CGRectMake( xPos,0, ([Props global].screenHeight + kPartialHideTabBarHeight), [Props global].screenWidth);
        
        //update for SW - WHY????
        else self.tabBarController.view.frame = CGRectMake( 0,0, [Props global].screenWidth, [Props global].screenHeight + kPartialHideTabBarHeight);
		
		[ UIView commitAnimations ];
	}
    
    if ([Props global].showAds) [self fixupAdViewWithAnimation:YES];
}


#pragma mark -
#pragma mark iAd Private Helpers

//get banner height based on device orientation
- (int)getBannerHeight:(UIDeviceOrientation)orientation {
    
    if (UIInterfaceOrientationIsPortrait(orientation))
        return 50;
    else
        return 32;
}

//get banner height
- (int)getBannerHeight {
    
    return [self getBannerHeight:[UIDevice currentDevice].orientation];
}

- (void) hideAdBannerWithAnimation:(BOOL) shouldAnimate {
    
    if (self.adView != nil) {
        
        //float animationDuration = shouldAnimate ? 0.8 : 0.001;
        
        //[UIView beginAnimations:@"fixupAdView" context:nil]; 
        //[ UIView setAnimationDuration: animationDuration ];
        
        CGRect adViewFrame = [self.adView frame];
        adViewFrame.origin.x = 0;
        adViewFrame.origin.y = [Props global].screenHeight; //set offscreen as there is no ad
        [self.adView setFrame:adViewFrame];
        
        //float tabBarHeight = [[Props global] inLandscapeMode] && [Props global].deviceType != kiPad ? kTabBarHeight - kPartialHideTabBarHeight : kTabBarHeight; 
        
        //commentViewer.frame = [[UIScreen mainScreen] applicationFrame]; //CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - tabBarHeight - [Props global].titleBarHeight);
        
        //[UIView commitAnimations];
    }    
}

/* Idea:
 1. Set the current size of the expected ad based on orientation
 2. Animate the hiding or displaying of the ADBannerView if ad has arrived
 */
- (void)fixupAdViewWithAnimation:(BOOL) shouldAnimate
{
    if (self.adView != nil) {
        
        if ([[Props global] inLandscapeMode]) {
            self.adView.currentContentSizeIdentifier =ADBannerContentSizeIdentifierLandscape;
        } else {
            self.adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        }
        
        float animationDuration = shouldAnimate ? 0.4 : 0.001;
        
        [UIView beginAnimations:@"fixupAdView" context:nil]; 
        [ UIView setAnimationDuration: animationDuration ];
        if (adBannerIsVisible) {
            CGRect adViewFrame = [self.adView frame];
            adViewFrame.origin.x = 0;
            float tabBarHeight = [[Props global] inLandscapeMode] && [Props global].deviceType != kiPad ? kTabBarHeight - kPartialHideTabBarHeight : kTabBarHeight; 
            if (self.entry != nil) tabBarHeight = 0;
                
            adViewFrame.origin.y = [Props global].screenHeight - tabBarHeight - [Props global].titleBarHeight - adViewFrame.size.height;
            
            //commentViewer.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - tabBarHeight - [Props global].titleBarHeight - adView.frame.size.height);
            
            [self.adView setFrame:adViewFrame];
            
        } else {
            CGRect adViewFrame = [self.adView frame];
            adViewFrame.origin.x = 0;
            adViewFrame.origin.y = [Props global].screenHeight; //set offscreen as there is no ad
            [self.adView setFrame:adViewFrame];
        }
        [UIView commitAnimations];
    }
}


/* Steps:
 1. Alloc and init ADBannerView object with CGRectZero
 2. Set the possible sizes of expected ads
 3. Set the current size of expected ads (based on device orientation)
 4. Set the current frame of the ad banner offscreen initially, since we
 don't know if ad is available, and thus don't want to display the
 view until we know an ad is ready
 5. Set the location view controller to be the ADBannerView's delegate
 6. Add ADBannerView as subView to DetailView
 */

- (void)createAdBannerView {
    
    self.adView = nil;
    
    ADBannerView *anAdView = [[ADBannerView alloc] initWithFrame:CGRectZero];
    
    self.adView = anAdView;
    self.adBannerIsVisible = FALSE;
    
    //set the possible sizes of expected ads
    self.adView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil];
    
    //set the current size of expected ads
    if (UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        self.adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
    } else {
        self.adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    }
    
    //set offscreen as there is no ad
    //[self.adView setFrame:CGRectOffset([adView frame], 0, -[self getBannerHeight])];
    
    self.adView.frame = CGRectMake(0, [Props global].screenHeight, [Props global].screenWidth, [self getBannerHeight]);
    
    self.adView.delegate = self;
    
    //is this the best place to put the ad banner?
    
    [self.view addSubview:self.adView];
    NSLog(@"CVC.createAdBannerView");
}


#pragma mark -
#pragma mark ADBannerViewDelegate Methods


//Detect when new ads are shown
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    /* Called when a new banner ad is loaded. Implement this to notify
     app that new ad is ready for display */
    NSLog(@"CVC.bannerViewDidLoad: AdBannerView loaded");
    if (!adBannerIsVisible) {
        adBannerIsVisible = TRUE;
        NSLog(@"CVC.bannerViewDidLoad: set adBannerVisible to TRUE and calling fixupAdView");
        [self fixupAdViewWithAnimation:YES];
    }
}

//Detect when user interacts with ad
- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    /* Called when banner view finishes executing an action that covers
     the app's UI. Any activities paused the delegate should be resumed */
    //Nothing to do right now
}


//Detect errors
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    /* Called when banner view fails to load a new ad */
    NSLog(@"CVC.bannerView:didFailToReceiveAdWithError: error: %@", [error localizedDescription]);
    if (adBannerIsVisible) {
        adBannerIsVisible = FALSE;
        [self fixupAdViewWithAnimation:YES];
    }
}


- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    
    int pageId = entry == nil ? kTLCV : kCommentsView;
    
    SMLog *log = [[SMLog alloc] initWithPageID: pageId actionID: kAdClicked];
    //log.entry_id = guideId;
    [[ActivityLogger sharedActivityLogger] logPurchase: [log createLogString]];
    
    return TRUE;
}


@end
