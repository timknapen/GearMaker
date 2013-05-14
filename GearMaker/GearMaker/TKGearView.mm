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

@implementation TKGearView
@synthesize centerp;
@synthesize dimensionView;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		dimensionView = [[NSTextView alloc] initWithFrame:NSMakeRect(2, 2, 200, 10)];
		[dimensionView setFont:[NSFont systemFontOfSize:11]];
		[dimensionView setString:@"10mm x 10mm"];
		[dimensionView setSelectable:NO];
		[dimensionView setDrawsBackground:NO];
		[dimensionView setTextColor:[NSColor blueColor]];
		[self addSubview:dimensionView];
		centerp = NSMakePoint(0, 0);
		[self setAcceptsTouchEvents:YES];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];

	// calculate the outerDiam of the gear
	float pitchRadius = appDel.gearTeeth * appDel.pitch  / (2.0 * M_PI);

	// fill background
	[[NSColor whiteColor] set];
	NSRectFill(dirtyRect);
	
	// rotation translation
	// 360° at base circle = numTeeth * circularPitch
	NSAffineTransform * motion = [NSAffineTransform transform];
	[motion translateXBy: -((appDel.rackTeeth-1-0.75f) * appDel.pitch) + pitchRadius* (M_PI * appDel.rotation/ 180.0f) yBy:-pitchRadius];
	
	// convert window coordinates to mm
	// 1 pixel @ 72dpi => 72pixels/inch =>
	// 1 pixel = inch/72
	// 1 pixel = 25.4 / 72.0 mm
	NSAffineTransform * scaler = [NSAffineTransform transform];
	[scaler scaleBy:appDel.scale];
	[scaler scaleBy: 72.0f / 25.4f];
	
	NSAffineTransform * translation = [NSAffineTransform transform];
	[translation translateXBy:self.frame.size.width/2 yBy:self.frame.size.height/2];
	[translation translateXBy:self.centerp.x yBy:self.centerp.y];
	
	
	NSAffineTransform * rotation = [NSAffineTransform transform];
	[rotation rotateByDegrees:appDel.rotation];
	
	NSBezierPath * pitchCircle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-pitchRadius, -pitchRadius, 2*pitchRadius, 2*pitchRadius)];
	[pitchCircle moveToPoint:NSMakePoint(-1, 0)];
	[pitchCircle lineToPoint:NSMakePoint(1, 0)];
	[pitchCircle moveToPoint:NSMakePoint(0, -1)];
	[pitchCircle lineToPoint:NSMakePoint(0, 1)];
	[pitchCircle transformUsingAffineTransform:scaler];
	[pitchCircle transformUsingAffineTransform:translation];
	
	NSBezierPath * refPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 10, 10)];
	[refPath moveToPoint:NSMakePoint(0, 0)];
	[refPath lineToPoint:NSMakePoint(10, 10)];
	[refPath transformUsingAffineTransform:scaler];

	
	
	NSBezierPath * gearPath = [self involuteGearWithTeeth:appDel.gearTeeth
											circularPitch:appDel.pitch
											pressureAngle:appDel.pressureAngle
												clearance:appDel.gearClearance];
	
	NSBezierPath * holePath = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-appDel.gearHoleDiam/2, -appDel.gearHoleDiam/2, appDel.gearHoleDiam, appDel.gearHoleDiam)];
	holePath = [holePath bezierPathByReversingPath];
	
	
	[gearPath transformUsingAffineTransform:rotation];
	[gearPath appendBezierPath:holePath];
	[gearPath transformUsingAffineTransform:scaler];
	[gearPath transformUsingAffineTransform:translation];
	
	
	NSBezierPath * rackPath = [self involuteRackWithTeeth:appDel.rackTeeth
													pitch:appDel.pitch
											pressureAngle:appDel.pressureAngle
												clearance:appDel.rackClearance];
	[rackPath transformUsingAffineTransform:motion];
	[rackPath transformUsingAffineTransform:scaler];
	[rackPath transformUsingAffineTransform:translation];

	
	[pitchCircle setLineWidth:0.5f];

	
	[[NSColor blueColor] set];
	[refPath stroke];
	[pitchCircle stroke];

	
	[[NSColor colorWithCalibratedRed:.5f green:0 blue:0 alpha:.5f] set];
	[gearPath fill];
	
	[[NSColor colorWithCalibratedRed:0 green:.5f blue:0 alpha:.5f] set];
	[rackPath fill];
	
	
}


