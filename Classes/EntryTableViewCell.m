/*

File: EntryTableViewCell.m
Abstract: Draws the tableview cell and lays out the subviews.

Copyright (C) 2009 Sutro Media Inc. All Rights Reserved.

*/

#import "EntryTableViewCell.h"
#import "Entry.h"
#import "Props.h"
#import <QuartzCore/QuartzCore.h>

#define kImageWidth [Props global].deviceType == kiPad ? 52.0 : 45.0
#define kBorderMargin [Props global].deviceType == kiPad ? 6.0 : 5.0

@implementation EntryTableViewCell

@synthesize entry;
@synthesize labelView, priceLabelView, distanceLabelView, locationLabelView, dealsTag, countLabel, iconImage, taglineLabelView, descriptionView;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
		entry = nil;
		labelView = nil;
		aboutSutroView = nil;
        
        self.contentView.opaque = NO;
        self.contentView.autoresizesSubviews = NO;
        
        if ([[Props global].browseViewVariation  isEqual: kTaglineOnlyWithCost]) {
            borderMargin = [Props global].deviceType == kiPad ? 7.0 : 5.0;
            imageWidth = [Props global].tableviewRowHeight - borderMargin * 2;
            iconFrame = CGRectMake(borderMargin, borderMargin, imageWidth, imageWidth);
            UIImageView *_iconImage = [[UIImageView alloc] initWithFrame:iconFrame];
            
            shadow = [[UIView alloc] initWithFrame:iconFrame];
            //shadow.backgroundColor = [UIColor whiteColor];
            CALayer *background = [[CALayer alloc] init];
            background.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0].CGColor;
            background.frame = CGRectMake(0, 0, imageWidth, imageWidth);
            background.shadowColor = [UIColor blackColor].CGColor;
            background.shadowOffset = CGSizeMake(0, 1.5);
            background.shadowRadius = 1.5;
            background.shadowOpacity = 0.8;
            [shadow.layer addSublayer:background];
            [self.contentView addSubview:shadow];
            
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            UIButton *distanceLabel = [UIButton buttonWithType:0];
            UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            UIImageView *_dealsCount = [[UIImageView alloc] initWithFrame:CGRectZero];
            UILabel *_countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            
            UILabel *_taglineLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            UILabel *_descriptionView = [[UILabel alloc] init];
            
            label.backgroundColor = [UIColor clearColor];
            label.minimumFontSize = 13;
            label.adjustsFontSizeToFitWidth = TRUE;
            label.font = [Props global].deviceType == kiPad ? [UIFont boldSystemFontOfSize:20] : [UIFont boldSystemFontOfSize:17];
            label.textColor = [Props global].LVEntryTitleTextColor;
            
            float fontSize = [Props global].deviceType == kiPad ? 14 : 12;
            UIColor *textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            
            _taglineLabel.backgroundColor = [UIColor clearColor];
            _taglineLabel.font = [UIFont fontWithName:kFontName size:fontSize];
            _taglineLabel.textAlignment = UITextAlignmentLeft;
            _taglineLabel.textColor = textColor;
            
            _descriptionView.backgroundColor = [UIColor clearColor];
            _descriptionView.font =  [UIFont fontWithName:kFontName size:fontSize];
            _descriptionView.textColor = textColor;
            _descriptionView.numberOfLines = 0;
            
            distanceLabel.backgroundColor = [UIColor clearColor];
            [distanceLabel setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
            [distanceLabel setTitleColor:[UIColor grayColor] forState:UIControlEventTouchUpInside];
            distanceLabel.titleLabel.font = [UIFont boldSystemFontOfSize:fontSize]; //[UIFont fontWithName:kFontName size:11];
            [distanceLabel addTarget:self action:@selector(showLocation) forControlEvents:UIControlEventTouchUpInside];
            
            priceLabel.backgroundColor = [UIColor clearColor];
            priceLabel.font = [UIFont fontWithName:kFontName size:fontSize];
            priceLabel.textAlignment = UITextAlignmentLeft;
            priceLabel.textColor = textColor;
            
            locationLabel.backgroundColor = [UIColor clearColor];
            locationLabel.font = [UIFont fontWithName:kFontName size:fontSize];
            locationLabel.textAlignment =  ([Props global].hasPrices || [Props global].appID == 0) ? UITextAlignmentCenter : UITextAlignmentLeft;
            locationLabel.textColor = textColor;
            
            _countLabel.textAlignment = UITextAlignmentCenter;
            _countLabel.font = [UIFont boldSystemFontOfSize:fontSize];
            _countLabel.textColor = [UIColor whiteColor];
            _countLabel.backgroundColor = [UIColor clearColor];
            
            self.iconImage = _iconImage;
            self.labelView = label;
            self.priceLabelView = priceLabel;
            self.distanceLabelView = distanceLabel;
            self.locationLabelView = locationLabel;
            self.dealsTag = _dealsCount;
            self.countLabel = _countLabel;
            self.taglineLabelView = _taglineLabel;
            self.descriptionView = _descriptionView;
            
            [self.contentView addSubview:iconImage];
            [self.contentView addSubview:label];
            [self.contentView addSubview: priceLabel];
            [self.contentView addSubview: distanceLabel];
            [self.contentView addSubview:locationLabel];
            [self.contentView addSubview:dealsTag];
            [self.contentView addSubview:countLabel];
            [self.contentView addSubview:taglineLabelView];
            [self.contentView addSubview:descriptionView];
            
            //[distanceLabel release];
        }
        
        //Tagline and description
        else {
            borderMargin = [Props global].deviceType == kiPad ? 7.0 : 5.0;
            imageWidth = [Props global].tableviewRowHeight - borderMargin * 2 - 13;
            iconFrame = CGRectMake(borderMargin, borderMargin, imageWidth, imageWidth);
            UIImageView *_iconImage = [[UIImageView alloc] initWithFrame:iconFrame];
            
            shadow = [[UIView alloc] initWithFrame:iconFrame];
            //shadow.backgroundColor = [UIColor whiteColor];
            CALayer *background = [[CALayer alloc] init];
            background.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0].CGColor;
            background.frame = CGRectMake(0, 0, imageWidth, imageWidth);
            background.shadowColor = [UIColor blackColor].CGColor;
            background.shadowOffset = CGSizeMake(0, 1.5);
            background.shadowRadius = 1.5;
            background.shadowOpacity = 0.8;
            [shadow.layer addSublayer:background];
            [self.contentView addSubview:shadow];
            
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            UIButton *distanceLabel = [UIButton buttonWithType:0];
            UILabel *locationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            UIImageView *_dealsCount = [[UIImageView alloc] initWithFrame:CGRectZero];
            UILabel *_countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            
            UILabel *_taglineLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            UILabel *_descriptionView = [[UILabel alloc] init];
            
            label.backgroundColor = [UIColor clearColor];
            label.minimumFontSize = 13;
            label.adjustsFontSizeToFitWidth = TRUE;
            label.font = [Props global].deviceType == kiPad ? [UIFont boldSystemFontOfSize:20] : [UIFont boldSystemFontOfSize:17];
            label.textColor = [Props global].LVEntryTitleTextColor;
            
            float fontSize = [Props global].deviceType == kiPad ? 14 : 12;
            UIColor *textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
            
            _taglineLabel.backgroundColor = [UIColor clearColor];
            _taglineLabel.font = [UIFont fontWithName:kFontName size:fontSize + 1];
            _taglineLabel.textAlignment = UITextAlignmentLeft;
            _taglineLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];;
            
            _descriptionView.backgroundColor = [UIColor clearColor];
            _descriptionView.font =  [UIFont fontWithName:kFontName size:fontSize];
            _descriptionView.textColor = textColor;
            _descriptionView.numberOfLines = 0;
            
            distanceLabel.backgroundColor = [UIColor clearColor];
            [distanceLabel setTitleColor:[Props global].linkColor forState:UIControlStateNormal];
            [distanceLabel setTitleColor:[UIColor grayColor] forState:UIControlEventTouchUpInside];
            distanceLabel.titleLabel.font = [UIFont boldSystemFontOfSize:fontSize]; //[UIFont fontWithName:kFontName size:11];
            [distanceLabel addTarget:self action:@selector(showLocation) forControlEvents:UIControlEventTouchUpInside];
            
            priceLabel.backgroundColor = [UIColor clearColor];
            priceLabel.font = [UIFont fontWithName:kFontName size:fontSize];
            priceLabel.textAlignment = UITextAlignmentLeft;
            priceLabel.textColor = textColor;
            
            locationLabel.backgroundColor = [UIColor clearColor];
            locationLabel.font = [UIFont fontWithName:kFontName size:fontSize];
            locationLabel.textAlignment =  UITextAlignmentLeft;
            locationLabel.textColor = textColor;
            
            _countLabel.textAlignment = UITextAlignmentCenter;
            _countLabel.font = [UIFont boldSystemFontOfSize:fontSize];
            _countLabel.textColor = [UIColor whiteColor];
            _countLabel.backgroundColor = [UIColor clearColor];
            
            
            if([reuseIdentifier  isEqual: kSortByCost]) {
                
                distanceLabel.hidden = TRUE;
                priceLabel.hidden = FALSE;
            }
            
            else {
                
                distanceLabel.hidden = FALSE;
                priceLabel.hidden = TRUE;
            }
  
            self.iconImage = _iconImage;
            self.labelView = label;
            self.priceLabelView = priceLabel;
            self.distanceLabelView = distanceLabel;
            self.locationLabelView = locationLabel;
            self.dealsTag = _dealsCount;
            self.countLabel = _countLabel;
            self.taglineLabelView = _taglineLabel;
            self.descriptionView = _descriptionView;
            
            [self.contentView addSubview:iconImage];
            [self.contentView addSubview:label];
            [self.contentView addSubview: priceLabel];
            [self.contentView addSubview: distanceLabel];
            [self.contentView addSubview:locationLabel];
            [self.contentView addSubview:dealsTag];
            [self.contentView addSubview:countLabel];
            [self.contentView addSubview:taglineLabelView];
            [self.contentView addSubview:descriptionView];
            
            //[distanceLabel release];
        }
    }
    
    return self;
}


