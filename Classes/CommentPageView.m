/*
     File: CommentPageView.m
 Abstract: The view controller for hosting the UITextField features of this sample.
  Version: 2.5
 
*/

#import "CommentPageView.h"
#import "Constants.h"
#import "ActivityLogger.h"
#import	"Entry.h"
#import "SMLog.h"
#import "Props.h"
//#import "Apsalar.h"

#define kUsernameFieldHeight			25
#define kEmailFieldHeight				25
#define kNameOrAlias					@"nameOrAlias"
#define kEmailAddress					@"emailAddress"
#define kTextFieldPlaceholderText		@"Your comments, questions, or suggestions here..."
#define kEmailFieldPlaceholderText		@" Email address (optional and not posted)"
#define kUsernameFieldPlaceholderText	@" Name or alias (optional)"

@interface CommentPageView(private)

- (void) addCancelButton;
- (void) addTitleLabel;
- (void) addText;
- (void) createTextField;
- (void) displayAlert;
- (void) hideKeyboard: (id) sender;
- (void) sendEmail: (id) sender;
- (void) setupEmailButtons;
- (void) removeEmailButtons;
- (void) reset;
- (void) layoutSubviews;

@end


@implementation CommentPageView


- (id)initWithEntry:(Entry*) theEntry {
    self = [super init];
    if (self) {
        
		entry = theEntry;
	}
	
    return self;
}


- (void)dealloc{
	
	entry = nil;
	
	textFieldRounded = nil;
	
	usernameField = nil;
	
	emailField = nil;
	
}


- (void)loadView {
	
	NSLog(@"CPV.loadView");
	self.navigationController.navigationBar.translucent = FALSE;
	self.navigationController.navigationBar.tintColor = [Props global].navigationBarTint;
	
	CGRect screenRect = CGRectMake(0, [Props global].titleBarHeight, [Props global].screenWidth, [Props global].screenHeight - [Props global].titleBarHeight); // [[UIScreen mainScreen] applicationFrame];
	
	UIView *contentView = [[UIView alloc] initWithFrame:screenRect];
	self.view = contentView;
	
	self.view.autoresizesSubviews = YES;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	self.view.backgroundColor = [UIColor colorWithWhite:.1 alpha: 1];
		
	[self createTextField];
	[self addCancelButton];
	[self addTitleLabel];
    
    [self layoutSubviews];
}

