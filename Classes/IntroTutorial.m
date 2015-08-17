//
//  IntroTutorial.m
//  TheProject
//
//  Created by Tobin Fisher on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IntroTutorial.h"
#import <QuartzCore/QuartzCore.h>
#import "EntriesTableViewController.h"

#define kTabLabelTransform 0.4
#define kTabLabelShrinkTime 0.3
#define kTabLabelDwellTime 0.8
#define kBulletPointDwell 0.4 //Time in seconds to dwell on each upgrade bullet point
#define kBulletPointFadeIn 0.5 //Time to face in bullet point
#define kBackgroundTag 2345234
#define kButtonOverlayTag 635436

@implementation IntroTutorial

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        //self.alpha = 0.75;
        //self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        UIView *background = [[UIView alloc] initWithFrame:self.frame];
        background.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        background.backgroundColor = [UIColor blackColor];
        background.alpha = 0.7;
        background.tag = kBackgroundTag;
        [self addSubview:background];
        
        filterAndSort = nil;
        
        UIImage *welcome = [UIImage imageNamed:@"Welcome.png"];
        welcomeHolder = [[UIImageView alloc] initWithImage:welcome];
        [self addSubview:welcomeHolder];
        
        UIImage *quickTutorial = [UIImage imageNamed:@"QuickTutorial.png"];
        tutorialHolder = [[UIImageView alloc] initWithImage:quickTutorial];
        tutorialHolder.alpha = 0;
        [self addSubview:tutorialHolder];
        
        UIImage *tapToStartImage = [UIImage imageNamed:@"tapToStart.png"];
        tapToStart = [[UIImageView alloc] initWithImage:tapToStartImage];
        tapToStart.alpha = 0;
        [self addSubview:tapToStart];
        
        UIImage *tapToHideImage = [UIImage imageNamed:@"tapToHide.png"];
        tapToHide = [[UIImageView alloc] initWithImage:tapToHideImage];
        tapToHide.alpha = 0;
        [self addSubview:tapToHide];
        
        UIImage *exploreUsing = [UIImage imageNamed:@"ExploreUsing.png"];
        exploreHolder = [[UIImageView alloc] initWithImage:exploreUsing];
        exploreHolder.alpha = 0;
        [self addSubview:exploreHolder];
        
        
        UIImage *image = [UIImage imageNamed:@"sortableList.png"];
        sortableList = [[UIImageView alloc] initWithImage:image];
        //width = image.size.width * height/image.size.height;
        sortableList.alpha = 0;
        [self addSubview:sortableList];
        
        UIImage *image2 = [UIImage imageNamed:@"picturesOfEverything.png"];
        picturesOfEverything = [[UIImageView alloc] initWithImage:image2];
        //width = image2.size.width * height/image2.size.height;
        picturesOfEverything.alpha = 0;
        [self addSubview:picturesOfEverything];
        
        if ([Props global].hasLocations) {
            UIImage *image3 = [UIImage imageNamed:@"locationsOnMap.png"];
            locationsOnMap = [[UIImageView alloc] initWithImage:image3];
            //width = image3.size.width * height/image3.size.height;
            locationsOnMap.alpha = 0;
            [self addSubview:locationsOnMap];
        }
        
        
        UIImage *image4 = [UIImage imageNamed:@"comments.png"];
        comments = [[UIImageView alloc] initWithImage:image4];
        //width = image4.size.width * height/image4.size.height;
        comments.alpha = 0;
        [self addSubview:comments];
        
        if ([Props global].hasDeals) {
            UIImage *image4a = [UIImage imageNamed:@"localDeals.png"];
            deals = [[UIImageView alloc] initWithImage:image4a];
            //width = image4a.size.width * height/image4a.size.height;
            deals.alpha = 0;
            [self addSubview:deals];
        }
        
        UIImage *image5 = [UIImage imageNamed:@"sort.png"];
        sort = [[UIImageView alloc] initWithImage:image5];
        sort.alpha = 0;
        [self addSubview:sort];
        
        UIImage *image6 = [UIImage imageNamed:@"upgrade.png"];
        upgrade = [[UIImageView alloc] initWithImage:image6];
        upgrade.alpha = 0;
        [self addSubview:upgrade];
        
        UIImage *image7 = [UIImage imageNamed:@"andGet.png"];
        andGet = [[UIImageView alloc] initWithImage:image7];
        andGet.alpha = 0;
        [self addSubview:andGet];
        
        
        UIImage *image8 = [UIImage imageNamed:@"offlineEverything.png"];
        offlineEverything = [[UIImageView alloc] initWithImage:image8];
        offlineEverything.alpha = 0;
        [self addSubview:offlineEverything];
        
        UIImage *image9 = [UIImage imageNamed:@"fullContentSearch.png"];
        search = [[UIImageView alloc] initWithImage:image9];
        search.alpha = 0;
        [self addSubview:search];
        
        UIImage *image10 = [UIImage imageNamed:@"saveFavs.png"];
        saveFavs = [[UIImageView alloc] initWithImage:image10];
        saveFavs.alpha = 0;
        [self addSubview:saveFavs];
        
        UIImage *image11 = [UIImage imageNamed:@"noAds.png"];
        noAds = [[UIImageView alloc] initWithImage:image11];
        noAds.alpha = 0;
        [self addSubview:noAds];
        
        morePictures = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"morePictures.png"]];
        morePictures.alpha = 0;
        [self addSubview:morePictures];
        
        UIImage *image12 = [UIImage imageNamed:@"happyAuthor.png"];
        happyAuthor = [[UIImageView alloc] initWithImage:image12];
        happyAuthor.alpha = 0;
        [self addSubview:happyAuthor];
        
        UIImage *image12a = [UIImage imageNamed:@"settings.png"];
        settings = [[UIImageView alloc] initWithImage:image12a];
        settings.alpha = 0;
        [self addSubview:settings];
        
        settings2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"settings2.png"]];
        settings2.alpha = 0;
        [self addSubview:settings2];
        
        if ([Props global].isShellApp) {
            
            goHome = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"goHome.png"]];
            goHome.alpha = 0;
            [self addSubview:goHome];
        }
        
        UIImage *image13 = [UIImage imageNamed:@"enjoy.png"];
        enjoy = [[UIImageView alloc] initWithImage:image13];
        enjoy.alpha = 0;
        [self addSubview:enjoy];
        
        if ([Props global].isShellApp || [Props global].freemiumType != kFreemiumType_V1) {
            hide = [UIButton buttonWithType:0];
            [hide addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
            hide.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
            hide.frame = self.frame;
            hide.tag = kButtonOverlayTag;
            hide.enabled = FALSE;
            hide.backgroundColor = [UIColor clearColor];
            hide.alpha = 0.5;
            [self addSubview:hide];
        }
        
        start = [UIButton buttonWithType:0];
        [start addTarget:self action:@selector(startTutorial) forControlEvents:UIControlEventTouchUpInside];
        start.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        start.frame = self.frame;
        start.enabled = FALSE;
        [self addSubview:start];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange) name:kOrientationChange object:nil];
        [self orientationChange]; //Do this at start to set all frames
    }
    
    return self;
}


