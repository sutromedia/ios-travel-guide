//
//  SingleSettingView.h
//  TheProject
//
//  Created by Tobin Fisher on 11/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsView.h"

@interface SingleSettingView : UIView {
    
    SettingsView *controller;
    UIProgressView *downloadProgress;
    UISlider *downloadAmount;
    UILabel *mainLabel;
    //UILabel *downloadProgressLabel;
    //UILabel *descriptionLabel;
    UIButton *pauseButton;
    UIButton *resumeButton;
    BOOL paused;
    BOOL downloading;
    float totalContentSize;
    float currentContentSize;
    float amountToDownload;
    float photoSize;
}

@property (unsafe_unretained, nonatomic) NSString *title;
@property (unsafe_unretained, nonatomic) NSString *key;

- (void) setSliderToDefault;

@end
