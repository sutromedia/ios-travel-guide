

#import <Foundation/Foundation.h>
#import "Entry.h"


@interface HeaderViewCell : UITableViewCell {
 
    Entry *__unsafe_unretained entry;
    UIImageView *imageHolder;
    
    UIView *backgroundView; //holder of layer for the background behind the text
    CALayer *background; //layer for content of background view
    
}

@property (nonatomic) UILabel *titleLabel;
@property (unsafe_unretained, nonatomic) UILabel *taglineLabel;
@property (unsafe_unretained, nonatomic) Entry *entry;



@end