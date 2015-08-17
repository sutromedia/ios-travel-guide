//
//  ActivityLogger.h
//  TravelGuideSF
//
//  Created by Tobin1 on 3/28/09.
//  Copyright 2009 Ard ica Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Entry;

@interface ActivityLogger : NSObject {
	
	NSString *activityLogEvents;
	//NSString *activityLog;
	NSDate *startTime;
	NSData *imageData;
	NSTimer *updateTimer;
	BOOL locationLogged;
	int sequence_id;
}

+ (ActivityLogger *) sharedActivityLogger;
//+(NSString *) urlEncode: (NSString *) unencodedString;
//- (NSString *) formatActivityLog;
- (void) startSession;
- (void) endSession;
- (void) setLocation:(CLLocation*) theLocation;
- (void) sendEmailWithContent: (NSString*) message userName:(NSString*) userName emailAddress:(NSString*) emailAddress andEntry:(Entry *) entry;
- (void) sendLogMessage:(NSString*)logMessage;
- (void)uploadImage:(NSData *)imageData;
- (NSString*) urlEncodeString:(NSString*) unencodedString;
- (void) logPurchase: (NSMutableString*) logMessage;
- (void) sendPopularityLog: (NSMutableString*) logMessage;

@property (nonatomic) int sequence_id;


@end
