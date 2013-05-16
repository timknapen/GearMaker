//
//  TKGearView.m
//  GearMaker
//
//  Created by timknapen on 13/05/13.
//  Copyright (c) 2013 timknapen. All rights reserved.
//

#import "TKGearView.h"
#import "TKAppDelegate.h"
#import "ofxVec2f.h"
#import <vector>
#include <algorithm>    // std::reverse
#include "clipper.hpp"
using namespace ClipperLib;


void applyfillet( std::vector <ofxVec2f> *pts, float fillet){
	
	
	float precision = 1000.0f; // scale the values for better precision
	
	Clipper clipper;
	Polygons subj(1), solution(1), result(1);
	
	for(int i = 0; i < pts->size(); i++){
		subj[0].push_back(IntPoint(precision*(*pts)[i].x, precision*(*pts)[i].y));
	}
	
	pts->clear();
	
	
	clipper.AddPolygons(subj, ptSubject);
	if(!Orientation(subj[0])){
		ReversePolygon(subj[0]);
	}

	if(fillet > 0.0f){
		
		// Join types:  jtRound,  jtMiter, jtSquare
		// void OffsetPolygons( in_polys, out_polys, delta,  jointype, MiterLimit, AutoFix)
		
		// inside fillet
		OffsetPolygons(subj, solution, fillet*precision, jtSquare, 0.0f, false);
		OffsetPolygons(solution, subj, -fillet*precision, jtRound, 0.0f, false);
		
		// outside fillet
		OffsetPolygons(subj, solution, -fillet*precision, jtSquare, 0.0f, false);
		OffsetPolygons(solution, solution, fillet*precision, jtRound, 0.0f, false);
		
	}else{
		solution = subj;
	}
	
	// remove too many points
	CleanPolygons(solution, result, 0.001f*precision);
	
	
	for (int s = 0;  s < result.size(); s++) {
		for (int i =0; i < result[s].size(); i++) {
			pts->push_back( ofxVec2f((float)result[s][i].X/precision, (float)result[s][i].Y/precision));
		}
	}
	
}

@implementation TKGearView
@synthesize centerp;
@synthesize dimensionView, pitchRadiusView, rackInfoView, gearPath, rackPath;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
	
    if (self) {
		
		self.dimensionView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 1, 600, 10)];
		[dimensionView setFont:[NSFont systemFontOfSize:11]];
		[dimensionView setSelectable:NO];
		[dimensionView setDrawsBackground:NO];
		[dimensionView setTextColor:[NSColor  colorWithCalibratedRed:0 green:0 blue:1 alpha:.5f]];
		[dimensionView setString: @"10mm"];
		[dimensionView setHidden:YES];
		
		self.pitchRadiusView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 500, 10)];
		[pitchRadiusView setFont:[NSFont systemFontOfSize:11]];
		[pitchRadiusView setSelectable:NO];
		[pitchRadiusView setDrawsBackground:NO];
		[pitchRadiusView setTextColor:[NSColor  colorWithCalibratedRed:0 green:0 blue:1 alpha:.5f]];
		
		self.rackInfoView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 500, 10)];
		[rackInfoView setFont:[NSFont systemFontOfSize:11]];
		[rackInfoView setSelectable:NO];
		[rackInfoView setDrawsBackground:NO];
		[rackInfoView setTextColor:[NSColor  colorWithCalibratedRed:0 green:0 blue:1 alpha:.5f]];
		[self addSubview:dimensionView];
		[self addSubview:pitchRadiusView];
		[self addSubview:rackInfoView];
		centerp = NSMakePoint(0, 0);
		[self setAcceptsTouchEvents:YES];
    }
    
    return self;
}

- (void)awakeFromNib{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	
	appDel.pitch = 5;
	appDel.pressureAngle = 20;
	appDel.fillet = 0.1f;
	
	appDel.rackTeeth = 5;
	appDel.rackClearance = 0;
	
	appDel.gearTeeth = 11;
	appDel.gearClearance = 0;
	appDel.gearHoleDiam = 5;
	appDel.gearUnderCut = 0;
	
	appDel.scale = 4;
	appDel.rotation = 0;
	[self updateBoth:nil];
}


