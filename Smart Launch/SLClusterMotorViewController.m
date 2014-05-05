//
//  SLClusterMotorViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 5/5/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterMotorViewController.h"
#import "SLClusterMotor.h"

@interface SLClusterMotorViewController ()

@property (nonatomic, strong)SLClusterMotor *clusterMotor;

@end

@implementation SLClusterMotorViewController

#pragma mark SLMotorThrustCurveDataSource protocol methods

- (float)curveGraphViewDataValueRange: (SLCurveGraphView *)sender{
    return self.clusterMotor.truePeakThrust;
}

-(float)curveGraphViewDataValueMinimumValue:(SLCurveGraphView *)sender{
    return 0.0;
}

- (float)curveGraphViewTimeValueRange:(SLCurveGraphView *)sender{
    return self.clusterMotor.totalBurnLength;
}

- (float)curveGraphView:(SLCurveGraphView *)thrustCurveView dataValueForTimeIndex:(CGFloat)timeIndex{
    return [self.clusterMotor thrustAtTime:timeIndex];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

-(void)listMotors{
    NSString *list = @"";
    for (NSDictionary *motorDict in self.motorLoadoutPlist) {
        list = [list stringByAppendingString:[NSString stringWithFormat:@"%@ x%d\n", motorDict[MOTOR_PLIST_KEY][NAME_KEY], [motorDict[MOTOR_COUNT_KEY]integerValue]]];
    }
    [self.motorListTextView setText:list];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if (!self.splitViewController){
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_IMAGE_FILENAME];
        [backgroundView setImage:backgroundImage];
        [self.view insertSubview:backgroundView atIndex:0];
    }else{
        //self.view.backgroundColor = [SLCustomUI iPadBackgroundColor];
        UIImageView * backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        UIImage * backgroundImage = [UIImage imageNamed:BACKGROUND_FOR_IPAD_MASTER_VC];
        [backgroundView setImage:backgroundImage];
        [self.view insertSubview:backgroundView atIndex:0];
    }
    self.clusterMotor = [[SLClusterMotor alloc] initWithMotorLoadout:self.motorLoadoutPlist];
    self.motorMass.text = [NSString stringWithFormat:@"%1.2f kg", self.clusterMotor.mass];
    self.propellantMass.text = [NSString stringWithFormat:@"%1.2f kg", self.clusterMotor.propellantMass];
    self.totalImpulse.text = [NSString stringWithFormat:@"%1.1f N-sec", self.clusterMotor.totalImpulse];
    self.initialThrust.text = [NSString stringWithFormat:@"%1.1f N", self.clusterMotor.peakInitialThrust];
    self.fractionalImpulse.text = [self.clusterMotor fractionalImpulseClass];
    self.thrustCurve.dataSource = self;
    [self listMotors];
    [self.thrustCurve setNeedsDisplay];
}

-(void)dealloc{
    self.motorLoadoutPlist = nil;
    self.clusterMotor = nil;
}

@end
