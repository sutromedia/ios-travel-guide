//
//  SearchCell.m
//  TheProject
//
//  Created by Tobin1 on 8/4/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import "SearchCell.h"
#import "EntriesTableViewController.h"
#import "Props.h"


@implementation SearchCell

@synthesize controller, searchBar;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		
        //NSLog(@"SEARCHCELL.initWithStyle");
        
		self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		//self.contentView.autoresizesSubviews = YES;
		
		UISearchBar *tmpSearchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, [Props global].screenWidth, kSearchBarHeight/*[Props global].tableviewRowHeight*/)];
		self.searchBar = tmpSearchBar;
		self.searchBar.barStyle = UIBarStyleDefault;
		self.searchBar.tintColor = [UIColor colorWithWhite:0.7 alpha:1];
		self.searchBar.showsCancelButton=NO;
		self.searchBar.autocorrectionType=UITextAutocorrectionTypeNo;
		self.searchBar.autocapitalizationType=UITextAutocapitalizationTypeNone;
		self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		
		UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, kSearchBarHeight/*[Props global].tableviewRowHeight*/)];
		navigationBar.barStyle = UIBarStyleDefault;
		navigationBar.tintColor = [UIColor colorWithWhite:0.7 alpha:1];
		[navigationBar addSubview:searchBar];
		navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self.contentView addSubview:navigationBar];
		self.selectionStyle = UITableViewCellSelectionStyleBlue;
		
    }
    return self;
}

- (void)layoutSubviews{
	
	//NSLog(@"SEARCHCELL.layoutSubviews with screenWidth = %f", [Props global].screenWidth);
	self.searchBar.frame =  CGRectMake(0, 0, [Props global].screenWidth, kSearchBarHeight/*[Props global].tableviewRowHeight*/);
}


- (void) setController:(EntriesTableViewController*) theController {
	//NSLog(@"SearchCell.setController called with controller %i", theController);
	searchBar.delegate = theController;
	controller = theController;
	
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

	//This is a work around to deal with touch events that we want to go to the cancel butten getting intercepted by the cell.
	//Hope to make this less of a kludge at some point.
	[controller searchBarCancelButtonClicked:self.searchBar];
}


- (void)dealloc {
	
    NSLog(@"SEARCHCELL.dealloc");
}


@end
