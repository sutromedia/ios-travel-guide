//
//  TestData.m
//  MapView
//
//  Created by Tobin1 on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TestData.h"


@implementation TestData

@synthesize data;

- (id) initWithData:(NSMutableData*)srcData {
	self.data = srcData;
	return self;
}

- (id) initWithCapacity:(NSUInteger)capacity {
	
	return [data initWithCapacity:capacity];
}


- (id) initWithLength:(NSUInteger)length {
	return [data initWithLength:length];
}

- (void) increaseLengthBy:(NSUInteger)extraLength {
	return [data increaseLengthBy:extraLength];
}

- (void) setLength:(NSUInteger)length {

	[data setLength:length];
}

- (void*)mutableBytes {
	
	return [data mutableBytes];
}

- (void)appendBytes:(const void *)bytes length:(NSUInteger)length {
	[data appendBytes:bytes length:length];
}

- (void)appendData:(NSData *)otherData {
	[data appendData:otherData];
}

- (void)replaceBytesInRange:(NSRange)range withBytes:(const void *)bytes {
	[data replaceBytesInRange:range
					withBytes:bytes];
}

- (void)replaceBytesInRange:(NSRange)range withBytes:(const void *)replacementBytes length:(NSUInteger) replacementLength {
	[data replaceBytesInRange:range withBytes:replacementBytes length:replacementLength];
}

- (void)resetBytesInRange:(NSRange)range {
	[data resetBytesInRange:range];
}

- (void)setData:(NSData *)aData {
	[data setData:aData];
}

- (void) dealloc {
	[data dealloc];
}

- (void) release {
	[data release];
}

- (id) retain {
	[data retain];
	return self;
}
																							
@end
