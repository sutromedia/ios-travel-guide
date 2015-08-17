//
//  ASIS3Bucket.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 16/03/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//
//  Instances of this class represent buckets stored on S3
//  ASIS3ServiceRequests return an array of ASIS3Buckets when you perform a service GET query
//  You'll probably never need to create instances of ASIS3Bucket yourself

#import <Foundation/Foundation.h>


@interface ASIS3Bucket : NSObject {
	
	// The name of this bucket (will be unique throughout S3)
	NSString *__unsafe_unretained name;
	
	// The date this bucket was created
	NSDate *__unsafe_unretained creationDate;
	
	// Information about the owner of this bucket
	NSString *__unsafe_unretained ownerID;
	NSString *__unsafe_unretained ownerName;
}

+ (id)bucketWithOwnerID:(NSString *)ownerID ownerName:(NSString *)ownerName;

@property  (unsafe_unretained) NSString *name;
@property  (unsafe_unretained) NSDate *creationDate;
@property  (unsafe_unretained) NSString *ownerID;
@property  (unsafe_unretained) NSString *ownerName;
@end
