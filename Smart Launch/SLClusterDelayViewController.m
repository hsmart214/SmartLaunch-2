//
//  SLClusterDelayViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterDelayViewController.h"
#import "SLCurveGraphView.h"

@interface SLClusterDelayViewController ()<SLCurveGraphViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *delayTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *motorImpulseLabel;
@property (weak, nonatomic) IBOutlet UIImageView *manufacturerLogo;
@property (weak, nonatomic) IBOutlet UILabel *burnoutTimeLabel;
@property (weak, nonatomic) IBOutlet SLCurveGraphView *thrustCurveGraphView;
@property (nonatomic, strong) SLClusterMotor *clusterMotor;
@property (nonatomic) float delayBasis;
@property (nonatomic) float delayTimeFromLaunch;
@property (nonatomic, strong) RocketMotor *motor;

@end

@implementation SLClusterDelayViewController

- (IBAction)delayTimeChanged:(UIStepper *)sender {
    if (self.datasource.selectedMotorIndex){
        [sender setValue:0.0];
        return;
    }
    self.delayTimeLabel.text = [NSString stringWithFormat:@"%1.1f sec", sender.value];
    [self.delegate changeDelayTimeTo:self.delayBasis sender:self];
    [self updateView];
}

- (IBAction)delayBasisChanged:(UISegmentedControl *)sender {
    self.delayBasis = [self.datasource timeToFirstBurnout] * sender.selectedSegmentIndex;
    [self.delegate changeDelayTimeTo:self.delayBasis sender:self];
    [self updateView];
}

-(void)updateView{
    [self.thrustCurveGraphView resetAxes];
}

#pragma mark - SLCurveGraphViewDataSource methods

-(CGFloat)curveGraphViewTimeValueRange:(SLCurveGraphView *)sender{
    return [self.clusterMotor totalBurnLength];
}

-(CGFloat)curveGraphViewDataValueRange:(SLCurveGraphView *)sender{
    return [[self.clusterMotor peakThrust] floatValue];
}

-(CGFloat)curveGraphViewDataValueMinimumValue:(SLCurveGraphView *)sender{
    return 0.0;
}

-(CGFloat)curveGraphView:(SLCurveGraphView *)sender dataValueForTimeIndex:(CGFloat)timeIndex{
    return [self.clusterMotor thrustAtTime:timeIndex];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    self.clusterMotor = [self.datasource clusterSoFar];
    self.delayBasis = 0.0;
    self.burnoutTimeLabel.text = [NSString stringWithFormat:@"%1.1f sec", [self.datasource timeToFirstBurnout]];
    self.motor = self.clusterMotor.motors[[self.datasource selectedMotorIndex]][CLUSTER_MOTOR_KEY];
    self.delayTimeFromLaunch = [self.clusterMotor.motors[[self.datasource selectedMotorIndex]][CLUSTER_START_DELAY_KEY] floatValue];
    self.manufacturerLogo.image = [UIImage imageNamed:self.motor.manufacturer];
    self.motorNameLabel.text = [self.motor description];
    self.motorImpulseLabel.text = [NSString stringWithFormat:@"%1.1f N-sec", [self.motor.totalImpulse floatValue]];
    self.thrustCurveGraphView.dataSource = self;
    [self updateView];
}

@end
