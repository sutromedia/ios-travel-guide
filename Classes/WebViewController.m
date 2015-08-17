
//
//  IntroView.m
//
//  Created by Tobin1 on 2/24/09.
//

#import "WebViewController.h"
#import "Entry.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"
#import "ActivityLogger.h"
#import "DataDownloader.h"
#import "SMLog.h"
#import "Props.h"

@interface WebViewController(private)

//- (BOOL) checkNetworkStatus;
- (void) showLoadingAnimation;
- (void) showErrorMessageWithText:(NSString*) errorText;
//- (void) updateStatus;
- (void) showGoToAppStoreAlert: (id) sender;
- (void) goToExternalWebPageWithURL:(NSURL*) webPageURL;
- (void) addTitleLabel;
- (BOOL) isSutroMediaURL:(NSString*) urlString; 
- (BOOL) isReviewURL:(NSString*) urlString;
- (NSURL*) turnURLIntoSkimLinkURL: (NSURL*) theURL;

@end

@implementation WebViewController

//@synthesize internetConnectionStatus;
//@synthesize myWebView;
//@synthesize entry;


CGRect webFrame;

// initialize the view, calling super and setting the 
// properties to nil
- (id)initWithEntry:(Entry*) theEntry andURLToLoad:(NSURL*) theURL {
	
    self = [super init];
	if (self) {
        
		targetAppID = kValueNotSet;
		progressInd = nil;
		errorLabel  = nil;
		appStoreAlert = nil;
		
		entry = theEntry;
		
		//For when webview is pushed from top level slideshow
		self.hidesBottomBarWhenPushed = YES; 
		
		//myWebView = [[UIWebView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
        myWebView = [[UIWebView alloc] initWithFrame: CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
		myWebView.backgroundColor = [UIColor whiteColor];
		myWebView.dataDetectorTypes = UIDataDetectorTypeAll;
		
		myWebView.scalesPageToFit = YES;
		myWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		myWebView.delegate = self;	
		
		//This line was added to prevent a memory leak, but also seems to cause intermittent crashes. Will try removing it, but need to keep eye on the potential leak
        /*NSLog(@"WEBVIEWCONTROLLER.init: memory usage = %i kb", [NSURLCache sharedURLCache].currentMemoryUsage/1024); 
		NSLog(@"WEBVIEWCONTROLLER.init: memory capacity = %i kb", [NSURLCache sharedURLCache].memoryCapacity/1024); 
		NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
		[NSURLCache setSharedURLCache:sharedCache];
		[sharedCache release];
		NSLog(@"WEBVIEWCONTROLLER.init: memory usage = %i kb", [NSURLCache sharedURLCache].currentMemoryUsage/1024); 
		NSLog(@"WEBVIEWCONTROLLER.init: memory capacity = %i kb", [NSURLCache sharedURLCache].memoryCapacity/1024); */
		//NSURLRequest *webRequest = [NSURLRequest requestWithURL:theURL];
		if (([Props global].appID == 3 || [Props global].appID == 37) &&![self isSutroMediaURL:[theURL absoluteString]]) theURL = [self turnURLIntoSkimLinkURL:theURL];
		
		NSURLRequest *webRequest = [[NSURLRequest alloc] initWithURL:theURL];
		//webRequest.delegate = self;
		
		[myWebView loadRequest:webRequest];
	}
	
    return self;
}


- (NSURL*) turnURLIntoSkimLinkURL: (NSURL*) theURL {
	
	NSString *url = [theURL absoluteString];
	NSString * encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
																									 NULL,
																									 (CFStringRef)url,
																									 NULL,
																									 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
																									 kCFStringEncodingUTF8 ));
	
	NSString * doubleEncodedURL = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
																										NULL,
																										(CFStringRef)encodedString,
																										NULL,
																										(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																										kCFStringEncodingUTF8 ));
	
	
	NSString *simlinkURL = [NSString stringWithFormat:@"http://%@/published/external/%i/%@", [Props global].serverContentSource, [Props global].appID, doubleEncodedURL];
	NSLog(@"Simlink URL = %@", simlinkURL);
	
	return [NSURL URLWithString:simlinkURL];
	
	//return [NSURL URLWithString:@"http://www.google.com"];
}


