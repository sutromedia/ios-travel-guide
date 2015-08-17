//
//  YouTubePlayer.h
//
//  Created by Robert on 18/12/2009.
//

#import <Foundation/Foundation.h>

@class LocationViewController;

@interface YouTubePlayer : NSObject <UIWebViewDelegate, UIAlertViewDelegate>
{
@private
	UIView	  *					background;
	UIWebView *					webView;
	UIActivityIndicatorView *	activityIndicator;
	LocationViewController		*delegate;
}

- (id) initWithDelegate:(LocationViewController*) theDelegate;
- (void) playbackVideo:(NSString*)_videoID InView:(UIView*)_view;

@end

