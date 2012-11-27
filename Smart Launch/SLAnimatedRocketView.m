//
//  SLAnimatedRocketView.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/25/12.
//  Copyright (c) 2012 J. HOWARD SMART. All rights reserved.
//

#import "SLAnimatedRocketView.h"
#import "SLDefinitions.h"

#define X_INSET 30.0
#define Y_INSET 10.0
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
    self.launchAngle = angle;
    CGAffineTransform tx = CGAffineTransformMakeRotation(angle);
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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self startFresh];
    }
    return self;
}

- (void)awakeFromNib{
    [self startFresh];
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
    float rhoriz = rv * sinf(_launchAngle);
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
    
    //Draw the rocket velocity vector
    CGFloat ctrx, ctry, tipx, tipy, rad;
    float headAngle = 0.75  * _PI_;
    ctrx = self.goblin.center.x;
    ctry = self.goblin.center.y;
    rad = self.goblin.bounds.size.height/2.0;
    tipx = ctrx - rad * sinf(_launchAngle);
    tipy = ctry - rad * cosf(_launchAngle);
    CGContextSetStrokeColorWithColor(context, [[UIColor redColor] CGColor]);
    CGContextSetLineWidth(context, VECTOR_WIDTH);
    CGPathMoveToPoint(vectors, nil, tipx, tipy);
    CGPoint rvTip, wvTip, head;
    rvTip.x = tipx - rv * scale * sinf(_launchAngle);
    rvTip.y = tipy - rv * scale * cosf(_launchAngle);
    CGPathAddLineToPoint(vectors, nil, rvTip.x, rvTip.y);
    head.x = rvTip.x + VECTOR_HEAD * sinf(headAngle - _launchAngle);
    head.y = rvTip.y - VECTOR_HEAD * cosf(headAngle - _launchAngle);
    CGPathAddLineToPoint(vectors, nil, head.x, head.y);
    CGContextAddPath(context, vectors);
    CGPathRelease(vectors);
    CGContextStrokePath(context);
    
    //Draw the wind velocity vector
    vectors = CGPathCreateMutable();
    CGContextSetStrokeColorWithColor(context, [[UIColor blueColor] CGColor]);
    CGPathMoveToPoint(vectors, nil, rvTip.x, rvTip.y);
    wvTip.x = rvTip.x - wv * scale;
    wvTip.y = rvTip.y;
    CGPathAddLineToPoint(vectors, nil, wvTip.x, wvTip.y);
    head.x = wvTip.x - VECTOR_HEAD * 0.707;
    head.y = wvTip.y - VECTOR_HEAD * 0.707;
    CGPathAddLineToPoint(vectors, nil, head.x, head.y);
    CGContextAddPath(context, vectors);
    CGPathRelease(vectors);
    CGContextStrokePath(context);
    
    //Draw the angle of attack vector
    vectors = CGPathCreateMutable();
    CGContextSetStrokeColorWithColor(context, [[UIColor greenColor] CGColor]);
    CGPathMoveToPoint(vectors, nil, wvTip.x, wvTip.y);
    CGPathAddLineToPoint(vectors, nil, tipx, tipy);
    float aoa = atanf((wvTip.x-tipx)/(wvTip.y-tipy));
    headAngle = aoa - _PI_/4.0;
    head.x = tipx + VECTOR_HEAD * cosf(headAngle);
    head.y = tipy - VECTOR_HEAD * sinf(headAngle);
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
