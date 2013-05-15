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
	self.scale = self.scale * 2;
	[gearView setNeedsDisplay:YES];
}

- (IBAction)zoomOut:(id)sender {
	self.scale = self.scale/2;
	[gearView setNeedsDisplay:YES];
}

- (void)zoomNormal:(id)sender{
	self.scale = 1;
	gearView.centerp = NSMakePoint(0, 0);
	[gearView setNeedsDisplay:YES];
}
@end