- (void) dealloc {
    
    NSLog(@"INTROTUTORIAL.dealloc");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}


- (void) orientationChange {
    
    NSLog(@"IntroTutorial.orientationChange. Frame height = %f", self.frame.size.height);
    float frameHeight = [Props global].screenHeight - [Props global].titleBarHeight - kTabBarHeight;
    if([Props global].deviceType != kiPad && [[Props global] inLandscapeMode]) frameHeight += kPartialHideTabBarHeight;
    self.frame = CGRectMake(0, 0, [Props global].screenWidth, frameHeight);
    
    NSLog(@"Screen width = %f", self.frame.size.width);
    
    int numberOfTabs = 3;
    if ([Props global].hasLocations) numberOfTabs ++;
    if ([Props global].hasDeals) numberOfTabs ++;
    
    float andGetHeight, upgradeHeight, labelWidth, exploreHeight;
    
    if ([Props global].deviceType == kiPad) {
        
        tabWidth = 76; 
        tabSpacing = 35;
        tabOffset = ([Props global].screenWidth - numberOfTabs * tabWidth - tabSpacing * (numberOfTabs - 1))/2;
        NSLog(@"tab offset = %0.0f, tab width = %0.0f", tabOffset, tabWidth);
        //if[[Props global] inLandscapeMode]) ? 256 : 120;
        labelWidth = tabWidth * 2.2;
        andGetHeight = [[Props global] inLandscapeMode] ? 85 : 90;
        upgradeHeight = [[Props global] inLandscapeMode] ? 250: 200;
        exploreHeight = 80;
        
        /*
        UIView *test2 = [[UIView alloc] initWithFrame:CGRectMake(tabOffset, 0, tabWidth, [Props global].screenHeight)];
        test2.backgroundColor = [UIColor greenColor];
        test2.alpha = 0.2;
        [self addSubview:test2];
        [test2 release];*/
    }
    
    else {
        tabOffset = 0;
        tabSpacing = 0;
        tabWidth = (self.frame.size.width - tabOffset * 2)/(float)numberOfTabs;
        labelWidth = [[Props global] inLandscapeMode] ? tabWidth * 1.3 : tabWidth * 2.2;

        andGetHeight = [[Props global] inLandscapeMode] ? 40 : 42;
        upgradeHeight = [[Props global] inLandscapeMode] ? 120 : 110;
        exploreHeight = [[Props global] inLandscapeMode] ? 40 : 40;
    }
    
    //Set position for "Welcome"
    float width = powf([Props global].screenWidth, 0.89);
    float height = welcomeHolder.frame.size.height * width/welcomeHolder.frame.size.width;
    //CGAffineTransform oldTransform = welcomeHolder.transform;
    //welcomeHolder.transform = CGAffineTransformMakeScale(1.0f, 1.0f); 
    welcomeHolder.frame = CGRectMake((self.frame.size.width - width)/2, powf((self.frame.size.height - height),.55), width, height);
    
    //"Here's a quick tutorial" and "Tap to start"
    width = powf([Props global].screenWidth, 0.93);
    height = tutorialHolder.frame.size.height * width/tutorialHolder.frame.size.width;
    tutorialHolder.frame = CGRectMake(([Props global].screenWidth - width)/2, (self.frame.size.height - height)/2, width, height);
    
    width = tutorialHolder.frame.size.width * 0.9;
    height = tapToStart.frame.size.height * width/tapToStart.frame.size.width;
    tapToStart.frame = CGRectMake(([Props global].screenWidth - width)/2, CGRectGetMaxY(tutorialHolder.frame) + 5, width, height);
    
    int tabNumber = 0;
    
    height = sortableList.frame.size.height * labelWidth/sortableList.frame.size.width;
    sortableList.frame = CGRectMake(0, 0, labelWidth, height);
    if (tabOffset == 0) {
        sortableList.layer.anchorPoint = CGPointMake(0.5, 1);
        sortableList.center = CGPointMake(labelWidth/2, self.frame.size.height);
    }
    
    else {
        sortableList.layer.anchorPoint = CGPointMake(0.5, 1);
        sortableList.center = CGPointMake(tabOffset + tabWidth/2, self.frame.size.height);
    }
    tabNumber ++;
    
    height = picturesOfEverything.frame.size.height * labelWidth/picturesOfEverything.frame.size.width;
    picturesOfEverything.layer.anchorPoint = CGPointMake(0.5, 1);
    picturesOfEverything.frame = CGRectMake(0, 0, labelWidth, height);
    picturesOfEverything.center = CGPointMake(tabOffset + (tabWidth + tabSpacing) * tabNumber + tabWidth/2, self.frame.size.height);
    tabNumber ++;
    
    if ([Props global].hasLocations) {
        height = locationsOnMap.frame.size.height * labelWidth/locationsOnMap.frame.size.width;
        locationsOnMap.layer.anchorPoint = CGPointMake(0.5, 1);
        locationsOnMap.frame = CGRectMake(0, 0, labelWidth, height);
        locationsOnMap.center = comments.center = CGPointMake(tabOffset + (tabWidth + tabSpacing) * tabNumber + tabWidth/2, self.frame.size.height);
        tabNumber ++;
    }
    
    height = comments.frame.size.height * labelWidth/comments.frame.size.width;
    
    comments.frame = CGRectMake(0, 0, labelWidth, height);
    comments.layer.anchorPoint = CGPointMake(0.5, 1);
    
    if ([Props global].deviceType != kiPad && ![Props global].hasDeals) //we are not on an ipad and this is the rightmost tab
        comments.center = CGPointMake(self.frame.size.width - labelWidth * .47, self.frame.size.height);
            
    else comments.center = CGPointMake(tabOffset + (tabWidth + tabSpacing) * tabNumber + tabWidth/2, self.frame.size.height);

    
    tabNumber ++;
    
    if ([Props global].hasDeals) {
        height = deals.frame.size.height * labelWidth/deals.frame.size.width;
        deals.frame = CGRectMake(0, 0, labelWidth, height);
        
        if (tabOffset == 0) { //ie we are not on an ipad
            deals.layer.anchorPoint = CGPointMake(.7, 1);
            deals.center = CGPointMake(self.frame.size.width - tabOffset - labelWidth * .1, self.frame.size.height);
        }
        
        else {
            deals.layer.anchorPoint = CGPointMake(.5, 1);
            deals.center = CGPointMake(tabOffset + (tabWidth + tabSpacing) * tabNumber + tabWidth/2, self.frame.size.height);
        }
        
        tabNumber ++;
    }
    
    
    //width = [Props global].screenWidth/1.5;
    //height = exploreHolder.frame.size.height * width/exploreHolder.frame.size.width;
    //height = [Props global].screenHeight/10;
    width = exploreHolder.frame.size.width * exploreHeight/exploreHolder.frame.size.height;
    exploreHolder.frame = CGRectMake(([Props global].screenWidth - width)/2, sortableList.frame.origin.y - exploreHeight - self.frame.size.height/15, width, exploreHeight);

    
    if (filterAndSort != nil) {
        [filterAndSort removeFromSuperview];
        filterAndSort = nil;
    }
    
    NSString *imageName = [Props global].deviceType == kiPad || [[Props global] inLandscapeMode] ? @"filter" : @"filterAndSort";
    UIImage *image5 = [UIImage imageNamed:imageName];
    filterAndSort = [[UIImageView alloc] initWithImage:image5];
    filterAndSort.alpha = 0;
    [self addSubview:filterAndSort];
    width = [Props global].screenWidth/2;
    height = filterAndSort.frame.size.height * width/filterAndSort.frame.size.width;
    filterAndSort.frame = CGRectMake([Props global].leftMargin, 0, width, height);
    
    if ([Props global].deviceType == kiPad || [[Props global] inLandscapeMode]) {
        
        width = [Props global].screenWidth/2.2;
        height = sort.frame.size.height * width/sort.frame.size.width;
        sort.frame = CGRectMake((self.frame.size.width - width)/2, 0, width, height);
        sort.hidden = FALSE;
    }
    
    else sort.hidden = TRUE;
    
    width = 50 + [Props global].screenWidth/2.7;
    height = settings.frame.size.height * width/settings.frame.size.width;
    float x_pos = [Props global].screenWidth - width - [Props global].leftMargin;
    if ([Props global].isShellApp) x_pos -= [Props global].titleBarHeight * .55 + 15;
    settings.frame = CGRectMake(x_pos, 0, width, height);
    
    width = 80 + [Props global].screenWidth/1.8;
    height = settings2.frame.size.height * width/settings2.frame.size.width;
    settings2.frame = CGRectMake([Props global].screenWidth - width - [Props global].leftMargin, 0, width, height);
    
    if ([Props global].isShellApp) {
        width = 80 + [Props global].screenWidth/1.8;
        height = goHome.frame.size.height * width/goHome.frame.size.width;
        goHome.frame = CGRectMake([Props global].screenWidth - width - [Props global].leftMargin, 0, width, height);
    }
    
    width = upgrade.frame.size.width * upgradeHeight/upgrade.frame.size.height; //145; //[Props global].screenWidth/2.2;
    CGAffineTransform transform = upgrade.transform;
    upgrade.layer.anchorPoint = CGPointMake(0.8, 0);
    upgrade.transform = CGAffineTransformMakeScale(1, 1);
    upgrade.frame = CGRectMake([Props global].screenWidth - width - [Props global].leftMargin, 0, width, upgradeHeight);
    upgrade.transform = transform;
    //NSLog(@"Upgrade transform = %f, %f, %f, %f", upgrade.transform.a, upgrade.transform.b, upgrade.transform.c, upgrade.transform.d);
    
    //height = self.frame.size.height/8; //andGet.frame.size.height * width/andGet.frame.size.width;
    width = andGet.frame.size.width * andGetHeight/andGet.frame.size.height; //128; //[Props global].screenWidth/2.5;
    float xPos = [Props global].screenWidth/25;
    andGet.frame = CGRectMake(xPos, self.frame.size.height * .11, width, andGetHeight);
    
    width = powf(self.frame.size.width, .91); //[Props global].screenWidth/1.5;
    height = tapToHide.frame.size.height * width/tapToHide.frame.size.width;
    tapToHide.frame = CGRectMake(([Props global].screenWidth - width)/2, self.frame.size.height - height - self.frame.size.height/25, width, height);
    
    
    xPos = andGet.frame.origin.x;
    float totalLineHeight = andGet.frame.size.height * .9; //(tapToHide.frame.origin.y - CGRectGetMaxY(andGet.frame) - self.frame.size.height/14)/5;
    //if (totalLineHeight > andGet.frame.size.height) totalLineHeight = andGet.frame.size.height * .9;
    float textHeight = totalLineHeight * .9;
    float vSpace = totalLineHeight * .1;
    
    width = offlineEverything.frame.size.width * textHeight/offlineEverything.frame.size.height;
    offlineEverything.frame = CGRectMake(xPos, CGRectGetMaxY(andGet.frame) + vSpace, width, textHeight);
    
    width = search.frame.size.width * textHeight/search.frame.size.height;
    search.frame = CGRectMake(xPos, CGRectGetMaxY(offlineEverything.frame) + vSpace, width, textHeight);
    
    width = saveFavs.frame.size.width * textHeight/saveFavs.frame.size.height;
    saveFavs.frame = CGRectMake(xPos, CGRectGetMaxY(search.frame) + vSpace, width, textHeight);
    
    width = noAds.frame.size.width * textHeight/noAds.frame.size.height;
    noAds.frame = CGRectMake(xPos, CGRectGetMaxY(saveFavs.frame) + vSpace, width, textHeight);
    
    width = morePictures.frame.size.width * textHeight/morePictures.frame.size.height;
    morePictures.frame = CGRectMake(xPos, CGRectGetMaxY(noAds.frame) + vSpace, width, textHeight);
    
    width = happyAuthor.frame.size.width * textHeight/happyAuthor.frame.size.height;
    happyAuthor.frame = CGRectMake(xPos, CGRectGetMaxY(morePictures.frame), width, textHeight);
    
    height = self.frame.size.height/5;
    width = enjoy.frame.size.width * height/enjoy.frame.size.height;
    enjoy.frame = CGRectMake((self.frame.size.width - width)/2, (self.frame.size.height - height)/2.2, width, height);
}


