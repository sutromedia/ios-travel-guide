/*

File: EntriesTableViewController.h
Abstract: Coordinates the tableviews and Entry data sources. It also responds
 to changes of selection in the table view and provides the cells.

*/

#import <UIKit/UIKit.h>
#import "SectionHeaderView.h"
#import <iAD/iAD.h>


@class Entry, FilterPicker, SorterPicker, SearchCell, FilterButton;

 
@interface EntriesTableViewController : UIViewController <UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, SectionHeaderViewDelegate, ADBannerViewDelegate> { 
	
	UITableView                 *theTableView;
	UIBarButtonItem             *doneButton;
    UISegmentedControl          *upgradeButtonView;
	UISearchDisplayController   *searchController;
    UISearchBar                 *searchBar;
	//SearchCell                  *searchCell;
	Entry                       *currentEntry;
	//UIView                      *coverView;
	UIButton                    *sutroButton;
	FilterButton                *pickerSelectButton;
    NSMutableArray              *entryFirstLetterIndex;
	NSString                    *filterCriteria;
	NSString                    *lastFilterChoice;
	NSString                    *lastSortChoice;
	NSString                    *searchText;
	NSString                    *sortCriteria;
    //NSString                    *upgradeButtonTitle;
    UIColor                     *upgradeButtonColor;
    NSNumber                    *upgradeButtonColorRef;
	CGRect                      viewRect;
    NSInteger                   openSectionIndex;
	BOOL                        filterPickerShowing;
    BOOL                        settingsShowing;
	BOOL                        showingDistanceRow;
	BOOL                        firstTime;
	BOOL                        searchKeyboardShowing;
    BOOL                        movingGear;
    BOOL                        shouldMoveGear;
    //BOOL                        goingToEntry;
	NSIndexPath                 *rowToGoBackTo;
    UINavigationController      *homeController;         
}


@property (nonatomic, strong)    UITableView *theTableView;
@property (nonatomic, strong)   Entry *currentEntry;
@property (nonatomic, strong)   NSIndexPath *rowToGoBackTo;
//@property (nonatomic, retain)   SearchCell *searchCell;
@property (nonatomic, strong)   UINavigationController *homeController;
@property (nonatomic, strong)   NSMutableArray *entryFirstLetterIndex;
@property (nonatomic, strong)   NSString *sortCriteria;

@property (nonatomic, strong) ADBannerView *adView;
@property (nonatomic) BOOL adBannerIsVisible;   

- (void) showFilterPicker:(id) sender;
- (void) hideFilterPicker: (id) sender;

@end
