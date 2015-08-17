//
//  SMLog.h
//  TheProject
//
//  Created by Tobin1 on 2/2/10.
//  Copyright 2010 Sutro Media. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SMLog : NSObject {
	
	int			app_id;
	float		session_id;
	NSString	*device_id;
	int			page_id;
	int			action_id;
	int			entry_id;
	int			filter_id;
	int			photo_id;
	int			target_app_id;
	int			bundle_version;
    int         favorite_entry_id;
    int         favorite_value;
	float		latitude;
	float		longitude;
	int			svn_revision;
	NSString	*OS_version;
	NSString	*deviceType;
	NSString	*note;
}

@property (nonatomic)			int			entry_id;
@property (nonatomic)			int			photo_id;
@property (nonatomic)			int			target_app_id;
@property (nonatomic)			int			filter_id;
@property (nonatomic)			int			favorite_entry_id;
@property (nonatomic)			int			favorite_value;
@property (nonatomic)			float 		latitude;
@property (nonatomic)			float		longitude;
@property (nonatomic, strong)	NSString	*note;


- (id) initWithPageID:(int) thePageID actionID: (int) theActionID;
- (NSMutableString*) createLogString;
- (NSString*) hashId:(NSString *) idToHash;

- (id) initPopularityLog;
- (NSMutableString*) createPopularityLog;

@end
