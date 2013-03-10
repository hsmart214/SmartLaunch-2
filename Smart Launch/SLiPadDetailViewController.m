//
//  SLiPadDetailViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 3/9/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLiPadDetailViewController.h"
#import "SLCurveGraphView.h"
#import "SLUnitsConvertor.h"

@interface SLiPadDetailViewController ()<SLCurveGraphViewDelegate, SLCurveGraphViewDataSource>

@property (weak, nonatomic) IBOutlet SLCurveGraphView *thrustCurveView;
@property (weak, nonatomic) IBOutlet SLCurveGraphView *flightProfileView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *graphTypeSegmentedControl;

@end

@implementation SLiPadDetailViewController

-(void)setModel:(SLPhysicsModel *)model{
    _model = model;
    self.dataSource = _model;
}

- (IBAction)flightProfileGraphTypeChanged:(UISegmentedControl *)sender {
    [self updateDisplay];
}

-(void)updateDisplay{
    [self.flightProfileView resetAxes];
    [self.thrustCurveView resetAxes];
    NSArray *unitNames = @[VELOCITY_UNIT_KEY, ACCEL_UNIT_KEY, ALT_UNIT_KEY, MACH_UNIT_KEY, THRUST_UNIT_KEY];
    NSArray *formatStrings = @[@"%1.0f",@"%1.0f",@"%1.0f",@"%1.1f", @"%1.0f"];
    NSUInteger index = [self.graphTypeSegmentedControl selectedSegmentIndex];
    [self.flightProfileView setVerticalUnits:[SLUnitsConvertor displayStringForKey:unitNames[index]]withFormat:formatStrings[index]];
    [self.thrustCurveView setVerticalUnits:[SLUnitsConvertor displayStringForKey:THRUST_UNIT_KEY] withFormat:@"%1.0f"];
    [self.thrustCurveView setNeedsDisplay];
    [self.flightProfileView setNeedsDisplay];
}


#pragma mark - SLCurveGraphViewDataSource methods

-(CGFloat)curveGraphViewDataValueRange:(SLCurveGraphView *)sender{
    if (sender == self.flightProfileView){
        switch ((enum SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex]) {
            case SLFlightProfileGraphTypeVelocity:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource maxVelocity] forKey:VELOCITY_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeAcceleration:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource maxAcceleration] forKey:ACCEL_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeAltitude:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource apogeeAltitude] forKey:ALT_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeMach:
                return [[self.dataSource maxMachNumber] floatValue];
            case SLFlightProfileGraphTypeDrag:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource maxDrag] forKey:THRUST_UNIT_KEY] floatValue];
        }
    }else{ //must be thrust curve
        return [[SLUnitsConvertor displayUnitsOf:self.model.motor.peakThrust forKey:THRUST_UNIT_KEY] floatValue];
    }
}

-(CGFloat)curveGraphViewDataValueMinimumValue:(SLCurveGraphView *)sender{
    if (sender == self.thrustCurveView) return 0.0;
    if ([self.graphTypeSegmentedControl selectedSegmentIndex] == SLFlightProfileGraphTypeAcceleration){
        return [[SLUnitsConvertor displayUnitsOf:[self.dataSource maxDeceleration] forKey:ACCEL_UNIT_KEY] floatValue];
    }else{
        return 0.0;
    }
}

-(CGFloat)curveGraphViewTimeValueRange:(SLCurveGraphView *)sender{
    if (sender == self.flightProfileView){
        return [[self.dataSource totalTime] floatValue];
    }else{
        return [[self.model.motor.times lastObject] floatValue];
    }
}

-(CGFloat)curveGraphView:(SLCurveGraphView *)sender dataValueForTimeIndex:(CGFloat)timeIndex{
    if (sender == self.flightProfileView){
        switch ((enum SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex]) {
            case SLFlightProfileGraphTypeVelocity:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource dataAtTime: @(timeIndex) forKey:VEL_INDEX] forKey:VELOCITY_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeAcceleration:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource dataAtTime: @(timeIndex) forKey:ACCEL_INDEX] forKey:ACCEL_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeAltitude:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource dataAtTime: @(timeIndex) forKey:ALT_INDEX] forKey:ALT_UNIT_KEY] floatValue];
            case SLFlightProfileGraphTypeMach:
                return [[self.dataSource dataAtTime: @(timeIndex) forKey:MACH_INDEX] floatValue];
            case SLFlightProfileGraphTypeDrag:
                return [[SLUnitsConvertor displayUnitsOf:[self.dataSource dataAtTime: @(timeIndex) forKey:DRAG_INDEX] forKey:THRUST_UNIT_KEY] floatValue];
        }
    }else{ //must be thrust curve
        return [[SLUnitsConvertor displayUnitsOf:@([self.model.motor thrustAtTime:timeIndex]) forKey:THRUST_UNIT_KEY] floatValue];
    }
}

#pragma mark - SLCurveGraphViewDelegate methods

-(NSUInteger)numberOfVerticalDivisions:(SLCurveGraphView *)sender{
    return 5;
}

-(BOOL)shouldDisplayMachOneLine:(SLCurveGraphView *)sender{
    return ((enum SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex] == SLFlightProfileGraphTypeMach);
}


#pragma mark - View Life Cycle

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.thrustCurveView.delegate = self;
    self.thrustCurveView.dataSource = self;
    self.flightProfileView.delegate = self;
    self.flightProfileView.dataSource = self;
}

@end
