//
//  ASICloudFilesContainerXMLParserDelegate.h
//
//  Created by Michael Mayo on 1/10/10.
//

#import "ASICloudFilesRequest.h"

#if !TARGET_OS_IPHONE || (TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_4_0)
#import "ASINSXMLParserCompat.h"
#endif

@class ASICloudFilesContainer;

@interface ASICloudFilesContainerXMLParserDelegate : NSObject <NSXMLParserDelegate> {
		
	NSMutableArray *containerObjects;

	// Internally used while parsing the response
	NSString *__unsafe_unretained currentContent;
	NSString *__unsafe_unretained currentElement;
	ASICloudFilesContainer *__unsafe_unretained currentObject;
}

@property  NSMutableArray *containerObjects;

@property  (unsafe_unretained) NSString *currentElement;
@property  (unsafe_unretained) NSString *currentContent;
@property  (unsafe_unretained) ASICloudFilesContainer *currentObject;

@end
