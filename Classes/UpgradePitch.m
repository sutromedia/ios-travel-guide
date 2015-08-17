//
//  UpgradePitch.m
//  TheProject
//
//  Created by Tobin Fisher on 11/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UpgradePitch.h"
#import <QuartzCore/QuartzCore.h>

@interface UpgradePitch (Private) 

- (NSString*) generateHTMLWithMessage:(NSString*) theMessage;

@end

@implementation UpgradePitch


- (id)initWithYPos:(float) yPos andMessage:(NSString*) theMessage {
    
    //float height = [Props global].screenWidth > 400 ? 20 : 33; 
    CGRect frame = CGRectMake(0, yPos, [Props global].screenWidth, 27);
    
    self = [super initWithFrame:frame];
    if (self) {
        
        self.scalesPageToFit = NO;
		//self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		self.delegate = self;	
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = FALSE;
        [self loadHTMLString:[self generateHTMLWithMessage:theMessage] baseURL:nil];
        
        background = [[CALayer alloc] init];
        background.backgroundColor = [UIColor blackColor].CGColor;
        background.shadowColor = [UIColor blackColor].CGColor;
        background.shadowOffset = CGSizeMake(0, 2);
        background.opacity = 0.6;
        background.opaque = NO;
        background.shadowOpacity = 1.0;
        background.frame = CGRectMake(-5, 0, [Props global].screenWidth + 10, frame.size.height);
        [self.layer insertSublayer:background atIndex:0];

        
        hideButton = [UIButton buttonWithType:0];
        float buttonWidth = 30;
        hideButton.frame = CGRectMake(frame.size.width - buttonWidth + 5, -5, buttonWidth, buttonWidth);
        hideButton.backgroundColor = [UIColor clearColor];
        hideButton.alpha = 0.3;
        hideButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
        [hideButton setTitle:@"✕" forState:UIControlStateNormal];
        [hideButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:hideButton];
        
    }
    
    return self;
}


- (void) dealloc {
    
    self.delegate = nil;
}


- (void) layoutSubviews {
    
    background.frame = CGRectMake(-5, 0, [Props global].screenWidth + 10, self.frame.size.height);
}


- (void) hide {
    
    NSLog(@"Time to hide");
    
    hideButton.hidden = TRUE;
    
    float animationDuration = 0.5;
    
    [ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
	[ UIView setAnimationDuration: animationDuration ]; // Set the duration
	
    background.frame = CGRectMake(0, 0, self.frame.size.width, 0);
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 0);
    [self setNeedsDisplay];
	
	[ UIView commitAnimations ];
}


- (NSString*) generateHTMLWithMessage:(NSString*) theMessage {
    
    //box-shadow: 0px 3px 3px rgba(0, 0, 0, 0.8);
    //background-color:rgba(0,0,0,0.7);
    
    NSString *header = [NSString stringWithFormat:@"\
                        <html><head><title>Sutro Media</title>\
                        <style type=\"text/css\">\
                        A:link{text-decoration: none; -webkit-tap-highlight-color:rgba(0,0,0,0); opacity:1.0;}\
                        .SMUpgradeLink{font-weight:700; color:%@; opacity:1.0;}\
                        body{padding:0; font-family:'Arial'; font-size:16px; padding:0; margin:5px %0.1fpx 0px %0.1fpx; border:0; color:#CCCCCC; opacity:0.75; text-align:center;}\
                        </style>\
                        </head><body>\
                        <div id='pageContent'>\
                        ", [Props global].cssLinkColor, [Props global].rightMargin, [Props global].leftMargin];    
    
    NSString *htmlDescription = theMessage; //@"<a class='SMUpgradeLink' href='SMUpgradeLink://1'>Upgrade</a>&nbsp;for&nbsp;full&nbsp;offline&nbsp;access";
    
    
    NSString *footer = @"</div></body></html>";
    
    NSString *formattedString = [NSString stringWithFormat:@"%@%@%@",header,htmlDescription,footer];
    
    //NSLog(@"Formatted string = %@", formattedString);
    
    return formattedString;
}



- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        
        NSString *scheme = [request.URL scheme];
        
        if ([scheme caseInsensitiveCompare:@"SMUpgradeLink"] == NSOrderedSame) {
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowUpgrade object:nil userInfo:nil];
            NSLog(@"Time to go to settings");
            //if ([self.delegate respondsToSelector:@selector(showSettings)]) [self.delegate showSettings];
            //[self goToEntry:entryID];
            return NO;
        }
    }
    
    return YES;
}




@end