- (void) layoutSubviews {
	
	//Top text field
    float textFieldHeight;
    
    if ([Props global].deviceType == kiPad) textFieldHeight = [[Props global] inLandscapeMode] ? [Props global].screenHeight - 520 : [Props global].screenHeight - 320;
    
    else textFieldHeight = [[Props global] inLandscapeMode] ? [Props global].screenHeight - 270 : [Props global].screenHeight - 330;
	
    if (textFieldHeight > 500) textFieldHeight = 500;
	
	CGRect textFieldFrame = CGRectMake([Props global].leftMargin, kTopMargin, [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, textFieldHeight);
    textFieldRounded.frame = textFieldFrame;
    
    
    usernameField.frame = CGRectMake([Props global].leftMargin, CGRectGetMaxY(textFieldRounded.frame) + [Props global].tinyTweenMargin, [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, kUsernameFieldHeight);
	
	emailField.frame = CGRectMake([Props global].leftMargin, CGRectGetMaxY(usernameField.frame) + [Props global].tinyTweenMargin, [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, kEmailFieldHeight);
    
    [self addText];
}


- (BOOL)prefersStatusBarHidden { return YES;}


- (void) addText {
    
    int textTag = 87643;
    
    for (UIView *view in [self.view subviews]) {
        if (view.tag == textTag) [view removeFromSuperview];
    }
	
	float theYPosition = CGRectGetMaxY(emailField.frame) + [Props global].tweenMargin + 5;
	
	// draw the text cueing the user what to write
	//Title label
	float labelHeight = 20;
	
    if (![[Props global] inLandscapeMode] && [Props global].deviceType != kiPad) {
        
        CGRect titleLabelRect = CGRectMake(0, theYPosition, [Props global].screenWidth, labelHeight);
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame: titleLabelRect];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor colorWithRed: .94 green: .31 blue: .22 alpha:1];// [UIColor whiteColor];
        titleLabel.font = [UIFont fontWithName: kFontName size:19.5];
        titleLabel.tag = textTag;
        titleLabel.text = [NSString stringWithFormat:@"We'd love to hear YOUR thoughts"];
        titleLabel.textAlignment = UITextAlignmentCenter;
        
        [self.view addSubview: titleLabel];
        
        theYPosition += labelHeight + [Props global].tweenMargin - 4;
    }
	
	//Bullet points below...
	
	NSArray *bulletPointsArray;
	
	if (entry != nil) bulletPointsArray = [NSArray arrayWithObjects: @"- Ask the author a question", @"- Give us your comments on this spot", @"- Help us correct any errors", @"- Suggest additional information that would be helpful", nil];
	
	else bulletPointsArray = [NSArray arrayWithObjects: @"- Ask the author a question", @"- Help us correct any errors", @"- Suggest additional information that would be helpful", @"- Suggest a place that you think should be added", nil];
	
	CGSize textBoxSizeMax	= CGSizeMake([Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, 2000); // height value does not matter as long as it is larger than height needed for text box
	UIFont *bulletFont = [ UIFont fontWithName: kFontName size: 15.0 ];
	
	for(NSString *bullet in bulletPointsArray) {
		
		CGSize textBoxSize = [bullet sizeWithFont: bulletFont constrainedToSize: textBoxSizeMax lineBreakMode: 0];
		CGRect bulletRect = CGRectMake ([Props global].leftMargin, theYPosition, textBoxSize.width, textBoxSize.height);
		UILabel *bulletLabel = [[UILabel alloc] initWithFrame:bulletRect];
		bulletLabel.font = bulletFont;
		bulletLabel.numberOfLines = 0;
		bulletLabel.text = bullet;
		bulletLabel.textColor = [UIColor colorWithWhite:.8 alpha:1];
		bulletLabel.backgroundColor = [UIColor clearColor];
        bulletLabel.tag = textTag;
		[self.view addSubview:bulletLabel];
		//[bullet drawInRect:bulletRect withFont: bulletFont];
		theYPosition += CGRectGetHeight(bulletRect) + 5;
	}
	
	//theYPosition += 5;
	
	labelHeight = 18;
	CGRect lastLabelRect = CGRectMake([Props global].leftMargin, [Props global].screenHeight - labelHeight - kBottomMargin - [Props global].titleBarHeight, [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, labelHeight);
	UILabel *lastLabel = [[UILabel alloc] initWithFrame: lastLabelRect];
	lastLabel.backgroundColor = [UIColor clearColor];
	lastLabel.numberOfLines = 5;
	lastLabel.lineBreakMode = 0;
	lastLabel.textColor = [UIColor colorWithWhite:.5 alpha:1];
	lastLabel.font = [UIFont fontWithName: kFontName size: 15.5];
	lastLabel.text = [NSString stringWithFormat:@"All comments are reviewed prior to posting."];
	lastLabel.textAlignment = UITextAlignmentCenter;
	lastLabel.tag = textTag;
    
	[self.view addSubview: lastLabel];
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (![textFieldRounded.text isEqualToString:kTextFieldPlaceholderText]) [self sendEmail:nil];

	else if (textField == usernameField)
		[usernameField resignFirstResponder];
	
	else if (textField == emailField)
		[emailField resignFirstResponder];
	
	else NSLog(@"ERROR: CommentPageView - Something weird going on wiht textFieldShouldReturn");
	
	return YES;
}


-(void)displayAlert {  
	
	/*NSString *alertMessage;
	
	if (entry != nil) 
		alertMessage = @"Head back to the entry?";
	
	else alertMessage = @"Head back to comments?";
    
    alertMessage = [alertMessage stringByAppendingString:@"All */
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thanks!" message:@"All comments are reviewed by the author prior to posting." delegate: self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];   
	 
	[alert show];  
} 


-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
	
    [self.parentViewController dismissModalViewControllerAnimated:YES];
    
	/*if (buttonIndex != 0) [self.parentViewController dismissModalViewControllerAnimated:YES];
		
	
	else {
		textFieldRounded.textColor = [UIColor grayColor];
		textFieldRounded.text = kTextFieldPlaceholderText;
	}*/
}


- (void) reset {
	textFieldRounded.text = kTextFieldPlaceholderText;
}


#pragma mark Text Fields

- (void) createTextField {
	
	//Add comment text field
	textFieldRounded = [[UITextView alloc] init];
	
	//textFieldRounded.borderStyle = UITextBorderStyleRoundedRect;
	textFieldRounded.textColor = [UIColor grayColor];
    textFieldRounded.backgroundColor = [UIColor whiteColor];
	textFieldRounded.font = [UIFont systemFontOfSize:16.0];
	textFieldRounded.text = kTextFieldPlaceholderText;	//textFieldRounded.backgroundColor = [UIColor clearColor];
	textFieldRounded.autocorrectionType = UITextAutocorrectionTypeYes;	// no auto correction support
	textFieldRounded.keyboardType = UIKeyboardTypeDefault;
	textFieldRounded.returnKeyType = UIReturnKeyDefault;
	textFieldRounded.delegate = self;	// let us be the delegate so we know when the keyboard's "send" button is pressed
	
	[self.view addSubview: textFieldRounded];

	
	//add username field
	usernameField = [[UITextField alloc] init];
	usernameField.textColor = [UIColor grayColor];
	//usernameField.borderStyle  = UITextBorderStyleRoundedRect;
	usernameField.font = [UIFont systemFontOfSize:16.0];
    usernameField.backgroundColor = [UIColor whiteColor];
	usernameField.autocorrectionType = UITextAutocorrectionTypeYes;	// no auto correction support
	usernameField.keyboardType = UIKeyboardTypeDefault;
	usernameField.returnKeyType = UIReturnKeySend;
	usernameField.delegate = self;	// let us be the delegate so we know when the keyboard's "send" button is pressed
	
	if(	[[NSUserDefaults standardUserDefaults] stringForKey:kNameOrAlias] !=nil)
		usernameField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kNameOrAlias];
	
	else usernameField.placeholder = kUsernameFieldPlaceholderText;
	
	[self.view addSubview: usernameField];
	
	
	emailField = [[UITextField alloc] init];
	emailField.textColor = [UIColor grayColor];
    emailField.backgroundColor = [UIColor whiteColor];
	//emailField.borderStyle  = UITextBorderStyleRoundedRect;
	emailField.font = [UIFont systemFontOfSize:16.0];
	emailField.autocorrectionType = UITextAutocorrectionTypeYes;	// no auto correction support
	emailField.keyboardType = UIKeyboardTypeEmailAddress;
	emailField.returnKeyType = UIReturnKeySend;
	emailField.delegate = self;	// let us be the delegate so we know when the keyboard's "send" button is pressed
	
	if(	[[NSUserDefaults standardUserDefaults] stringForKey:kEmailAddress] !=nil)
		emailField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kEmailAddress];
	
	else emailField.placeholder = kEmailFieldPlaceholderText;
	
	
	[self.view addSubview: emailField];
}


