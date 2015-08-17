//
//  WelcomeView.h
//  TheProject
//
//  Created by Tobin1 on 12/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TutorView : UIView {
    
    NSString* viewName;
    UIImageView *welcomeHolder;
    UIImageView *tutorialHolder;
    UIImageView *freeSample;
    UIImageView *getMoreGuides;
    UIImageView *resumeDownload;
    UIImageView *swipeToDelete;
    UIImageView *enjoy;
    UIView *background;
    UIView *background2;
    CGRect backgroundFrame1;
    CGRect backgroundFrame2;

}

- (void) startAnimation;
- (void) hide;

@end