-(NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {return nil;}


- (void)dealloc {
	NSLog(@"WEBVIEWCONTROLLER.dealloc");
	entry = nil;
	
	[myWebView stopLoading];
	
	/*NSLog(@"WEBVIEWCONTROLLER.dealloc: URLCache memory usage = %i kb", [NSURLCache sharedURLCache].currentMemoryUsage/1024); 
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	NSLog(@"WVC.dealloc: URLCache memory usag after = %i kb", [NSURLCache sharedURLCache].currentMemoryUsage/1024); 
	
	NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
	[NSURLCache setSharedURLCache:sharedCache];
	[sharedCache release];*/
	
	myWebView.delegate = nil;
	
	self.view = nil;
	
	
	if (progressInd != nil) { progressInd = nil;}
	
}


- (void) loadView {
	
	self.navigationController.navigationBar.tintColor = [Props global].navigationBarTint;
	self.navigationController.navigationBar.translucent = FALSE;
	self.navigationController.navigationBar.hidden = FALSE;
	[self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
	
	if (entry != nil) [self addTitleLabel];
	
	
	//CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    CGRect screenRect = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
	
	// setup our parent content view and embed it to the view controller
	UIView *contentView = [[UIView alloc] initWithFrame:screenRect];
	
	//contentView.backgroundColor = [UIColor blackColor];
    contentView.backgroundColor = [UIColor redColor];
	self.view = contentView;
	
	
	
	[self.view addSubview:myWebView];
	
	[self showLoadingAnimation];
		
	UISegmentedControl *webNavControls = [[UISegmentedControl alloc] initWithItems:
										  [NSArray arrayWithObjects:
										   [UIImage imageNamed:@"back_inactive.png"],
										   [UIImage imageNamed:@"forward_inactive.png"],
										   nil]];
	[webNavControls addTarget:self action:@selector(webNavAction:) forControlEvents:UIControlEventValueChanged];
	webNavControls.frame = CGRectMake(0, 0, 90, kCustomButtonHeight);
	webNavControls.segmentedControlStyle = UISegmentedControlStyleBar;
	webNavControls.momentary = YES;
	
	UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:webNavControls];
	
	
	self.navigationItem.rightBarButtonItem = barButtonItem;	
	
	
	self.navigationController.navigationBar.translucent = FALSE;
	self.navigationController.navigationBar.tintColor = [Props global].navigationBarTint;
	[self.navigationController setNavigationBarHidden:FALSE animated:FALSE];
	
	myWebView.delegate = self;
	[[DataDownloader sharedDataDownloader] pauseDownload];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.delegate = self;
    [self.view addGestureRecognizer:swipeRight];
}


- (void) viewDidAppear:(BOOL)animated {
    
    [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
}


- (void) viewWillDisappear:(BOOL)animated {
	
	[myWebView stopLoading];
	myWebView.delegate = nil;
	if(errorLabel != nil) errorLabel.hidden = TRUE;

	[[DataDownloader sharedDataDownloader] resumeDownload];
}


- (void) addTitleLabel {
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 260, 30)];
	
	[label setFont:[UIFont boldSystemFontOfSize:16.0]];
	label.adjustsFontSizeToFitWidth = TRUE;
	label.minimumFontSize = 13;
	[label setBackgroundColor:[UIColor clearColor]];
	[label setTextColor:[UIColor colorWithWhite:0.9 alpha:0.9]];
	label.textAlignment = UITextAlignmentCenter;
	
	if ([entry.name length] < 20) [label setText: [NSString stringWithFormat:@"%@   ", entry.name]];
	
	else if ([entry.name length] < 26) [label setText: [NSString stringWithFormat:@"%@", entry.name]];
	
	else [label setText:entry.name];
	
	self.navigationItem.titleView = label;
	
}


- (void) webNavAction:(id)sender
{
	UISegmentedControl* segCtl = sender;
	// the segmented control was clicked, handle it here 
	
	switch (segCtl.selectedSegmentIndex)
	{
		case 0:	{ // previous entry
			
			[myWebView goBack];
			
			break;
		}
			
		case 1: { // next entry
			[myWebView goForward];
			
			break;
		}
	}
}

- (void) updateWebNavBackButtonwithBack:(BOOL) back andForward: (BOOL) forward {
	
	NSString *backWebNavButtonImage;
	NSString *forwardWebNavButtonImage;
	
	if(back) 
		backWebNavButtonImage = @"back_active.png";
	
	
	else backWebNavButtonImage = @"back_inactive.png";
	
	if (forward)
		forwardWebNavButtonImage = @"forward_active.png";
	
	else forwardWebNavButtonImage = @"forward_inactive.png";
	
	
	UISegmentedControl *webNavControls = [[UISegmentedControl alloc] initWithItems:
										  [NSArray arrayWithObjects:
										   [UIImage imageNamed:backWebNavButtonImage],
										   [UIImage imageNamed:forwardWebNavButtonImage],
										   nil]];
	[webNavControls addTarget:self action:@selector(webNavAction:) forControlEvents:UIControlEventValueChanged];
	webNavControls.frame = CGRectMake(0, 0, 90, kCustomButtonHeight);
	webNavControls.segmentedControlStyle = UISegmentedControlStyleBar;
	webNavControls.momentary = YES;
	
	UIBarButtonItem * navBarItem = [[UIBarButtonItem alloc] initWithCustomView:webNavControls];
	
	
	self.navigationItem.rightBarButtonItem = navBarItem;

}



