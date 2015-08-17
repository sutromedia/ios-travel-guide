//
//  SlideshowUpgradeView.m
//  TheProject
//
//  Created by Tobin Fisher on 2/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SlideshowUpgradeView.h"

@implementation SlideshowUpgradeView

- (id)initWithNumberOfImagesRemaining: (int) theNumberOfImagesRemaining
{
    CGRect frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
        
        UIColor *textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        UIFont *font = [Props global].deviceType == kiPad ? [UIFont fontWithName:kFontName size:22] : [UIFont fontWithName:kFontName size:16];
        UIFont *titleFont = [Props global].deviceType == kiPad ? [UIFont boldSystemFontOfSize:30]: [UIFont boldSystemFontOfSize:25];
        UIFont *title2Font = [Props global].deviceType == kiPad ? [UIFont boldSystemFontOfSize:23]: [UIFont boldSystemFontOfSize:18];
        
        float horizontalMargin = [Props global].screenHeight/50;
        
        UILabel *label = [[UILabel alloc] init];
        label.font = titleFont;
        label.textAlignment = UITextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = textColor;
        label.frame = CGRectMake([Props global].leftMargin, [Props global].titleBarHeight, [Props global].screenWidth - [Props global].leftMargin * 2, label.font.pointSize * 1.2);
        label.numberOfLines = 0;
        label.text = @"Want to see more?";
        [self addSubview:label];

        
        UILabel *label1 = [[UILabel alloc] init];
        label1.font = font;
        label1.textAlignment = UITextAlignmentCenter;
        label1.backgroundColor = [UIColor clearColor];
        label1.textColor = textColor;
        label1.numberOfLines = 0;
        label1.text = [NSString stringWithFormat:@"This slideshow has %i more image%@ for premium users", theNumberOfImagesRemaining, theNumberOfImagesRemaining > 1 ? @"s" : @""];
        CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, [Props global].screenHeight);
        CGSize textBoxSize = [label1.text sizeWithFont: label1.font constrainedToSize: textBoxSizeMax lineBreakMode: 2];
        label1.frame = CGRectMake([Props global].leftMargin, CGRectGetMaxY(label.frame) + horizontalMargin, [Props global].screenWidth - [Props global].leftMargin * 2, textBoxSize.height);
        [self addSubview:label1];
        
        UIButton *upgradeButton = [UIButton buttonWithType:0];
        UIImage *buttonImage = [UIImage imageNamed:@"upgradeButton.png"];
        [upgradeButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [upgradeButton setTitle:@"Upgrade" forState:UIControlStateNormal];
        [upgradeButton setTitleColor:textColor forState:UIControlStateNormal];
        float fontSize = [Props global].deviceType == kiPad ? 33 : 25;
        upgradeButton.titleLabel.font = [UIFont boldSystemFontOfSize:fontSize];
        float width = [Props global].deviceType == kiPad ? 200 : 150;
        float height = buttonImage.size.height * (width/buttonImage.size.width);
        upgradeButton.frame = CGRectMake(([Props global].screenWidth - width)/2, CGRectGetMaxY(label1.frame) + horizontalMargin * 2, width, height);
        [upgradeButton addTarget:self action:@selector(upgrade) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:upgradeButton];
        
        UILabel *andGet = [[UILabel alloc] init];
        andGet.font = title2Font;
        andGet.textAlignment = UITextAlignmentLeft;
        andGet.backgroundColor = [UIColor clearColor];
        andGet.textColor = textColor;
        float xPos = [Props global].deviceType == kiPad ? ([Props global].screenWidth - 512)/2 : [Props global].screenWidth/25;
        andGet.frame = CGRectMake(xPos, CGRectGetMaxY(upgradeButton.frame) + horizontalMargin * 2, [Props global].screenWidth - [Props global].leftMargin * 2, andGet.font.pointSize * 1.2);
        andGet.numberOfLines = 0;
        andGet.text = @"Premium users get:";
        [self addSubview:andGet];

        UILabel *label2 = [[UILabel alloc] init];
        label2.font = font;
        label2.textAlignment = UITextAlignmentLeft;
        label2.numberOfLines = 0;
        label2.textColor = textColor;
        label2.backgroundColor = [UIColor clearColor];
        label2.text = @"✓ full slideshows\n✓ fast offline access\n✓ full content search\n✓ ability to save favorites\n✓ an ad free experience\n✓ a happy author";
        
        textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, [Props global].screenHeight);
        textBoxSize = [label2.text sizeWithFont: label2.font constrainedToSize: textBoxSizeMax lineBreakMode: 2];
        label2.frame = CGRectMake(xPos, CGRectGetMaxY(andGet.frame) + horizontalMargin, [Props global].screenWidth - [Props global].leftMargin * 2, textBoxSize.height);
        
        [self addSubview:label2];
    }
    
    return self;
}

- (void) upgrade {
    
    NSLog(@"Time to upgrade");
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowUpgrade object:nil userInfo:nil];
}


@end
