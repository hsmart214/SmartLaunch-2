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

@end

@implementation SLSaveFlightDataTVC

- (IBAction)cancelFlightSaving:(UIBarButtonItem *)sender {
}

#pragma mark - View Life Cycle

-(void)viewWillAppear:(BOOL)animated{
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
