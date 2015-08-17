/*
 
 
 Version: 1.7
 */

#import "TestAppView.h"
#import "Constants.h"
#import "ActivityLogger.h"
#import "Props.h"
#import "EntriesAppDelegate.h"
#import "DataDownloader.h"
#import "AppPicker.h"
#import	"Reachability.h"
#import "EntryCollection.h"
#import "FilterPicker.h"
#import "Entry.h"
#import "MapViewController.h"
#import "GuideDownloader.h"

#define kLoginTextFieldHeight	40
#define kLoginTextFieldSize		20
#define kLoadingAnimationSize	92

@interface TestAppView (Private)

- (NSArray*) getAppListForUser:(NSString*) user withPassword:(NSString*) password;
- (void) updateStatusLabel;

- (void) getDataForApp;
- (void) getSmallIcons;
- (void) getBigIcons;
- (void) getMapIcons;
- (void) showGetUpdateAlert;
- (void) generateMapMarkers;

@end

@implementation TestAppView


// initialize the view, calling super and setting the  properties to nil

- (id)initWithAppDelegate: (EntriesAppDelegate*) theAppDelegate {
    
    self = [super init];
	if (self) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kEnteringTestApp object:nil];
        
		appDelegate = theAppDelegate;	
		
		loadingTag = nil;
		progressInd = nil;
		urlDictionary = nil;
	}
    return self;
}


