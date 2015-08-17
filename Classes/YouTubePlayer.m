//
//  YouTubePlayer.m
//
//  Created by Robert on 18/12/2009.
//

#import "YouTubePlayer.h"
#import "SystemConfiguration/SCNetworkReachability.h"
#import <netinet/in.h>
#import "DataDownloader.h"
#import "Props.h"
#import "LocationViewController.h"

NSString * template = @"<pre><code><html><head>"
"<meta name = \"viewport\" content = \"initial-scale = 1.0, user-scalable = no, width = 212\"/></head>"
"<body style=\"background:#FFF;margin-top:0px;margin-left:0px\">"
"<div><object width=\"212\" height=\"172\">"
"<param name=\"movie\" value=\"http://www.youtube.com/v/%@&f=gdata_videos\"></param>"
"<param name=\"wmode\" value=\"transparent\"></param>"
"<embed src=\"http://www.youtube.com/v/%@&f=gdata_videos\""
"type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"212\" height=\"172\"></embed>"
"</object></div></body></html></pre></code>";

@interface YouTubePlayer (PrivateMethods)

- (UIButton *)findButtonInView:(UIView *)view;

- (Boolean) connectedToNetwork;

@end


@implementation YouTubePlayer

#pragma mark ---------------------------------------------------------
#pragma mark === End Constructor / Destructor Functions  ===
#pragma mark ---------------------------------------------------------

// -------------------------------------------------------------------
// Initialization
// -------------------------------------------------------------------



// ******* THIS DOES NOT WORK ON SIMULATOR ******************************************



- (id) initWithDelegate:(id) theDelegate
{
    self = [super init];
	if (self)
	{
		delegate = theDelegate;
		
		background = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
		[background setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f]];
		[background setOpaque:TRUE];
		[background setUserInteractionEnabled:FALSE];
		[background setClipsToBounds:FALSE]; 
		
		//NSLog(@"YOUTUBEPLAYER.initWithDelegate: background width = %f", background.frame.size.width);
		
		webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight)];
		[webView setHidden:TRUE];
		[webView setDelegate:self];
		
		activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[activityIndicator setHidesWhenStopped:FALSE];
		[activityIndicator setCenter:CGPointMake([Props global].screenWidth/2, [Props global].screenHeight/2)];
		
		[background addSubview:webView];
		[background addSubview:activityIndicator];
		[[DataDownloader sharedDataDownloader] pauseDownload];
	}
	
	return self;
}


// -------------------------------------------------------------------
// dealloc
// -------------------------------------------------------------------
- (void)dealloc 
{	
	NSLog(@"YOUTUBEPLAYER.dealloc");
	//IMPROVEMENT - there's probably a better place to put this, as data downloader pauses until the user leaves that entry
	[[DataDownloader sharedDataDownloader] resumeDownload];
	[background release];
	[webView release];
	[activityIndicator release];
	
    [super dealloc];
}

#pragma mark ---------------------------------------------------------
#pragma mark === End Constructor / Destructor Functions  ===
#pragma mark ---------------------------------------------------------

#pragma mark ---------------------------------------------------------
#pragma mark === Public Functions  ===
#pragma mark ---------------------------------------------------------

// -------------------------------------------------------------------
// trigger the video to playback
// -------------------------------------------------------------------
- (void) playbackVideo:(NSString*)_videoID InView:(UIView*)_view
{
	NSLog(@"YOUTUBEPLAYER.playbackVideo with ID: %@", _videoID);
    
    if (_videoID == nil) [delegate loadVideoWithoutYouTubePlayer];
	
    else {
        //[[_view window] addSubview:background];
        [_view addSubview:background];
        
        if ( [self connectedToNetwork] )
        {
            NSString * htmlString = [NSString stringWithFormat:template, _videoID, _videoID, nil];
            
            NSLog(@"YOUTUBEPLAYER.playbackVideo: HTML string = %@", htmlString);
            
            [webView loadHTMLString:htmlString baseURL:[NSURL URLWithString:@"http://youtube.com"]];
        }
        else 
        {
            UIAlertView * alert = [[UIAlertView alloc]
                                   initWithTitle:@"Error"
                                   message:@"Unable to download Movie."
                                   delegate:self
                                   cancelButtonTitle:@"Ok"
                                   otherButtonTitles:nil];
            
            [alert show];
            [alert release];
        }
    }
}

#pragma mark ---------------------------------------------------------
#pragma mark === End Public Functions  ===
#pragma mark ---------------------------------------------------------

#pragma mark ---------------------------------------------------------
#pragma mark === Private Functions  ===
#pragma mark ---------------------------------------------------------

// -------------------------------------------------------------------
// find the button in the view
// -------------------------------------------------------------------
- (UIButton *)findButtonInView:(UIView *)view 
{
	NSLog(@"YOUTUBEPLAYER.findButtonInView");
	
	UIButton *button = nil;
	
	if ([view isMemberOfClass:[UIButton class]]) {
		return (UIButton *)view;
	}
	
	if (view.subviews && [view.subviews count] > 0) {
		for (UIView *subview in view.subviews) {
			button = [self findButtonInView:subview];
			if (button) return button;
		}
	}
	
	return button;
}