- (void) startAnimation {
    
    if ([Props global].isShellApp) welcomeHolder.hidden = TRUE;
    
    welcomeHolder.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showTutorialMessage)];
    
    welcomeHolder.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    
    [UIView commitAnimations];
}


- (void) showTutorialMessage {
    
    start.enabled = TRUE;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:0.8];
	[UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    //[UIView setAnimationDidStopSelector:@selector(showExploreUsing)];
    
    tutorialHolder.alpha = 1.0;
    tapToStart.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) startTutorial {
    
    start.enabled = FALSE;
    [start removeFromSuperview];
    
    hide.enabled = TRUE;
    
    if ([Props global].isShellApp) [self showGoHome];
    
    else if ([Props global].freemiumType == kFreemiumType_V1)[self showFilter];
    
    else [self showSettings];
}


- (void) showGoHome {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:1.5];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showSettings)];
    
    for (UIView *view in [self subviews]) { if(view.tag != kBackgroundTag && view.tag != kButtonOverlayTag) view.alpha = 0;}
    
    goHome.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showSettings {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:2.0];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    if ([Props global].isShellApp) [UIView setAnimationDidStopSelector:@selector(showFilter)];
    
    else [UIView setAnimationDidStopSelector:@selector(showSettings2)];
    
    for (UIView *view in [self subviews]) { if(view.tag != kBackgroundTag && view.tag != kButtonOverlayTag) view.alpha = 0;}
    //goHome.alpha = 0.0;
    //filterAndSort.alpha = 0.0;
    //sort.alpha = 0.0;
    settings.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showSettings2 {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:1.5];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showFilter)];
    
    settings.alpha = 0;
    settings2.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showFilter {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:2.5];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    
    if ([Props global].deviceType == kiPad || [[Props global] inLandscapeMode]){
        [UIView setAnimationDidStopSelector:@selector(showSort)];
    }
    
    else [UIView setAnimationDidStopSelector:@selector(showExploreUsing)];
    
    //exploreHolder.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    /*exploreHolder.alpha = 0;
    deals.transform = CGAffineTransformMakeScale(kTabLabelTransform, kTabLabelTransform);
    //deals.center = CGPointMake(5.5 * tabWidth/2, self.frame.size.height);
    float alpha = 0.0;
    comments.alpha = alpha;
    locationsOnMap.alpha = alpha;
    sortableList.alpha = alpha;
    picturesOfEverything.alpha = alpha;
    deals.alpha = alpha;*/
    
    for (UIView *view in [self subviews]) { if(view.tag != kBackgroundTag && view.tag != kButtonOverlayTag) view.alpha = 0;}
    
    filterAndSort.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showSort {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:1.5];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    
    [UIView setAnimationDidStopSelector:@selector(showExploreUsing)];
    
    filterAndSort.alpha = 0.0;
    sort.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showExploreUsing {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:1];
	[UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showSortableList)];
    
    //tutorialHolder.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    //tutorialHolder.alpha = 0;
    //tapToStart.alpha = 0;
    //welcomeHolder.alpha = 0.0;
    //tapToHide.center = CGPointMake(tapToHide.center.x, tapToHide.center.y - [Props global].screenHeight/10);
    for (UIView *view in [self subviews]) { if(view.tag != kBackgroundTag && view.tag != kButtonOverlayTag) view.alpha = 0;}
    exploreHolder.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showSortableList {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:0.5];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showPicturesOfEverything)];
    
    sortableList.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showPicturesOfEverything {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kTabLabelDwellTime];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    
    if ([Props global].hasLocations) [UIView setAnimationDidStopSelector:@selector(showLocationsOnAMap)];
    else [UIView setAnimationDidStopSelector:@selector(showComments)];
    
    //sortableList.alpha = 0.0;
    sortableList.transform = CGAffineTransformMakeScale(kTabLabelTransform, kTabLabelTransform);
    sortableList.layer.anchorPoint = CGPointMake(0.5, 1);
    sortableList.center = CGPointMake(tabOffset + tabWidth/2, self.frame.size.height);
    //sortableList.center = CGPointMake(sortableList.center.x, sortableList.center.y + 10);
    picturesOfEverything.alpha = 1.0;
    
    [UIView commitAnimations];
}

