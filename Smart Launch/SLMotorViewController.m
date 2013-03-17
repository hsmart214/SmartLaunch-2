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

- (void)drawThrustCurve{
    
}

#pragma mark SLMotorThrustCurveDataSource protocol methods

- (CGFloat)curveGraphViewDataValueRange: (SLCurveGraphView *)sender{
    return [self.motor.peakThrust floatValue];
}

-(CGFloat)curveGraphViewDataValueMinimumValue:(SLCurveGraphView *)sender{
    return 0.0;
}

- (CGFloat)curveGraphViewTimeValueRange:(SLCurveGraphView *)sender{
    return [[self.motor.times lastObject] floatValue];
}

- (CGFloat)curveGraphView:(SLCurveGraphView *)thrustCurveView dataValueForTimeIndex:(CGFloat)timeIndex{
    return [self.motor thrustAtTime:timeIndex];
}

- (IBAction)userChoseMotor:(UIBarButtonItem *)sender {
    [self.delegate sender:self didChangeRocketMotor:self.motor];
    [self.navigationController popToRootViewControllerAnimated:YES];
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
        NSString *backgroundFileName = [[NSBundle mainBundle] pathForResource: @"Vellum" ofType:@"png"];
        UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:backgroundFileName];
        [backgroundView setImage:backgroundImage];
        [self.view insertSubview:backgroundView atIndex:0];
    }
    self.motorManufacturer.text = self.motor.manufacturer;
    self.motorDiameter.text = [self.motor.diameter description];
    self.motorMass.text = [self.motor.loadedMass description];
    self.propellantMass.text = [self.motor.propellantMass description];
    self.motorLength.text = [self.motor.length description];
    self.totalImpulse.text = [NSString stringWithFormat:@"%1.1f N-sec", [self.motor.totalImpulse floatValue]];
    self.initialThrust.text = [NSString stringWithFormat:@"%1.2f N", [self.motor.peakThrust floatValue]];
    self.thrustCurve.dataSource = self;
    [self.thrustCurve setNeedsDisplay];
}

-(void)dealloc{
    self.motor = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
