//
//  SLAnimatedRocketView.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/25/12.
//  Copyright (c) 2012 All rights reserved.
//

@import QuartzCore;
#import "SLAnimatedRocketView.h"

#define TOP_BUFFER 20.0
#define VECTOR_WIDTH 3.0
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

-(void)setAvatar:(NSString *)avatar{
    if (![avatar isEqualToString:_avatar]){
        _avatar = avatar;
        self.goblin.image = [UIImage imageNamed:[avatar stringByAppendingString:AVATAR_VERTICAL_SUFFIX]];
        NSAssert(self.goblin.image != nil, @"No image for vertical avatar");
    }
}

-(UIImageView *)goblin{
    if (!_goblin){
        _goblin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:VERTICAL_ROCKET_PIC_NAME]];
    }
    return _goblin;
}

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
    for (UIView* v in self.subviews){
        [v removeFromSuperview];
    }
    NSString *avatarName = self.avatar ? [self.avatar stringByAppendingString:AVATAR_VERTICAL_SUFFIX] : VERTICAL_ROCKET_PIC_NAME;
    self.goblin.image = [UIImage imageNamed:avatarName];
    NSAssert(self.goblin.image != nil, @"No image for vertical avatar");
    CGPoint orig = CGPointMake(self.bounds.size.width/2.0 - self.goblin.bounds.size.width/2.0, self.goblin.bounds.size.height);
    CGSize s = self.bounds.size;
    CGRect frame = CGRectMake(orig.x, s.height - orig.y, self.goblin.bounds.size.width, self.goblin.bounds.size.height);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) frame = CGRectMake(s.width/2 - self.goblin.bounds.size.width/2, s.height - self.goblin.bounds.size.height, self.goblin.bounds.size.width, self.goblin.bounds.size.height);
    [self.goblin setTransform:CGAffineTransformIdentity];
    [self addSubview:self.goblin];
    [self.goblin setFrame:frame];
    [self setNeedsDisplay];
}

void drawVectorWithHead(CGContextRef context, UIColor *color, const CGPoint fromPt, const CGPoint toPt, const bool ccwLoop){
    if (toPt.x == fromPt.x && toPt.y == fromPt.y) return;
    float angle = 0.5 * _PI_ + atanf((toPt.y-fromPt.y)/(toPt.x-fromPt.x));
    if (fromPt.x <= toPt.x){
        angle += _PI_;
    }
    CGContextSetStrokeColorWithColor(context, [color CGColor]);
    CGContextSetFillColorWithColor(context,[color CGColor]);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPoint corner, cross;
    CGAffineTransform rot = CGAffineTransformMakeRotation(angle);
    CGAffineTransform tran = CGAffineTransformMakeTranslation(toPt.x, toPt.y);
    CGAffineTransform tx = CGAffineTransformConcat(rot, tran);
    float length = sqrtf((fromPt.x-toPt.x)*(fromPt.x-toPt.x) + (fromPt.y-toPt.y)*(fromPt.y-toPt.y));
    float offset = VECTOR_HEAD * 0.707106;
    if (!ccwLoop) offset *= -1;
    corner.x = offset;
    corner.y = - fabsf(offset);
    cross.x = 0;
    cross.y = - fabsf(offset);
    CGPathMoveToPoint(path, &tx, 0, -length);
    CGPathAddLineToPoint(path, &tx, 0, 0);
    CGPathCloseSubpath(path);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    CGPathMoveToPoint(path, &tx, 0, 0);
    CGPathAddLineToPoint(path, &tx, corner.x, corner.y);
    CGPathAddLineToPoint(path, &tx, cross.x, cross.y);
    CGPathCloseSubpath(path);
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    CGPathRelease(path);
    
}

- (void)drawRect:(CGRect)rect
{
    if (!self.goblin || _rocketVelocity == 0.0) return;
    float rv = _rocketVelocity;
    float wv = _windVelocity;
    //Figure out the scale that will show the vectors the best
    CGFloat scale;
    CGFloat xAvail = self.bounds.size.width/2.0 - self.goblin.bounds.size.width/2.0;
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
    CGContextSaveGState(context);
    

    UIColor *color = [SLCustomUI thrustVectorColor];
    CGContextSetLineWidth(context, VECTOR_WIDTH);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    if (self.launchAngle == 0.0) ccwLoop = false;    // only for this vector, so we have to reset this for the others below
    drawVectorWithHead(context, color, rvEnd, rvTip, !ccwLoop);
    
    //Draw the wind velocity vector ================================================
    ccwLoop = self.windVelocity < 0.0;
    color = [SLCustomUI windVectorColor];
    drawVectorWithHead(context, color, wvTip, rvTip, ccwLoop);
    
    //Draw the angle of attack vector ===============================================
    ccwLoop = !ccwLoop;
    color = [SLCustomUI AoAVectorColor];
    drawVectorWithHead(context, color, wvTip, tip, ccwLoop);
    
    //Clean up
    CGContextRestoreGState(context);

}

- (void)dealloc{
    self.goblin = nil;
}

-(NSString *)description{
    return @"AnimatedRocketView";
}

@end
