//
//  SMPopUp.m
//  TheProject
//
//  Created by Tobin Fisher on 1/10/12.
//  Copyright (c) 2012 Sutro Media. All rights reserved.
//

#import "SMPopUp.h"
#import <QuartzCore/QuartzCore.h>

@interface SMPopUp (Private)

- (void) createView;

@end

@implementation SMPopUp

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self createView];
    }
    return self;
}

- (void) createView {
    
	@autoreleasepool {
	
        UIView *waitingBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        waitingBackground.opaque = NO;
        waitingBackground.backgroundColor = [UIColor clearColor];
        //waitingBackground.tag = kThankYouTag;
        
	CALayer *backgroundLayer = [[CALayer alloc] init];
        backgroundLayer.borderColor = [UIColor blackColor].CGColor;
        backgroundLayer.borderWidth = 2;
        backgroundLayer.cornerRadius = 12;
        backgroundLayer.backgroundColor = [UIColor blackColor].CGColor;
        backgroundLayer.opacity = 0.4;
        backgroundLayer.shadowOpacity = 0.8;
        backgroundLayer.shadowColor = [UIColor blackColor].CGColor;
        backgroundLayer.shadowOffset = CGSizeMake(2, 2);
        backgroundLayer.bounds = waitingBackground.bounds;
        backgroundLayer.position = CGPointMake([waitingBackground bounds].size.width/2, [waitingBackground bounds].size.height/2);
        [waitingBackground.layer addSublayer:backgroundLayer];
        
        [self addSubview: waitingBackground];
    
	}
}


- (void) hideMessage {
    
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.1];
    
    /*for (UIView *view in [self subviews]) {
        if (view.tag == kWaitingForAppStoreMessageTag || view.tag == kThankYouTag) view.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    }*/
    
    [UIView commitAnimations];
    
    [self performSelector:@selector(removeMessage) withObject:nil afterDelay:0.1];
}


- (void) removeMessage {
    
    /*for (UIView *view in [self subviews]) {
        if (view.tag == kWaitingForAppStoreMessageTag || view.tag == kThankYouTag) [view removeFromSuperview];
    }*/
    
    [self setNeedsDisplay];
}


@end
