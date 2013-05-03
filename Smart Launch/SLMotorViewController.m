//
//  SLMotorViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

#import "SLMotorViewController.h"

@interface SLMotorViewController () <SLCurveGraphViewDataSource>

@end

@implementation SLMotorViewController 

#pragma mark SLMotorThrustCurveDataSource protocol methods

- (float)curveGraphViewDataValueRange: (SLCurveGraphView *)sender{
    return self.motor.peakThrust;
}

-(float)curveGraphViewDataValueMinimumValue:(SLCurveGraphView *)sender{
    return 0.0;
}

- (float)curveGraphViewTimeValueRange:(SLCurveGraphView *)sender{
    return [[self.motor.times lastObject] floatValue];
}

- (float)curveGraphView:(SLCurveGraphView *)thrustCurveView dataValueForTimeIndex:(CGFloat)timeIndex{
    return [self.motor thrustAtTime:timeIndex];
}

#pragma mark - SLSimulationDelegate method

- (IBAction)userChoseMotor:(UIBarButtonItem *)sender {
    [self.delegate sender:self didChangeRocketMotor:@[@{MOTOR_COUNT_KEY: @1,
          MOTOR_PLIST_KEY: [self.motor motorDict]}]];
    [self.navigationController popToViewController:self.popBackViewController animated:YES];
}

- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.splitViewController){
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        [self.view insertSubview:backgroundView atIndex:0];
    }else{
        self.view.backgroundColor = [SLCustomUI iPadBackgroundColor];
    }
    self.motorManufacturer.text = self.motor.manufacturer;
    self.motorDiameter.text = [NSString stringWithFormat:@"%d", self.motor.diameter];
    self.motorMass.text = [@(self.motor.loadedMass) description];
    self.propellantMass.text = [@(self.motor.propellantMass) description];
    self.motorLength.text = [@(self.motor.length) description];
    self.totalImpulse.text = [NSString stringWithFormat:@"%1.1f N-sec", self.motor.totalImpulse];
    self.initialThrust.text = [NSString stringWithFormat:@"%1.2f N", self.motor.peakThrust];
    self.thrustCurve.dataSource = self;
    [self.thrustCurve setNeedsDisplay];
}

-(void)dealloc{
    self.motor = nil;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"Motor view controller for %@", self.motor];
}

@end
