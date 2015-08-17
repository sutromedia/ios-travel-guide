//
//  SMPitch.h
//  TheProject
//
//  Created by Tobin1 on 2/9/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SMPitch : NSObject {
	
	int appID;
	NSString *author;
	NSString *appName;
	NSString *linkshareURL;
	
}

@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *linkshareURL;
@property (nonatomic)			int		appID;


- (id)initWithEntryID:(int) theEntryId;


@end
