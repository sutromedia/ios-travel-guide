/*
 
 Abstract: Manages login for test app
 
 Version: 1.7
 
 */


#import <UIKit/UIKit.h>


@class EntriesAppDelegate;
@class AppPicker;
@class UITextField;


@interface TestAppView : UIViewController <UITextFieldDelegate> {
	
	UIFont *font;
	UIFont *subTitleFont;
	EntriesAppDelegate *appDelegate;
	UITextField *textFieldRounded;
	UITextField *passwordTextField;
	AppPicker *appPicker;
	NSDictionary		*urlDictionary;
	UIButton			*pickerButton;
	UIBarButtonItem		*pickerSelectButton;
	UIBarButtonItem		*goThereBarButton;
	UIBarButtonItem		*pickerDoneButton;
	float				yPosition;
	UIButton			*loginButton;
	UILabel				*errorLabel;
	UIActivityIndicatorView *progressInd;
	UILabel				*loadingTag;
	NSString			*loadingTagMessage;
	BOOL				hidePickerButton;
	BOOL				hideLogin;
	BOOL				hidePicker;
	float				buttonYPosition;
    
    
    NSTimer *connectivityChecker;
    NSDictionary *lastStatus;
    UILabel *titleLabel;
    UILabel *downloadProgressLabel;
    UILabel *statusLabel;
    UILabel *sizeLabel;
    UIProgressView *downloadProgress;
    NSString *currentTask;
    BOOL connectedToInternet;
}


- (id)initWithAppDelegate: (EntriesAppDelegate*) appDelegate;
- (float) createUserNameTextFieldAtYPosition: (float) theYPosition;
- (float) createPasswordTextFieldAtYPosition: (float) theYPosition;
- (void) createAppPickerAtYPosition: (float) theYPosition withAppList: (NSArray*) theAppList;
- (void) createLoadingAnimation;
- (void) removeLoadingAnimation;
- (void) showErrorMessageWithText:(NSString*) errorText;
- (void) resetTextFields;
+ (UIButton *) newButtonWithTitle:	(NSString *)title target:(id)target selector:(SEL)selector yPosition:(int)theYPosition;


@end