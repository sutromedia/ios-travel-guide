/*

File: CustomView.m
Abstract: The custom view holding the image and title for the custom picker.

Version: 1.7

*/

#import "CustomView.h"


#define MAIN_FONT_SIZE 18
#define MIN_MAIN_FONT_SIZE 18

@implementation CustomView

@synthesize title, image;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	if (self)
	{
		self.frame = frame; 
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.backgroundColor = [UIColor greenColor];	// make the background transparent
		self.userInteractionEnabled = NO;
	}
	return self;
	
}


- (void)drawRect:(CGRect)rect
{
	// draw the image and title using their draw methods
	
	float xCoord = 20;
	float yCoord;
	
	if(self.image != nil) {
		yCoord = (self.bounds.size.height - self.image.size.height) / 2;
		xCoord = 5;
		[self.image drawAtPoint:CGPointMake(xCoord, yCoord)];
		xCoord += [image size].width + 10;	
	}	
    
    UIFont *font = [self.title  isEqual: kFavorites] || [self.title isEqualToString:@"Everything"] ? [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE] :[UIFont systemFontOfSize:MAIN_FONT_SIZE];
	
	yCoord = (self.bounds.size.height - MAIN_FONT_SIZE) / 2;
	[self.title drawAtPoint: CGPointMake(xCoord, yCoord)
					forWidth:self.bounds.size.width
					withFont:font
					minFontSize:MIN_MAIN_FONT_SIZE
					actualFontSize:NULL
					lineBreakMode:UILineBreakModeTailTruncation
					baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
	}


- (NSComparisonResult)compareTitles:(CustomView *) theView {
	
	return [self.title caseInsensitiveCompare: theView.title]; // [[NSNumber numberWithInt:[self score]] compare:[NSNumber numberWithInt:[highScore score]]];
}




@end
