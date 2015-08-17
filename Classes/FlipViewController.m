    //
//  FlipViewController.m
//  TheProject
//
//  Created by Tobin1 on 6/27/10.
//  Copyright 2010 Ard ica Technologies. All rights reserved.
//

#import "FlipViewController.h"
#import "EntriesAppDelegate.h"
#import "Props.h"
#import "Constants.h"
#import "SMLog.h"
#import	"ActivityLogger.h"
#import "EntryCollection.h"
#import "FilterPicker.h"
#import "MapViewController.h"

@interface FlipViewController (PrivateMethods)

- (void) hideSplashScreen;

@end


@implementation FlipViewController

@synthesize containerView; //, frontView,backView;


- (id) initWithAppDelegate:(EntriesAppDelegate*) theAppDelegate startingImage:(UIImage*) theStartingImage andDestination:(NSString*) theDestination {
	
    self = [super init];
	if (self) {
		appDelegate = theAppDelegate;	
		destination = theDestination;
		NSLog(@"Starting image address = %@", theStartingImage);
		frontView = [[UIImageView alloc] initWithImage:theStartingImage];
	}
    return self;
}


- (void)viewDidLoad {
	
	[super viewDidLoad];
	
	UIView *tmpContainerView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	//self.containerView = tmpContainerView;
	self.view = tmpContainerView;
	
	//[self.view addSubview:self.containerView];
	
	[self.view addSubview:frontView];
	
	// create the back view
	backView = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	
	NSString *theImageName;
	
	if ([destination  isEqual: kOriginalApp]) theImageName = ([Props global].deviceType == kiPad) ? @"Default-Portrait" : @"Default";
	
	else if ([destination  isEqual: kTestApp]) theImageName = @"TestApp";
    
    else theImageName = @"SutroWorld";
	
	UIImage *backViewImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:theImageName ofType:@"png"]];
	backView.image = backViewImage;
	
	if ([destination  isEqual: kTestApp]) {
		[frontView removeFromSuperview];
		[self.view addSubview:backView];
		[self hideLoginScreen];
	}
}


- (void) flipViews {
	
	@autoreleasepool {
	
	//UIViewAnimationTransition viewAnimation = [[Props global] inLandscapeMode] ? UIViewAnimationTransitionCurlDown : UIViewAnimationTransitionFlipFromLeft; 
	
		[UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(transitionDidStop:finished:context:)];
		
		
		if ([destination  isEqual: kOriginalApp]) [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view cache:YES];
		
		else [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
		
		[frontView removeFromSuperview];
		//[self.containerView addSubview:backView];
		[self.view addSubview:backView];

		
		[UIView commitAnimations];
	
		
	}
	
		
	NSLog(@"FLIPVIEWCONTROLLER.flipViews");
}


- (void)transitionDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	// re-enable user interaction when the flip is completed.
	NSLog(@"Animatation done.");
	
	NSLog(@"About to swap over between worlds");
	
	
	if ([destination  isEqual: kSutroWorld] || [destination  isEqual: kOriginalApp]) {
		
		//about 1.7 Mb after ten flips with only list view
        
        [[ActivityLogger sharedActivityLogger] endSession]; //End logging of test app use
		
		/*[EntryCollection resetContent]; //up to 2.27 MB after 10 flips with only list view
		[[MapViewController sharedMVC] reset]; //2.33 MB after 10, with only LV //What happpens here for places without locations?
        [[FilterPicker sharedFilterPicker] resetContent];
		[FilterPicker resetContent];*/
        
        [EntryCollection resetContent];
		[Props global].inTestAppMode = FALSE;
        [Props global].downloadTestAppContent = FALSE;
        
		
		NSLog(@"App id prior to switch = %i", [Props global].appID);
		
		if([destination  isEqual: kSutroWorld]){
			
			[Props global].appID = 0;
			[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kShouldQuit];
		}
		
		else {

			[Props global].appID = [[Props global] getOriginalAppId];
			[[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:kShouldQuit];
			NSLog(@"Just set should quit to FALSE");
		}
		
		NSLog(@"Just set the app id to %i", [Props global].appID);
		
		// Calling this method also ends up calling entry collection to set the database
		//[[Props global] setupPropsDictionary];
        [[Props global] setupPropsDictionary];
        [[EntryCollection sharedEntryCollection] initialize];
        [[FilterPicker sharedFilterPicker] initialize];
        [[MapViewController sharedMVC] reset]; //This needs to be after setting up props dictionary, as calling this for the first time before setting the app id causes problems

		
        [Props global].commentsDatabaseNeedsUpdate = TRUE;
        
		[[Props global] setContentFolder];
	
		if ([destination  isEqual: kTestApp])[Props global].showAds = FALSE;
        
        else if ([destination  isEqual: kOriginalApp]) [Props global].showAds = [Props global].freemiumType == kFreemiumType_V1 && [Props global].osVersion >= 4.3;
        
		[appDelegate setupSingleGuide];
		[appDelegate.portraitWindow addSubview:self.view];
		//if ([Props global].hasLocations)[[MapViewController sharedMVC] performSelectorInBackground:@selector(loadEntries) withObject:nil];
		
		[self hideSplashScreen];
	}
	
		
	else if ([destination  isEqual: kTestAppLogin]) {
		
		[appDelegate showLoginScreen];
	}
}


- (void) hideSplashScreen {
	
	frontView.alpha = 0;
	
	[UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[UIView setAnimationDuration: 0.5f ]; 
	[UIView setAnimationDelegate:appDelegate];
    [UIView setAnimationDidStopSelector:@selector(transitionDidStop:finished:context:)];
	
	backView.frame = CGRectMake(150, -10, 20, 10);
	backView.alpha = 0;
	//self.view.contentScaleFactor = .1;
	
	[UIView commitAnimations];
}


- (void) hideLoginScreen {

	[ UIView beginAnimations: nil context: nil ]; // Tell UIView we're ready to start animations.
	[ UIView setAnimationCurve: UIViewAnimationCurveEaseInOut ];
	[ UIView setAnimationDuration: 0.6f ]; 
	[UIView setAnimationDelegate:appDelegate];
    [UIView setAnimationDidStopSelector:@selector(finishedHidingLogin:finished:context:)];
	
	backView.frame = CGRectMake(150, -10, 20, 10);
	frontView.alpha = 0;
	//flipView.view.contentScaleFactor = .1;
	
	[UIView commitAnimations];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc {
	
	NSLog(@"FLIPVIEWCONTROLLER.dealloc");
	//self.containerView = nil;
	
	NSLog(@"FlipView contains %i subviews", [[self.view subviews] count]);
}


@end
