//
//  untitled.m
//  TheProject
//
//  Created by Tobin1 on 2/18/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import "SMRichTextViewer.h"
#import "Props.h"


@implementation SMRichTextViewer

@synthesize contentSize;

//static int counter = 0;

- init {
    
    self = [super initWithFrame:CGRectZero];
	if (self) {
		
		self.scalesPageToFit = NO;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		self.dataDetectorTypes = UIDataDetectorTypePhoneNumber;
		
		if([[[[UIDevice currentDevice] systemVersion] substringToIndex:3] floatValue] >= 3.2){
			
			UIScrollView *scrollView = [[self subviews] lastObject];
			scrollView.scrollEnabled = FALSE;
		}
	}
	
	return self;
}


- (void) dealloc {
	
	NSLog(@"SMRICHTEXTVIEW.dealloc");
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
}


- (void) emptyMemoryCache {
	
	if([NSURLCache sharedURLCache].currentMemoryUsage > (500 * 1024)) { //only empty cache if it's got 500 kb or more in there
		NSLog(@"SMRICHTEXTVIEWER.emptyMemoryCache with memory usage = %i kb", [NSURLCache sharedURLCache].currentMemoryUsage/1024); 
		[[NSURLCache sharedURLCache] removeAllCachedResponses];
	}
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	
	//NSLog(@"Looks like blank webpage finished loading");
}


@end
