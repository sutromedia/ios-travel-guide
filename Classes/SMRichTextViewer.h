//
//  SMRichTextViewer.h
//  TheProject
//
//  Created by Tobin1 on 2/18/10.
//  Copyright 2010 Sutro Media. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SMRichTextViewer : UIWebView <UIWebViewDelegate>{

	float contentSize;

}

@property(nonatomic) float contentSize;

//+ (SMRichTextViewer*)sharedCopy;

//- (void) reset;
- (void) emptyMemoryCache;

@end
