
/*
     File: SectionHeaderView.m
 
 Copyright (C) 2011 Sutro Media. All Rights Reserved.
 */



#import "HeaderViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation HeaderViewCell


@synthesize titleLabel, taglineLabel, entry;


+ (Class)layerClass {
    
    return [CAGradientLayer class];
}


//-(id)initWithFrame:(CGRect)frame andEntry:(Entry*) theEntry {
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    //NSLog(@"SHV.initWithFrame: height = %f", frame.size.height);
    
    if (self != nil) {
        
        self.autoresizesSubviews = TRUE;
        titleLabel = nil;
        taglineLabel = nil;
        entry = nil;
        
        imageHolder = [[UIImageView alloc] init];
        [self addSubview: imageHolder];
        
        UIFont *titleLabelFont = [Props global].deviceType == kiPad ? [UIFont boldSystemFontOfSize:34.0] : [UIFont boldSystemFontOfSize:24.0];
        
        titleLabel = [[UILabel alloc] init];
        titleLabel.font = titleLabelFont;
        titleLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];//[Props global].LVEntryTitleTextColor;
        //titleLabel.shadowColor = [UIColor lightGrayColor];
        //titleLabel.shadowOffset = CGSizeMake(1, 1);
        titleLabel.adjustsFontSizeToFitWidth = TRUE;
        titleLabel.minimumFontSize = 14;
        titleLabel.numberOfLines = 1;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.clipsToBounds = FALSE;
        
        //titleLabel.layer.backgroundColor = [UIColor colorWithWhite:0.96 alpha:0.6].CGColor;
        //titleLabel.layer.frame = CGRectMake(-25, 0, titleLabel.frame.size.width + 50, titleLabel.frame.size.height);
        //titleLabel.layer.cornerRadius = titleLabel.frame.size.height/3;
        

        backgroundView = [[UIView alloc] init];
        
        background = [[CALayer alloc] init];
        background.backgroundColor = [UIColor colorWithWhite:0.96 alpha:0.38].CGColor;
        //background.borderColor = [Props global].linkColor.CGColor;
        //background.borderWidth = 2;
        background.shadowColor = [UIColor blackColor].CGColor;
        background.shadowOffset = CGSizeMake(2, 2);
        background.shadowRadius = 1.5;
        background.shadowOpacity = 0.8;
        [backgroundView.layer addSublayer:background];
        
        [self addSubview:backgroundView];
        
        [self addSubview:titleLabel];

    }
    
    return self;
}

- (void)layoutSubviews {
 
    //NSLog(@"SECTIONHEADERVIEW.layoutSubviews:");
    //Add background view
    int theImageId = entry.icon;
    
    UIImage *theImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i_768", theImageId] ofType:@"jpg"]];
    
    if (theImage == nil) 
        theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_768.jpg",[Props global].contentFolder , theImageId]];
    
    if(theImage == nil) //look for the image in the documents/app name directory if it's not in the resources folder
        theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i.jpg",[Props global].contentFolder , theImageId]];
    
    if (theImage == nil) 
        theImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%i", theImageId] ofType:@"jpg"]];
    
    if (theImage == nil) 
        theImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i_x100.jpg",[Props global].contentFolder , theImageId]];
    
    
    if(theImage == nil) NSLog(@"*********ERROR1:HEADERVIEWCELL.layoutSubviews:image %i not found!!!", theImageId);
    
    if (theImage != nil) {

        UIGraphicsBeginImageContext(CGSizeMake(self.frame.size.width * 2, self.frame.size.height * 2));
        
        float width = self.frame.size.width*2; //multiple by two for extra resolution on retina displays
        float height = theImage.size.height * (width/(theImage.size.width));
        height = (height + self.frame.size.height * 2)/2; //compress the image a bit
        float yPos = (self.frame.size.height * 2 - height)/5; //bias towards the top of the image
        
        //NSLog(@"HEADERVIEWCELL.layoutSubviews: Height = %f, yPos = %f", height, yPos);
        
        [theImage drawInRect:CGRectMake(0, yPos, self.frame.size.width * 2, height)];
        
        UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        imageHolder.image = croppedImage;
        imageHolder.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    }
    
    
    // Create and configure the title label.
    CGSize textBoxSizeMax	= CGSizeMake(self.frame.size.width - 10, self.frame.size.height); // height value does not matter as long as it is larger than height needed for text box
    CGSize textBoxSize = [entry.name sizeWithFont:titleLabel.font constrainedToSize: textBoxSizeMax lineBreakMode: 0];
    float borderMargin = [Props global].deviceType == kiPad ? 9.0 : 7.0;
    CGRect titleLabelFrame = CGRectMake(borderMargin, borderMargin, textBoxSize.width, titleLabel.font.pointSize * 1.2);
    titleLabel.frame = titleLabelFrame;
    
    float cornerRadius = titleLabel.frame.size.height/2;
    backgroundView.frame = CGRectMake(-cornerRadius, -cornerRadius, titleLabel.frame.size.width + cornerRadius + borderMargin * 2, titleLabel.frame.size.height + cornerRadius + borderMargin * 2);
    background.cornerRadius = cornerRadius;
    background.frame = CGRectMake(0, 0, backgroundView.frame.size.width, backgroundView.frame.size.height);
    
    /*
    UIFont *tagLineLabelFont = [UIFont fontWithName:kFontName size:titleLabel.font.pointSize * .7];
    textBoxSizeMax	= CGSizeMake(self.frame.size.width - 10, self.frame.size.height); // height value does not matter as long as it is larger than height needed for text box
    textBoxSize = [@"Life in San Francisco" sizeWithFont:tagLineLabelFont constrainedToSize: textBoxSizeMax lineBreakMode: 0];
    CGRect taglineLabelFrame = CGRectMake(titleLabel.frame.origin.x, CGRectGetMaxY(titleLabel.frame) + 5, textBoxSize.width, textBoxSize.height);
    NSLog(@"Frame = %f, %f, %f, %f", taglineLabelFrame.origin.x, taglineLabelFrame.origin.y, taglineLabelFrame.size.width, taglineLabelFrame.size.height);
    if (taglineLabel != nil) [taglineLabel release];
    taglineLabel = [[UILabel alloc] initWithFrame:taglineLabelFrame];
    taglineLabel.text = @"Life in San Francisco"; // entry.tagline;
    NSLog(@"Text = %@", taglineLabel.text);
    taglineLabel.font = tagLineLabelFont;
    taglineLabel.numberOfLines = 2;
    taglineLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];//[Props global].LVEntryTitleTextColor;
    taglineLabel.shadowColor = [UIColor lightGrayColor];
    taglineLabel.shadowOffset = CGSizeMake(1, 1);
    taglineLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:taglineLabel];
    */
    
	[super layoutSubviews];
}


- (void) setEntry:(Entry*) theEntry {
    
    if (theEntry != entry) {
        
		entry = theEntry;
	}
    
    titleLabel.text = [NSString stringWithFormat:@"%@ ➤",entry.name];
}


- (void)dealloc {
    
    NSLog(@"HeaderView.dealloc");
    
}


@end
