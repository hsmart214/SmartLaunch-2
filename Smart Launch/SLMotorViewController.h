//
//  SLMotorViewController.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RocketMotor.h"
#import "SLUnitsConvertor.h"
#import "SLMotorThrustCurveView.h"

@interface SLMotorViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *motorManufacturer;
@property (weak, nonatomic) IBOutlet UILabel *motorDiameter;
@property (weak, nonatomic) IBOutlet UILabel *motorMass;
@property (weak, nonatomic) IBOutlet UILabel *motorLength;
@property (weak, nonatomic) IBOutlet UILabel *propellantMass;
@property (weak, nonatomic) IBOutlet UILabel *totalImpulse;
@property (weak, nonatomic) IBOutlet UILabel *initialThrust;
@property (weak, nonatomic) IBOutlet SLMotorThrustCurveView *thrustCurve;

@property (nonatomic, strong) RocketMotor *motor;
@end
