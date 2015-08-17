//
//  UpgradePitch.h
//  TheProject
//
//  Created by Tobin Fisher on 11/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UpgradePitch : UIWebView <UIWebViewDelegate> {
    
    CALayer *background;
    UIButton *hideButton;
}

//- (id)initWithMessage:(NSString*) theMessage;
- (id)initWithYPos:(float) yPos andMessage:(NSString*) theMessage;

@end
