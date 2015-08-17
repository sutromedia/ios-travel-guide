//
//  CommentsDatasource.m
//  TheProject
//
//  Created by Tobin1 on 4/6/10.
//  Copyright 2010 Sutro Media. All rights reserved.
//

#import "CommentsDatasource.h"
#import "CommentViewCell.h"
#import "CommentView.h"
#import "Comment.h"
#import "Props.h"


@implementation CommentsDatasource

@synthesize commentsArray;

- (id) initWithCommentsArray:(NSArray*) theCommentsArray {

	self.commentsArray = theCommentsArray;
	
	return self;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	//CommentViewCell *cell = [[[CommentViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"CommentView"] autorelease];
	CommentViewCell *cell = [[[CommentViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CommentView"] autorelease];
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.comment = [self commentForIndexPath:indexPath];
	return cell; //[cell autorelease]; //TF 102209
}


- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath*) indexPath {
	
	Comment *tempComment = [commentsArray objectAtIndex:indexPath.row];
	//[tempComment calculateHeight];
	//CommentView *tmpCommentView = tempComment.commentView;
	float height = [tempComment getHeight];
	//NSLog(@"COMMENTSDATASOURCE.tableView:heightForRowAtIndexPath:height = %f, row = %i, tableView = %i", height,indexPath.row, tableView);
	
	return height + [Props global].tweenMargin;
}


// return the entry at the index in the sorted by numbers array
- (Comment *)commentForIndexPath:(NSIndexPath *)indexPath {
	
	if([commentsArray count] > indexPath.row) {
		Comment *theComment = [commentsArray objectAtIndex:indexPath.row];
		//NSLog(@"COMMENTDATASOURCE.commentForIndexPath: comment = %@", theComment.commentText);
		return theComment;
	}
	
	else if (indexPath.row >= [commentsArray count]) {
		NSLog(@"ERROR - Trying to access out of range element in sortedEntries with indexPath of > count, which = %i", [commentsArray count]);
		return [commentsArray objectAtIndex:([commentsArray count] - 1)];
	}
	
	else {
		return nil;
		NSLog(@"ERROR - Something very weird happening");
	}
}


- (void) setHeight:(float) theHeight forIndex:(int) theIndex {

	NSLog(@"Height for index %f for %i", theHeight, theIndex);
}


- (CGFloat) heightForRowAtIndexPath:(NSIndexPath*) indexPath {
	
	CGFloat height = 250.0;
	
	return height;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView  {

	return 1;
}



- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section {
	// ask for, and return, the number of entries in the current selection
    NSLog(@"COMMENTSDATASOURCE.numberOfRowsInSection: %i rows", [commentsArray count]);
    
	return [commentsArray count];
}


@end
