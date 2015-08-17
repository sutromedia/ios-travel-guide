//
//  FilterButton.h
//  TheProject
//
//  Created by Tobin1 on 12/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FilterButton : NSObject {
	
	UIButton		* pickerButton;
	UIBarButtonItem *selectBarButton;
	UIBarButtonItem *cancelBarButton;
	NSString		*previousFilterChoice;
	int				previousSortIndex;
	id              __unsafe_unretained controller;
    BOOL            hasBeenSelected;
	
}


@property (nonatomic, strong)   UIBarButtonItem *selectBarButton;
@property (nonatomic, strong)   UIBarButtonItem *cancelBarButton;
@property (unsafe_unretained, nonatomic)   id              controller;
@property (nonatomic)           int             previousSortIndex;
@property (nonatomic)           BOOL            hasBeenSelected;



- (void) update;
- (void) addHint;
- (id) initWithController:(id) theController;
- (NSString*) getFormatedPickerTitle;


@end
