//
//  SearchCell.h
//  TheProject
//
//  Created by Tobin1 on 8/4/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EntryTileView, EntriesTableViewController;


@interface SearchCell : UITableViewCell {
	
	EntriesTableViewController *__unsafe_unretained controller;
	UISearchBar *__unsafe_unretained searchBar;

}


@property (unsafe_unretained, nonatomic) EntriesTableViewController *controller;
@property (unsafe_unretained, nonatomic) UISearchBar	*searchBar;

@end
