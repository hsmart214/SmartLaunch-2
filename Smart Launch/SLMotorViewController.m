//
//  SLMotorViewController.m
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import "SLMotorViewController.h"

@interface SLMotorViewController () <SLMotorThrustCurveViewDataSource>

@end

@implementation SLMotorViewController 

@synthesize motorManufacturer;
@synthesize motorDiameter;
@synthesize motorMass;
@synthesize motorLength;
@synthesize propellantMass;
@synthesize totalImpulse;
@synthesize initialThrust;
@synthesize thrustCurve;
@synthesize motor;

- (void)drawThrustCurve{
    
}

#pragma mark SLMotorThrustCurveDataSource protocol methods

- (CGFloat)dataValueRange:(SLMotorThrustCurveView *)sender{
    return [self.motor.peakThrust floatValue];
}

- (CGFloat)timeValueRange:(SLMotorThrustCurveView *)sender{
    return [[self.motor.times lastObject] floatValue];
}

- (CGFloat)dataValueForTimeIndex:(CGFloat)time forView:(SLMotorThrustCurveView *)sender{
    return [self.motor thrustAtTime:time];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    NSString *backgroundFileName = [[NSBundle mainBundle] pathForResource: @"Vellum" ofType:@"png"];
    UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:backgroundFileName];
    [backgroundView setImage:backgroundImage];
    [self.view insertSubview:backgroundView atIndex:0];
    
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

- (void)viewDidUnload
{
    [self setMotorManufacturer:nil];
    [self setMotorDiameter:nil];
    [self setMotorMass:nil];
    [self setTotalImpulse:nil];
    [self setInitialThrust:nil];
    [self setThrustCurve:nil];
    [self setMotorLength:nil];
    [self setPropellantMass:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
