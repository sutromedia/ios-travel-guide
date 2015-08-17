/*
 
 File: FilterPicker.h
 Abstract: A custom UIPicker that shows text and images.
 
 Version: 1.7
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */

#import <UIKit/UIKit.h>

@interface SorterPicker : UIPickerView <UIPickerViewDelegate>
{
	NSMutableArray* firstRowPickerViews;
	int pickerState;
	CGRect cellFrame;

}

- (id)initWithFrame:(CGRect)frame andFilterCriteria: (NSString*) theFilterCriteria;
- (NSString*) getPickerTitle;
- (int) getPickerState;
- (CGRect) getFrame;
- (int) getActionID;

@end
