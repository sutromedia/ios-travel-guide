

#import "FilterPicker.h"
//#import "CustomView.h"
#import	"Constants.h"
#import "Props.h"
#import "EntryCollection.h"
#import "LocationManager.h"
#import "EntriesTableViewController.h"
#import "CommentsViewController.h"
//#import "FilterPicker_old.h"


#define kHintLabelTag 98723450

@interface FilterPicker (PrivateMethods)

- (void) createSortButtons;
- (void) balanceSorterButtonSizes;
- (void) createFilterPicker;
- (void) createFilterButton;
- (void) addDropShadowAtYPosition:(float) viewHeight;
- (void) showBottomBar;
- (void) hideBottomBar;

@end


@implementation FilterPicker

@synthesize sortType, showingDistanceSort, theFilterPicker, sorterControl, showing;
@synthesize delegate, sorterHidden;

- (id)init
{	
    float frameWidth = [Props global].deviceType == kiPad ? 768/2 : 320;
	CGRect frame = CGRectMake(0, - 1, frameWidth, 1);
	
    self = [super initWithFrame:frame];
	if (self) {
	
        [self initialize];
		
	}
	
	//NSLog(@"FILTERPICKER.init: frame height = %f", self.frame.size.height);
	
	return self;
}


- (void) initialize {
    
    self.backgroundColor = [UIColor colorWithWhite:0.275 alpha:0.97];
    
    //[self createFilterButton];
    
    sorterControl = nil;
    self.theFilterPicker = nil;
    sortLabel = nil;
    filterLabel = nil;
    
    for (UIView *view in [self subviews]) {
        [view removeFromSuperview];
    }
    
    float viewHeight = 0;
    
    //heightWithoutSort = 0;
    //heightWithSort = 0;
    
    if ([Props global].filters != nil){
        [self createFilterPicker];
        //**viewHeight = CGRectGetMaxY(self.theFilterPicker.frame) + kBottomMargin - 2;
        viewHeight = CGRectGetMaxY(self.theFilterPicker.frame) + kBottomMargin - 2;
    }
    
    if ([Props global].sortable) {
        sorterHidden = FALSE;
        self.showingDistanceSort = FALSE;
        [self createSortButtons];
        viewHeight = CGRectGetMaxY(sorterControl.frame);
        //heightWithSort = viewHeight + 3;
    }
    
    UIImage *background = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pickerDoneButton" ofType:@"png"]];
    UIImage *stretchableBackground = [background stretchableImageWithLeftCapWidth:20 topCapHeight:0];
    float width =  self.frame.size.width - [Props global].leftMargin - [Props global].rightMargin + 5;
    
    selectButton = [UIButton buttonWithType: 0]; 
    [selectButton setBackgroundColor: [UIColor clearColor]];
    [selectButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:1] forState:UIControlStateNormal];
    [selectButton setTitle:@"Apply" forState:0];	
    //selectButton.alpha = 0.9;
    [selectButton addTarget:self action:@selector(hideFilterPicker) forControlEvents:UIControlEventTouchUpInside];
    selectButton.titleLabel.font =[UIFont boldSystemFontOfSize:20];
    selectButton.titleLabel.shadowOffset = CGSizeMake(.7, .7);
    [selectButton setBackgroundImage:stretchableBackground forState:UIControlStateNormal];
    [selectButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    [selectButton setTitleShadowColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
    selectButton.frame = CGRectMake((self.frame.size.width - width)/2 - 1, viewHeight + 10, width, 32);
    [self addSubview:selectButton];
    viewHeight = CGRectGetMaxY(selectButton.frame) + 10;
    
    //[self addDropShadowAtYPosition: viewHeight];
    //viewHeight += 5;
    
    self.frame = CGRectMake(0, - viewHeight, self.frame.size.width, viewHeight);

}


- (void)dealloc {
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) createFilterPicker {
	//NSLog(@"FILTERPICKER.createFilterPicker");
	//Add label
    if (filterLabel == nil) {
        filterLabel = [[UILabel alloc] initWithFrame:CGRectMake([Props global].leftMargin, [Props global].tinyTweenMargin - 2, 120, 21)];
        filterLabel.text = @"Filter to:";
        filterLabel.backgroundColor = [UIColor clearColor];
        filterLabel.textColor = [UIColor whiteColor];
        filterLabel.font = [UIFont fontWithName:kFontName size:16];
        filterLabel.alpha = .75;
        [self addSubview:filterLabel];
    }
	
	if (self.theFilterPicker == nil) {
        UIPickerView *tmpPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(filterLabel.frame)+[Props global].tinyTweenMargin - 3, self.frame.size.width, 215)];
        self.theFilterPicker = tmpPickerView;
        self.theFilterPicker.showsSelectionIndicator = YES;
        self.theFilterPicker.backgroundColor = [UIColor whiteColor];
        self.theFilterPicker.delegate = self;
    }
	
	
	firstRowPickerViews = [[NSMutableArray alloc] init];		
	
	int i;
    
    if ([[EntryCollection sharedEntryCollection] favoritesExist]) [firstRowPickerViews addObject:kFavorites];
    
    [firstRowPickerViews addObject:@"Everything"];
    
	for(i=0; i < [[Props global].filters count]; i++) {
        [firstRowPickerViews addObject:[[Props global].filters objectAtIndex: i]];
		//[self addFilterElement:[[Props global].filters objectAtIndex: i]];
	}
	
	//[firstRowPickerViews sortUsingSelector:@selector(compareTitles:)];
	//[firstRowPickerViews sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    
    NSString *filterKey = [NSString stringWithFormat:@"%@_%i", kLastFilter, [Props global].appID];
    NSString *lastFilter = [[NSUserDefaults standardUserDefaults] objectForKey:filterKey];
    [self setPickerToFilter: lastFilter];
    

	theRow = 0;
	theComponent = 0;
	pickerState = CGPointMake(theRow,theComponent);
	
	[self addSubview:theFilterPicker];
}