// yes this view can become first responder
- (BOOL)canBecomeFirstResponder {
	return YES;
}


// causes an occasional runtime crash
/*- (void) sendUpdateButtonMessage: (id) sender {
	
	[self.viewController upDateWebNavBackButtonwithBack: self.myWebView.canGoBack andForward: self.myWebView.canGoForward];
	
}*/


#pragma mark
#pragma mark Delegate Methods

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	
	//[self performSelector:@selector(removeLoadingAnimation:) withObject:nil afterDelay: 14];
	[self updateWebNavBackButtonwithBack:myWebView.canGoBack andForward:myWebView.canGoForward];
	
	if(errorLabel != nil) errorLabel.hidden = TRUE;
}


- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	
	NSURL *url = [request URL];
	
	NSLog(@"URL absolute string = %@", [url absoluteString]);
	
	if ([self isSutroMediaURL:[url absoluteString]]) {
		
		//** Code for handling links on Sutro Entry 
		//Need to add target app id on the the signature of the linkshare URL
		//Take advantage of the fact that sutro website gets called before linkshare referral
		//first strip app id from the sutro URL
		//then use it in the linkshare URL signature
		
		//get the target app id from the sutro page on the first run through
		
		NSArray *sutroURLArray = [[url resourceSpecifier] componentsSeparatedByString:@"target_app_id="];
		NSArray *linkshareURLArray = [[url absoluteString] componentsSeparatedByString:@"&u1="];
		
		NSLog(@"Sutro URL Array count = %i", [sutroURLArray count]);
		
		if ([sutroURLArray count] > 1) {
			
			targetAppID = [[sutroURLArray objectAtIndex:1] intValue];
			NSLog(@"Target App ID = %i", targetAppID);
			
			return YES;
		}
		
		//then use the target app id the next time this method gets called to construct the linkshare URL
		else if ([linkshareURLArray count] > 1) {
			
			NSLog(@"Linkshare base URL = %@", [linkshareURLArray objectAtIndex:0]);
			
			
			NSString *linkShareURLWithSignature = [[linkshareURLArray objectAtIndex:0] stringByAppendingString:[NSString stringWithFormat:@"&u1=%i", targetAppID]];
			
			appURL = [NSURL URLWithString:linkShareURLWithSignature];
			NSLog(@"Final URL = %@", appURL);
			NSLog(@"App store URL before clicking alert view button = %@", [appURL absoluteString]);
			
			[self showGoToAppStoreAlert: (nil)];
			
			return NO;
		}
		
		else if ([self isReviewURL:[url absoluteString]]) {
			
			[self goToExternalWebPageWithURL:url];
		}
	}
	
	return YES;
}


//Checks if a URL is a URL for buying a Sutro App

- (BOOL) isSutroMediaURL:(NSString*) urlString {
	
	if ([urlString length] >= 25) NSLog(@"Potential sutro string = %@", [urlString substringWithRange:NSMakeRange(7,17)]);
	
	if ([urlString length] <= 25) return NO;

	//http://www.sutromedia.com...	 
	else if([[urlString substringWithRange:NSMakeRange(11,10)] isEqualToString:@"sutromedia"]) return YES;
	
	//http://click.linksynergy.com... 
	else if([[urlString substringWithRange:NSMakeRange(7,17)] isEqualToString:@"click.linksynergy"]) return YES;
		 
	//http://itunes.apple.com/us/app/id337670530?mt=8&partnerId=30&siteID=MOZtzhoMa6E-oPJg_UGa8XWBI7eoIs3WyQ
	else if([[urlString substringWithRange:NSMakeRange(7,6)] isEqualToString:@"itunes"]) return YES;
		 
	//http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?
	else if([[urlString substringWithRange:NSMakeRange(7,6)] isEqualToString:@"phobos"]) return YES;	 
	
	else return NO;
}


- (BOOL) isReviewURL:(NSString*) urlString {
	
	if ([urlString length] <= 30) return NO;
	
	//http://sutromedia.com/review/...
	else if([[urlString substringWithRange:NSMakeRange(7,21)] isEqualToString:@"sutromedia.com/review"]) return YES;
	
	//http://www.sutromedia.com/review/...
	else if([urlString length] >= 33 && [[urlString substringWithRange:NSMakeRange(11,21)] isEqualToString:@"sutromedia.com/review"]) return YES;
	
	else return NO;
}


