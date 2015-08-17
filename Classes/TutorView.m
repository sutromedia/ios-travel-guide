//
//  WelcomeView.m
//  TheProject
//
//  Created by Tobin1 on 12/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TutorView.h"
#import <QuartzCore/QuartzCore.h>

#define kBackgroundTag 2345234
#define kAnimationDwellTime 1.7
#define kBackgroundAlpha 0.65

@implementation TutorView


- (id)init {
    
    CGRect frame = CGRectZero;
    
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        background = [[UIView alloc] init];
        background.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        background.backgroundColor = [UIColor clearColor];
        background.alpha = 0.0;
        background.tag = kBackgroundTag;
        [self addSubview:background];
        
        backgroundFrame1 = CGRectMake(0, -([Props global].tableviewRowHeight_libraryView + 10), [Props global].screenWidth, [Props global].screenHeight + ([Props global].tableviewRowHeight_libraryView + 10) - [Props global].titleBarHeight);
        
        backgroundFrame2 = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - [Props global].titleBarHeight);
        
        
        background2 = [[UIView alloc] init];
        background2.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        background2.autoresizesSubviews = TRUE;
        background2.backgroundColor = [UIColor clearColor];
        background2.alpha = 0.0;
        background2.tag = kBackgroundTag;
        [self addSubview:background2];

        
        UIImage *welcome = [UIImage imageNamed:@"Welcome.png"];
        welcomeHolder = [[UIImageView alloc] initWithImage:welcome];
        [self addSubview:welcomeHolder];
        
        UIImage *quickTutorial = [UIImage imageNamed:@"QuickTutorial.png"];
        tutorialHolder = [[UIImageView alloc] initWithImage:quickTutorial];
        tutorialHolder.alpha = 0;
        [self addSubview:tutorialHolder];
        
    
        freeSample = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"free_sample.png"]];
        freeSample.alpha = 0;
        [self addSubview:freeSample];
        
        getMoreGuides = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"get_more_guides.png"]];
        getMoreGuides.alpha = 0;
        [self addSubview:getMoreGuides];
        
        resumeDownload = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"resume_download_2.png"]];
        resumeDownload.alpha = 0;
        [self addSubview:resumeDownload];
       
        swipeToDelete = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"swipe_to_delete.png"]];
        swipeToDelete.alpha = 0;
        [self addSubview:swipeToDelete];
        
        enjoy = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"enjoy.png"]];
        enjoy.alpha = 0;
        [self addSubview:enjoy];
        
        
        UIButton *tutorial = [UIButton buttonWithType:0];
        //[tutorial setImage:tutorialImage forState:UIControlStateNormal];
        
        [tutorial addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        tutorial.frame = self.frame;
        [self addSubview:tutorial];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange) name:kOrientationChange object:nil];
        [self orientationChange]; //Do this at start to set all frames
	
    }
    return self;
}


