//
//  ASICloudFilesContainer.h
//
//  Created by Michael Mayo on 1/7/10.
//

#import <Foundation/Foundation.h>


@interface ASICloudFilesContainer : NSObject {
	
	// regular container attributes
	NSString *__unsafe_unretained name;
	NSUInteger count;
	NSUInteger bytes;
	
	// CDN container attributes
	BOOL cdnEnabled;
	NSUInteger ttl;
	NSString *__unsafe_unretained cdnURL;
	BOOL logRetention;
	NSString *__unsafe_unretained referrerACL;
	NSString *__unsafe_unretained useragentACL;
}

+ (id)container;

// regular container attributes
@property  (unsafe_unretained) NSString *name;
@property (assign) NSUInteger count;
@property (assign) NSUInteger bytes;

// CDN container attributes
@property (assign) BOOL cdnEnabled;
@property (assign) NSUInteger ttl;
@property  (unsafe_unretained) NSString *cdnURL;
@property (assign) BOOL logRetention;
@property  (unsafe_unretained) NSString *referrerACL;
@property  (unsafe_unretained) NSString *useragentACL;

@end
