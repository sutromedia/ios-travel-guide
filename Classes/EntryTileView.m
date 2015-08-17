/*

File: EntryTileView.m
Abstract: Draws the small tile view displayed in the tableview rows.

Version: 1.7

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/

#import "EntryTileView.h"
#import "Entry.h"


@implementation EntryTileView
@synthesize entry;

+ (CGSize)preferredViewSize {
	return CGSizeMake([Props global].tableviewRowHeight,[Props global].tableviewRowHeight);
}


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
		entry = nil;
		entrySymbolRectangle = CGRectMake(0,0, [Props global].tableviewRowHeight, [Props global].tableviewRowHeight);
    }
    return self;
}
 
- (void)drawRect:(CGRect)rect {
	UIImage *backgroundImage = entry.iconImage;
    if ([Props global].appID != 0) [backgroundImage drawInRect:entrySymbolRectangle];
    
    else {
        [backgroundImage drawInRect:CGRectMake(1.9, 1, [Props global].tableviewRowHeight - 3.7, [Props global].tableviewRowHeight - 3.7)];
        UIImage *overlayImage = [UIImage imageNamed:@"SW_icon_overlay.png"];
        [overlayImage drawInRect:entrySymbolRectangle];
    }
}


- (void)dealloc {
	[entry release];
	[super dealloc];
}


@end
