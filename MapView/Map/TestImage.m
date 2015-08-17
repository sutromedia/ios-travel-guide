//
//  TestImage.m
//  MapView
//
//  Created by Tobin1 on 11/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TestImage.h"


@implementation TestImage

- (id) initWithData:(NSData *)data {

	NSLog(@"Test image init - %i", self);
	
	return [super initWithData:data];
	
}

- (void) dealloc {

	NSLog(@"Test image dealloc - %i", self);
	
	[super dealloc];
}

@end
