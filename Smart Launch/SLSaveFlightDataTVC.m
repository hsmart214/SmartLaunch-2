//
//  SLSaveFlightDataTVC.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 1/13/13.
//  Copyright (c) 2013 J. HOWARD SMART. All rights reserved.
//

#import "SLSaveFlightDataTVC.h"

@interface SLSaveFlightDataTVC ()
@property (weak, nonatomic) IBOutlet UILabel *rocketName;
@property (weak, nonatomic) IBOutlet UIImageView *motorManufacturerLogo;
@property (weak, nonatomic) IBOutlet UILabel *motorName;
@property (weak, nonatomic) IBOutlet UILabel *launchAngleLabel;
@property (weak, nonatomic) IBOutlet UILabel *simAltitudeLabel;
@property (weak, nonatomic) IBOutlet UITextField *cdEstimateField;

@end

@implementation SLSaveFlightDataTVC

- (IBAction)cancelFlightSaving:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveFlightData:(UIBarButtonItem *)sender {
    float cd = [self.cdEstimateField.text floatValue];
    self.rocket.cd = @(cd);
    NSMutableDictionary *newFlightData = [self.flightData mutableCopy];
    newFlightData[FLIGHT_BEST_CD] = @(cd);
    self.rocket.recordedFlights = [newFlightData copy];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)calculateNewCd:(UIBarButtonItem *)sender {
    float initialGuess = [self.cdEstimateField.text floatValue];
    Rocket *tempRocket = [self.rocket copyWithZone:nil];
    tempRocket.cd = @(initialGuess);
    self.physicsModel.rocket = tempRocket;
    float initialAlt = self.physicsModel.fastApogee;
}

#pragma mark - View Life Cycle

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setToolbarHidden:NO animated:animated];
    self.cdEstimateField.text = [NSString stringWithFormat:@"%1.2f",[self.rocket.cd floatValue]];
    self.rocketName.text = self.rocket.name;
    self.motorName.text = self.physicsModel.motor.name;
    self.motorManufacturerLogo.image = [UIImage imageNamed:self.physicsModel.motor.manufacturer];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