/*- (NSComparisonResult)compareTitles:(NSString *) theTitle {
	
	return [self.title caseInsensitiveCompare: theView.title]; // [[NSNumber numberWithInt:[self score]] compare:[NSNumber numberWithInt:[highScore score]]];
}*/




- (void) createSortButtons {
	
	//NSLog(@"FILTERPICKER.createSortButtons");
	//NSLog(@"Adding sort buttons");
	
	NSMutableArray *segmentTextContent = [NSMutableArray new];
	
    [segmentTextContent addObject: kSortByName];
	
	if ([Props global].hasLocations && [[LocationManager sharedLocationManager] getLatitude] != kValueNotSet) {
		[segmentTextContent addObject:kSortByDistance];
		self.showingDistanceSort = TRUE;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
	}
    
    else [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDistanceButton) name:kLocationUpdated object:nil];
	
	if ([Props global].hasPrices) [segmentTextContent addObject:kSortByCost];
	
	if ([Props global].hasSpatialCategories) [segmentTextContent addObject:[Props global].spatialCategoryName];
    
    if ([Props global].appID == 1) [segmentTextContent addObject: kSortByPopularity];
	
	
	if ([segmentTextContent count] > 0) {
		
		//CGRect sortLabelFrame = (theFilterPicker != nil || TRUE) ? CGRectMake([Props global].leftMargin, /*CGRectGetMaxY(self.theFilterPicker.frame)*/ 150 + [Props global].tinyTweenMargin, self.frame.size.width - 10, 21) : CGRectMake([Props global].leftMargin, [Props global].tinyTweenMargin, self.frame.size.width - 10, 21);
		
        if (sortLabel == nil) {
            CGRect sortLabelFrame = (theFilterPicker != nil) ? CGRectMake([Props global].leftMargin, CGRectGetMaxY(self.theFilterPicker.frame) + [Props global].tinyTweenMargin, self.frame.size.width - 10, 21) : CGRectMake([Props global].leftMargin, [Props global].tinyTweenMargin, self.frame.size.width - 10, 21);
            
            sortLabel = [[UILabel alloc] initWithFrame: sortLabelFrame];
            sortLabel.text = @"Sort by:";
            sortLabel.backgroundColor = [UIColor clearColor];
            sortLabel.textColor = [UIColor whiteColor];
            sortLabel.font = [UIFont fontWithName:kFontName size:16];
            sortLabel.alpha = .75;
            sortLabel.hidden = sorterHidden;
            [self addSubview:sortLabel];
        }
		
		if (sorterControl == nil) {
            sorterControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
            sorterControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            sorterControl.segmentedControlStyle = UISegmentedControlStyleBar;
            sorterControl.alpha = .8;
            sorterControl.tintColor = [UIColor colorWithWhite:0.5 alpha:1.0];
            sorterControl.frame = CGRectMake([Props global].leftMargin, CGRectGetMaxY(sortLabel.frame) + [Props global].tinyTweenMargin - 3, self.frame.size.width - [Props global].leftMargin - [Props global].rightMargin, 32);
            [sorterControl addTarget: self action:@selector(toggleSortType:) forControlEvents:UIControlEventValueChanged];
            [self addSubview:sorterControl];
        }
		
        sorterControl.hidden = sorterHidden;
        
        int i;
        int selectedSegmentIndex = 0;
        
        NSString *sortKey = [NSString stringWithFormat:@"%@_%i", kLastSort, [Props global].appID];
        NSString *lastSort = [[NSUserDefaults standardUserDefaults] objectForKey:sortKey];
        
        if ([Props global].appID == 1 && lastSort == nil) lastSort = [Props global].spatialCategoryName;
        
        for (i = 0; i < [sorterControl numberOfSegments]; i++) {
            
            if ([[sorterControl titleForSegmentAtIndex:i] isEqualToString:lastSort]) {
                selectedSegmentIndex = i;
                break;
            }
        }
        
        //sorterControl.selectedSegmentIndex = [Props global].appID == 1 ? (self.showingDistanceSort ? 2 : 1) : 0;
        sorterControl.selectedSegmentIndex = selectedSegmentIndex;
        //NSLog(@"FILTERPICKER.createSortButtons: Selected index = %i", sorterControl.selectedSegmentIndex);
        
        self.sortType = [sorterControl titleForSegmentAtIndex:sorterControl.selectedSegmentIndex];
        [self balanceSorterButtonSizes];

		[self addSubview:sorterControl];
	}	
	
}