- (void)layoutSubviews {
    
	//NSLog(@"Layout subviews for %@", self.entry.name);
    
    [super layoutSubviews];
    
    if(entry.entryid > 0){
        
        descriptionView.hidden = FALSE;
        iconImage.hidden = FALSE;
        shadow.hidden = FALSE;
        
        if ([[Props global].browseViewVariation  isEqual: kTaglineOnlyWithCost]) {
            
            float yPos = borderMargin - 2; //small hand offset to get text to line up
            iconImage.frame = CGRectMake(borderMargin, borderMargin, imageWidth, imageWidth);
            shadow.frame = iconImage.frame;
            
            labelView.frame = CGRectMake(CGRectGetMaxX(iconImage.frame) + borderMargin + 2, yPos , [Props global].screenWidth - CGRectGetMaxX(iconImage.frame) - [Props global].rightMargin - 25, labelView.font.pointSize + 2);
            yPos = CGRectGetMaxY(labelView.frame) + 1;
            
            
            NSNumber *width = [NSNumber numberWithFloat:imageWidth];
            float widerWidth = [width floatValue] + 10;
            distanceLabelView.bounds = CGRectMake(0, 0, widerWidth, 40);
            
            //distanceLabelView.center = CGPointMake(CGRectGetMidX(iconImage.frame), (CGRectGetMaxY(iconImage.frame) + [Props global].tableviewRowHeight)/2 + 1);
            
            //priceLabelView.frame = distanceLabelView.frame;
            
            if (entry.numberOfDeals > 0) {
                
                UIImage *dealsTagImage = [UIImage imageNamed:@"deals.png"];
                dealsTag.image = dealsTagImage;
                float height = countLabel.font.pointSize + 1;
                float width = dealsTagImage.size.width * (height/dealsTagImage.size.height);
                //CGSize priceSize = [priceLabelView.text sizeWithFont:priceLabelView.font constrainedToSize:priceLabelRect.size lineBreakMode: 0];
                float xPos = CGRectGetMaxX(iconImage.frame) - width - 1; //priceLabelRect.origin.x + priceSize.width + 4;
                float yPos = CGRectGetMaxY(iconImage.frame) - height - 1; //priceSize.height > 0 ? secondRowYPos - (priceSize.height - height)/2 : secondRowYPos - 2;
                
                dealsTag.frame = CGRectMake(xPos, yPos, width, height);
                
                CGRect countFrame = dealsTag.frame;
                countFrame.origin.x = countFrame.origin.x + 4;
                countFrame.origin.y = countFrame.origin.y;
                countFrame.size.width = countFrame.size.width - 4;
                countLabel.frame = countFrame; 
            }
            
            else {
                dealsTag.frame = CGRectZero;
                countLabel.frame = CGRectZero;
            }
            
            BOOL showTagline = [taglineLabelView.text length] > 0 ? TRUE : FALSE;
            BOOL showDetailsRow = [priceLabelView.text length] == 0 && [locationLabelView.text length] == 0 && !distanceLabelView.enabled ? FALSE : TRUE;
            //BOOL showDetailsRow = [locationLabelView.text length] <= 2 && !distanceLabelView.enabled ? FALSE : TRUE;
            
            //NSLog(@"Price length = %i, location length = %i, distance length = %i", [priceLabelView.text length], [locationLabelView.text length], [distanceLabelView.titleLabel.text length]);
            
            if (showTagline) {
                taglineLabelView.frame = CGRectMake(labelView.frame.origin.x, yPos, labelView.frame.size.width, descriptionView.font.pointSize * 1.2);
                //taglineLabelView.center = CGPointMake(taglineLabelView.center.x, self.frame.size.height/2);
            }
            
            else {
                taglineLabelView.frame = CGRectZero;
                descriptionView.frame = CGRectMake(labelView.frame.origin.x, yPos, labelView.frame.size.width, descriptionView.font.pointSize * 1.2);
                //descriptionView.center = CGPointMake(descriptionView.center.x, self.frame.size.height/2);
            }
            
            //Check to see if there is a bottom row to show. If not, show a text preview
            if (showDetailsRow) {
                float height = distanceLabelView.titleLabel.font.pointSize * 1.2;
                yPos = CGRectGetMaxY(iconImage.frame) - height + 2;
                
                float priceWidth = ([Props global].hasPrices) ? ([Props global].hasAbstractPrices ? ([Props global].screenWidth > 320 ? 70 : 55):([Props global].screenWidth > 320 ? 70 : 30)) : 0;
                if ([Props global].appID == 0) priceWidth = ([Props global].screenWidth > 320 ? 140 : 90);
                priceLabelView.frame = CGRectMake(labelView.frame.origin.x, yPos, priceWidth, height);
                
                float locationLabelWidth = ([Props global].hasSpatialCategories) ? ([Props global].hasAbstractPrices ? ([Props global].screenWidth > 320 ? 170 : 119):([Props global].screenWidth > 320 ? 190 : 144)) : 0;
                if ([Props global].appID == 0) locationLabelWidth = ([Props global].screenWidth > 320 ? 130 : 90);
                locationLabelView.frame = CGRectMake(CGRectGetMaxX(priceLabelView.frame), yPos, locationLabelWidth, height);
                
                float distanceLabelWidth = ([Props global].hasLocations) ? ([Props global].screenWidth > 320 ? 70 : 59) : 0; //used to be 59
                if ([Props global].appID == 0) distanceLabelWidth = ([Props global].screenWidth > 320 ? 90 : 50);
                distanceLabelView.frame = CGRectMake(CGRectGetMaxX(locationLabelView.frame), yPos, distanceLabelWidth, height);
                
                /*CGSize maxSize = CGSizeMake(100, height);
                CGSize distanceSize = [distanceLabelView.titleLabel.text sizeWithFont:distanceLabelView.titleLabel.font constrainedToSize:maxSize lineBreakMode: 0];
                
                distanceLabelView.frame = CGRectMake(labelView.frame.origin.x, yPos, distanceSize.width, height);
                locationLabelView.frame = CGRectMake(CGRectGetMaxX(distanceLabelView.frame) + 2, yPos, 140, height);*/
            }
            
            else {
                if (showTagline) {
                    float height = descriptionView.font.pointSize * 1.2;
                    yPos = CGRectGetMaxY(iconImage.frame) - height + 2;
                    descriptionView.frame = CGRectMake(labelView.frame.origin.x, yPos, labelView.frame.size.width, height);
                }
                
                else {
                    taglineLabelView.frame = CGRectZero;
                    descriptionView.frame = CGRectMake(labelView.frame.origin.x, yPos, labelView.frame.size.width, CGRectGetMaxY(iconImage.frame) - yPos);
                } 
                
                priceLabelView.frame = CGRectZero;
                locationLabelView.frame = CGRectZero;
                distanceLabelView.frame = CGRectZero;
            }
            
            if (showTagline && showDetailsRow) descriptionView.frame = CGRectZero;
        }
        
        else if ([[Props global].browseViewVariation  isEqual: kTaglineOnlyWithCost]) {
            
        }
        
        //Tagline and description
        else {
            
            float yPos = borderMargin - 3; //small hand offset to get text to line up
            iconImage.frame = CGRectMake(borderMargin, borderMargin, imageWidth, imageWidth);
            shadow.frame = iconImage.frame;
            
            labelView.frame = CGRectMake(CGRectGetMaxX(iconImage.frame) + borderMargin + 2, yPos , [Props global].screenWidth - CGRectGetMaxX(iconImage.frame) - [Props global].rightMargin - 25, labelView.font.pointSize + 2);
            yPos = CGRectGetMaxY(labelView.frame) + 1;
            
            
            NSNumber *width = [NSNumber numberWithFloat:imageWidth];
            float widerWidth = [width floatValue] + 10;
            distanceLabelView.bounds = CGRectMake(0, 0, widerWidth, 40);
            
            distanceLabelView.center = CGPointMake(CGRectGetMidX(iconImage.frame), (CGRectGetMaxY(iconImage.frame) + [Props global].tableviewRowHeight)/2 + 1);
            
            priceLabelView.frame = distanceLabelView.frame;
            
            if (entry.numberOfDeals > 0) {
                
                UIImage *dealsTagImage = [UIImage imageNamed:@"deals.png"];
                dealsTag.image = dealsTagImage;
                float height = countLabel.font.pointSize + 1;
                float width = dealsTagImage.size.width * (height/dealsTagImage.size.height);
                //CGSize priceSize = [priceLabelView.text sizeWithFont:priceLabelView.font constrainedToSize:priceLabelRect.size lineBreakMode: 0];
                float xPos = CGRectGetMaxX(iconImage.frame) - width - 1; //priceLabelRect.origin.x + priceSize.width + 4;
                float yPos = CGRectGetMaxY(iconImage.frame) - height - 1; //priceSize.height > 0 ? secondRowYPos - (priceSize.height - height)/2 : secondRowYPos - 2;
                
                dealsTag.frame = CGRectMake(xPos, yPos, width, height);
                
                CGRect countFrame = dealsTag.frame;
                countFrame.origin.x = countFrame.origin.x + 4;
                countFrame.origin.y = countFrame.origin.y;
                countFrame.size.width = countFrame.size.width - 4;
                countLabel.frame = countFrame; 
            }
            
            else {
                dealsTag.frame = CGRectZero;
                countLabel.frame = CGRectZero;
            }
            
            if ([taglineLabelView.text length] > 0) {
                taglineLabelView.frame = CGRectMake(labelView.frame.origin.x, yPos, labelView.frame.size.width, descriptionView.font.pointSize * 1.2);
                
                descriptionView.frame = CGRectMake(labelView.frame.origin.x, CGRectGetMaxY(taglineLabelView.frame), labelView.frame.size.width, self.frame.size.height - CGRectGetMaxY(taglineLabelView.frame));
            }
            
            else {
                taglineLabelView.frame = CGRectZero;
                descriptionView.frame = CGRectMake(labelView.frame.origin.x, yPos, labelView.frame.size.width, self.frame.size.height - CGRectGetMaxY(labelView.frame));
                //descriptionView.center = CGPointMake(descriptionView.center.x, self.frame.size.height/2);
            }
        }
    }
	
	//************* Sutro Media Entry *******************
    else {	
        
		priceLabelView.text = nil;
        
        descriptionView.hidden = TRUE;
        iconImage.hidden = TRUE;
        shadow.hidden = TRUE;
        
        dealsTag.frame = CGRectZero;
        countLabel.frame = CGRectZero;
		
		if(entry.entryid == -1){
			
			labelView.text = nil;
			//entryTileView.frame = CGRectZero;
			
			NSString *imageSource = ([Props global].screenWidth > 320) ? @"aboutSutroMedia_iPad":@"aboutSutroMedia";
			
			UIImage *aboutSutroImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:imageSource ofType:@"png"]];
			UIImageView *aboutSutroImageView = [[UIImageView alloc] initWithImage:aboutSutroImage];
			self.backgroundView = aboutSutroImageView;
			self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			self.backgroundView.frame = self.bounds;
		}
	}	
}


