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

@end

@implementation SLClusterDelayViewController

- (IBAction)delayTimeChanged:(UIStepper *)sender {
    self.delayTimeLabel.text = [NSString stringWithFormat:@"%1.1f sec", sender.value];
}

- (IBAction)delayBasisChanged:(UISegmentedControl *)sender {
}

-(void)updateView{
    
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
}

@end