- (void) addDropShadowAtYPosition:(float)viewHeight {
    
    UIImage* dropShadow =[[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dropShadow" ofType:@"png"]];
	dropViewer = [[UIImageView alloc] initWithImage:dropShadow];
	dropViewer.frame =  CGRectMake(0, viewHeight, self.frame.size.width, 5);
	dropViewer.alpha = 1.0;
	[self addSubview:dropViewer];
}


- (void) hideFilterPicker {[delegate hideFilterPicker:nil];}


- (void) select {[self hideControls];}


- (void) showControls {
	
	if ([[Props global] inLandscapeMode] && [Props global].deviceType != kiPad) [self hideLabels];
	
	//We use a transparent titlebar on the map and slideshow and need to adjust the y-origin of the frame
	float frameY = ([delegate isKindOfClass:[EntriesTableViewController class]] || [delegate isKindOfClass:[CommentsViewController class]]) ? 0 : [Props global].titleBarHeight;
	
	[ UIView beginAnimations: nil context: nil ];
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[ UIView setAnimationDuration: 0.8f ]; // Set the duration to 1 second.
	
	self.frame = CGRectMake(self.frame.origin.x, frameY, self.frame.size.width, self.frame.size.height); 
	self.alpha = 1;
	
	if ([[Props global] inLandscapeMode] && [Props global].deviceType != kiPad)[self hideBottomBar];
	
	[ UIView commitAnimations ];
	
    showing = TRUE;
}


- (void) hideControls {
	
	[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[ UIView setAnimationDuration: 0.8f ]; // Set the duration to 1 second.
	
	self.frame = CGRectMake(self.frame.origin.x, - self.bounds.size.height, self.bounds.size.width, self.bounds.size.height); 
	self.alpha = 0;
	if ([Props global].deviceType != kiPad) [self showBottomBar];
	
	[ UIView commitAnimations ];
	
	[self performSelector:@selector(showLabels) withObject:nil afterDelay:0.8];
    
    showing = FALSE;
    
    SMLog *log = [[SMLog alloc] initPopularityLog];
	log.filter_id = [self getFilterID];
	[[ActivityLogger sharedActivityLogger] sendPopularityLog: [log createPopularityLog]];
}


- (void)toggleSortType:(id)sender {
	
	UISegmentedControl *segControl = sender;
	
	self.sortType = [segControl titleForSegmentAtIndex:segControl.selectedSegmentIndex];
}


- (void) hideSorterPicker {

	NSLog(@"FILTERPICKER.hideSorterPicker: called");
	sorterControl.hidden = TRUE;
	sortLabel.hidden = TRUE;
	sorterHidden = TRUE;
	selectButton.frame = CGRectMake(selectButton.frame.origin.x, CGRectGetMaxY(theFilterPicker.frame) + 10, selectButton.frame.size.width, selectButton.frame.size.height);
    //dropViewer.frame = CGRectMake(0, CGRectGetMaxY(selectButton.frame) + 10, self.frame.size.width, dropViewer.frame.size.height);
    float height = CGRectGetMaxY(selectButton.frame) + 10;
	self.frame = CGRectMake(self.frame.origin.x, -height, self.frame.size.width, height);
}


- (void) showSorterPicker {
	
	sorterControl.hidden = FALSE;
	sorterHidden = FALSE;
	sortLabel.hidden = FALSE;
	CGRect selectButtonFrame;
    
    if (sorterControl != nil) selectButtonFrame = CGRectMake(selectButton.frame.origin.x, CGRectGetMaxY(sorterControl.frame) + 10, selectButton.frame.size.width, selectButton.frame.size.height);
    
    else selectButtonFrame = CGRectMake(selectButton.frame.origin.x, CGRectGetMaxY(theFilterPicker.frame) + 10, selectButton.frame.size.width, selectButton.frame.size.height);
    
	selectButton.frame = selectButtonFrame;
    
	//dropViewer.frame = CGRectMake(0, CGRectGetMaxY(selectButton.frame) + 10, self.frame.size.width, dropViewer.frame.size.height);
    float height = CGRectGetMaxY(selectButton.frame) + 10;
	self.frame = CGRectMake(self.frame.origin.x, -height, self.frame.size.width, height);
}


- (void) addDistanceButton {
	
    NSLog(@"FILTERPICKER.addDistanceButton:");
	
    if (!self.showingDistanceSort) {
		
		[sorterControl insertSegmentWithTitle: kSortByDistance atIndex:1 animated:NO];
		
		self.showingDistanceSort = TRUE;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDistanceSortAdded object:nil];
	}
	
	[self balanceSorterButtonSizes];
}


- (void) balanceSorterButtonSizes {

	int i;
	int totalTitleLengths = 0;
	
	for (i = 0;i < sorterControl.numberOfSegments; i++) {
		NSString *title = [sorterControl titleForSegmentAtIndex:i];
		totalTitleLengths += [title length];
		//NSLog(@"total title lengths = %i", totalTitleLengths);
	}
	
	if (totalTitleLengths != 0) {
		
		for (i = 0;i < sorterControl.numberOfSegments - 1; i++) {
			NSString *title = [sorterControl titleForSegmentAtIndex:i];
			float segmentWidth =  ((float)[title length]/totalTitleLengths) * ((self.frame.size.width - 20) - 40 * sorterControl.numberOfSegments) + 40;
			[sorterControl setWidth:segmentWidth forSegmentAtIndex:i];
		}
	}
}


- (CGRect) getFrame {
	
	return self.frame;
}


/*- (void) addFilterElement: (NSString*) theFilterElement {
    
	NSLog(@"Adding %@", theFilterElement);
    
	if(![theFilterElement  isEqual: kFavorites] || [[EntryCollection sharedEntryCollection] favoritesExist])
        [firstRowPickerViews addObject:theFilterElement];
    
    //else [firstRowPickerViews addObject:theFilterElement];  //*** New 0821
	
	if([theFilterElement  isEqual: kFavorites])
		favoriteView = theFilterElement;
}*/


- (void) setComponentWidth: (CGFloat) theWidth {
	
	componentWidth = theWidth;
}


- (void) removeFavoriteChoice {

	NSString *currentView= [firstRowPickerViews objectAtIndex:[self.theFilterPicker selectedRowInComponent:0]];
	[firstRowPickerViews removeObject:kFavorites];
	[self.theFilterPicker reloadComponent:0];
	
	if([firstRowPickerViews containsObject:currentView]) 
		[self.theFilterPicker selectRow: [firstRowPickerViews indexOfObject:currentView] inComponent:0 animated:NO];
	
	else [self.theFilterPicker selectRow:0 inComponent:0 animated:NO];
}


- (void) addFavoriteChoice {
	NSString *currentView = [firstRowPickerViews objectAtIndex:[self.theFilterPicker selectedRowInComponent:0]];
	//[firstRowPickerViews addObject:favoriteView];
    [firstRowPickerViews insertObject:kFavorites atIndex:0];
	
	/*CustomView *allView = [firstRowPickerViews objectAtIndex:0];
	[allView retain];
	[firstRowPickerViews removeObjectAtIndex:0];
	[firstRowPickerViews sortUsingSelector:@selector(compareTitles:) ];
	[firstRowPickerViews insertObject:allView atIndex:0];
	[allView release]; Was commented out, just uncommented 090210*/
	[self.theFilterPicker reloadComponent:0];
	[self.theFilterPicker selectRow: [firstRowPickerViews indexOfObject:currentView] inComponent:0 animated:NO];

}


#pragma mark UIPicker delegate methods

// tell the picker how many rows are available for a given component (in our case we have one component)
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	NSUInteger numRows = (NSUInteger)[firstRowPickerViews count];
	//NSUInteger numRows = (NSUInteger)[filters count];
	
	return numRows;
}

/*
- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return [firstRowPickerViews objectAtIndex:row];
}
*/



- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSMutableAttributedString *attrTitle = nil;
    
    NSString *title = [firstRowPickerViews objectAtIndex:row];
    
    NSLog(@"Returing %@ for row %i", title, row);
    NSLog(@"Picker views has %i elements", [firstRowPickerViews count]);
    
    attrTitle = [[NSMutableAttributedString alloc] initWithString:title];
    
    if (row == 0 || [title isEqualToString:kFavorites]) [attrTitle addAttribute:NSStrokeWidthAttributeName
                          value:[NSNumber numberWithFloat:-3.0]
                          range:NSMakeRange(0, [attrTitle length])];
 
    
    //else  attrTitle = [[NSMutableAttributedString alloc] initWithString:@"yo"];
    
    return attrTitle;
}


- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return [firstRowPickerViews objectAtIndex:row];
}


- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {return 1;}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {return self.frame.size.width - kPickerBorderSize * 2 - 20;}


- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	//CustomView *viewToUse = [firstRowPickerViews objectAtIndex:0];

	return 30; //** viewToUse.bounds.size.height;
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	
	theRow = (int) row;
	theComponent = (int) component;
	
	pickerState.x = theRow;	
}


/*
- (void) setPickerToFilter:(NSString*) theFilter {

	int i;
	int row = 0;
	
	CustomView *curentView;
	
	for (i=0; i < [firstRowPickerViews count]; i++) {
		
		curentView = [firstRowPickerViews objectAtIndex:i];
		
		//NSLog(@"FILTERPICKER.setPickerToFilter:test title = %@ and target title = %@", curentView.title, theFilter);
		
		if([curentView.title isEqualToString: theFilter]) {
			
			row = i;
			i = [firstRowPickerViews count];
			//break;
		}
	}
	
	[self.theFilterPicker selectRow:row inComponent:0 animated:NO];
}
*/

- (void) setPickerToFilter:(NSString*) theFilter {
    
	int i;
	int row = 0;
    
    NSString *title;
	
	for (i=0; i < [firstRowPickerViews count]; i++) {
		
		title = [firstRowPickerViews objectAtIndex:i];
		
		//NSLog(@"FILTERPICKER.setPickerToFilter:test title = %@ and target title = %@", curentView.title, theFilter);
		
		if([title isEqualToString: theFilter]) {
			
			row = i;
			i = [firstRowPickerViews count];
			//break;
		}
	}
	
	[self.theFilterPicker selectRow:row inComponent:0 animated:NO];
}


