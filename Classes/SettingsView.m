//
//  SettingsView.m
//  TheProject
//
//  Created by Tobin Fisher on 11/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SettingsView.h"
#import "SingleSettingView.h"
#import "MyStoreObserver.h"

#define kUpgradeViews 4839373
#define kWaitingForAppStoreMessageTag 4239867
#define kUpgradeButtonTag 2456234
#define kThankYouTag 9349873

@implementation SettingsView

- (id)init {
    
    CGRect frame = CGRectMake(0, 0, [Props global].screenWidth, 185);
    
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0;

        background = [[CALayer alloc] init];
        //background.backgroundColor = [Props global].deviceType == kiPad || [Props global].osVersion < 5.0 ? [UIColor colorWithRed:0.65 green:0.70 blue:0.75 alpha:1.0].CGColor : [UIColor groupTableViewBackgroundColor].CGColor;
		//background.backgroundColor = [Props global].deviceType == kiPad || [Props global].osVersion < 5.0 || [Props global].osVersion >= 6.0 ? [UIColor colorWithRed:0.65 green:0.70 blue:0.75 alpha:1.0].CGColor : [UIColor groupTableViewBackgroundColor].CGColor;
		
		NSString *className = [NSString stringWithFormat:@"%@", [[UIColor groupTableViewBackgroundColor] class]];
		
		//Show the pinstriped background color if it's available, otherwise show a flat blueish background
		if ([className isEqualToString: @"UICachedDevicePatternColor"]) background.backgroundColor = [UIColor groupTableViewBackgroundColor].CGColor;
		else background.backgroundColor = [UIColor colorWithRed:0.65 green:0.70 blue:0.75 alpha:1.0].CGColor;
		
        background.shadowColor = [UIColor blackColor].CGColor;
        background.shadowOffset = CGSizeMake(0, 5);
        background.shadowOpacity = 1.0;
        background.opacity = 0.95;
        background.frame = CGRectMake(0, 0, [Props global].screenWidth, 0);
        [self.layer addSublayer:background];
        
        
        if ([Props global].freemiumType == kFreemiumType_V1) {
            
            NSLog(@"SETTINGSVIEW.drawRect: add upgrade stuff");
            UIFont *pitchFont = [Props global].deviceType != kiPad && [[Props global] inLandscapeMode] ? [UIFont boldSystemFontOfSize:14] : [UIFont boldSystemFontOfSize:16];
            //NSString *pitchText = @"Upgrade for offline maps and images (and to support your author!)";
            NSString *pitchText = [Props global].hasLocations ? @"Upgrade to get:\n• fast offline maps and photos\n• an ad-free experience\n• full content search\n• ability to save favorites\n• a happy author!" : @"Upgrade to get:\n• fast offline photos\n• an ad-free experience\n• full content search\n• ability to save favorites\n• a happy author!";
            
            float textBoxWidth = self.frame.size.width - [Props global].leftMargin * 4;
            CGSize textBoxSizeMax = CGSizeMake(textBoxWidth, 5000); // height value does not matter as long as it is larger than height needed for text box
            CGSize textBoxSize = [pitchText sizeWithFont:pitchFont constrainedToSize: textBoxSizeMax lineBreakMode: 0];
            
            pitchLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin *2, 0, textBoxWidth, textBoxSize.height)];
            pitchLabel.font = pitchFont;
            pitchLabel.text = pitchText;
            pitchLabel.textColor = [UIColor colorWithRed:0.30 green:0.34 blue:0.42 alpha:1];
            pitchLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.8];
            pitchLabel.shadowOffset = CGSizeMake(0, 1);
            pitchLabel.backgroundColor = [UIColor clearColor];
            pitchLabel.numberOfLines = 0;
            pitchLabel.textAlignment = UITextAlignmentCenter;
            pitchLabel.tag = kUpgradeViews;
            [self addSubview:pitchLabel];
            
            [self addBuyButton];
			
			UIFont *restoreFont = [UIFont fontWithName:kFontName size:pitchFont.pointSize];            
            restoreLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin *2, 0, [Props global].screenWidth - [Props global].leftMargin * 4, restoreFont.pointSize + 2)];
            restoreLabel.font = [UIFont fontWithName:kFontName size:restoreFont.pointSize];
            restoreLabel.text =  @"Already upgraded previously?";
            restoreLabel.textColor = [UIColor colorWithRed:0.30 green:0.34 blue:0.42 alpha:1];
            //restoreLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.8];
            //restoreLabel.shadowOffset = CGSizeMake(0, 1);
            restoreLabel.backgroundColor = [UIColor clearColor];
            restoreLabel.numberOfLines = 0;
            restoreLabel.textAlignment = UITextAlignmentCenter;
            restoreLabel.tag = kUpgradeViews;
            [self addSubview:restoreLabel];
			
			
			restoreButton = [UIButton buttonWithType:0];
			float buttonWidth = 140;
			restoreButton.frame = CGRectMake(([Props global].screenWidth - buttonWidth)/2, 0, buttonWidth, 25);
			
			static NSMutableArray *colors2 = nil;
			
			if (colors2 == nil) {
				colors2 = [[NSMutableArray alloc] initWithCapacity:3];
				UIColor *color = nil;
				color = [UIColor colorWithRed:0.5 green:0.55 blue:0.60 alpha:1.0];
				[colors2 addObject:(id)[color CGColor]];
				//color = [UIColor colorWithWhite:0.0 alpha:0.425];
				//[colors2 addObject:(id)[color CGColor]];
				color = [UIColor colorWithRed:0.40 green:0.45 blue:0.5 alpha:1.0];
				[colors2 addObject:(id)[color CGColor]];
			}
			
			CAGradientLayer *buttonBackground = [[CAGradientLayer alloc] init];
			//NSLog(@"Y pos for gradient layer = %f", self.frame.origin.y);
			buttonBackground.colors = colors2;
			buttonBackground.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0], nil];
			buttonBackground.bounds = restoreButton.bounds;
			buttonBackground.position = CGPointMake([restoreButton bounds].size.width/2, [restoreButton bounds].size.height/2);
			buttonBackground.shadowColor = [UIColor whiteColor].CGColor;
			buttonBackground.shadowOpacity = 0.3;
			buttonBackground.shadowOffset = CGSizeMake(0, 1);
			buttonBackground.shadowRadius = 0.1;
			buttonBackground.cornerRadius = 5;
			buttonBackground.borderColor = [UIColor colorWithRed:.26 green:.44 blue:.47 alpha:0.8].CGColor;
			buttonBackground.borderWidth = 1;
			//buttonBackground.masksToBounds = TRUE;
			
			[restoreButton.layer insertSublayer:buttonBackground atIndex:0];
			//upgradeButton.layer.masksToBounds = YES;
			//upgradeButton.layer.cornerRadius = 5;
	
			[restoreButton setTitle:@"Restore purchase" forState:UIControlStateNormal];
			[restoreButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.9] forState:UIControlStateNormal];
			[restoreButton setTitleColor:[UIColor darkGrayColor] forState:UIControlEventTouchDown];
			restoreButton.titleLabel.font = restoreFont;
			[restoreButton addTarget:[MyStoreObserver sharedMyStoreObserver] action:@selector(getPreviouslyPurchasedProducts) forControlEvents:UIControlEventTouchUpInside];
			restoreButton.tag = kUpgradeButtonTag;
			[self addSubview:restoreButton];

        }
        
		
		
		offlineSettingsLabel = [[UILabel alloc] init];
		offlineSettingsLabel.text = @"Set space used for offline content";
		offlineSettingsLabel.font = [UIFont fontWithName:kFontName size:16];
		offlineSettingsLabel.textColor = [UIColor colorWithRed:0.30 green:0.34 blue:0.42 alpha:1];
		offlineSettingsLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:offlineSettingsLabel];
		
		settingCluserBackground = [[CALayer alloc] init];
		settingCluserBackground.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0].CGColor;
		settingCluserBackground.cornerRadius = 10;
		settingCluserBackground.borderColor = [UIColor colorWithRed:0.63 green:0.68 blue:0.69 alpha:1.0].CGColor;
		settingCluserBackground.borderWidth = 1;
		settingCluserBackground.shadowColor = [UIColor whiteColor].CGColor;
		settingCluserBackground.shadowOffset = CGSizeMake(0, .5);
		settingCluserBackground.shadowRadius = 0.5;
		settingCluserBackground.shadowOpacity = 0.7;
		settingCluserBackground.opacity = 0.9;
		
		[self.layer addSublayer:settingCluserBackground];
		
		imageSetting = [[SingleSettingView alloc] initWithFrame: CGRectZero];
		imageSetting.title = @"Offline photos";
		imageSetting.key = kOfflinePhotos;
		[self addSubview:imageSetting];
		
		if ([Props global].hasLocations) {
			mapSetting = [[SingleSettingView alloc] initWithFrame:CGRectZero];
			mapSetting.title = @"Offline maps";
			mapSetting.key = kOfflineMaps_Max_ContentSize;
			[self addSubview:mapSetting];
		}
		
		else mapSetting = nil;
		
		if ([[Props global].offlineLinkURLs count] > 0) {
			fileSetting = [[SingleSettingView alloc] initWithFrame:CGRectZero];
			fileSetting.title = @"Offline files";
			fileSetting.key = kOfflineFiles;
			[self addSubview:fileSetting];
		}
		
		else fileSetting = nil;
        
        
        if ([Props global].freemiumType == kFreemiumType_V1) {
            
			if ([Props global].deviceType == kiPad) {
				cover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 0)];
				cover.tag = kUpgradeViews;
				cover.backgroundColor = [UIColor clearColor];
				// Set the colors for the gradient layer.
				static NSMutableArray *colors2 = nil;
				
				if (colors2 == nil) {
					colors2 = [[NSMutableArray alloc] initWithCapacity:3];
					UIColor *color = nil;
					color = [UIColor clearColor];
					[colors2 addObject:(id)[color CGColor]];
					//color = [UIColor colorWithWhite:0.0 alpha:0.425];
					//[colors2 addObject:(id)[color CGColor]];
					color = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.6];
					[colors2 addObject:(id)[color CGColor]];
				}
				
				gradientLayer = [[CAGradientLayer alloc] init];
				//gradientLayer.frame = CGRectMake(0, 0, cover.frame.size.width, cover.frame.size.height);
				gradientLayer.bounds = cover.bounds;
				gradientLayer.position = CGPointMake(cover.bounds.size.width/2, cover.bounds.size.height/2);
				//NSLog(@"Y pos for gradient layer = %f", self.frame.origin.y);
				[gradientLayer setColors:colors2];
				[gradientLayer setLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.03], nil]];
				//gradientLayer.opacity = 0.5;
				[cover.layer addSublayer: gradientLayer];
				
				[self addSubview:cover];
			}
                        
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freemiumUpgradePurchased) name:kFreemiumUpgradePurchased object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideMessage) name:kTransactionFailed object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateButton) name:kUpdateBuyButton object:nil];
        }
    }
    
    return self;
}


- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) layoutSubviews {
    
    float height = kTopMargin;
    
    float coverTop = 0;
    
    //[UIView beginAnimations:nil context:NULL];
	//[UIView setAnimationDuration:0.2];
    
    if ([Props global].freemiumType == kFreemiumType_V1) {
        
        //float textBoxWidth = self.frame.size.width - [Props global].leftMargin * 2;
        //CGSize textBoxSizeMax = CGSizeMake(textBoxWidth, 5000); // height value does not matter as long as it is larger than height needed for text box
        //CGSize textBoxSize = [self.description sizeWithFont:pitchFont constrainedToSize: textBoxSizeMax lineBreakMode: 0];
        
        float hMargin = [Props global].deviceType == kiPad || ![[Props global] inLandscapeMode] ? 15 : 10;
        
        pitchLabel.frame = CGRectMake(pitchLabel.frame.origin.x, height, pitchLabel.frame.size.width, pitchLabel.frame.size.height);
        
        upgradeButton.frame = CGRectMake(upgradeButton.frame.origin.x, CGRectGetMaxY(pitchLabel.frame) + hMargin, upgradeButton.frame.size.width, upgradeButton.frame.size.height);
        
        //height = CGRectGetMaxY(upgradeButton.frame) + 20;
		
		restoreLabel.frame = CGRectMake(restoreLabel.frame.origin.x, CGRectGetMaxY(upgradeButton.frame) + hMargin, restoreLabel.frame.size.width, restoreLabel.frame.size.height);
		
		restoreButton.frame = CGRectMake(restoreButton.frame.origin.x, CGRectGetMaxY(restoreLabel.frame) + hMargin * .5, restoreButton.frame.size.width, restoreButton.frame.size.height);
		
		height = CGRectGetMaxY(restoreButton.frame) + hMargin + 5;
        
        coverTop = height - 8;
    
        cover.frame = CGRectMake(cover.frame.origin.x, coverTop, [Props global].screenWidth, self.frame.size.height - coverTop);
    }
    
	if ([Props global].freemiumType != kFreemiumType_V1 || [Props global].deviceType == kiPad) {
		
		offlineSettingsLabel.hidden = FALSE;
		mapSetting.hidden = FALSE;
		imageSetting.hidden = FALSE;
		fileSetting.hidden = FALSE;
		settingCluserBackground.hidden = FALSE;
		
		height += 5;
		
		offlineSettingsLabel.frame = CGRectMake([Props global].leftMargin, height, [Props global].screenWidth - [Props global].leftMargin * 2, offlineSettingsLabel.font.pointSize + 2);
		
		height = CGRectGetMaxY(offlineSettingsLabel.frame) + 2;
		float clusterBackgroundY = height;
		
		if (mapSetting != nil) {
			mapSetting.frame = CGRectMake(0, height, mapSetting.frame.size.width, mapSetting.frame.size.height);
			height = CGRectGetMaxY(mapSetting.frame);
			//totalCluserBackgroundHeight += unitCluserBackgroundHeight;
		} 
		
		
		imageSetting.frame = CGRectMake(0, height, imageSetting.frame.size.width, imageSetting.frame.size.height);
		height = CGRectGetMaxY(imageSetting.frame);
		//totalCluserBackgroundHeight += unitCluserBackgroundHeight;
		
		if (fileSetting != nil) {
			fileSetting.frame = CGRectMake(0, height, fileSetting.frame.size.width, fileSetting.frame.size.height);
			height = CGRectGetMaxY(fileSetting.frame);
		}
		
		float totalCluserBackgroundHeight = height - clusterBackgroundY + 15;
		settingCluserBackground.frame = CGRectMake([Props global].leftMargin, clusterBackgroundY, self.frame.size.width - [Props global].leftMargin * 2, totalCluserBackgroundHeight);
		height = CGRectGetMaxY(settingCluserBackground.frame) + 15;
	}
	
	else {
		
		offlineSettingsLabel.hidden = TRUE;
		mapSetting.hidden = TRUE;
		imageSetting.hidden = TRUE;
		fileSetting.hidden = TRUE;
		settingCluserBackground.hidden = TRUE;
	}
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
    cover.frame = CGRectMake(self.frame.origin.x, coverTop, self.frame.size.width, height - coverTop);
    gradientLayer.bounds = cover.bounds;
    gradientLayer.position = CGPointMake(cover.bounds.size.width/2, cover.bounds.size.height/2);
    
    //NSLog(@"SETTINGSVIEW.layoutSubviews: coverview height = %f", cover.frame.size.height);
    //self.frame = CGRectMake(self.frame.origin.x, -height, self.frame.size.width, height);
    //self.alpha = 1.0;
    
    background.frame = CGRectMake(0, 0, [Props global].screenWidth, height);
    
    [self setNeedsDisplay];
    
    //[UIView commitAnimations];
}


