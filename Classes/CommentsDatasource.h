//
//  CommentsDatasource.h
//  TheProject
//
//  Created by Tobin1 on 4/6/10.
//  Copyright 2010 Sutro Media. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Comment;

@interface CommentsDatasource : NSObject <UITableViewDataSource, UITableViewDelegate> {

	NSArray *commentsArray;
}

@property (nonatomic, retain) NSArray *commentsArray;

- (id) initWithCommentsArray:(NSArray*) theCommentsArray;
- (CGFloat) heightForRowAtIndexPath:(NSIndexPath*) indexPath;
//- (Comment*)commentViewForIndexPath:(NSIndexPath *)indexPath; 
- (Comment *)commentForIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section;

@end