- (void)setEntry:(Entry *)anEntry {
	
	if (anEntry != entry) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
		entry = anEntry;
	}
	
    iconImage.image = entry.iconImage;
    
	labelView.text = entry.name;
	
    if ([Props global].appID > 1) {
        int price = [entry getPrice];
        
        if(price == 0)
            priceLabelView.text = [NSString stringWithFormat: @"Free!"];
        
        else if(price < 0)
            priceLabelView.text = [NSString stringWithFormat: @""];
        
        else if (price > 0 && ![Props global].hasAbstractPrices)
            priceLabelView.text = [NSString stringWithFormat: @"%@%i",[Props global].currencyString, [entry getPrice]];
        
        else if (price > 0 && [Props global].hasAbstractPrices) {
            NSString *priceString = @"";
            
            int i;
            
            for (i = 0; i < [entry getPrice]; i++) {
                priceString = [priceString stringByAppendingString:[NSString stringWithFormat:@"%@ ",[Props global].abstractPriceSymbol]];
            }
            
            priceLabelView.text = priceString;
        }
		
        else {
            NSLog(@"FIXME - Something weird going on with price info");
            priceLabelView.text = [NSString stringWithFormat: @""];	
        }	
    }
	
    else priceLabelView.text = [NSString stringWithFormat:@"By %@", entry.pitchAuthor]; 
    
	[self setDistanceText];
    
    countLabel.text = [NSString stringWithFormat:@"%i", entry.numberOfDeals];
    
    if ([[Props global].browseViewVariation  isEqual: kTaglineOnlyWithCost]) {
        
        locationLabelView.text = entry.spatial_group_name;
        taglineLabelView.text = entry.tagline;
        
        if ([taglineLabelView.text length] == 0 || ([locationLabelView.text length] <= 2 && !distanceLabelView.enabled))
            descriptionView.text = entry.noHTMLShortDescription;
    }
    
    /*else if ([Props global].variationNumber == kTaglineOnlyNoCost) {
        
        locationLabelView.text = [NSString stringWithFormat:@"- %@", entry.spatial_group_name];
        countLabel.text = [NSString stringWithFormat:@"%i", entry.numberOfDeals];
        
        taglineLabelView.text = entry.tagline;
        
        if ([taglineLabelView.text length] == 0 || ([locationLabelView.text length] <= 2 && !distanceLabelView.enabled))
            descriptionView.text = entry.noHTMLShortDescription;
    }*/
    
    //Tagline and description
    else {
	
        taglineLabelView.text = entry.tagline;
        descriptionView.text = entry.noHTMLShortDescription;
	}
    
	if(entry.entryid == -1)
		[aboutSutroView setNeedsDisplay];
}


