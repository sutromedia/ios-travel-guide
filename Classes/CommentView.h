//
//  CommentView.h
//  TheProject
//
//  Created by Tobin1 on 4/1/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Comment, CommentsViewController;

@interface CommentView : UIView {

	Comment					*comment;
	CommentsViewController	*controller;
	BOOL					shouldShowEntry;
}


@property (nonatomic, retain)	Comment *comment;
@property (nonatomic, retain)	CommentsViewController *controller;
@property (nonatomic)			BOOL shouldShowEntry;


- (id)initWithComment:(Comment*) theComment controller:(CommentsViewController*) theController showEntry:(BOOL) _shouldShowEntry;
- (id)initWithComment:(Comment*) theComment;
- (float) getFrameHeight;


@end
