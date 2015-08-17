//
//  AppPicker.h
//  TravelGuideSF
//
//  Created by Tobin1 on 8/17/09.
//  Copyright 2009 Sutro Media. All rights reserved.
//


#import <UIKit/UIKit.h>

@class CustomView;

@interface AppPicker : UIPickerView <UIPickerViewDelegate>
{
	NSArray* firstRowPickerViews;
	//NSMutableArray *pickerState;
	CGPoint pickerState; 
	int theRow;
	int theComponent;
	CGFloat componentWidth;
	CustomView *favoriteView;
}


- (CGPoint) getPickerState;
//- (void) addFilterElement: (NSString*) theFilterElement;
- (NSString*) getPickerTitle;
//- (void) removeFavoriteChoice;
//- (void) addFavoriteChoice;
- (id)initWithFrame: (CGRect) frame andApps:(NSArray*) theAppArray;

@end

