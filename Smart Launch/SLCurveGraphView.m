//
//  SLMotorThrustCurveView.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLCurveGraphView.h"

#define WIDTH_FRACTION 0.8
#define SEC_OFFSET 7
#define MAX_HORIZ_DIVS 20

@interface SLCurveGraphView ()

@property (nonatomic) CGFloat hrange;
@property (nonatomic) CGFloat vrange;
@property (nonatomic) CGFloat fullrange;
@property (nonatomic, strong) NSString *verticalUnits;
@property (nonatomic, strong) NSString *verticalUnitsFormat;
@property (nonatomic) NSUInteger verticalDivisions;
@property (nonatomic) CGFloat hStepSize;                // if the time range is too big, reduce the number of grid lines

@end

@implementation SLCurveGraphView

- (void)setup{
    if ([self.delegate respondsToSelector:@selector(numberOfVerticalDivisions:)]){
        self.verticalDivisions = [self.delegate numberOfVerticalDivisions:self];
    }else{
        self.verticalDivisions = CURVEGRAPHVIEW_DEFAULT_VERTICAL_DIVISIONS;
    }
    [self setNeedsDisplay];
}

-(NSString *)verticalUnits{
    if (!_verticalUnits){
        _verticalUnits = @"N";
    }
    return _verticalUnits;
}

-(NSString *)verticalUnitsFormat{
    if (!_verticalUnitsFormat){
        _verticalUnitsFormat = @"%1.0f %@";
    }
    return _verticalUnitsFormat;
}

-(void)setVerticalUnits:(NSString *)units withFormat:(NSString *)formatString{
    self.verticalUnits = units;
    self.verticalUnitsFormat = [formatString stringByAppendingString:@" %@"];;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)awakeFromNib{
    [self setup];
}

- (CGFloat)hrange{
    if (_hrange==0.0){
        CGFloat btime = [self.dataSource curveGraphViewTimeValueRange:self];
        _hrange = ceil(btime);
        if (btime <= MAX_HORIZ_DIVS) {
            self.hStepSize = 1.0;
        }else{
            self.hStepSize = 2.0;
        }
    }
    return _hrange;
}

- (CGFloat)vrange{
    if(_vrange==0.0){
        CGFloat fmax = [self.dataSource curveGraphViewDataValueRange:self] - [self.dataSource curveGraphViewDataValueMinimumValue:self];
        int ex = floor(log10(fmax));
        double mant = fmax/pow(10.0, ex);
        _vrange = ceil(mant * 10.0)/10.0;
        self.fullrange = _vrange * pow(10.0, ex);
    }
    return _vrange;
}

-(void)resetAxes{
    _hrange = 0.0;
    _vrange = 0.0;
}

-(CGFloat)timeSlice{
    return self.hrange /self.frame.size.width * WIDTH_FRACTION;
}


