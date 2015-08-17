//
//  SutroView.h
//  TheProject
//
//  Created by Tobin1 on 8/13/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DetailView.h>


@interface SutroView : DetailView {
    
    NSTimer *refreshViewTimer;
    BOOL showEntireDescription;
    BOOL doNotShowSecondRow;
	int	heightAfterTagline;
	int tagsViewTag;
	int commentsViewTag;
	int	buttonBarViewTag;
	int descriptionViewTag;
	int appPitchViewTag;
}


@property (nonatomic) BOOL showEntireDescription;

@end
