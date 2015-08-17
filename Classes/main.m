/*

File: main.m
Version: 1.0

*/

#import <UIKit/UIKit.h>

int main(int argc, char *argv[])
{
	@autoreleasepool {
		setenv("CLASSIC", "0", 1);
		int retVal = UIApplicationMain(argc, argv, nil, @"EntriesAppDelegate");
    return retVal;
    }
}