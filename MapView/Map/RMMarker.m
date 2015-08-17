//
//  RMMarker.m
//
// Copyright (c) 2008-2009, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "RMMarker.h"

#import "RMPixel.h"

@implementation RMMarker

@synthesize projectedLocation;
@synthesize enableDragging;
@synthesize enableRotation;
@synthesize data;
@synthesize label;
@synthesize textForegroundColor;
@synthesize textBackgroundColor;
@synthesize id;
@synthesize controlLayers;

//#define defaultMarkerAnchorPoint CGPointMake(0.5, 0.5)
#define defaultMarkerAnchorPoint CGPointMake(0.5, 1.0)

+ (UIFont *)defaultFont
{
	return [UIFont systemFontOfSize:15];
}

// init
- (id)init
{
    if (self = [super init]) {
        label = nil;
        textForegroundColor = [UIColor blackColor];
        textBackgroundColor = [UIColor clearColor];
		enableDragging = YES;
		enableRotation = YES;
    }
    return self;
}

//New code from Paul Mans patch
/*- (NSArray*) controlLayers {
	
	return controlLayers;
}*/

- (id) initWithUIImage: (UIImage*) image
{
	return [self initWithUIImage:image anchorPoint: defaultMarkerAnchorPoint];
}


- (id) initWithUIImage: (UIImage*) image andId:(int) theId
{
	self.id = theId;
	self.controlLayers = nil;
	return [self initWithUIImage:image anchorPoint: defaultMarkerAnchorPoint];
}


- (id) initWithUIImage: (UIImage*) image anchorPoint: (CGPoint) _anchorPoint
{
	if (![self init])
		return nil;
	
	self.contents = (id)[image CGImage];
	self.bounds = CGRectMake(0,0,image.size.width,image.size.height);
	self.anchorPoint = _anchorPoint;
	
	self.masksToBounds = NO;
	self.label = nil;
	
	return self;
}

- (void) replaceUIImage: (UIImage*) image
{
	[self replaceUIImage:image anchorPoint:defaultMarkerAnchorPoint];
}

- (void) replaceUIImage: (UIImage*) image
			anchorPoint: (CGPoint) _anchorPoint
{
	self.contents = (id)[image CGImage];
	self.bounds = CGRectMake(0,0,image.size.width,image.size.height);
	self.anchorPoint = _anchorPoint;
	
	self.masksToBounds = NO;
}

- (void) setLabel:(UIView*)aView
{
	//new code from Paul Mans post **
	//NSLog(@"Set label called with %i subviews", [[aView subviews] count]);
	for (UIView *subView in [aView subviews]) {
		//NSLog(@"View class = %@", [subView class]);
		if ([subView isKindOfClass:[UIButton class]]) {
			if (!controlLayers) {
				controlLayers = [NSMutableArray new];
			}
			[controlLayers addObject:subView];
		}
	} //** End new code
	
	if (label == aView) {
		return;
	}

	if (label != nil)
	{
		[[label layer] removeFromSuperlayer];
		[label release];
		label = nil;
	}
	
	if (aView != nil)
	{
		label = [aView retain];
		[self addSublayer:[label layer]];
	}
}

- (void) changeLabelUsingText: (NSString*)text
{
	CGPoint position = CGPointMake([self bounds].size.width / 2 - [text sizeWithFont:[RMMarker defaultFont]].width / 2, 4);
/// \bug hardcoded font name
	[self changeLabelUsingText:text position:position font:[RMMarker defaultFont] foregroundColor:[self textForegroundColor] backgroundColor:[self textBackgroundColor]];
}

- (void) changeLabelUsingText: (NSString*)text position:(CGPoint)position
{
	[self changeLabelUsingText:text position:position font:[RMMarker defaultFont] foregroundColor:[self textForegroundColor] backgroundColor:[self textBackgroundColor]];
}

- (void) changeLabelUsingText: (NSString*)text font:(UIFont*)font foregroundColor:(UIColor*)textColor backgroundColor:(UIColor*)backgroundColor
{
	CGPoint position = CGPointMake([self bounds].size.width / 2 - [text sizeWithFont:font].width / 2, 4);
	[self setTextForegroundColor:textColor];
	[self setTextBackgroundColor:backgroundColor];
	[self changeLabelUsingText:text  position:position font:font foregroundColor:textColor backgroundColor:backgroundColor];
}