#pragma mark -
#pragma mark DRAWING

- (void)updateView:(id)sender{
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
	
	// fill background
	[[NSColor whiteColor] set];
	NSRectFill(dirtyRect);
	
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	float fscale = appDel.scale * (72.0f / 25.4f);
	// convert window coordinates to mm
	// 1 pixel @ 72dpi => 72pixels/inch =>
	// 1 pixel = inch/72
	// 1 pixel = 25.4 / 72.0 mm
	
	NSAffineTransform * scaler = [NSAffineTransform transform];
	[scaler scaleBy:fscale];
	
	
	// calculate the pitch radius of the gear
	float circularPitch = appDel.pitch;
	float pitchRadius = appDel.gearTeeth * circularPitch  / (2.0 * M_PI);
	[pitchRadiusView setString: [NSString stringWithFormat:@"Circular pitch\n%.2fmm\n\nPitch radius\n%.2fmm",circularPitch, pitchRadius]];
	[pitchRadiusView setFrameOrigin: NSMakePoint( self.frame.size.width/2 + centerp.x + pitchRadius * fscale, self.frame.size.height/2 + centerp.y - pitchRadiusView.frame.size.height/2 )];
	
	
	// move the rack along with the gear rotation
	NSAffineTransform * motion = [NSAffineTransform transform];
	[motion translateXBy: -((appDel.rackTeeth-1-0.75f) * appDel.pitch) + pitchRadius* (M_PI * appDel.rotation/ 180.0f) yBy:-pitchRadius];
	
	[rackInfoView setString:[NSString stringWithFormat:@"Rack width\n%.2fmm", appDel.rackTeeth * appDel.pitch]];
	[rackInfoView setFrameOrigin: NSMakePoint( self.frame.size.width/2
											  + fscale * ( (1+0.75f)*appDel.pitch + pitchRadius * (M_PI * appDel.rotation/ 180.0f))+centerp.x,
											  self.frame.size.height/2 - fscale*pitchRadius + centerp.y - 22)];
	
	
	NSAffineTransform * translation = [NSAffineTransform transform];
	[translation translateXBy:self.frame.size.width/2 yBy:self.frame.size.height/2];
	[translation translateXBy:self.centerp.x yBy:self.centerp.y];
	
	// rotate the gear
	NSAffineTransform * rotation = [NSAffineTransform transform];
	[rotation rotateByDegrees:appDel.rotation];
	
	
	// reference sizes
	NSBezierPath * pitchCircle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-pitchRadius, -pitchRadius, 2*pitchRadius, 2*pitchRadius)];
	for(int i = 0; i <= (int)pitchRadius; i++){
		[pitchCircle moveToPoint:NSMakePoint(i, .5)];
		[pitchCircle lineToPoint:NSMakePoint(i, -.5)];
		[pitchCircle moveToPoint:NSMakePoint(-i, .5)];
		[pitchCircle lineToPoint:NSMakePoint(-i, -.5)];
		[pitchCircle moveToPoint:NSMakePoint(.5, i)];
		[pitchCircle lineToPoint:NSMakePoint(-.5, i)];
		[pitchCircle moveToPoint:NSMakePoint(.5, -i)];
		[pitchCircle lineToPoint:NSMakePoint(-.5, -i)];
		if( i % 10 == 0){
			[pitchCircle moveToPoint:NSMakePoint(i, pitchRadius)];
			[pitchCircle lineToPoint:NSMakePoint(i, -pitchRadius)];
			[pitchCircle moveToPoint:NSMakePoint(-i, pitchRadius)];
			[pitchCircle lineToPoint:NSMakePoint(-i, -pitchRadius)];
			[pitchCircle moveToPoint:NSMakePoint(pitchRadius, i)];
			[pitchCircle lineToPoint:NSMakePoint(-pitchRadius, i)];
			[pitchCircle moveToPoint:NSMakePoint(pitchRadius, -i)];
			[pitchCircle lineToPoint:NSMakePoint(-pitchRadius, -i)];
		}
	}
	// show pitch
	[pitchCircle moveToPoint:NSMakePoint(pitchRadius - 1, -circularPitch/2)];
	[pitchCircle lineToPoint:NSMakePoint(pitchRadius + 1, -circularPitch/2)];
	
	[pitchCircle moveToPoint:NSMakePoint(pitchRadius - 1, circularPitch/2)];
	[pitchCircle lineToPoint:NSMakePoint(pitchRadius + 1, circularPitch/2)];
	
	[pitchCircle moveToPoint:NSMakePoint(0, -pitchRadius)];
	[pitchCircle lineToPoint:NSMakePoint(0, pitchRadius)];
	[pitchCircle moveToPoint:NSMakePoint( -pitchRadius, 0)];
	[pitchCircle lineToPoint:NSMakePoint( pitchRadius, 0)];
	
	[pitchCircle transformUsingAffineTransform:scaler];
	[pitchCircle transformUsingAffineTransform:translation];
	[pitchCircle setLineWidth:0.5f];
	
	NSBezierPath * rackInfo = [NSBezierPath bezierPath];
	[rackInfo moveToPoint:NSMakePoint(0, -1)];
	[rackInfo lineToPoint:NSMakePoint(0, 1)];
	[rackInfo moveToPoint:NSMakePoint(0, 0)];
	[rackInfo lineToPoint:NSMakePoint(appDel.rackTeeth * appDel.pitch, 0)];
	[rackInfo moveToPoint:NSMakePoint(appDel.rackTeeth * appDel.pitch, -1)];
	[rackInfo lineToPoint:NSMakePoint(appDel.rackTeeth * appDel.pitch, 1)];
	
	
	// create a gear
	NSBezierPath * gear = [NSBezierPath bezierPath];
	[gear appendBezierPath:self.gearPath];
	
	// create the hole
	NSBezierPath * holePath = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-appDel.gearHoleDiam/2, -appDel.gearHoleDiam/2, appDel.gearHoleDiam, appDel.gearHoleDiam)];
	holePath = [holePath bezierPathByReversingPath];
	
	
	[gear transformUsingAffineTransform:rotation];
	[gear appendBezierPath:holePath];
	[gear transformUsingAffineTransform:scaler];
	[gear transformUsingAffineTransform:translation];
	
	// create the rack
	NSBezierPath * rack = [NSBezierPath bezierPath];
	[rack appendBezierPath:rackPath];
	
	[rack transformUsingAffineTransform:motion];
	[rack transformUsingAffineTransform:scaler];
	[rack transformUsingAffineTransform:translation];
	
	[rackInfo transformUsingAffineTransform:motion];
	[rackInfo transformUsingAffineTransform:scaler];
	[rackInfo transformUsingAffineTransform:translation];
	
	
	
	
	// ACTUAL DRAWING
	[[NSColor  colorWithCalibratedRed:0 green:0 blue:1 alpha:.5f] set];
	[pitchCircle stroke];
	[rackInfo stroke];
	
	[[NSColor colorWithCalibratedRed:1 green:.2f blue:.2f alpha:.7f] set];
	//[gear setLineJoinStyle:NSMiterLineJoinStyle];
	//[gear setMiterLimit:1000];
	[gear fill];
	
	[[NSColor colorWithCalibratedRed:0 green:.6f blue:0 alpha:.7f] set];
	[rack fill];
	
	if(![[NSGraphicsContext currentContext] isDrawingToScreen]){
		NSBezierPath * pageEdges = [NSBezierPath bezierPathWithRect:dirtyRect];
		[[NSColor grayColor] set];
		[pageEdges stroke];
		
		[[NSColor  colorWithCalibratedRed:0 green:0 blue:1 alpha:.5f] set];
		NSBezierPath * refPath = [NSBezierPath bezierPathWithRect:NSMakeRect(1, self.frame.size.height-fscale*10, fscale*10, fscale*10)];
		[dimensionView setFrameOrigin:NSMakePoint(0, self.frame.size.height-12)];
		[refPath stroke];
	}
	
	
}


