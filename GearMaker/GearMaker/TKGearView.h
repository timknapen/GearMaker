//
//  TKGearView.h
//  GearMaker
//
//  Created by timknapen on 13/05/13.
//  Copyright (c) 2013 timknapen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TKGearView : NSView
{
}
@property NSPoint centerp;
@property (strong) NSTextView * dimensionView;
@property (strong) NSTextView * pitchRadiusView;
@property (strong) NSTextView * rackInfoView;
@property (strong) NSBezierPath * gearPath;
@property (strong) NSBezierPath * rackPath;

- (NSBezierPath *) involuteRackWithTeeth:(int)numTeeth
								   pitch:(float)circularPitch
						   pressureAngle:(float)pressureAngle
							   clearance:(float)clearance
								  fillet:(float)fillet;


- (NSBezierPath *) involuteGearWithTeeth:(int)numTeeth
						   circularPitch:(float)circularPitch
						   pressureAngle:(float)pressureAngle
							   clearance:(float)clearance
						   underCutAngle:(float)underCutAngle
								  fillet:(float)fillet;

- (IBAction)updateView:(id)sender;
- (IBAction)updateBoth:(id)sender;
- (IBAction)updateGear:(id)sender;
- (IBAction)updateRack:(id)sender;

@end
