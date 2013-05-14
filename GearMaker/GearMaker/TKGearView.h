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
@property (strong)	NSTextView * dimensionView;
@property (strong) NSTextView * pitchRadiusView;


- (NSBezierPath *) involuteRackWithTeeth:(int)numTeeth
								   pitch:(float)circularPitch
						   pressureAngle:(float)pressureAngle
							   clearance:(float)clearance;

- (NSBezierPath *) involuteGearWithTeeth:(int)numTeeth
						   circularPitch:(float)circularPitch
						   pressureAngle:(float)pressureAngle
							   clearance:(float)clearance;

@end
