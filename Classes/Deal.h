//
//  Deal.h
//  TheProject
//
//  Created by Tobin Fisher on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet, Entry;

@interface Deal : NSObject {
    
    /*NSString    *title;
    NSString    *description;
    NSString    *imageURL;
    NSString    *url;
    NSDate      *expiration;
    float       price;
    float       value;
    float       discount;*/
}

- (id)initWithRow:(FMResultSet *) rs;
//- (void) createDealImageWithData:(NSData*) _imageData;;
- (void) makeDealImage;
//- (UIImage*) getImageWithURL:(NSURL*) theURL;

@property (nonatomic, strong)   Entry       *entry;
@property (nonatomic, strong)   NSData      *imageData;
@property (nonatomic, strong)   UIImage     *image;
@property (nonatomic, strong)   UIImage     *squareImage;
@property (nonatomic, strong)   NSString    *title;
@property (nonatomic, strong)   NSString    *shortTitle; //Not used
@property (nonatomic, strong)   NSString    *description; 
@property (nonatomic, strong)   NSString    *imageFileLocation;
@property (nonatomic, strong)   NSString    *imageURL;
@property (nonatomic, strong)   NSString    *merchantName;
@property (nonatomic, strong)   NSString    *url;
@property (nonatomic, strong)   NSString     *expiration;
@property (nonatomic, strong)   NSString    *entryName;
@property (nonatomic, strong)   NSString    *distanceString;
@property (nonatomic, strong)   NSString    *discountString;
@property (nonatomic, strong)   NSString    *priceString;
@property (nonatomic)           float       price;
@property (nonatomic)           float       value;
@property (nonatomic)           float       discount;
@property (nonatomic)           float       distance;
@property (nonatomic)           int         rowid;

@end