#pragma mark -
#pragma mark GEARS

-(void)updateBoth:(id)sender{
	[self updateGear:nil];
	[self updateRack:nil];
}

-(void) updateRack:(id)sender{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	self.rackPath = [self involuteRackWithTeeth:appDel.rackTeeth
										  pitch:appDel.pitch
								  pressureAngle:appDel.pressureAngle
									  clearance:appDel.rackClearance
										 fillet:appDel.fillet];
	[self setNeedsDisplay:YES];
}

- (NSBezierPath *)involuteRackWithTeeth:(int)numTeeth
								  pitch:(float)circularPitch
						  pressureAngle:(float)pressureAngle
							  clearance:(float)clearance
								 fillet:(float)fillet
{
	
	NSBezierPath * rack = [NSBezierPath bezierPath];
	
	float addendum = circularPitch / M_PI;
	float dedendum = addendum + clearance;
	ofxVec2f deden(0, -dedendum);
	ofxVec2f adden(0, addendum);
	ofxVec2f pt;
	
	std::vector <ofxVec2f> pts;
	pts.push_back(ofxVec2f(0, -2*dedendum));
	
	for(int i =0; i < numTeeth; i++){
		float xpos = (float)i * circularPitch;
		pt = ofxVec2f( xpos + 0, 0) + deden.getRotated(pressureAngle);
		pts.push_back(pt);
		
		pt = ofxVec2f( xpos + circularPitch/2, 0) + deden.getRotated(-pressureAngle);
		pts.push_back(pt);
		
		
		pt = ofxVec2f( xpos + circularPitch/2, 0) + adden.getRotated(-pressureAngle);
		pts.push_back(pt);
		
		pt = ofxVec2f( xpos + circularPitch, 0) + adden.getRotated(pressureAngle);
		pts.push_back(pt);
	}
	
	pt = ofxVec2f( numTeeth * circularPitch, 0) + deden.getRotated(pressureAngle);
	pts.push_back(pt);
	
	pt = ofxVec2f( pt.x, -2 *dedendum);
	pts.push_back(pt);
	
	applyfillet(&pts, fillet);
	
	
	if(pts.size() > 0){
		[rack moveToPoint:NSMakePoint(pts[0].x, pts[0].y)];
	}
	for(int i = 0; i  < pts.size(); i++){
		[rack lineToPoint:NSMakePoint(pts[i].x, pts[i].y)];
	}
	
	
	[rack closePath];
	
	
	
	return rack;
}


