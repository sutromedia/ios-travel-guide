

#import <Foundation/Foundation.h>

@protocol SectionHeaderViewDelegate;


@interface SectionHeaderView : UIView {
 
    NSString *title;
    int numberOfMembers;
    UIActivityIndicatorView *progressInd;
}

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *regionCount;
@property (nonatomic, strong) UIButton *disclosureButton;
@property (nonatomic, assign) NSInteger section;
@property (nonatomic, unsafe_unretained) id <SectionHeaderViewDelegate> delegate;
@property (nonatomic, strong) UIActivityIndicatorView *progressInd;

-(id)initWithFrame:(CGRect)frame title:(NSString*)title number:(int) theNumberOfMembers section:(NSInteger)sectionNumber delegate:(id <SectionHeaderViewDelegate>)aDelegate;
-(void)toggleOpenWithUserAction:(BOOL)userAction;
- (void) startWaitAnimation;
- (void) stopWaitAnimation;

@end



/*
 Protocol to be adopted by the section header's delegate; the section header tells its delegate when the section should be opened and closed.
 */
@protocol SectionHeaderViewDelegate <NSObject>

@optional
- (void) sectionHeaderView:(SectionHeaderView*)sectionHeaderView sectionOpened:(NSInteger)section;
- (void) sectionHeaderView:(SectionHeaderView*)sectionHeaderView sectionClosed:(NSInteger)section;

@end

