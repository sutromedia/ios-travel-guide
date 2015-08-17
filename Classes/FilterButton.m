//
//  FilterButton.m
//  TheProject
//
//  Created by Tobin1 on 12/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FilterButton.h"
#import "FilterPicker.h"
#import "EntriesTableViewController.h"

#define kHintLabelTag 341124

@implementation FilterButton

@synthesize selectBarButton, cancelBarButton, previousSortIndex, hasBeenSelected, controller;

- (id) initWithController:(id) theController {

    NSLog(@"FILTERBUTTON.initWithController");
    self = [super init];
	if (self) {
		
		self.controller = theController;
		previousFilterChoice = [[FilterPicker sharedFilterPicker] getPickerTitle];
		previousSortIndex = [FilterPicker sharedFilterPicker].sorterControl.selectedSegmentIndex;
		
        //UIBarButtonItem *theBarButton = [[UIBarButtonItem alloc] initWithTitle:[self getFormatedPickerTitle] style:UIBarButtonItemStylePlain target:self action:@selector(showFilterAndSortControls)];
        UIBarButtonItem *theBarButton = [[UIBarButtonItem alloc] initWithTitle:[self getFormatedPickerTitle] style:UIBarButtonItemStylePlain target:self action:@selector(showFilterAndSortControls)];

		self.selectBarButton = theBarButton;
        
		UIBarButtonItem *aBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)]; 
		self.cancelBarButton = aBarButton;
        
        hasBeenSelected = FALSE;
	}
	
	
	return self;
}


- (id) init {
    
    NSLog(@"FILTERBUTTON.initWithController");
    self = [super init];
	if (self) {
		
		previousFilterChoice = [[FilterPicker sharedFilterPicker] getPickerTitle];
		previousSortIndex = [FilterPicker sharedFilterPicker].sorterControl.selectedSegmentIndex;
		
        //UIBarButtonItem *theBarButton = [[UIBarButtonItem alloc] initWithTitle:[self getFormatedPickerTitle] style:UIBarButtonItemStylePlain target:self action:@selector(showFilterAndSortControls)];
        UIBarButtonItem *theBarButton = [[UIBarButtonItem alloc] initWithTitle:[self getFormatedPickerTitle] style:UIBarButtonItemStylePlain target:self action:@selector(showFilterAndSortControls)];
        
		self.selectBarButton = theBarButton;
        
		UIBarButtonItem *aBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)]; 
		self.cancelBarButton = aBarButton;
        
        hasBeenSelected = FALSE;
	}
	
	
	return self;
}


- (void) dealloc {
    
    NSLog(@"FILTERBUTTON.dealloc");
}


- (void) cancel {

	NSLog(@"Canceling");
	[[FilterPicker sharedFilterPicker] setPickerToFilter:previousFilterChoice];
	[FilterPicker sharedFilterPicker].sorterControl.selectedSegmentIndex = previousSortIndex;
	[controller hideFilterPicker:nil];
}


- (void) showFilterAndSortControls {
	
	hasBeenSelected = TRUE;
    
    previousFilterChoice = [[FilterPicker sharedFilterPicker] getPickerTitle];
	previousSortIndex = [FilterPicker sharedFilterPicker].sorterControl.selectedSegmentIndex;
	
	[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kFilterButtonPressed];
	[controller showFilterPicker:nil];
	
}


- (void) update {

	NSLog(@"FILTERBUTTON.update");
	
	//UIBarButtonItem *theBarButton = [[UIBarButtonItem alloc] initWithCustomView:pickerButton];
    UIBarButtonItem *theBarButton = [[UIBarButtonItem alloc] initWithTitle:[self getFormatedPickerTitle] style:UIBarButtonItemStylePlain target:self action:@selector(showFilterAndSortControls)];
    theBarButton.style = UIBarButtonItemStyleBordered;
	self.selectBarButton = theBarButton;
}


- (NSString*) getFormatedPickerTitle {
    
    NSString *_pickerTitle = ([Props global].filters != nil) ? [[FilterPicker sharedFilterPicker] getPickerTitle] : [FilterPicker sharedFilterPicker].sortType;
    
    if (!hasBeenSelected && [_pickerTitle isEqualToString:@"Everything"]) {
        
        if ([Props global].deviceType == kiPad || [[Props global] inLandscapeMode] || ![controller isKindOfClass:[EntriesTableViewController class]]) _pickerTitle = @"Filter  ";
        
        else _pickerTitle = @"Filter and Sort  ";
    }
    
    //NSLog(@"Picker title = %@", _pickerTitle);
	
    NSMutableString *pickerTitle = [NSMutableString stringWithString:_pickerTitle];
    
    int length = [Props global].deviceType == kiPad ? 40 : 15;
    
    if ([Props global].deviceType != kiPad && [Props global].osVersion >= 7.0) {
        int maxLength = 19;
        if ([pickerTitle length] > maxLength){
            pickerTitle = [NSMutableString stringWithString:[pickerTitle substringToIndex:maxLength - 3]];
            [pickerTitle appendString:@"..."];
        }
    }
	
    while ([pickerTitle length] < length) {
        [pickerTitle insertString:@" " atIndex:0];
        [pickerTitle appendString:@" "];
    }
    
    [pickerTitle appendString:@"▼"];
    
    return pickerTitle;
}


- (void) addHint {

	NSString *pickerTitle = [pickerButton titleForState:UIControlStateNormal];
	[pickerButton setTitle:[NSString stringWithFormat:@"%@                                 ", pickerTitle] forState:0];
	UILabel *hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, pickerButton.frame.origin.y, 185, pickerButton.frame.size.height)];
	hintLabel.textAlignment = UITextAlignmentLeft;
	hintLabel.backgroundColor = [UIColor clearColor];
	hintLabel.font = [UIFont fontWithName:kFontName size:13];
	hintLabel.textColor = [UIColor grayColor];
	hintLabel.text = @"<-- Tap to filter or sort list";
	hintLabel.tag = kHintLabelTag;
	
	[pickerButton addSubview:hintLabel];
	
	pickerButton.frame = CGRectMake(pickerButton.frame.origin.x, pickerButton.frame.origin.y,CGRectGetMaxX(hintLabel.frame) - CGRectGetMinX(pickerButton.frame), pickerButton.frame.size.height);
}


@end
