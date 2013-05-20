//
//  TKAppDelegate.m
//  GearMaker
//
//  Created by timknapen on 13/05/13.
//  Copyright (c) 2013 timknapen. All rights reserved.
//

#import "TKAppDelegate.h"

@implementation TKAppDelegate
@synthesize window;
@synthesize gearView;
@synthesize pitch,  pressureAngle, fillet,
rackClearance, rackTeeth,
gearATeeth, gearAClearance, gearAHoleDiam, gearAUndercut,
gearBTeeth, gearBClearance, gearBHoleDiam, gearBUndercut,
scale, rotation;

- (void)awakeFromNib{
	[window  setExcludedFromWindowsMenu:YES];
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

- (IBAction)saveToSVG:(id)sender {
	
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"svg"]];
	[savePanel setTitle:@"Save to SVG"];
	if([savePanel runModal] == NSFileHandlingPanelOKButton){
		NSMutableString * svgString = [[NSMutableString alloc] initWithString:@"<?xml version=\"1.0\" encoding=\"utf-8\" ?> \
									   <!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\" \"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\">"];
		
		[svgString appendFormat:@" <svg version=\"1.0\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" width=\"%.3fpx\" height=\"%.3fpx\" viewBox=\"0 0 %.3f %.3f\" >",
		 210.0 * POINT_TO_MM,
		 297.0 * POINT_TO_MM,
		 210.0 * POINT_TO_MM,
		 297.0 * POINT_TO_MM];
		
		
		
		NSAffineTransform * scaleToMM = [NSAffineTransform transform];
		[scaleToMM scaleXBy:POINT_TO_MM yBy:-POINT_TO_MM]; // flipped Y axis!
		
		NSAffineTransform * center = [NSAffineTransform transform];
		[center translateXBy:210.0/2 yBy: -297.0/2 ]; // flipped Y axis!
		
		NSAffineTransform * gearBPosition = [NSAffineTransform transform];
		// calculate gearRadius
		float circularPitch = pitch;
		float pitchRadiusA = gearATeeth * circularPitch  / (2.0 * M_PI);
		float pitchRadiusB = gearBTeeth * circularPitch  / (2.0 * M_PI);
		[gearBPosition translateXBy:0 yBy:pitchRadiusA + pitchRadiusB];
		
		NSAffineTransform * gearBRotation = [NSAffineTransform transform];
		if(gearATeeth % 2 == 0){
			// EVEN number of teeth => half a pitch angle added!
			[gearBRotation rotateByDegrees:-(((360.0f/(2.0f*(float)gearATeeth))  * pitchRadiusA) / pitchRadiusB )];
		}
		
		NSAffineTransform * rackPosition = [NSAffineTransform transform];
		[rackPosition translateXBy: - rackTeeth * circularPitch +  0.75f * pitch yBy:-pitchRadiusA];
		
		// add a reference square of 10 x 10mm
		NSBezierPath * refSquare = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 10, -10)]; // flipped Y axis
		[refSquare transformUsingAffineTransform:scaleToMM];
		
		// to mark the center of the gear
		NSBezierPath * crossHair = [NSBezierPath bezierPath];
		[crossHair moveToPoint:NSMakePoint(-.5, 0)];
		[crossHair lineToPoint:NSMakePoint(.5, 0)];
		[crossHair moveToPoint:NSMakePoint(0, -.5)];
		[crossHair lineToPoint:NSMakePoint(0, .5)];
		
		NSBezierPath * gearA = [NSBezierPath bezierPath];
		[gearA appendBezierPath:[gearView gearPathA]];
		[gearA transformUsingAffineTransform:center];
		[gearA transformUsingAffineTransform:scaleToMM];
		
		NSBezierPath * gearACenter = [NSBezierPath bezierPath];
		[gearACenter appendBezierPath:crossHair];
		[gearACenter transformUsingAffineTransform:center];
		[gearACenter transformUsingAffineTransform:scaleToMM];
		
		NSBezierPath * gearB =  [NSBezierPath bezierPath];
		[gearB appendBezierPath:[gearView gearPathB]];
		[gearB transformUsingAffineTransform:gearBRotation];
		[gearB transformUsingAffineTransform:center];
		[gearB transformUsingAffineTransform:gearBPosition];
		[gearB transformUsingAffineTransform:scaleToMM];
		
		NSBezierPath * gearBCenter = [NSBezierPath bezierPath];
		[gearBCenter appendBezierPath:crossHair];
		[gearBCenter transformUsingAffineTransform:gearBRotation];
		[gearBCenter transformUsingAffineTransform:center];
		[gearBCenter transformUsingAffineTransform:gearBPosition];
		[gearBCenter transformUsingAffineTransform:scaleToMM];
		
		NSBezierPath * rack =  [NSBezierPath bezierPath];
		[rack appendBezierPath:[gearView rackPath]];
		[rack transformUsingAffineTransform:center];
		[rack transformUsingAffineTransform:rackPosition];
		[rack transformUsingAffineTransform:scaleToMM];
		
		
		[svgString appendString:[self createSVGPathFromPath:refSquare
												  fillColor:@"none"
												strokeColor:@"#0000FF"
												strokeWidth:0.1f]];
		
		[svgString appendString:[self createSVGPathFromPath:gearA
												  fillColor:@"#FF6666"
												strokeColor:@"none"]];
		[svgString appendString:[self createSVGPathFromPath:gearACenter
												  fillColor:@"none"
												strokeColor:@"#FF6666"
												strokeWidth:0.1f]];
		
		[svgString appendString:[self createSVGPathFromPath:gearB
												  fillColor:@"#3333FF"
												strokeColor:@"none"]];
		[svgString appendString:[self createSVGPathFromPath:gearBCenter
												  fillColor:@"none"
												strokeColor:@"#3333FF"
												strokeWidth:0.1f]];
		
		[svgString appendString:[self createSVGPathFromPath:rack
												  fillColor:@"#66CC66"
												strokeColor:@"none"]];
		
		// add text info
		[svgString appendString:@"<text fill=\"gray\" font-size=\"8\">"];
		[svgString appendFormat:@"<tspan x=\"0\" y=\"%.3f\">Circular pitch = %.2fmm</tspan>", 20 * POINT_TO_MM, pitch];
		[svgString appendFormat:@"<tspan x=\"0\" dy=\"1.2em\">Pressure Angle = %.2f°</tspan>",  pressureAngle];
		[svgString appendFormat:@"<tspan x=\"0\" dy=\"1.2em\">Fillet (rounding) = %.2fmm</tspan>", fillet];
		[svgString appendFormat:@"<tspan x=\"0\" dy=\"1.2em\">Blue Gear: Teeth = %d, Pitch Radius = %.2fmm</tspan>", gearBTeeth, pitchRadiusB];
		[svgString appendFormat:@"<tspan x=\"0\" dy=\"1.2em\">Red Gear: Teeth = %d, Pitch Radius = %.2fmm</tspan>", gearATeeth, pitchRadiusA];
		[svgString appendFormat:@"<tspan x=\"0\" dy=\"1.2em\">Rack: Teeth = %d, Width = %.2fmm</tspan>", rackTeeth,  rackTeeth * circularPitch];
		[svgString appendString:@"</text>"];
		
		// text for reference square
		[svgString appendString:@"<text fill=\"blue\" font-size=\"8\">"];
		[svgString appendString:@"<tspan x=\"2\" y=\"1.2em\">10mm</tspan>"];
		[svgString appendString:@"</text>"];
		
		[svgString appendString:@"</svg>"];
		[svgString writeToURL:[savePanel URL] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	}
	
	
}

