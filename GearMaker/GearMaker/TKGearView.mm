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

void reducePoints( std::vector<ofxVec2f> *pts, float minDist){
	// remove points that are not far enough from each other
	float mDist = minDist * minDist;
	
	if(pts->size() < 2) return;
	
	std::vector < ofxVec2f > newpts;
	newpts.push_back(pts->at(0));
	
	ofxVec2f lastPt = newpts[0];
	for (int i = 1; i < pts->size(); i++) {
		if( ((pts->at(i).x -  lastPt.x) * (pts->at(i).x -  lastPt.x)
			 + (pts->at(i).y -  lastPt.y) * (pts->at(i).y -  lastPt.y)) > mDist){
			newpts.push_back(pts->at(i));
			lastPt = newpts.at(newpts.size()-1);
		}
	}
	
	// swap the vectors
	pts->clear();
	*pts = newpts;
	
}

void applyfillet( std::vector <ofxVec2f> *pts, float fillet){
	
	if(fillet < 0.1f) return;
	float precision = 1000.0f; // scale the values for better precision
	
	Clipper clipper;
	Paths subj(1), solution(1), result(1);
	
	for(int i = 0; i < pts->size(); i++){
		subj[0].push_back(IntPoint(precision*(*pts)[i].x, precision*(*pts)[i].y));
	}
	
	pts->clear();
	
    
	clipper.AddPaths(subj, ptSubject, true);
	if(!Orientation(subj[0])){
		ReversePath(subj[0]);
	}
	
	
	
	// Join types:  jtRound,  jtMiter, jtSquare
	// void OffsetPolygons( in_polys, out_polys, delta,  jointype, MiterLimit, AutoFix)
	
    
    /*
     
     void AddPath(const Path& path, JoinType joinType, EndType endType);
     void AddPaths(const Paths& paths, JoinType joinType, EndType endType);
     void Execute(Paths& solution, double delta);
     
     */
    ClipperOffset clipperOffset;
    
    // inside fillet
    clipperOffset.AddPaths(subj, jtSquare, etClosedPolygon); // add the paths
    clipperOffset.Execute(solution, fillet*precision);
    clipperOffset.Clear();
    clipperOffset.AddPaths(solution, jtRound, etClosedPolygon);
    clipperOffset.Execute(subj, -fillet*precision);
    
    CleanPolygons(subj);

    // outside fillet
    clipperOffset.Clear();
    clipperOffset.AddPaths(subj, jtSquare, etClosedPolygon); // add the paths
    clipperOffset.Execute(solution, -fillet*precision);
    clipperOffset.Clear();
    clipperOffset.AddPaths(solution, jtRound, etClosedPolygon);
    clipperOffset.Execute(subj, fillet*precision);
    
    CleanPolygons(subj);

    
    /* 
    //OLD VERSION :
    // inside fillet
	OffsetPaths(subj, solution, fillet*precision, jtSquare, 0.0f, false);
	OffsetPaths(solution, subj, -fillet*precision, jtRound, 0.0f, false);
	
	// outside fillet
	OffsetPaths(subj, solution, -fillet*precision, jtSquare, 0.0f, false);
	OffsetPaths(solution, subj, fillet*precision, jtRound, 0.0f, false);
	*/
	
	
	// remove too many points
	// CleanPolygons(subj, result); //, 0.002f*precision); //<<< IS BUGGY, DO IT MYSELF!!
	
	result = subj;
	
	for (int s = 0;  s < result.size(); s++) {
		for (int i =0; i < result[s].size(); i++) {
			pts->push_back( ofxVec2f((float)result[s][i].X/precision, (float)result[s][i].Y/precision));
		}
	}
	
	reducePoints(pts, 0.01f); // 0.01 mm

}


