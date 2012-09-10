//
//  SLMotorSearchViewController.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 Smart Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RocketMotor.h"
#import "SLSimulationDelegate.h"
#import "SLDefinitions.h"

@interface SLMotorSearchViewController: UIViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *search1Control;
@property (weak, nonatomic) IBOutlet UISegmentedControl *search2Control;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) NSDictionary *manufacturerNames;
@property (strong, nonatomic) NSArray *allMotors;
@property (weak, nonatomic) id<SLSimulationDelegate> delegate;
@property (nonatomic, strong) NSNumber *rocketMotorMountDiameter;

@end
