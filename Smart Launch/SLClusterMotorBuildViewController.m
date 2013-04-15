//
//  SLClusterMotorBuildViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterMotorBuildViewController.h"
#import "RocketMotor.h"

@interface SLClusterMotorBuildViewController ()

@property (nonatomic) NSUInteger selectedMotorIndex;

@end

@implementation SLClusterMotorBuildViewController

-(SLClusterMotor *)clusterMotor{
    if (!_clusterMotor){
        _clusterMotor = (SLClusterMotor *)[SLClusterMotor defaultMotor];
    }
    return _clusterMotor;
}

- (IBAction)addNewMotor:(UIBarButtonItem *)sender {
    if ([self.clusterMotor.motors count] >= 7) return;
    RocketMotor *newMotor = [self.clusterMotor.motors lastObject][CLUSTER_MOTOR_KEY];
    NSNumber *delay = [self.clusterMotor.motors lastObject][CLUSTER_START_DELAY_KEY];
    [self.clusterMotor addClusterMotor:newMotor withStartDelay:delay];
    [self.tableView reloadData];
}

#pragma mark - SLSimulationDelegate method

-(void)sender:(id)sender didChangeRocketMotor:(RocketMotor *)motor{
    [self.clusterMotor replaceMotorAtIndex:self.selectedMotorIndex withMotor:motor];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.clusterMotor.motors count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier;
    UITableViewCell *cell;
    NSUInteger motorIndex = indexPath.section / 2;  // this is integer division, just to be clear
    NSDictionary *motorEntry = self.clusterMotor.motors[motorIndex];
    RocketMotor *motor = motorEntry[CLUSTER_MOTOR_KEY];
    float delay = [motorEntry[CLUSTER_START_DELAY_KEY] floatValue];
    UIImage *image = [UIImage imageNamed:motor.manufacturer];
    switch (indexPath.row % 2) {
        case 0:
            cellIdentifier = @"ClusterMemberCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
            cell.textLabel.text = [motor description];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%1.1f Ns", [motor.totalImpulse floatValue]];
            cell.imageView.image = image;
            break;
        case 1:
            cellIdentifier = @"ClusterDelayCell";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
            cell.textLabel.text = [NSString stringWithFormat:@"Delay %1.1f sec", delay];
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    self.selectedMotorIndex = [self.tableView indexPathForCell:sender].section / 2;
}

@end
