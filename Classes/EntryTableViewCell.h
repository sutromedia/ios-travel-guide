/*

File: EntryTableViewCell.h
Abstract: Draws the tableview cell and lays out the subviews.

Version: 1.7

*/

#import <UIKit/UIKit.h>

@class Entry;


@interface EntryTableViewCell : UITableViewCell {
	Entry *__unsafe_unretained entry;
	UILabel *__unsafe_unretained labelView;
	UILabel *__unsafe_unretained priceLabelView;
	UIButton *__unsafe_unretained distanceLabelView;
	UILabel *__unsafe_unretained locationLabelView;
    UILabel *__unsafe_unretained taglineLabelView;
    UILabel *__unsafe_unretained descriptionView;
	CGRect iconFrame;
	UIImageView *aboutSutroView;
	UINavigationBar *navigationBar;
    UIImageView *__unsafe_unretained dealsTag;
    UILabel *__unsafe_unretained countLabel;
    UIImageView *__unsafe_unretained iconImage;
    UIView *shadow;
    float imageWidth;
    float borderMargin;
}
 
@property (unsafe_unretained, nonatomic) Entry *entry;
@property (unsafe_unretained, nonatomic) UIImageView *iconImage;
@property (unsafe_unretained, nonatomic) UILabel *labelView;
@property (unsafe_unretained, nonatomic) UILabel *priceLabelView;
@property (unsafe_unretained, nonatomic) UIButton *distanceLabelView;
@property (unsafe_unretained, nonatomic) UILabel *locationLabelView;
@property (unsafe_unretained, nonatomic) UIImageView *dealsTag;
@property (unsafe_unretained, nonatomic) UILabel *countLabel;
@property (unsafe_unretained, nonatomic) UILabel *taglineLabelView;
@property (unsafe_unretained, nonatomic) UILabel *descriptionView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void) setDistanceText;

@end
