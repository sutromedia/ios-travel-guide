#import <Foundation/Foundation.h>
#import "SectionHeaderView.h"

@interface Region : NSObject {

}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *entries;
@property (nonatomic, strong) SectionHeaderView* headerView;
@property (nonatomic)         BOOL  open;

@end
