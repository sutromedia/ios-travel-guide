//
//  CommentView.m
//  TheProject
//
//  Created by Tobin1 on 4/1/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import "CommentView.h"
#import "CommentsViewController.h"
#import "Comment.h"
#import "Constants.h"
#import "Entry.h"
#import "EntryCollection.h"
#import "Props.h"

#define	kFontSize			14
#define responseFontSize	13
#define topTextHeight		15
#define outerVMargin		6
#define xTweenMargin		6
#define yTweenMargin		6
#define kLeftMargin			10
#define kRightMargin		10
#define topMargin			8
#define bottomMargin		15
#define dateWidth			90
#define spaceAboveResponse	-4
#define spaceLeftOfResponse 25
#define spaceBetweenGroups	-1


@interface CommentView (Private)

- (float) getFrameHeight;
- (float) drawCommentBubbleAndActuallyDraw:(BOOL) shouldDraw;
- (float) drawResponseBubbleAtYPosition:(float) theYPosition andActuallyDraw:(BOOL) shouldDraw;

@end


@implementation CommentView

@synthesize comment, controller, shouldShowEntry;

- (id)initWithComment:(Comment*) theComment controller:(CommentsViewController*) theController showEntry:(BOOL) _shouldShowEntry {
	
	self.comment =	theComment;
	self.shouldShowEntry = _shouldShowEntry;
	self.controller =	theController;
	
    self = [super initWithFrame:CGRectMake(0, 0, self.controller.view.bounds.size.width, [self getFrameHeight])];
	if (self) {
    
		self.backgroundColor = [UIColor clearColor];
		self.autoresizesSubviews = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
	
    return self;
}

- (id)initWithComment:(Comment*) theComment {
	
	//NSLog(@"COMMENTVIEW.initWithComment:%@", theComment.commentText);
	self.comment =	theComment;
	self.shouldShowEntry = theComment.shouldShowEntry;
	self.controller =	theComment.controller;
	
    self = [super initWithFrame:CGRectMake(0, 0, self.controller.view.bounds.size.width, [self getFrameHeight])];
	if (self) {
		
		self.backgroundColor = [UIColor clearColor];
		self.autoresizesSubviews = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
	
    return self;
}


- (void)dealloc {
	
	//NSLog(@"COMMENTVIEW.dealloc");
	self.comment = nil;
	self.controller = nil;
	
	[super dealloc];
}


- (void)drawRect:(CGRect)rect {
	
	//NSLog(@"COMMENTVIEW.drawRect");
	float height = 0;

	height += [self drawCommentBubbleAndActuallyDraw:YES];
	
	if ([comment.response length] > 0) {
		
		height += spaceAboveResponse;
		[self drawResponseBubbleAtYPosition:height andActuallyDraw:YES];
	}

	self.comment.height = self.frame.size.height;
}


- (float) drawCommentBubbleAndActuallyDraw:(BOOL) shouldDraw {
	
	float height = topMargin;
	
	UIFont *buttonFont = [UIFont boldSystemFontOfSize:15];
	
	//Draw Entry info
	
	Entry *entry = [EntryCollection entryByName:comment.entryName];
	
	if (entry == nil) self.shouldShowEntry = FALSE;
	
	if (self.shouldShowEntry) {
		
		CGRect iconFrame = CGRectMake(outerVMargin + kLeftMargin, height, 30, 30);
		
		if( shouldDraw) {
				
            UIImageView *iconImageViewer = [[UIImageView alloc] initWithImage:entry.iconImage];
            //[iconImage release];
            iconImageViewer.frame = iconFrame;
            [self addSubview: iconImageViewer];
            [iconImageViewer release];
		}
		
		height += iconFrame.size.height + xTweenMargin;
		
		//Draw entry button
		if (shouldDraw) {
			float buttonWidth = [comment.entryName sizeWithFont:buttonFont].width;
			
			float maxButtonWidth = self.controller.view.bounds.size.width - [Props global].leftMargin * 2 - iconFrame.size.width - outerVMargin * 2;
			
			if (buttonWidth > maxButtonWidth) buttonWidth = maxButtonWidth;
			
			UIButton *entryButton = [[UIButton alloc] initWithFrame:CGRectMake( CGRectGetMaxX(iconFrame) + xTweenMargin, iconFrame.origin.y, buttonWidth, iconFrame.size.height)];
			
			[entryButton setTitle:comment.entryName forState:0];
			[entryButton addTarget:self.controller action:@selector(goToEntry:) forControlEvents:UIControlEventTouchUpInside];
			entryButton.backgroundColor = [UIColor clearColor];
			entryButton.titleLabel.font = buttonFont;
			entryButton.titleLabel.textAlignment = UITextAlignmentRight;
			[entryButton setTitleColor: [Props global].linkColor forState:0];
			[self addSubview:entryButton];
			[entryButton release];
		}
	}
	
	
	//Add entry name if we're in sutro world
	if ([Props global].appID <= 1 && [comment.subEntryName length] > 0) {
		
		//UIFont *textFont = [UIFont fontWithName:kFontName size:kFontSize];
		float subEntryLabelHeight = kFontSize + 4;
		
		if (shouldDraw) {
			UIFont *textFont = [UIFont italicSystemFontOfSize: kFontSize];
			CGFloat textBoxWidth = self.controller.view.bounds.size.width - 2 * ([Props global].leftMargin + [Props global].rightMargin);
			
			UILabel *subEntryLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin + outerVMargin, height, textBoxWidth, subEntryLabelHeight)];
			subEntryLabel.backgroundColor = [UIColor clearColor];
			subEntryLabel.textAlignment = UITextAlignmentLeft;
			subEntryLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
			subEntryLabel.font = textFont;
			subEntryLabel.numberOfLines = 0;
			subEntryLabel.text = [NSString stringWithFormat:@"\"%@\"", comment.subEntryName];
			
			[self addSubview:subEntryLabel];
			
			[subEntryLabel release];
		}
		
		
		height += subEntryLabelHeight + xTweenMargin;
		
	}
	
	//Add comment
	UIFont *textFont = [UIFont fontWithName:kFontName size:kFontSize];
	CGFloat textBoxWidth = self.controller.view.bounds.size.width - 2 * ([Props global].leftMargin + [Props global].rightMargin);
	CGSize textBoxSize = [self.comment.commentText sizeWithFont:textFont constrainedToSize:CGSizeMake(textBoxWidth, 5000)];	
	
	/*
    UITextView *commentLabel = nil;
	
	if (shouldDraw){
		commentLabel = [[UITextView alloc] initWithFrame:CGRectMake([Props global].leftMargin + outerVMargin, height - 10, textBoxWidth, textBoxSize.height + 10)];
		commentLabel.backgroundColor = [UIColor clearColor];
		commentLabel.textAlignment = UITextAlignmentLeft;
		commentLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
		commentLabel.font = textFont;
        commentLabel.text = comment.commentText;
        commentLabel.scrollEnabled = NO;
        commentLabel.userInteractionEnabled = NO;
        commentLabel.dataDetectorTypes = UIDataDetectorTypeAll;
        commentLabel.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        commentLabel.editable = NO;
		[self addSubview:commentLabel];
	}*/
    
    
    UILabel *commentLabel = nil;
	
	if (shouldDraw){
		commentLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin + outerVMargin, height - 10, textBoxWidth, textBoxSize.height + 10)];
		commentLabel.backgroundColor = [UIColor clearColor];
		commentLabel.textAlignment = UITextAlignmentLeft;
		commentLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
		commentLabel.font = textFont;
        commentLabel.text = comment.commentText;
        commentLabel.numberOfLines = 0;
		[self addSubview:commentLabel];
	}
	
	height += textBoxSize.height + xTweenMargin;
	
	//Add date
	if (shouldDraw) {
		
		UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(commentLabel.frame) - dateWidth, height, dateWidth, topTextHeight)];
		dateLabel.backgroundColor = [UIColor clearColor];
		dateLabel.textAlignment = UITextAlignmentRight;
		dateLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
		dateLabel.font = [UIFont italicSystemFontOfSize:14];
		dateLabel.numberOfLines = 0;
		dateLabel.text = comment.date;
		[self addSubview:dateLabel];
		[dateLabel release];
	}
	
	//Add user name
	float userLabelHeight = 14;
	
	if (shouldDraw) {
		UILabel *userLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(commentLabel.frame), height, commentLabel.frame.size.width, userLabelHeight)];
		userLabel.backgroundColor = [UIColor clearColor];
		userLabel.textAlignment = UITextAlignmentLeft;
		userLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
		userLabel.font = [UIFont italicSystemFontOfSize:14];
		userLabel.numberOfLines = 0;
		
		if ([comment.userName length] > 0)
			userLabel.text = [NSString stringWithFormat:@"from %@", comment.userName];
		
		else
			userLabel.text = @"posted by Anonymous";
		
		[self addSubview:userLabel];
		[userLabel release];
	}
	
	height += userLabelHeight + bottomMargin;
	
	//draw CommentBubble around everything
	if (shouldDraw) {
		UIImage *commentBubble = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"commentBubble" ofType:@"png"]];
		UIImage *stretchablecommentBubble = [commentBubble stretchableImageWithLeftCapWidth:28 topCapHeight:28];
		UIImageView *commentBubbleViewer = [[UIImageView alloc] initWithImage:stretchablecommentBubble];
		[commentBubble release];
		
		//commentBubbleViewer.frame = CGRectMake(outerVMargin, 0, [Props global].screenWidth - outerVMargin * 2, height);
		commentBubbleViewer.frame = CGRectMake(outerVMargin, 0, self.controller.view.bounds.size.width - outerVMargin * 2, height);
		[self insertSubview:commentBubbleViewer atIndex:0];
		[commentBubbleViewer release];
	}
	
	if (commentLabel != nil) [commentLabel release];
	
	return height;
}