- (void) orientationChange {
    
    self.frame = CGRectMake(0, [Props global].titleBarHeight, [Props global].screenWidth, [Props global].screenHeight - [Props global].titleBarHeight);
    /*background.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight - [Props global].titleBarHeight);
    
    if (TRUE) {
        static NSMutableArray *colors = nil;
        
        if (colors == nil) {
            colors = [[NSMutableArray alloc] initWithCapacity:2];
            UIColor *color = nil;
            color = [UIColor colorWithWhite:0.0 alpha:kBackgroundAlpha];
            [colors addObject:(id)[color CGColor]];
            color = [UIColor colorWithWhite:0.0 alpha:kBackgroundAlpha * 1.1];
            [colors addObject:(id)[color CGColor]];
            color = [UIColor colorWithWhite:0.0 alpha:kBackgroundAlpha * 1.15];
            [colors addObject:(id)[color CGColor]];
            color = [UIColor colorWithWhite:0.0 alpha:kBackgroundAlpha * 1.2];
            [colors addObject:(id)[color CGColor]];
        }
        
        CAGradientLayer *maskLayer = [[CAGradientLayer alloc] init];
        maskLayer.frame = background.frame;
        [maskLayer setColors:colors];
        [maskLayer setStartPoint:CGPointMake(0.5, 0.0)];
        [maskLayer setEndPoint:CGPointMake(0.5, 1.0)];
        //float fullOpacityLocation = fadeWidth/maskLayer.frame.size.width;
        float transition2 = 0.75;
        float transitionWidth = 0.05;
        
        [maskLayer setLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:transition2 - transitionWidth], [NSNumber numberWithFloat:transition2 + transitionWidth], [NSNumber numberWithFloat:1.0], nil]];
        [background.layer addSublayer: maskLayer];
    }*/
    
    
    background2.frame = backgroundFrame1;
    static NSMutableArray *colors = nil;
    
    if (colors == nil) {
        colors = [[NSMutableArray alloc] initWithCapacity:2];
        UIColor *color = nil;
        color = [UIColor colorWithWhite:0.0 alpha:0.2];
        [colors addObject:(id)[color CGColor]];
        color = [UIColor colorWithWhite:0.0 alpha:0.2];
        [colors addObject:(id)[color CGColor]];
        color = [UIColor colorWithWhite:0.0 alpha:kBackgroundAlpha];
        [colors addObject:(id)[color CGColor]];
        color = [UIColor colorWithWhite:0.0 alpha:kBackgroundAlpha * 1.1];
        [colors addObject:(id)[color CGColor]];
        color = [UIColor colorWithWhite:0.0 alpha:kBackgroundAlpha * 1.15];
        [colors addObject:(id)[color CGColor]];
        color = [UIColor colorWithWhite:0.0 alpha:kBackgroundAlpha * 1.2];
        [colors addObject:(id)[color CGColor]];
    }
    
    CAGradientLayer *maskLayer = [[CAGradientLayer alloc] init];
    maskLayer.frame = CGRectMake(0,0,backgroundFrame1.size.width, backgroundFrame1.size.height);
    [maskLayer setColors:colors];
    [maskLayer setStartPoint:CGPointMake(0.5, 0.0)];
    [maskLayer setEndPoint:CGPointMake(0.5, 1.0)];
    //float fullOpacityLocation = fadeWidth/maskLayer.frame.size.width;
    float transition1 = ([Props global].tableviewRowHeight_libraryView)/self.frame.size.height;
    float transition2 = 0.75;
    float transitionWidth = 0.01;
    
    [maskLayer setLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:transition1 - transitionWidth], [NSNumber numberWithFloat:transition1 + transitionWidth], [NSNumber numberWithFloat:transition2 - transitionWidth], [NSNumber numberWithFloat:transition2 + transitionWidth], [NSNumber numberWithFloat:1.0], nil]];
    [background2.layer addSublayer: maskLayer];

    
    //Set position for "Welcome"
    float width = powf([Props global].screenWidth, 0.95);
    float height = welcomeHolder.frame.size.height * width/welcomeHolder.frame.size.width;
    //CGAffineTransform oldTransform = welcomeHolder.transform;
    //welcomeHolder.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    welcomeHolder.frame = CGRectMake((self.frame.size.width - width)/2, (self.frame.size.height - height)/2.4, width, height);
    
    //"Here's a quick tutorial"
    width = powf([Props global].screenWidth, 0.96);
    height = tutorialHolder.frame.size.height * width/tutorialHolder.frame.size.width;
    tutorialHolder.frame = CGRectMake(([Props global].screenWidth - width)/2, (self.frame.size.height - height)/2.4, width, height);
    
    width = [Props global].screenWidth/2.2;
    height = freeSample.frame.size.height * width/freeSample.frame.size.width;
    freeSample.frame = CGRectMake([Props global].leftMargin * .6, [Props global].tableviewRowHeight_libraryView * .7, width, height);
    
    width = [Props global].screenWidth/2.7;
    height = resumeDownload.frame.size.height * width/resumeDownload.frame.size.width;
    resumeDownload.frame = CGRectMake(self.frame.size.width - width - [Props global].leftMargin * .8, [Props global].tableviewRowHeight_libraryView/2, width, height);
    
    width = [Props global].screenWidth/2.2;
    height = getMoreGuides.frame.size.height * width/getMoreGuides.frame.size.width;
    getMoreGuides.frame = CGRectMake(self.frame.size.width - width - [Props global].leftMargin * 3, 0, width, height);
    
    width = [Props global].screenWidth/1.2;
    height = swipeToDelete.frame.size.height * width/swipeToDelete.frame.size.width;
    swipeToDelete.frame = CGRectMake((self.frame.size.width - width)/2, [Props global].tableviewRowHeight_libraryView/2.3, width, height);
    
    width = powf([Props global].screenWidth, 0.92);
    height = enjoy.frame.size.height * width/enjoy.frame.size.width;
    enjoy.frame = CGRectMake((self.frame.size.width - width)/2, (self.frame.size.height - height)/2.4, width, height);
    
}


