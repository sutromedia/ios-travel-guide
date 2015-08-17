//
//  AppPicker.m
//  TravelGuideSF
//
//  Created by Tobin1 on 8/17/09.
//  Copyright 2009 Ard ica Technologies. All rights reserved.
//

#import "AppPicker.h"
#import "CustomView.h"
#import	"Constants.h"
#import "Props.h"
#import "EntryCollection.h"

@implementation AppPicker


- (id)initWithFrame: (CGRect) frame andApps:(NSArray*) theAppArray
{
	
	//float pickerHeight = 180;
	//float pickerWidth = 200;
	
	self = [super initWithFrame:frame];
	
	if (self)
	{
		
		//CGSize pickerSize = [self sizeThatFits:CGSizeMake(frame.size.width, frame.size.height)];
		
		//self.frame = CGRectMake(0, -pickerSize.height, frame.size.width, pickerSize.height);
		
		self.delegate = self;
		self.frame = frame;
		self.showsSelectionIndicator = TRUE;
        self.backgroundColor = [UIColor whiteColor];
		
		//firstRowPickerViews = [[NSMutableArray alloc] init];
		
		//NSArray *filterTypes = theAppArray; // [Props global].filters;
        
        firstRowPickerViews = [NSArray arrayWithArray:theAppArray];
		/*
		int i;
		for(i=0; i < [filterTypes count]; i++) {[self addFilterElement:[filterTypes objectAtIndex: i]];}	
        */
        
        theRow = 0;
        theComponent = 0;
        pickerState = CGPointMake(0,0);
	}
	
	return self;
}

/*- (void) addFilterElement: (NSString*) theFilterElement {
	
	CGRect cellFrame = CGRectMake(kPickerBorderSize, 0, self.frame.size.width - kPickerBorderSize*2, 35);
	
	CustomView *theView = [[CustomView alloc] initWithFrame:cellFrame];
	theView.title = theFilterElement;
	
    [firstRowPickerViews addObject:theView];
	
}*/


- (void) setComponentWidth: (CGFloat) theWidth {
	
	componentWidth = theWidth;
}

/*
- (void) removeFavoriteChoice {
	
	CustomView *currentView = [firstRowPickerViews objectAtIndex:[self selectedRowInComponent:0]];
	[firstRowPickerViews removeObject:favoriteView];
	[self reloadComponent:0];
	
	if([firstRowPickerViews containsObject:currentView]) 
		[self selectRow: [firstRowPickerViews indexOfObject:currentView] inComponent:0 animated:NO];
}


- (void) addFavoriteChoice {
	CustomView *currentView = [firstRowPickerViews objectAtIndex:[self selectedRowInComponent:0]];
	[firstRowPickerViews addObject:favoriteView];
	[firstRowPickerViews sortUsingSelector:@selector(compareTitles:) ];
	[self reloadComponent:0];
	[self selectRow: [firstRowPickerViews indexOfObject:currentView] inComponent:0 animated:NO];
	
}*/




#pragma mark UIPicker delegate methods

// tell the picker how many rows are available for a given component (in our case we have one component)
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	NSUInteger numRows = (NSUInteger)[firstRowPickerViews count];
	
	return numRows;
}

// tell the picker which view to use for a given component and row, we have an array of color views to show
/*- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row
		  forComponent:(NSInteger)component reusingView:(UIView *)view
{
	UIView *viewToUse = [firstRowPickerViews objectAtIndex:row];
	
	return viewToUse;
}*/


// tell the picker how many components it will have (in our case we have one component)
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    // create attributed string
   /* NSString *yourString = [firstRowPickerViews objectAtIndex:row];  //can also use array[row] to get string
    NSDictionary *attributeDict = @{NSForegroundColorAttributeName : [UIColor blackColor]};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:yourString attributes:attributeDict];*/
    
    // add the string to a label's attributedText property
    UILabel *labelView = [[UILabel alloc] init];
    labelView.text = [firstRowPickerViews objectAtIndex:row];
    labelView.font = [UIFont fontWithName:kFontName size:14];
    
    // return the label
    return labelView;
}

/*
// tell the picker the title for a given component (in our case we have one component)
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return [firstRowPickerViews objectAtIndex:row];
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    
    NSString *title = [firstRowPickerViews objectAtIndex:row];
    
    NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:title];
    NSMutableParagraphStyle *mutParaStyle=[[NSMutableParagraphStyle alloc] init];
    mutParaStyle.alignment = NSTextAlignmentLeft;
    [as addAttribute:NSParagraphStyleAttributeName value:mutParaStyle range:NSMakeRange(0,[title length])];
 
    
    [as addAttribute:NSFontAttributeName
               value:[UIFont fontWithName:kFontName size:8]
               range:NSMakeRange(0, [title length])];
    
    NSLog(@"Attributes = %@", [as attribute:<#(NSString *)#> atIndex:<#(NSUInteger)#> effectiveRange:<#(NSRangePointer)#>])
    
    return as;
    
    //[attrTitle addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:10] range:NSMakeRange(0, [attrTitle length])];
    
    //return attrTitle;
}*/

// tell the picker the width of each row for a given component (in our case we have one component)
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	return self.frame.size.width - kPickerBorderSize * 2 - 20;
}

// tell the picker the height of each row for a given component (in our case we have one component)
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	//CustomView *viewToUse = [firstRowPickerViews objectAtIndex:0];
	
	return 20; //viewToUse.bounds.size.height;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	
	theRow = (int) row;
	theComponent = (int) component;
	
	pickerState.x = theRow;
	
}

- (NSString*) getPickerTitle {
	
	//CustomView *curentView = [firstRowPickerViews objectAtIndex: [self selectedRowInComponent:0]];
	
	return [firstRowPickerViews objectAtIndex: [self selectedRowInComponent:0]]; //curentView.title;
}


- (CGPoint) getPickerState {
	return pickerState;
}



@end
