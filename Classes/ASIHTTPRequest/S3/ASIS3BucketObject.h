//
//  ASIS3BucketObject.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 13/07/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//
//  Instances of this class represent objects stored in a bucket on S3
//  ASIS3BucketRequests return an array of ASIS3BucketObjects when you perform a list query

#import <Foundation/Foundation.h>
@class ASIS3ObjectRequest;

@interface ASIS3BucketObject : NSObject <NSCopying> {
	
	// The bucket this object belongs to
	NSString *__unsafe_unretained bucket;
	
	// The key (path) of this object in the bucket
	NSString *__unsafe_unretained key;
	
	// When this object was last modified
	NSDate *__unsafe_unretained lastModified;
	
	// The ETag for this object's content
	NSString *__unsafe_unretained ETag;
	
	// The size in bytes of this object
	unsigned long long size;
	
	// Info about the owner
	NSString *__unsafe_unretained ownerID;
	NSString *__unsafe_unretained ownerName;
}

+ (id)objectWithBucket:(NSString *)bucket;

// Returns a request that will fetch this object when run
- (ASIS3ObjectRequest *)GETRequest;

// Returns a request that will replace this object with the contents of the file at filePath when run
- (ASIS3ObjectRequest *)PUTRequestWithFile:(NSString *)filePath;

// Returns a request that will delete this object when run
- (ASIS3ObjectRequest *)DELETERequest;

@property  (unsafe_unretained) NSString *bucket;
@property  (unsafe_unretained) NSString *key;
@property  (unsafe_unretained) NSDate *lastModified;
@property  (unsafe_unretained) NSString *ETag;
@property (assign) unsigned long long size;
@property  (unsafe_unretained) NSString *ownerID;
@property  (unsafe_unretained) NSString *ownerName;
@end
