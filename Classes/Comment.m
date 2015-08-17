//
//  Comment.m
//  TheProject
//
//  Created by Tobin1 on 4/1/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import "Comment.h"
#import "FMResultSet.h"
//#import "CommentView.h"


@implementation Comment

@synthesize commentText, entryName, userName, date, response, responseDate, responderName, subEntryName, controller, shouldShowEntry, height, commentView;


- (id)initWithRow:(FMResultSet *) rs {
	
	self = [super init];
	
	if (self) {
		
		self.commentText = [rs stringForColumn:@"comment"];
		self.entryName = [rs stringForColumn:@"name"];
		self.userName = [rs stringForColumn:@"commenter_alias"];
        if ([userName length] == 0) self.userName = @"anonymous";
		self.date = [rs stringForColumn:@"created"];
		self.response = [rs stringForColumn:@"response"];
		self.responseDate = [rs stringForColumn:@"response_date"];
		self.responderName = [rs stringForColumn:@"responder_name"];
        if ([responderName length] == 0) self.responderName = @"anonymous";
		self.subEntryName = [rs stringForColumn:@"subentry_name"];
		self.commentView = nil;
        
        if ([Props global].appID == 121) self.responseDate = @"";
		
		//NSLog(@"COMMENT.initWithRow: commentDate = %@", date);
	}
	
	return self;
}

/*- (float) getHeight {
	//NSLog(@"COMMENT.getHeight");
	if (height == 0) {
		
		CommentView *tmpCommentView = [[CommentView alloc] initWithComment:self];
		height = [tmpCommentView getFrameHeight];
		[tmpCommentView release];
		
		//NSLog(@"COMMENT.getHeight = just set height to %f", height);
	}
	
	//NSLog(@"COMMENT.getHeight:done");

	return height;
}



- (void) hydrateView {

	//NSLog(@"COMMENT.hydrateView");
	CommentView *tmpCommentView = [[CommentView alloc] initWithComment:self];
	self.commentView = tmpCommentView;
	[tmpCommentView release];
}


- (void) dehydrateView {

	//NSLog(@"COMMENT.dehydrateView");
	//[commentView release];
	self.commentView = nil;
}
*/



@end