@implementation TKGearView
@synthesize centerp;
@synthesize dimensionView, distanceView, pitchRadiusView, pitchRadiusBView, rackInfoView, gearPathA, gearPathB, rackPath;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
	
    if (self) {
		
		self.distanceView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, 10)];
		[distanceView setFont:[NSFont systemFontOfSize:11]];
		[distanceView setSelectable:NO];
		[distanceView setDrawsBackground:NO];
		[distanceView setTextColor:[NSColor  colorWithCalibratedRed:0 green:0 blue:0 alpha:.5f]];
		
		self.dimensionView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 1, 100, 10)];
		[dimensionView setFont:[NSFont systemFontOfSize:11]];
		[dimensionView setSelectable:NO];
		[dimensionView setDrawsBackground:NO];
		[dimensionView setTextColor:[NSColor  colorWithCalibratedRed:0 green:0 blue:0 alpha:.5f]];
		[dimensionView setString: @"10mm"];
		[dimensionView setHidden:YES];
		
		self.pitchRadiusView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, 10)];
		[pitchRadiusView setFont:[NSFont systemFontOfSize:11]];
		[pitchRadiusView setSelectable:NO];
		[pitchRadiusView setDrawsBackground:NO];
		[pitchRadiusView setTextColor:[NSColor  colorWithCalibratedRed:0 green:0 blue:0 alpha:.5f]];
		
		
		self.pitchRadiusBView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, 10)];
		[pitchRadiusBView setFont:[NSFont systemFontOfSize:11]];
		[pitchRadiusBView setSelectable:NO];
		[pitchRadiusBView setDrawsBackground:NO];
		[pitchRadiusBView setTextColor:[NSColor  colorWithCalibratedRed:0 green:0 blue:0 alpha:.5f]];
		
		self.rackInfoView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, 10)];
		[rackInfoView setFont:[NSFont systemFontOfSize:11]];
		[rackInfoView setSelectable:NO];
		[rackInfoView setDrawsBackground:NO];
		[rackInfoView setTextColor:[NSColor  colorWithCalibratedRed:0 green:0 blue:0 alpha:.5f]];
		
		[self addSubview:distanceView];
		[self addSubview:dimensionView];
		[self addSubview:pitchRadiusView];
		[self addSubview:pitchRadiusBView];

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
	appDel.fillet = 0.0f;
	
	appDel.rackTeeth = 5;
	appDel.rackClearance = 0;
	
	appDel.gearATeeth = 11;
	appDel.gearAClearance = 0;
	appDel.gearAHoleDiam = 5;
	appDel.gearAUndercut = 0;
	appDel.gearBTeeth = 11;
	appDel.gearBClearance = 0;
	appDel.gearBHoleDiam = 5;
	appDel.gearBUndercut = 0;
	
	appDel.scale = 4;
	appDel.rotation = 0;
	[self updateAll:nil];
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
	float pitchRadiusA = appDel.gearATeeth * circularPitch  / (2.0 * M_PI);
	float pitchRadiusB =  appDel.gearBTeeth * circularPitch  / (2.0 * M_PI);
	[pitchRadiusView setString: [NSString stringWithFormat:@"Circular pitch\n%.2fmm\n\nPitch radius\n%.2fmm",circularPitch, pitchRadiusA]];
	[pitchRadiusView setFrameOrigin: NSMakePoint( self.frame.size.width/2 + centerp.x + pitchRadiusA * fscale,
												  self.frame.size.height/2 + centerp.y + fscale * pitchRadiusA / 2 - pitchRadiusView.frame.size.height/2 )];
	
	[pitchRadiusBView setString: [NSString stringWithFormat:@"Pitch radius\n%.2fmm", pitchRadiusB]];
	[pitchRadiusBView setFrameOrigin: NSMakePoint( self.frame.size.width/2 + centerp.x + ( pitchRadiusB  ) * fscale,
												 self.frame.size.height/2 + centerp.y + fscale * (pitchRadiusA + pitchRadiusB / 2) - pitchRadiusBView.frame.size.height/2 )];
	
	
	// move the rack along with the gear rotation
	NSAffineTransform * motion = [NSAffineTransform transform];
	[motion translateXBy: -((appDel.rackTeeth - 0.75f) * appDel.pitch) + pitchRadiusA* (M_PI * appDel.rotation/ 180.0f)
					 yBy:-pitchRadiusA];
	
	[rackInfoView setString:[NSString stringWithFormat:@"Rack width\n%.2fmm", appDel.rackTeeth * appDel.pitch]];
	[rackInfoView setFrameOrigin: NSMakePoint( self.frame.size.width/2
											  + fscale * ( 0.75f*appDel.pitch + pitchRadiusA * (M_PI * appDel.rotation/ 180.0f))+centerp.x,
											  self.frame.size.height/2 - fscale*pitchRadiusA + centerp.y - 22)];
	
	[distanceView setString:[NSString stringWithFormat:@"Distance\n%.2fmm", pitchRadiusA + pitchRadiusB]];
	[distanceView setFrameOrigin:NSMakePoint(centerp.x + self.frame.size.width/2 + fscale * 3,
											centerp.y + self.frame.size.height/2 + fscale * (pitchRadiusB +pitchRadiusA))];
	NSAffineTransform * translation = [NSAffineTransform transform];
	[translation translateXBy:self.frame.size.width/2 yBy:self.frame.size.height/2];
	[translation translateXBy:self.centerp.x yBy:self.centerp.y];
	
	// rotate the gear
	NSAffineTransform * rotation = [NSAffineTransform transform];
	[rotation rotateByDegrees:appDel.rotation];
	NSAffineTransform * rotationB = [NSAffineTransform transform];
	[rotationB rotateByDegrees:-((appDel.rotation  * pitchRadiusA) / pitchRadiusB )];
	if(appDel.gearATeeth % 2 == 0){
		// EVEN number of teeth => half a pitch angle added!
		[rotationB rotateByDegrees:-(((360.0f/(2.0f*(float)appDel.gearATeeth))  * pitchRadiusA) / pitchRadiusB )];
	}
	
	// pitch line
	NSBezierPath * pitchLine = [NSBezierPath bezierPath];
	[pitchLine moveToPoint:NSMakePoint(-pitchRadiusB, 0)];
	[pitchLine lineToPoint:NSMakePoint(pitchRadiusB, 0)];
	NSAffineTransform * pressureAngleRot = [NSAffineTransform transform];
	[pressureAngleRot translateXBy:0 yBy:pitchRadiusA];
	[pressureAngleRot rotateByDegrees:appDel.pressureAngle];
	[pitchLine transformUsingAffineTransform:pressureAngleRot];
	 
	
	// reference sizes
	NSBezierPath * pitchCircle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-pitchRadiusA,
																				   -pitchRadiusA,
																				   2*pitchRadiusA,
																				   2*pitchRadiusA)];

	// show pitch
	[pitchCircle moveToPoint:NSMakePoint(pitchRadiusA - .5f, 0)];
	[pitchCircle lineToPoint:NSMakePoint(pitchRadiusA + .5f, 0)];
	[pitchCircle moveToPoint:NSMakePoint(pitchRadiusA , 0)];
	[pitchCircle lineToPoint:NSMakePoint(pitchRadiusA , pitchRadiusA)];
	[pitchCircle moveToPoint:NSMakePoint(pitchRadiusA - .5f, pitchRadiusA)];
	[pitchCircle lineToPoint:NSMakePoint(pitchRadiusA + .5f, pitchRadiusA)];
	
	// center A
	[pitchCircle moveToPoint:NSMakePoint(0, -.5f)];
	[pitchCircle lineToPoint:NSMakePoint(0, .5f)];
	[pitchCircle moveToPoint:NSMakePoint( -.5f, 0)];
	[pitchCircle lineToPoint:NSMakePoint( .5f, 0)];
	
	// show distance
	[pitchCircle moveToPoint:NSMakePoint( 2 - .5f, 0)];
	[pitchCircle lineToPoint:NSMakePoint( 2 + .5f, 0)];
	[pitchCircle lineToPoint:NSMakePoint( 2, 0)];
	[pitchCircle lineToPoint:NSMakePoint( 2, pitchRadiusA + pitchRadiusB )];
	[pitchCircle lineToPoint:NSMakePoint( 2 - .5f, pitchRadiusA + pitchRadiusB )];
	[pitchCircle lineToPoint:NSMakePoint( 2 + .5f, pitchRadiusA + pitchRadiusB )];

	// gear B
	[pitchCircle appendBezierPathWithOvalInRect:NSMakeRect(-pitchRadiusB,
														   pitchRadiusA + pitchRadiusB -pitchRadiusB,
														   2*pitchRadiusB,
														   2*pitchRadiusB)];
	[pitchCircle moveToPoint:NSMakePoint(0, pitchRadiusA + pitchRadiusB - .5f)];
	[pitchCircle lineToPoint:NSMakePoint(0, pitchRadiusA + pitchRadiusB + .5f)];
	[pitchCircle moveToPoint:NSMakePoint( -.5f, pitchRadiusA + pitchRadiusB)];
	[pitchCircle lineToPoint:NSMakePoint( .5f, pitchRadiusA + pitchRadiusB)];
	[pitchCircle moveToPoint:NSMakePoint(pitchRadiusB - .5f, pitchRadiusA + pitchRadiusB)];
	[pitchCircle lineToPoint:NSMakePoint(pitchRadiusB + .5f, pitchRadiusA + pitchRadiusB)];
	[pitchCircle moveToPoint:NSMakePoint(pitchRadiusB , pitchRadiusA + pitchRadiusB)];
	[pitchCircle lineToPoint:NSMakePoint(pitchRadiusB , pitchRadiusA  )];
	[pitchCircle moveToPoint:NSMakePoint(pitchRadiusB - .5f, pitchRadiusA)];
	[pitchCircle lineToPoint:NSMakePoint(pitchRadiusB + .5f, pitchRadiusA)];
	[pitchCircle appendBezierPath:pitchLine];
	[pitchCircle transformUsingAffineTransform:scaler];
	[pitchCircle transformUsingAffineTransform:translation];
	[pitchCircle setLineWidth:0.5f];
	
	NSBezierPath * rackInfo = [NSBezierPath bezierPath];
	[rackInfo moveToPoint:NSMakePoint(0, -.5f)];
	[rackInfo lineToPoint:NSMakePoint(0, .5f)];
	[rackInfo moveToPoint:NSMakePoint(0, 0)];
	[rackInfo lineToPoint:NSMakePoint(appDel.rackTeeth * appDel.pitch, 0)];
	[rackInfo moveToPoint:NSMakePoint(appDel.rackTeeth * appDel.pitch, -.5f)];
	[rackInfo lineToPoint:NSMakePoint(appDel.rackTeeth * appDel.pitch, .5f)];
	[rackInfo setLineWidth:0.5f];
	
	// create a gear
	NSBezierPath * gearA = [NSBezierPath bezierPath];
	[gearA appendBezierPath:self.gearPathA];
	
	[gearA transformUsingAffineTransform:rotation];
	[gearA transformUsingAffineTransform:scaler];
	[gearA transformUsingAffineTransform:translation];
	
	// create a second gear
	NSBezierPath * gearB = [NSBezierPath bezierPath];
	[gearB appendBezierPath:self.gearPathB];
	[gearB transformUsingAffineTransform:rotationB];
	NSAffineTransform * translationGearB = [NSAffineTransform transform];
	[translationGearB translateXBy:0 yBy:pitchRadiusB + pitchRadiusA];
	[gearB transformUsingAffineTransform:translationGearB];
	[gearB transformUsingAffineTransform:scaler];
	[gearB transformUsingAffineTransform:translation];
	
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
	[[NSColor colorWithCalibratedRed:1 green:.2f blue:.2f alpha:.7f] set];
	[gearA fill];
	
	[[NSColor colorWithCalibratedRed:0 green:.0f blue:1 alpha:.7f] set];
	[gearB fill];
	
	[[NSColor colorWithCalibratedRed:0 green:.6f blue:0 alpha:.7f] set];
	[rack fill];
	
	if([[NSGraphicsContext currentContext] isDrawingToScreen]){
		// SCREEN
		[[NSColor  colorWithCalibratedRed:0 green:0 blue:0 alpha:.5f] set];
		[pitchCircle stroke];
		[rackInfo stroke];
		
	}else{
		
		// PRINT
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

-(void)updateAll:(id)sender{
	[self updateGearA:nil];
	[self updateGearB:nil];
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
	pts.push_back(ofxVec2f(0, -7 )); // bottom of the rack
	
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
	
	pt = ofxVec2f( pt.x, -7 ); // bottom of the rack
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


-(void)updateGearA:(id)sender{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	NSBezierPath * gear = [self involuteGearWithTeeth:appDel.gearATeeth
								   circularPitch:appDel.pitch
								   pressureAngle:appDel.pressureAngle
									   clearance:appDel.gearAClearance
								   underCutAngle:appDel.gearAUndercut
										  fillet:appDel.fillet];
	// create the hole
	NSBezierPath * holePath = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-appDel.gearAHoleDiam/2,
																				-appDel.gearAHoleDiam/2,
																				appDel.gearAHoleDiam,
																				appDel.gearAHoleDiam)];
	holePath = [holePath bezierPathByReversingPath];
	[gear appendBezierPath:holePath];
	
	self.gearPathA = gear;
	
	[self setNeedsDisplay:YES];
}