- (void)textViewDidBeginEditing:(UITextField *)textView {
	
	if([textView.text isEqualToString: kTextFieldPlaceholderText]) textFieldRounded.text = nil;
	
	textFieldRounded.textColor = [UIColor blackColor];
	[self setupEmailButtons];
}


- (void) textFieldDidBeginEditing:(UITextField *)textField {
	
	if (textField == emailField) {
		
		if ([textFieldRounded.text isEqualToString:kTextFieldPlaceholderText]) emailField.returnKeyType = UIReturnKeyDone;
		else emailField.returnKeyType = UIReturnKeySend;
			
		emailField.textColor = [UIColor blackColor];
	}
	
	else if (textField == usernameField) {
		
		if ([textFieldRounded.text isEqualToString:kTextFieldPlaceholderText]) usernameField.returnKeyType = UIReturnKeyDone;
		else usernameField.returnKeyType = UIReturnKeySend;
		
		usernameField.textColor = [UIColor blackColor];
	}
}


# pragma mark Button action methods

- (void) hideKeyboard:(id) sender {
	[textFieldRounded resignFirstResponder];
	[self removeEmailButtons];
	textFieldRounded.textColor = [UIColor lightGrayColor];
	textFieldRounded.text = kTextFieldPlaceholderText;
}