- (void) showLocationsOnAMap {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kTabLabelDwellTime];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showComments)];
    
    picturesOfEverything.transform = CGAffineTransformMakeScale(kTabLabelTransform, kTabLabelTransform);
    locationsOnMap.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showComments {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kTabLabelDwellTime];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    
    if ([Props global].hasDeals) [UIView setAnimationDidStopSelector:@selector(showDeals)];
    else [UIView setAnimationDidStopSelector:@selector(shrinkComments)];
    
    picturesOfEverything.transform = CGAffineTransformMakeScale(kTabLabelTransform, kTabLabelTransform);
    locationsOnMap.transform = CGAffineTransformMakeScale(kTabLabelTransform, kTabLabelTransform);
    comments.alpha = 1.0;
    
    [UIView commitAnimations];
}

- (void) shrinkComments {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kTabLabelDwellTime];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    
    if ([Props global].freemiumType == kFreemiumType_V1) [UIView setAnimationDidStopSelector:@selector(showUpgrade)];
    else [UIView setAnimationDidStopSelector:@selector(showEnjoy)];
    
    if ([Props global].deviceType != kiPad && ![Props global].hasDeals) 
        comments.center = CGPointMake(self.frame.size.width - tabWidth/2, self.frame.size.height);
    
    comments.transform = CGAffineTransformMakeScale(kTabLabelTransform, kTabLabelTransform);
    
    [UIView commitAnimations];
}