- (void)loadView {	
	
	// setup our parent content view and embed it to the view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	self.view = contentView;
	
	yPosition = [Props global].screenWidth/5; //height of top of login
	
	UIImage *backgroundImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TestApp" ofType:@"png"]];
	
	UIImageView *imageHolder = [[UIImageView alloc] initWithImage: backgroundImage];
	float imageWidth = backgroundImage.size.width * ([Props global].screenHeight/ backgroundImage.size.height);
	imageHolder.frame = CGRectMake(([Props global].screenWidth - imageWidth)/2, 0, imageWidth, [Props global].screenHeight);
	
	[self.view addSubview:imageHolder];
	
	
	//check current bundle 
	
	yPosition += [self createUserNameTextFieldAtYPosition:yPosition] + [Props global].tweenMargin;
	
	yPosition += [self createPasswordTextFieldAtYPosition: yPosition] + 20;
	
	//loginButton = [TestAppView newButtonWithTitle:@"Login" target:self selector:@selector(login:) yPosition: yPosition];
	//[loginButton retain];
	
	loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	loginButton.frame = CGRectMake([Props global].leftMargin, yPosition, ([Props global].screenWidth - [Props global].leftMargin)/2 - [Props global].rightMargin * 2, 40);
	[loginButton setTitle:@"login" forState:UIControlStateNormal];
	[loginButton addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
	[loginButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
	loginButton.backgroundColor = [UIColor clearColor];
	loginButton.hidden = TRUE;
	[self.view addSubview:loginButton];
	
	
	UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	cancelButton.frame = CGRectMake(([Props global].screenWidth + [Props global].leftMargin)/2, yPosition, ([Props global].screenWidth - [Props global].leftMargin)/2 - [Props global].rightMargin * 2, 40);
	[cancelButton setTitle:@"cancel" forState:UIControlStateNormal];
	[cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
	[cancelButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
	cancelButton.backgroundColor = [UIColor clearColor];
							  
	[self.view addSubview:cancelButton];
	
	yPosition = CGRectGetMaxY(cancelButton.frame) + [Props global].tweenMargin;
	
	pickerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	pickerButton.frame = CGRectMake([Props global].leftMargin*2, yPosition, [Props global].screenWidth - [Props global].leftMargin * 4, 40);
	[pickerButton setTitle:@"Select App" forState:UIControlStateNormal];
	[pickerButton addTarget:self action:@selector(goToApp:) forControlEvents:UIControlEventTouchUpInside];
	[pickerButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
	pickerButton.backgroundColor = [UIColor clearColor];
	pickerButton.hidden = TRUE;
	[self.view addSubview:pickerButton];
	//pickerButton = [TestAppView newButtonWithTitle:@"Select App" target:self selector:@selector(goToApp:) yPosition: yPosition];
	//[pickerButton retain]; //app crashes without this, don't get why it is being released otherwise
	
	//only show the login button on startup if username and password are saved in defaults
	if(([[NSUserDefaults standardUserDefaults] objectForKey:@"password"] != nil) && ([[NSUserDefaults standardUserDefaults] objectForKey:@"username"] != nil))
		loginButton.hidden = FALSE;		
	
	yPosition += pickerButton.frame.size.height + [Props global].tweenMargin;
	
	buttonYPosition = yPosition;
}


- (float) createUserNameTextFieldAtYPosition: (float) theYPosition {
	
	float width = [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin;
	if (width > 350) width = 350;
	
	CGRect frame = CGRectMake(([Props global].screenWidth - width)/2, theYPosition, width, kLoginTextFieldHeight);
	textFieldRounded = [[UITextField alloc] initWithFrame:frame];
	textFieldRounded.borderStyle = UITextBorderStyleRoundedRect;
	textFieldRounded.textColor = [UIColor grayColor];
	textFieldRounded.font = [UIFont systemFontOfSize: kLoginTextFieldSize];
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"username"] != nil)
		textFieldRounded.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
	
	else	
		textFieldRounded.text = @"<username>";
	
	textFieldRounded.backgroundColor = [UIColor clearColor];
	textFieldRounded.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
	textFieldRounded.keyboardType = UIKeyboardTypeEmailAddress;
	textFieldRounded.returnKeyType = UIReturnKeyDone;
	textFieldRounded.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
	textFieldRounded.delegate = self;	// let us be the delegate so we know when the keyboard's "Done" button is pressed
		
	[self.view addSubview: textFieldRounded];
	
	return CGRectGetHeight(frame);
}


- (float) createPasswordTextFieldAtYPosition: (float) theYPosition {
	
	float width = [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin;
	if (width > 350) width = 350;
	
	CGRect frame = CGRectMake(([Props global].screenWidth - width)/2, theYPosition, width, kLoginTextFieldHeight);
	passwordTextField = [[UITextField alloc] initWithFrame:frame];
	passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
	passwordTextField.textColor = [UIColor grayColor];
	passwordTextField.font = [UIFont systemFontOfSize: kLoginTextFieldSize];
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"password"] != nil)
		passwordTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
	
	else	
		passwordTextField.placeholder = @"<password>";
	
	passwordTextField.backgroundColor = [UIColor clearColor];
	passwordTextField.secureTextEntry = YES;	// make the text entry secure (bullets)

	passwordTextField.keyboardType = UIKeyboardTypeDefault;
	passwordTextField.returnKeyType = UIReturnKeyDone;	
	
	passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
	
	passwordTextField.delegate = self;	// let us be the delegate so we know when the keyboard's "Done" button is pressed
	[self.view addSubview:passwordTextField];
	
	return CGRectGetHeight(frame);
}


- (void) login: (id) sender {
	
	NSLog(@"Trying to log in for user = %@ and password = %@ and bundle revision %i and appid = %i", textFieldRounded.text, passwordTextField.text, [Props global].bundleVersion, [Props global].appID);

	hidePickerButton = FALSE;
	hideLogin = TRUE;
	hidePicker = FALSE;
	
	[passwordTextField resignFirstResponder];
	
	if([[Reachability sharedReachability] internetConnectionStatus] != NotReachable) {
	
		loadingTagMessage = @"Logging in...";
		[self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
		
		//Sort out the source for the data
		NSString *theFilePath= [NSString stringWithFormat:@"%@/theAppList.plist", [Props global].cacheFolder];
		
		NSString *myRequestString = [[NSString alloc] initWithFormat:@"&username=%@&password=%@&svnrevision=%i&listapps=true", textFieldRounded.text, passwordTextField.text, [Props global].svnRevision];
		
		//NSLog(@"DOWNLOADER - Post request string = %@", myRequestString);
		
		NSData *myRequestData = [ NSData dataWithBytes: [ myRequestString UTF8String ] length: [ myRequestString length ] ];
		NSHTTPURLResponse   *response;
		
		
		NSURL *url = [ NSURL URLWithString: [NSString stringWithFormat:@"http://sutroproject.com/admin%@/", [Props global].adminSuffix]];
		
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc ] initWithURL: url]; 
		[request setHTTPMethod: @"POST" ];
		[request setHTTPBody: myRequestData ];
		
		NSData *appList = [NSURLConnection sendSynchronousRequest: request returningResponse:&response error: nil ];
		
		NSLog(@"Response header = \n%@", [response allHeaderFields]);
		
		NSArray * all = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:url];
		
		if ([all count] > 0) [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:all forURL:url mainDocumentURL:nil]; //BUG HAPPENING ON THIS LINE OF CODE
		
		
		//Write the data to disk
		[appList writeToFile: theFilePath atomically:YES];
		
		//NSLog(@"DOWNLOADER - Just wrote appList to %@", theFilePath);
		
		NSDictionary *appInfoDictionary = [[NSDictionary alloc] initWithContentsOfFile:theFilePath];
		
		int responseCode = [[appInfoDictionary valueForKey: @"response_code"] intValue];
		
		//Success
		if (responseCode == 0) {
			NSArray *arrayOfApps = [[NSArray alloc] initWithArray:[appInfoDictionary objectForKey: @"applicationlist"]];
			
			NSLog(@"TESTAPP.getAppListForUser: Login successful, array of apps has %i apps", [arrayOfApps count]);
			
			if([arrayOfApps count] > 0){
				pickerButton.hidden = FALSE;
				[self createAppPickerAtYPosition: yPosition withAppList: arrayOfApps];
				urlDictionary = [[NSDictionary alloc] initWithDictionary:[appInfoDictionary objectForKey: @"applicationurldict"]];
				
				NSLog(@"TESTAPP.login: urlDictionary has %i entries", [urlDictionary count]);
				
				[[NSUserDefaults standardUserDefaults] setObject:textFieldRounded.text forKey:@"username"]; //set default name for future use
				[[NSUserDefaults standardUserDefaults] setObject:passwordTextField.text forKey:@"password"]; //set default password for future use
			}
			
			else
				[self showErrorMessageWithText:@"Unknown error logging in. Give it another shot (and if it still doesn't work, let us know!)."];
			
		}
		
		else if (responseCode == 1) { 	//Login failure
			
			[self showErrorMessageWithText:@"Incorrect username or password"];
			[self resetTextFields];
		}
		
		else if (responseCode == 2)[self showGetUpdateAlert]; //Software out of date
		
		[self removeLoadingAnimation];
	}
	
	else {
		[self showErrorMessageWithText: @"Looks like you don't have an internet connection. Give it another shot when you do."];
		loginButton.hidden = TRUE;
	}
				
}


- (void) showErrorMessageWithText:(NSString*) errorText {
		
	UIFont *errorFont = [UIFont fontWithName: kFontName size: 20];
	CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin, 120);
	CGSize textBoxSize = [errorText sizeWithFont: errorFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
	
	CGRect imageUnderlayLabelRect = CGRectMake(([Props global].screenWidth - textBoxSize.width)/2, buttonYPosition, textBoxSize.width, textBoxSize.height);
	
	errorLabel = [[UILabel alloc] initWithFrame:imageUnderlayLabelRect];
	errorLabel.backgroundColor = [UIColor clearColor];
	errorLabel.numberOfLines = 5;
	errorLabel.textColor = [UIColor whiteColor];
	errorLabel.font = errorFont;
	
	errorLabel.text = errorText;
	errorLabel.textAlignment = UITextAlignmentCenter;
	
	[self.view addSubview:errorLabel];
	
}	


- (void) resetTextFields {
	
	passwordTextField.text = nil;
	passwordTextField.placeholder = @"<password>";
	loginButton.hidden = TRUE;
}


- (void) createAppPickerAtYPosition: (float) theYPosition withAppList: (NSArray*) theAppList {
	
	float pickerWidth = [Props global].screenWidth - [Props global].leftMargin * 2;
	
	float pickerHeight = 200;
	
	CGRect frame = CGRectMake(([Props global].screenWidth - pickerWidth)/2, theYPosition, pickerWidth, pickerHeight);
	
	appPicker = [[AppPicker alloc] initWithFrame:frame andApps: theAppList];
	
	[self.view addSubview:appPicker];
	
}


- (void) goToApp: (id) sender {
	
	//show loading icon and text
	//need to do this in a different thread to get it to show up
	
	NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
	[NSURLCache setSharedURLCache:sharedCache];
	
	NSLog(@"Getting ready to go to app");
	
	hidePickerButton = TRUE;
	hideLogin = TRUE;
	hidePicker = TRUE;
	
	//[[DataDownloader sharedDataDownloader] pauseDownload];
	
	loadingTagMessage = [NSString stringWithFormat:@"Loading %@...", [appPicker getPickerTitle]];
	//[self createLoadingAnimation];
	[self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
	
	[FilterPicker resetContent];

	[[Props global] setTheAppID:[appPicker getPickerTitle]];
	
	NSLog(@"Just set inTestAppMode to true");
    //download content to folder
	NSLog(@"About to start downloading data for app");
    
    /*    
    GuideDownloader *downloader = [[GuideDownloader alloc] initForTestAppWithGuideId:[Props global].appID];
    
    loadingTagMessage =  @"Downloading latest app database...";
	[self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
    
    [downloader getDataForApp];
    
    loadingTagMessage =  @"Downloading icon photos...";
    [self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
    [downloader getIconPhotos];
    
    loadingTagMessage = @"Downloading thumbnails...";
    [self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
    [downloader getThumbnails];
    
    
    if ([downloader doesAppHaveMaps]){
        
        loadingTagMessage = @"Downloading empty map database...";
        [self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
        [downloader getMapDatabase];
        
        loadingTagMessage = @"Downloading offline maps...";
        [self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
        [downloader getOfflineMapTiles];
    }
    
    loadingTagMessage = @"getting offline link files";
    [self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
    [downloader getOfflineLinkFiles];
    
    [downloader performSelectorInBackground:@selector(getOtherPhotos) withObject:nil];
    
    //Register to recieve future updates when available from downloader
    NSString *notificationName = [NSString stringWithFormat:@"%@_%i", kUpdateDownloadProgress, [Props global].appID];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloadProgress:) name:notificationName object:nil];
	*/
    
    [Props global].inTestAppMode = TRUE;
	[Props global].commentsDatabaseNeedsUpdate = TRUE;
    
	[self getDataForApp];
    
    //[Props global].downloadTestAppContent = TRUE;
    
	[[MapViewController sharedMVC] reset];
	
	NSLog(@"About to set up portrait user interface");
	
	[appDelegate setupSingleGuide];
	
    [[DataDownloader sharedDataDownloader] performSelectorInBackground:@selector(getLowPriorityTestAppContent) withObject:nil];
	//[[MapViewController sharedMVC] performSelectorInBackground:@selector(loadEntries) withObject:nil];
	
	[self removeLoadingAnimation];
	
	[appDelegate hideTestAppLogin];
    
    [Props global].isTestAppDevice = TRUE;
    [[ActivityLogger sharedActivityLogger] startSession];
}


- (void) updateDownloadProgress: (NSNotification *) theNotification  {
    
    // NSLog(@"LIBRARYCELL.updateDownloadProgress: %i", entry.entryid);
    NSDictionary *status = [theNotification object];
    
    [self performSelectorOnMainThread:@selector(updateProgressView:) withObject:status waitUntilDone:NO];
}


- (void) updateProgressView:(NSDictionary*) theStatus {
    
    if (theStatus != nil) {
        
        if (lastStatus != nil) { lastStatus = nil;}
        lastStatus = theStatus;
        
        float amountDownloaded = [[theStatus objectForKey:@"current"] floatValue];
        float total = [[theStatus objectForKey:@"total"] floatValue];
         NSString *newCurrentTask = [theStatus objectForKey:@"current task"];
        
        //NSLog(@"LIBRARYCELL.updateProgressView: amountDownloaded = %0.1f, total = %0.0f, currentTask = %@, status = %i", amountDownloaded, total, newCurrentTask, [[theStatus objectForKey:@"summary"] intValue]);
        
        if (newCurrentTask != nil && newCurrentTask != currentTask) {
            NSLog(@"Updating current task to %@", newCurrentTask);
            currentTask = newCurrentTask;
            
            [self updateStatusLabel];
        }
        
        //NSLog(@"LIBRARYCELL.updateProgressView: %i total = %f, current = %0.1f, download progress = %0.3f", entry.entryid, total, amountDownloaded, downloadProgress.progress);
        
        float fraction = amountDownloaded/total;
        
        //The progress contin
        if (downloadProgress.progress < 0.01 /*make sure to set download progress if we're just starting*/) {
            downloadProgress.progress = fraction;
            downloadProgressLabel.text = total > 0 ? [NSString stringWithFormat:@"%0.1f of %0.0f MB", amountDownloaded, total] : @"0.0 of ? MB";
        }
        
        //NSLog(@"Download progress text = %@", downloadProgressLabel.text);
        
        if ([[theStatus objectForKey:@"summary"] intValue] == kDownloadComplete) {
            
        }
        
        else if ([[theStatus objectForKey:@"summary"] intValue] >= kReadyForViewing){
            
            [self updateStatusLabel];
        }
    }
    
    else {
        downloadProgressLabel.text = @"0.0 of ? MB";
    }
    
    
    [downloadProgressLabel setNeedsDisplay];
    [downloadProgress setNeedsDisplay];
    
    //NSLog(@"LIBRARYCELL.updateDownloadProgress:Download progress for %i. Downloading = %@", entry.entryid, downloading ? @"TRUE" : @"FALSE");
}


- (void) updateStatusLabel {
    
    //cancelImageDownloadButton.hidden = TRUE; //easier to make this true by default and then only show it when appropriate
    //statusLabel.hidden = FALSE;
    
    if (!connectedToInternet) statusLabel.text = [NSString stringWithFormat:@"Waiting for internet"];
    
    else statusLabel.text = [NSString stringWithFormat:@"%@", currentTask];
    
    //NSLog(@"LIBRARYCELL.updateStatusLabel: Status label = %@ and paused = %@", statusLabel.text, paused ? @"TRUE" : @"FALSE");
    
    [statusLabel setNeedsDisplay];
}


- (void) createLoadingAnimation {
	
	//Line below and last line of method are needed to wrap separate thread and create memory pool
	@autoreleasepool {
	
		pickerButton.hidden = hidePickerButton;
		loginButton.hidden = hideLogin;
		appPicker.hidden	= hidePicker;
		
		float loadingAnimationSize = 33; //This variable is weird - only sort of determines size at best.
		
		UIFont *errorFont = [UIFont fontWithName: kFontName size: 19];
		CGSize textBoxSizeMax = CGSizeMake([Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin - 80, 60);
		CGSize textBoxSize = [loadingTagMessage sizeWithFont: errorFont constrainedToSize: textBoxSizeMax lineBreakMode: 2];
		
		float progressInd_x = ([Props global].screenWidth - (loadingAnimationSize + 50 + textBoxSize.width))/2 + 10;
		float progressInd_y = buttonYPosition;
		
		CGRect frame = CGRectMake(progressInd_x, progressInd_y, loadingAnimationSize, loadingAnimationSize);
		
    @synchronized([Props global].dbSync) {
    
        if (progressInd != nil) {
            [progressInd removeFromSuperview];
            progressInd = nil;
        }
        
        progressInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
        progressInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [progressInd sizeToFit];
        [progressInd startAnimating];
        [self.view addSubview: progressInd];
    }
    
		
		CGRect labelRect = CGRectMake (progressInd_x + 50, progressInd_y + (loadingAnimationSize - textBoxSize.height)/2, textBoxSize.width, textBoxSize.height);
		
		if (loadingTag != nil) {
			[loadingTag removeFromSuperview];
			loadingTag = nil;
		}
		
		loadingTag = [[UILabel alloc] initWithFrame:labelRect];
		loadingTag.text = loadingTagMessage;
		loadingTag.font = errorFont;
		loadingTag.textColor = [UIColor whiteColor];
		loadingTag.lineBreakMode = 0;
		loadingTag.numberOfLines = 2;
		loadingTag.shadowColor = [UIColor darkGrayColor];
		loadingTag.shadowOffset = CGSizeMake(1, 1);
		loadingTag.backgroundColor = [UIColor clearColor];
		
		[self.view addSubview:loadingTag];
	
	}

}


- (void) removeLoadingAnimation {
	
	[loadingTag removeFromSuperview];
	[progressInd removeFromSuperview];
	
}


+ (UIButton *)newButtonWithTitle:	(NSString *)title
						  target:(id)target
						selector:(SEL)selector
					   yPosition: (int) theYPosition
					   {	
	
						   float buttonWidth = [Props global].screenWidth - [Props global].leftMargin - [Props global].rightMargin;
						   CGRect frame = CGRectMake(([Props global].screenWidth -buttonWidth)/2, theYPosition, buttonWidth, 40);
	
	UIButton *button = [UIButton buttonWithType: UIButtonTypeRoundedRect];
	button.frame = frame;					   
	
	button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
						   
	[button setTitle:title forState:UIControlStateNormal];	
	
	[button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
	
	[button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
	
	button.backgroundColor = [UIColor clearColor];
	
	return button;
}


#pragma mark 
#pragma mark TextField Delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	// the user pressed the "Done" button, so dismiss the keyboard
	
	[textField resignFirstResponder];
	
	if([passwordTextField.text length] > 4)
		[self login:nil];
	
	return YES;
}


- (void) textFieldDidEndEditing: (UITextField *) textField {
	
	//if(textField == passwordTextField)
	//	[self.view addSubview: loginButton];
	
	if((textFieldRounded.text != nil) && (passwordTextField.text != nil)) loginButton.hidden = NO;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
	if(errorLabel != nil)
		errorLabel.hidden = TRUE;
	
	if(textField == textFieldRounded) {
		textFieldRounded.text = nil;
		textFieldRounded.textColor = [UIColor blackColor];
	}
	
	else if (textField == passwordTextField) {
		passwordTextField.text = nil;
		passwordTextField.textColor = [UIColor blackColor];
		
		if (textFieldRounded.text != nil) loginButton.hidden = FALSE;
			
	}
	else NSLog(@"ERROR - TestAppView, textViewDidBeginEditing");
	
}

#pragma mark
#pragma mark Data Downloading methods

- (void) showGetUpdateAlert {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Looks like your version of SF Explorer is out of date." message:@"You'll need the latest version for the test app to work correctly. Click 'Update' below to go off to the App Store to get the update." delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Update", nil];
	[alert show];
}


-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
	
	//Go to App Store to get latest version
	if (buttonIndex != 0){
		[Props global].inTestAppMode = TRUE;
		[[NSNotificationCenter defaultCenter] postNotificationName:kFlipWorlds object:nil];
		
		for (UIView *view in [self.view subviews]) [view removeFromSuperview];
		
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[Props global].appLink]];
	}
		
	//Leave test app
	else {
		
		[Props global].inTestAppMode = TRUE;
		[[NSNotificationCenter defaultCenter] postNotificationName:kFlipWorlds object:nil];

		for (UIView *view in [self.view subviews]) [view removeFromSuperview];
	}					  
}


- (void) cancel: (id) sender {
	
	NSLog(@"TestAppView.cancel: called");
	
	[Props global].inTestAppMode = TRUE;
	[[NSNotificationCenter defaultCenter] postNotificationName:kFlipWorlds object:nil];
	
	for (UIView *view in [self.view subviews]) [view removeFromSuperview];	
}


- (void) getDataForApp {
	
	[[DataDownloader sharedDataDownloader] pauseDownload];
	
	loadingTagMessage =  @"Downloading latest app database...";
	[self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
	
	if([[NSFileManager defaultManager] isWritableFileAtPath:[Props global].contentFolder] || [[NSFileManager defaultManager] createDirectoryAtPath: [Props global].contentFolder withIntermediateDirectories:YES attributes: nil error:nil ])
		NSLog(@"TESTAPP - Content folder should have been successfully created at %@", [Props global].contentFolder);
	
	NSLog(@"App name = %@", [appPicker getPickerTitle]);
	NSString *urlString = [[urlDictionary objectForKey: [appPicker getPickerTitle]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];  // [[NSString stringWithFormat: @"http://www.sutroproject.com/content/%i/%i Content/content.sqlite3", [Props global].appID, [Props global].appID] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
	
	NSURL *dataURL = [NSURL URLWithString: urlString];
	NSLog(@"TESTAPP - About to try and download database at %@", urlString);
	
	//Get the data
	NSData *databaseData = [[NSData alloc] initWithContentsOfURL:dataURL];
	
	NSString *theFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].contentFolder];
	
	//Write the data to disk
	[databaseData writeToFile: theFilePath atomically:YES];
	
	
    [EntryCollection resetContent];
    [[Props global] setupPropsDictionary];
    [[EntryCollection sharedEntryCollection] initialize];
    [[FilterPicker sharedFilterPicker] initialize];
    [[MapViewController sharedMVC] reset]; //This needs to be after setting up props dictionary, as calling this for the first time before setting the app id causes problems
    
    NSLog(@"Props dictionary set up for %@", [Props global].appName);
    
	NSLog(@"TESTAPP.getDataForApp: Number of entries in collection = %i",[[EntryCollection sharedEntryCollection] numberOfEntries]);
	
	[self getSmallIcons];
	[self getBigIcons];
	[self generateMapMarkers];
    
    
	[Props global].dataDownloaderShouldCheckForUpdates = TRUE;
	[[DataDownloader sharedDataDownloader] resumeDownload];
	NSLog(@"TESTAPP - Done getting test app data");	
}


- (void) getSmallIcons {
	
	NSString *theFilePath;
	
	NSString *theFolderPath = [NSString stringWithFormat:@"%@/images", [Props global].contentFolder];
	
	loadingTagMessage =  @"Downloading small icon images...";
	[self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
	
	if([[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath] || [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ])
		NSLog(@"TESTAPP - Content folder should have been successfully created at %@", theFolderPath);
	
	NSLog(@"TESTAPP - Starting to download small icons for an entry collection with %i entries", [[EntryCollection sharedEntryCollection].allEntries count]);
	
	for(Entry* theEntry in [EntryCollection sharedEntryCollection].allEntries) {
		
		@autoreleasepool {
		
		//Sort out where to write the data/ check if it's already there
			theFilePath = [NSString stringWithFormat:@"%@/%i-icon.jpg", theFolderPath, theEntry.icon];
			
			// check to see if the file exists either in the documents directory or resources folder
			if(([[NSFileManager defaultManager] fileExistsAtPath: theFilePath] != TRUE)) {
				
				//Source for the data
				NSString *tempString = [[NSString alloc] initWithFormat: @"http://www.sutromedia.com/published/iphone-sized-photos/icons/%i-icon.jpg", theEntry.icon];
				
				NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
				
				//Get the data
				NSData *imageData = [[NSData alloc] initWithContentsOfURL:dataURL];
				
				//Write the data to disk
				NSError * theError = nil;
				
				if([imageData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) {
					NSLog(@"TESTAPPVIEW.getSmallIcons: failed to write local file to %@, error = %@, userInfo = %@", theFilePath, theError, [theError userInfo]);
				}
				
				//Clean up
			}
		
		}
	}
}


- (void) getBigIcons {
	
	NSLog(@"TESTAPP - Starting to download Big Icons");
	
	loadingTagMessage =  @"Downloading big icon images...";
	[self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
	
	int downloadCounter = 0;
	
	NSString *theFolderPath = [NSString stringWithFormat:@"%@/images",[Props global].contentFolder];
	
	//check to see if images folder is there and create it if not
	if([[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath] || [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ]) {
		
		for(Entry* theEntry in [EntryCollection sharedEntryCollection].allEntries) {
			
			@autoreleasepool {
			
			//Sort out where to write the data/ check if it's already there
				NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/%i.jpg", theFolderPath, theEntry.icon];
				
				// check to see if the file exists either in the documents directory or resources folder
				if(([[NSFileManager defaultManager] fileExistsAtPath: theFilePath] != TRUE)) {
					
					//Source for the data
					NSString *tempString = [[NSString alloc] initWithFormat: @"http://www.sutromedia.com/published/iphone-sized-photos/%i.jpg", theEntry.icon];
					
					NSString *urlString = [tempString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];	
					
					NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
					//Get the data
					NSData *imageData = [[NSData alloc] initWithContentsOfURL:dataURL];
					
					//Write the data to disk
					if (![imageData writeToFile: theFilePath atomically:YES]) NSLog(@"Error writing file to %@ from %@", urlString, theFilePath); 
					
					//Clean up
					
					//Clean up
					//[urlString release];
					//[autoreleasepool drain];
				}
				

				
				if([[NSFileManager defaultManager] fileExistsAtPath: theFilePath]) {
					
					downloadCounter ++;
					
					NSString *query = [[NSString alloc] initWithFormat:@"UPDATE photos SET downloaded_320px_photo = %i WHERE rowid = %i", downloadCounter, theEntry.icon];
					
					//NSLog(@"DATADOWNLOADER.downloadImageForImageArray: Updating photo_downloaded, query = %@", query);
					
					@synchronized([Props global].dbSync) {
						///NSLog(@"TestApp.imagesForImageArray:lock");
                    FMDatabase *db = [EntryCollection sharedContentDatabase];
						[db executeUpdate:@"BEGIN TRANSACTION"];
						[db executeUpdate:query];
						[db executeUpdate:@"END TRANSACTION"];
					}
					
				}
				
			}
		}
	}
}


- (void) generateMapMarkers {
	
	NSLog(@"TESTAPPVIEW.generateMapMarkers");
	
	loadingTagMessage =  @"Generating map markers...";
	[self performSelectorInBackground:@selector(createLoadingAnimation) withObject:nil];
		
	NSString *theFolderPath = [NSString stringWithFormat:@"%@/images",[Props global].contentFolder];
	
	if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath])
		[[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:nil ];
	
	//NSLog(@"background width = %f", background2.size.width);
	
	float scaledWidth = 70;
	float imageWidth = 58;
	CGRect imageRect = CGRectMake((scaledWidth - imageWidth)/2, (scaledWidth - imageWidth)/2 - 4, imageWidth, imageWidth);
	
	for(Entry *theEntry in [EntryCollection sharedEntryCollection].allEntries) {
		
		@autoreleasepool {
		
			NSString *theImagePath = [NSString stringWithFormat:@"%@/images/%i-marker.png",[Props global].contentFolder , theEntry.icon];
			
			if (![[NSFileManager defaultManager] fileExistsAtPath: theImagePath]) {
				
				NSLog(@"TESTAPPVIEW.generateMapMarkers:Adding %@", theEntry.name);
				
				UIImage *squareImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/images/%i-icon.jpg",[Props global].contentFolder , theEntry.icon]];
				
				if (squareImage != nil) {
					
					UIImage *background2 = [UIImage imageNamed:@"Marker_background4.png"];
					
					float scaledHeight = background2.size.height * (scaledWidth/background2.size.width);
					
					CGSize backgroundSize = CGSizeMake(scaledWidth, scaledHeight);
					
					//NSLog(@"Marker image retain = %i and background retain = %i and background width = %f imageRect width = %f, backgroundRectWidth = %f, background size width = %f", [markerImage retainCount], [background2 retainCount], background2.size.width, imageRect.size.width, backgroundRect.size.width, backgroundRect.size.width);
					
					UIGraphicsBeginImageContext(backgroundSize);
					[squareImage drawInRect:imageRect];
					[background2 drawAtPoint:CGPointZero];
					
					UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
					UIGraphicsEndImageContext();
					
					NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(newImage)];
					
					if(![imageData writeToFile:theImagePath atomically:YES])
						NSLog(@"TESTAPPVIEW.generateMapMarkers: getFileWithName() failed to write file to %@", theImagePath);
					
				}
			}
		
		}
	}
}


- (void)dealloc {
	
    @synchronized([Props global].dbSync) {} //Necessary to avoid crash as indicator is updated in a background thread
	
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	//NSLog(@"TESTAPPVIEW.shouldAutorotateToInterfaceOrientation");
	
	return NO;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	
}



@end