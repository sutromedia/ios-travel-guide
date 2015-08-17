//
//  OpeningView.h
//  TheProject
//
//  Created by Tobin Fisher on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpeningView : UIView {
    
    UILabel *label;
    UIActivityIndicatorView *progressInd;
    UIButton *cancelButton;
    BOOL cancel;
}

//- (void) checkForContentUpdate;
- (void) update;
- (void) updateContent;
- (void) hide;

@end
