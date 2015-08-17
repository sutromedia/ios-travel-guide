/*

File: FilterPicker.h
Abstract: A custom UIPicker that shows text and images.

Version: 1.7

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/

#import <UIKit/UIKit.h>

@class CustomView;

@interface FilterPicker : UIView <UIPickerViewDelegate>
{
	NSMutableArray*		firstRowPickerViews;
	UIView*				sortAndPickerView;
	UIPickerView*		theFilterPicker;
	UISegmentedControl* sorterControl;
	UILabel*			sortLabel;
	UILabel*			filterLabel;
	UIBarButtonItem*	barButton;
	UIButton*			pickerButton;
	UIButton*			selectButton;
    UIImageView*        dropViewer;
	id					__unsafe_unretained delegate;
	NSString*			favoriteView;
	NSMutableArray*		filters;
	NSString*			sortType;	
	CGPoint				pickerState; 
	CGFloat				componentWidth;
//	float				heightWithSort;
//	float				heightWithoutSort;
	int					theRow;
	int					theComponent;
	BOOL				sorterHidden;
	BOOL				showingDistanceSort;
    BOOL                showing;
}

@property (nonatomic, strong) NSString *sortType;
@property (nonatomic)   BOOL sorterHidden;
@property (nonatomic) BOOL showingDistanceSort;
@property (nonatomic) BOOL showing;
@property (nonatomic, strong) UIPickerView *theFilterPicker;
@property (nonatomic) UISegmentedControl* sorterControl;
@property (unsafe_unretained, nonatomic) id delegate;

+ (FilterPicker*)sharedFilterPicker;
+ (void) resetContent;
- (void) resetContent;
- (CGPoint) getPickerState;
//- (void) addFilterElement: (NSString*) theFilterElement;
- (NSString*) getPickerTitle;
- (void) removeFavoriteChoice;
- (void) addFavoriteChoice;
- (CGRect) getFrame;
- (void) setPickerToFilter:(NSString*) filter;
- (int) getFilterID;
- (void) hideSorterPicker;
- (void) showSorterPicker;
- (void) addDistanceButton;
- (void) viewWillRotate;
- (void) showControls;
- (void) hideControls;
- (void) hideLabels;
- (void) showLabels;
- (void) initialize;

@end

