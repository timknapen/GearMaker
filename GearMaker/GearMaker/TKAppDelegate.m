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
@synthesize pitch,  pressureAngle,
rackClearance, rackTeeth,
gearTeeth, gearClearance, gearHoleDiam, gearUnderCut,
scale, rotation;

- (void)awakeFromNib{
	self.pitch = 8;
	self.pressureAngle = 20;
	
	self.rackTeeth = 10;
	self.rackClearance = 0;

	self.gearTeeth = 11;
	self.gearClearance = 0;
	self.gearHoleDiam = 5;
	self.gearUnderCut = 0;

	self.scale = 4;
	self.rotation = 0;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}

- (IBAction)regenerate:(id)sender {
	[self.gearView setNeedsDisplay:YES];
}

@end