- (NSString*) getPickerTitle {

    //**CustomView *curentView = [firstRowPickerViews objectAtIndex: [self.theFilterPicker selectedRowInComponent:0]];
    //**return curentView.title;
    
	return [firstRowPickerViews objectAtIndex: [self.theFilterPicker selectedRowInComponent:0]];
}


- (int) getFilterID {
	
	int filterID = kValueNotSet;
	
	NSString *title = [firstRowPickerViews objectAtIndex: [self.theFilterPicker selectedRowInComponent:0]];
	
	NSLog(@"FILTERPICKER.getFilterID: filter = %@", title);
	
	@synchronized([Props global].dbSync) {
		FMDatabase * db = [EntryCollection sharedContentDatabase];
		NSString * query = @"SELECT rowid FROM groups WHERE groups.name = ?";
		
		FMResultSet * rs = [db executeQuery:query, title];
		
		if ([db hadError]) NSLog(@"sqlite error in FilterPicker getPickerID, query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
		
		else if ([rs next]) filterID = [rs intForColumn:@"rowid"];
		
		else if ([title isEqualToString:@"Everything"]) filterID = 0;
		
		else NSLog(@"ERROR - Could not find FilterID in getFilterID");
		
		[rs close];
	}
	
	return filterID;
}
	

- (CGPoint) getPickerState {
	return pickerState;
}


- (void) hideLabels {
	
	filterLabel.hidden = TRUE;
	sortLabel.hidden = TRUE;
	theFilterPicker.frame = CGRectMake(0, 0, self.frame.size.width, theFilterPicker.frame.size.height);
	float selectButtonY = CGRectGetMaxY(theFilterPicker.frame) + 10;
	if(!sorterHidden && sortLabel != nil) {
		sorterControl.frame = CGRectMake(sorterControl.frame.origin.x, CGRectGetMaxY(theFilterPicker.frame) + 2, sorterControl.frame.size.width, sorterControl.frame.size.height);
		selectButtonY = CGRectGetMaxY(sorterControl.frame) + 2;
	}
		
	selectButton.frame = CGRectMake(selectButton.frame.origin.x, selectButtonY, selectButton.frame.size.width, selectButton.frame.size.height);
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, CGRectGetMaxY(selectButton.frame) + 10);
}


