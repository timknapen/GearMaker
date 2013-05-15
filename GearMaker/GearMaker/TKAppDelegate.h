//
//  TKAppDelegate.h
//  GearMaker
//
//  Created by timknapen on 13/05/13.
//  Copyright (c) 2013 timknapen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TKGearView.h"
@interface TKAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet TKGearView *gearView;


// GENERAL
@property float pitch;
@property float pressureAngle;
@property float fillet;

// RACK
@property int rackTeeth;
@property float rackClearance;

// GEAR
@property int gearTeeth;
@property float	gearClearance;
@property float gearHoleDiam;
@property float gearUnderCut;


// interface
@property float scale;
@property float rotation;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)zoomNormal:(id)sender;

@end
