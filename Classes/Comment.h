//
//  Comment.h
//  TheProject
//
//  Created by Tobin1 on 4/1/10.
//  Copyright 2010 Sutro Media. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CommentsViewController, CommentView, FMResultSet;

@interface Comment : NSObject {
	
	CommentView *commentView;
	NSString *commentText;
	NSString *date;
	NSString *entryName;
	NSString *userName;
	NSString *response;
	NSString *responseDate;
	NSString *responderName;
	NSString *subEntryName;
	CommentsViewController *controller;
	BOOL	shouldShowEntry;
	float	height;
}

@property (nonatomic, strong) CommentView *commentView;
@property (nonatomic, strong) NSString *commentText;
@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) NSString *entryName;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *response;
@property (nonatomic, strong) NSString *responseDate;
@property (nonatomic, strong) NSString *responderName;
@property (nonatomic, strong) NSString *subEntryName;
@property (nonatomic, strong) CommentsViewController *controller;
@property (nonatomic)			BOOL	shouldShowEntry;
@property (nonatomic)			float	height;


//- (void) hydrateView;
//- (void) dehydrateView;
//- (float) getHeight;
- (id)initWithRow:(FMResultSet *) rs;


@end