- (void) showLabels {
	
	filterLabel.hidden = FALSE;
	if(!sorterHidden && sortLabel != nil) sortLabel.hidden = FALSE;
	
	theFilterPicker.frame = CGRectMake(0, CGRectGetMaxY(filterLabel.frame) + [Props global].tinyTweenMargin - 3, theFilterPicker.frame.size.width, theFilterPicker.frame.size.height);
	sorterControl.frame = CGRectMake(sorterControl.frame.origin.x, CGRectGetMaxY(sortLabel.frame) + [Props global].tinyTweenMargin - 3, sorterControl.frame.size.width, sorterControl.frame.size.height);
	
	float selectY = (sorterHidden || sortLabel == nil) ? CGRectGetMaxY(theFilterPicker.frame) + 10 : CGRectGetMaxY(sorterControl.frame) + 10;
	selectButton.frame = CGRectMake(selectButton.frame.origin.x, selectY + [Props global].tinyTweenMargin - 3, selectButton.frame.size.width, selectButton.frame.size.height);
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, CGRectGetMaxY(selectButton.frame) + 10);
}


- (void) hideBottomBar {
	
	NSLog(@"FILTERPICKER.hideBottomBar");
	
	//float hideTabBarHeight, hideTabBarWidth;
	CGRect newScreenRect; // = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
	
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    NSLog(@"Orientation = %u", orientation);
	
	if (orientation == UIDeviceOrientationLandscapeRight || ([Props global].lastOrientation == UIDeviceOrientationLandscapeRight && orientation == UIDeviceOrientationFaceUp)) {
		
		NSLog(@"In landscape right");
        if([Props global].isShellApp) newScreenRect = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight + kTabBarHeight);
        
        else newScreenRect = CGRectMake(0, 0, [Props global].screenHeight + kTabBarHeight, [Props global].screenWidth);
        
        EntriesTableViewController *controller = (EntriesTableViewController*) delegate;
        
        controller.tabBarController.view.frame = newScreenRect; // CGRectMake(0, 0, hideTabBarWidth, hideTabBarHeight);
	}
	
	else if (orientation == UIDeviceOrientationLandscapeLeft || ([Props global].lastOrientation == UIDeviceOrientationLandscapeLeft && orientation == UIDeviceOrientationFaceUp)) {
		
		NSLog(@"In landscape left");
        if([Props global].isShellApp)newScreenRect = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight + kTabBarHeight);
        
        else newScreenRect = CGRectMake(-kTabBarHeight, 0, [Props global].screenHeight + kTabBarHeight, [Props global].screenWidth);
        
        EntriesTableViewController *controller = (EntriesTableViewController*) delegate;
        
        controller.tabBarController.view.frame = newScreenRect; // CGRectMake(0, 0, hideTabBarWidth, hideTabBarHeight);
	}
}


