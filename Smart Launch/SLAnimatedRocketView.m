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

void drawVectorWithHead(CGMutablePathRef path, CGPoint fromPt, CGPoint toPt){
    CGPathMoveToPoint(path, nil, fromPt.x, fromPt.y);
    CGPathAddLineToPoint(path, nil, toPt.x, toPt.y);
    float angle = atanf((toPt.y-fromPt.y)/(toPt.x-fromPt.x));
    CGPoint ccwPt, cwPt;
    ccwPt.x = toPt.x + VECTOR_HEAD * cosf(angle - _PI_*3/4);
    ccwPt.y = toPt.y + VECTOR_HEAD * sinf(angle - _PI_*3/4);
    cwPt.x = toPt.x + VECTOR_HEAD * cosf(angle + _PI_*3/4);
    cwPt.y = toPt.y + VECTOR_HEAD * sinf(angle + _PI_*3/4);
    CGPathAddLineToPoint(path, nil, ccwPt.x, ccwPt.y);
    CGPathAddLineToPoint(path, nil, cwPt.x, cwPt.y);
    CGPathAddLineToPoint(path, nil, toPt.x, toPt.y);
}

- (void)drawRect:(CGRect)rect
{
    float rv = _rocketVelocity;
    float wv = _windVelocity;
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
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
    CGMutablePathRef vectors = CGPathCreateMutable();
    
    //Draw the rocket velocity vector ============================================
    CGFloat rad, headAngle;
    CGPoint rvTip, rvEnd, wvTip, ctr, tip;
    if (wv > 0){
        headAngle = 0.75  * _PI_;
    }else{
        headAngle = 0.75 * _PI_;
    }
    ctr = self.goblin.center;
    rad = self.goblin.bounds.size.height/2.0;  // radius to the tip of the Goblin image
    tip.x = ctr.x - rad * sinf(-_launchAngle); // tip of the Goblin image
    tip.y = ctr.y - rad * cosf(_launchAngle);
    CGContextSetStrokeColorWithColor(context, [[UIColor redColor] CGColor]);
    CGContextSetLineWidth(context, VECTOR_WIDTH);
//    CGPathMoveToPoint(vectors, nil, tip.x, tip.y);
    rvTip.x = tip.x - rv * scale * sinf(-_launchAngle);
    rvTip.y = tip.y - rv * scale * cosf(_launchAngle);
    rvEnd = tip;
    rvEnd.x -= wv * scale;
    rvTip.x -= wv * scale;
    wvTip.x = rvTip.x + wv * scale;
    wvTip.y = rvTip.y;

//    CGPathAddLineToPoint(vectors, nil, rvTip.x, rvTip.y);
//    CGPathMoveToPoint(vectors, nil, tip.x, tip.y);
//    head.x = tip.x + VECTOR_HEAD * sinf(headAngle + (_launchAngle - _PI_/2));
//    head.y = tip.y - VECTOR_HEAD * cosf(headAngle + (_launchAngle - _PI_/2));
//    CGPathAddLineToPoint(vectors, nil, head.x, head.y);
    drawVectorWithHead(vectors, rvTip, rvEnd);
    CGContextAddPath(context, vectors);
    CGPathRelease(vectors);
    CGContextStrokePath(context);
    
    //Draw the wind velocity vector ================================================

    vectors = CGPathCreateMutable();
    CGContextSetStrokeColorWithColor(context, [[UIColor blueColor] CGColor]);
//    CGPathMoveToPoint(vectors, nil, rvTip.x, rvTip.y);
//    CGPathAddLineToPoint(vectors, nil, wvTip.x, wvTip.y);
//    if (wv > 0){
//        head.x = rvTip.x - VECTOR_HEAD * 0.707;
//    }else{
//        head.x = rvTip.x - VECTOR_HEAD * 0.707;
//    }
//    head.y = rvTip.y - VECTOR_HEAD * 0.707;
//    CGPathMoveToPoint(vectors, nil, rvTip.x, rvTip.y);
//    CGPathAddLineToPoint(vectors, nil, head.x, head.y);
    drawVectorWithHead(vectors, rvTip, wvTip);
    CGContextAddPath(context, vectors);
    CGPathRelease(vectors);
    CGContextStrokePath(context);
    
    //Draw the angle of attack vector ===============================================
    
    vectors = CGPathCreateMutable();
    CGContextSetStrokeColorWithColor(context, [[UIColor purpleColor] CGColor]);
//    CGPathMoveToPoint(vectors, nil, wvTip.x, wvTip.y);
//    CGPathAddLineToPoint(vectors, nil, tip.x, tip.y);
//    float aoa = atanf((wvTip.x-tip.x)/(wvTip.y-tip.y));
//    headAngle = 1.25 * _PI_ + _launchAngle - aoa;
//    if (wv < 0) headAngle = aoa + _PI_/4.0;
//    head.x = tip.x + VECTOR_HEAD * cosf(headAngle);
//    head.y = tip.y - VECTOR_HEAD * sinf(headAngle);
//    CGPathAddLineToPoint(vectors, nil, head.x, head.y);
    drawVectorWithHead(vectors, rvTip, tip);
    CGContextAddPath(context, vectors);
    CGPathRelease(vectors);
    CGContextStrokePath(context);
    
    //Clean up
    UIGraphicsPopContext();

}


- (void)dealloc{
    self.goblin = nil;
}

@end