- (void)dealloc {
	
    self.entry = nil;
    //self.taglineLabelView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    
	
}

- (void) setDistanceText {
    
    NSString *distanceText;
	
    if([Props global].hasLocations) {
		double latitude = [entry getLatitude];
		double longitude = [entry getLongitude];
		float distance = [[LocationManager sharedLocationManager] getDistanceFromHereToPlaceWithLatitude:latitude andLongitude:longitude];
        
		if(distance != kNoDistance){
			
			NSString *distanceUnit;
            
			if ([Props global].unitsInMiles) distanceUnit = @"mi";
			else distanceUnit = @"km";
			
            if ([Props global].appID <= 1) {
                
                if (distance < 10) distanceText = [NSString stringWithFormat:@"< 10 %@", distanceUnit];
                
                else distanceText = [NSString stringWithFormat:@"%0.0f %@", round(distance/10) * 10, distanceUnit];
            }
			
            else if (distance < 100) distanceText = [NSString stringWithFormat:@"%0.1f %@", distance, distanceUnit];
			
			else distanceText = [NSString stringWithFormat:@"%0.0f %@", distance, distanceUnit];
		}
		
		else {
            
            distanceText = nil;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDistanceText) name:kLocationUpdated object:nil];
        }
    }
	
	else distanceText = nil;
    
	
    [distanceLabelView setTitle:distanceText forState:UIControlStateNormal];
    
    if (distanceText == nil) distanceLabelView.enabled = FALSE;
    
    else distanceLabelView.enabled = TRUE;
}

- (void) updateDistanceText {
    
    [self setDistanceText];
    
    [self setNeedsLayout];
}


- (void) showLocation {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kShowLocation object:self.entry];
}


@end
