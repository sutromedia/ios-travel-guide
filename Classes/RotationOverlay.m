//
//  RotationOverlay.m
//  TheProject
//
//  Created by Tobin1 on 4/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RotationOverlay.h"


@implementation RotationOverlay



// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    
}




- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    if (interfaceOrientation != UIDeviceOrientationFaceUp && interfaceOrientation != UIDeviceOrientationFaceDown && interfaceOrientation != UIDeviceOrientationUnknown) {
        
        return YES;
    }
    
    else return NO;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	if (toInterfaceOrientation != UIDeviceOrientationFaceUp && toInterfaceOrientation != UIDeviceOrientationFaceDown && toInterfaceOrientation != UIDeviceOrientationUnknown) {
        
        [[Props global] updateScreenDimensions: toInterfaceOrientation];
	}
}


@end
