//
//  CommentViewCell.h
//  TheProject
//
//  Created by Tobin1 on 4/6/10.
//  Copyright 2010 Sutro Media. All rights reserved.
//

#import <Foundation/Foundation.h>

//@class CommentView;
@class Comment;

@interface CommentViewCell : UITableViewCell {
	

	//CommentView				*commentView;
	Comment *comment;
		
}


//@property (nonatomic, retain) CommentView *commentView;
@property (nonatomic, retain) Comment *comment;


//- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier; 

@end