
/*
     File: SectionHeaderView.m
 
 Copyright (C) 2011 Sutro Media. All Rights Reserved.
 */



#import "SectionHeaderView.h"
#import <QuartzCore/QuartzCore.h>

@implementation SectionHeaderView


@synthesize titleLabel, disclosureButton, delegate, section, regionCount, progressInd;


+ (Class)layerClass {
    
    return [CAGradientLayer class];
}


-(id)initWithFrame:(CGRect)frame title:(NSString*)theTitle number:(int) theNumberOfMembers section:(NSInteger)sectionNumber delegate:(id <SectionHeaderViewDelegate>)aDelegate {
    
    self = [super initWithFrame:frame];
    
    //NSLog(@"SHV.initWithFrame: height = %f", frame.size.height);
    
    if (self != nil) {
        
        self.autoresizesSubviews = TRUE;
        // Set up the tap gesture recognizer.
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
        [self addGestureRecognizer:tapGesture];

        delegate = aDelegate;        
        self.userInteractionEnabled = YES;
        title = theTitle;
        section = sectionNumber;
        numberOfMembers = theNumberOfMembers;
        progressInd = nil;
        disclosureButton = nil;
        regionCount = nil;
        titleLabel = nil;
    }
    
    return self;
}

- (void)layoutSubviews {
 
    //NSLog(@"SECTIONHEADERVIEW.layoutSubviews:");
    //Add background view
    UIImage *backgroundImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", title]];
    
    if ([Props global].appID == 1 && backgroundImage != nil) {
            
        if (backgroundImage != nil) {
            UIImageView *background = [[UIImageView alloc] initWithImage:backgroundImage];
            background.frame = CGRectMake(0, 0, backgroundImage.size.width * (self.frame.size.height/backgroundImage.size.height), self.frame.size.height);
            
            [self addSubview:background];
            
            if (background.frame.size.width < self.frame.size.width) {
                NSLog(@"Adding gradient mask");
                static NSMutableArray *colors = nil;
                
                if (colors == nil) {
                    colors = [[NSMutableArray alloc] initWithCapacity:2];
                    UIColor *color = nil;
                    color = [UIColor colorWithWhite:0.7 alpha:0.0];
                    [colors addObject:(id)[color CGColor]];
                    color = [UIColor colorWithWhite:0.7 alpha:1.0];
                    [colors addObject:(id)[color CGColor]];
                }
                
                float fadeWidth = 50;
                
                CAGradientLayer *maskLayer = [[CAGradientLayer alloc] init];
                float xPos = CGRectGetMaxX(background.frame) - fadeWidth;
                maskLayer.frame = CGRectMake(xPos, 0, self.frame.size.width - xPos, self.frame.size.height);
                [maskLayer setColors:colors];
                [maskLayer setStartPoint:CGPointMake(0.0, 0.5)];
                [maskLayer setEndPoint:CGPointMake(1.0, 0.5)];
                float fullOpacityLocation = fadeWidth/maskLayer.frame.size.width;
                [maskLayer setLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:fullOpacityLocation], nil]];
                [self.layer addSublayer: maskLayer];
            }
            
            // Set the colors for the gradient layer.
            static NSMutableArray *colors2 = nil;
            
            if (colors2 == nil) {
                colors2 = [[NSMutableArray alloc] initWithCapacity:4];
                UIColor *color = nil;
                color = [UIColor colorWithWhite:0.8 alpha:0.55];
                [colors2 addObject:(id)[color CGColor]];
                color = [UIColor colorWithWhite:0.7 alpha:0.65];
                [colors2 addObject:(id)[color CGColor]];
                color = [UIColor colorWithWhite:0.5 alpha:0.55];
                [colors2 addObject:(id)[color CGColor]];
                color = [UIColor colorWithWhite:0.1 alpha:1.0];
                [colors2 addObject:(id)[color CGColor]];
            }
            
            CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
            gradientLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
            //NSLog(@"Y pos for gradient layer = %f", self.frame.origin.y);
            [gradientLayer setColors:colors2];
            [gradientLayer setLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.5], [NSNumber numberWithFloat:0.98], [NSNumber numberWithFloat:0.99], nil]];
            //gradientLayer.opacity = 0.5;
            [self.layer addSublayer: gradientLayer];
        }
    }
        
    else   {   
        // Set the colors for the gradient layer.
        static NSMutableArray *colors2 = nil;
        
        if (colors2 == nil) {
            colors2 = [[NSMutableArray alloc] initWithCapacity:3];
            UIColor *color = nil;
            color = [UIColor colorWithWhite:0.9 alpha:1.0];
            [colors2 addObject:(id)[color CGColor]];
            color = [UIColor colorWithWhite:0.8 alpha:1.0];
            [colors2 addObject:(id)[color CGColor]];
            color = [UIColor colorWithWhite:0.7 alpha:1.0];
            [colors2 addObject:(id)[color CGColor]];
        }
        
        CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
        gradientLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        [gradientLayer setColors:colors2];
        [gradientLayer setLocations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1.0], nil]];
        //gradientLayer.opacity = 0.5;
        [self.layer addSublayer: gradientLayer];
    }
    
    // Create and configure the title label.
    
    UIFont *titleLabelFont = [Props global].deviceType == kiPad ? [UIFont boldSystemFontOfSize:26.0] : [UIFont boldSystemFontOfSize:19.0];
    CGSize textBoxSizeMax	= CGSizeMake(self.frame.size.width - 75, self.frame.size.height); // height value does not matter as long as it is larger than height needed for text box
    CGSize textBoxSize = [title sizeWithFont:titleLabelFont constrainedToSize: textBoxSizeMax lineBreakMode: 0];
    CGRect titleLabelFrame = CGRectMake(35, 0, textBoxSize.width, self.frame.size.height);
    //titleLabelFrame.origin.x += 35.0;
    //titleLabelFrame.size.width -= 35.0;
    //CGRectInset(titleLabelFrame, 0.0, 5.0);
    titleLabel = [[UILabel alloc] initWithFrame:titleLabelFrame];
    titleLabel.text = title;
    titleLabel.font = titleLabelFont;
    titleLabel.textColor = [UIColor blackColor];//[Props global].LVEntryTitleTextColor;
    titleLabel.shadowColor = [UIColor lightGrayColor];
    titleLabel.shadowOffset = CGSizeMake(1, 1);
    titleLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:titleLabel];
    
    CGRect regionCountLabelFrame = CGRectMake(CGRectGetMaxX(titleLabelFrame) + 10, 0, 75, self.frame.size.height);
    
    regionCount = [[UILabel alloc] initWithFrame:regionCountLabelFrame];
    regionCount.text = [NSString stringWithFormat:@"(%i)", numberOfMembers];
    regionCount.font = [UIFont systemFontOfSize:titleLabelFont.pointSize];
    regionCount.textColor = [Props global].LVEntryTitleTextColor;
    regionCount.alpha = .85;
    regionCount.shadowColor = [UIColor lightGrayColor];
    regionCount.shadowOffset = CGSizeMake(1, 1);
    regionCount.backgroundColor = [UIColor clearColor];
    [self addSubview:regionCount];
    
    
    // Create and configure the disclosure button.
    BOOL selected = FALSE;
    if (disclosureButton != nil){
        selected = disclosureButton.selected;
    }
        
    disclosureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [disclosureButton setImage:[UIImage imageNamed:@"carat.png"] forState:UIControlStateNormal];
    [disclosureButton setImage:[UIImage imageNamed:@"carat-open.png"] forState:UIControlStateSelected];
    [disclosureButton addTarget:self action:@selector(toggleOpen:) forControlEvents:UIControlEventTouchUpInside];
    disclosureButton.frame = CGRectMake(0.0, (self.frame.size.height - 35)/2, 35.0, 35.0);
    disclosureButton.selected = selected;
    [self addSubview:disclosureButton];
    
    if (progressInd != nil) [self bringSubviewToFront:progressInd];
    /*float width = 22;
    CGRect frame = CGRectMake(self.frame.size.width - width - [Props global].rightMargin, (self.frame.size.height - width)/2, width, width);
    progressInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
    progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [progressInd sizeToFit];
    [progressInd startAnimating];
    [self addSubview:progressInd];
    progressInd.hidden = TRUE;
    
    NSLog(@"Progress indicator %@ hidden for %@", progressInd.hidden ? @"is" : @"is not", title);*/
    
    float width = 22;
    CGRect frame = CGRectMake(self.frame.size.width - width - [Props global].rightMargin, (self.frame.size.height - width)/2, width, width);
    progressInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
    
    progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [progressInd sizeToFit];
    [self addSubview:progressInd];

    
	[super layoutSubviews];
}