-(void)updateGear:(id)sender{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	self.gearPath  = [self involuteGearWithTeeth:appDel.gearTeeth
								   circularPitch:appDel.pitch
								   pressureAngle:appDel.pressureAngle
									   clearance:appDel.gearClearance
								   underCutAngle:appDel.gearUnderCut
										  fillet:appDel.fillet];
	[self setNeedsDisplay:YES];
}



- (NSBezierPath *)involuteGearWithTeeth:(int)numTeeth
						  circularPitch:(float)circularPitch
						  pressureAngle:(float)pressureAngle
							  clearance:(float)clearance
						  underCutAngle:(float)underCutAngle
								 fillet:(float)fillet
{
	underCutAngle *= DEG_TO_RAD;
	
	float addendum = (float) circularPitch / M_PI;
	float dedendum = addendum + clearance;
	
	// radiuses of the 4 circles:
	float pitchRadius = numTeeth * circularPitch / (2.0 * M_PI);
	float baseRadius = pitchRadius * cos( M_PI * pressureAngle /180.0);
	float outerRadius = pitchRadius + addendum;
	
	float maxtanlength = sqrt(outerRadius*outerRadius - baseRadius*baseRadius);
	float maxangle = maxtanlength / baseRadius;
	
	float tl_at_pitchcircle = sqrt(pitchRadius*pitchRadius - baseRadius*baseRadius);
	float angle_at_pitchcircle = tl_at_pitchcircle / baseRadius;
	float diffangle = angle_at_pitchcircle - atan(angle_at_pitchcircle);
	float angularToothWidthAtBase = M_PI / numTeeth + 2.0 * diffangle;
	
	
	int resolution = 10;
	
	NSBezierPath * gear = [NSBezierPath bezierPath];
	std::vector <ofxVec2f> pts;
	ofxVec2f vec;
	float rot =  M_PI -angularToothWidthAtBase/2;
	vec = ofxVec2f(0, baseRadius - dedendum + 10);
	vec.rotateRad(rot + underCutAngle );
	//pts.push_back(vec);
	
	
	for(int a = 0; a < numTeeth; a++){
		rot = M_PI - angularToothWidthAtBase/2 + (float) a * 2 * M_PI / (float)numTeeth;
		vec = ofxVec2f(0, baseRadius - dedendum);
		vec.rotateRad(rot + underCutAngle);
		pts.push_back(vec);
		
		for(int i = 0; i <= resolution; i++){
			// first side of the teeth:
			float angle = maxangle * (float)i / (float)resolution;
			float tanlength = angle * baseRadius;
			ofxVec2f radvec = ofxVec2f(0,1).getRotatedRad(angle);
			ofxVec2f tanvec = radvec.getPerpendicular() * -1;
			vec = (radvec * baseRadius) + (tanvec * tanlength);
			vec.rotateRad(rot);
			pts.push_back(vec);
		}
		for(int i = resolution ; i >=0; i--){
			// first side of the teeth:
			float angle = maxangle * (float)i / (float)resolution;
			float tanlength = angle * baseRadius;
			ofxVec2f radvec = ofxVec2f(0, 1).getRotatedRad(angularToothWidthAtBase - angle);
			ofxVec2f tanvec =  radvec.getPerpendicular();
			vec = (radvec * baseRadius) + (tanvec * tanlength);
			vec.rotateRad(rot);
			pts.push_back(vec);
		}
		
		
		vec = ofxVec2f(0, baseRadius - dedendum).getRotatedRad(angularToothWidthAtBase);
		vec.rotateRad(rot - underCutAngle);
		pts.push_back(vec);
	}
	
	applyfillet(&pts, fillet);
	
	if(pts.size() >0){
		[gear moveToPoint:NSMakePoint(pts[0].x, pts[0].y)];
	}
	for(int i = 0; i  < pts.size(); i++){
		[gear lineToPoint:NSMakePoint(pts[i].x, pts[i].y)];
	}
	
	[gear closePath];
	return gear;
	
	
}