- (NSString *)createSVGPathFromPath:(NSBezierPath *)path
						  fillColor:(NSString *)fill
						strokeColor:(NSString *)stroke{
	return [self createSVGPathFromPath:path
							 fillColor:fill
						   strokeColor:stroke
						   strokeWidth:0.0f];
}

- (NSString *)createSVGPathFromPath:(NSBezierPath *)path
						  fillColor:(NSString *) fill
						strokeColor:(NSString *) stroke
						strokeWidth:(float) strokeWidth
{
	
	
	NSMutableString * pathString = [[NSMutableString alloc] init];
	[pathString appendFormat:@"<path fill=\"%@\" stroke=\"%@\" stroke-width=\"%.3f\" d=\"" , fill, stroke, strokeWidth];
	
	NSPoint pts[3];
	pts[0] = pts[1] = pts[2] = NSMakePoint(0, 0);
	pts[1] = NSMakePoint(0, 0);
	pts[2] = NSMakePoint(0, 0);
	NSBezierPathElement el;
	
	for (int i = 0; i < [path elementCount]; i++ ) {
		
		el = [path elementAtIndex:i associatedPoints:pts];
		switch (el) {
			case NSMoveToBezierPathElement:
				[pathString appendFormat:@"M%.3f,%.3f", pts[0].x, pts[0].y];
				break;
			case NSLineToBezierPathElement:
				[pathString appendFormat:@"L%.3f,%.3f", pts[0].x, pts[0].y];
				break;
			case NSCurveToBezierPathElement:
				[pathString appendFormat:@"C%.3f,%.3f,%.3f,%.3f,%.3f,%.3f", pts[0].x, pts[0].y, pts[1].x, pts[1].y, pts[2].x, pts[2].y];
				break;
			case NSClosePathBezierPathElement:
				[pathString appendFormat:@"Z"];
				break;
			default: // should never happen
				NSLog(@"mysterious path element? %ld", el);
				break;
		}
	}
	// close path tag
	[pathString appendString:@"\"/>"];
	
	return pathString;
	
}


@end