-(IBAction)toggleOpen:(id)sender {
    
    [self toggleOpenWithUserAction:YES];
}


-(void)toggleOpenWithUserAction:(BOOL)userAction {
    
    // Toggle the disclosure button state.
    disclosureButton.selected = !disclosureButton.selected;
    
    // If this was a user action, send the delegate the appropriate message.
    if (userAction) {
        NSLog(@"SHV.toggleOpenWithUserAction:disclosure button is %@", disclosureButton.selected ? @"selected" : @"not selected");
        if (disclosureButton.selected) {
            if ([delegate respondsToSelector:@selector(sectionHeaderView:sectionOpened:)]) {
                [delegate sectionHeaderView:self sectionOpened:section];
            }
        }
        else {
            if ([delegate respondsToSelector:@selector(sectionHeaderView:sectionClosed:)]) {
                [delegate sectionHeaderView:self sectionClosed:section];
            }
        }
    }
}

- (void) startWaitAnimation {
    
    NSLog(@"SECTIONHEADERVIEW.startWaitAnimation");
    //Line below and last line of method are needed to wrap separate thread and create memory pool
    @autoreleasepool {
    
        [progressInd startAnimating];
    
    }
}


- (void) stopWaitAnimation {
    
    NSLog(@"SECTIONHEADERVIEW.stopWaitAnimation");
    [progressInd stopAnimating];
    //[progressInd removeFromSuperview];
}


- (void)dealloc {
    
    //NSLog(@"SectionHeaderView.dealloc");
    self.delegate = nil;
}


@end