- (float) drawResponseBubbleAtYPosition:(float) theYPosition andActuallyDraw:(BOOL) shouldDraw {
	
	float height = topMargin;
	CGFloat textBoxWidth = self.controller.view.bounds.size.width - (kLeftMargin + kRightMargin) - 2 * outerVMargin - spaceLeftOfResponse;
	float textBoxX = outerVMargin + spaceLeftOfResponse + kLeftMargin;
		
	//Add response comment
	UIFont *textFont = [UIFont fontWithName:kFontName size:responseFontSize];
	CGSize textBoxSize = [self.comment.response sizeWithFont:textFont constrainedToSize:CGSizeMake(textBoxWidth, 5000)];	
	
    UILabel *commentLabel = nil;
	
	if (shouldDraw) {
		commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(textBoxX, theYPosition + height, textBoxWidth, textBoxSize.height)];
		commentLabel.backgroundColor = [UIColor clearColor];
		commentLabel.textAlignment = UITextAlignmentLeft;
		commentLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
		commentLabel.font = textFont;
		commentLabel.numberOfLines = 0;
		commentLabel.text = comment.response;
		
		[self addSubview:commentLabel];
	}
    
    /*UITextView *commentLabel = nil;
	
	if (shouldDraw) {
		commentLabel = [[UITextView alloc] initWithFrame:CGRectMake(textBoxX, theYPosition + height, textBoxWidth, textBoxSize.height)];
		commentLabel.backgroundColor = [UIColor clearColor];
		commentLabel.textAlignment = UITextAlignmentLeft;
		commentLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
        commentLabel.dataDetectorTypes = UIDataDetectorTypeAll;
		commentLabel.font = textFont;
        commentLabel.scrollEnabled = NO;
        commentLabel.editable = NO;
        commentLabel.userInteractionEnabled = NO;
		//commentLabel.numberOfLines = 0;
		commentLabel.text = comment.response;
		
		[self addSubview:commentLabel];
	}*/
	
	height += textBoxSize.height + xTweenMargin;
	
	//Add date
	if (shouldDraw) {
		
		UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(commentLabel.frame), theYPosition + height, dateWidth, topTextHeight)];
		dateLabel.backgroundColor = [UIColor clearColor];
		dateLabel.textAlignment = UITextAlignmentLeft;
		dateLabel.textColor = [UIColor colorWithWhite:0.35 alpha:1.0];
		dateLabel.font = [UIFont italicSystemFontOfSize:responseFontSize];
		dateLabel.numberOfLines = 0;
		dateLabel.text = comment.responseDate;
		dateLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		[self addSubview:dateLabel];
		
		[dateLabel release];
	}

	//Add author name
	float labelHeight = 14;
	
	if (shouldDraw) {
		UILabel *userLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(commentLabel.frame) + dateWidth + xTweenMargin, theYPosition + height, commentLabel.frame.size.width - dateWidth - xTweenMargin - 4, 14)];
		userLabel.backgroundColor = [UIColor clearColor];
		userLabel.textAlignment = UITextAlignmentRight;
		userLabel.textColor = [UIColor colorWithWhite:0.35 alpha:1.0];
		userLabel.font = [UIFont italicSystemFontOfSize:responseFontSize];
		userLabel.numberOfLines = 0;
		
		userLabel.text = comment.responderName;
		
		[self addSubview:userLabel];
		[userLabel release];
	}

	height += labelHeight + bottomMargin;
	
	if (shouldDraw) {
		UIImage *commentBubble = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"commentBubble_response" ofType:@"png"]];
		UIImage *stretchablecommentBubble = [commentBubble stretchableImageWithLeftCapWidth:28 topCapHeight:28];
		UIImageView *commentBubbleViewer = [[UIImageView alloc] initWithImage:stretchablecommentBubble];
		[commentBubble release];
		commentBubbleViewer.frame = CGRectMake(outerVMargin + spaceLeftOfResponse, theYPosition, self.controller.view.bounds.size.width - outerVMargin * 2 - spaceLeftOfResponse, height);
		[self insertSubview:commentBubbleViewer atIndex:0];
		[commentBubbleViewer release];
	}
	
	if (commentLabel != nil) [commentLabel release];
	
	return height;
}


- (float) getFrameHeight {
	
	float height = 0;
	
	height += [self drawCommentBubbleAndActuallyDraw:NO];
	
	if ([comment.response length] > 0) {
		
		height += spaceAboveResponse;
		height += [self drawResponseBubbleAtYPosition:height andActuallyDraw:NO];
	}
	
	height += spaceBetweenGroups;
	
	return height;
}


@end