- (void) upgrade {
    
    NSLog(@"SETTINGSVIEW.upgrade");
    
    [self showMessage:@"Waiting for App Store..."];
    
    [[MyStoreObserver sharedMyStoreObserver] getOfflineContentUpgrade];
}

- (void) showMessage:(NSString *) message {
    
	@autoreleasepool {
    
        [[self viewWithTag:kWaitingForAppStoreMessageTag] removeFromSuperview];
	
	NSString *loadingTagMessage = message; //@"Waiting for the App Store...";
	float loadingAnimationSize = 20; //This variable is weird - only sort of determines size at best.
	
	UIFont *errorFont = [UIFont fontWithName: kFontName size: 16];
	CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].rightMargin - [Props global].leftMargin, 19);
        
	CGSize textBoxSize = [loadingTagMessage sizeWithFont: errorFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
	
	float borderWidth = 12; //side of border between background and stuff on inside
	float messageWidth = loadingAnimationSize + textBoxSize.width + borderWidth * 3;
	
        UIView *waitingBackground = [[UIView alloc] initWithFrame:CGRectMake(([Props global].screenWidth - messageWidth)/2, 130, messageWidth, loadingAnimationSize + borderWidth*2)];
        waitingBackground.opaque = NO;
        waitingBackground.backgroundColor = [UIColor clearColor];
        waitingBackground.tag = kWaitingForAppStoreMessageTag;
        
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
	
	CGRect frame = CGRectMake(borderWidth, (waitingBackground.frame.size.height - loadingAnimationSize)/2, loadingAnimationSize, loadingAnimationSize);
	UIActivityIndicatorView * progressInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
	progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
	[progressInd sizeToFit];
	[progressInd startAnimating];
	[waitingBackground addSubview: progressInd];
	
	CGRect labelRect = CGRectMake ( CGRectGetMaxX(progressInd.frame) + borderWidth, (waitingBackground.frame.size.height - textBoxSize.height)/2, textBoxSize.width, textBoxSize.height);
	UILabel *loadingTag = [[UILabel alloc] initWithFrame:labelRect];
	loadingTag.text = loadingTagMessage;
	loadingTag.font = errorFont;
	loadingTag.textColor = [UIColor lightGrayColor];
	loadingTag.lineBreakMode = 0;
	loadingTag.numberOfLines = 2;
	loadingTag.backgroundColor = [UIColor clearColor];
	[waitingBackground addSubview:loadingTag];
        
        [self addSubview: waitingBackground];
    
	}
}