- (void) sendEmail: (id) sender {
	
	/*[Apsalar eventWithArgs:@"send comment",
	 @"entry id", [NSNumber numberWithInt:entry.entryid],
	 @"entry name", entry.name,
	 nil];*/
	
	SMLog *log = [[SMLog alloc] initWithPageID: kCommentsView actionID: kLeaveComment];
	log.entry_id = entry.entryid;
	[[ActivityLogger sharedActivityLogger] sendLogMessage: [log createLogString]];
	
	if ([usernameField.text isEqualToString:usernameField.placeholder]) usernameField.text = nil;
	
	if ([emailField.text isEqualToString:emailField.placeholder]) emailField.text = nil;
	
	[[ActivityLogger sharedActivityLogger] sendEmailWithContent: textFieldRounded.text userName:usernameField.text emailAddress:emailField.text andEntry:entry]; 
	
	if (usernameField.text != nil) [[NSUserDefaults standardUserDefaults] setObject:usernameField.text forKey:kNameOrAlias];
	
	if (emailField.text != nil) [[NSUserDefaults standardUserDefaults] setObject:emailField.text forKey:kEmailAddress];
	
	[textFieldRounded resignFirstResponder];
	
	[self removeEmailButtons];
	
	[self displayAlert];
}


- (void) setupEmailButtons {
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target:self action: @selector(hideKeyboard:)];	
	self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
	
	UIBarButtonItem *temporaryRightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style: UIBarButtonItemStyleDone target:self action: @selector(sendEmail:)];	
	self.navigationItem.rightBarButtonItem = temporaryRightBarButtonItem;
}


- (void) removeEmailButtons {
	[self addCancelButton];
	self.navigationItem.rightBarButtonItem = nil;
}


- (void) addCancelButton {
	
	self.navigationItem.leftBarButtonItem = nil;
	self.navigationItem.rightBarButtonItem = nil;
	self.navigationItem.hidesBackButton = TRUE;
	
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target:self action: @selector(goBack:)];
	
	self.navigationItem.leftBarButtonItem = temporaryBarButtonItem;
	
	
}


- (void) goBack: (id) sender {
	
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}


- (void) addTitleLabel {
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 260, 30)];
	
	[label setFont:[UIFont boldSystemFontOfSize:16.0]];
	label.adjustsFontSizeToFitWidth = TRUE;
	label.minimumFontSize = 13;
	[label setBackgroundColor:[UIColor clearColor]];
	//[label setTextColor:[UIColor colorWithRed: .94 green: .31 blue: .22 alpha:1]];
	label.textColor = [UIColor colorWithWhite:0.8 alpha:0.9];
	label.textAlignment = UITextAlignmentCenter;
	//label.alpha = .9;
	
	NSString *title = @" Share your thoughts or question...";
	
	//if (entry != nil) title = entry.name;
	
	//else title = @"Comment";
	
	[label setText:title];
	
	self.navigationItem.titleView = label;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	NSLog(@"CPV.shouldRotateToInterfaceOrientation");
    
    if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        //[[Props global] updateScreenDimensions: interfaceOrientation];
        
        return YES;
    }
    
    else return NO;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	NSLog(@"CPV.willRotateToInterfaceOrientation");
	[self performSelector:@selector(layoutSubviews) withObject:nil afterDelay:0.1];
}

/*
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    NSLog(@"Screen width = %f", [Props global].screenWidth);
    
    if ([Props global].osVersion < 5) [self.parentViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    else [self.presentingViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}
*/

@end
