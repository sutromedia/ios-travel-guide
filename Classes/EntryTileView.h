/*

File: AtomicElementTileView.h
Abstract: Draws the small tile view displayed in the tableview rows.

Version: 1.7
*/

#import <UIKit/UIKit.h>

@class Entry;

@interface EntryTileView : UIView {
	Entry *entry;
	CGRect entrySymbolRectangle;
}
 
@property (nonatomic, retain) Entry *entry;

+ (CGSize)preferredViewSize;

@end