- (void) showThankYou {
    
	@autoreleasepool {
    
        [[self viewWithTag:kWaitingForAppStoreMessageTag] removeFromSuperview];
	
	NSString *loadingTagMessage = @"Thanks!"; //@"Waiting for the App Store...";
	
	UIFont *errorFont = [UIFont boldSystemFontOfSize: 20];
	CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].rightMargin - [Props global].leftMargin, 19);
        
	CGSize textBoxSize = [loadingTagMessage sizeWithFont: errorFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
	
	float borderWidth = 12; //side of border between background and stuff on inside
        float height = textBoxSize.height + borderWidth * 2;
	float messageWidth = textBoxSize.width + borderWidth * 2;
	
        UIView *waitingBackground = [[UIView alloc] initWithFrame:CGRectMake(([Props global].screenWidth - messageWidth)/2, 130, messageWidth, height)];
        waitingBackground.opaque = NO;
        waitingBackground.backgroundColor = [UIColor clearColor];
        waitingBackground.tag = kThankYouTag;
        
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
	
	CGRect labelRect = CGRectMake (borderWidth, (waitingBackground.frame.size.height - textBoxSize.height)/2, textBoxSize.width, textBoxSize.height);
	UILabel *loadingTag = [[UILabel alloc] initWithFrame:labelRect];
	loadingTag.text = loadingTagMessage;
	loadingTag.font = errorFont;
	loadingTag.textColor = [UIColor lightGrayColor];
	loadingTag.lineBreakMode = 0;
	loadingTag.numberOfLines = 2;
	loadingTag.backgroundColor = [UIColor clearColor];
	[waitingBackground addSubview:loadingTag];
        
        [self addSubview: waitingBackground];
    
	}
}


