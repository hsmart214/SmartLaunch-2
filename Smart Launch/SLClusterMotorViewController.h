//
//  SLClusterMotorViewController.h
//  Smart Launch
//
//  Created by J. HOWARD SMART on 5/5/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLCurveGraphView.h"
#import "SLSimulationDelegate.h"

@interface SLClusterMotorViewController : UIViewController<SLCurveGraphViewDataSource>

@property (nonatomic, strong) NSArray *motorLoadoutPlist;

@property (weak, nonatomic) IBOutlet UILabel *motorMass;
@property (weak, nonatomic) IBOutlet UILabel *propellantMass;
@property (weak, nonatomic) IBOutlet UILabel *totalImpulse;
@property (weak, nonatomic) IBOutlet UILabel *fractionalImpulse;
@property (weak, nonatomic) IBOutlet UILabel *initialThrust;
@property (weak, nonatomic) IBOutlet SLCurveGraphView *thrustCurve;
@property (weak, nonatomic) IBOutlet UITextView *motorListTextView;

@property (nonatomic, weak) id<SLSimulationDelegate> delegate;      // never used
@property (weak, nonatomic) UIViewController *popBackViewController;


@end