- (void)drawRect:(CGRect)rect
{
    if (!_dataSource) return;
    CGFloat tmax = [self.dataSource curveGraphViewTimeValueRange:self];
    CGFloat fmax = [self.dataSource curveGraphViewDataValueRange:self];
    CGFloat fmin = [self.dataSource curveGraphViewDataValueMinimumValue:self];
    CGFloat graphWidth = self.bounds.size.width * WIDTH_FRACTION;
    CGFloat margin = (self.bounds.size.width - graphWidth) / 2.0;
    CGFloat graphHeight = self.bounds.size.height - 2*margin;
    CGPoint origin = CGPointMake(margin, self.bounds.size.height - margin);
    CGFloat hscale = graphWidth/self.hrange;
    CGFloat vscale = graphHeight/self.vrange;
    CGFloat ppp = [UIScreen mainScreen].scale;              //ratio of pixels per point on the screen (usually 1.0, but 2.0 for retina display)
    
    // Draw the axes
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    CGContextSetLineWidth(context, 1.5);
    [[UIColor blackColor] setStroke];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, origin.x, origin.y);
    CGContextAddLineToPoint(context, origin.x, margin);
    CGContextMoveToPoint(context, origin.x, origin.y);
    CGContextAddLineToPoint(context, origin.x+graphWidth, origin.y);
    CGContextStrokePath(context);
    
    // If the fmin is not zero, draw an x axis line
    
    if (fmin != 0.0){
        int ex = floor(log10(fmax - fmin));
        double mant = -fmin/pow(10, ex);
        CGFloat yvalue = origin.y - mant * vscale;
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, origin.x, yvalue);
        CGContextAddLineToPoint(context, origin.x + graphWidth, yvalue);
        CGContextStrokePath(context);
    }
    
    // If the delegate tells us to do so, draw a line at data value = 1.0
    // Intended to be used for mach one.
    
    if ([self.delegate respondsToSelector:@selector(shouldDisplayMachOneLine:)] &&
        [self.delegate shouldDisplayMachOneLine:self] && fmax >= 1.0){
        int ex = floor(log10(fmax - fmin));
        double mant = 1.0/pow(10, ex);
        CGFloat yvalue = origin.y - mant * vscale;
        CGContextBeginPath(context);
        [[SLCustomUI machLineColor] setStroke];
        CGContextMoveToPoint(context, origin.x, yvalue);
        CGContextAddLineToPoint(context, origin.x + graphWidth, yvalue);
        CGContextStrokePath(context);
    }
    
    // Draw the hash grid
    
    CGContextBeginPath(context);
    CGContextSetLineWidth(context, 1.0);
    [[UIColor lightGrayColor] setStroke];
    
    for (int i = 1; i < self.verticalDivisions; i++) {
        CGFloat yoffset = (self.vrange/self.verticalDivisions)*vscale;
        CGContextMoveToPoint(context, origin.x+1, origin.y-i*yoffset);
        CGContextAddLineToPoint(context, origin.x+graphWidth, origin.y-i*yoffset);
    }
    for (int i = self.hStepSize; i <= floor(self.hrange); i += self.hStepSize){
        CGContextMoveToPoint(context, origin.x+i*hscale, origin.y-1);
        CGContextAddLineToPoint(context, origin.x+i*hscale, margin);
        NSString *sec = [NSString stringWithFormat:@"%d", i];
        NSAttributedString *attSec = [[NSAttributedString alloc] initWithString:sec attributes:@{
                                                                NSForegroundColorAttributeName:[SLCustomUI graphTextColor],
                                                                           NSFontAttributeName:[UIFont systemFontOfSize:10]}];
        CGPoint secPt = CGPointMake(origin.x+i*hscale-3, origin.y+SEC_OFFSET);
        [attSec drawAtPoint:secPt];
        
    }
    CGContextStrokePath(context);
    
    NSString *maxValueNotation = [NSString stringWithFormat:self.verticalUnitsFormat,self.fullrange, self.verticalUnits];
    NSMutableAttributedString *notation = [[NSMutableAttributedString alloc] initWithString:maxValueNotation attributes:@{
                                                             NSForegroundColorAttributeName:[SLCustomUI graphTextColor],
                                                                        NSFontAttributeName:[UIFont boldSystemFontOfSize:10]}];
    CGPoint maxNPoint = CGPointMake(10, 10);
    [notation drawAtPoint:maxNPoint];
    CGContextSetLineWidth(context, 2.0);
    [[SLCustomUI curveGraphCurveColor] setStroke];
    CGContextBeginPath(context);
    // The next three lines correct the starting point if the graph's 0,0 origin is not in the lower left corner
    int ex = floor(log10(fmax - fmin));
    double mant = -fmin/pow(10, ex);
    CGFloat yvalue = origin.y - mant * vscale;
    CGContextMoveToPoint(context, origin.x, yvalue);
    
    CGFloat time = 0.0;
    
    while (time < tmax) {
        time += 1/(ppp*hscale);
        double thrust = [self.dataSource curveGraphView:self dataValueForTimeIndex:time] - fmin;
        int ex = floor(log10(fmax - fmin));
        double mant = thrust/pow(10, ex);
        CGFloat yvalue = origin.y - mant * vscale;
        CGFloat xvalue = origin.x + time * hscale;
        CGContextAddLineToPoint(context, xvalue, yvalue);
    }
    CGContextStrokePath(context);
    
}

-(void)dealloc{
    self.verticalUnits = nil;
    self.verticalUnitsFormat = nil;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"%@ curve graph", self.verticalUnits];
}

@end