- (void) freemiumUpgradePurchased {
    
    NSLog(@"SETTINGSVIEW.freemiumUpgradePurchased");
    
    for (UIView *view in [self subviews]) {
        if (view.tag == kUpgradeViews || view.tag == kUpgradeButtonTag) [view removeFromSuperview];
    }
    
    [self showThankYou];
    [self performSelector:@selector(hideMessage) withObject:nil afterDelay:1.0];
    [self performSelector:@selector(setSlidersToDefaults) withObject:nil afterDelay:1.1];
    
    [self setNeedsLayout];
}


- (void) setSlidersToDefaults {
    
    [mapSetting setSliderToDefault];
    [fileSetting setSliderToDefault];
    [imageSetting setSliderToDefault];
}


- (void) hideMessage {
 
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.1];
    
    for (UIView *view in [self subviews]) {
        if (view.tag == kWaitingForAppStoreMessageTag || view.tag == kThankYouTag) view.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    }
    
    [UIView commitAnimations];
    
    [self performSelector:@selector(removeMessage) withObject:nil afterDelay:0.1];
}


- (void) removeMessage {
    
    for (UIView *view in [self subviews]) {
        if (view.tag == kWaitingForAppStoreMessageTag || view.tag == kThankYouTag) [view removeFromSuperview];
    }
    
    [self setNeedsDisplay];
}


