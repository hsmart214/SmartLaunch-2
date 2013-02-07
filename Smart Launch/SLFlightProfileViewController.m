//
//  SLFlightProfileViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 2/3/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLFlightProfileViewController.h"
#import "SLUnitsConvertor.h"

@interface SLFlightProfileViewController ()
@property (weak, nonatomic) IBOutlet UILabel *rocketNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *apogeeLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *coastTimeLabel;

@property (weak, nonatomic) IBOutlet UISegmentedControl *graphTypeSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *altitudeUnitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *velocityUnitsLabel;
@property (weak, nonatomic) IBOutlet SLMotorThrustCurveView *graphView;
@property (nonatomic, strong) NSArray *slicedFlightProfile;
@end

@implementation SLFlightProfileViewController

enum SLFlightProfileGraphType {
    SLFlightProfileGraphTypeVelocity,
    SLFlightProfileGraphTypeAcceleration,
    SLFlightProfileGraphTypeAltitude,
    SLFlightProfileGraphTypeMach
};

-(void)updateDisplay{
    self.rocketNameLabel.text = [self.dataSource rocketName];
    self.motorNameLabel.text = [self.dataSource motorName];
    self.maxVelocityLabel.text = [NSString stringWithFormat:@"%1.0f",[[self.dataSource burnoutVelocity] floatValue]];
    self.coastTimeLabel.text = [NSString stringWithFormat:@"%1.1f",[[self.dataSource coastTime] floatValue]];
    NSArray *unitNames = @[VELOCITY_UNIT_KEY, ACCEL_UNIT_KEY, ALT_UNIT_KEY, MACH_UNIT_KEY];
    NSUInteger index = [self.graphTypeSegmentedControl selectedSegmentIndex];
    [self.graphView setVerticalUnits:[SLUnitsConvertor displayStringForKey:unitNames[index]]];
    
    [self.graphView setNeedsDisplay];
}

#pragma mark - SLMotorThrustCurveViewDataSource methods

-(CGFloat)motorThrustCurveViewDataValueRange:(SLMotorThrustCurveView *)sender{
    switch ((enum SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex]) {
        case SLFlightProfileGraphTypeVelocity:
            return [[SLUnitsConvertor displayUnitsOf:[self.dataSource burnoutVelocity] forKey:VELOCITY_UNIT_KEY] floatValue];
        case SLFlightProfileGraphTypeAcceleration:
            return [[SLUnitsConvertor displayUnitsOf:[self.dataSource maxAcceleration] forKey:ACCEL_UNIT_KEY] floatValue];
        case SLFlightProfileGraphTypeAltitude:
            return [[SLUnitsConvertor displayUnitsOf:[self.dataSource apogeeAltitude] forKey:ALT_UNIT_KEY] floatValue];
        case SLFlightProfileGraphTypeMach:
            return [[self.dataSource maxMachNumber] floatValue];
    }
}

-(CGFloat)motorThrustCurveViewTimeValueRange:(SLMotorThrustCurveView *)sender{
    return [[self.dataSource totalTime] floatValue];
}

//This is completely wrong and needs to be rewritten
-(CGFloat)motorThrustCurveView:(SLMotorThrustCurveView *)thrustCurveView dataValueForTimeIndex:(CGFloat)timeIndex{
    switch ((enum SLFlightProfileGraphType)[self.graphTypeSegmentedControl selectedSegmentIndex]) {
        case SLFlightProfileGraphTypeVelocity:
            return [[SLUnitsConvertor displayUnitsOf:[self.dataSource dataAtTime: @(timeIndex) forKey:VEL_INDEX] forKey:VELOCITY_UNIT_KEY] floatValue];
        case SLFlightProfileGraphTypeAcceleration:
            return [[SLUnitsConvertor displayUnitsOf:[self.dataSource dataAtTime: @(timeIndex) forKey:ACCEL_INDEX] forKey:ACCEL_UNIT_KEY] floatValue];
        case SLFlightProfileGraphTypeAltitude:
            return [[SLUnitsConvertor displayUnitsOf:[self.dataSource dataAtTime: @(timeIndex) forKey:ALT_INDEX] forKey:ALT_UNIT_KEY] floatValue];
        case SLFlightProfileGraphTypeMach:
            return [[self.dataSource dataAtTime: @(timeIndex) forKey:MACH_INDEX] floatValue];
    }
}

#pragma mark - View Lifecycle

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:YES animated:YES];
    self.velocityUnitsLabel.text = [SLUnitsConvertor displayStringForKey:VELOCITY_UNIT_KEY];
    self.altitudeUnitsLabel.text = [SLUnitsConvertor displayStringForKey:ALT_UNIT_KEY];
    self.graphView.dataSource = self;
    
    [self updateDisplay];
}

-(void)viewWillDisappear:(BOOL)animated{
    
}

@end