- (void) changeLabelUsingText: (NSString*)text position:(CGPoint)position font:(UIFont*)font foregroundColor:(UIColor*)textColor backgroundColor:(UIColor*)backgroundColor
{
	CGSize textSize = [text sizeWithFont:font];
	CGRect frame = CGRectMake(position.x,
							  position.y,
							  textSize.width+4,
							  textSize.height+4);
	
	UILabel *aLabel = [[UILabel alloc] initWithFrame:frame];
	[self setTextForegroundColor:textColor];
	[self setTextBackgroundColor:backgroundColor];
	[aLabel setNumberOfLines:0];
	[aLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	[aLabel setBackgroundColor:backgroundColor];
	[aLabel setTextColor:textColor];
	[aLabel setFont:font];
	[aLabel setTextAlignment:UITextAlignmentCenter];
	[aLabel setText:text];
	
	[self setLabel:aLabel];
	[aLabel release];
}

- (void) toggleLabel
{
	if (self.label == nil) {
		return;
	}
	
	if ([self.label isHidden]) {
		[self showLabel];
				
	} else {
		[self hideLabel];
	}
}

- (void) showLabel
{
	//NSLog(@"Show label called");
	if ([self.label isHidden]) {
		
	//	NSLog(@"Show label called 2");
		// Using addSublayer will animate showing the label, whereas setHidden is not animated
		[self addSublayer:[self.label layer]];
		[self.label setHidden:NO];
		
	
		//label.frame = CGRectMake(0, 0, 40, 40);
		
		//NSLog(@"RMMARKER: just set frame size");
		
		//CALayer *layer = [self.label layer];
		
		//layer.transform = CATransform3DMakeScale(0.3, 0.3, 1.0f);

		
		//layer.bounds = CGRectMake(0, 0, 40, 40);
		
		
		//Setting the bounds does not re-size subviews
		/*
		CGRect oldRect = CGRectMake(0, 0, 2, 2);
		CGRect newRect = CGRectMake(0, 0, 200, 100);
		CABasicAnimation *boundsAnimation = [ CABasicAnimation animationWithKeyPath: @"bounds"];
		[boundsAnimation setFromValue:[NSValue valueWithCGRect:oldRect]] ;
		[boundsAnimation setToValue: [NSValue valueWithCGRect:newRect]] ;
		[boundsAnimation setDuration: 5.0f] ;
		//[[self.label layer] setBounds:newRect] ;
		[[self.label layer] addAnimation: boundsAnimation forKey: @"someKey"] ;
		*/
		
		//This approach is close, but the re-sizing is done from the center
		/*
		CAKeyframeAnimation *bounce = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
		
		CATransform3D forward = CATransform3DMakeScale(0.1, 0.1, 1);
		CATransform3D back = CATransform3DMakeScale(0.7, 0.7, 1);
		CATransform3D forward2 = CATransform3DMakeScale(1.2, 1.2, 1);
		CATransform3D back2 = CATransform3DMakeScale(0.9, 0.9, 1);
		CATransform3D forward3 = CATransform3DMakeScale(1.1, 1.1, 1);
		
		[bounce setValues:[NSArray arrayWithObjects:[NSValue valueWithCATransform3D:forward],[NSValue valueWithCATransform3D:back],[NSValue valueWithCATransform3D:forward2],[NSValue valueWithCATransform3D:back2],[NSValue valueWithCATransform3D:forward3],[NSValue valueWithCATransform3D:CATransform3DIdentity],nil]];
		
		[bounce setDuration:6.6];
		
		//[self.label layer].anchorPoint = CGPointMake(.3, 1);

		[[self.label layer] addAnimation:bounce forKey:@"bounceAnimation"];*/

		/*CALayer *welcomeLayer = [self.label layer];
		
		// Create a keyframe animation to follow a path back to the center
		CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
		bounceAnimation.removedOnCompletion = NO;
		
		CGFloat animationDuration = 2.5;
		
		
		// Create the path for the bounces
		CGMutablePathRef thePath = CGPathCreateMutable();
		
		CGFloat x = 60;
		CGFloat midY = -30;
		CGFloat originalOffsetY = 100 - midY;
		
		CGFloat offsetDivider = 4.0;
		
		BOOL stopBouncing = NO;
	
		//CGContextScaleCTM(<#CGContextRef c#>, <#CGFloat sx#>, <#CGFloat sy#>)
		// Start the path at the placard's current location
		CGPathMoveToPoint(thePath, NULL, x, -10);
		CGPathAddLineToPoint(thePath, NULL, x, midY);
		
		while (stopBouncing != YES) {
			CGPathAddLineToPoint(thePath, NULL, x, midY + originalOffsetY/offsetDivider);
			CGPathAddLineToPoint(thePath, NULL, x, midY);
			
			offsetDivider += 4;
			animationDuration += 1/offsetDivider;
			if (abs(originalOffsetY/offsetDivider) < 6) {
				stopBouncing = YES;
			}
		}
			
		bounceAnimation.path = thePath;
		bounceAnimation.duration = animationDuration;
		bounceAnimation.delegate = self;
		
				
		// Add the animation group to the layer
		[welcomeLayer addAnimation:bounceAnimation forKey:@"animatePlacardViewToCenter"];
		
		// Set the placard view's center and transformation to the original values in preparation for the end of the animation
		//placardView.center = self.center;
		//placardView.transform = CGAffineTransformIdentity;*/
	}
}


- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	NSLog(@"Animation done");
}


- (void) hideLabel
{
	if (![self.label isHidden]) {
		// Using removeFromSuperlayer will animate hiding the label, whereas setHidden is not animated
		[[self.label layer] removeFromSuperlayer];
		[self.label setHidden:YES];
	}
}

- (void) dealloc 
{
    self.data = nil;
    self.label = nil;
    self.textForegroundColor = nil;
    self.textBackgroundColor = nil;
	[super dealloc];
}

- (void)zoomByFactor: (float) zoomFactor near:(CGPoint) center
{
	if(enableDragging){
		self.position = RMScaleCGPointAboutPoint(self.position, zoomFactor, center);
	}
}

- (void)moveBy: (CGSize) delta
{
	if(enableDragging){
		[super moveBy:delta];
	}
}

@end
