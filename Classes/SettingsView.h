//
//  SettingsView.h
//  TheProject
//
//  Created by Tobin Fisher on 11/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class SingleSettingView;

@interface SettingsView : UIView {
    
    SingleSettingView *mapSetting;
    SingleSettingView *imageSetting;
    SingleSettingView *fileSetting;
    CALayer *settingCluserBackground;
    UILabel *offlineSettingsLabel;
    UIView *cover;
    CALayer *background;
    UILabel *pitchLabel;
    UIButton *upgradeButton;
	UILabel *restoreLabel;
	UIButton *restoreButton;
    CAGradientLayer *gradientLayer;
}

- (void) showMessage:(NSString *) message;
- (void) addBuyButton;

@end
