//
//  SLMotorSearchViewController.h
//  Smart Launch
//
//  Created by J. Howard Smart on 6/24/12.
//  Copyright (c) 2012 All rights reserved.
//

@import UIKit;
#import "RocketMotor.h"
#import "SLSimulationDelegate.h"

@protocol SLMotorPickerDatasource <NSObject>

-(NSUInteger)motorSizeRequested;

@end

@interface SLMotorSearchViewController: UIViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *search1Control;
@property (weak, nonatomic) IBOutlet UISegmentedControl *search2Control;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) NSDictionary *manufacturerNames;
@property (strong, nonatomic) NSArray *allMotors;
@property (weak, nonatomic) id<SLSimulationDelegate> delegate;
@property (weak, nonatomic) id<SLMotorPickerDatasource> dataSource;
@property (weak, nonatomic) UIViewController *popBackController;
@property (nonatomic, getter=isInRSOMode ) BOOL inRSOMode;

@end