-(void)updateGearB:(id)sender{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	NSBezierPath * gear = [self involuteGearWithTeeth:appDel.gearBTeeth
								   circularPitch:appDel.pitch
								   pressureAngle:appDel.pressureAngle
									   clearance:appDel.gearBClearance
								   underCutAngle:appDel.gearBUndercut
										  fillet:appDel.fillet];
	// create the hole
	NSBezierPath * holePath = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-appDel.gearBHoleDiam/2,
																				-appDel.gearBHoleDiam/2,
																				appDel.gearBHoleDiam,
																				appDel.gearBHoleDiam)];
	holePath = [holePath bezierPathByReversingPath];
	[gear appendBezierPath:holePath];
	
	self.gearPathB = gear;
	
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
	NSPoint pt = self.centerp;
	self.centerp = NSMakePoint(0, 0);
	[dimensionView setHidden:NO];
	
	[super print:sender];
	
	// SET BACK
	self.centerp = pt;
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
	[appDel scaleView: scaleDif];
}

- (void)rotateWithEvent:(NSEvent *)event{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	appDel.rotation += [event rotation];
	[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent{
	centerp.x += [theEvent deltaX];
	centerp.y -= [theEvent deltaY];
	[self setNeedsDisplay:YES];
}

- (BOOL)canBecomeKeyView{
	return YES;
}

@end