- (void) startAnimation {
    
    welcomeHolder.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showTutorialMessage)];
    
    welcomeHolder.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    background2.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showTutorialMessage {
    
    //start.enabled = TRUE;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kAnimationDwellTime];
	[UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showFreeSample)];
    
    welcomeHolder.alpha = 0;
    tutorialHolder.alpha = 1.0;
   // tapToStart.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showFreeSample {
    
    //start.enabled = TRUE;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kAnimationDwellTime];
	[UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showResumeDownload)];
    
    freeSample.alpha = 1.0;
    background2.frame = backgroundFrame2;
    //background2.alpha = 1.0;
    //background.alpha = 0.0;
    tutorialHolder.alpha = 0.0;
    
    [UIView commitAnimations];
}


- (void) showResumeDownload {
    
    //start.enabled = TRUE;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kAnimationDwellTime];
	[UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showSwipeToDelete)];
    
    getMoreGuides.alpha = 0.0;
    freeSample.alpha = 0.0;
    resumeDownload.alpha = 1.0;
    //background2.alpha = 1.0;
    //background.alpha = 0.0;
    background2.frame = backgroundFrame2;
    
    [UIView commitAnimations];
}


- (void) showSwipeToDelete {
    
    //start.enabled = TRUE;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kAnimationDwellTime];
	[UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showGetMoreGuides)];
    
    swipeToDelete.alpha = 1.0;
    resumeDownload.alpha = 0.0;
    
    [UIView commitAnimations];
}


- (void) showGetMoreGuides {
    
    //start.enabled = TRUE;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kAnimationDwellTime];
	[UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showEnjoy)];
    
    getMoreGuides.alpha = 1.0;
    freeSample.alpha = 0.0;
    swipeToDelete.alpha = 0.0;
    //background2.alpha = 0.0;
    //background.alpha = 1.0;
    background2.frame = backgroundFrame1;
    
    [UIView commitAnimations];
}



- (void) showEnjoy {
    
    //start.enabled = TRUE;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kAnimationDwellTime];
	[UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(hide)];
    
    swipeToDelete.alpha = 0.0;
    getMoreGuides.alpha = 0.0;
    background2.frame = backgroundFrame1;
    //background2.alpha = 0.0;
    //background.alpha = 1.0;
    enjoy.alpha = 1.0;
    
    [UIView commitAnimations];
}




- (void) hide {
	
	[ UIView beginAnimations: nil context: nil ]; 
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseIn ];
    [UIView setAnimationDelay:kAnimationDwellTime];
	[ UIView setAnimationDuration: 0.4f ]; 
	
	self.transform = CGAffineTransformMakeScale(0.001, 0.001);
	self.alpha = 0;
	
	[ UIView commitAnimations ];
	
	[self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:3];
}


- (void) dealloc {
    
   [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
