//
//  SLClusterMotorBuildViewController.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 4/14/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLClusterMotorBuildViewController.h"
#import "RocketMotor.h"
#import "SLMotorSearchViewController.h"
#import "SLSimulationDelegate.h"
#import "SLClusterMotorMemberCell.h"

@interface SLClusterMotorBuildViewController ()<SLMotorPickerDatasource, SLSimulationDelegate, SLMotorGroupDelegate>

@property (nonatomic, readwrite) NSUInteger selectedMotorIndex;

@end

@implementation SLClusterMotorBuildViewController

#pragma mark - SLSimulationDelegate method

-(void)sender:(id)sender didChangeRocketMotor:(NSArray *)motor{
    if (![motor count]) return;
    NSMutableDictionary *dict = motor[0];
    dict[MOTOR_COUNT_KEY] = self.motorConfiguration[self.selectedMotorIndex][MOTOR_COUNT_KEY];
}

-(NSUInteger)motorSizeRequested{
    return [self.motorConfiguration[self.selectedMotorIndex][MOTOR_DIAM_KEY] integerValue];
}

-(void)SLClusterMotorMemberCell:(SLClusterMotorMemberCell *)sender didChangeStartDelay:(float)time fromBurnout:(BOOL)fromBurnout{
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.motorConfiguration count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0){
        SLClusterMotorFirstGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ClusterFirstCell"];
        cell.motorDiameterTextLabel.text = [NSString stringWithFormat:@"%dmm", [self.motorConfiguration[0][MOTOR_DIAM_KEY] integerValue]];
        if (self.motorLoadoutPlist) {
            NSDictionary *motorDict = self.motorLoadoutPlist[0][MOTOR_PLIST_KEY];
            RocketMotor *motor = [RocketMotor motorWithMotorDict:motorDict];
            NSString *manName = motor.manufacturer;
            cell.imageView.image = [UIImage imageNamed:manName];
            cell.motorNameLabel.text = motor.name;
            cell.motorDetailTextLabel.text = [NSString stringWithFormat:@"%1.1f Ns", [motor totalImpulse]];
        }else{
            cell.imageView.image = nil;
            cell.motorNameLabel.text = NSLocalizedString(@"No Motor Selected", @"No Motor Selected");
            cell.motorDetailTextLabel.text = @"";
            cell.motorCountTextLabel = [NSString stringWithFormat:@"x %d", [self.motorConfiguration[0][MOTOR_COUNT_KEY] integerValue]];
        }
        return cell;
    }else{  // must be another row (1, 2, or 3)
        SLClusterMotorMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ClusterMemberCell"];
        cell.motorDiameterTextLabel.text = [NSString stringWithFormat:@"%dmm", [self.motorConfiguration[indexPath.row][MOTOR_DIAM_KEY] integerValue]];
        cell.delegate = self;
        cell.motorCountTextLabel = [NSString stringWithFormat:@"x %d", [self.motorConfiguration[indexPath.row][MOTOR_COUNT_KEY] integerValue]];
        [cell.delayBasisSelector setSelectedSegmentIndex:0];

        // need to check for the existence of motors in the loadout
        if ([self.motorLoadoutPlist count] > indexPath.row){
            // we have at least this many loaded groups, so we can load the info
            NSDictionary *motorDict = self.motorLoadoutPlist[indexPath.row][MOTOR_PLIST_KEY];
            RocketMotor *motor = [RocketMotor motorWithMotorDict:motorDict];
            NSString *manName = motor.manufacturer;
            cell.imageView.image = [UIImage imageNamed:manName];
            cell.motorNameLabel.text = motor.name;
            cell.motorDetailTextLabel.text = [NSString stringWithFormat:@"%1.1f Ns", [motor totalImpulse]];
            cell.delayTextLabel.text = [NSString stringWithFormat:@"Ignition Delay %1.1f sec", motor.startDelay];
            [cell.delayTimeStepper setValue:motor.startDelay];
        }else{
            // load up the empty row so the user can fill it if they like
            cell.imageView.image = nil;
            cell.motorNameLabel.text = NSLocalizedString(@"No Motor Selected", @"No Motor Selected");
            cell.motorDetailTextLabel.text = @"";
            cell.delayTextLabel.text = @"Ignition Delay 0.0 sec";
            [cell.delayTimeStepper setValue:0.0];
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    self.selectedMotorIndex = indexPath.row;
    [self performSegueWithIdentifier:@"clusterMemberMotorSearch" sender:indexPath];
}

#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"clusterMemberMotorSearch"]) {
        [(SLMotorSearchViewController *)segue.destinationViewController setDataSource:self];
        [(SLMotorSearchViewController *)segue.destinationViewController setDelegate:self];
        [(SLMotorSearchViewController *)segue.destinationViewController setPopBackController:self];
    }
}

@end
