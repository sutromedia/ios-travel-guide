//
//  FlipViewController.h
//  TheProject
//
//  Created by Tobin1 on 6/27/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EntriesAppDelegate;

@interface FlipViewController : UIViewController {
	
	EntriesAppDelegate *appDelegate;
	UIView *containerView;
	UIView *frontView;
	UIImageView *backView;
	NSString *destination;

}

@property (nonatomic, strong) UIView *containerView;
//@property (nonatomic, retain) UIView *frontView;
//@property (nonatomic, retain) UIImageView *backView;

- (id) initWithAppDelegate:(EntriesAppDelegate*) theAppDelegate startingImage:(UIImage*) theStartingImage andDestination:(NSString*) theDestination ; 
- (void) hideLoginScreen;
- (void) flipViews;

@end
