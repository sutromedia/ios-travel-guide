//
//  LoadingController.h
//  TheProject
//
//  Created by Tobin1 on 7/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LoadingController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    
    UINavigationController *__unsafe_unretained homeController;
    //UITabBarController *tabBarController;
}

@property (unsafe_unretained, nonatomic) UINavigationController *homeController;
//@property (nonatomic, retain) UITabBarController *tabBarController;

- (void) createLoadingAnimation;
- (id) initWithGuideId:(int)theGuideId;
- (void) addBackground;

@end
