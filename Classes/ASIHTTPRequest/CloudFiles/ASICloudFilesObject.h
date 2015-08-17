//
//  ASICloudFilesObject.h
//
//  Created by Michael Mayo on 1/7/10.
//

#import <Foundation/Foundation.h>


@interface ASICloudFilesObject : NSObject {
	NSString *__unsafe_unretained name;
	NSString *__unsafe_unretained hash;
	NSUInteger bytes;
	NSString *__unsafe_unretained contentType;
	NSDate *__unsafe_unretained lastModified;
	NSData *__unsafe_unretained data;
	NSMutableDictionary *__unsafe_unretained metadata;
}

@property  (unsafe_unretained) NSString *name;
@property  (unsafe_unretained) NSString *hash;
@property (assign) NSUInteger bytes;
@property  (unsafe_unretained) NSString *contentType;
@property  (unsafe_unretained) NSDate *lastModified;
@property  (unsafe_unretained) NSData *data;	
@property  (unsafe_unretained) NSMutableDictionary *metadata;

+ (id)object;

@end
