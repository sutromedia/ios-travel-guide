//
//  ASICloudFilesContainerRequest.h
//
//  Created by Michael Mayo on 1/6/10.
//

#import "ASICloudFilesRequest.h"

@class ASICloudFilesContainer, ASICloudFilesContainerXMLParserDelegate;

@interface ASICloudFilesContainerRequest : ASICloudFilesRequest {
	
	// Internally used while parsing the response
	NSString *__unsafe_unretained currentContent;
	NSString *__unsafe_unretained currentElement;
	ASICloudFilesContainer *__unsafe_unretained currentObject;
	ASICloudFilesContainerXMLParserDelegate *xmlParserDelegate;
}

@property  (unsafe_unretained) NSString *currentElement;
@property  (unsafe_unretained) NSString *currentContent;
@property  (unsafe_unretained) ASICloudFilesContainer *currentObject;
@property  ASICloudFilesContainerXMLParserDelegate *xmlParserDelegate;

// HEAD /<api version>/<account>
// HEAD operations against an account are performed to retrieve the number of Containers and the total bytes stored in Cloud Files for the account. This information is returned in two custom headers, X-Account-Container-Count and X-Account-Bytes-Used.
+ (id)accountInfoRequest;
- (NSUInteger)containerCount;
- (NSUInteger)bytesUsed;

// GET /<api version>/<account>/<container>
// Create a request to list all containers
+ (id)listRequest;
+ (id)listRequestWithLimit:(NSUInteger)limit marker:(NSString *)marker;
- (NSArray *)containers;

// PUT /<api version>/<account>/<container>
+ (id)createContainerRequest:(NSString *)containerName;

// DELETE /<api version>/<account>/<container>
+ (id)deleteContainerRequest:(NSString *)containerName;

@end
