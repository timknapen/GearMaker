//
//  TKAppDelegate.m
//  GearMaker
//
//  Created by timknapen on 13/05/13.
//  Copyright (c) 2013 timknapen. All rights reserved.
//

#import "TKAppDelegate.h"

@implementation TKAppDelegate
@synthesize gearView;
@synthesize pitch,  pressureAngle, fillet,
rackClearance, rackTeeth,
gearTeeth, gearClearance, gearHoleDiam, gearUnderCut,
scale, rotation;

- (void)awakeFromNib{
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}


- (IBAction)zoomIn:(id)sender {
	float scaleDif = 2.0f;
	[self scaleView:scaleDif];
}

- (IBAction)zoomOut:(id)sender {
	float scaleDif = 0.5f;
	[self scaleView:scaleDif];
}

- (void)zoomNormal:(id)sender{
	self.scale = 1;
	gearView.centerp = NSMakePoint(0, 0);
	[gearView setNeedsDisplay:YES];
}

- (void)scaleView:(float)scaleDif{
	self.scale = self.scale * scaleDif;
	float x = gearView.centerp.x;
	float y = gearView.centerp.y;
	
	// distance from middle of the frame gets scaled
	// centerp IS a distance from the middle of the frame
	x *= scaleDif;
	y *= scaleDif;
	
	gearView.centerp = NSMakePoint(x, y);
	[gearView setNeedsDisplay:YES];
}


@end
