/*
 
 File: FilterPicker.m
 Abstract: A custom UIPicker that shows text and images.
 
 Version: 1.7
 */

#import "SorterPicker.h"
#import "CustomView.h"
#import	"Constants.h"
#import	"LocationManager.h"
#import "Properties.h"

@implementation SorterPicker

- (id)initWithFrame:(CGRect)frame andFilterCriteria: (NSString*) theFilterCriteria {
	
	self = [super initWithFrame:frame];
	
	if (self)
	{
		//Picker needs to be just the right height in order to not look weird. There is probably a better way to do this.
		CGSize pickerSize = [self sizeThatFits:CGSizeMake(frame.size.width, frame.size.height)];
		
		self.frame = CGRectMake(kScreenWidth - frame.size.width, -pickerSize.height, frame.size.width, pickerSize.height);
		
		self.delegate = self;
		//self.frame = frame;
		self.showsSelectionIndicator = TRUE;
		
		firstRowPickerViews = [[NSMutableArray alloc] init];
		
		cellFrame = CGRectMake(0, 0, self.frame.size.width - kPickerBorderSize*2, 40);
		
	
		CustomView *nameView = [[CustomView alloc] initWithFrame:cellFrame];
		nameView.title = kSortByName;
		nameView.image = nil; // [UIImage imageNamed:@"byNameSortIconForPicker.png"];
		[firstRowPickerViews addObject:nameView];
		[nameView release];
			
		if([[Properties sharedProperties] hasPrices]) { 
			
			CustomView *costView = [[CustomView alloc] initWithFrame:cellFrame];
			costView.title = kSortByCost;
			costView.image = nil; // [UIImage imageNamed:@"byCostSortIconForPicker.png"];
			[firstRowPickerViews addObject:costView];
			[costView release];
		}
	
		
		if([Properties sharedProperties].hasLocations && ([[LocationManager sharedLocationManager] getLatitude] != -1)) {
			CustomView *distanceView = [[CustomView alloc] initWithFrame:cellFrame];
			distanceView.title = kSortByDistance;
			distanceView.image = nil;// [UIImage imageNamed:@"byDistanceSortIconForPicker.png"];
			[firstRowPickerViews addObject:distanceView];
			[distanceView release];
		
		}
		
		if([[Properties sharedProperties] hasSpatialCategories]) { //put test here for whether or not there are spatial categories
			CustomView *locationView = [[CustomView alloc] initWithFrame:cellFrame];
			locationView.title = [Properties sharedProperties].spatialCategoryName; //[NSString stringWithFormat:@"By Neighborhood"]; //add correct title later
			[firstRowPickerViews addObject:locationView];
			[locationView release];
			
		}
		
		pickerState = 0;
	}
	return self;
}

- (CGRect) getFrame {
	
	return self.frame;
}

- (void)dealloc
{
	[firstRowPickerViews release];
	[super dealloc];
}


#pragma mark UIPicker delegate methods

// tell the picker how many rows are available for a given component (in our case we have one component)
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	NSUInteger numRows;
	
	numRows = (NSUInteger)[firstRowPickerViews count];
	
	return numRows;
}

// tell the picker which view to use for a given component and row, we have an array of color views to show
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row
		  forComponent:(NSInteger)component reusingView:(UIView *)view
{
	UIView *viewToUse = nil;
	
	viewToUse = [firstRowPickerViews objectAtIndex:row];
	
	return viewToUse;
}

// tell the picker how many components it will have (in our case we have one component)
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

// tell the picker the title for a given component (in our case we have one component)
/*- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	NSString *title;
	if (component == 0)
	{
		title = @"color";
	}
	
	if (component == 1)
	{
		title = @"test";
	}
	
	return title;
} *///TF 102209

// tell the picker the width of each row for a given component (in our case we have one component)
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	CGFloat componentWidth;

	componentWidth = self.frame.size.width - kPickerBorderSize*2 -20;	// first column size is wider to hold names
	
	return componentWidth;
}

// tell the picker the height of each row for a given component (in our case we have one component)
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	CustomView *viewToUse;
	
	viewToUse = [firstRowPickerViews objectAtIndex:0];
	
	return viewToUse.bounds.size.height;
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	pickerState = (int) row;	
}


- (int) getPickerState {
	return pickerState;
}


- (int) getActionID {

	int actionID;
	
	CustomView *theView = [firstRowPickerViews objectAtIndex:pickerState];
	
	if (theView.title == kSortByName) actionID = kLVSortByName;
	
	else if (theView.title == kSortByDistance) actionID = kLVSortByDistance;
	
	else if (theView.title == kSortByCost) actionID = kLVSortByCost;
	
	else if (theView.title == kSortBySpatialCategory) actionID = kLVSortBySpatial;
	
	else actionID = kValueNotSet;
	
	return actionID;
}


- (NSString*) getPickerTitle {
	
	CustomView *curentView = [firstRowPickerViews objectAtIndex:pickerState];
		
	return curentView.title;
}

@end
