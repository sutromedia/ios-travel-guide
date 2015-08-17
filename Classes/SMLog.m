//
//  SMLog.m
//  TheProject
//
//  Created by Tobin1 on 2/2/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import "SMLog.h"
#import "Props.h"
#import "Constants.h"
#import <CommonCrypto/CommonDigest.h>

@implementation SMLog

@synthesize entry_id, filter_id, photo_id, latitude, longitude, target_app_id, note, favorite_entry_id, favorite_value;

- (id) initWithPageID:(int) thePageID actionID: (int) theActionID {
	
    self = [super init];
    if (self) {
	
		//Mandatory fields
		app_id = [Props global].appID;
		device_id	= [self hashId:[Props global].deviceID];
		session_id = [Props global].sessionID;
		svn_revision = [Props global].svnRevision;
		OS_version = [[UIDevice currentDevice] systemVersion];
		deviceType	= [[UIDevice currentDevice] model];
		bundle_version = [Props global].bundleVersion;
		page_id = thePageID;
		action_id = theActionID;
		
		//Set optional fields to nil or placeholder values
		entry_id	= kValueNotSet;
		filter_id	= kValueNotSet;
		photo_id	= kValueNotSet;
		target_app_id= kValueNotSet;
		latitude	= kValueNotSet;
		longitude	= kValueNotSet;
        favorite_entry_id = kValueNotSet;
        favorite_value = kValueNotSet;
		note		= kStringNotSet;
	}
	
	return self;
}


- (NSMutableString*) createLogString {
	
	NSMutableString *logString = [[NSMutableString alloc] initWithCapacity:120];
	
	//Mandatory fields
	[logString appendString:[NSString stringWithFormat:@"_appid=%i", app_id]];
	[logString appendString:[NSString stringWithFormat:@"_sessionid=%0.0f", session_id]];
	[logString appendString:[NSString stringWithFormat:@"_sutroid=%@", device_id]];
	[logString appendString:[NSString stringWithFormat:@"_time=%0.0f",[[NSDate date] timeIntervalSince1970]]];
	[logString appendString:[NSString stringWithFormat:@"_pageid=%i", page_id]];
	[logString appendString:[NSString stringWithFormat:@"_actionid=%i", action_id]];
	[logString appendString:[NSString stringWithFormat:@"_svnrevision=%i", svn_revision]];
	[logString appendString:[NSString stringWithFormat:@"_devicetype=%@", deviceType]];
	[logString appendString:[NSString stringWithFormat:@"_osversion=%@", OS_version]];
	[logString appendString:[NSString stringWithFormat:@"_bundleversion=%i", bundle_version]];
	[logString appendString:[NSString stringWithFormat:@"_l=%i", UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ? 1 : 0]];
	
	//Optional fields
	if(entry_id		!= kValueNotSet)[logString appendString:[NSString stringWithFormat:@"_entryid=%i", entry_id]];
	if(filter_id	!= kValueNotSet)[logString appendString:[NSString stringWithFormat:@"_filterid=%i", filter_id]];
	if(photo_id		!= kValueNotSet)[logString appendString:[NSString stringWithFormat:@"_photoid=%i", photo_id]];
	if(target_app_id != kValueNotSet)[logString appendString:[NSString stringWithFormat:@"_targetappid=%i", target_app_id]];
	//if(latitude		!= kValueNotSet)[logString appendString:[NSString stringWithFormat:@"_latitude=%f", latitude]];
	//if(longitude	!= kValueNotSet)[logString appendString:[NSString stringWithFormat:@"_longitude=%f", longitude]];
	if([Props global].inTestAppMode) [logString appendString:@"_testapp=1"];
    if ([Props global].isTestAppDevice) [logString appendString:@"_testdevice=1"];
	if([Props global].appID <= 1) [logString appendString:[NSString stringWithFormat:@"_originalappid=%i",[[Props global] getOriginalAppId]]];
	if (![note  isEqual: kStringNotSet]) [logString appendString:[NSString stringWithFormat:@"_note=%@", note]];
	
	return logString;
}


- (NSString*) hashId:(NSString *) idToHash {
    
    //NSLog(@"Pre hashed id = %@", idToHash);
    
    // Create pointer to the string as UTF8
    const char *ptr = [idToHash UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) 
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    //NSLog(@"Hashed ID = %@", output);
    
    return output;
}


- (id) initPopularityLog {
	
    self = [super init];
    if (self) {
        
		//Mandatory fields
		app_id = [Props global].appID;
		
		//Set optional fields to nil or placeholder values
		entry_id	= kValueNotSet;
		filter_id	= kValueNotSet;
		photo_id	= kValueNotSet;
	}
	
	return self;
}


- (NSMutableString*) createPopularityLog {
	
	NSMutableString *logString = [[NSMutableString alloc] initWithCapacity:100];
	
	//Mandatory fields
	[logString appendString:[NSString stringWithFormat:@"_appid=%i", app_id]];
	
	//Optional fields
	if(entry_id	!= kValueNotSet)[logString appendString:[NSString stringWithFormat:@"_entryid=%i", entry_id]];
	if(filter_id != kValueNotSet)[logString appendString:[NSString stringWithFormat:@"_filterid=%i", filter_id]];
	if(photo_id	!= kValueNotSet)[logString appendString:[NSString stringWithFormat:@"_photoid=%i", photo_id]];
	
	if(favorite_entry_id != kValueNotSet)[logString appendString:[NSString stringWithFormat:@"_favoriteentryid=%i", favorite_entry_id]];
    
    if(favorite_value != kValueNotSet)[logString appendString:[NSString stringWithFormat:@"_favoritevalue=%i", favorite_value]];
    
	return logString;
}




@end
