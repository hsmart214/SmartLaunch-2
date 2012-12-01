//
//  SLAnimatedRocketView.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/25/12.
//  Copyright (c) 2012 J. HOWARD SMART. All rights reserved.
//

#import "SLAnimatedRocketView.h"
#import "SLDefinitions.h"
#import <QuartzCore/QuartzCore.h>

#define X_INSET 30.0
#define Y_INSET 100.0
#define TOP_BUFFER 100.0
#define VECTOR_WIDTH 5.0
#define VECTOR_HEAD 10.0

@interface SLAnimatedRocketView()

@property (nonatomic, strong) UIImageView *goblin;
@property (nonatomic) float launchAngle;
@property (nonatomic) float rocketVelocity;
@property (nonatomic) float windVelocity;

@end

@implementation SLAnimatedRocketView

@synthesize launchAngle = _launchAngle;
@synthesize windVelocity = _windVelocity;

-(void)tiltRocketToAngle:(float)angle{
    self.launchAngle = -angle;  //in the model the launch angle is always positive, in Quartz, ccw is negative, so we switch it here
    CGAffineTransform tx = CGAffineTransformMakeRotation(-angle);
    [self.goblin setTransform:tx];
    [self setNeedsDisplay];
}

-(void)UpdateVectorsWithRocketVelocity:(float)rv andWindVelocity:(float)wv{
    self.rocketVelocity = rv;
    self.windVelocity = wv;
    [self setNeedsDisplay];
}

-(void)startFresh{
    self.goblin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:VERTICAL_ROCKET_PIC_NAME]];
    CGPoint orig = CGPointMake(self.goblin.bounds.size.width + X_INSET, self.goblin.bounds.size.height + Y_INSET);
    CGSize s = self.bounds.size;
    CGRect frame = CGRectMake(s.width - orig.x, s.height - orig.y, self.goblin.bounds.size.width, self.goblin.bounds.size.height);
    [self.goblin setFrame:frame];
    [self addSubview:self.goblin];
}

void drawVectorWithHead(CGContextRef context, UIColor *color, const CGPoint fromPt, const CGPoint toPt, const bool ccwLoop){
    CGContextSetStrokeColorWithColor(context, [color CGColor]);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, fromPt.x, fromPt.y);
    CGPathAddLineToPoint(path, nil, toPt.x, toPt.y);
    CGPathCloseSubpath(path);
    CGPoint corner, cross;
    
    if (toPt.y == fromPt.y){    //This must be the wind vector - the only horizontal vector
        float offset;
        if (ccwLoop){
            offset = -VECTOR_HEAD * 0.707;
        }else{
            offset = VECTOR_HEAD * 0.707;
        }
        corner.x = toPt.x + offset;
        corner.y = toPt.y - fabs(offset);
        cross.x = corner.x;
        cross.y = toPt.y;
        
    }else{  // This is either the rocket vector or the angle of attack vector
        
        float angle;    // This is the angle of our vector in our view's coordinate system (0° to the right, CW positive)
        float headAngle;// This is the angle of the vector head half-arrow
        
        if (toPt.x == fromPt.x){
            angle = _PI_ * 0.5;   //We will not have an upward vertical vector
            float offset;
            if (ccwLoop){
                offset = -VECTOR_HEAD * 0.707;
            }else{
                offset = VECTOR_HEAD * 0.707;
            }
            corner.x = toPt.x + offset;
            corner.y = toPt.y - VECTOR_HEAD * 0.707;
            cross.x = toPt.x;
            cross.y = corner.y;
        }else{
            angle = atanf((toPt.y-fromPt.y)/(toPt.x-fromPt.x));
            headAngle = 0.75 * _PI_ - angle;
            
            if (ccwLoop){
                corner.x = toPt.x + VECTOR_HEAD * 0.707 * cosf(headAngle);
                corner.y = toPt.y - VECTOR_HEAD * 0.707 * sinf(headAngle);
            }else{
                corner.x = toPt.x - VECTOR_HEAD * 0.707 * cosf(headAngle - _PI_ * 0.5);
                corner.y = toPt.y - VECTOR_HEAD * 0.707 * sinf(headAngle - _PI_ * 0.5);
            }
            cross.x = toPt.x - cosf(angle) * VECTOR_HEAD * 0.707;
            cross.y = toPt.y - sinf(angle) * VECTOR_HEAD * 0.707;
        }
        
    }
    CGPathMoveToPoint(path, nil, cross.x, cross.y);
    
    CGPathAddLineToPoint(path, nil, corner.x, corner.y);
    
    CGPathAddLineToPoint(path, nil, toPt.x, toPt.y);
    CGPathCloseSubpath(path);
    CGContextAddPath(context, path);
    CGPathRelease(path);
    CGContextStrokePath(context);

}

- (void)drawRect:(CGRect)rect
{
    float rv = _rocketVelocity;
    float wv = _windVelocity;
    //Figure out the scale that will show the vectors the best
    CGFloat scale;
    CGFloat xAvail = self.bounds.size.width - X_INSET;
    CGFloat yAvail = self.bounds.size.height - TOP_BUFFER - self.goblin.bounds.size.height;
    float rhoriz = rv * sinf(-_launchAngle);
    float xExtent;
    if (wv > 0){
        xExtent = rhoriz + wv;
    }else{
        xExtent = MAX(rhoriz, -wv);
    }
    
    float yExtent = rv * cosf(_launchAngle);
    if (xExtent!=0){
        scale = MIN((xAvail/xExtent), (yAvail/yExtent));
    }else{
        scale = yAvail/yExtent;
    }
    //Scale is points per unit velocity (meters/sec)
    
    //Set up the start and endpoints ===============================================
    CGFloat rad;
    CGPoint rvTip, rvEnd, wvTip, ctr, tip;
    ctr = self.goblin.center;
    rad = self.goblin.bounds.size.height/2.0;  // radius to the tip of the Goblin image
    tip.x = ctr.x - rad * sinf(-_launchAngle); // tip of the Goblin image
    tip.y = ctr.y - rad * cosf(_launchAngle);
    rvTip.x = tip.x - rv * scale * sinf(-_launchAngle);
    rvTip.y = tip.y - rv * scale * cosf(_launchAngle);
    rvEnd = tip;
    wvTip.x = rvTip.x + wv * scale;
    wvTip.y = rvTip.y;
    bool ccwLoop = self.windVelocity < 0.0;
    //Draw the reciprocal of the rocket velocity vector
    //(the vector of air motion contributed by the rocket motion along the launch guide)
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);

    UIColor *color = [UIColor redColor];
    CGContextSetLineWidth(context, VECTOR_WIDTH);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    if (self.launchAngle == 0.0) ccwLoop = true;    // only for this vector, so we have to reset this for the others below
    drawVectorWithHead(context, color, rvTip, rvEnd, ccwLoop);
    
    //Draw the wind velocity vector ================================================
    ccwLoop = self.windVelocity < 0.0;
    color = [UIColor blueColor];
    drawVectorWithHead(context, color, wvTip, rvTip, ccwLoop);
    
    //Draw the angle of attack vector ===============================================
    
    color = [UIColor purpleColor];
    drawVectorWithHead(context, color, wvTip, tip, ccwLoop);
    
    //Clean up
    UIGraphicsPopContext();

}


- (void)dealloc{
    self.goblin = nil;
}

@end