- (void) showBottomBar {
	
	EntriesTableViewController *controller = (EntriesTableViewController*) delegate;
	
	if ([Props global].deviceType != kiPad && [[Props global] inLandscapeMode] && [Props global].osVersion > 3.1){
		
        NSLog(@"FILTERPICKER.showBottomBar: Setting partial hide height");
		
        if ([Props global].isShellApp) controller.tabBarController.view.frame = CGRectMake( 0,0, [Props global].screenWidth, [Props global].screenHeight + kPartialHideTabBarHeight);
            
        else {
            float xPos =  [[UIDevice currentDevice] orientation]==UIDeviceOrientationLandscapeLeft || [Props global].lastOrientation == UIDeviceOrientationLandscapeLeft ? -kPartialHideTabBarHeight : 0;
            controller.tabBarController.view.frame = CGRectMake( xPos,0, [Props global].screenHeight + kPartialHideTabBarHeight, [Props global].screenWidth);
        }
	}
	
	else controller.tabBarController.view.frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
}


- (void) viewWillRotate {
    
    if ([Props global].deviceType != kiPad) {
        float frameY = ([delegate isKindOfClass:[EntriesTableViewController class]]) ? 0 : [Props global].titleBarHeight;
        self.frame = CGRectMake(self.frame.origin.x, frameY, self.frame.size.width, self.frame.size.height);
        
        if ([[Props global] inLandscapeMode])[self hideLabels];
        else [self showLabels];
        
        [self hideBottomBar];
    }
}

/*
 - (NSString*) createHTMLForTags {
 
 NSString *htmlTagString = @"";
 
 NSString *header = [NSString stringWithFormat:@"<html><head><title>Sutro Media</title><style type=\"text/css\"> A:link{text-decoration: none; -webkit-tap-highlight-color:rgba(0,0,0,0);} .SMTag{font-weight:700; color:%@} body{padding:0; font-family:'Arial'; font-size:%0.0fpx; margin-bottom:0; padding:0; margin:0; border:0; color:%@;} </style></head><body><div id='pageContent'>", [Props global].cssLinkColor, [Props global].bodyTextFontSize, [Props global].cssTextColor];
 
 FMResultSet * rs;
 
 @synchronized([Props global].dbSync) {
 
 FMDatabase * db = [EntryCollection sharedContentDatabase];
 NSString * query = [NSString stringWithFormat:@"SELECT name, rowid FROM groups"];
 
 rs = [db executeQuery:query];
 
 if ([db hadError]) (@"sqlite error in [PictureView initImageArray], query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
 }
 
 
 while ([rs next]) {
 
 NSString *tagString = [[rs stringForColumn:@"name"] stringByReplacingOccurrencesOfString:@" " withString:@"&nbsp;"];
 
 htmlTagString = [htmlTagString stringByAppendingString:[NSString stringWithFormat:@"<a class='SMTag' href='SMTag:%i'>%@</a>, ",[rs intForColumn:@"rowid"], tagString]];
 } 
 
 
 if ([htmlTagString length] >= 2) htmlTagString = [htmlTagString substringToIndex:([htmlTagString length]-3)];
 
 else htmlTagString = nil;
 
 NSString *footer = @"</div></body></html>";
 
 NSString *fullHTML = [NSString stringWithFormat:@"%@%@%@", header, htmlTagString, footer];
 
 NSLog(@"Full HTML = %@", fullHTML);
 
 return fullHTML;
 }
 */

#pragma mark
#pragma mark Picker Button