- (void) showDeals {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kTabLabelDwellTime];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    
    [UIView setAnimationDidStopSelector:@selector(shrinkDeals)];
    

    comments.transform = CGAffineTransformMakeScale(kTabLabelTransform, kTabLabelTransform);
    deals.alpha = 1.0;
    
    [UIView commitAnimations];
}

- (void) shrinkDeals {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kTabLabelDwellTime];
	[UIView setAnimationDuration:kTabLabelShrinkTime];
    [UIView setAnimationDelegate:self];
    
    if ([Props global].freemiumType == kFreemiumType_V1) 
        [UIView setAnimationDidStopSelector:@selector(showUpgrade)];
    
    else [UIView setAnimationDidStopSelector:@selector(showEnjoy)];
    
    deals.transform = CGAffineTransformMakeScale(kTabLabelTransform, kTabLabelTransform);
    
    [UIView commitAnimations];
}


- (void) showUpgrade {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:1.0];
	[UIView setAnimationDuration:1.0];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showAndGet)];
    
    filterAndSort.alpha = 0;
    settings2.alpha = 0;
    sort.alpha = 0;
    exploreHolder.alpha = 0;
    tapToHide.alpha = 0;
    comments.alpha = 0;
    locationsOnMap.alpha = 0;
    picturesOfEverything.alpha = 0;
    sortableList.alpha = 0;
    deals.alpha = 0;
    upgrade.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showAndGet {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:0.7];
	[UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showOfflineEverything)];
    
    upgrade.transform = CGAffineTransformMakeScale(0.6f, 0.6f);
    //upgrade.center = CGPointMake(upgrade.center.x, upgrade.center.y - 20);
    andGet.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showOfflineEverything {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kBulletPointDwell];
	[UIView setAnimationDuration:kBulletPointFadeIn];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showFullSearch)];
    
    offlineEverything.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showFullSearch {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kBulletPointDwell];
	[UIView setAnimationDuration:kBulletPointFadeIn];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showSaveFavs)];
    
    search.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showSaveFavs {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kBulletPointDwell];
	[UIView setAnimationDuration:kBulletPointFadeIn];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showNoAds)];
    
    saveFavs.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showNoAds {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kBulletPointDwell];
	[UIView setAnimationDuration:kBulletPointFadeIn];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showMorePictures)];
    
    noAds.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showMorePictures {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kBulletPointDwell];
	[UIView setAnimationDuration:kBulletPointFadeIn];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showHappyAuthor)];
    
    morePictures.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showHappyAuthor {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:kBulletPointDwell];
	[UIView setAnimationDuration:kBulletPointFadeIn];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showEnjoy)];
    
    happyAuthor.alpha = 1.0;
    
    [UIView commitAnimations];
}


- (void) showEnjoy {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:2];
	[UIView setAnimationDuration:0.7];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationsFinished)];
    
    for (UIView *view in [self subviews]) { if(view.tag != kBackgroundTag) view.alpha = 0;}
    enjoy.alpha = 1.0;
        
    [UIView commitAnimations];
}


- (void) showTapToHide {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:1];
	[UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationsFinished)];
    
    tapToHide.alpha = 1.0;
    
    [UIView commitAnimations];
}



- (void) animationsFinished {
    
    hide.enabled = TRUE;
    [self performSelector:@selector(hide) withObject:nil afterDelay:1];
}


- (void) hide {
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(remove)];
    
     self.transform = CGAffineTransformMakeScale(0.001f, 0.001f);
    self.alpha = 0.1;
    
    [UIView commitAnimations];
}

- (void) remove {
    
    [self removeFromSuperview];
}

@end
