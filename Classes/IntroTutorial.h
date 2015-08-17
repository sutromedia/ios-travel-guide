//
//  IntroTutorial.h
//  TheProject
//
//  Created by Tobin Fisher on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IntroTutorial : UIView {
    
    UIButton *hide;
    UIButton *start;
    UIImageView *welcomeHolder;
    UIImageView *tutorialHolder;
    UIImageView *tapToHide;
    UIImageView *tapToStart;
    UIImageView *exploreHolder;
    UIImageView *sortableList;
    UIImageView *picturesOfEverything;
    UIImageView *comments;
    UIImageView *locationsOnMap;
    UIImageView *deals;
    UIImageView *filterAndSort;
    UIImageView *sort;
    UIImageView *upgrade;
    UIImageView *andGet;
    UIImageView *offlineEverything;
    UIImageView *search;
    UIImageView *saveFavs;
    UIImageView *noAds;
    UIImageView *morePictures;
    UIImageView *happyAuthor;
    UIImageView *settings;
    UIImageView *settings2;
    UIImageView *enjoy;
    UIImageView *goHome;

    float tabWidth;
    float tabOffset;
    float tabSpacing;
}


- (void) startAnimation;
- (void) orientationChange;

@end
