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
@property (strong) NSTextView * distanceView;
@property (strong) NSTextView * dimensionView;
@property (strong) NSTextView * pitchRadiusView;
@property (strong) NSTextView * pitchRadiusBView;

@property (strong) NSTextView * rackInfoView;
@property (strong) NSBezierPath * gearPathA;
@property (strong) NSBezierPath * gearPathB;
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
- (IBAction)updateAll:(id)sender;
- (IBAction)updateGearA:(id)sender;
- (IBAction)updateGearB:(id)sender;
- (IBAction)updateRack:(id)sender;



@end
