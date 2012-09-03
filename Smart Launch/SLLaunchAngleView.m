//
//  SLLaunchAngleView.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import "SLLaunchAngleView.h"

#define TOLERANCE 0.001

@interface SLLaunchAngleView() 

@property (nonatomic, readonly) CGPoint point;
//@property (nonatomic) CGFloat angle;

@end

@implementation SLLaunchAngleView

@synthesize point = _point;
//@synthesize angle = _angle;
@synthesize dataSource = _dataSource;

//- (void)setAngle:(CGFloat)angle{
//    if (fabsf(_angle-angle)>TOLERANCE){
//        _angle = angle;
//        CGFloat x = sqrtf(1/(1+1/(tanf(angle)*tanf(angle))));
//        CGFloat y = sqrtf(1-x*x);
//        if (angle<0) x= -x;
//        CGPoint pt = CGPointMake(x, y);
//        self.point = pt;
//    }
//}
//
//- (void)setPoint:(CGPoint)point{
//    if (fabsf(point.x-_point.x)>TOLERANCE || fabsf(point.y-_point.y)>TOLERANCE){
//        _point = point;
//        _angle = atanf(_point.x/_point.y);
//        [self setNeedsDisplay];
//    }
//}

- (CGPoint)point{
    CGFloat angle = [self.dataSource angleForLaunchAngleView:self];
    CGFloat x = sqrtf(1/(1+1/(tanf(angle)*tanf(angle))));
    CGFloat y = sqrtf(1-x*x);
    if (angle<0) x= -x;
    return CGPointMake(x, y);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    CGFloat mult = self.bounds.size.height;
    CGPoint origin = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height);
    CGPoint midTop = CGPointMake(self.bounds.size.width/2.0, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    CGContextSetLineWidth(context, 1.0);
    [[UIColor blueColor] setStroke];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, midTop.x, midTop.y);
    CGContextAddLineToPoint(context, origin.x, origin.y);
    CGContextStrokePath(context);
    CGContextBeginPath(context);
    CGContextSetLineWidth(context, 3.0);
    [[UIColor greenColor] setStroke];
    CGContextMoveToPoint(context, origin.x, origin.y);
    CGContextAddLineToPoint(context, origin.x + self.point.x * mult, origin.y - self.point.y * mult);
    CGContextStrokePath(context);
    UIGraphicsPopContext();
}


@end
