//
//  SLMotorViewController.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RocketMotor.h"
#import "SLUnitsConvertor.h"
#import "SLCurveGraphView.h"
#import "SLSimulationDelegate.h"

@interface SLMotorViewController : UIViewController<SLCurveGraphViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *motorManufacturer;
@property (weak, nonatomic) IBOutlet UILabel *motorDiameter;
@property (weak, nonatomic) IBOutlet UILabel *motorMass;
@property (weak, nonatomic) IBOutlet UILabel *motorLength;
@property (weak, nonatomic) IBOutlet UILabel *propellantMass;
@property (weak, nonatomic) IBOutlet UILabel *totalImpulse;
@property (weak, nonatomic) IBOutlet UILabel *initialThrust;
@property (weak, nonatomic) IBOutlet SLCurveGraphView *thrustCurve;

@property (nonatomic, strong) RocketMotor *motor;
@property (nonatomic, weak) id<SLSimulationDelegate> delegate;
@end
