//
//  TestData.h
//  MapView
//
//  Created by Tobin1 on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TestData : NSMutableData {
	NSMutableData *data;
}

@property (nonatomic, retain) NSMutableData *data;

- (id) initWithData:(NSMutableData*)srcData;
- (int)mutableBytes;

@end