/*
- (void) createFilterButton {
	
	pickerButton = [UIButton buttonWithType: 0]; 
	
	[pickerButton setBackgroundColor: [UIColor clearColor]];
	[pickerButton setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
	//[pickerButton setBackgroundImage:stretchableIcon forState:normal];
	
	//[theIcon release];
	
	NSString *pickerTitle = ([Props global].filters != nil) ? [self getPickerTitle] : self.sortType;
	
	//[pickerButton setTitle:[NSString stringWithFormat:@"> %@", pickerTitle] forState:0];	
	
	[pickerButton setTitle:@"> All" forState:0];
	
	float buttonWidth = ([Props global].deviceType == kiPad) ? 320 : 220;
	UIFont *buttonFont = [UIFont boldSystemFontOfSize:18];
	CGSize buttonSizeMax	= CGSizeMake(buttonWidth, 40);
	CGSize buttonSize = [[pickerButton titleForState:UIControlStateNormal] sizeWithFont: buttonFont constrainedToSize: buttonSizeMax lineBreakMode: 0];
	
	pickerButton.frame = CGRectMake(25, 0, buttonSize.width, 40);
	[pickerButton addTarget:self action:@selector(showFilterPicker:) forControlEvents:UIControlEventTouchUpInside];
	pickerButton.titleLabel.textAlignment = UITextAlignmentLeft;
	pickerButton.titleLabel.font = buttonFont;
	pickerButton.titleLabel.shadowOffset = CGSizeMake(1, 1);
	pickerButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
	pickerButton.backgroundColor = [UIColor clearColor];
	[pickerButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
	[pickerButton setTitleShadowColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:kFilterButtonPressed]) [self addHint];
	
	[self addSubview:pickerButton];
	//UIBarButtonItem *theBarButton = [[UIBarButtonItem alloc] initWithCustomView:pickerButton];
	//self.barButton = theBarButton;
	//[theBarButton release];
}


- (void) update {
	
	NSLog(@"FILTERPicker.update");
	
	NSString *pickerTitle = ([Props global].filters != nil) ? [self getPickerTitle] : self.sortType;
	
	[pickerButton setTitle:[NSString stringWithFormat:@"> %@", pickerTitle] forState:0];
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:kFilterButtonPressed])
		for (UIView *view in [pickerButton subviews])
			if (view.tag == kHintLabelTag) [view removeFromSuperview];
	
	float buttonWidth = ([Props global].deviceType == kiPad) ? 320 : 180;
	UIFont *buttonFont = [UIFont boldSystemFontOfSize:18];
	CGSize buttonSizeMax	= CGSizeMake(buttonWidth, 40);
	CGSize buttonSize = [[pickerButton titleForState:UIControlStateNormal] sizeWithFont: buttonFont constrainedToSize: buttonSizeMax lineBreakMode: 0];
	
	pickerButton.frame = CGRectMake(25, 0, buttonSize.width, [stretchableIcon size].height40);
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:kFilterButtonPressed]) [self addHint];
	
	//UIBarButtonItem *theBarButton = [[UIBarButtonItem alloc] initWithCustomView:pickerButton];
	//self.barButton = theBarButton;
	//[theBarButton release];
}


- (void) addHint {
	
	NSString *pickerTitle = [pickerButton titleForState:UIControlStateNormal];
	[pickerButton setTitle:[NSString stringWithFormat:@"%@                                ", pickerTitle] forState:0];
	UILabel *hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, pickerButton.frame.origin.y, 185, pickerButton.frame.size.height)];
	hintLabel.textAlignment = UITextAlignmentLeft;
	hintLabel.backgroundColor = [UIColor clearColor];
	hintLabel.font = [UIFont fontWithName:kFontName size:13];
	hintLabel.textColor = [UIColor grayColor];
	hintLabel.text = @"<-- Tap to filter or sort list";
	hintLabel.tag = kHintLabelTag;
	
	[pickerButton addSubview:hintLabel];
	
	pickerButton.frame = CGRectMake(pickerButton.frame.origin.x, pickerButton.frame.origin.y,CGRectGetMaxX(hintLabel.frame) - CGRectGetMinX(pickerButton.frame), pickerButton.frame.size.height);
}
*/

#pragma mark
#pragma mark Singleton Implementation
//static FilterPicker *sharedFilterPickerInstance = nil;
static bool resetContent;

+ (FilterPicker*)sharedFilterPicker {
   

    
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        
        //if ([Props global].osVersion > 6.0) {
            return [[self alloc] init];
        //}
        
        //else return (FilterPicker*)[[FilterPicker_old alloc]init];
        
    });
}

/*+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedFilterPickerInstance == nil) {
            sharedFilterPickerInstance = [super allocWithZone:zone];
            return sharedFilterPickerInstance;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone { return self;}

- (id)retain {return self;}

- (unsigned)retainCount {return UINT_MAX; //denotes an object that cannot be released}

- (oneway void)release {//do nothing}

- (id)autorelease {return self;}
*/

+ (void) resetContent {
	
	resetContent = TRUE;
}


- (void) resetContent {
    
    self.sortType = nil;
    self.theFilterPicker = nil;
    self.delegate = nil;
    
}


@end
