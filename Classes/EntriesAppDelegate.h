
#import <UIKit/UIKit.h>
#import "CrashReportSender.h"

@class TestAppView, FlipViewController;


@interface EntriesAppDelegate : NSObject  <UIApplicationDelegate, CrashReportSenderDelegate> {

    UIWindow *loginWindow;
	UIWindow *portraitWindow;
	UITabBarController *tabBarController;
	TestAppView	*testAppView;
	FlipViewController *flipView;
	UIWindow *flipWindow;
    BOOL    doNotShowUpgradeOrReviewPopup; //Set to yes when there is an update
}


@property (nonatomic)	UITabBarController	*tabBarController;
@property (nonatomic, strong)	UIWindow			*portraitWindow;

- (void) setupSingleGuide;
- (void) showLoginScreen;
- (BOOL) shouldShowWiFiAlert;
- (void) hideTestAppLogin;
- (void) print_free_memory;
- (UIImage *)imageByCropping:(UIImage *)imageToCrop toRect:(CGRect)rect;
- (UIImage*) takeScreenshot;
- (void) addScreenshotButton;
- (void) setupLibraryHome; 
- (void) runStartupTasks;
- (void) updateContent; //Currently used for SW only - need to figure out how to merge these two
//- (void) checkForContentUpdate;
//- (void) startAnimation;
//- (void) checkForSoftwareUpdates;


@end
