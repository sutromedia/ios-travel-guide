/*

File: EntriesTableViewController.h
Abstract: Coordinates the tableviews and Entry data sources. It also responds
 to changes of selection in the table view and provides the cells.

*/

#import <UIKit/UIKit.h>

@class Entry;

 
@interface DealsViewController : UIViewController <UIWebViewDelegate> { 
	
    Entry *entry;
    NSURL *dealURL;
    BOOL showAllDeals;
    UIWebView *dealView;
    NSURL *baseURL;

}

@property (nonatomic, strong) Entry *entry;
@property (nonatomic, strong) NSURL *dealURL;

- (id) initWithEntry:(Entry*) theEntry;


@end