- (void) addBuyButton {
    
    NSLog(@"SETTINGSVIEW.init: pitch label height = %f", pitchLabel.frame.size.height);
    NSString *upgradePrice = [[MyStoreObserver sharedMyStoreObserver] getUpgradePrice];
    
    if (upgradePrice == nil) [[MyStoreObserver sharedMyStoreObserver] requestProductData];
    
    NSString *buttonTitle = upgradePrice == nil ? @"Waiting for price..." : upgradePrice;
    
    [[self viewWithTag:kUpgradeButtonTag] removeFromSuperview];
    
    upgradeButton = [UIButton buttonWithType:0];
    float buttonWidth = upgradePrice == nil ? 180 : 100;
    upgradeButton.frame = CGRectMake(([Props global].screenWidth - buttonWidth)/2, 0, buttonWidth, 30);
    
    static NSMutableArray *colors2 = nil;
    
    if (colors2 == nil) {
        colors2 = [[NSMutableArray alloc] initWithCapacity:3];
        UIColor *color = nil;
        color = [UIColor colorWithRed:0.38 green:0.46 blue:0.60 alpha:1.0];
        [colors2 addObject:(id)[color CGColor]];
        //color = [UIColor colorWithWhite:0.0 alpha:0.425];
        //[colors2 addObject:(id)[color CGColor]];
        color = [UIColor colorWithRed:0.20 green:0.34 blue:0.61 alpha:1.0];
        [colors2 addObject:(id)[color CGColor]];
    }
    
    CAGradientLayer *buttonBackground = [[CAGradientLayer alloc] init];
    //NSLog(@"Y pos for gradient layer = %f", self.frame.origin.y);
    buttonBackground.colors = colors2;
    buttonBackground.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0], nil];
    buttonBackground.bounds = upgradeButton.bounds;
    buttonBackground.position = CGPointMake([upgradeButton bounds].size.width/2, [upgradeButton bounds].size.height/2);
    buttonBackground.shadowColor = [UIColor whiteColor].CGColor;
    buttonBackground.shadowOpacity = 0.3;
    buttonBackground.shadowOffset = CGSizeMake(0, 1);
    buttonBackground.shadowRadius = 0.1;
    buttonBackground.cornerRadius = 5;
    buttonBackground.borderColor = [UIColor colorWithRed:.26 green:.44 blue:.47 alpha:0.8].CGColor;
    buttonBackground.borderWidth = 1;
    //buttonBackground.masksToBounds = TRUE;
    
    [upgradeButton.layer insertSublayer:buttonBackground atIndex:0];
    //upgradeButton.layer.masksToBounds = YES;
    //upgradeButton.layer.cornerRadius = 5;
    SEL buttonSelector = upgradePrice == nil ? nil : NSSelectorFromString(@"upgrade");
    [upgradeButton setTitle:[NSString stringWithFormat:@"%@", buttonTitle] forState:UIControlStateNormal];
    [upgradeButton setTitleColor:[UIColor grayColor] forState:UIControlEventTouchDown];
    upgradeButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [upgradeButton addTarget:self action:buttonSelector forControlEvents:UIControlEventTouchUpInside];
    upgradeButton.tag = kUpgradeButtonTag;
    [self addSubview:upgradeButton];
}


- (void) updateButton {
    
    NSLog(@"Time to update button");
    
    [self addBuyButton];
    
    [upgradeButton setNeedsDisplay];    
}


@end