- (void) showGoToAppStoreAlert: (id) sender {
	
	NSLog(@"Got message to show go to app store alert");
	appStoreAlert = [[UIAlertView alloc] initWithTitle: nil message:@"This will leave the guide and open the App Store" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Go for it!", nil];
	[appStoreAlert show];
}


-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
	
	
	if(theAlert == appStoreAlert) { 
		if (buttonIndex != 0) {
			
			SMLog *log = [[SMLog alloc] initWithPageID: kEntryWebView actionID: kIVGoToAppStore];
			//log.entry_id = entry.entryid;
			log.target_app_id = targetAppID;
			[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
			
			[self goToExternalWebPageWithURL: appURL];
		}
		
		else {
			SMLog *log = [[SMLog alloc] initWithPageID: kEntryWebView actionID: kIVDontGoToAppStore];
			//log.entry_id = entry.entryid;
			log.target_app_id = targetAppID;
			[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
		}
	}
	
	else NSLog(@"ERROR: WebpageView, Alert not found.");
}


- (void)goToExternalWebPageWithURL:(NSURL*) webPageURL  {
	
	if (![[UIApplication sharedApplication] openURL:webPageURL])
	{
		NSLog(@"Error trying to open web page");
		
		SMLog *log = [[SMLog alloc] initWithPageID: kEntryWebView actionID: kIVErrorGoingToAppStore];
		//log.entry_id = entry.entryid;
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	}
	
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{		
	[self performSelector:@selector(removeLoadingAnimation:) withObject:nil afterDelay: 0];
	if(errorLabel != nil) errorLabel.hidden = TRUE;
	
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	
	[self performSelector:@selector(removeLoadingAnimation:) withObject:nil afterDelay: 0];
	
	if (error.code == 102);
	
	else if (error.code == 204) NSLog(@"Loading plug in to handle file");
	
	else if([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) [self showErrorMessageWithText:@"No internet connection.\nWebpage not available."];
        
    else [self showErrorMessageWithText:@"Webpage failed to load."];
	
	
	NSLog(@"WEBVIEWCONTROLLER.webView:didFailLoadWithError:error = %@ code = %i", error.localizedDescription, error.code);
}


- (void) goBack {
    
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark
#pragma mark Loading Icon Code 

- (void)showLoadingAnimation {
	
	float progressInd_x = ([Props global].screenWidth - kProgressIndicatorSize)/2 - 60;
	float progressInd_y = 150;
	
	CGRect frame = CGRectMake(progressInd_x, progressInd_y, kProgressIndicatorSize, kProgressIndicatorSize);
	progressInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
	
	[progressInd startAnimating];
	progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
	[progressInd sizeToFit];
	
	[self.view addSubview: progressInd];
	
	CGRect labelRect = CGRectMake (progressInd_x + 30, progressInd_y - 20, 150, kProgressIndicatorSize); //dunno why the -30 is needed for the y coordinate, but it works
	loadingTag = [[UILabel alloc] initWithFrame:labelRect];
	loadingTag.text = @"Loading webpage...";
	UIFont *font = [UIFont fontWithName: kFontName size:17];
	loadingTag.font = font;
	loadingTag.textColor = [UIColor grayColor];
	loadingTag.lineBreakMode = 0;
	loadingTag.numberOfLines = 5;
	loadingTag.backgroundColor = [UIColor clearColor];
	loadingTag.hidden = FALSE;
	
	[self.view addSubview:loadingTag];
}


- (void) removeLoadingAnimation: (id) sender {
	
	[progressInd stopAnimating];
	
	if(loadingTag != nil) loadingTag.hidden = TRUE;
}


- (void) showErrorMessageWithText:(NSString*) errorText {
	
	UIFont *errorFont = [UIFont fontWithName: kFontName size: 17];
	CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, 120);
	CGSize textBoxSize = [errorText sizeWithFont: errorFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
	
	CGRect imageUnderlayLabelRect = CGRectMake(([Props global].screenWidth - textBoxSize.width)/2, ([Props global].screenWidth - kTitleBarHeight - textBoxSize.height)/2 - 50, textBoxSize.width, textBoxSize.height);
	
	errorLabel = [[UILabel alloc] initWithFrame:imageUnderlayLabelRect];
	errorLabel.backgroundColor = [UIColor clearColor];
	errorLabel.numberOfLines = 5;
	errorLabel.textColor = [UIColor darkGrayColor];
	errorLabel.font = errorFont;
	errorLabel.text = errorText;
	errorLabel.textAlignment = UITextAlignmentCenter;
	errorLabel.hidden = FALSE;
	
	[self.view addSubview:errorLabel];
	
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
    if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        
        return YES;
    }
    
    else return NO;
	
    
	return YES;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    
	
	if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        [[Props global] updateScreenDimensions: interfaceOrientation];
	}
}


@end