// -------------------------------------------------------------------
// Check to see if we are connected to a network
// -------------------------------------------------------------------
- (Boolean) connectedToNetwork
{
	NSLog(@"YOUTUBEPLAYER.connectToNetwork");
	// Create zero addy 
	struct sockaddr_in zeroAddress; 
	bzero(&zeroAddress, sizeof(zeroAddress)); 
	zeroAddress.sin_len = sizeof(zeroAddress); 
	zeroAddress.sin_family = AF_INET;
	
	// Recover reachability flags 
	SCNetworkReachabilityRef defaultRouteReachability =	SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
	SCNetworkReachabilityFlags flags; BOOL didRetrieveFlags =
	SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags); CFRelease(defaultRouteReachability);
	if (!didRetrieveFlags) 
	{
		printf("Error. Could not recover network reachability flags\n"); 
		NSLog(@"YOUTUBEPLAYER.connectToNetwork: Could not connect to network");
		return NO;
	}
	BOOL isReachable = flags & kSCNetworkFlagsReachable; 
	BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired; 
	return (isReachable && !needsConnection) ? YES : NO;
}

#pragma mark ---------------------------------------------------------
#pragma mark === End Private Functions  ===
#pragma mark ---------------------------------------------------------

#pragma mark ---------------------------------------------------------
#pragma mark === UIWebViewDelegate Functions  ===
#pragma mark ---------------------------------------------------------

// -------------------------------------------------------------------
// Sent before a web view begins loading content
// -------------------------------------------------------------------
- (BOOL)webView:(UIWebView *)_webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSLog(@"%@", [[request mainDocumentURL] absoluteString] );
    NSLog(@"%@", request);
	return TRUE;
}

// -------------------------------------------------------------------
// Sent if a web view failed to load content.
// -------------------------------------------------------------------
- (void)webView:(UIWebView *)_webView didFailLoadWithError:(NSError *)error
{
	NSLog(@"YOUTUBEPLAYER.webView:(UIWebView *)_webView didFailLoadWithError:");
	UIApplication* app = [UIApplication sharedApplication]; 
	app.networkActivityIndicatorVisible = NO;
	[activityIndicator stopAnimating];
	
	// alert the user of the fail
	UIAlertView * alert = [[UIAlertView alloc]
						   initWithTitle:@"Error"
						   message:error.localizedDescription
						   delegate:self
						   cancelButtonTitle:@"Ok"
						   otherButtonTitles:nil];
	
	[alert show];
	[alert release];
}

// -------------------------------------------------------------------
// Sent after a web view starts loading content.
// -------------------------------------------------------------------
- (void)webViewDidStartLoad:(UIWebView *)_webView
{	
	NSLog(@"YOUTUBEPLAYER.webViewDidStartLoad:url = %@", _webView.request);
	UIApplication* app = [UIApplication sharedApplication]; 
	app.networkActivityIndicatorVisible = YES; // to stop it, set this to NO 
	[activityIndicator startAnimating];
}

// -------------------------------------------------------------------
// web view had finished loading
// -------------------------------------------------------------------
- (void)webViewDidFinishLoad:(UIWebView *)_webView 
{		
	NSLog(@"YOUTUBEPLAYER.webViewDidFinishLoad: url = %@", _webView.request);
	// remove the background
	//webView.hidden = FALSE;
	[background removeFromSuperview];
	
	// stop the activity indicators
	UIApplication* app = [UIApplication sharedApplication]; 
	app.networkActivityIndicatorVisible = NO;
	[activityIndicator stopAnimating];
	
	// trigger the youtube video to play
	UIButton *b = [self findButtonInView:_webView];
	
	if (b != nil && [b respondsToSelector:@selector(sendActionsForControlEvents:)]){
		
		NSLog(@"Button = %@", b);
		
		[b sendActionsForControlEvents:UIControlEventTouchUpInside];
	}
	
	else {
		NSLog(@"YOUTUBEPLAYER - Button equals nil");
		if ([delegate respondsToSelector:@selector(loadURL:)]) {
			NSLog(@"Sending message to delegate to load %@", _webView.request.URL);
            [delegate loadVideoWithoutYouTubePlayer];
		}
	}
}

#pragma mark ---------------------------------------------------------
#pragma mark === End UIWebViewDelegate Functions  ===
#pragma mark ---------------------------------------------------------

#pragma mark ---------------------------------------------------------
#pragma mark === UIAlertViewDelegate Functions  ===
#pragma mark ---------------------------------------------------------

// -------------------------------------------------------------------
// Deal with the alert view responce
// -------------------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[background removeFromSuperview];
}

#pragma mark ---------------------------------------------------------
#pragma mark === End UIAlertViewDelegate Functions  ===
#pragma mark ---------------------------------------------------------

@end