#pragma mark -
#pragma mark PRINTING

- (void)print:(id)sender{
	
	NSRect oldFrame = self.frame;
	
	// set frame to DIN A4 : 210 mm, 297 mm
	[self setFrame:NSMakeRect(0, 0, 210.0 * 72.0f / 25.4f, 297.0 * 72.0f / 25.4f)];
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	float tscale = appDel.scale;
	float trot = appDel.rotation;
	appDel.scale = 1;
	appDel.rotation = 0;
	
	[dimensionView setHidden:NO];
	
	[super print:sender];
	
	// SET BACK
	
	[self setFrame:oldFrame];
	appDel.scale = tscale;
	appDel.rotation=trot;
	[dimensionView setHidden:YES];
	[self setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark EVENTS


- (void)magnifyWithEvent:(NSEvent *)event{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	float scaleDif = (1.0f + [event magnification]);
	//if( 1.0f + [event magnification] < 1.0f) return;
	[appDel scaleView: scaleDif];
}

- (void)rotateWithEvent:(NSEvent *)event{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	appDel.rotation += [event rotation];
	[self setNeedsDisplay:YES];
}


- (void)scrollWheel:(NSEvent *)theEvent {
	centerp.x += [theEvent deltaX];
	centerp.y -= [theEvent deltaY];
	[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent{
	centerp.x += [theEvent deltaX];
	centerp.y -= [theEvent deltaY];
	[self setNeedsDisplay:YES];
}

@end
