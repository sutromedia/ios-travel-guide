/*
     File: CommentPageView.h
 Abstract: The view controller for hosting the UITextField features of this sample.
  Version: 2.5
 
 */

#import <UIKit/UIKit.h>

@class	Entry;

@interface CommentPageView : UIViewController <UITextFieldDelegate, UITextViewDelegate>

{
	Entry					*entry;
    UITextView				*textFieldRounded;
    UITextField				*usernameField;
    UITextField				*emailField;
}

- (id)initWithEntry:(Entry*) theEntry;

@end
