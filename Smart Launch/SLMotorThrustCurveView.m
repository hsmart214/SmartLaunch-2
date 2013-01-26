//
//  SLMotorThrustCurveView.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLMotorThrustCurveView.h"

#define WIDTH_FRACTION 0.8
#define SEC_OFFSET 7

@interface SLMotorThrustCurveView ()

@property (nonatomic) CGFloat hrange;
@property (nonatomic) CGFloat vrange;
@property (nonatomic) CGFloat fullrange;

@end

@implementation SLMotorThrustCurveView

- (void)setup{
    [self setNeedsDisplay];
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (CGFloat)hrange{
    if (_hrange==0.0){
        CGFloat btime = [self.dataSource motorThrustCurveViewTimeValueRange:self];
        _hrange = ceil(btime);
    }
    return _hrange;
}

- (CGFloat)vrange{
    if(_vrange==0.0){
        CGFloat fmax = [self.dataSource motorThrustCurveViewDataValueRange:self];
        int ex = floor(log10(fmax));
        double mant = fmax/pow(10.0, ex);
        _vrange = ceil(mant * 10.0)/10.0;
        self.fullrange = _vrange * pow(10.0, ex);
    }
    return _vrange;
}


- (void)drawRect:(CGRect)rect
{
    if (!_dataSource) return;
    ///    CGFloat ppp = [UIScreen mainScreen].scale;
    CGFloat tmax = [self.dataSource motorThrustCurveViewTimeValueRange:self];
    CGFloat fmax = [self.dataSource motorThrustCurveViewDataValueRange:self];
    CGFloat graphWidth = self.frame.size.width * WIDTH_FRACTION;
    CGFloat margin = (self.frame.size.width - graphWidth) / 2.0;
    CGFloat graphHeight = self.frame.size.height - 2*margin;
    CGPoint origin = CGPointMake(margin, self.bounds.size.height - margin);
    CGFloat hscale = graphWidth/self.hrange;
    CGFloat vscale = graphHeight/self.vrange;
    CGFloat ppp = [UIScreen mainScreen].scale;              //ratio of pixels per point on the screen (usually 1.0, but 2.0 for retina display)
    
    // Draw the axes
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    CGContextSetLineWidth(context, 2.0);
    [[UIColor blackColor] setStroke];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, origin.x, origin.y);
    CGContextAddLineToPoint(context, origin.x, margin);
    CGContextMoveToPoint(context, origin.x, origin.y);
    CGContextAddLineToPoint(context, origin.x+graphWidth, origin.y);
    CGContextStrokePath(context);
    
    // Draw the hash grid
    
    CGContextBeginPath(context);
    CGContextSetLineWidth(context, 1.0);
    [[UIColor lightGrayColor] setStroke];
    
    for (int i = 1; i < 6; i++) {
        CGFloat yoffset = (self.vrange/6)*vscale;
        CGContextMoveToPoint(context, origin.x+1, origin.y-i*yoffset);
        CGContextAddLineToPoint(context, origin.x+graphWidth, origin.y-i*yoffset);
    }
    for (int i = 1; i <= floor(self.hrange); i++){
        CGContextMoveToPoint(context, origin.x+i*hscale, origin.y-1);
        CGContextAddLineToPoint(context, origin.x+i*hscale, margin);
        NSString *sec = [NSString stringWithFormat:@"%d", i];
        CGPoint secPt = CGPointMake(origin.x+i*hscale-3, origin.y+SEC_OFFSET);
        [sec drawAtPoint:secPt forWidth:20 withFont:[UIFont systemFontOfSize:10] fontSize:10 lineBreakMode:NSLineBreakByCharWrapping baselineAdjustment:UIBaselineAdjustmentNone];
    }
    CGContextStrokePath(context);
    
    NSString *maxNewtons = [NSString stringWithFormat:@"%1.0f N",self.fullrange];
    CGPoint maxNPoint = CGPointMake(10, 10);
    [maxNewtons drawAtPoint:maxNPoint forWidth:80 withFont:[UIFont systemFontOfSize:10] fontSize:10 lineBreakMode:NSLineBreakByCharWrapping baselineAdjustment:UIBaselineAdjustmentNone];
    
    CGContextSetLineWidth(context, 2.0);
    [[UIColor redColor] setStroke];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, origin.x, origin.y);
    
    CGFloat time = 0.0;
    
    while (time < tmax) {
        time += 1/(ppp*hscale);
        double thrust = [self.dataSource motorThrustCurveView:self dataValueForTimeIndex:time];
        int ex = floor(log10(fmax));
        double mant = thrust/pow(10, ex);
        CGFloat yvalue = origin.y - mant * vscale;
        CGFloat xvalue = origin.x + time * hscale;
        CGContextAddLineToPoint(context, xvalue, yvalue);
    }
    CGContextStrokePath(context);
    
}

@end

