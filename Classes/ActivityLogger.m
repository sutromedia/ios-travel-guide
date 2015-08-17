//
//  ActivityLogger.m
//  TravelGuideSF
//
//  Created by Tobin1 on 3/28/09.
//  Copyright 2009 Ard ica Technologies. All rights reserved.
//

#import "ActivityLogger.h"
#import "LocationManager.h"
#import "Props.h"
#import "Entry.h"
#import "Constants.h"
#import "SMLog.h"
#import "Reachability.h"
//#import "Apsalar.h"

@interface ActivityLogger (PrivateMethods)

- (NSString*) urlEncodeString:(NSString*) unencodedString;
- (void) uploadTheImage;
- (void) sendSessionLog;

@end

@implementation ActivityLogger

@synthesize sequence_id;

/*
static ActivityLogger *sharedActivityLoggerInstance = nil;
+ (ActivityLogger*)sharedActivityLogger {
    @synchronized(self) {
        if (sharedActivityLoggerInstance == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedActivityLoggerInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedActivityLoggerInstance == nil) {
            sharedActivityLoggerInstance = [super allocWithZone:zone];
            return sharedActivityLoggerInstance;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}
*/

+ (ActivityLogger*)sharedActivityLogger {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}



// setup the data collection
- init {
	self = [super init];
    
    if (self) {
		
		startTime = nil;
		locationLogged = FALSE;
		sequence_id = 0;
    }
    
	return self;
}


- (void) startSession {
    
    locationLogged = FALSE;
    sequence_id = 0;
    
    if (startTime != nil) { startTime = nil; }
    
    startTime = [[NSDate alloc] init];
    
    //[Apsalar reStartSession:@"tobinfisher" withKey:@"sEY0yo8F"]; 
}


- (void) endSession {
    
    //[Apsalar endSession];
    if([Props global].deviceType != kSimulator) [self sendSessionLog];
}
	 

- (void) setLocation: (CLLocation*) theLocation {
	
	/*
    if([[[UIDevice currentDevice] model] isEqualToString: @"iPhone Simulator"] != TRUE || ! [Props global].hasLocations) {
		
		SMLog *log = [[SMLog alloc] initWithPageID:kStartup actionID:kStarting];
		log.latitude = theLocation.coordinate.latitude;
		log.longitude = theLocation.coordinate.longitude;
		[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
		[log release];
	}*/
}


- (void) logPurchase: (NSMutableString*) logMessage {
	
    @autoreleasepool {
    [logMessage insertString:[NSString stringWithFormat:@"sequenceid=%i", sequence_id] atIndex:0];
    [logMessage insertString: @"a1=" atIndex:0];
    [logMessage insertString:@"https://sutroproject.com/proxy/audit/add.php?" atIndex:0];
    
    NSString *encodedLog = [logMessage stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *webServiceURL = [NSURL URLWithString:encodedLog];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:webServiceURL];
    (void) [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES]; 
    
    sequence_id ++;
	
	}
}


- (void) sendLogMessage: (NSMutableString*) logMessage {
	
	
    @autoreleasepool {
	/*[logMessage retain];
	[logMessage insertString:[NSString stringWithFormat:@"sequenceid=%i", sequence_id] atIndex:0];
	[logMessage insertString: @"a1=" atIndex:0];
	[logMessage insertString:@"http://stats.sutromedia.com/log/add.php?" atIndex:0];
	
	NSString *encodedLog = [logMessage stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	//NSLog(@"Log = %@", encodedLog);
	
	NSURL *webServiceURL = [NSURL URLWithString:encodedLog];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:webServiceURL];
	NSURLConnection * urlConn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES]; 
	
	[urlConn release];
	
	[logMessage release];*/
	
		sequence_id ++;
	
	}
}


- (void) sendPopularityLog: (NSMutableString*) logMessage {	
	
    @autoreleasepool {
    
        if (![Props global].inTestAppMode && [Props global].deviceType != kSimulator) {
            
            [logMessage insertString: @"a1=" atIndex:0];
            [logMessage insertString:@"http://use.sutromedia.com/popularity/add.php?" atIndex:0];
            
            NSString *encodedLog = [logMessage stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSLog(@"Log = %@", encodedLog);
            
            NSURL *webServiceURL = [NSURL URLWithString:encodedLog];
            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:webServiceURL];
            (void)  [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES]; 
            
            
            
            sequence_id ++;
        }
    
	}
}


- (void) sendSessionLog {
		
    @autoreleasepool {
    
        SMLog *log = [[SMLog alloc] initWithPageID:kShutdown actionID:kTerminating];
        
        NSMutableString *logMessage = [log createLogString];
        
        
        [logMessage insertString:[NSString stringWithFormat:@"sequenceid=%i", sequence_id] atIndex:0];
        [logMessage insertString: @"a1=" atIndex:0];
        [logMessage insertString:@"https://use.sutromedia.com/session/add.php?" atIndex:0];
        
        [logMessage appendFormat:@"_sessionlengthseconds=%0.0f", -[startTime timeIntervalSinceNow]];
        
        NSLog(@"Log message = %@", logMessage);
        NSString *encodedLog = [logMessage stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"Log = %@", encodedLog);
        
        NSURL *webServiceURL = [NSURL URLWithString:encodedLog];
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:webServiceURL];
        (void)  [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES]; 
	}
}