- (NSBezierPath *)involuteRackWithTeeth:(int)numTeeth
								  pitch:(float)circularPitch
						  pressureAngle:(float)pressureAngle
							  clearance:(float)clearance
{
	
	NSBezierPath * rackPath = [NSBezierPath bezierPath];
	
	float addendum = circularPitch / M_PI;
	float dedendum = addendum + clearance;
	ofxVec2f deden(0, -dedendum);
	ofxVec2f adden(0, addendum);
	ofxVec2f pt;
	
	[rackPath moveToPoint:NSMakePoint(0, -2*dedendum)];

	for(int i =0; i < numTeeth; i++){
		float xpos = (float)i * circularPitch;
		pt = ofxVec2f( xpos + 0, 0) + deden.getRotated(pressureAngle);
		[rackPath lineToPoint:NSMakePoint(pt.x, pt.y)];
		
		pt = ofxVec2f( xpos + circularPitch/2, 0) + deden.getRotated(-pressureAngle);
		[rackPath lineToPoint:NSMakePoint(pt.x, pt.y)];
		
		pt = ofxVec2f( xpos + circularPitch/2, 0) + adden.getRotated(-pressureAngle);
		[rackPath lineToPoint:NSMakePoint(pt.x, pt.y)];
		
		pt = ofxVec2f( xpos + circularPitch, 0) + adden.getRotated(pressureAngle);
		[rackPath lineToPoint:NSMakePoint(pt.x, pt.y)];
		
	}
	
	pt = ofxVec2f( numTeeth * circularPitch, 0) + deden.getRotated(pressureAngle);
	[rackPath lineToPoint:NSMakePoint(pt.x, pt.y)];
	pt = ofxVec2f( pt.x, -2 *dedendum);
	[rackPath lineToPoint:NSMakePoint(pt.x, pt.y)];
	
	[rackPath closePath];
	
	
	
	return rackPath;
}

- (NSBezierPath *)involuteGearWithTeeth:(int)numTeeth
						  circularPitch:(float)circularPitch
						  pressureAngle:(float)pressureAngle
							  clearance:(float)clearance
{
	float addendum = (float) circularPitch / M_PI;
	float dedendum = addendum + clearance;
	
	// radiuses of the 4 circles:
	float pitchRadius = numTeeth * circularPitch / (2.0 * M_PI);
	float baseRadius = pitchRadius * cos( M_PI * pressureAngle /180.0);
	float outerRadius = pitchRadius + addendum;
	float rootRadius = pitchRadius - dedendum;
	
	float maxtanlength = sqrt(outerRadius*outerRadius - baseRadius*baseRadius);
	float maxangle = maxtanlength / baseRadius;
	
	float tl_at_pitchcircle = sqrt(pitchRadius*pitchRadius - baseRadius*baseRadius);
	float angle_at_pitchcircle = tl_at_pitchcircle / baseRadius;
	float diffangle = angle_at_pitchcircle - atan(angle_at_pitchcircle);
	float angularToothWidthAtBase = M_PI / numTeeth + 2.0 * diffangle;
	

	int resolution = 10;
	
	NSBezierPath * teeth = [NSBezierPath bezierPath];
	ofxVec2f vec;
	float rot =  M_PI -angularToothWidthAtBase/2;
	vec = ofxVec2f(0, rootRadius);
	vec.rotateRad(rot );
	[teeth moveToPoint:NSMakePoint(vec.x, vec.y)];
	
	for(int a = 0; a < numTeeth; a++){
		rot = M_PI -angularToothWidthAtBase/2 + (float) a * 2 * M_PI / (float)numTeeth;
		
		
		vec = ofxVec2f(0, rootRadius);
		vec.rotateRad(rot);
		[teeth lineToPoint:NSMakePoint(vec.x, vec.y)];
		
		
		for(int i = 0; i <= resolution; i++){
			// first side of the teeth:
			float angle = maxangle * (float)i / (float)resolution;
			float tanlength = angle * baseRadius;
			ofxVec2f radvec = ofxVec2f(0,1).getRotatedRad(angle);
			ofxVec2f tanvec = radvec.getPerpendicular() * -1;
			vec = (radvec * baseRadius) + (tanvec * tanlength);
			vec.rotateRad(rot);
			[teeth lineToPoint:NSMakePoint(vec.x, vec.y)];
			
		}
		for(int i = resolution ; i >=0; i--){
			// first side of the teeth:
			float angle = maxangle * (float)i / (float)resolution;
			float tanlength = angle * baseRadius;
			ofxVec2f radvec = ofxVec2f(0, 1).getRotatedRad(angularToothWidthAtBase - angle);
			ofxVec2f tanvec =  radvec.getPerpendicular();
			vec = (radvec * baseRadius) + (tanvec * tanlength);
			vec.rotateRad(rot);
			[teeth lineToPoint:NSMakePoint(vec.x, vec.y)];
		}
		
		
		vec = ofxVec2f(0, rootRadius).getRotatedRad(angularToothWidthAtBase);
		vec.rotateRad(rot );
		[teeth lineToPoint:NSMakePoint(vec.x, vec.y)];
		
		
	}
	[teeth closePath];
	return teeth;
	
	
}


- (void)print:(id)sender{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	float tscale = appDel.scale;
	float trot = appDel.rotation;
	appDel.scale =1;
	appDel.rotation=0;
	[super print:sender];
	appDel.scale = tscale;
	appDel.rotation=trot;
	[self setNeedsDisplay:YES];
}


- (void)magnifyWithEvent:(NSEvent *)event{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];

	NSSize newSize;
    newSize.height = self.frame.size.height * ([event magnification] + 1.0);
    newSize.width = self.frame.size.width * ([event magnification] + 1.0);
    //[self setFrameSize:newSize];
	appDel.scale *= 1+[event magnification];
	[self setNeedsDisplay:YES];
}

- (void)rotateWithEvent:(NSEvent *)event{
	TKAppDelegate * appDel =  [[NSApplication sharedApplication] delegate];
	appDel.rotation += [event rotation];
	[self setNeedsDisplay:YES];
}


- (void)scrollWheel:(NSEvent *)theEvent {
   // NSLog(@"user scrolled %f horizontally and %f vertically", [event deltaX], [event deltaY]);
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
