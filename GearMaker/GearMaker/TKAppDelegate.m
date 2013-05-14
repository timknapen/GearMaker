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
@synthesize pitch, rackClearance, pressureAngle, rackTeeth, gearTeeth, gearClearance, gearHoleDiam, scale, rotation;

- (void)awakeFromNib{
	self.pitch = 8;
	self.pressureAngle = 20;
	self.rackClearance = 5;
	self.gearTeeth = 11;
	self.rackTeeth = 10;
	self.gearClearance = 0;
	self.rackClearance = 0;
	self.gearHoleDiam = 5;
	self.scale = 2;
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
