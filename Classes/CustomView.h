/*

File: CustomView.h
Abstract: The custom view holding the image and title for the custom picker.

Version: 1.7
 
Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/

#import <UIKit/UIKit.h>


@interface CustomView : UIView
{
	NSString* title;
	UIImage* image;
}

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIImage *image;

@end