-(NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {return nil;}


- (void) sendEmailWithContent: (NSString*) message userName:(NSString*) userName emailAddress:(NSString*) emailAddress andEntry:(Entry *) entry {
	if(message != nil) {
		int appID = [[Props global] appID];
		NSString *encodedMessage = [self urlEncodeString:message];
		NSString *encodedEntryName = (entry == nil) ? [NSString stringWithFormat:@""] : [entry.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *encodedUserName = (userName == nil) ? [NSString stringWithFormat:@""] : [userName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *encodedEmailAddres = (emailAddress == nil) ? [NSString stringWithFormat:@""] : [emailAddress stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *encodedDeviceModel = [[[UIDevice currentDevice] model] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *encodedSystemVersion = [[[UIDevice currentDevice] systemVersion] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		int entryId = (entry == nil) ? 0 : entry.entryid;
		NSString *queryString;
		
		if([Props global].hasLocations) {
		   
		   queryString = [NSString stringWithFormat:@"?email_address=%@&username=%@&feedback=%@&appid=%i&entryid=%i&deviceid=%@&entryname=%@&latitude=%0.8f&longitude=%0.8f&osversion=%@&devicetype=%@",encodedEmailAddres, encodedUserName, encodedMessage, appID, entryId, [Props global].deviceID, encodedEntryName, [[LocationManager sharedLocationManager] getLatitude], [[LocationManager sharedLocationManager] getLongitude],encodedSystemVersion,encodedDeviceModel];
		}
		
		else queryString = [NSString stringWithFormat:@"?email_address=%@&username=%@&feedback=%@&appid=%i&entryid=%i&deviceid=%@&entryname=%@&osversion=%@&devicetype=%@",encodedEmailAddres,encodedUserName,encodedMessage, appID, entryId, [Props global].deviceID, encodedEntryName, encodedSystemVersion, encodedDeviceModel];
		
		NSString * urlString = [NSString stringWithFormat:@"http://sutroproject.com/contact%@", queryString];
		NSURL *webServiceURL = [NSURL URLWithString:urlString];
		NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:webServiceURL];
		(void) [[NSURLConnection alloc] initWithRequest:req delegate:nil startImmediately:YES];   
	}
}


- (NSString*) urlEncodeString:(NSString*) unencodedString {

	NSRange wholeString = NSMakeRange(0, [unencodedString length]);
	NSMutableString *escaped = [NSMutableString stringWithCapacity:[unencodedString length]];
	[escaped appendString:[unencodedString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];       
	[escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@" " withString:@"%20" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:wholeString];

	return (NSString*) escaped;
}


- (void)uploadImage:(NSData *)theImageData {
	
	imageData = theImageData;
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Upload screen shot? \n(This will take a few seconds)"  delegate: self cancelButtonTitle:@"cancel" otherButtonTitles:@"Okay", nil];
	
	[alert show];  
}


-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
	
	if (theAlert.numberOfButtons > 1) {
		
		if (buttonIndex != 0) {[self uploadTheImage];}
		
		else ;
	}
}

	
- (void) uploadTheImage {
	
    NSString *urlString = [NSString stringWithFormat:@"http://www.sutroproject.com/admin%@/?appid=%i&upload_target=screenshot", [Props global].adminSuffix, [Props global].appID];
	
	NSLog(@"Upload URL = %@", urlString);
	
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
	
    NSString *boundary = @"---------------------------14737809831466499882746641449";
	
	NSURL *url = [ NSURL URLWithString: [NSString stringWithFormat:@"http://sutroproject.com/admin%@/", [Props global].adminSuffix]];
	NSArray * availableCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
	
	NSLog(@"ACTIVITYLOGGER.uploadImage: there are %i cookies", [availableCookies count]);
	
    NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:availableCookies];
    // we are just recycling the original request
    [request setAllHTTPHeaderFields:headers];
	
	
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
	
    NSMutableData *body = [NSMutableData data];
	
	NSString *filename = [NSString stringWithFormat:@"screenshot_app_%i_id_%0.0f_%@.jpg",[Props global].appID, [[NSDate date] timeIntervalSince1970], [Props global].deviceType == kiPad ? @"ipad" : @"iphone"];
	
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n",filename]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:imageData]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:body];
	
	
	NSLog(@"Request head fields \n = %@", [request allHTTPHeaderFields]);
	
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
	
	NSLog(@"Return string is %@", returnString);
	
	NSString *message;
	
	if ([returnString isEqualToString:@"okay"]) {
		NSLog(@"Screenshot upload successful!");
		message = @"Screenshot successfully uploaded\nLook in the marketing section to see your screenshot.";
	}
	
	else if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) message = @"Looks like you don't have internet - you'll need an internet connection to upload screenshots";
	
	else message = @"Done.\nLook in the marketing section to see your screenshot.";
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate: self cancelButtonTitle:@"Okay" otherButtonTitles:nil];   
	
	[alert show];  
	
}


@end
