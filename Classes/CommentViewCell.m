//
//  CommentViewCell.m
//  TheProject
//
//  Created by Tobin1 on 4/6/10.
//  Copyright 2010 Sutro Media. All rights reserved.
//

#import "CommentViewCell.h"
#import "CommentsViewController.h"
#import "CommentView.h"
#import "Comment.h"


@interface CommentViewCell (Private)


@end


@implementation CommentViewCell

//@synthesize commentView;
@synthesize comment;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
   
	//NSLog(@"COMMENTVIEWCELL.initWithStyle");
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		
		self.backgroundColor = [UIColor greenColor];
		self.autoresizesSubviews = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	}
	
    return self;
}


- (void)dealloc {
	
	//NSLog(@"COMMENTVIEWCELL.dealloc");
	//self.commentView = nil;
	[self.comment dehydrateView];
	self.comment = nil;
	[super dealloc];
}


- (void)layoutSubviews {
	
	//NSLog(@"COMMENTVIEWCELL.layoutSubviews");
	
	if (self.comment.commentView == nil) [self.comment hydrateView];
	
	[self addSubview:comment.commentView];
}


@end